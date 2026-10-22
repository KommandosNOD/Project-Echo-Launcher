-- PROJECT ECHO Player Count API v1.0.0 / B42 server-only
-- Exports ONLY connected player count. No usernames, secrets, HTTP or socket access.
-- Output: %USERPROFILE%\Zomboid\Lua\ProjectEchoPlayerCountAPI.txt
-- A separate, authorized LOCAL PowerShell reporter publishes this number.
if not isServer() then return end

local FILE = "ProjectEchoPlayerCountAPI.txt"
local PERIOD_MS = 30000
local lastReportAt = 0
local lastCount = -1
local didWarn = false

local function reportPlayers(force)
    local now = getTimestampMs()
    if not force and now - lastReportAt < PERIOD_MS then return end
    lastReportAt = now

    local ok, result = pcall(function()
        local online = getOnlinePlayers()
        if not online then return nil end
        local players = online:size()
        if players < 0 or players > 16 then return nil end
        local writer = getFileWriter(FILE, true, false)
        if not writer then error("getFileWriter returned nil") end
        writer:write("PEPLAYERS|1|" .. tostring(players) .. "|16|" .. tostring(now) .. "\n")
        writer:close()
        return players
    end)
    if ok and result ~= nil then
        if result ~= lastCount then
            print("[ProjectEchoPlayerCountAPI] Players online: " .. tostring(result) .. "/16")
            lastCount = result
        end
        didWarn = false
    elseif not didWarn then
        print("[ProjectEchoPlayerCountAPI] WARNING: cannot export player count: " .. tostring(result))
        didWarn = true
    end
end

-- B42 server loop; wall-clock timestamp prevents game-speed-dependent reporting.
Events.OnServerStarted.Add(function() reportPlayers(true) end)
Events.OnTick.Add(function() reportPlayers(false) end)
-- PROJECT_ECHO_PLAYERCOUNT_PAUSE_EMPTY_FIX_V104
-- OnTick may stop when PauseEmpty=true and zero players are connected.
-- OnTickEvenPaused continues delivering heartbeats while the world is paused.
-- Both callbacks call the same 30-second rate-limited reporter, so there
-- are no extra writes when the game is running normally.
if Events.OnTickEvenPaused then
    Events.OnTickEvenPaused.Add(function() reportPlayers(false) end)
else
    print("[ProjectEchoPlayerCountAPI] WARNING: OnTickEvenPaused not available")
end
