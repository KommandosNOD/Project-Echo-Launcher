-- PROJECT ECHO Guns of 93 B42.21 MP FIX v0.2.0 TEST
-- Source: Guns of 93 0.8.2.7A (Workshop 3183820077)
print("[PE Guns93 MP Fix v0.2.0] Patched Guns93SpawnerItemsReplacer loaded")

local SmallContainers = {
    "Base.Bag_ProtectiveCaseSmall",
    "Base.Bag_ProtectiveCaseSmallMilitary",
    "Base.Bag_ProtectiveCaseSmall",
    "Base.Bag_ProtectiveCaseSmallMilitary",
    "Base.HollowBook",
    "Base.HollowBook",
    "Base.PistolCase1",
    "Base.PistolCase1",
    "Base.PistolCase1",
    "Base.Cashbox",
    "Base.CigarBox",
    "Base.Shoebox",
    "Base.Shoebox",
    "Base.Suitcase",
    "Base.Handbag",
    "Base.Purse",
    "Base.Bag_BowlingBallBag",
    "Base.Hatbox",
    "Base.Tacklebox"
}

local LargeContainers = {
    "Base.Flightcase",
    "Base.Guitarcase",
    "Base.Bag_RifleCase",
    "Base.Bag_RifleCaseGreen",
    "Base.Bag_RifleCaseCloth",
    "Base.Bag_RifleCaseClothCamo"
}

SpawnPistolCommon = {}
SpawnPistolUncommon = {}
SpawnPistolRare = {}
SpawnPistolVaryRare = {}

SpawnBUGCommon = {}
SpawnBUGUncommon = {}
SpawnBUGRare = {}
SpawnBUGVaryRare = {}

SpawnRevolverCommon = {}
SpawnRevolverUncommon = {}
SpawnRevolverRare = {}
SpawnRevolverVaryRare = {}

SpawnSportShotgunCommon = {}
SpawnSportShotgunUncommon = {}
SpawnSportShotgunRare = {}
SpawnSportShotgunVaryRare = {}

SpawnTacShotgunCommon = {}
SpawnTacShotgunUncommon = {}
SpawnTacShotgunRare = {}
SpawnTacShotgunVaryRare = {}

SpawnSportRifleCommon = {}
SpawnSportRifleUncommon = {}
SpawnSportRifleRare = {}
SpawnSportRifleVaryRare = {}

SpawnTacRifleCommon = {}
SpawnTacRifleUncommon = {}
SpawnTacRifleRare = {}
SpawnTacRifleVaryRare = {}

SpawnPoliceHandgunCommon = {}
SpawnPoliceHandgunUncommon = {}
SpawnPoliceHandgunRare = {}
SpawnPoliceHandgunVaryRare = {}

SpawnPoliceLongGunCommon = {}
SpawnPoliceLongGunUncommon = {}
SpawnPoliceLongGunRare = {}
SpawnPoliceLongGunVaryRare = {}

SpawnSWATLongGunCommon = {}
SpawnSWATLongGunUncommon = {}
SpawnSWATLongGunRare = {}
SpawnSWATLongGunVaryRare = {}

SpawnMilitaryHandgunCommon = {}
SpawnMilitaryHandgunUncommon = {}
SpawnMilitaryHandgunRare = {}
SpawnMilitaryHandgunVaryRare = {}

SpawnMilitaryLongGunCommon = {}
SpawnMilitaryLongGunUncommon = {}
SpawnMilitaryLongGunRare = {}
SpawnMilitaryLongGunVaryRare = {}

SpawnMilitarySniperCommon = {}
SpawnMilitarySniperUncommon = {}
SpawnMilitarySniperRare = {}
SpawnMilitarySniperVaryRare = {}

SpawnStoreHandgunCommon = {}
SpawnStoreHandgunUncommon = {}
SpawnStoreHandgunRare = {}
SpawnStoreHandgunVaryRare = {}

SpawnStoreRifleCommon = {}
SpawnStoreRifleUncommon = {}
SpawnStoreRifleRare = {}
SpawnStoreRifleVaryRare = {}

SpawnStoreShotgunCommon = {}
SpawnStoreShotgunUncommon = {}
SpawnStoreShotgunRare = {}
SpawnStoreShotgunVaryRare = {}

SpawnCnRGunCommon = {}
SpawnCnRGunUncommon = {}
SpawnCnRGunRare = {}
SpawnCnRGunVaryRare = {}

SpawnNFAGunCommon = {}
SpawnNFAGunUncommon = {}
SpawnNFAGunRare = {}
SpawnNFAGunVaryRare = {}

SpawnSBSCommon = {}
SpawnSBSUncommon = {}
SpawnSBSRare = {}
SpawnSBSVaryRare = {}

SpawnSawedRifleCommon = {}
SpawnSawedRifleUncommon = {}
SpawnSawedRifleRare = {}
SpawnSawedRifleVaryRare = {}

SpawnCrimeHandgunCommon = {}
SpawnCrimeHandgunUncommon = {}
SpawnCrimeHandgunRare = {}
SpawnCrimeHandgunVaryRare = {}

SpawnCrimeLongGunCommon = {}
SpawnCrimeLongGunUncommon = {}
SpawnCrimeLongGunRare = {}
SpawnCrimeLongGunVaryRare = {}

local COUNTER_KEY = "Guns93_ItemSpawnCounts"

local MAX_SPAWNS = {
    ["Base.SPAS12"] = 3,
    ["Base.HK91"] = 5,
}

local function GetSpawnCounters()
    local data = ModData.getOrCreate(COUNTER_KEY)
    if not data.counts then data.counts = {} end
    return data.counts
end

local function CanSpawnItem(fullType)
    if not MAX_SPAWNS[fullType] then return true end 
    local counts = GetSpawnCounters()
    return (counts[fullType] or 0) < MAX_SPAWNS[fullType]
end

local function IncrementSpawnCount(fullType)
    if not MAX_SPAWNS[fullType] then return end
    local counts = GetSpawnCounters()
    counts[fullType] = (counts[fullType] or 0) + 1
    ModData.transmit(COUNTER_KEY)
end

local function Guns93GunPicker(Gun, Guns)
    if not Guns then return nil end
    local fullType = Guns:getFullType()
    local name = fullType:gsub("Base%.Guns93", ""):gsub("Spawner", "")
    local common   = _G["Spawn" .. name .. "Common"]   or {}
    local uncommon = _G["Spawn" .. name .. "Uncommon"] or {}
    local rare     = _G["Spawn" .. name .. "Rare"]     or {}
    local varyRare = _G["Spawn" .. name .. "VaryRare"] or {}
    local attempts = 0
    local maxAttempts = 5
    while attempts < maxAttempts do
        local GunSpawnD100 = ZombRand(0, 100)
        local candidate
        if GunSpawnD100 > 65 and #common > 0 then
            candidate = common[ZombRand(#common) + 1]
        elseif GunSpawnD100 > 35 and #uncommon > 0 then
            candidate = uncommon[ZombRand(#uncommon) + 1]
        elseif GunSpawnD100 > 5 and #rare > 0 then
            candidate = rare[ZombRand(#rare) + 1]
        elseif #varyRare > 0 then
            candidate = varyRare[ZombRand(#varyRare) + 1]
        end
        if candidate and CanSpawnItem(candidate) then
            local altAmmo = ""
            if ZombRand(1, 10) > 7 and ScriptManager.instance:getItem(candidate .. "_Alt") then
                altAmmo = "_Alt"
            end
            return candidate .. altAmmo
        end
        attempts = attempts + 1
    end
    return nil
end

local function Guns93VanillaReplacerFloor(roomType, square, spawner)
    if isClient() then return end
    local fullType = spawner:getFullType()
    local pickedType = nil
    if fullType == "Base.Pistol" or fullType == "Base.Pistol2" or fullType == "Base.Pistol3" then
        pickedType = "Base.Guns93PistolSpawner"
    elseif fullType == "Base.Revolver" or fullType == "Base.Revolver_Short" or fullType == "Base.Revolver_Long" then
        pickedType = "Base.Guns93RevolverSpawner"
    elseif fullType == "Base.TrapperCarbine" or fullType == "Base.L94_Rifle" or fullType == "Base.L92_Carbine" or fullType == "Base.VarmintRifle" or fullType == "Base.HuntingRifle" or fullType == "Base.JS14_Rifle" then
        pickedType = "Base.Guns93SportRifleSpawner"
    elseif fullType == "Base.MSR7T_Rifle" or fullType == "Base.AssaultRifle" or fullType == "Base.AssaultRifle2" then
        if roomType ~= "armystorage" then
            if ZombRand(10) > 3 then
                pickedType = "Base.Guns93NFAGunSpawner"
            else
                pickedType = "Base.Guns93TacRifleSpawner"
            end
        else
            pickedType = "Base.MilitaryLongGunSpawner"
        end
    elseif fullType == "Base.Shotgun" or fullType == "Base.ShotgunSawnoff" or fullType == "Base.DoubleBarrelShotgun" or fullType == "Base.DoubleBarrelShotgunSawnoff" then
        pickedType = "Base.Guns93SportShotgunSpawner"
    elseif fullType == "Base.JS3T_Shotgun" then
        pickedType = "Base.Guns93TacShotgunSpawner"
    end
    if not pickedType then return end
    local gun = instanceItem(pickedType)
    local zHeight = 0
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local props = obj:getProperties()
        if props and props:getSurface() then
            local isTall = (props:getSurface() * 0.01) + 0.01
            if isTall > zHeight then
                zHeight = isTall
            end
        end
    end
    square:AddWorldInventoryItem(gun, ZombRandFloat(0.2, 0.8), ZombRandFloat(0.2, 0.8), zHeight)
    return true
end

local function applyAutoParts(gun)
    if isClient() then return end
    if not gun:getFireModePossibilities() then return end
    local md = gun:getModData()
    local partToUse
    if md.hasAutoTrigger and md.hasAutoPart then
        local trigger = gun:getWeaponPart("Trigger")
        if ZombRand(10) > 5 and not (trigger:hasTag(Gun93Registries.guns93.Fullauto) or trigger:hasTag(Gun93Registries.guns93.Burst)) then
            partToUse = md.hasAutoPart
        else
            partToUse = md.hasAutoTrigger
        end
    else
        partToUse = md.hasAutoTrigger or md.hasAutoPart
    end
    if partToUse then
        local partItem = instanceItem(partToUse)
        gun:detachWeaponPart(partItem:getPartType())
        gun:attachWeaponPart(partItem)
        if md.hasSpcPart then
            local spcItem = instanceItem(md.hasSpcPart)
            gun:detachWeaponPart(spcItem:getPartType())
        end
    end
end

local function Guns93ZombieGunSpawns(zombie)
    if isClient() or not zombie then return end
    local ZomID = zombie:getPersistentOutfitID()
    for i = zombie:getAttachedItems():size() - 1, 0, -1 do
        local zomGun = zombie:getAttachedItems():get(i)
        if zomGun ~= nil then
            local Guns = zomGun:getItem()
            local md = zombie:getModData()
            local data = md.Guns93Attached
            if Guns and Guns:hasTag(Gun93Registries.guns93.Guns93Spawner) then
                local Gun = nil
                local GunLocation = zomGun:getLocation()
                Gun = Guns93GunPicker(nil, Guns)
                if Gun ~= nil then
                    zombie:setAttachedItem(GunLocation, nil)
                    local spawn = instanceItem(Gun)
                    IncrementSpawnCount(spawn:getFullType())
                    if spawn:getAttachmentType() == "Rifle" then
                        spawn:attachWeaponPart(instanceItem("Base.Sling"))
                    end
                    zombie:setAttachedItem(GunLocation, spawn)
                end
            end
            if not SandboxVars.Guns93.Guns93VanillaGuns then
                for _, badItem in ipairs(Guns93RemoveItems) do
                    if Guns:getFullType() == badItem then
                        zombie:setAttachedItem(zomGun:getLocation(), nil)
                    end
                end
            end
            zombie:transmitModData()
            zombie:resetModel()
            zombie:resetModelNextFrame()
        end
    end
end

local function setGunCondition(gun, spawner)
    if isClient() then return end
    if not gun then return end
    local isNew = spawner:hasTag(Gun93Registries.guns93.NewGun)
    if isNew then
        gun:setCondition(ZombRand(1,10) > 5 and ZombRand(15,20) or 20)
    else
        gun:setCondition(ZombRand(7,20))
    end
end

local function loadedGun(gun, spawner)
    if isClient() then return end
    if not spawner:hasTag(Gun93Registries.guns93.GunLoaded) then return end
    local roll = ZombRand(11)
    if roll <= 5 then return end
    gun:setCurrentAmmoCount(ZombRand(1, gun:getMaxAmmo()))
    if roll > 7 and gun:haveChamber() then
        gun:setRoundChambered(true)
    end
    if gun:isManuallyRemoveSpentRounds() then
        local spent = gun:getMaxAmmo() - gun:getCurrentAmmoCount()
        gun:setSpentRoundCount(spent)
    end
end

local function createCase(spawner)
    if isClient() then return end
    if ZombRand(11) <= 5 then return nil end
    local hasSmall  = spawner:hasTag(Gun93Registries.guns93.SmallContainer)
    local hasLarge  = spawner:hasTag(Gun93Registries.guns93.LargeContainer)
    if not hasSmall and not hasLarge then return nil end
    local pool = hasLarge and LargeContainers or SmallContainers
    if #pool == 0 then return nil end
    local case = instanceItem(pool[ZombRand(#pool) + 1])
    return case, case:getInventory()
end

-- PE_G93_MPFIX 0.1.0: avoid incremental network notifications while
-- the game constructs a freshly generated container (OnFillContainer).
-- Post-generation replacements from the periodic scanner still transmit.
local PE_G93_fillingInitialContainer = false

local function PE_G93_sendAdd(container, item)
    if not PE_G93_fillingInitialContainer then
        sendAddItemToContainer(container, item)
    end
end

local function PE_G93_sendRemove(container, item)
    if not PE_G93_fillingInitialContainer then
        sendRemoveItemFromContainer(container, item)
    end
end

local function finalizeGun(gun, spawner, targetContainer)
    if isClient() then return end
    IncrementSpawnCount(gun:getFullType())
    if spawner:hasTag(Gun93Registries.guns93.MGun) then
        applyAutoParts(gun)
    end
    setGunCondition(gun, spawner)
    loadedGun(gun, spawner)
    if targetContainer then
        local isLoadedMags = spawner:hasTag(Gun93Registries.guns93.LoadedMags)
        local refItem = instanceItem(gun:getFullType())
        if gun:getMagazineType() then
            local magType = gun:getMagazineType()
            local fallbackMagType = refItem:getMagazineType()
            local mag1 = instanceItem(magType)
            local mag2 = instanceItem(fallbackMagType)
            local rareMag = mag1:hasTag(Gun93Registries.guns93.RareMag)
            local rareMag2 = mag2:hasTag(Gun93Registries.guns93.RareMag)
            local roll = ZombRand(11)
            if magType == "Base.EblocClip" then
                for _ = 1, ZombRand(0,8) do
                    local clip = instanceItem(magType)
                    DynamicMagClip(clip)
                    targetContainer:AddItem(clip)
                    PE_G93_sendAdd(targetContainer, clip)
                end
                for _ = 1, ZombRand(8,12) do
                    local clip = instanceItem(magType)
                    if isLoadedMags then clip:setCurrentAmmoCount(clip:getMaxAmmo()) end
                    DynamicMagClip(clip)
                    targetContainer:AddItem(clip)
                    PE_G93_sendAdd(targetContainer, clip)
                end
            else
                if roll > 3 or spawner:hasTag(Gun93Registries.guns93.SmallContainer) or spawner:hasTag(Gun93Registries.guns93.LargeContainer) then
                    if isLoadedMags then mag1:setCurrentAmmoCount(mag1:getMaxAmmo()) end
                    DynamicMagClip(mag1)
                    targetContainer:AddItem(mag1)
                    PE_G93_sendAdd(targetContainer, mag1)
                end
                if roll > 5 and not rareMag2 then
                    if isLoadedMags then mag2:setCurrentAmmoCount(mag2:getMaxAmmo()) end
                    DynamicMagClip(mag2)
                    targetContainer:AddItem(mag2)
                    PE_G93_sendAdd(targetContainer, mag2)
                end
                if spawner:hasTag(Gun93Registries.guns93.MoreMags) then
                    if roll > 2 and not rareMag then
                        local extra1 = instanceItem(magType)
                        if isLoadedMags then extra1:setCurrentAmmoCount(extra1:getMaxAmmo()) end
                        DynamicMagClip(extra1)
                        targetContainer:AddItem(extra1)
                        PE_G93_sendAdd(targetContainer, extra1)
                    end
                    if roll > 3 and not rareMag2 then
                        local extra2 = instanceItem(fallbackMagType)
                        if isLoadedMags then extra2:setCurrentAmmoCount(extra2:getMaxAmmo()) end
                        DynamicMagClip(extra2)
                        targetContainer:AddItem(extra2)
                        PE_G93_sendAdd(targetContainer, extra2)
                    end
                end
            end
        end
        if gun:getModData().hasClip then
            local clipType = gun:getModData().hasClip
            local clipCount = ZombRand(1,3)
            if instanceItem(clipType):hasTag(Gun93Registries.guns93.StripperClip) then
                clipCount = ZombRand(4,10)
            end
            for _ = 1, clipCount do
                local clip = instanceItem(clipType)
                if isLoadedMags then clip:setCurrentAmmoCount(clip:getMaxAmmo()) end
                DynamicMagClip(clip)
                targetContainer:AddItem(clip)
                PE_G93_sendAdd(targetContainer, clip)
            end
        end
        if gun:getModData().hasLoader then
            local loaderType = nil
            if ZombRand(0,11) > 8 then 
                loaderType = gun:getModData().hasLoader
            elseif ZombRand(0,11) > 9 and gun:getModData().hasLoader2 then 
                loaderType = gun:getModData().hasLoader2 
            elseif ZombRand(0,11) > 9 and gun:getModData().hasLoader3 then 
                loaderType = gun:getModData().hasLoader3 
            end
            if loaderType then
                for _ = 1, ZombRand(1,3) do
                    local loader = instanceItem(loaderType)
                    if isLoadedMags and ZombRand(11) > 5 then loader:setCurrentAmmoCount(loader:getMaxAmmo()) end
                    DynamicMagClip(loader)
                    targetContainer:AddItem(loader)
                    PE_G93_sendAdd(targetContainer, loader)
                end
            end
        end
        if gun:hasTag(Gun93Registries.guns93.SurplusAmmo) then
            local box = gun:getAmmoBox():gsub("Box$", "Carton")
            local spawnBox =instanceItem(box)
            targetContainer:AddItem(spawnBox)
            PE_G93_sendAdd(targetContainer, spawnBox)
        end
        if not spawner:hasTag(Gun93Registries.guns93.NoAmmo) then
            local roll = ZombRand(11)
            if roll > 2 then
                local spawnBox = instanceItem(gun:getAmmoBox())
                targetContainer:AddItem(spawnBox) 
                PE_G93_sendAdd(targetContainer, spawnBox)
            end
            if roll > 4 then
                local ammoBox = instanceItem(gun:getAmmoBox())
                if ammoBox then 
                    targetContainer:AddItem(ammoBox)
                    PE_G93_sendAdd(targetContainer, ammoBox)
                end
                if gun:hasTag(Gun93Registries.guns93.AmmoSwitch) then
                    local altGunType = gun:hasTag(Gun93Registries.guns93.AltAmmo) and gun:getFullType():gsub("_Alt$", "") or (gun:getFullType() .. "_Alt")
                    local altItem = instanceItem(altGunType)
                    local altBox = altItem:getAmmoBox()
                    if altItem then
                        local altBox = altItem:getAmmoBox()
                        if altItem then
                            if roll > 4 then 
                                local spawnBox = instanceItem(altBox)
                                targetContainer:AddItem(spawnBox) 
                                PE_G93_sendAdd(targetContainer, spawnBox)
                            end
                            if roll > 6 then 
                                local spawnBox = instanceItem(altBox)
                                targetContainer:AddItem(spawnBox)
                                PE_G93_sendAdd(targetContainer, spawnBox)
                            end
                        end
                    end
                end
            end
            if spawner:hasTag(Gun93Registries.guns93.MoreAmmo) then
                if roll > 5 then
                    local spawnBox = instanceItem(gun:getAmmoBox())
                    targetContainer:AddItem(spawnBox) 
                    PE_G93_sendAdd(targetContainer, spawnBox)
                end
                if roll > 6 then
                    local spawnBox = instanceItem(gun:getAmmoBox())
                    targetContainer:AddItem(spawnBox)
                    PE_G93_sendAdd(targetContainer, spawnBox)
                end
            end
        end
        targetContainer:AddItem(gun)
        PE_G93_sendAdd(targetContainer, gun)
    end
end

local function finalizeZedGun(Gun, spawner, targetContainer)
    if isClient() then return end
    if Gun:hasTag(Gun93Registries.guns93.Guns93) then
        Gun:setCondition(ZombRand(5, 20))
        Gun:setCurrentAmmoCount(ZombRand(0, Gun:getMaxAmmo()))
        if Gun:haveChamber() then
            if Gun:getCurrentAmmoCount() > 0 then
                if ZombRand(0, 10) > 6 then
                    Gun:setJammed(true)
                    Gun:setSpentRoundChambered(true)
                else
                    Gun:setRoundChambered(true)
                end
            end
        end
        if Gun:isManuallyRemoveSpentRounds() then
            local spent = Gun:getMaxAmmo() - Gun:getCurrentAmmoCount()
            Gun:setSpentRoundCount(spent)
        end
        if Gun:getAttachmentType() == "Rifle" then
            Gun:attachWeaponPart(instanceItem("Base.Sling"))
        end
        targetContainer:AddItem(Gun)
        PE_G93_sendAdd(targetContainer, Gun)
        if Gun:getMagazineType() then
            local refItem = instanceItem(Gun:getFullType())
            local RareMag2 = false
            local GunMag = instanceItem(Gun:getMagazineType())
            local GunMag2 = instanceItem(refItem:getMagazineType())
            if Gun:getMagazineType() == "Base.EblocClip" then
                local clipNum = ZombRand(0,8)
                for _ = 0, clipNum - 1 do
                    local clip = instanceItem(Gun:getMagazineType())
                    clip:setCurrentAmmoCount(clip:getMaxAmmo())
                    DynamicMagClip(clip)
                    targetContainer:AddItem(clip)
                    PE_G93_sendAdd(targetContainer, clip)
                end
            else
                if GunMag2:hasTag(Gun93Registries.guns93.RareMag) then
                    RareMag2 = true
                end
                local magsD10 = ZombRand(0,10)
                if magsD10 > 2 then
                    local newMag = instanceItem(GunMag2:getFullType())
                    local ammo = ZombRand(0, Gun:getMaxAmmo())
                    newMag:setCurrentAmmoCount(ammo)
                    DynamicMagClip(newMag)
                    targetContainer:AddItem(newMag)
                    PE_G93_sendAdd(targetContainer, newMag)
                    if not RareMag2 then
                        for _ = 0, ZombRand(1,3)-1 do
                            local newMag = instanceItem(GunMag2:getFullType())
                            local ammo = ZombRand(0, Gun:getMaxAmmo())
                            newMag:setCurrentAmmoCount(ammo)
                            DynamicMagClip(newMag)
                            targetContainer:AddItem(newMag)
                            PE_G93_sendAdd(targetContainer, newMag)
                        end
                    end
                end
            end
        else
            local looseCount = ZombRand(20)
            local ammoType = Gun:getAmmoType()
            if ammoType and ammoType:getItemKey() then
                for _ = 1, looseCount do
                    local ammo = instanceItem(ammoType:getItemKey())
                    if ammo then
                        targetContainer:AddItem(ammo)
                        PE_G93_sendAdd(targetContainer, ammo)
                    end
                end
            end
        end
        if Gun:getModData().hasClip then
            local clip = Gun:getModData().hasClip
            local clipNum = ZombRand(1,3)
            if instanceItem(clip):hasTag(Gun93Registries.guns93.StripperClip) then
                clipNum = ZombRand(4,10)
            end
            if clip then
                for _ = 0, clipNum-1 do
                    local newClip = instanceItem(clip)
                    local ammo = ZombRand(0, newClip:getMaxAmmo())
                    newClip:setCurrentAmmoCount(ammo)
                    DynamicMagClip(newClip)
                    targetContainer:AddItem(newClip)
                    PE_G93_sendAdd(targetContainer, newClip)
                end
            end
        end
        if Gun:getModData().hasLoader then
            local loader = nil
            if ZombRand(0,10) > 7 then
                loader = Gun:getModData().hasLoader
            elseif ZombRand(0,10) > 8 and Gun:getModData().hasLoader2 then
                loader = Gun:getModData().hasLoader2
            elseif ZombRand(0,10) > 8 and Gun:getModData().hasLoader3 then
                loader = Gun:getModData().hasLoader3
            end
            if loader then
                for _ = 0, ZombRand(1,3)-1 do
                    local newLoader = instanceItem(loader)
                    if ZombRand(0,10) > 5 then
                        newLoader:setCurrentAmmoCount(newLoader:getMaxAmmo())
                    end
                    DynamicMagClip(newLoader)
                    targetContainer:AddItem(newLoader)
                    PE_G93_sendAdd(targetContainer, newLoader)
                end
            end
        end
    end
end

-- PROJECT ECHO v0.2.0: server-side Guns93 BUG-spawner duplicate guard.
-- Only the special BUG placeholder is affected. In normal weapon loot without a
-- real Guns93 firearm in the SAME container/square, native spawning stays intact.
local function PE_G93_isReal93Gun(item)
    return item
        and instanceof(item, "HandWeapon")
        and not item:hasTag(Gun93Registries.guns93.Guns93Spawner)
        and item:hasTag(Gun93Registries.guns93.Guns93)
end

local function PE_G93_getRoundType(gun)
    if not PE_G93_isReal93Gun(gun) then return nil end
    -- B42 ammoType is usually ItemKey, not a raw string. Different weapon
    -- variants can provide nil; don't invent ammo for an unrecognised gun.
    local ok, raw = pcall(function() return gun:getAmmoType() end)
    if not ok or not raw then return nil end
    local key
    if type(raw) == "string" then
        key = raw
    else
        local keyOk, value = pcall(function() return raw:getItemKey() end)
        if keyOk then key = value end
    end
    if not key or key == "" then return nil end
    -- ItemKey can be a Java key on B42; pass it straight to instanceItem.
    local itemOk, round = pcall(function() return instanceItem(key) end)
    if not itemOk or not round or instanceof(round, "HandWeapon") then return nil end
    return tostring(key), round
end

local function PE_G93_findExistingGunInContainer(container)
    local items = container and container:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if PE_G93_isReal93Gun(item) then return item end
    end
    return nil
end

local function PE_G93_findExistingGunOnFloor(square)
    local objects = square and square:getWorldObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local item = object and object:getItem()
        if PE_G93_isReal93Gun(item) then return item end
    end
    return nil
end

local function PE_G93_convertDuplicateInContainer(container, spawner)
    if not spawner or spawner:getFullType() ~= "Base.Guns93BUGSpawner" then return false end
    local gun = PE_G93_findExistingGunInContainer(container)
    if not gun then return false end
    local roundType, round = PE_G93_getRoundType(gun)
    if roundType then
        container:AddItem(round)
        PE_G93_sendAdd(container, round)
        print("[PE Guns93 MP Fix v0.2.0] duplicate BUGSpawner -> one " .. roundType .. " (container)")
    else
        print("[PE Guns93 MP Fix v0.2.0] duplicate BUGSpawner removed (no valid round type; container)")
    end
    return true
end

local function PE_G93_convertDuplicateOnFloor(square, spawner)
    if not spawner or spawner:getFullType() ~= "Base.Guns93BUGSpawner" then return false end
    local gun = PE_G93_findExistingGunOnFloor(square)
    if not gun then return false end
    local roundType, round = PE_G93_getRoundType(gun)
    if roundType then
        local zHeight = 0
        local objects = square:getObjects()
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            local props = obj and obj:getProperties()
            if props and props:getSurface() then
                local height = (props:getSurface() * 0.01) + 0.01
                if height > zHeight then zHeight = height end
            end
        end
        local spawned = square:AddWorldInventoryItem(round,
            ZombRandFloat(0.2, 0.8), ZombRandFloat(0.2, 0.8), zHeight)
        if not spawned then
            -- Don't remove a placeholder until its intended replacement exists.
            print("[PE Guns93 MP Fix v0.2.0] failed to spawn round " .. roundType)
            return false
        end
        print("[PE Guns93 MP Fix v0.2.0] duplicate BUGSpawner -> one " .. roundType .. " (floor)")
    else
        print("[PE Guns93 MP Fix v0.2.0] duplicate BUGSpawner removed (no valid round type; floor)")
    end
    return true
end

local function Guns93ItemPickerContainer(roomType, containerType, container, spawner, zed)
    if isClient() then return end
    if not container or not container.AddItem then
        return
    end
    if PE_G93_convertDuplicateInContainer(container, spawner) then return true end
    local fullType = spawner:getFullType()
    local isMilitary = fullType:match("MilitaryHandgunSpawner") or fullType:match("MilitaryLongGunSpawner") or fullType:match("MilitarySniperSpawner")
    if isMilitary and roomType ~= "armystorage" then
        if zed == false then
            local replacement = "Base.Guns93SBSSpawner"
            if ZombRand(10) > 3 then
                replacement = "Base.Guns93NFAGunSpawner"
            end
            spawner = instanceItem(replacement)
        end
    end
    local pickedType = Guns93GunPicker(nil, spawner)
    if not pickedType then return end
    local gun = instanceItem(pickedType)
    if not gun then return end
    local target = container
    local case, caseInv = createCase(spawner)
    if case and caseInv and caseInv.AddItem then
        target = caseInv
        container:AddItem(case)
        PE_G93_sendAdd(container, case)
    end
    if zed == true then
        finalizeZedGun(gun, spawner, target)
    else
        finalizeGun(gun, spawner, target)
    end
end

local function Guns93ItemPickerFloor(roomType, square, spawner)
    if isClient() then return false end
    if PE_G93_convertDuplicateOnFloor(square, spawner) then return true end
    local fullType = spawner:getFullType()
    local isMilitary = fullType:match("MilitaryHandgunSpawner") or fullType:match("MilitaryLongGunSpawner") or fullType:match("MilitarySniperSpawner")
    if isMilitary and roomType ~= "armystorage" then
        local replacement = "Base.Guns93SBSSpawner"
        if ZombRand(10) > 3 then
            replacement = "Base.Guns93NFAGunSpawner"
        end
        spawner = instanceItem(replacement)
    end
    local pickedType = Guns93GunPicker(nil, spawner)
    if not pickedType then return end
    local gun = instanceItem(pickedType)
    finalizeGun(gun, spawner, nil)
    local zHeight = 0
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local props = obj:getProperties()
        if props and props:getSurface() then
            local isTall = (props:getSurface() * 0.01) + 0.01
            if isTall > zHeight then
                zHeight = isTall
            end
        end
    end
    local spawned = square:AddWorldInventoryItem(gun,
        ZombRandFloat(0.2, 0.8), ZombRandFloat(0.2, 0.8), zHeight)
    return spawned ~= nil
end

local function PE_G93_Guns93SpawnerItemBody(roomType, containerType, container)
    if isClient() then return end
    if not instanceof(container, "ItemContainer") then return end
    local items = container:getItems()
    local toRemove = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if item:getFullType() == "Base.Guns93Junk" then
                table.insert(toRemove, item)
            elseif instanceof(item, "HandWeapon") and item:hasTag(Gun93Registries.guns93.Guns93Spawner) then
                Guns93ItemPickerContainer(roomType, containerType, container, item)
                table.insert(toRemove, item)
            elseif not SandboxVars.Guns93.Guns93VanillaGuns then
                for _, badItem in ipairs(Guns93RemoveItems or {}) do
                    if item:getFullType() == badItem then
                        table.insert(toRemove, item)
                        break
                    end
                end
            end
        end
    end
    for _, item in ipairs(toRemove) do
        if container:contains(item) then
            container:DoRemoveItem(item)
            PE_G93_sendRemove(container, item)
            container:setDirty(true)
            container:setExplored(true)
        end
    end
end


-- Wrap only the initial item picker event; failures must not leave suppression
-- enabled for the scanner or another event.
local function Guns93SpawnerItem(roomType, containerType, container)
    if isClient() or not instanceof(container, "ItemContainer") then return end
    local before = PE_G93_fillingInitialContainer
    PE_G93_fillingInitialContainer = true
    local ok, err = pcall(PE_G93_Guns93SpawnerItemBody, roomType, containerType, container)
    PE_G93_fillingInitialContainer = before
    if not ok then error(err) end
end

Events.OnFillContainer.Add(Guns93SpawnerItem)

local function Guns93ProcessInventory(roomType, inventory, zed)
    if not inventory then return end
    local items = inventory:getItems()
    local toRemove = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if item:hasTag(Gun93Registries.guns93.Guns93Spawner) and instanceof(item, "HandWeapon") then
                Guns93ItemPickerContainer(roomType, nil, inventory, item, zed)
                table.insert(toRemove, item)
            elseif item:getFullType() == "Base.Guns93Junk" then
                table.insert(toRemove, item)
            elseif instanceof(item, "InventoryContainer") and item:getInventory() then
                Guns93ProcessInventory(roomType, item:getInventory())
            elseif not SandboxVars.Guns93.Guns93VanillaGuns then
                for _, badItem in ipairs(Guns93RemoveItems or {}) do
                    if item:getFullType() == badItem then
                        table.insert(toRemove, item)
                        break
                    end
                end
            end
        end
    end
    for _, item in ipairs(toRemove) do
        if inventory:contains(item) then
            inventory:DoRemoveItem(item)
            PE_G93_sendRemove(inventory, item)
            inventory:setDirty(true)
            inventory:setExplored(true)
        end
    end
end

local function Guns93SpawnerItemScanner()
    if isClient() then return end
    local playersToCheck = {}
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers and onlinePlayers:size() > 0 then
        for i = 0, onlinePlayers:size() - 1 do
            table.insert(playersToCheck, onlinePlayers:get(i))
        end
    else
        local player = getPlayer()
        if player then
            table.insert(playersToCheck, player)
        end
    end
    for _, player in ipairs(playersToCheck) do
        local playerSquare = player:getSquare()
        if playerSquare then
            local cell = getCell()
            local z = playerSquare:getZ()
            local SEARCH_RADIUS = 10
            for dx = -SEARCH_RADIUS, SEARCH_RADIUS do
                for dy = -SEARCH_RADIUS, SEARCH_RADIUS do
                    for dz = -1, 1 do
                        local x = math.floor(player:getX() + dx)
                        local y = math.floor(player:getY() + dy)
                        local z = math.floor(player:getZ() + dz)
                        local square = cell:getGridSquare(x, y, z)
                        if square then
                            local roomType = square:getRoom() and square:getRoom():getName() or nil
                            local worldObjects = square:getWorldObjects()
                            local toProcess = {}
                            local toRemove = {}
---                            local corpse = square:getDeadBody()
--                            if corpse and corpse:getContainer() then
--                                Guns93ProcessInventory(roomType, corpse:getContainer(), true)
--                            end
                            for j = 0, worldObjects:size() - 1 do
                                local worldItem = worldObjects:get(j)
                                if worldItem then
                                    local item = worldItem:getItem()
                                    table.insert(toProcess, {worldItem = worldItem, item = item})
                                end
                            end
                            local movingObjects = square:getMovingObjects()
                            if movingObjects then
                                for i = 0, movingObjects:size() - 1 do
                                    local mover = movingObjects:get(i)
                                    if mover then
                                        if instanceof(mover, "BaseVehicle") then
                                            for p = 0, mover:getPartCount() - 1 do
                                                local part = mover:getPartByIndex(p)
                                                if part and part:getItemContainer() then
                                                    Guns93ProcessInventory(roomType, part:getItemContainer())
                                                end
                                            end
                                        elseif instanceof(mover, "IsoZombie") then
                                            Guns93ZombieGunSpawns(mover)
                                        end
                                    end
                                end
                            end
                            for _, entry in ipairs(toProcess) do
                                local item = entry.item
                                local worldItem = entry.worldItem
                                if item:hasTag(Gun93Registries.guns93.Guns93Spawner) then
                                    -- Only consume a spawner if generation/conversion completed.
                                    if Guns93ItemPickerFloor(roomType, square, item) then
                                        table.insert(toRemove, worldItem)
                                    end
                                elseif item:getFullType() == "Base.Guns93Junk" then
                                    table.insert(toRemove, worldItem)
                                elseif instanceof(item, "InventoryContainer") and item:getInventory() then
                                    Guns93ProcessInventory(roomType, item:getInventory())
                                elseif not SandboxVars.Guns93.Guns93VanillaGuns then
                                    if instanceof(item, "HandWeapon") and item:isRanged() and not item:hasTag(Gun93Registries.guns93.Guns93) then
                                        Guns93VanillaReplacerFloor(roomType, square, item)
                                    end
                                    for _, badItem in ipairs(Guns93RemoveItems) do
                                        if item:getFullType() == badItem then
                                            table.insert(toRemove, worldItem)
                                        end
                                    end
                                end
                            end
                            for _, worldItem in ipairs(toRemove) do
                                if worldItem then
                                    local sq = worldItem:getSquare()
                                    if sq then
                                        sq:removeWorldObject(worldItem)
                                        sq:transmitRemoveItemFromSquare(worldItem)
                                    end
                                end
                            end
                            local objects = square:getObjects()
                            for i = 0, objects:size() - 1 do
                                local obj = objects:get(i)
                                local zed = false
                                if instanceof(obj, "IsoDeadBody") or instanceof(obj, "IsoZombie") then
                                    zed = true
                                end
                                local container = obj:getContainer() or (obj.getItemContainer and obj:getItemContainer())
                                if container then
                                    Guns93ProcessInventory(roomType, container, zed)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local TICK_DELAY = 180
local tickTimer = TICK_DELAY or 180

local function Guns93SpawnerOnTickDelay()
    if isClient() then return end
    tickTimer = tickTimer - 1
    if tickTimer <= 0 then
        Guns93SpawnerItemScanner()
        tickTimer = TICK_DELAY
    end
end

Events.OnTick.Add(Guns93SpawnerOnTickDelay)

local function Guns93ZombieDrops(zombie)
    if isClient() then return end
--    Guns93ZombieGunSpawns(zombie)
    for i = zombie:getAttachedItems():size() - 1, 0, -1 do
        local zomGun = zombie:getAttachedItems():get(i)
        local Gun = zomGun:getItem()
        if Gun:hasTag(Gun93Registries.guns93.Guns93) then
            Gun:setCondition(ZombRand(5, 20))
            Gun:setCurrentAmmoCount(ZombRand(0, Gun:getMaxAmmo()))
            if Gun:haveChamber() then
                if Gun:getCurrentAmmoCount() > 0 then
                    if ZombRand(0, 10) > 6 then
                        Gun:setJammed(true)
                        Gun:setSpentRoundChambered(true)
                    else
                        Gun:setRoundChambered(true)
                    end
                end
            end
            if Gun:isManuallyRemoveSpentRounds() then
                local spent = Gun:getMaxAmmo() - Gun:getCurrentAmmoCount()
                Gun:setSpentRoundCount(spent)
            end
--            zombie:getInventory():AddItem(Gun)
--            PE_G93_sendAdd(zombie:getInventory(), Gun)
            if Gun:getMagazineType() then
                local refItem = instanceItem(Gun:getFullType())
                local RareMag2 = false
                local GunMag = instanceItem(Gun:getMagazineType())
                local GunMag2 = instanceItem(refItem:getMagazineType())
                if Gun:getMagazineType() == "Base.EblocClip" then
                    local clipNum = ZombRand(0,8)
                    for _ = 0, clipNum - 1 do
                        local clip = instanceItem(Gun:getMagazineType())
                        clip:setCurrentAmmoCount(clip:getMaxAmmo())
                        DynamicMagClip(clip)
                        zombie:getInventory():AddItem(clip)
                        PE_G93_sendAdd(zombie:getInventory(), clip)
                    end
                else
                    if GunMag2:hasTag(Gun93Registries.guns93.RareMag) then
                        RareMag2 = true
                    end
                    local magsD10 = ZombRand(0,10)
                    if magsD10 > 2 then
                        local newMag = instanceItem(GunMag2:getFullType())
                        local ammo = ZombRand(0, Gun:getMaxAmmo())
                        newMag:setCurrentAmmoCount(ammo)
                        DynamicMagClip(newMag)
                        zombie:getInventory():AddItem(newMag)
                        PE_G93_sendAdd(zombie:getInventory(), newMag)
                        if not RareMag2 then
                            for _ = 0, ZombRand(1,3)-1 do
                                local newMag = instanceItem(GunMag2:getFullType())
                                local ammo = ZombRand(0, Gun:getMaxAmmo())
                                newMag:setCurrentAmmoCount(ammo)
                                DynamicMagClip(newMag)
                                zombie:getInventory():AddItem(newMag)
                                PE_G93_sendAdd(zombie:getInventory(), newMag)
                            end
                        end
                    end
                end
            else
                local looseCount = ZombRand(20)
                local ammoType = Gun:getAmmoType()
                if ammoType and ammoType:getItemKey() then
                    for _ = 1, looseCount do
                        local ammo = instanceItem(ammoType:getItemKey())
                        if ammo then
                            zombie:getInventory():AddItem(ammo)
                            PE_G93_sendAdd(zombie:getInventory(), ammo)
                        end
                    end
                end
            end
            if Gun:getModData().hasClip then
                local clip = Gun:getModData().hasClip
                local clipNum = ZombRand(1,3)
                if instanceItem(clip):hasTag(Gun93Registries.guns93.StripperClip) then
                    clipNum = ZombRand(4,10)
                end
                if clip then
                    for _ = 0, clipNum-1 do
                        local newClip = instanceItem(clip)
                        local ammo = ZombRand(0, newClip:getMaxAmmo())
                        newClip:setCurrentAmmoCount(ammo)
                        DynamicMagClip(newClip)
                        zombie:getInventory():AddItem(newClip)
                        PE_G93_sendAdd(zombie:getInventory(), newClip)
                    end
                end
            end
            if Gun:getModData().hasLoader then
                local loader = nil
                if ZombRand(0,10) > 7 then
                    loader = Gun:getModData().hasLoader
                elseif ZombRand(0,10) > 8 and Gun:getModData().hasLoader2 then
                    loader = Gun:getModData().hasLoader2
                elseif ZombRand(0,10) > 8 and Gun:getModData().hasLoader3 then
                    loader = Gun:getModData().hasLoader3
                end
                if loader then
                    for _ = 0, ZombRand(1,3)-1 do
                        local newLoader = instanceItem(loader)
                        if ZombRand(0,10) > 5 then
                            newLoader:setCurrentAmmoCount(newLoader:getMaxAmmo())
                        end
                        DynamicMagClip(newLoader)
                        zombie:getInventory():AddItem(newLoader)
                        PE_G93_sendAdd(zombie:getInventory(), newLoader)
                    end
                end
            end
        end
    end
end

Events.OnZombieUpdate.Add(Guns93ZombieGunSpawns)
Events.OnZombieDead.Add(Guns93ZombieDrops)
Events.OnZombieCreate.Add(Guns93ZombieGunSpawns)