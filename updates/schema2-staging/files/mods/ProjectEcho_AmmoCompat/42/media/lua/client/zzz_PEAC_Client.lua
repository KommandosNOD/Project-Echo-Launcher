-- Context-menu and reload hotkey adapter (client only).
local C = require("PEAC_Registry")
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISReloadWeaponAction"
require "TimedActions/ISLoadBulletsInMagazine"
require "TimedActions/ISInsertMagazine"
require "TimedActions/ISEjectMagazine"
if not C.UI_INSTALLED then
    C.UI_INSTALLED = true
    local UI = ISInventoryPaneContextMenu

    local function queueMag(player, mag, key)
        local inv = player:getInventory()
        if not C.canUseAlias(mag, key) or inv:getCountTypeRecurse(key) <= 0 then return 0 end
        local amount = UI.transferBullets(player, key, mag:getCurrentAmmoCount(), mag:getMaxAmmo())
        if amount <= 0 then return 0 end
        UI.transferIfNeeded(player, mag)
        ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(player, mag, mag:getCurrentAmmoCount() + amount))
        return amount
    end

    local originalMagazineMenu = UI.doMagazineMenu
    UI.doMagazineMenu = function(player, mag, context, ...)
        originalMagazineMenu(player, mag, context, ...)
        if not mag or mag:getCurrentAmmoCount() >= mag:getMaxAmmo() then return end
        local key = C.choose(mag, player:getInventory())
        if not key then return end
        context:addOption("PROJECT ECHO: Load compatible " .. key,
            player, queueMag, mag, key)
    end

    local originalBulletMenu = UI.doBulletMenu
    UI.doBulletMenu = function(player, gun, context, ...)
        originalBulletMenu(player, gun, context, ...)
        if not C.isSafeInternalGun(gun) then return end
        local keys = C.availableAliases(gun, player:getInventory())
        for _, key in ipairs(keys) do
            local label
            if C.isGuns93Shotgun(gun) then
                label = "PROJECT ECHO: 12ga " .. ((C.ammoKey(gun) == "Base.SlugBullets")
                    and "SLUG" or "BUCKSHOT") .. " - " .. key
            else
                -- Works for internal rifles, revolvers, tube-fed shotguns,
                -- break-action guns and other standard non-detachable loaders.
                label = "PROJECT ECHO: Load compatible " .. key
            end
            context:addOption(label, player, function(pl, wp, ammo)
                if not C.canUseAlias(wp, ammo) then return end
                local inv = pl:getInventory()
                if inv:getCountTypeRecurse(ammo) <= 0 then return end
                local moved = UI.transferBullets(pl, ammo,
                    wp:getCurrentAmmoCount(), wp:getMaxAmmo())
                if moved <= 0 then return end
                UI.equipWeapon(wp, true, false, pl:getPlayerNum())
                C.log("manual internal reload: " .. tostring(wp:getFullType())
                    .. " <- " .. tostring(ammo))
                ISTimedActionQueue.add(ISReloadWeaponAction:new(pl, wp, nil, ammo))
            end, gun, key)
        end
    end

    -- Last-loaded UI module wraps Gunworks' BeginAutomaticReload rather than
    -- replacing its implementation for Gunworks-registered guns.
    local originalAuto = ISReloadWeaponAction.BeginAutomaticReload
    ISReloadWeaponAction.BeginAutomaticReload = function(player, gun, ...)
        if not player or not gun or C.isGunworks(gun) then
            return originalAuto(player, gun, ...)
        end
        local inv = player:getInventory()
        if C.isSafeInternalGun(gun) and not gun:isJammed()
            and gun:getCurrentAmmoCount() < gun:getMaxAmmo() then
            local key = C.choose(gun, inv)
            if key then
                local amount = UI.transferBullets(player, key, gun:getCurrentAmmoCount(), gun:getMaxAmmo())
                if amount > 0 then
                    if C.isGuns93Shotgun(gun) then
                        C.log("Guns93 R reload request " .. tostring(gun:getFullType()) .. " <- " .. tostring(key))
                    end
                    ISTimedActionQueue.add(ISReloadWeaponAction:new(player, gun, nil, key))
                    return
                end
            end
        elseif gun:getMagazineType() and not gun:isContainsClip() then
            local mag = gun:getBestMagazine(player)
            if mag and mag:getCurrentAmmoCount() == 0 then
                local key = C.choose(mag, inv)
                if key and queueMag(player, mag, key) > 0 then
                    ISTimedActionQueue.add(ISInsertMagazine:new(player, gun, mag))
                    return
                end
            end
        end
        return originalAuto(player, gun, ...)
    end

    -- Vanilla queued reload after ejecting an empty magazine.
    local originalReloadBest = ISReloadWeaponAction.ReloadBestMagazine
    ISReloadWeaponAction.ReloadBestMagazine = function(player, gun, ...)
        if not C.isGunworks(gun) then
            local mag = gun:getBestMagazine(player)
            if mag and mag:getCurrentAmmoCount() == 0 then
                local key = C.choose(mag, player:getInventory())
                if key and queueMag(player, mag, key) > 0 then
                    ISTimedActionQueue.add(ISInsertMagazine:new(player, gun, mag))
                    return
                end
            end
        end
        return originalReloadBest(player, gun, ...)
    end
    C.log("client reload/context menu hooks installed")
end
