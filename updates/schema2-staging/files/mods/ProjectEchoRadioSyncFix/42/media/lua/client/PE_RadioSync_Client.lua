require "PE_RadioSync_Config"

-- Prevent sound from restarting when multiple radios/players request the
-- same song. Track the server-provided sequence to support repeated songs.
local P = {installed = false, lastHeartbeat = {}, lastScan = 0, currentSeq = nil}

local function now()
    if type(getTimestamp) == "function" then
        local ok, n = pcall(getTimestamp)
        if ok and type(n) == "number" then return n end
    end
    if os and os.time then return os.time() end
    return 0
end

function P.install()
    if P.installed or not isClient() or type(TMRadio) ~= "table"
       or type(TMRadioClient) ~= "table" then return end
    if type(TMRadio.PlaySound) ~= "function"
       or type(TMRadioClient.Play) ~= "function"
       or type(TMRadioClient.PlayNext) ~= "function" then return end

    local originalSound = TMRadio.PlaySound
    local originalPlay = TMRadioClient.Play
    local originalNext = TMRadioClient.PlayNext

    TMRadio.PlaySound = function(number, device)
        if not number or not device then return originalSound(number, device) end
        local data = nil
        local ok = pcall(function()
            data = TMRadio.getData(device:getDeviceData())
        end)
        local soundStillPlaying = false
        if ok and data and data.sound and data.sound.isPlaying then
            local good, playing = pcall(function() return data.sound:isPlaying() end)
            soundStillPlaying = good and playing
        end
        if data and data.peRadioSong == number
            and (P.currentSeq == nil or data.peRadioSeq == P.currentSeq)
            and soundStillPlaying then
            return data -- already playing this exact station generation
        end
        local t = originalSound(number, device)
        if t then
            t.peRadioSong = number
            if P.currentSeq then t.peRadioSeq = P.currentSeq end
        end
        return t
    end

    local function withSeq(fn, args)
        local prev = P.currentSeq
        P.currentSeq = args and args.peRadioSeq or nil
        local ok, result = pcall(fn, args)
        P.currentSeq = prev
        if not ok then
            print("[PE-RadioSync] " .. tostring(result))
            return nil
        end
        return result
    end

    TMRadioClient.Play = function(args)
        return withSeq(originalPlay, args)
    end
    TMRadioClient.PlayNext = function(args)
        return withSeq(originalNext, args)
    end

    P.installed = true
    print("[PE-RadioSync] client hooks active (duplicate sound protection)")
end

Events.OnGameStart.Add(P.install)
local tick = 0
Events.OnTick.Add(function()
    if not P.installed then
        tick = tick + 1
        if tick % 120 == 1 then P.install() end
        return
    end
    if not TMRadio or type(TMRadio.soundCache) ~= "table" then return end
    local time = now()
    if time == P.lastScan then return end
    P.lastScan = time
    for _, t in ipairs(TMRadio.soundCache) do
        if t and t.peRadioSeq and t.peRadioSong and t.deviceData
            and t.sound and t.sound.isPlaying then
            local ch = t.deviceData:getChannel()
            if type(ch) == "number" and t.sound:isPlaying()
                and not t.muted
                and time - (P.lastHeartbeat[ch] or 0) >= PERS_Config.heartbeatSeconds then
                P.lastHeartbeat[ch] = time
                sendClientCommand("ProjectEchoRadioSync", "Heartbeat", {
                    channel = ch, number = t.peRadioSong, seq = t.peRadioSeq
                })
            end
        end
    end
end)
