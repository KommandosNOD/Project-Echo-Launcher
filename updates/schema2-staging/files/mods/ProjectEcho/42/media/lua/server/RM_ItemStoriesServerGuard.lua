-- PROJECT ECHO Item Stories B42.21: dedicated-server room-sweep guard v5
-- Fixes nil getPlayer() in Item Stories AddCellsRoomsToList.
-- Does not replace Workshop sources or any spawner functions; it only
-- detaches the *registered function values* from server-only events.
-- Unlike v4, this never replaces StoryItemSpawner.AddCellsRoomsToList with
-- a stub: overwriting the global loses the reference to the OLD callback.

if not (isServer and isServer()) then return end

local TAG = "[PROJECT ECHO][ItemStories Guard v5]"
print(TAG .. " server script loaded; watching room-sweep callbacks")

local tracked = {}
local known = {}
local ticks = 0
local suppressed = 0

local function detach(fn)
    local ev = Events and Events.EveryOneMinute
    if ev and ev.Remove then ev.Remove(fn) end
    -- Only these are plausible aliases used by third-party compatibility mods.
    ev = Events and Events.EveryTenMinutes
    if ev and ev.Remove then ev.Remove(fn) end
end

local function checkAndDetach()
    local spawner = StoryItemSpawner
    local fn = type(spawner) == "table" and spawner.AddCellsRoomsToList or nil

    -- Keep all observed identities, not only the current method. The event
    -- registry retains old closures even after another patch overwrites it.
    if type(fn) == "function" and not known[fn] then
        known[fn] = true
        tracked[#tracked + 1] = fn
        print(TAG .. " captured handler #" .. tostring(#tracked))
    end

    -- Do not alter the method or attach a replacement. Other client logic
    -- may legitimately use it in SP/MP; the server has no local player.
    for i = 1, #tracked do detach(tracked[i]) end

    if #tracked > 0 then suppressed = suppressed + 1 end
end

checkAndDetach()

local function onTick()
    ticks = ticks + 1
    -- Catch late registration during server start very promptly; afterward
    -- check at a much lower rate (no per-frame printing or menu hooks).
    if ticks <= 600 or ticks % 30 == 0 then
        checkAndDetach()
    end
    if ticks == 600 then
        print(TAG .. " startup scan complete; distinct callbacks=" ..
              tostring(#tracked) .. "; switched to periodic checking")
    end
end

local function onServerReady()
    checkAndDetach()
    print(TAG .. " server ready; callbacks observed=" .. tostring(#tracked))
end

if Events then
    if Events.OnServerStarted then Events.OnServerStarted.Add(onServerReady) end
    if Events.OnGameStart then Events.OnGameStart.Add(checkAndDetach) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
end
