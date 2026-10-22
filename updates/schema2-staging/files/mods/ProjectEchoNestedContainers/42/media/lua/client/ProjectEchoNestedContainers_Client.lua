-- PROJECT ECHO Nested Containers, 42.21 MP TEST v0.1.0
-- Adapted architecture informed by NestedContainers (CJ187, Workshop 3797079676).
-- Conservative scope: world object/corpse -> player inventory (including carried bags),
-- with the item in one or more bags inside the world container. No floor/vehicle cases.
-- NO automatic bag staging, no modifications to vanilla game files.
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISInventoryTransferAction"

local MODULE = "ProjectEchoNestedContainers"
local RESULT = "NestedTakeResult"
local REQUEST = "NestedTakeRequest"
local ROOT_CHANGED = "RootChanged"
local MAX_DEPTH = 12
local TIMEOUT_MS = 8500
local installed = false
local originalAdd = nil
local nextId = 1
local waiting = {}

local function log(msg)
    print("[PEC-NC42][Client] " .. tostring(msg))
end

local function describe(cont, player, onlyWorld)
    if not cont or not player then return nil end
    local path = {}
    local cur = cont
    local depth = 0
    while cur and cur:getContainingItem() do
        local bag = cur:getContainingItem()
        local enclosing = bag:getContainer()
        if not enclosing or not enclosing:contains(bag) then return nil end
        table.insert(path, 1, bag:getID())
        cur = enclosing
        depth = depth + 1
        if depth > MAX_DEPTH then return nil end
    end
    if not cur then return nil end
    if cur == player:getInventory() then
        if onlyWorld then return nil end
        return { kind = "player", path = path }
    end
    if not onlyWorld or depth < 1 then return nil end
    if cur:getType() == "floor" or cur:getVehiclePart() or cur:isVehicleSeat() then return nil end
    local parent = cur:getParent()
    if not parent then return nil end
    local square = cur:getSourceGrid()
    if not square and parent.getSquare then square = parent:getSquare() end
    if not square then return nil end
    local kind, index
    if instanceof(parent, "IsoDeadBody") then
        kind = "corpse"
        index = parent:getStaticMovingObjectIndex()
    else
        kind = "object"
        index = parent:getObjectIndex()
    end
    if not index or index < 0 then return nil end
    local cindex = 0
    if parent.getContainerIndex then
        local found = parent:getContainerIndex(cur)
        if found and found >= 0 then cindex = found end
    end
    return {
        kind = kind, x = square:getX(), y = square:getY(), z = square:getZ(),
        objectIndex = index, containerIndex = cindex,
        rootType = tostring(cur:getType() or ""), path = path
    }
end

-- Only intercept the supported world-nested -> carried inventory direction.
-- All unrelated actions remain untouched (including ProximityInventory virtual lists).
local function eligible(action)
    if not isClient() or not action or action.Type ~= "ISInventoryTransferAction" then return nil end
    local player = action.character
    local item = action.item
    local src = action.srcContainer
    local dst = action.destContainer
    if not player or not item or not src or not dst then return nil end
    if item:getContainer() ~= src or not src:contains(item) then return nil end
    if src == dst or src:getType() == "proxInv" or dst:getType() == "proxInv" then return nil end
    local source = describe(src, player, true)
    if not source then return nil end
    local dest = describe(dst, player, false)
    if not dest or dest.kind ~= "player" then return nil end
    return source, dest
end

PE42NestedTakeAction = ISBaseTimedAction:derive("PE42NestedTakeAction")

function PE42NestedTakeAction:isValid()
    if self.ack then return true end
    return self.character ~= nil and self.item ~= nil
        and self.srcContainer ~= nil and self.destContainer ~= nil
        and self.item:getContainer() == self.srcContainer
        and self.srcContainer:contains(self.item)
end

function PE42NestedTakeAction:start()
    if not self.action then return end
    self.startedAt = getTimestampMs()
    self.action:setWaitForFinished(true)
    waiting[self.requestId] = self
    if self.item.setJobType then
        self.item:setJobType(getText("IGUI_MovingToContainer"))
        self.item:setJobDelta(0)
    end
    local sent, err = pcall(sendClientCommand, self.character, MODULE, REQUEST, {
        requestId = self.requestId,
        itemId = self.item:getID(),
        src = self.source,
        dst = self.destination,
    })
    if not sent then
        log("REQUEST FAILED: " .. tostring(err))
        self:forceStop()
    else
        log("request=" .. self.requestId .. " item=" .. tostring(self.item:getFullType()))
    end
end

function PE42NestedTakeAction:update()
    if self.item and self.item.setJobDelta then self.item:setJobDelta(0) end
    if self.startedAt and getTimestampMs() - self.startedAt > TIMEOUT_MS then
        log("TIMEOUT request=" .. tostring(self.requestId) .. " (no server confirmation)")
        self:forceStop()
    end
end

local function clearAction(action)
    waiting[action.requestId] = nil
    if action.item and action.item.setJobDelta then action.item:setJobDelta(0) end
    if action.action then action.action:setWaitForFinished(false) end
end

function PE42NestedTakeAction:stop()
    clearAction(self)
    ISBaseTimedAction.stop(self)
end
function PE42NestedTakeAction:perform()
    clearAction(self)
    ISBaseTimedAction.perform(self)
end

function PE42NestedTakeAction:new(original, source, destination)
    local o = ISBaseTimedAction.new(self, original.character)
    o.character = original.character
    o.item = original.item
    o.srcContainer = original.srcContainer
    o.destContainer = original.destContainer
    o.source = source
    o.destination = destination
    o.requestId = nextId
    o.ack = false
    o.startedAt = nil
    o.maxTime = -1
    o.stopOnWalk = true
    o.stopOnRun = true
    o.ignoreHandsWounds = true
    nextId = nextId + 1
    if nextId > 1900000000 then nextId = 1 end
    return o
end

local function mirror(action)
    -- The server has already performed this exact transfer. Do not issue a second
    -- transaction and do not mirror if the server sync has already applied it.
    local item, src, dst = action.item, action.srcContainer, action.destContainer
    if not item or not src or not dst then return false end
    if dst:contains(item) and not src:contains(item) then return true end
    if not src:contains(item) or item:getContainer() ~= src then
        log("MIRROR SKIP: local source changed before confirmation")
        return false
    end
    local ok, err = pcall(function()
        src:DoRemoveItem(item)
        dst:AddItem(item)
        src:setDrawDirty(true)
        src:setHasBeenLooted(true)
        dst:setDrawDirty(true)
        if ISInventoryPage then ISInventoryPage.renderDirty = true end
    end)
    if not ok then log("MIRROR FAILED: " .. tostring(err)) end
    return ok and dst:contains(item)
end

local function onServerCommand(module, command, args)
    if module ~= MODULE or not args then return end
    if command == RESULT then
        local id = tonumber(args.requestId)
        local action = id and waiting[id]
        if not action then
            log("LATE RESULT request=" .. tostring(id) .. " ok=" .. tostring(args.ok))
            return
        end
        if args.ok == true then
            action.ack = true
            mirror(action)
            log("APPROVED request=" .. tostring(id))
            action:forceComplete()
        else
            log("REJECTED request=" .. tostring(id) .. " reason=" .. tostring(args.reason))
            action:forceStop()
        end
    elseif command == ROOT_CHANGED then
        local localPlayer = getPlayer()
        if not localPlayer or localPlayer:getOnlineID() == tonumber(args.actorId) then return end
        local info = args.root
        if type(info) ~= "table" then return end
        local square = getCell():getGridSquare(info.x, info.y, info.z)
        if not square then return end
        local list = info.kind == "corpse" and square:getStaticMovingObjects() or square:getObjects()
        local parent = list and list:get(info.objectIndex)
        if not parent then return end
        local root = parent.getContainerByIndex and parent:getContainerByIndex(info.containerIndex or 0) or nil
        if not root and (info.containerIndex or 0) == 0 and parent.getContainer then root = parent:getContainer() end
        if root and root.requestServerItemsForContainer then
            pcall(function() root:requestServerItemsForContainer() end)
        end
    end
end

local function addWithNestedSupport(action, ...)
    local source, destination = eligible(action)
    if source and destination then
        return originalAdd(PE42NestedTakeAction:new(action, source, destination), ...)
    end
    return originalAdd(action, ...)
end

local function install()
    if installed then return end
    if not isClient() or not ISTimedActionQueue or type(ISTimedActionQueue.add) ~= "function" then return end
    originalAdd = ISTimedActionQueue.add
    ISTimedActionQueue.add = addWithNestedSupport
    installed = true
    log("v0.1.0 installed: server-authoritative world-nested TAKE ONLY")
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnGameStart.Add(install)
