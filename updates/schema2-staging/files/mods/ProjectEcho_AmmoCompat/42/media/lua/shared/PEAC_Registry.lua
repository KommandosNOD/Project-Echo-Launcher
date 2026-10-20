-- PROJECT ECHO Ammo Compatibility B42.21 (v0.2.8), shared client/server
-- No item ID replacements; no cross-caliber or silent inventory conversion.
-- The source files were provided by the PROJECT ECHO administrator 2026-10-13.
local C = rawget(_G, "ProjectEchoAmmoCompat") or {}
_G.ProjectEchoAmmoCompat = C
C.VERSION = "0.2.8"
C.groups = {
    ["9x19"] = { "SWMG.9x19_Bullet", "Base.Bullets9mm", "Base.Bullets9x19mm" },
    ["545x39"] = { "SWMG.545x39_Bullet", "Base.Bullets545x39" },
    ["762x39"] = { "SWMG.762x39_Bullet", "Base.Bullets762x39", "Base.76239Bullets" },
    ["762x54R"] = { "SWMG.762x54_Bullet", "Base.Bullets762x54R" },
    ["9x39"] = { "SWMG.9x39_Bullet", "Base.Bullets9x39mm" },
    ["12gaBuck"] = { "SWMG.12Gauge_Shell_Buckshot", "Base.ShotgunShells", "Base.12x70ShotgunShells" },
    ["12gaSlug"] = { "SWMG.12Gauge_Shell_Slug", "Base.SlugBullets" },
    ["45acp"] = { "SWMG.45_Bullet", "Base.Bullets45" },
    ["38sp"] = { "SWMG.38_Bullet", "Base.Bullets38" },
    ["357mag"] = { "SWMG.357_Bullet", "Base.Bullets357" },
    ["44mag"] = { "SWMG.44_Bullet", "Base.Bullets44" },
    ["308"] = { "SWMG.308_Bullet", "SWMG.762x51_Bullet", "Base.308Bullets" },
    ["3006"] = { "SWMG.3006_Bullet", "Base.3006Bullets" },
    ["556"] = { "SWMG.556x45_Bullet", "Base.556Bullets" },
    ["3030"] = { "SWMG.3030_Bullet", "Base.3030Bullets" },
    ["223"] = { "SWMG.223_Bullet" },
    ["50ae"] = { "SWMG.50_Bullet" },
    ["4570"] = { "SWMG.4570_Bullet" },
    ["22lr"] = { "Base.22Bullets", "Base.Bullets22LR" },
}
C.byType = {}
for caliber, types in pairs(C.groups) do
    for _, fullType in ipairs(types) do
        C.byType[fullType] = caliber
    end
end

function C.ammoKey(item)
    if not item or not item.getAmmoType then return nil end
    local enum = item:getAmmoType()
    if not enum then return nil end
    return enum:getItemKey()
end

-- Gunworks can register the weapon itself OR a caliber-conversion part.
-- Leave all those weapons to Gunworks' own AmmoList and reload implementation.
function C.isGunworks(item)
    if not item or not item.getFullType then return false end
    local ok, ammo = pcall(require, "WeaponSystems/Utils/Ammo")
    if not ok or not ammo then return false end
    if ammo.ItemAmmoFamily and ammo.ItemAmmoFamily[item:getFullType()] ~= nil then return true end
    if ammo.GetFamilyForItem then
        local worked, family = pcall(ammo.GetFamilyForItem, item)
        if worked and family then return true end
    end
    return false
end

-- Only use the generic per-round loader on standard/internal weapons.
-- B42 and Guns93 have separate systems for removable magazines, moon-clips,
-- registered speed-loaders, stripper clips, caliber-changing parts, and
-- weapons which consume powder/caps on each shot. NEVER bypass them.
function C.isSafeInternalGun(item)
    if not item or not item.getMagazineType or not item.getAmmoType
       or not item.getMaxAmmo or not item.getCurrentAmmoCount then return false end
    if C.isGunworks(item) or item:getMagazineType() then return false end
    if item.isContainsClip and item:isContainsClip() then return false end
    if item.getWeaponPart and item:getWeaponPart("Moonclip") then return false end
    if item.getMaxAmmo and item:getMaxAmmo() < 1 then return false end
    local reg = rawget(_G, "Gun93Registries")
    local tags = reg and reg.guns93
    if tags and item.hasTag then
        for _, k in ipairs({"MoonClip", "SpeedLoader", "StripperClip"}) do
            if tags[k] and item:hasTag(tags[k]) then return false end
        end
    end
    local ok, speed = pcall(require, "WeaponSystems/Utils/SpeedLoader")
    if ok and speed and speed.IsRegisteredGun then
        local worked, registered = pcall(speed.IsRegisteredGun, item)
        if worked and registered then return false end
    end
    local ro, anim = pcall(require, "WeaponSystems/Utils/ReloadAnim")
    if ro and anim and anim.GetConsumeItemsForGun then
        local worked, consumes = pcall(anim.GetConsumeItemsForGun, item)
        if worked and consumes then return false end
    end
    return true
end

function C.isBulletPresent(fullType)
    local sm = getScriptManager and getScriptManager()
    return sm and sm:FindItem(fullType) ~= nil
end

-- Guns of '93 uses Base.ShotgunShells for buckshot and guns93:bullets_slug
-- (registered by Guns93 registries.lua as Base.SlugBullets) for slugs.
-- Never infer a caliber solely from weapon name, or mix these two modes.
function C.isGuns93Shotgun(item)
    if not item or not item.getAmmoType or not item.hasTag then return false end
    local tags = rawget(_G, "Gun93Registries")
    local gun93tag = tags and tags.guns93 and tags.guns93.Guns93
    if not gun93tag or not item:hasTag(gun93tag) then return false end
    local ammoKey = C.ammoKey(item)
    return ammoKey == "Base.ShotgunShells" or ammoKey == "Base.SlugBullets"
end

-- Gunworks tracks each physical round in AmmoList on some Guns93 weapons.
-- Recover a homogeneous stack's lineage, but refuse unknown or mixed stacks.
local function recordedCompatibleRound(item, original)
    if not item or not original then return nil end
    local md = item:getModData()
    if not md then return nil end
    local stored = md.PEAC_LoadedAmmoType
    local list = md.AmmoList
    if type(list) == "table" and #list > 0 then
        -- Gunworks' physical-round list takes precedence over a stale PEAC marker.
        local first = list[1]
        if not C.isCompatible(original, first) then return nil end
        for i = 2, #list do
            if list[i] ~= first then return nil end
        end
        if stored and stored ~= first then return nil end
        return first
    end
    if stored and C.isCompatible(original, stored) then return stored end
    return nil
end

function C.isCompatible(reference, candidate)
    if not reference or not candidate then return false end
    local family = C.byType[reference]
    return family ~= nil and C.byType[candidate] == family
end

-- Only pick a different type if the original is not available, or the item
-- already has a magazine-load type stored. Never mix different types in the
-- same partly loaded vanilla magazine/weapon.
function C.choose(item, inventory)
    if not item or not inventory or C.isGunworks(item) then return nil end
    if item.getMagazineType and not C.isSafeInternalGun(item) then return nil end
    local original = C.ammoKey(item)
    local family = original and C.byType[original]
    if not family then return nil end
    local loaded = item:getCurrentAmmoCount() or 0
    local chambered = item.haveChamber and item:haveChamber()
                    and item.isRoundChambered and item:isRoundChambered()
    local md = item:getModData()
    if loaded == 0 and not chambered and md then
        md.PEAC_LoadedAmmoType = nil
    end
    local marked = (loaded > 0 or chambered) and recordedCompatibleRound(item, original) or nil
    -- Unknown loaded ammunition: never add a different physical type.
    if (loaded > 0 or chambered) and not marked then return nil end
    if marked then
        if marked == original then return nil end -- leave original stack to standard loader
        if inventory:getCountTypeRecurse(marked) > 0 then return marked end
        return nil
    end
    if inventory:getCountTypeRecurse(original) > 0 then return nil end
    for _, candidate in ipairs(C.groups[family]) do
        if candidate ~= original and C.isBulletPresent(candidate)
           and inventory:getCountTypeRecurse(candidate) > 0 then
            return candidate
        end
    end
    return nil
end

function C.canUseAlias(item, candidate)
    if not item or not candidate or C.isGunworks(item) then return false end
    if item.getMagazineType and not C.isSafeInternalGun(item) then return false end
    local original = C.ammoKey(item)
    if original == candidate or not C.isCompatible(original, candidate) then return false end
    if not C.isBulletPresent(candidate) then return false end
    local loaded = item:getCurrentAmmoCount() or 0
    local chambered = item.haveChamber and item:haveChamber()
                    and item.isRoundChambered and item:isRoundChambered()
    if loaded > 0 or chambered then
        return recordedCompatibleRound(item, original) == candidate
    end
    return true
end

-- Explicit context-menu choices, including when OEM ammunition is present.
-- Never include an unknown caliber, a loaded incompatible round, or the
-- weapon's native ammunition (vanilla already exposes native loading).
function C.availableAliases(item, inventory)
    local out = {}
    if not item or not inventory then return out end
    if item.getMagazineType and not C.isSafeInternalGun(item) then return out end
    local native = C.ammoKey(item)
    local family = native and C.byType[native]
    if not family then return out end
    for _, candidate in ipairs(C.groups[family]) do
        if candidate ~= native and C.canUseAlias(item, candidate)
            and inventory:getCountTypeRecurse(candidate) > 0 then
            out[#out + 1] = candidate
        end
    end
    return out
end

function C.getLoadedAlias(item)
    if not item or C.isGunworks(item) then return nil end
    local original = C.ammoKey(item)
    local key = recordedCompatibleRound(item, original)
    if key and key ~= original then return key end
    return nil
end

function C.log(str)
    print("[PE AmmoCompat v" .. C.VERSION .. "] " .. tostring(str))
end

return C
