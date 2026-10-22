--
-- Viewpoint Interface - built-in extras (merged from VPUI_Extras, by G00SE)
-- Aim-prompt additions: Grab/Drop corpse, Search all bodies, Jiggle locked
-- doors, a sane tap action near doors/windows/vehicles, and a debug filter.
--
-- Providers are registered through ViewpointUI.Interactions.register (the
-- documented API). Arrangers are the host mod's own post-processing list
-- (ViewpointUI.Interaction.Registry.arrangers), which it exposes and already
-- uses for "Enter Vehicle first".
--

if isServer() then return end

require "ViewpointUI/Extras/Core"

local X = VPUIExtras
if X.Interactions then return end
X.Interactions = true

local installed = false

local function playerNum(p)
    local ok, n = pcall(function() return p:getPlayerNum() end)
    return ok and n or 0
end

---------------------------------------------------------------------------
-- Corpses
---------------------------------------------------------------------------

local function isDeadBody(obj)
    if not obj then return false end
    local ok, r = pcall(instanceof, obj, "IsoDeadBody")
    return ok and r == true
end

-- Same steps as ISWorldObjectContextMenu.onGrabCorpseItem (B42): get up,
-- walk there, free the hands, grab. All timed actions, so the server checks
-- them exactly as it does for the right-click menu.
local function grabCorpse(player, body)
    if player:isSitOnGround() then player:setVariable("forceGetUp", true) end
    ISTimedActionQueue.add(ISPathFindAction:pathToGrabCorpse(player, body))
    local prim, sec = player:getPrimaryHandItem(), player:getSecondaryHandItem()
    if prim then ISTimedActionQueue.add(ISUnequipAction:new(player, prim, 50)) end
    if sec and sec ~= prim then ISTimedActionQueue.add(ISUnequipAction:new(player, sec, 50)) end
    ISTimedActionQueue.add(ISGrabCorpseAction:new(player, body))
end

local function dropCorpse(player)
    -- what the vanilla "Drop Corpse" entry does (ISWorldObjectContextMenu
    -- .handleGrabWorldItem_onDropCorpse): stop the grapple
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.handleGrabWorldItem_onDropCorpse then
        ISWorldObjectContextMenu.handleGrabWorldItem_onDropCorpse(player)
    else
        player:setDoContinueGrapple(false)
    end
end

local function bodiesOn(square)
    local out = {}
    if not square then return out end
    pcall(function()
        local list = square:getDeadBodys()
        if list then
            for i = 0, list:size() - 1 do
                local b = list:get(i)
                if b then table.insert(out, b) end
            end
        end
    end)
    return out
end

local function openInventoryOn(player, containers, V)
    local first = containers[1]
    if first then pcall(luautils.walkToContainer, first, playerNum(player)) end
    V.Hub.open("inventory", { containers = containers })
end

local function registerCorpseProvider(V)
    local KIND = V.Bridge.KIND
    V.Interactions.register({
        id = "vpuix.corpse",
        priority = 19, -- just under vpui.loot (20): Search body stays the tap action
        collect = function(target, player, add, result)
            if target.kind ~= KIND.BODY then return end
            local body = target.object
            if not isDeadBody(body) then return end

            if X.get("grabCorpse") ~= false then
                local okD, dragging = pcall(function() return player:isDraggingCorpse() end)
                if okD and dragging then
                    add({ id = "vpuix.corpse:drop", label = X.text("ContextMenu_Drop_Corpse"),
                          run = function(p) dropCorpse(p) end })
                else
                    local okF, onFire = pcall(function() return body:getSquare():haveFire() end)
                    add({ id = "vpuix.corpse:grab", label = X.text("ContextMenu_Grab_Corpse"),
                          enabled = not (okF and onFire),
                          run = function(p) grabCorpse(p, body) end })
                end
            end

            if X.get("searchAllBodies") ~= false then
                local bodies = bodiesOn(body:getSquare())
                if #bodies > 1 then
                    local containers = {}
                    for _, b in ipairs(bodies) do
                        local ok, c = pcall(function() return b:getContainer() end)
                        if ok and c then table.insert(containers, c) end
                    end
                    if #containers > 1 then
                        add({ id = "vpuix.corpse:all",
                              label = string.format("Search all bodies here (%d)", #containers),
                              run = function(p) openInventoryOn(p, containers, V) end })
                    end
                end
            end
        end,
    })
end

---------------------------------------------------------------------------
-- Locked doors: Jiggle lock
---------------------------------------------------------------------------

local function isDoor(obj)
    if not obj then return false end
    if instanceof(obj, "IsoDoor") then return true end
    if instanceof(obj, "IsoThumpable") and obj.isDoor and obj:isDoor() then return true end
    return false
end

local function isLockedDoor(obj)
    if not isDoor(obj) then return false end
    if obj.isLocked and obj:isLocked() then return true end
    if obj.isLockedByKey and obj:isLockedByKey() then return true end
    return false
end

-- The door Viewpoint aims at: its target object, or a door on the aimed square
-- (Viewpoint's target kinds are its own; a door is not always an "object").
local function doorFor(target)
    if isDoor(target.object) then return target.object end
    local square = target.square
    if not square and target.object and target.object.getSquare then square = target.object:getSquare() end
    if not square then return nil end
    local objects = square:getObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if isDoor(o) then return o end
    end
    return nil
end

-- Translate at interaction time, when RU JSON has already been loaded.
-- Avoid raw non-ASCII Lua literals: they caused broken text in ViewpointUI.
local function peJiggleLabel()
    if type(getTextOrNull) == "function" then
        local ok, value = pcall(getTextOrNull, "UI_ProjectEcho_JiggleLock")
        if ok and type(value) == "string" and value ~= "" and value ~= "UI_ProjectEcho_JiggleLock" then
            return value
        end
    end
    if type(getText) == "function" then
        local ok, value = pcall(getText, "UI_ProjectEcho_JiggleLock")
        if ok and type(value) == "string" and value ~= "" and value ~= "UI_ProjectEcho_JiggleLock" then
            return value
        end
    end
    return "Jiggle lock"
end

local function registerDoorProvider(V)
    V.Interactions.register({
        id = "vpuix.door",
        priority = 5,
        collect = function(target, player, add)
            if X.get("jiggleDoors") == false then return end
            local door = doorFor(target)
            if not door or not isLockedDoor(door) then return end
            -- the vanilla key-in-hand path is already offered by the game's menu
            -- (Unlock Door); jiggling is what the isometric interact key does
            add({ id = "vpuix.door:jiggle", label = peJiggleLabel(), primary = true,
                  run = function(p)
                      ISTimedActionQueue.add(ISOpenCloseDoor:new(p, door))
                  end })
        end,
    })
end

---------------------------------------------------------------------------
-- Windows behind something: a sink, counter or shelf on a window's tile is
-- what Viewpoint aims at, so the window's own entries never appear. The
-- window on that tile (or the one just past it, since windows sit on the
-- north/west edge of their square) gets the game's own entries through the
-- same handlers the right-click menu calls.
---------------------------------------------------------------------------

local function windowsNear(target, player)
    local out = {}
    local square = target.square
    if not square and target.object and target.object.getSquare then square = target.object:getSquare() end
    if not square then return out end
    local squares = { square }
    -- the square one step further along the line player -> target
    pcall(function()
        local dx, dy = square:getX() - player:getX(), square:getY() - player:getY()
        local sx = (dx > 0.5 and 1) or (dx < -0.5 and -1) or 0
        local sy = (dy > 0.5 and 1) or (dy < -0.5 and -1) or 0
        if sx ~= 0 or sy ~= 0 then
            local cell = getCell()
            local far = cell and cell:getGridSquare(square:getX() + sx, square:getY() + sy, square:getZ())
            if far then table.insert(squares, far) end
        end
    end)
    for _, sq in ipairs(squares) do
        local objects = sq:getObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local o = objects:get(i)
                if o and o ~= target.object and instanceof(o, "IsoWindow") then table.insert(out, o) end
            end
        end
    end
    return out
end

local function registerWindowProvider(V)
    V.Interactions.register({
        id = "vpuix.window",
        priority = 4,
        collect = function(target, player, add, result)
            if X.get("windowBehind") == false then return end
            -- the window is the target itself (or already listed): nothing to add
            if target.object and instanceof(target.object, "IsoWindow") then return end
            local openL, closeL = X.text("ContextMenu_Open_window"), X.text("ContextMenu_Close_window")
            for _, a in ipairs(result.actions) do
                if a.label == openL or a.label == closeL then return end
            end
            local M = ISWorldObjectContextMenu
            if not M then return end
            local pn = playerNum(player)
            for _, w in ipairs(windowsNear(target, player)) do
                local okB, barricaded = pcall(function() return w:isBarricaded() end)
                if not (okB and barricaded) then
                    local okD, destroyed = pcall(function() return w:isDestroyed() end)
                    local okO, open = pcall(function() return w:IsOpen() end)
                    local okL, locked = pcall(function() return w:isLocked() or w:isPermaLocked() end)
                    destroyed, open, locked = okD and destroyed, okO and open, okL and locked
                    if not destroyed then
                        if open or not locked then
                            add({ id = "vpuix.window:toggle", label = open and closeL or openL,
                                  run = function(p) M.onOpenCloseWindow(nil, w, pn) end })
                        end
                        if not open and M.onSmashWindow then
                            add({ id = "vpuix.window:smash", label = X.text("ContextMenu_Smash_window"),
                                  run = function(p) M.onSmashWindow(nil, w, pn) end })
                        end
                    else
                        local okG, glass = pcall(function() return w:isGlassRemoved() end)
                        if okG and not glass and M.onRemoveBrokenGlass then
                            add({ id = "vpuix.window:glass", label = X.text("ContextMenu_RemoveBrokenGlass"),
                                  run = function(p) M.onRemoveBrokenGlass(nil, w, pn) end })
                        end
                    end
                    if (open or destroyed) and M.onClimbThroughWindow then
                        add({ id = "vpuix.window:climb", label = X.text("ContextMenu_Climb_through"),
                              run = function(p) M.onClimbThroughWindow(nil, w, pn) end })
                    end
                    break   -- one window is enough; the nearest square wins
                end
            end
        end,
    })
end

---------------------------------------------------------------------------
-- Arrangers: tap-action priority and the debug filter
---------------------------------------------------------------------------

-- Labels that should win the tap of Interact when present, in order.
local function winners()
    return {
        X.text("IGUI_EnterVehicle"),
        X.text("ContextMenu_Open_door"), X.text("ContextMenu_Close_door"),
        X.text("ContextMenu_Climb_through"), X.text("ContextMenu_Climb_over"),
        X.text("ContextMenu_Open_window"), X.text("ContextMenu_Close_window"),
        X.text("ContextMenu_RemoveBrokenGlass"),
        X.text("ContextMenu_Open_curtains"), X.text("ContextMenu_Close_curtains"),
        X.text("ContextMenu_UnlockDoor"),
    }
end

-- Labels that must never be the tap action while a winner is around
-- ("jiggle" is ours: a key in hand should unlock, not rattle).
local LOSERS_LC = { "build", "disassemble", "dismantle", "carpentry", "scrap", "place ", "jiggle", "smash" }

local function startsWith(s, prefix)
    return type(s) == "string" and type(prefix) == "string" and prefix ~= "" and s:sub(1, #prefix) == prefix
end

local function smartPrimary(target, result)
    if X.get("smartPrimary") == false then return end
    local actions = result.actions
    if #actions < 2 then return end
    local currentPrimary
    for _, a in ipairs(actions) do
        if a.primary and a.enabled then currentPrimary = a break end
    end
    -- find the best winner present
    local best, bestRank
    for _, a in ipairs(actions) do
        if a.enabled and type(a.label) == "string" then
            for rank, w in ipairs(winners()) do
                if (a.label == w or startsWith(a.label, w)) and (not bestRank or rank < bestRank) then
                    best, bestRank = a, rank
                end
            end
        end
    end
    if not best then return end
    if currentPrimary == best then return end
    -- only step in when the current tap action is a known loser, or none is set
    local demote = currentPrimary == nil
    if currentPrimary then
        if currentPrimary.id == "vpuix.door:jiggle" then demote = true end
        local lc = X.lower(currentPrimary.label)
        for _, l in ipairs(LOSERS_LC) do
            if lc:find(l, 1, true) then demote = true break end
        end
    end
    if not demote then return end
    for _, a in ipairs(actions) do a.primary = nil end
    best.primary = true
    -- and put it at the top of the list, as the host mod does for Enter Vehicle
    for i, a in ipairs(actions) do
        if a == best then
            table.remove(actions, i)
            table.insert(actions, 1, a)
            break
        end
    end
end

-- Smash Window sits above Open Window in the game's own menu; here it goes
-- just under the open/close/climb entries, so a quick scroll never lands on it.
local function sinkSmash(target, result)
    local actions = result.actions
    if #actions < 2 then return end
    local smash = X.text("ContextMenu_Smash_window")
    local keep = { X.text("ContextMenu_Open_window"), X.text("ContextMenu_Close_window"),
                   X.text("ContextMenu_Climb_through"), X.text("ContextMenu_Climb_over"),
                   X.text("ContextMenu_RemoveBrokenGlass") }
    local si, last = nil, nil
    for i, a in ipairs(actions) do
        if type(a.label) == "string" then
            if not si and (a.label == smash or startsWith(a.label, smash)) then si = i end
            for _, k in ipairs(keep) do
                if a.label == k or startsWith(a.label, k) then last = i end
            end
        end
    end
    if not si or not last or si > last then return end
    local a = table.remove(actions, si)
    table.insert(actions, last, a)   -- last shifted down by one after the removal
    if a.primary then
        -- the tap action should be the window entry, not the smash
        a.primary = nil
        actions[last - 1].primary = true
    end
end

local function hideDebug(target, result)
    if X.get("hideDebug") == false then return end
    local words = X.debugWords()
    if #words == 0 then return end
    local actions = result.actions
    for i = #actions, 1, -1 do
        local label = actions[i].label
        if type(label) == "string" then
            for _, w in ipairs(words) do
                if label:find(w, 1, true) then
                    table.remove(actions, i)
                    break
                end
            end
        end
    end
end

local function installArrangers(V)
    local Registry = V.Interaction.Registry
    Registry.arrangers = Registry.arrangers or {}
    table.insert(Registry.arrangers, function(target, result)
        local ok, err = pcall(hideDebug, target, result)
        if not ok then X.log("debug filter error:", tostring(err)) end
    end)
    table.insert(Registry.arrangers, function(target, result)
        local ok, err = pcall(smartPrimary, target, result)
        if not ok then X.log("primary arranger error:", tostring(err)) end
    end)
    table.insert(Registry.arrangers, function(target, result)
        local ok, err = pcall(sinkSmash, target, result)
        if not ok then X.log("smash arranger error:", tostring(err)) end
    end)
end

---------------------------------------------------------------------------
-- Install once the host mod is there
---------------------------------------------------------------------------

local function install()
    if installed then return true end
    local V = X.vpui()
    if not V or not V.Bridge or not V.Bridge.KIND or not V.Hub then return false end
    local ok, err = pcall(function()
        registerCorpseProvider(V)
        registerDoorProvider(V)
        registerWindowProvider(V)
        installArrangers(V)
    end)
    if not ok then
        X.log("install failed:", tostring(err))
        return false
    end
    installed = true
    X.log("aim-prompt extras installed (v" .. X.VERSION .. ")")
    return true
end

-- Try now (if ViewpointUI loaded first), then again at game start.
pcall(install)
Events.OnGameStart.Add(function() pcall(install) end)
Events.OnCreatePlayer.Add(function() pcall(install) end)
