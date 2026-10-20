-- PROJECT ECHO / Firearm Visual Refresh v0.2.0 (diagnostic test)
-- PZ B42.21 / Viewpoint. Client-only. Does not modify weapon stats, inventory,
-- aim calculations, ammunition, damage, or equip/unequip hands.
-- v0.2.0: restrict to firearms, and detect weapon changes while already in 3D.
-- This does NOT patch any proprietary Java rendering hooks (ADS/STT).

local PREFIX = "[PE WeaponVisualFix] "
local frame = 0
local previousWeapon = nil
local scheduled = {}  -- target frame -> reason
local SCAN_TICKS = 12

local function localPlayer()
    if not getPlayer then return nil end
    local ok, obj = pcall(getPlayer)
    if ok then return obj end
    return nil
end

local function getGun(player)
    if not player then return nil end
    local ok, item = pcall(function() return player:getPrimaryHandItem() end)
    if not ok or not item then return nil end

    local isWeapon = false
    if instanceof then
        local good, yes = pcall(instanceof, item, "HandWeapon")
        if good then isWeapon = (yes == true) end
    end
    if not isWeapon then return nil end

    local good, ranged = pcall(function() return item:isRanged() end)
    if good and ranged then return item end
    -- Fallback for modded guns that expose an ammunition type but no isRanged.
    local got, ammo = pcall(function() return item:getAmmoType() end)
    if got and ammo and tostring(ammo) ~= "" and tostring(ammo) ~= "none" then
        return item
    end
    return nil
end

local function gunName(item)
    if not item then return "none" end
    local ok, value = pcall(function() return item:getFullType() end)
    if ok and value then return tostring(value) end
    return "unknown"
end

local function refresh(reason)
    local player = localPlayer()
    local item = getGun(player)
    if not item then
        print(PREFIX .. "SKIP (no firearm); reason=" .. reason)
        return
    end
    local a, errA = pcall(function() player:resetEquippedHandsModels() end)
    local b, errB = pcall(function() player:resetModelNextFrame() end)
    print(PREFIX .. "REFRESH reason=" .. reason .. " item=" .. gunName(item) ..
        " hands=" .. tostring(a) .. " model=" .. tostring(b))
    if not a then print(PREFIX .. "ERROR hands=" .. tostring(errA)) end
    if not b then print(PREFIX .. "ERROR model=" .. tostring(errB)) end
end

local function schedule(reason)
    -- Give Viewpoint/ADS time to settle before resetting visible hand model.
    scheduled = {
        { at = frame + 10, reason = reason .. "/10" },
        { at = frame + 38, reason = reason .. "/38" }
    }
    print(PREFIX .. "SCHEDULE reason=" .. reason)
end

local function keyIs(key, name, fallback)
    if Keyboard and Keyboard[name] ~= nil then return key == Keyboard[name] end
    return key == fallback
end

local function onKeyPressed(key)
    if keyIs(key, "KEY_F10", 68) then
        scheduled = {}
        refresh("manual-F10")
    elseif keyIs(key, "KEY_O", 24) then
        if getGun(localPlayer()) then schedule("viewpoint-key-O") end
    end
end

local function onTick()
    frame = frame + 1
    if frame % SCAN_TICKS == 0 then
        local gun = getGun(localPlayer())
        if gun ~= previousWeapon then
            previousWeapon = gun
            if gun then schedule("firearm-equipped-" .. gunName(gun)) end
        end
    end
    if #scheduled > 0 then
        local done = {}
        local outstanding = {}
        for _, task in ipairs(scheduled) do
            if task.at <= frame then
                done[#done + 1] = task.reason
            else
                outstanding[#outstanding + 1] = task
            end
        end
        scheduled = outstanding
        for _, reason in ipairs(done) do refresh(reason) end
    end
end

if Events and Events.OnKeyPressed and Events.OnTick then
    Events.OnKeyPressed.Add(onKeyPressed)
    Events.OnTick.Add(onTick)
    print(PREFIX .. "Loaded v0.2.0; F10=manual test, O=refresh, equip=refresh")
else
    print(PREFIX .. "ERROR: missing OnTick / OnKeyPressed event")
end
