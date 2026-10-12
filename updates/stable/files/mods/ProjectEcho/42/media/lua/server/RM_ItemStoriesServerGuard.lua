-- PROJECT ECHO Item Stories B42.21 server guard v4 (2026-10-12)
-- Workshop files are not modified. This removes callbacks that have already
-- been registered by the upstream client-side cell sweep on a dedicated server.
-- Other story-generation code and genuine MP item spawning remain enabled.

if not (isServer and isServer()) then return end

local safeCellSweep = function() return end
local checkCount = 0
local lastRemoved = nil

local function disableServerCellSweep()
    local spawner = StoryItemSpawner
    if type(spawner) ~= 'table' then return end
    local fn = spawner.AddCellsRoomsToList
    if type(fn) ~= 'function' or fn == safeCellSweep then return end

    -- Events store the function value at Add-time: assigning a new method
    -- alone does NOT remove an old registered callback.
    local names = {'EveryOneMinute', 'OnTick', 'EveryTenMinutes',
                   'EveryHours', 'OnGameStart', 'OnPlayerUpdate'}
    for i = 1, #names do
        local event = Events and Events[names[i]]
        if event and event.Remove then event.Remove(fn) end
    end
    spawner.AddCellsRoomsToList = safeCellSweep
    spawner.__ProjectEcho_ItemStoriesCellSweepFixed = true
    if lastRemoved ~= fn then
        print('[PROJECT ECHO] ItemStories DS cell-sweep callback detached; no local player on dedicated server')
        lastRemoved = fn
    end
end

-- Guard at script load, during startup, and on subsequent ticks in case
-- another mod defines/re-registers the function later than ours.
disableServerCellSweep()
local function watchdog()
    checkCount = checkCount + 1
    if checkCount >= 60 then
        checkCount = 0
        disableServerCellSweep()
    end
end

if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(disableServerCellSweep) end
    if Events.OnGameStart then Events.OnGameStart.Add(disableServerCellSweep) end
    if Events.OnServerStarted then Events.OnServerStarted.Add(disableServerCellSweep) end
    if Events.OnTick then Events.OnTick.Add(watchdog) end
end
