--
-- Viewpoint UI - built-in interaction providers.
--
-- "viewpoint.context" (priority 0): the generic context-action adapter.
--   Viewpoint already builds the game's own right-click menu for the aimed
--   object (mods' entries included, through OnFillWorldObjectContextMenu),
--   filters it to entries about that object, and keeps the functions to call
--   (ViewpointInteract.harvest). This provider shows those entries and runs them
--   through Viewpoint, so every vanilla and modded world action works without a
--   list kept here, and nothing simulates mouse clicks.
--
-- "vpui.loot" (priority 20): containers, bodies and items on the ground open the
--   Viewpoint inventory (Search / Search body / Pick up), replacing Viewpoint's
--   loot panel as the way to loot.
--
-- "vpui.vehicle" (priority 15): seats, condition and storage of a vehicle.
--
-- "vpui.npc" (priority -5): characters from NPC mods (see Interaction/NPC.lua).
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/Interaction/Registry"

local VPUI = ViewpointUI
local Bridge = VPUI.Bridge
local Registry = VPUI.Interaction.Registry
local KIND = Bridge.KIND

if Registry.builtinsLoaded then return end
Registry.builtinsLoaded = true

local T = VPUI.Text

---------------------------------------------------------------------------
-- viewpoint.context
---------------------------------------------------------------------------

-- Viewpoint marks a handful of entries as the obvious one (open/close a door or
-- window or curtain, a light switch, a generator, a stove, chopping a tree,
-- milking/shearing/petting an animal, entering a vehicle). Its Lua keeps the
-- flag in ViewpointInteract.actions; the labels come from Java in the same order.
local function primaryFlags(count)
    local list = ViewpointInteract and ViewpointInteract.actions
    if type(list) ~= "table" or #list ~= count then return nil end
    return list
end

Registry.register({
    id = "viewpoint.context",
    priority = 0,
    collect = function(target, player, add, result)
        if target.kind == KIND.NPC then return end   -- Viewpoint's list is about something else
        local count = Bridge.call("actionCount", 0)
        if count <= 0 then return end
        local version = Bridge.call("actionsVersion", -1)
        result.title = result.title or Bridge.call("actionTitle", nil)
        local flags = primaryFlags(count)
        for i = 1, count do
            local label = Bridge.call("actionLabel", nil, i)
            if label then
                local index = i
                add({
                    id = "viewpoint.context:" .. tostring(i),
                    label = label,
                    enabled = Bridge.call("actionEnabled", false, i) == true,
                    primary = flags ~= nil and flags[i] ~= nil and flags[i].first == true,
                    source = "viewpoint",
                    version = version,
                    run = function(p)
                        return Bridge.call("runAction", false, p, index) == true
                    end,
                })
            end
        end
    end,
})

---------------------------------------------------------------------------
-- vpui.npc: what NPC mods put in the right-click menu for a character
---------------------------------------------------------------------------

Registry.register({
    id = "vpui.npc",
    priority = -5,
    collect = function(target, player, add, result)
        if target.kind ~= KIND.NPC and target.kind ~= KIND.PERSON then return end
        local npc = target.object
        if not npc or not (instanceof(npc, "IsoZombie") or instanceof(npc, "IsoPlayer")) then return end
        local NPC = VPUI.Interaction.NPC
        local res = NPC.actions(player, npc)
        if not res then return end
        local have = {}
        for _, a in ipairs(result.actions) do have[a.label] = true end
        result.title = result.title or res.title or T.npc
        for _, entry in ipairs(res.list) do
            if not have[entry.label] then
                have[entry.label] = true
                add({ label = entry.label, enabled = entry.enabled,
                      run = function(p) return NPC.run(p, entry) end })
            end
        end
    end,
})

---------------------------------------------------------------------------
-- vpui.loot
---------------------------------------------------------------------------

local function targetContainers(target)
    local list = {}
    for i = 1, target.containers or 0 do
        local c = Bridge.call("targetContainer", nil, i)
        if c then table.insert(list, c) end
    end
    return list
end

local function containerTitle(container)
    if not container then return nil end
    local custom = container:getCustomName()
    if custom then return custom end
    return getTextOrNull("IGUI_ContainerTitle_" .. tostring(container:getType()))
end

-- Opens the inventory on these containers, walking to the first one if it is
-- out of reach (the inventory picks it up as soon as the player arrives).
local function openOn(player, containers, item)
    local first = containers[1]
    if first then pcall(luautils.walkToContainer, first, player:getPlayerNum()) end
    VPUI.Hub.open("inventory", { containers = containers, item = item })
end

Registry.register({
    id = "vpui.loot",
    priority = 20,
    collect = function(target, player, add, result)
        if target.kind == KIND.GROUND then
            local square = target.square
            local objects = square and square:getWorldObjects()
            local n = objects and objects:size() or 0
            if n == 1 then
                local worldItem = objects:get(0)
                local item = worldItem:getItem()
                if item then
                    result.title = result.title or item:getDisplayName()
                    add({ label = string.format(T.pickUp, item:getDisplayName()), primary = true,
                          run = function(p) VPUI.Inventory.Actions.grabWorldItem(p, worldItem) end })
                    add({ label = T.inspect, run = function(p)
                        openOn(p, { ISInventoryPage.GetFloorContainer(p:getPlayerNum()) }, item)
                    end })
                end
            elseif n > 1 then
                result.title = result.title or T.ground
                add({ label = string.format(T.searchGround, tostring(n)), primary = true,
                      run = function(p) openOn(p, { ISInventoryPage.GetFloorContainer(p:getPlayerNum()) }) end })
            end
            return
        end
        if (target.containers or 0) <= 0 then return end
        local containers = targetContainers(target)
        if #containers == 0 then return end
        if target.kind == KIND.BODY then
            result.title = result.title or T.body
            add({ label = T.searchBody, primary = true, run = function(p) openOn(p, containers) end })
        elseif target.kind == KIND.VEHICLE then
            add({ label = T.vehStorage, run = function(p) openOn(p, containers) end })
        else
            result.title = result.title or containerTitle(containers[1])
            add({ label = target.locked and T.searchLocked or T.search, enabled = not target.locked,
                  primary = true, run = function(p) openOn(p, containers) end })
        end
    end,
})

---------------------------------------------------------------------------
-- vpui.moveable: pick up and rotate furniture (see Building/MoveMode.lua)
---------------------------------------------------------------------------

Registry.register({
    id = "vpui.moveable",
    priority = 10,
    collect = function(target, player, add, result)
        if target.kind ~= KIND.OBJECT and target.kind ~= KIND.THING then return end
        local object, square = target.object, target.square
        if not object or not square or not VPUI.Building or not VPUI.Building.MoveMode then return end
        -- doors, windows and walls keep their own entries
        if instanceof(object, "IsoDoor") or instanceof(object, "IsoWindow") then return end
        local okW, isWall = pcall(function() return object:getType() == IsoObjectType.wall end)
        if okW and isWall then return end
        local MoveMode = VPUI.Building.MoveMode
        local props = MoveMode.propsOf(object)
        if not props or props.type == "Window" or props.type == "WindowObject" or props.type == "WallOverlay" then return end
        local name = MoveMode.displayName(props)
        result.title = result.title or name
        local okC, can = pcall(function()
            return ISMoveableDefinitions.cheat or player:isMovablesCheat() or props:canPickUpMoveable(player, square, object)
        end)
        local label = string.format(T.movePickUpAction, name)
        if not (okC and can) then
            local why = MoveMode.pickupReason(player, square, object, props)
            if why then label = label .. " (" .. why .. ")" end
        end
        add({ label = label, enabled = okC and can == true,
              run = function(p) return MoveMode.pickUp(p, square, object) end })
        local okR, rot = pcall(function() return props:canManuallyRotate() end)
        if okR and rot then
            add({ label = string.format(T.moveRotateAction, name), run = function(p)
                VPUI.Hub.close()
                MoveMode.open(p, "rotate")
                return true
            end })
        end
    end,
})

---------------------------------------------------------------------------
-- vpui.vehicle
---------------------------------------------------------------------------

-- On a vehicle, Enter Vehicle (the game's own entry, IGUI_EnterVehicle as in
-- ISVehicleMenu / ISButtonPrompt) goes to the top and is what a tap of
-- Interact does, so getting in is one press.
Registry.arrangers = Registry.arrangers or {}
table.insert(Registry.arrangers, function(target, result)
    if target.kind ~= KIND.VEHICLE then return end
    local want = getText("IGUI_EnterVehicle")
    for i, action in ipairs(result.actions) do
        if action.label == want then
            table.remove(result.actions, i)
            table.insert(result.actions, 1, action)
            if action.enabled then
                for _, other in ipairs(result.actions) do other.primary = nil end
                action.primary = true
            end
            return
        end
    end
end)

Registry.register({
    id = "vpui.vehicle",
    priority = 15,
    collect = function(target, player, add)
        if target.kind ~= KIND.VEHICLE or not target.object then return end
        local vehicle = target.object
        if not instanceof(vehicle, "BaseVehicle") then return end
        add({ label = T.vehSeatsInfo, run = function()
            VPUI.Hub.open("vehicle", { vehicle = vehicle })
        end })
    end,
})
