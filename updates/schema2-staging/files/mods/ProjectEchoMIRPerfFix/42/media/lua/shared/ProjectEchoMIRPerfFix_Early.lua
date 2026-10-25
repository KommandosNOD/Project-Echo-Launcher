-- PROJECT ECHO - experimental MultiPurposeItemRack event coalescer.
-- B42.21 MP. No original Workshop files are modified or redistributed.
-- Load the patch before MultiPurposeItemRack in server Mods list.

if isServer and isServer() then
    return
end

local PREFIX = '[PE-MIR-FIX] '
local TARGET_FILE = 'mir_client.lua'
local TARGET_LINE = 439  -- observed in SmoothFrames client log, 2026-10-25
local LINE_TOLERANCE = 12
local MIN_INTERVAL_MS = 150 -- max 6.7 executions/second for this one callback

if not Events or not Events.OnContainerUpdate then
    print(PREFIX .. 'WARN: OnContainerUpdate unavailable; no changes made')
    return
end

if not getFilenameOfClosure or not getFirstLineOfClosure or not getTimestampMs then
    print(PREFIX .. 'WARN: closure inspection / clock unavailable; no changes made')
    return
end

local containerEvent = Events.OnContainerUpdate
local originalAdd = containerEvent.Add
if not originalAdd then
    print(PREFIX .. 'WARN: OnContainerUpdate.Add unavailable; no changes made')
    return
end

if _G.PE_MIR_PerfFix_HookActive then
    print(PREFIX .. 'Already initialized')
    return
end
_G.PE_MIR_PerfFix_HookActive = true

local installed = false
local candidates = 0

-- All other callbacks are forwarded untouched. Only a closure from the
-- original file and the known source line is eligible for this shim.
containerEvent.Add = function(callback)
    if installed or type(callback) ~= 'function' then
        return originalAdd(callback)
    end

    local okFile, filename = pcall(getFilenameOfClosure, callback)
    if not okFile or type(filename) ~= 'string' then
        return originalAdd(callback)
    end
    local lower = string.lower(filename)
    if not string.find(lower, TARGET_FILE, 1, true) then
        return originalAdd(callback)
    end

    candidates = candidates + 1
    local okLine, line = pcall(getFirstLineOfClosure, callback)
    if not okLine or type(line) ~= 'number' or math.abs(line - TARGET_LINE) > LINE_TOLERANCE then
        print(PREFIX .. 'MIR callback skipped (source line ' .. tostring(line) .. '; expected near ' .. tostring(TARGET_LINE) .. ')')
        return originalAdd(callback)
    end

    local originalCallback = callback
    local lastRun = -1000000000
    local pending = false
    local lastObject = nil
    local suppressed = 0
    local calls = 0

    local function safeClock()
        local ok, ms = pcall(getTimestampMs)
        if ok and type(ms) == 'number' then
            return ms
        end
        return nil
    end

    local function invokeOriginal(object, timeMs)
        pending = false
        lastObject = nil
        if timeMs then lastRun = timeMs end
        calls = calls + 1
        return originalCallback(object)
    end

    local function coalescedCallback(object)
        local now = safeClock()
        if not now then
            -- Missing timestamp? Fail open to the original event behaviour.
            return invokeOriginal(object, nil)
        end
        if not pending and now - lastRun >= MIN_INTERVAL_MS then
            return invokeOriginal(object, now)
        end
        -- The original handler invalidates rack inventory data. Group bursts
        -- and process the latest update on a later game tick.
        pending = true
        lastObject = object
        suppressed = suppressed + 1
    end

    local function flushPending()
        if not pending then return end
        local now = safeClock()
        if not now or now - lastRun >= MIN_INTERVAL_MS then
            invokeOriginal(lastObject, now)
        end
    end

    -- Register tick first, then the targeted callback; anything else remains
    -- registered on OnContainerUpdate as normal.
    if Events.OnTick then
        Events.OnTick.Add(flushPending)
    else
        print(PREFIX .. 'WARN: OnTick missing, original callback kept')
        return originalAdd(callback)
    end

    installed = true
    print(PREFIX .. 'ACTIVE: wrapped MIR_Client.lua:' .. tostring(line)
        .. ' (interval=' .. tostring(MIN_INTERVAL_MS) .. 'ms; client only)')

    local function showCounters()
        print(PREFIX .. 'diagnostic: original=' .. tostring(calls)
            .. ' merged=' .. tostring(suppressed))
    end
    -- Diagnostics roughly once each in-game hour to avoid log noise.
    if Events.EveryHours then
        Events.EveryHours.Add(showCounters)
    end
    return originalAdd(coalescedCallback)
end

if Events.OnGameStart then
    Events.OnGameStart.Add(function()
        if installed then
            print(PREFIX .. 'Startup check OK; target callback replaced')
        else
            print(PREFIX .. 'WARN: callback not intercepted; check Mods order and source line; MIR unchanged. Candidates=' .. tostring(candidates))
        end
    end)
end

print(PREFIX .. 'Hook ready; waiting for MultiPurposeItemRack client callback')
