-- PROJECT ECHO RV Interior Safety, B42.21 MP, v0.2.0 TEST
-- Companion patch; never overwrite the original RV mod.
if isClient() or not isMultiplayer() then return end

local PREFIX = "[PE-RV-Safety][server] "
local active = {}  -- server-side only, keyed by IsoPlayer
local oldEntry = nil
local wrapped = false
local MAX_TICKS = 1050 -- approx 17.5s at 60 ticks/sec; fail closed
local function log(s) print(PREFIX .. tostring(s)) end

local function getGod(player)
    local ok, value = pcall(function() return player:isGodMod() end)
    if not ok then return nil end
    return value == true
end
local function setGod(player, value)
    return pcall(function() player:setGodMod(value) end)
end
local function place(player, x, y, z)
    local ok, err = pcall(function()
        player:setX(x); player:setLastX(x)
        player:setY(y); player:setLastY(y)
        player:setZ(z); player:setLastZ(z)
    end)
    if not ok then log("server place failed: " .. tostring(err)) end
    return ok
end
local function forgetRoom(player)
    pcall(function()
        local pmd = player:getModData()
        if pmd and pmd.projectRV_playerId then
            local rv = ModData.getOrCreate("modPROJECTRVInterior")
            if rv and rv.Players then
                rv.Players[pmd.projectRV_playerId] = nil
            end
        end
    end)
end
local function finish(player, state, reason)
    if active[player] ~= state then return end
    active[player] = nil
    if state.changedGod then
        local ok = setGod(player, state.hadGod)
        if not ok then log("WARN: cannot restore GodMode for " .. tostring(state.name)) end
    end
    log("end " .. tostring(state.name) .. " reason=" .. tostring(reason))
end
local function rescue(player, state, reason)
    if not player or not state or active[player] ~= state then return end
    if state.recovering then return end
    state.recovering = true
    state.recoveryTicks = 0
    log("RESCUE " .. tostring(state.name) .. " reason=" .. tostring(reason))
    forgetRoom(player)
    -- Apply on both sides: multiplayer client and server must agree on coordinates.
    sendServerCommand(player, "ProjectEchoRVSafety", "returnToOrigin", {
        x = state.x, y = state.y, z = state.z
    })
    place(player, state.x, state.y, state.z)
    -- Keep invulnerability briefly until client has actually received rescue.
    state.rescueReason = reason
end

local function install()
    if wrapped then return end
    if type(GetInToRV) ~= "function" then return end
    oldEntry = GetInToRV
    GetInToRV = function(player, vehicle)
        if not player or not vehicle then return oldEntry(player, vehicle) end
        if active[player] then rescue(player, active[player], "new-entry-before-ack") end
        local old = getGod(player)
        if old == nil then
            log("BLOCK entry; cannot read GodMode (unsafe to teleport)")
            return
        end
        local state = {
            x = player:getX(), y = player:getY(), z = player:getZ(),
            hadGod = old, changedGod = not old,
            name = tostring(player:getUsername()), ticks = 0
        }
        -- Server-authoritative brief invulnerability avoids irreversible fall death.
        if state.changedGod and not setGod(player, true) then
            log("BLOCK entry; cannot provide temporary anti-fall protection")
            return
        end
        active[player] = state
        log("start " .. state.name .. " origin=" .. tostring(state.x) .. "," .. tostring(state.y) .. "," .. tostring(state.z))
        local ok, err = pcall(oldEntry, player, vehicle)
        if not ok then
            log("base GetInToRV failed: " .. tostring(err))
            rescue(player, state, "base-entry-exception")
            return
        end
        -- The RV mod may reject an entry (no free room, unsupported car).
        -- Don't leave the player in protected mode in that case.
        local gotRoom, hasRoom = pcall(function()
            local pmd = player:getModData()
            local rv = ModData.getOrCreate("modPROJECTRVInterior")
            local id = pmd and pmd.projectRV_playerId
            return id and rv and rv.Players and rv.Players[id]
                and rv.Players[id].ActualRoom ~= nil
        end)
        if gotRoom and not hasRoom then
            finish(player, state, "base-entry-declined")
        end
    end
    wrapped = true
    log("hooked original GetInToRV")
end

-- v0.2.0: RV exit recovery inside SAME safety mod. No separate Mod ID.
local nativeExitWrapped = false
local exitCooldown = {}
local exitTicks = 0
local rvTypes = nil

local function isFinite(n)
    return type(n) == "number" and n == n and n > -1e9 and n < 1e9
end
local function isInsideInterior(player)
    if not player then return false end
    local x, y = tonumber(player:getX()), tonumber(player:getY())
    return isFinite(x) and isFinite(y) and x > 22500 and y > 12000
end
local function reportExit(player, result, reason)
    log("EXIT " .. tostring(player and player:getUsername()) .. " status=" .. tostring(result) .. " reason=" .. tostring(reason))
    if player then
        sendServerCommand(player, "ProjectEchoRVSafety", "exitStatus", {
            result=tostring(result), reason=tostring(reason)
        })
    end
end
local function getTypes()
    if rvTypes then return rvTypes end
    local ok, data = pcall(require, "RVVehicleTypes")
    if ok and data and type(data.VehicleTypes) == "table" then
        rvTypes = data.VehicleTypes
    end
    return rvTypes
end
local function validVehiclePos(md, id)
    if not id or not md or type(md.Vehicles) ~= "table" then return false end
    local pos = md.Vehicles[id] or md.Vehicles[tostring(id)]
    if not pos then return false end
    local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z)
    if not isFinite(x) or not isFinite(y) or not isFinite(z) then return false end
    -- Do not return into another virtual RV interior.
    if x < 0 or y < 0 or z < -1 or z > 32 or (x > 22500 and y > 12000) then return false end
    return true
end
local function recordValid(md, record, types)
    return type(record) == "table" and record.ActualRoom ~= nil
        and record.VehicleId ~= nil
        and record.RoomType ~= nil and types[record.RoomType] ~= nil
        and validVehiclePos(md, record.VehicleId)
end
local function findUniqueRoom(player, md, types)
    local x, y, z = tonumber(player:getX()), tonumber(player:getY()), tonumber(player:getZ())
    if not isFinite(x) or not isFinite(y) or not isFinite(z) then
        return nil, "invalid-player-position"
    end
    local count, found = 0, nil
    for typeKey, def in pairs(types) do
        if type(def) == "table" then
            local key = typeKey == "normal" and "AssignedRooms" or ("AssignedRooms" .. tostring(typeKey))
            local assigned = md[key]
            if type(assigned) == "table" then
                for vehicleId, room in pairs(assigned) do
                    local rx, ry, rz = room and tonumber(room.x), room and tonumber(room.y), room and tonumber(room.z)
                    local w, h = math.abs(tonumber(def.roomWidth) or 2), math.abs(tonumber(def.roomHeight) or 3)
                    if isFinite(rx) and isFinite(ry) and isFinite(rz)
                       and z == rz and x >= rx - 1 and x <= rx + w + 1
                       and y >= ry - 1 and y <= ry + h + 1
                       and validVehiclePos(md, vehicleId) then
                        count = count + 1
                        found = { ActualRoom=room, VehicleId=vehicleId, Seat=-1, RoomType=typeKey }
                    end
                end
            end
        end
    end
    if count == 1 then return found, "unique-assigned-room" end
    if count == 0 then return nil, "no-unique-room-or-vehicle-position" end
    return nil, "ambiguous-room-matches-" .. tostring(count)
end
local function guardedExit(player, nativeExit)
    if not player or not isInsideInterior(player) then
        reportExit(player, "declined", "not-in-interior")
        return
    end
    local types = getTypes()
    if not types then reportExit(player, "declined", "RVVehicleTypes-not-loaded"); return end
    local md = ModData.getOrCreate("modPROJECTRVInterior")
    local pmd = player:getModData()
    if not md or not pmd then
        reportExit(player, "declined", "RV-moddata-missing")
        return
    end
    local id = pmd.projectRV_playerId
    local record = id and md.Players and md.Players[id]
    local didRestore = false
    if not recordValid(md, record, types) then
        -- Original RV code silently returns on a missing mapping. Do not teleport
        -- blindly: recover only from ONE assigned room with a valid parked vehicle.
        local candidate, why = findUniqueRoom(player, md, types)
        if not candidate then
            reportExit(player, "declined", "missing-or-stale-link;" .. tostring(why))
            return
        end
        md.Players = md.Players or {}
        if not id then
            for attempt=1,20 do
                local proposed = tostring(ZombRand(1,99999999))
                if not md.Players[proposed] then id=proposed; break end
            end
            if not id then reportExit(player, "declined", "cannot-generate-player-id"); return end
            pmd.projectRV_playerId = id
        end
        md.Players[id] = candidate
        record = candidate
        didRestore = true
        log("EXIT recovered RV link for " .. tostring(player:getUsername()) .. " vehicle=" .. tostring(candidate.VehicleId))
    end
    -- At this point original GetOutFromRV cannot clear ActualRoom and THEN
    -- bail out merely due to missing stored vehicle coordinates.
    local ok, err = pcall(nativeExit, player)
    if not ok then
        reportExit(player, "error", "native-exit-exception:" .. tostring(err))
        return
    end
    if active[player] then
        finish(player, active[player], "exit-request-processed")
    end
    reportExit(player, "native-exit-invoked", didRestore and "recovered-room-link" or "existing-room-link")
end
local function installNativeExit()
    if nativeExitWrapped then return end
    if not RVServer or type(RVServer.GetOutFromRV) ~= "function" then return end
    local original = RVServer.GetOutFromRV
    RVServer.GetOutFromRV = function(player)
        return guardedExit(player, original)
    end
    nativeExitWrapped = true
    log("v0.2.0 hooked original RVServer.GetOutFromRV; entry safety active")
end

local function onTick()
    if not wrapped then install() end
    if not nativeExitWrapped then installNativeExit() end
    exitTicks = exitTicks + 1
    for player, state in pairs(active) do
        state.ticks = state.ticks + 1
        if state.recovering then
            state.recoveryTicks = (state.recoveryTicks or 0) + 1
            if state.recoveryTicks >= 180 then
                finish(player, state, "rescue:" .. tostring(state.rescueReason))
            end
        elseif state.ticks >= MAX_TICKS then
            rescue(player, state, "server-timeout")
        end
    end
end
local function onClientCommand(module, command, player, args)
    if module ~= "ProjectEchoRVSafety" or not player then return end
    if command == "requestExit" then
        -- Cooldown only applies to fallback, not to the base RV context menu.
        if exitCooldown[player] and exitTicks - exitCooldown[player] < 150 then
            reportExit(player, "declined", "exit-cooldown")
            return
        end
        exitCooldown[player] = exitTicks
        if not nativeExitWrapped then installNativeExit() end
        if not nativeExitWrapped then
            reportExit(player, "declined", "native-RVServer-not-loaded")
            return
        end
        RVServer.GetOutFromRV(player)
        return
    elseif command == "exitAck" then
        log("EXIT ACK from " .. tostring(player:getUsername()))
        return
    end
    local state = active[player]
    if not state then return end
    if command == "arrived" and not state.recovering then
        -- Only client can see the streamed floor. Trust only that player's active transition.
        finish(player, state, "client-validated-floor")
    elseif command == "rescue" then
        rescue(player, state, args and args.reason or "client-reported-danger")
    end
end
Events.OnTick.Add(onTick)
Events.OnClientCommand.Add(onClientCommand)
install()

installNativeExit()
log("v0.2.0 server: original RV entry safety + guarded native exit installed")
