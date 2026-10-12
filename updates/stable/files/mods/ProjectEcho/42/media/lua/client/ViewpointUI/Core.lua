--
-- Viewpoint UI - core: namespace, logging, events, small utilities.
--
-- Everything the add-on defines lives under the global ViewpointUI table.
-- ViewpointUI.Native is created by the add-on's Java part (ZombieBuddy) before
-- any Lua runs; this file only fills in what is missing, so it never replaces it.
--

ViewpointUI = ViewpointUI or {}
local VPUI = ViewpointUI

if VPUI.Core then return end

VPUI.VERSION = "0.9.6"
VPUI.Core = {}

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------

local Log = {}
VPUI.Log = Log

Log.ERROR, Log.WARN, Log.INFO, Log.DEBUG, Log.TRACE = 1, 2, 3, 4, 5
local NAMES = { "ERROR", "WARN", "INFO", "DEBUG", "TRACE" }

-- Until the settings load, warnings and errors only.
Log.level = Log.WARN

local onceSeen = {}

local function emit(level, text)
    if level > Log.level then return end
    print("[ViewpointUI] " .. NAMES[level] .. ": " .. tostring(text))
end

function Log.error(text) emit(Log.ERROR, text) end
function Log.warn(text) emit(Log.WARN, text) end
function Log.info(text) emit(Log.INFO, text) end
function Log.debug(text) emit(Log.DEBUG, text) end
function Log.trace(text) emit(Log.TRACE, text) end

-- Logs a message only the first time its key is seen (per session), so a fault
-- hit every tick is reported once instead of flooding the console.
function Log.once(level, key, text)
    if onceSeen[key] then return end
    onceSeen[key] = true
    emit(level, text)
end

---------------------------------------------------------------------------
-- Events: a tiny bus for the add-on and for mods extending it.
---------------------------------------------------------------------------

local Bus = { listeners = {} }
VPUI.Events = Bus

function Bus.add(name, fn)
    local list = Bus.listeners[name]
    if not list then
        list = {}
        Bus.listeners[name] = list
    end
    table.insert(list, fn)
end

function Bus.remove(name, fn)
    local list = Bus.listeners[name]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == fn then table.remove(list, i) end
    end
end

-- Listeners are isolated from each other: one failing listener is logged once
-- and the rest still run.
function Bus.fire(name, a, b, c)
    local list = Bus.listeners[name]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], a, b, c)
        if not ok then
            Log.once(Log.ERROR, "event:" .. name .. ":" .. tostring(i),
                "listener for " .. name .. " failed: " .. tostring(err))
        end
    end
end

---------------------------------------------------------------------------
-- Performance counters (Phase 10). Cheap increments at the places that cost
-- something (action list rebuilds, inventory rescans, menu harvests...); at the
-- Debug log level a summary per 10 seconds goes to console.txt, so a server
-- owner can see what the interface does without a profiler.
---------------------------------------------------------------------------

local Perf = { counts = {}, nextFlush = 0 }
VPUI.Perf = Perf

function Perf.count(name)
    Perf.counts[name] = (Perf.counts[name] or 0) + 1
end

function Perf.flush(now)
    if now < Perf.nextFlush then return end
    Perf.nextFlush = now + 10000
    if Log.level < Log.DEBUG then
        Perf.counts = {}
        return
    end
    local parts = {}
    for name, n in pairs(Perf.counts) do table.insert(parts, name .. "=" .. tostring(n)) end
    table.sort(parts)
    if #parts > 0 then Log.debug("last 10 s: " .. table.concat(parts, " ")) end
    Perf.counts = {}
end

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

local Util = {}
VPUI.Util = Util

function Util.now()
    return getTimestampMs()
end

function Util.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Util.round(v)
    return math.floor(v + 0.5)
end

-- The local player the interface serves. Viewpoint is a single-view mod, so
-- this is player 0.
-- True while the player has hidden the whole UI with the game's Toggle UI key
-- (ISUIHandler.toggleUI / setVisibleAllUI). Nothing of this add-on may show then.
function Util.uiHidden()
    return ISUIHandler ~= nil and ISUIHandler.allUIVisible == false
end

function Util.player()
    local p = getSpecificPlayer(0)
    if p and not p:isDead() then return p end
    return nil
end
