-- PROJECT ECHO AmmoCompat v0.2.5. B42.21 dedicated server-authoritative box opening.
-- Stacked boxes are separate InventoryItems in one container. The server discovers
-- and consumes each real item, never using client-supplied box counts or ammo outputs.
local MODULE = "ProjectEcho_AmmoCompat"
local map = require("PEAC_AmmoBox_Map")
local PREFIX = "[PE AmmoCompat AmmoBox v0.2.5] "
local MAX_BOXES = 20
local MAX_OUTPUT = 2000

local function reply(player, status, itemType, message)
    if player then
        sendServerCommand(player, MODULE, "ammoBoxResult", {
            status = status,
            itemType = itemType,
            message = message,
        })
    end
end

local function refuse(player, itemType, message)
    print(PREFIX .. "REFUSED: " .. tostring(itemType) .. " reason=" .. tostring(message))
    reply(player, "refused", itemType, message)
end

local function command(module, action, player, args)
    if module ~= MODULE or action ~= "openAmmoBox" then return end
    if not player or type(args) ~= "table" or not args.itemId then return end
    if args.mode ~= nil and args.mode ~= "one" and args.mode ~= "all" then
        return refuse(player, args.itemType, "invalid mode")
    end
    local mode = args.mode == "all" and "all" or "one"

    local inv = player:getInventory()
    if not inv then return end
    local box = inv:getItemById(args.itemId)
    if not box then box = inv:getItemWithIDRecursiv(args.itemId) end
    if not box then return refuse(player, args.itemType, "not owned by player") end
    local typ = box:getFullType()
    if typ ~= args.itemType then return refuse(player, typ, "item type mismatch") end
    local spec = map[typ]
    if not spec or not spec.output or not spec.count or spec.count < 1 or spec.count > 200 then
        return refuse(player, typ, "unsupported package")
    end
    local source = box:getContainer()
    if not source then return refuse(player, typ, "no owning container") end
    if not getScriptManager():FindItem(spec.output) then
        return refuse(player, typ, "output item not registered: " .. tostring(spec.output))
    end

    -- Collect physical packages from the exact same owned source container.
    -- Never consume same-looking packages from unrelated bags or the ground.
    local limit = math.max(1, math.min(MAX_BOXES, math.floor(MAX_OUTPUT / spec.count)))
    local boxes = {box}
    if mode == "all" then
        local all = source:getItems()
        if not all then return refuse(player, typ, "no source items") end
        -- One original anchor first. Other boxes must be real items of same type.
        for i = 0, all:size()-1 do
            local other = all:get(i)
            if other and other ~= box and other:getFullType() == typ and other:getContainer() == source then
                boxes[#boxes+1] = other
                if #boxes >= limit then break end
            end
        end
    end

    -- Reject stale or suspicious inventory changes before altering any items.
    for i = 1, #boxes do
        local candidate = boxes[i]
        if candidate:getContainer() ~= source or candidate:getFullType() ~= typ
            or not source:getItems():contains(candidate) then
            return refuse(player, typ, "box changed during command")
        end
    end

    local total = #boxes * spec.count
    if total > MAX_OUTPUT then return refuse(player, typ, "request exceeds safety limit") end
    -- Pre-create complete result BEFORE deleting original packages.
    local rounds = {}
    for i = 1, total do
        local round = instanceItem(spec.output)
        if not round then return refuse(player, typ, "instanceItem failed at " .. i) end
        rounds[#rounds+1] = round
    end

    for i = 1, #boxes do
        local consumed = boxes[i]
        source:Remove(consumed)
        sendRemoveItemFromContainer(source, consumed)
    end
    for i = 1, #rounds do
        inv:AddItem(rounds[i])
        sendAddItemToContainer(inv, rounds[i])
    end
    print(PREFIX .. "OPENED: " .. typ .. " boxes=" .. #boxes .. " -> " .. total
        .. " x " .. spec.output .. " player=" .. tostring(player:getUsername()))
    reply(player, "opened", typ, tostring(#boxes) .. " boxes -> " .. total .. " x " .. spec.output)
end

if isServer() and Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(function(module, action, player, args)
        if module ~= MODULE or action ~= "openAmmoBox" then return end
        local ok, err = pcall(command, module, action, player, args)
        if not ok then
            print(PREFIX .. "SERVER ERROR: " .. tostring(err))
            refuse(player, args and args.itemType, "server exception")
        end
    end)
    print(PREFIX .. "server command handler installed; whitelist size=135; stack-aware")
end
