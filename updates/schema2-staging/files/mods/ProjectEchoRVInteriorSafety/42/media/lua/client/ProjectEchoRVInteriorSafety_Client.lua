-- PROJECT ECHO RV Interior Safety, B42.21 MP, experimental 0.1.0
if isServer() or not isMultiplayer() then return end

local PREFIX = "[PE-RV-Safety][client] "
local function log(s) print(PREFIX .. tostring(s)) end
local wrapped = false
local pending = nil
local CHECK_TICKS = 360 -- keep monitoring ~6 sec at 60 fps
local MAX_UNLOADED = 270 -- return to RV vehicle if we never see a valid floor

local function relocate(player, x, y, z)
    local ok, err = pcall(function()
        player:setX(x); player:setLastX(x)
        player:setY(y); player:setLastY(y)
        player:setZ(z); player:setLastZ(z)
    end)
    if not ok then log("relocate error: " .. tostring(err)) end
    return ok
end
local function safeFloorAt(x, y, z)
    local cell = getCell()
    if not cell then return false end
    local square = cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
    if not square then return false end
    -- If the square is loaded, it should have a walkable floor.
    local solid = false
    pcall(function() solid = (square:isSolidFloor() == true) end)
    if solid then return true end
    local floor = nil
    pcall(function() floor = square:getFloor() end)
    return floor ~= nil
end
local function requestRescue(why)
    if not pending or pending.rescueRequested then return end
    pending.rescueRequested = true
    log("rescue requested: " .. tostring(why))
    sendClientCommand("ProjectEchoRVSafety", "rescue", {reason = tostring(why)})
end
local function install()
    if wrapped or type(RV_TeleportToRoom) ~= "function" then return end
    local original = RV_TeleportToRoom
    RV_TeleportToRoom = function(player, data)
        if not player or not data then return original(player, data) end
        local x = tonumber(data.x) and tonumber(data.offsetX) and (tonumber(data.x) + tonumber(data.offsetX))
        local y = tonumber(data.y) and tonumber(data.offsetY) and (tonumber(data.y) + tonumber(data.offsetY))
        local z = tonumber(data.z)
        if not x or not y or z == nil then
            log("bad teleport coordinates received")
            return requestRescue("bad-destination")
        end
        original(player, data)
        pending = {x=x, y=y, z=z, ticks=0, good=0, bad=0, rescueRequested=false}
        log("RV entry at " .. x .. "," .. y .. "," .. z)
    end
    wrapped = true
    log("hooked original RV_TeleportToRoom")
end
local function onTick()
    if not wrapped then install() end
    if not pending then return end
    local player = getPlayer()
    if not player then return end
    local p = pending
    p.ticks = p.ticks + 1
    if p.rescueRequested then return end
    local dead = false
    pcall(function() dead = player:isDead() end)
    if dead then
        log("player is already dead; safety mechanism too late")
        pending = nil
        return
    end
    local floorOK = safeFloorAt(p.x, p.y, p.z)
    if floorOK then
        p.good = p.good + 1
        p.bad = 0
    else
        p.bad = p.bad + 1
        p.good = 0
    end
    -- When the chunk has not arrived, keep correcting downward displacement.
    -- The original module does a one-frame teleport; in Viewpoint the 3D
    -- physics may apply gravity before the target floor has finished loading.
    local currentZ = player:getZ()
    if p.ticks <= 240 and currentZ ~= nil and currentZ < (p.z - 0.15) then
        relocate(player, p.x, p.y, p.z)
        log("corrected Z drop while RV floor streamed")
    end
    if p.bad > MAX_UNLOADED then
        requestRescue("floor-not-loaded")
        return
    end
    -- Permit time for streamed chunks and 3D collisions to settle.
    if p.ticks >= CHECK_TICKS then
        if p.good >= 30 and floorOK then
            log("RV floor validated, restoring normal damage rules")
            sendClientCommand("ProjectEchoRVSafety", "arrived", {})
            pending = nil
        else
            requestRescue("floor-not-stable")
        end
    end
end
local function onServerCommand(module, command, args)
    if module ~= "ProjectEchoRVSafety" or command ~= "returnToOrigin" then return end
    local player = getPlayer()
    pending = nil
    if not player or not args then return end
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if x and y and z then
        relocate(player, x, y, z)
        log("returned to car after invalid RV arrival")
        pcall(function() player:Say("RV teleport failed - returned safely.") end)
    end
end
Events.OnTick.Add(onTick)
Events.OnServerCommand.Add(onServerCommand)
install()
