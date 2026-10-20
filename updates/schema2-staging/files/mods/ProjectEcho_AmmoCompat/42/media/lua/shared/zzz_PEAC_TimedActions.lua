-- Native B42.21 TimedAction layer: direct consumption of equivalent ammunition
-- in vanilla/PSA/Guns93 magazines and internal-magazine weapons. Server and
-- client BOTH need this module. Never patch a Gunworks-registered weapon.
local C = require("PEAC_Registry")
require "TimedActions/ISReloadWeaponAction"
require "TimedActions/ISLoadBulletsInMagazine"
require "TimedActions/ISUnloadBulletsFromMagazine"
require "TimedActions/ISUnloadBulletsFromFirearm"
require "TimedActions/ISRackFirearm"
require "TimedActions/ISInsertMagazine"
require "TimedActions/ISEjectMagazine"

if not C.TIMED_HOOKS then
    C.TIMED_HOOKS = true
    local baseGunInit = ISReloadWeaponAction.initVars
    function ISReloadWeaponAction:initVars(...)
        baseGunInit(self, ...)
        local gun, inv = self.gun, self.character and self.character:getInventory()
        if not gun or not inv or not C.isSafeInternalGun(gun) then return end
        local recorded = C.getLoadedAlias(gun)
        local chosen = C.choose(gun, inv)
        local requested = self.ammoTypeOverride
        if requested then
            -- Client-side requested bullet types are NEVER blindly trusted on the server.
            -- No buckshot in slug configuration, no different type atop loaded ammo.
            if not C.canUseAlias(gun, requested) then
                self.bullets, self.ammoCount = nil, nil
                if C.isGuns93Shotgun(gun) then
                    C.log("Guns93 rejected incompatible reload request: " .. tostring(requested))
                end
                return
            end
            chosen = requested
        end
        if recorded and not chosen then
            self.bullets, self.ammoCount = nil, nil
            return
        end
        if not chosen then return end
        if not C.canUseAlias(gun, chosen) then
            self.bullets, self.ammoCount = nil, nil
            return
        end
        local capacity = gun:getMaxAmmo() - gun:getCurrentAmmoCount()
        local count = math.min(capacity, inv:getItemCountRecurse(chosen))
        local bullets = count > 0 and inv:getSomeTypeRecurse(chosen, count) or nil
        if bullets and not bullets:isEmpty() then
            self.bullets, self.ammoCount = bullets, count
            self.pecAmmoKey = chosen
            if C.isGuns93Shotgun(gun) then
                C.log("Guns93 validated reload: " .. tostring(gun:getFullType())
                    .. " ammo=" .. tostring(chosen) .. " rounds=" .. tostring(count))
            end
        end
    end

    local baseGunLoad = ISReloadWeaponAction.loadAmmo
    function ISReloadWeaponAction:loadAmmo(...)
        local bulletType
        if self.bullets and not self.bullets:isEmpty() then
            local bullet = self.bullets:get(0)
            bulletType = bullet and bullet:getFullType()
        end
        local originalCount = self.gun and self.gun:getCurrentAmmoCount() or 0
        local result = baseGunLoad(self, ...)
        if bulletType and self.gun and not C.isGunworks(self.gun)
           and self.gun:getCurrentAmmoCount() > originalCount then
            local orig = C.ammoKey(self.gun)
            local md = self.gun:getModData()
            if orig ~= bulletType and C.isCompatible(orig, bulletType) then
                md.PEAC_LoadedAmmoType = bulletType
            else
                md.PEAC_LoadedAmmoType = nil
            end
        end
        return result
    end

    local magStart = ISLoadBulletsInMagazine.start
    function ISLoadBulletsInMagazine:start(...)
        if isClient() and self.magazine then
            local inv = self.character:getInventory()
            local newRef = inv:getItemById(self.magazine:getID())
            if newRef then self.magazine = newRef end
        end
        local inv = self.character and self.character:getInventory()
        self.pecAmmoKey = C.choose(self.magazine, inv)
        -- A partly loaded foreign-ammo magazine must never be topped off with
        -- a different type via the vanilla branch.
        if not self.pecAmmoKey then
            if self.magazine and C.getLoadedAlias(self.magazine)
                and self.magazine:getCurrentAmmoCount() > 0 then
                self:forceStop()
                return
            end
            return magStart(self, ...)
        end
        if not inv:containsWithModule(self.pecAmmoKey) then
            self:forceStop()
            return
        end
        self.ammoCountStart = self.magazine:getCurrentAmmoCount()
        self.magazine:setJobDelta(0.0)
        self:setOverrideHandModels(nil, "GunMagazine")
        self:setActionAnim(CharacterActionAnims.InsertBullets)
        self:initVars()
        self.loadedThisLoop = false
        self.updateLoadBulletsTime = 0.0
        self.character:setVariable("UpdateLoadBulletsTime", 0.0)
    end

    local magServerStart = ISLoadBulletsInMagazine.serverStart
    function ISLoadBulletsInMagazine:serverStart(...)
        self.pecAmmoKey = C.choose(self.magazine, self.character:getInventory())
        return magServerStart(self, ...)
    end

    local magIsFinished = ISLoadBulletsInMagazine.isLoadFinished
    function ISLoadBulletsInMagazine:isLoadFinished(...)
        if not self.pecAmmoKey then return magIsFinished(self, ...) end
        return self.magazine:getCurrentAmmoCount() >= self.magazine:getMaxAmmo()
            or not self.character:getInventory():containsWithModule(self.pecAmmoKey)
    end

    local magAnim = ISLoadBulletsInMagazine.animEvent
    function ISLoadBulletsInMagazine:animEvent(event, parameter)
        if not self.pecAmmoKey or event ~= "InsertBullet" then
            return magAnim(self, event, parameter)
        end
        if self:isLoadFinished() then return end
        if self:isLocal() and self.loadedThisLoop then return end
        self.loadedThisLoop = true
        if isClient() then return end
        local inv = self.character:getInventory()
        -- Server authority: validate again before incrementing the magazine.
        if not C.canUseAlias(self.magazine, self.pecAmmoKey) then return end
        local bullet = inv:RemoveOneOf(self.pecAmmoKey, true)
        if not bullet then return end
        if self.character:getPerkLevel(Perks.Reloading) < 5 then
            if ZombRand(2) == 0 then addXp(self.character, Perks.Reloading, 4) end
        elseif ZombRand(5) == 0 then
            addXp(self.character, Perks.Reloading, 1)
        end
        self.magazine:setCurrentAmmoCount(self.magazine:getCurrentAmmoCount() + 1)
        self.magazine:getModData().PEAC_LoadedAmmoType = self.pecAmmoKey
        sendRemoveItemFromContainer(inv, bullet)
        syncItemFields(self.character, self.magazine)
    end

    local magUnloadAnim = ISUnloadBulletsFromMagazine.animEvent
    function ISUnloadBulletsFromMagazine:animEvent(event, parameter)
        local gwList = self.magazine and self.magazine:getModData().AmmoList
        if gwList and #gwList > 0 then
            -- The Gunworks hook already returns the physical round and removes
            -- its AmmoList entry. PEAC must not intercept and leave a stale list.
            return magUnloadAnim(self, event, parameter)
        end
        local alias = self.magazine and C.getLoadedAlias(self.magazine)
        if not alias or event ~= "RemoveBullet" then return magUnloadAnim(self, event, parameter) end
        if self.magazine:getCurrentAmmoCount() <= 0 then return end
        if self:isLocal() and self.unloadedThisLoop then return end
        self.unloadedThisLoop = true
        if not isClient() then
            local bullet = instanceItem(alias)
            if not bullet then return end
            local inv = self.character:getInventory()
            inv:AddItem(bullet)
            self.magazine:setCurrentAmmoCount(self.magazine:getCurrentAmmoCount() - 1)
            if self.magazine:getCurrentAmmoCount() <= 0 then
                self.magazine:getModData().PEAC_LoadedAmmoType = nil
            end
            sendAddItemToContainer(inv, bullet)
            syncItemFields(self.character, self.magazine)
        end
        self.unloadFinished = false
    end

    -- Preserve magazine round lineage through insertion and ejection. Vanilla
    -- reconstructs the magazine on ejection, so it would otherwise lose modData.
    local insertLoad = ISInsertMagazine.loadAmmo
    function ISInsertMagazine:loadAmmo(...)
        local alias = self.magazine and C.getLoadedAlias(self.magazine)
        local isGW = self.gun and C.isGunworks(self.gun)
        local result = insertLoad(self, ...)
        if self.gun and not isGW then
            self.gun:getModData().PEAC_LoadedAmmoType = alias
            syncHandWeaponFields(self.character, self.gun)
        end
        return result
    end

    local ejectUnload = ISEjectMagazine.unloadAmmo
    function ISEjectMagazine:unloadAmmo(...)
        local gun = self.gun
        local alias = gun and C.getLoadedAlias(gun)
        if not alias or C.isGunworks(gun) or not gun:isContainsClip() then
            return ejectUnload(self, ...)
        end
        local newMag = instanceItem(gun:getMagazineType())
        if not newMag then return ejectUnload(self, ...) end
        newMag:setCurrentAmmoCount(gun:getCurrentAmmoCount())
        newMag:getModData().PEAC_LoadedAmmoType = alias
        local inv = self.character:getInventory()
        inv:AddItem(newMag)
        gun:setContainsClip(false)
        gun:setCurrentAmmoCount(0)
        gun:getModData().PEAC_LoadedAmmoType = nil
        sendAddItemToContainer(inv, newMag)
        syncHandWeaponFields(self.character, gun)
    end

    local rackBullet = ISRackFirearm.removeBullet
    function ISRackFirearm:removeBullet(...)
        local gwList = self.gun and self.gun:getModData().AmmoList
        if gwList and #gwList > 0 then
            -- Let Gunworks pop its own round entry during chamber ejection.
            return rackBullet(self, ...)
        end
        local alias = self.gun and C.getLoadedAlias(self.gun)
        if not alias then return rackBullet(self, ...) end
        local bullet = instanceItem(alias)
        if not bullet then return rackBullet(self, ...) end
        self.character:getInventory():AddItem(bullet)
        sendAddItemToContainer(self.character:getInventory(), bullet)
    end

    local gunUnloadAnim = ISUnloadBulletsFromFirearm.animEvent
    function ISUnloadBulletsFromFirearm:animEvent(event, parameter)
        local gwList = self.gun and self.gun:getModData().AmmoList
        if gwList and #gwList > 0 then
            -- Gunworks owns its AmmoList and knows exactly which shell to return.
            return gunUnloadAnim(self, event, parameter)
        end
        local alias = self.gun and C.getLoadedAlias(self.gun)
        if not alias or event ~= "playReloadSound" or parameter == "ejectAmmoStart" then
            return gunUnloadAnim(self, event, parameter)
        end
        if self.gun:getCurrentAmmoCount() <= 0 then return end
        if self.gun:getEjectAmmoSound() then self.character:playSound(self.gun:getEjectAmmoSound()) end
        if not isClient() then
            local count = self.gun:isInsertAllBulletsReload() and self.gun:getCurrentAmmoCount() or 1
            local inv = self.character:getInventory()
            while count > 0 and self.gun:getCurrentAmmoCount() > 0 do
                local bullet = instanceItem(alias)
                if not bullet then break end
                inv:AddItem(bullet)
                self.gun:setCurrentAmmoCount(self.gun:getCurrentAmmoCount() - 1)
                sendAddItemToContainer(inv, bullet)
                syncHandWeaponFields(self.character, self.gun)
                count = count - 1
            end
            if self.gun:getCurrentAmmoCount() == 0 and not self.gun:isRoundChambered() then
                self.gun:getModData().PEAC_LoadedAmmoType = nil
            end
        end
        self.unloadFinished = false
    end
    C.log("native B42 reload hooks installed")
end
