-- PROJECT ECHO AmmoCompat v0.2.5, B42.21
-- Context-menu handling of one or all identically typed ammo boxes in the SAME owned container.
-- Server validates and counts physical items. Client never supplies output type/count.
local MODULE = "ProjectEcho_AmmoCompat"
local map = require("PEAC_AmmoBox_Map")
local PREFIX = "[PE AmmoCompat AmmoBox v0.2.5] "
local installed = false
local installedDouble = false
local MAX_BOXES = 20
local MAX_OUTPUT = 2000
local function log(msg) print(PREFIX .. tostring(msg)) end

local function ownedBy(player, item)
    if not player or not item or not player.getInventory then return false end
    local inv = player:getInventory()
    return inv and inv:containsRecursive(item) or false
end

local function countInSource(item)
    local src = item and item:getContainer()
    local typ = item and item:getFullType()
    local spec = typ and map[typ]
    if not src or not spec or not src.getItems then return 0 end
    local all = src:getItems()
    if not all then return 0 end
    local n = 0
    for i=0,all:size()-1 do
        local current = all:get(i)
        if current and current:getFullType() == typ then n=n+1 end
    end
    return n
end

local function batchLimit(spec)
    return math.max(1, math.min(MAX_BOXES, math.floor(MAX_OUTPUT / spec.count)))
end

local function openItem(item, playerNum, mode)
    if not item or not item.getFullType then return false end
    local typ = item:getFullType()
    if not map[typ] then return false end
    local player = getSpecificPlayer(playerNum or 0)
    if not ownedBy(player, item) then
        log("Take package into personal inventory first: " .. typ)
        return false
    end
    mode = mode == "all" and "all" or "one"
    sendClientCommand(player, MODULE, "openAmmoBox", {
        itemId = item:getID(),
        itemType = typ,
        mode = mode
    })
    log("request sent: " .. typ .. " id=" .. tostring(item:getID()) .. " mode=" .. mode)
    return true
end

local function extractItem(items)
    if not items or type(items) ~= "table" then return nil end
    local pane = ISInventoryPane
    if pane and type(pane.getActualItems) == "function" then
        local ok, actual = pcall(pane.getActualItems, items)
        if ok and actual then
            for _, it in ipairs(actual) do
                if it and it.getFullType and map[it:getFullType()] then return it end
            end
        end
    end
    for _, node in ipairs(items) do
        if node and node.getFullType and map[node:getFullType()] then return node end
        if type(node) == "table" and type(node.items) == "table" then
            -- B42's first entry of grouped stack is a display-only duplicate.
            for i=2,#node.items do
                local it = node.items[i]
                if it and it.getFullType and map[it:getFullType()] then return it end
            end
        end
    end
    return nil
end

local function onContextMenu(playerNum, context, items)
    if not context or not context.addOption then return end
    local item = extractItem(items)
    if not item then return end
    local typ = item:getFullType()
    local spec = map[typ]
    local player = getSpecificPlayer(playerNum or 0)
    if not ownedBy(player,item) then
        local opt=context:addOption("PROJECT ECHO: Take ammo box first", item, function() end)
        if opt then opt.notAvailable=true end
        return
    end
    local available = countInSource(item)
    if available <= 0 then return end
    local limit = batchLimit(spec)
    local toOpen = math.min(available, limit)
    if available > 1 then
        context:addOption("PROJECT ECHO: Open boxes x" .. toOpen .. " (" .. (toOpen * spec.count) .. ")",
            item, openItem, playerNum, "all")
        context:addOption("PROJECT ECHO: Open ONE box (" .. spec.count .. ")",
            item, openItem, playerNum, "one")
    else
        context:addOption("PROJECT ECHO: Open ammo box (" .. spec.count .. ")",
            item, openItem, playerNum, "one")
    end
    log("menu: " .. typ .. " sourceBoxes=" .. available .. " batch=" .. toOpen)
end

local function onServerCommand(module, cmd, args)
    if module ~= MODULE or cmd ~= "ammoBoxResult" or not args then return end
    log("server result: " .. tostring(args.status) .. " " .. tostring(args.itemType)
        .. " " .. tostring(args.message))
end

local function install()
    if not installed and Events and Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(onContextMenu)
        if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
        installed = true
        log("context menu and server-reply events registered")
    end
    -- Double-click opens one box, by design. Right-click allows opening the entire stack.
    local pane = ISInventoryPane
    if not installedDouble and pane and type(pane.doContextualDblClick) == "function" then
        installedDouble = true
        local previous = pane.doContextualDblClick
        pane.doContextualDblClick = function(self, item, ...)
            if item and item.getFullType and map[item:getFullType()] then
                local num = self.player or 0
                if type(num) == "number" and openItem(item, num, "one") then return end
            end
            return previous(self, item, ...)
        end
        log("vanilla double-click hook installed")
    end
end

log("Client Lua loaded; boxes supported=135; stack-aware server mode")
install()
if Events and Events.OnGameStart then Events.OnGameStart.Add(install) end
