-- PROJECT ECHO | Street Light Fix v0.1.0 (TEST) | PZ B42.21
-- Client-side visual-only experiment. No world state, switches or network messages touched.
-- Purpose: suppress stray electric streetlight IsoLightSource while the power grid is down.
-- B42.15+ does NOT expose Java instance fields to Lua; identify switches by sprite name.

if isServer and isServer() then return end
if _G.PEStreetLightFixLoaded then return end
_G.PEStreetLightFixLoaded = true

local TAG = "[PE-StreetLightFix] "
local CFG = {
    ENABLED = true,
    SCAN_INTERVAL_MS = 650,
    MAX_DISTANCE = 42,
    MAX_SOURCES_PER_SCAN = 3000,
    DIAGNOSTICS = true,
    MAX_UNKNOWN_LOGS = 12,
}

-- Only outdoor streetlight tile names; never generic indoor lamps or wall switches.
-- Extend this list only after checking an affected tile in console logs.
local SPRITE_PREFIXES = {
    "lighting_outdoor_",
    "streetlight_",
    "streetlamp_",
    "lightpost_",
    "lamppost_",
}

local suppressed = setmetatable({}, { __mode = "k" })
local lastScanMs = 0
local unknownLogged = {}
local unknownCount = 0
local lastReportMs = 0
local totalSuppressed = 0
local warned = false

local function safeBool(fn)
    local ok, value = pcall(fn)
    if ok and type(value) == "boolean" then return value end
    return nil
end

local function isGridDown()
    local world = getWorld and getWorld()
    if not world then return false end
    return safeBool(function() return world:isHydroPowerOn() end) == false
end

local function spriteName(obj)
    local ok, value = pcall(function()
        local sp = obj:getSprite()
        return sp and sp:getName()
    end)
    if ok and value then return string.lower(tostring(value)) end
    return nil
end

local function isStreetTile(name)
    if not name then return false end
    for i = 1, #SPRITE_PREFIXES do
        if string.sub(name, 1, #SPRITE_PREFIXES[i]) == SPRITE_PREFIXES[i] then
            return true
        end
    end
    return false
end

local function logUnknown(name)
    if not CFG.DIAGNOSTICS or not name or unknownCount >= CFG.MAX_UNKNOWN_LOGS then return end
    if unknownLogged[name] then return end
    unknownLogged[name] = true
    unknownCount = unknownCount + 1
    print(TAG .. "nearby light switch sprite (not targeted): " .. name)
end

local function assessSource(light)
    -- Return "unpowered", "powered" or "unknown"; fail closed on unknown power.
    local ok, switches = pcall(function() return light:getSwitches() end)
    if not ok or not switches then return "unknown" end
    local okSize, size = pcall(function() return switches:size() end)
    if not okSize or not size or size < 1 then return "unknown" end

    local matched = false
    for i = 0, size - 1 do
        local okItem, sw = pcall(function() return switches:get(i) end)
        if okItem and sw then
            local isSwitch = (instanceof and instanceof(sw, "IsoLightSwitch")) or false
            if isSwitch then
                local name = spriteName(sw)
                if isStreetTile(name) then
                    matched = true
                    -- Battery lamps should remain untouched, regardless of power state.
                    if safeBool(function() return sw:getUseBattery() end) == true then return "battery" end
                    local okSquare, square = pcall(function() return sw:getSquare() end)
                    if not okSquare or not square then return "unknown" end
                    local hasPower = safeBool(function() return square:haveElectricity() end)
                    if hasPower == nil then return "unknown" end
                    if hasPower then
                        if safeBool(function() return sw:isActivated() end) == true then
                            return "powered"
                        end
                        return "off"
                    end
                else
                    logUnknown(name)
                end
            end
        end
    end
    if matched then return "unpowered" end
    return "unknown"
end

local function runScan()
    if not CFG.ENABLED then return end
    -- The game should handle street lighting normally while mains power is on.
    local down = isGridDown()
    local p = (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer())
    local cell = getCell and getCell()
    if not p or not cell then return end

    local ok, list = pcall(function() return cell:getLamppostPositions() end)
    if not ok or not list then
        if not warned then print(TAG .. "getLamppostPositions unavailable; no changes made") end
        warned = true
        return
    end
    local okSize, count = pcall(function() return list:size() end)
    if not okSize or not count then return end

    local px, py = p:getX(), p:getY()
    local limit2 = CFG.MAX_DISTANCE * CFG.MAX_DISTANCE
    local inspected = 0
    local touched = 0
    local maxSources = math.min(count, CFG.MAX_SOURCES_PER_SCAN)
    for i = 0, maxSources - 1 do
        local okLight, light = pcall(function() return list:get(i) end)
        if okLight and light then
            local okPos, x, y = pcall(function() return light:getX(), light:getY() end)
            if okPos and x and y then
                local dx, dy = x - px, y - py
                if dx * dx + dy * dy <= limit2 then
                    inspected = inspected + 1
                    local previouslySuppressed = suppressed[light] == true
                    if down then
                        local status = assessSource(light)
                        if status == "unpowered" then
                            local lit = safeBool(function() return light:isActive() end)
                            if lit == true then
                                local okOff = pcall(function() light:setActive(false) end)
                                if okOff then
                                    suppressed[light] = true
                                    touched = touched + 1
                                    totalSuppressed = totalSuppressed + 1
                                end
                            end
                        elseif previouslySuppressed then
                            -- Power may have returned from a generator. Never turn an off switch on.
                            if status == "powered" then
                                pcall(function() light:setActive(true) end)
                            end
                            if status ~= "unknown" then suppressed[light] = nil end
                        end
                    elseif previouslySuppressed then
                        -- City grid restored: restore only if the switch is still ON and powered.
                        if assessSource(light) == "powered" then
                            pcall(function() light:setActive(true) end)
                        end
                        suppressed[light] = nil
                    end
                end
            end
        end
    end

    local now = getTimestampMs and getTimestampMs() or 0
    if CFG.DIAGNOSTICS and now - lastReportMs > 30000 then
        print(TAG .. "gridDown=" .. tostring(down) .. " sources=" .. tostring(count)
            .. " near=" .. tostring(inspected) .. " lightsOffThisScan=" .. tostring(touched)
            .. " totalOff=" .. tostring(totalSuppressed))
        lastReportMs = now
    end
end

local function onTick()
    local now = getTimestampMs and getTimestampMs()
    if not now or now - lastScanMs < CFG.SCAN_INTERVAL_MS then return end
    lastScanMs = now
    local ok, err = pcall(runScan)
    if not ok and not warned then
        warned = true
        print(TAG .. "scan failed safely: " .. tostring(err))
    end
end

local function onGameStart()
    suppressed = setmetatable({}, { __mode = "k" })
    lastScanMs, lastReportMs, totalSuppressed = 0, 0, 0
    unknownLogged, unknownCount, warned = {}, 0, false
    print(TAG .. "v0.1.0 active (client-only, grid-sensitive, street-sprite allowlist)")
end

Events.OnGameStart.Add(onGameStart)
Events.OnTick.Add(onTick)
