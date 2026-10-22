-- PROJECT ECHO Nested Containers, 42.21 MP TEST v0.1.0
-- Server-authoritative world-nested -> player inventory transfers.
-- Based on analysis of NestedContainers (CJ187, Workshop 3797079676).
-- Explicitly limited scope to reduce desync/duplication risk.
if not isServer() then return end

local MODULE = "ProjectEchoNestedContainers"
local REQUEST = "NestedTakeRequest"
local RESULT = "NestedTakeResult"
local ROOT_CHANGED = "RootChanged"
local MAX_DEPTH = 12
local MAX_DISTANCE_SQ = 9.0
local seen = setmetatable({}, { __mode = "k" })

local function log(msg) print("[PEC-NC42][Server] " .. tostring(msg)) end

local function respond(player, id, ok, reason)
    sendServerCommand(player, MODULE, RESULT, {
        requestId = id, ok = ok == true, reason = reason or ""
    })
end

local function rootContainer(player, d)
    if type(d) ~= "table" then return nil, nil, "descriptor missing" end
    if d.kind == "player" then
        return player:getInventory(), nil, nil
    end
    if d.kind ~= "object" and d.kind ~= "corpse" then return nil, nil, "root kind not allowed" end
    local x, y, z, index = tonumber(d.x), tonumber(d.y), tonumber(d.z), tonumber(d.objectIndex)
    local subIndex = tonumber(d.containerIndex) or 0
    if not x or not y or not z or not index or not subIndex
        or x ~= math.floor(x) or y ~= math.floor(y) or z ~= math.floor(z)
        or index ~= math.floor(index) or subIndex ~= math.floor(subIndex)
        or index < 0 or subIndex < 0 then
        return nil, nil, "invalid world coordinates"
    end
    local square = getCell():getGridSquare(x, y, z)
    if not square then return nil, nil, "world square not loaded" end
    if math.floor(player:getZ()) ~= z then return nil, nil, "different floor" end
    local dx = player:getX() - (x + 0.5)
    local dy = player:getY() - (y + 0.5)
    if dx*dx + dy*dy > MAX_DISTANCE_SQ then return nil, nil, "out of reach" end
    local list = d.kind == "corpse" and square:getStaticMovingObjects() or square:getObjects()
    if not list or index >= list:size() then return nil, nil, "root object no longer exists" end
    local parent = list:get(index)
    if not parent then return nil, nil, "root object vanished" end
    if d.kind == "corpse" and not instanceof(parent, "IsoDeadBody") then
        return nil, nil, "root corpse changed"
    end
    local root = nil
    if parent.getContainerByIndex then root = parent:getContainerByIndex(subIndex) end
    if not root and subIndex == 0 and parent.getContainer then root = parent:getContainer() end
    if not root then return nil, nil, "root inventory not found" end
    if d.rootType and tostring(root:getType() or "") ~= d.rootType then
        return nil, nil, "root inventory type changed"
    end
    return root, square, nil
end

local function resolve(player, d)
    local cont, square, err = rootContainer(player, d)
    if not cont then return nil, square, err end
    local path = d.path or {}
    if type(path) ~= "table" or #path > MAX_DEPTH then return nil, square, "bad nested path" end
    for i = 1, #path do
        local id = tonumber(path[i])
        if not id then return nil, square, "invalid host id" end
        local host = cont:getItemWithID(id)
        -- Verify *direct* membership, not a matching item found recursively.
        if not host or host:getContainer() ~= cont or not cont:contains(host)
            or not host:IsInventoryContainer() then
            return nil, square, "host bag missing from its parent"
        end
        cont = host:getInventory()
        if not cont then return nil, square, "host bag inventory missing" end
    end
    return cont, square, nil
end

local function validate(player, item, src, dst, srcSquare)
    if src == dst or not item or not src or not dst then return false, "bad transfer endpoints" end
    if not src:contains(item) or item:getContainer() ~= src then return false, "item changed source" end
    if not src:isRemoveItemAllowed(item) then return false, "item removal not permitted" end
    if dst:isInside(item) or not dst:isItemAllowed(item) then return false, "destination rejects item" end
    if not dst:hasRoomFor(player, item) then return false, "destination full" end
    if not dst:isInCharacterInventory(player) then return false, "destination must be character inventory" end
    if srcSquare and SafeHouse and SafeHouse.isSafeHouse and
            SafeHouse.isSafeHouse(srcSquare, player:getUsername(), true) then
        return false, "safehouse denies access"
    end
    return true, nil
end

local function perform(src, dst, item)
    -- No vanilla createItemTransaction: it cannot resolve parentless nested bags.
    -- Never issue a *second* client-side transaction for the same item.
    local ok, err = pcall(function()
        src:DoRemoveItem(item)
        dst:AddItem(item)
        src:setDrawDirty(true)
        src:setHasBeenLooted(true)
        dst:setDrawDirty(true)
    end)
    if ok and dst:contains(item) and not src:contains(item) then return true, nil end
    -- Best-effort rollback, avoiding a duplicate if the destination already owns it.
    if not dst:contains(item) and not src:contains(item) then
        local reverted, revertErr = pcall(function() src:AddItem(item) end)
        if not reverted then log("ROLLBACK ERROR: " .. tostring(revertErr)) end
    end
    return false, "mutation failed: " .. tostring(err)
end

local function handle(player, args)
    if type(args) ~= "table" then return end
    local id = tonumber(args.requestId)
    if not id or id < 1 or id ~= math.floor(id) then return end
    if not player then return end
    if seen[player] and id <= seen[player] then
        respond(player, id, false, "duplicate or stale request")
        return
    end
    seen[player] = id
    if type(args.src) ~= "table" or type(args.dst) ~= "table"
        or (args.src.kind ~= "object" and args.src.kind ~= "corpse")
        or args.dst.kind ~= "player" or type(args.src.path) ~= "table"
        or #args.src.path < 1 then
        respond(player, id, false, "unsupported transfer direction")
        return
    end
    local src, square, srcError = resolve(player, args.src)
    if not src then respond(player, id, false, srcError); return end
    local dst, _, dstError = resolve(player, args.dst)
    if not dst then respond(player, id, false, dstError); return end
    local itemId = tonumber(args.itemId)
    local item = itemId and src:getItemWithID(itemId) or nil
    if not item or item:getContainer() ~= src then
        respond(player, id, false, "item id not found at source")
        return
    end
    local allowed, reason = validate(player, item, src, dst, square)
    if not allowed then respond(player, id, false, reason); return end
    local transferred, transferReason = perform(src, dst, item)
    if not transferred then respond(player, id, false, transferReason); return end
    log("APPROVED request=" .. tostring(id) .. " item=" .. tostring(item:getFullType()))
    respond(player, id, true, "")
    -- Other clients should reload the outer world container instead of locally
    -- replaying an inventory mutation with a possibly stale InventoryItem object.
    local notifyOK, notifyErr = pcall(function()
        sendServerCommand(MODULE, ROOT_CHANGED, {
            actorId = player:getOnlineID(), root = {
                kind = args.src.kind, x = args.src.x, y = args.src.y, z = args.src.z,
                objectIndex = args.src.objectIndex,
                containerIndex = args.src.containerIndex
            }
        })
    end)
    if not notifyOK then log("observer refresh broadcast unavailable: " .. tostring(notifyErr)) end
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= REQUEST then return end
    local id = args and args.requestId
    local ok, err = pcall(handle, player, args)
    if not ok then
        log("EXCEPTION request=" .. tostring(id) .. " " .. tostring(err))
        if player and tonumber(id) then respond(player, tonumber(id), false, "server exception") end
    end
end

Events.OnClientCommand.Add(onClientCommand)
log("v0.1.0 loaded (restricted dedicated MP transfer handler)")
