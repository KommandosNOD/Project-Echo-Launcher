-- PROJECT ECHO RV Interior Safety, B42.21 MP, v0.2.0 TEST
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
local waitingExit = false
local exitTicks = 0
local inputTicks = 0
local lastExitTick = -10000

local function inInterior(player)
    if not player then return false end
    local x, y = tonumber(player:getX()), tonumber(player:getY())
    return x ~= nil and y ~= nil and x > 22500 and y > 12000
end

local function requestExit(source)
    local player = getPlayer()
    if not inInterior(player) then
        log("exit declined locally: outside RV interior")
        return
    end
    if inputTicks - lastExitTick < 180 then
        log("exit request cooling down")
        return
    end
    lastExitTick = inputTicks
    waitingExit, exitTicks = true, 0
    log("exit requested source=" .. tostring(source) .. " pos=" .. tostring(player:getX()) .. "," .. tostring(player:getY()) .. "," .. tostring(player:getZ()))
    sendClientCommand("ProjectEchoRVSafety", "requestExit", {})
end

local function onExitKey(key)
    if not Keyboard or key ~= Keyboard.KEY_F9 or type(isKeyDown) ~= "function" then return end
    local ctrl = (Keyboard.KEY_LCONTROL and isKeyDown(Keyboard.KEY_LCONTROL)) or
                 (Keyboard.KEY_RCONTROL and isKeyDown(Keyboard.KEY_RCONTROL))
    local shift = (Keyboard.KEY_LSHIFT and isKeyDown(Keyboard.KEY_LSHIFT)) or
                  (Keyboard.KEY_RSHIFT and isKeyDown(Keyboard.KEY_RSHIFT))
    if ctrl and shift then requestExit("Ctrl+Shift+F9") end
end

local function onExitContext(playerIndex, context, worldObjects)
    local player = getSpecificPlayer(playerIndex)
    if not context or not inInterior(player) then return end
    -- Fallback beside the original menu item. No changes to PROJECTRVInterior42.
    local name = "Exit RV [PROJECT ECHO safety]"
    pcall(function()
        local trans = getText("ContextMenu_GetOutFromRV")
        if trans and trans ~= "ContextMenu_GetOutFromRV" then
            name = trans .. " [PROJECT ECHO safety]"
        end
    end)
    context:addOption(name, player, function() requestExit("context-menu") end)
end

local function onExitTick()
    inputTicks = inputTicks + 1
    if not waitingExit then return end
    local player = getPlayer()
    if player and not inInterior(player) then
        waitingExit = false
        pending = nil
        log("EXIT SUCCESS: player observed outside RV interior")
        sendClientCommand("ProjectEchoRVSafety", "exitAck", {})
        return
    end
    exitTicks = exitTicks + 1
    if exitTicks >= 600 then
        waitingExit = false
        log("EXIT TIMEOUT: still inside after 600 ticks; see server exitStatus reason")
    end
end

local function onServerCommand(module, command, args)
    if module == "RVClient" and command == "teleportToVehicle" then
        -- This packet belongs to PROJECTRVInterior42; do not teleport ourselves.
        pending = nil
        log("native RV exit packet received; destination=" .. tostring(args and args.x) .. "," .. tostring(args and args.y) .. "," .. tostring(args and args.z))
        return
    end
    if module == "ProjectEchoRVSafety" and command == "exitStatus" then
        log("exit status=" .. tostring(args and args.result) .. " reason=" .. tostring(args and args.reason))
        return
    end
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

Events.OnKeyPressed.Add(onExitKey)
Events.OnFillWorldObjectContextMenu.Add(onExitContext)
Events.OnTick.Add(onExitTick)
log("v0.2.0 exit fallback ready (Ctrl+Shift+F9); entry anti-fall preserved")
