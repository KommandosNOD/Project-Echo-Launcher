-- PROJECT ECHO Admin Commands v0.1.2 / Build 42.21 Multiplayer
-- All privileges checked SERVER SIDE with the actual OnClientCommand player object.
-- Never executes arbitrary client-provided Lua or arbitrary vanilla admin commands.
require "ProjectEchoAdminCommands/PEAC_ServerConfig"

local PREFIX = "[PE-AdminCmd] "
local MODULE = "ProjectEchoAdminCommands"
local lastCallByName = {}
local config = ProjectEchoAdminCommandsConfig or {}

local function log(message)
    print(PREFIX .. tostring(message))
end
local function reply(player, text, bad)
    if player then
        sendServerCommand(player, MODULE, "result", {text = tostring(text or ""), bad = bad == true})
    end
end
local function txt(v)
    if v == nil then return "" end
    return tostring(v)
end
local function trim(s)
    return (txt(s):gsub("^%s+", ""):gsub("%s+$", ""))
end
local function ownerAuthorized(player)
    if not player then return false, "No authenticated player." end
    local name = txt(player:getUsername())
    local expected = config.Owners and config.Owners[name] or nil
    if expected == nil then return false, "Access denied." end
    expected = trim(expected)
    if expected == "" and config.RequireSteamID == true then
        return false, "Owner SteamID64 is not configured on server."
    end
    if expected ~= "" then
        if not expected:match("^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            return false, "Invalid owner SteamID64 in server config."
        end
        -- The username is server-authenticated, the Steam ID is resolved server-side.
        local ok, steamId = pcall(function() return getSteamIDFromUsername(name) end)
        if (not ok) or steamId == nil or txt(steamId) ~= expected then
            return false, "SteamID64 check failed."
        end
    end
    return true, name
end
local function getPlayers()
    local ok, ps = pcall(function() return GameServer.getPlayers() end)
    if ok and ps then return ps end
    local ok2, fallback = pcall(function() return getOnlinePlayers() end)
    if ok2 then return fallback end
    return nil
end
local function findOnline(name)
    name = trim(name)
    if name == "" then return nil end
    local ps = getPlayers()
    if not ps then return nil end
    for i = 0, ps:size() - 1 do
        local p = ps:get(i)
        if p and txt(p:getUsername()):lower() == name:lower() then return p end
    end
    return nil
end
local function getPosition(p)
    return math.floor(p:getX() * 10) / 10, math.floor(p:getY() * 10) / 10, math.floor(p:getZ() * 10) / 10
end
local function moveToPlayer(moved, destination)
    if not moved or not destination then return false, "Player not online." end
    if moved == destination then return false, "Already at this player." end
    if moved:isDead() or destination:isDead() then return false, "Player is dead." end
    if moved:getVehicle() or destination:getVehicle() then
        return false, "Exit vehicles before teleport."
    end
    local x, y, z = destination:getX(), destination:getY(), destination:getZ()
    if z < -32 or z > 31 then return false, "Invalid destination Z." end
    -- Restrict to a position around an actual online player. Check loaded world square;
    -- never teleport to arbitrary untrusted coordinates, an unloaded room, or an empty floor.
    local okSq, sq = pcall(function()
        return getCell():getGridSquare(math.floor(x), math.floor(y), math.floor(z))
    end)
    if not okSq or not sq then return false, "Destination square is not loaded." end
    local floorOk = false
    pcall(function() floorOk = (sq:isSolidFloor() == true) end)
    if not floorOk then pcall(function() floorOk = (sq:getFloor() ~= nil) end) end
    if not floorOk then return false, "No confirmed floor at destination (3D safety)." end
    if not GameServer or not GameServer.sendTeleport then
        return false, "GameServer.sendTeleport is unavailable on this build."
    end
    local ok, err = pcall(function() GameServer.sendTeleport(moved, x, y, z) end)
    if not ok then return false, "Server teleport failed: " .. txt(err) end
    return true, "Teleport sent to " .. txt(moved:getUsername()) .. "."
end
local function healTarget(target)
    if not target or target:isDead() then return false, "Player is dead or offline." end
    local ok, err = pcall(function()
        target:getBodyDamage():RestoreToFullHealth()
        -- Heal the controlling client as well; the same command originates from the server.
        sendServerCommand(target, MODULE, "healLocal", {})
    end)
    if not ok then return false, "Heal failed: " .. txt(err) end
    return true, "Healed " .. txt(target:getUsername()) .. "."
end
local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= "run" then return end
    if not player then return end
    local good, usernameOrReason = ownerAuthorized(player)
    local senderName = txt(player:getUsername())
    if not good then
        log("DENY " .. senderName .. ": " .. usernameOrReason)
        reply(player, usernameOrReason, true)
        return
    end
    -- Rate-limit even an owner; no resource-intensive commands in this mod.
    local now = 0
    pcall(function() now = getTimestampMs() end)
    if now == 0 then pcall(function() now = os.time() * 1000 end) end
    local before = lastCallByName[senderName] or -9999999
    if now > 0 and (now - before) < (config.CooldownMilliseconds or 750) then
        reply(player, "Slow down (0.75 second between commands).", true)
        return
    end
    lastCallByName[senderName] = now
    local line = args and args.line or ""
    if type(line) ~= "string" or #line > 160 then
        reply(player, "Invalid command size.", true)
        return
    end
    local cmd, rest = line:match("^%s*(%S+)%s*(.-)%s*$")
    cmd, rest = txt(cmd):lower(), trim(rest)
    if cmd == "" or cmd == "help" then
        reply(player, table.concat({
            "PROJECT ECHO ADMIN COMMANDS:",
            "/pe help - command list",
            "/pe players - online users",
            "/pe where - your coordinates",
            "/pe heal [NAME] - restore health",
            "/pe tp NAME - teleport to player",
            "/pe bring NAME - summon player",
            "/pe invisible [on|off|status] - zombie invisibility",
            "/pe invisible - toggle invisibility"
        }, "\n"))
        return
    end
    if cmd == "invisible" then
        -- Own player only; never accept a target or arbitrary server command.
        if config.AllowInvisible == false then
            reply(player, "Invisible command disabled by server.", true)
            return
        end
        if rest ~= "" and rest ~= "on" and rest ~= "off" and rest ~= "status" then
            reply(player, "Usage: /pe invisible [on|off|status]", true)
            return
        end
        local got, active = pcall(function() return player:isInvisible() end)
        if not got or type(active) ~= "boolean" then
            reply(player, "Cannot read current invisibility on this build.", true)
            return
        end
        if rest == "status" then
            reply(player, "Invisible to zombies: " .. (active and "ON" or "OFF"))
            return
        end
        local enabled = (rest == "on") or (rest == "" and not active)
        local okSet, errSet = pcall(function() player:setInvisible(enabled) end)
        if not okSet then
            reply(player, "Invisible operation failed: " .. txt(errSet), true)
            log("FAIL " .. senderName .. " /pe invisible -> " .. txt(errSet))
            return
        end
        -- Sync the actor client as well; no god mode or debug/admin role change.
        sendServerCommand(player, MODULE, "invisibleLocal", {enabled = enabled})
        log("OK " .. senderName .. " /pe invisible " .. (enabled and "on" or "off"))
        reply(player, "Invisible to zombies: " .. (enabled and "ON" or "OFF"))
        return
    end
    if cmd == "players" then
        local ps = getPlayers()
        if not ps then reply(player, "Player list unavailable.", true); return end
        local names = {}
        for i = 0, math.min(ps:size() - 1, 30) do
            local p = ps:get(i)
            if p then table.insert(names, txt(p:getUsername())) end
        end
        reply(player, "Players (" .. tostring(ps:size()) .. "): " .. table.concat(names, ", "))
        return
    end
    if cmd == "where" then
        local x, y, z = getPosition(player)
        reply(player, "Your XYZ: " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))
        return
    end
    if cmd == "tp" or cmd == "bring" then
        if config.AllowTeleport ~= true then reply(player, "Teleport disabled by server.", true); return end
        if rest == "" or #rest > 40 then reply(player, "Usage: /pe " .. cmd .. " PLAYER_NAME", true); return end
        local target = findOnline(rest)
        if not target then reply(player, "Player not found: " .. rest, true); return end
        local actor, destination = player, target
        if cmd == "bring" then actor, destination = target, player end
        local ok, result = moveToPlayer(actor, destination)
        log((ok and "OK " or "FAIL ") .. senderName .. " /pe " .. cmd .. " " .. rest .. " -> " .. result)
        reply(player, result, not ok)
        if ok and cmd == "bring" then reply(target, "You were moved to " .. senderName .. ".") end
        return
    end
    if cmd == "heal" then
        local target = player
        if rest ~= "" then
            if config.AllowRemoteHeal ~= true then reply(player, "Remote heal disabled.", true); return end
            target = findOnline(rest)
            if not target then reply(player, "Player not found: " .. rest, true); return end
        end
        local ok, result = healTarget(target)
        log((ok and "OK " or "FAIL ") .. senderName .. " /pe heal " .. txt(target and target:getUsername()) .. " -> " .. result)
        reply(player, result, not ok)
        return
    end
    reply(player, "Unknown /pe command. Type /pe help.", true)
end
Events.OnClientCommand.Add(onClientCommand)
log("v0.1.2 ready; server-authorized invisible available")
