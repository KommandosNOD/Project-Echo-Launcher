--
-- Viewpoint UI - characters from NPC mods.
--
-- NPC mods (bandits, survivors, traders...) are mostly zombies or players run
-- by Lua, and they are talked to through the game's right-click menu: their
-- entries are added in OnFillWorldObjectContextMenu (or OnPreFill...) when the
-- player right-clicks the NPC's square. Viewpoint only aims at real players,
-- and there is no right-click in first person, so those NPCs could only be
-- used from the isometric view.
--
-- Finding the NPC: every living character other than you within reach is
-- projected with Viewpoint's own camera (Bridge "project"); the one whose body
-- (feet to head) is under the crosshair, nearer than the surface the crosshair
-- hits and in sight, is the target.
--
-- Its actions: the game's own world menu is built for the NPC's square, at the
-- NPC's screen position (the mouse position reads the same while it is built,
-- for mods that look there), exactly as a right-click would; only the entries
-- added during the two "fill" events are kept, minus the game's own (foraging,
-- building, admin, vehicle, debug), and their functions are called the way the
-- menu calls them. The menu itself is hidden again in the same tick, as
-- Viewpoint does for its own harvest. Nothing in an NPC mod needs changing.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.Interaction = VPUI.Interaction or {}
if VPUI.Interaction.NPC then return end

local NPC = {}
VPUI.Interaction.NPC = NPC

local Bridge = VPUI.Bridge
local Log = VPUI.Log

NPC.KIND = 100           -- not one of Viewpoint's kinds
Bridge.KIND.NPC = NPC.KIND
Bridge.KIND_NAME[NPC.KIND] = "npc"

local REACH = 2.6        -- tiles, a little more than Viewpoint's reach for players
local SCAN = 3           -- squares round the player searched
local HEAD = 0.62        -- floors: crown of the head above the feet
local CACHE_MS = 2500    -- a harvest is reused this long for the same character

---------------------------------------------------------------------------
-- Aim
---------------------------------------------------------------------------

-- Bridge.call takes at most two arguments; projection needs four (as in BuildMode).
local function project(x, y, z, lift)
    local native = VPUI.Native
    if not native or not native.project then return nil end
    local ok, visible = pcall(native.project, x, y, z, lift)
    if not ok or visible ~= true then return nil end
    return native.projectedX(), native.projectedY()
end

local function hitDistance(player)
    local hx, hy = Bridge.call("hitX", nil), Bridge.call("hitY", nil)
    if not hx or hx ~= hx or not hy or hy ~= hy then return math.huge end
    local dx, dy = hx - player:getX(), hy - player:getY()
    return math.sqrt(dx * dx + dy * dy)
end

local function candidate(player, o)
    if o == player then return false end
    if not (instanceof(o, "IsoZombie") or instanceof(o, "IsoPlayer")) then return false end
    local ok, dead = pcall(function() return o:isDead() end)
    if not ok or dead then return false end
    if instanceof(o, "IsoPlayer") then
        -- animals are players too (IsoAnimal); Viewpoint and the game's animal
        -- menu handle those
        if o:isAnimal() then return false end
        if o:isLocalPlayer() then return false end
    end
    return true
end

-- The character under the crosshair, or nil.
function NPC.aimed(player)
    local cell = getCell()
    if not cell then return nil end
    local cx, cy = getCore():getScreenWidth() / 2, getCore():getScreenHeight() / 2
    local px, py, pz = player:getX(), player:getY(), math.floor(player:getZ())
    local wall = hitDistance(player)
    local best, bestDist = nil, math.huge
    for x = math.floor(px) - SCAN, math.floor(px) + SCAN do
        for y = math.floor(py) - SCAN, math.floor(py) + SCAN do
            local sq = cell:getGridSquare(x, y, pz)
            local list = sq and sq:getMovingObjects()
            for i = 0, (list and list:size() or 0) - 1 do
                local o = list:get(i)
                if candidate(player, o) then
                    local dx, dy = o:getX() - px, o:getY() - py
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist <= REACH and dist < bestDist and dist < wall + 0.4 then
                        local fx, fy = project(o:getX(), o:getY(), o:getZ(), 0)
                        local hx, hy = project(o:getX(), o:getY(), o:getZ(), HEAD)
                        if fx and hx then
                            local top, bottom = math.min(fy, hy), math.max(fy, hy)
                            local half = math.max(12, (bottom - top) * 0.22)
                            local midX = (fx + hx) / 2
                            if cy >= top and cy <= bottom and math.abs(cx - midX) <= half then
                                local okS, sees = pcall(function() return player:CanSee(o) end)
                                if not okS or sees then best, bestDist = o, dist end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local aimCache = { at = -1, npc = nil }

-- NPC.aimed, at most every 100 ms.
function NPC.aimedCached(player)
    local now = getTimestampMs()
    if now - aimCache.at >= 100 or now < aimCache.at then
        local ok, npc = pcall(NPC.aimed, player)
        aimCache.npc = ok and npc or nil
        aimCache.at = now
        if not ok then Log.once(Log.WARN, "npcAim", "looking for NPCs failed: " .. tostring(npc)) end
    end
    return aimCache.npc
end

---------------------------------------------------------------------------
-- The NPC mods' menu entries
---------------------------------------------------------------------------

local vanillaFns = nil

-- Every function of the game's own world-menu tables (their entries are not
-- an NPC mod's).
local function vanilla()
    if vanillaFns then return vanillaFns end
    vanillaFns = {}
    local tables = { ISWorldObjectContextMenu, ISWorldObjectContextMenuLogic, DebugContextMenu, ISVehicleMenu,
        ISInventoryPaneContextMenu, ISSearchManager, ISInventoryBuildMenu, AdminContextMenu, ISHutchMenu,
        corpseStorageCheck, AnimalContextMenu }
    for _, t in ipairs(tables) do
        if type(t) == "table" then
            for _, f in pairs(t) do
                if type(f) == "function" then vanillaFns[f] = true end
            end
        end
    end
    return vanillaFns
end

local function handler(o)
    if o.onSelect == ISContextMenu.onGetUpAndThen then return o.param1 end
    return o.onSelect
end

local function copy(o, label, out, skip)
    if not o.onSelect or skip[handler(o)] then return end
    if o.isDefaultOption then return end
    table.insert(out, {
        label = label,
        enabled = not o.notAvailable and not o.isDisabled,
        fn = o.onSelect,
        args = { o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6, o.param7, o.param8, o.param9, o.param10 },
    })
end

local function collect(menu, prefix, out, skip, depth)
    if depth > 3 then return end
    for i = 1, (menu.numOptions or 1) - 1 do
        local o = menu.options[i]
        if o then
            local label = prefix and (prefix .. ": " .. tostring(o.name)) or tostring(o.name)
            if o.subOption then
                local sub = menu:getSubMenu(o.subOption)
                if sub then collect(sub, label, out, skip, depth + 1) end
            else
                copy(o, label, out, skip)
            end
        end
    end
end

-- Builds the world menu for the NPC and returns { title, list } or nil.
function NPC.harvest(player, npc)
    local pn = player:getPlayerNum()
    local open = getPlayerContextMenu(pn)
    if not open or open:getIsVisible() then return nil end
    if getCell():getDrag(pn) then return nil end
    local sq = npc:getCurrentSquare()
    if not sq then return nil end
    local objects = sq:getObjects()
    local worldobjects = {}
    for i = 0, objects:size() - 1 do table.insert(worldobjects, objects:get(i)) end
    if #worldobjects == 0 then return nil end
    local x = isoToScreenX(pn, npc:getX(), npc:getY(), npc:getZ())
    local y = isoToScreenY(pn, npc:getX(), npc:getY(), npc:getZ())

    -- top-level entries the fill events add (identities: the menu pools its options)
    local added = {}
    local realTrigger, realMouseX, realMouseY = triggerEvent, getMouseX, getMouseY
    triggerEvent = function(name, a, context, ...)
        if (name == "OnFillWorldObjectContextMenu" or name == "OnPreFillWorldObjectContextMenu")
                and type(context) == "table" and context.options then
            local before = {}
            for i = 1, context.numOptions - 1 do
                if context.options[i] then before[context.options[i]] = true end
            end
            local ok, err = pcall(realTrigger, name, a, context, ...)
            for i = 1, context.numOptions - 1 do
                local o = context.options[i]
                if o and not before[o] then added[o] = true end
            end
            if not ok then Log.once(Log.WARN, "npcFill", "a mod's menu entries failed while reading an NPC: " .. tostring(err)) end
            return
        end
        return realTrigger(name, a, context, ...)
    end
    getMouseX = function() return x end
    getMouseY = function() return y end
    local ok, context = pcall(ISWorldObjectContextMenu.createMenu, pn, worldobjects, x, y)
    triggerEvent, getMouseX, getMouseY = realTrigger, realMouseX, realMouseY

    local list = {}
    local title = nil
    if ok and type(context) == "table" and context.options then
        local skip = vanilla()
        for i = 1, (context.numOptions or 1) - 1 do
            local o = context.options[i]
            if o and added[o] then
                if o.subOption then
                    local sub = context:getSubMenu(o.subOption)
                    local before = #list
                    if sub then collect(sub, nil, list, skip, 1) end
                    if #list > before and not title then title = tostring(o.name) end
                else
                    copy(o, tostring(o.name), list, skip)
                end
            end
        end
    elseif not ok then
        Log.once(Log.WARN, "npcMenu", "could not build the menu for an NPC: " .. tostring(context))
    end
    pcall(open.hideAndChildren, open)
    if instanceof(npc, "IsoPlayer") then
        local okN, name = pcall(function() return npc:getDisguisedDisplayName() end)
        if okN and name and name ~= "" then title = name end
    end
    return { title = title, list = list }
end

local cache = {}   -- character -> { at, result }; pruned (Kahlua has no weak tables)

-- Cached harvest (the menu is built at most every CACHE_MS per character).
function NPC.actions(player, npc)
    -- not while fighting: aiming a weapon is not talking
    if player:isAiming() then return nil end
    local now = getTimestampMs()
    local c = cache[npc]
    if c and now - c.at < CACHE_MS then return c.result end
    local ok, result = pcall(NPC.harvest, player, npc)
    if not ok then
        Log.once(Log.WARN, "npcHarvest", "reading an NPC's actions failed: " .. tostring(result))
        result = nil
    end
    for k, v in pairs(cache) do
        if now - v.at >= CACHE_MS then cache[k] = nil end
    end
    cache[npc] = { at = now, result = result }
    return result
end

function NPC.run(player, entry)
    ISContextMenu.globalPlayerContext = player:getPlayerNum()
    entry.fn(entry.args[1], entry.args[2], entry.args[3], entry.args[4], entry.args[5], entry.args[6],
        entry.args[7], entry.args[8], entry.args[9], entry.args[10], entry.args[11])
    return true
end

return NPC
