require "PE_RadioSync_Config"

-- Radio sync adapter for TrueMusicRadio42 (42.20 code path).
-- The server accepts one controlling listener per station. The listener is
-- selected from the clients actually playing that station (heartbeat).
-- No world/save ModData changes and no audio handling on the server.
local P = {state = {}, manualOverrides = {}, installed = false}

local function now()
    if type(getTimestamp) == "function" then
        local ok, n = pcall(getTimestamp)
        if ok and type(n) == "number" then return n end
    end
    if os and os.time then return os.time() end
    return 0
end

local function pname(player)
    if not player then return "unknown" end
    local ok, n = pcall(function() return player:getUsername() end)
    if ok and type(n) == "string" then return n end
    return "unknown"
end

local function valid(args)
    return type(args) == "table"
       and type(args.channel) == "number"
       and type(args.number) == "number"
       and args.number >= 1
end

local function log(s)
    print("[PE-RadioSync] " .. s)
end

function P.install()
    if P.installed or not isServer() or type(TMRadioServer) ~= "table" then return end
    if type(TMRadioServer.Play) ~= "function" or type(TMRadioServer.PlayNext) ~= "function" then return end

    local originalPlay = TMRadioServer.Play
    local originalNext = TMRadioServer.PlayNext

    -- Station terminals update a playlist and then send PlayNext. This is an
    -- intentional station edit, NOT an audio-finished event: allow it through.
    local names = {"A", "B", "C", "D", "E", "MTV"}
    local keys = {"TMRChannel1", "TMRChannel2", "TMRChannel3", "TMRChannel4", "TMRChannel5", "TMRMTV"}
    for i, name in ipairs(names) do
        local command = "UpdatePlaylistTerminal" .. name
        local old = TMRadioServer[command]
        local key = keys[i]
        if type(old) == "function" then
            TMRadioServer[command] = function(player, args)
                if args and not args.request and SandboxVars and SandboxVars.TrueMusicRadio then
                    local ch = SandboxVars.TrueMusicRadio[key]
                    if ch then P.manualOverrides[pname(player) .. ":" .. tostring(ch)] = now() end
                end
                return old(player, args)
            end
        end
    end

    TMRadioServer.Play = function(player, args)
        if not valid(args) then return originalPlay(player, args) end
        local ch = args.channel
        local st = P.state[ch]
        local cur = TMRadioServer.Channels and TMRadioServer.Channels[ch]
        if not st then
            -- Stamp the FIRST broadcast as well, or the DJ cannot heartbeat.
            args.peRadioSeq = 1
            local r = originalPlay(player, args)
            local song = TMRadioServer.Channels and TMRadioServer.Channels[ch]
            if type(song) == "number" then
                P.state[ch] = {song = song, seq = 1, startedAt = now(),
                    leader = pname(player), lastBeat = now(), lastNext = 0}
                log("station=" .. tostring(ch) .. " first song=" .. tostring(song)
                  .. " leader=" .. pname(player))
            end
            return r
        end
        -- Other listeners cannot change the current station song on Play.
        -- Existing clients receive Play again, but the client hook avoids
        -- restarting an already playing instance of the same sequence.
        if type(cur) == "number" and cur ~= st.song then
            st.song = cur
            st.seq = st.seq + 1
            st.startedAt = now()
        end
        args.number = st.song
        args.peRadioSeq = st.seq
        return originalPlay(player, args)
    end

    TMRadioServer.PlayNext = function(player, args)
        if not valid(args) then return end
        local ch = args.channel
        local st = P.state[ch]
        local time = now()
        local who = pname(player)
        if not st then
            args.peRadioSeq = 1
            local r = originalNext(player, args)
            local song = TMRadioServer.Channels and TMRadioServer.Channels[ch]
            if type(song) == "number" then
                P.state[ch] = {song = song, seq = 1, startedAt = time,
                    leader = who, lastBeat = time, lastNext = time}
            end
            return r
        end
        local overrideKey = who .. ":" .. tostring(ch)
        local isManualEdit = P.manualOverrides[overrideKey]
            and time - P.manualOverrides[overrideKey] < 8
        P.manualOverrides[overrideKey] = nil
        if not isManualEdit then
            if time - st.startedAt < PERS_Config.minTrackSeconds then
                return -- multiple clients can finish in the same second
            end
            if st.leader ~= who and time - st.lastBeat <= PERS_Config.leaderTimeoutSeconds then
                return -- ignore a late listener finishing a different timeline
            end
        end
        -- The previous DJ has disappeared: let another listener take over.
        if st.leader ~= who then
            log("station=" .. tostring(ch) .. " new leader=" .. who)
        end
        local prevSong = st.song
        local prevSeq = st.seq
        st.leader = who
        st.lastBeat = time
        st.lastNext = time
        st.startedAt = time
        st.seq = prevSeq + 1
        args.peRadioSeq = st.seq
        local ok, result = pcall(originalNext, player, args)
        if not ok then
            st.seq = prevSeq
            st.song = prevSong
            log("PlayNext original failed: " .. tostring(result))
            return
        end
        local song = TMRadioServer.Channels and TMRadioServer.Channels[ch]
        st.song = type(song) == "number" and song or args.number
        log("station=" .. tostring(ch) .. " seq=" .. tostring(st.seq)
            .. " next=" .. tostring(st.song) .. " by=" .. who)
        return result
    end

    P.installed = true
    log("server hooks active (TrueMusicRadio42)")
end

local function onHeartbeat(module, command, player, args)
    if module ~= "ProjectEchoRadioSync" or command ~= "Heartbeat" then return end
    if type(args) ~= "table" then return end
    local ch = tonumber(args.channel)
    local st = ch and P.state[ch]
    if not st or tonumber(args.number) ~= st.song or tonumber(args.seq) ~= st.seq then return end
    local time = now()
    local who = pname(player)
    if st.leader == who or time - st.lastBeat > PERS_Config.leaderTimeoutSeconds then
        st.leader = who
        st.lastBeat = time
    end
end

Events.OnClientCommand.Add(onHeartbeat)
Events.OnServerStarted.Add(P.install)
-- Tolerate different mod loading orders without editing TrueMusicRadio42.
local attempts = 0
Events.OnTick.Add(function()
    if P.installed then return end
    attempts = attempts + 1
    if attempts % 120 == 1 then P.install() end
end)
