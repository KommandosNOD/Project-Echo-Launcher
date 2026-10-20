-- PROJECT ECHO RV Interior Safety, B42.21 MP, experimental 0.1.0
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
local function onTick()
    if not wrapped then install() end
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
