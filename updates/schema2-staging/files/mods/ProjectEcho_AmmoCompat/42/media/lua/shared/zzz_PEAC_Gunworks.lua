local C = require("PEAC_Registry")
local applied = false
local function register()
    if applied then return end
    local ok, Ammo = pcall(require, "WeaponSystems/Utils/Ammo")
    if not ok or not Ammo or not Ammo.FindBulletEntry or not Ammo.RegisterAmmoFamily then return end
    -- Wait for Guns of Marz to populate its caliber registry. A premature
    -- require() of Gunworks can otherwise return an empty registry.
    if not Ammo.FindBulletEntry("SWMG.545x39_Bullet") then return end
    -- Registration is additive; the canonical enum and ballistic profile are
    -- reused, so Gunworks' built-in AmmoList preserves each physical round key.
    local added = 0
    for _, list in pairs(C.groups) do
        local canonical = nil
        for _, itemKey in ipairs(list) do
            local entry, family = Ammo.FindBulletEntry(itemKey)
            if entry and family then
                canonical = {entry=entry, family=family}
                break
            end
        end
        if canonical then
            for _, candidate in ipairs(list) do
                local registered = Ammo.FindBulletEntry(candidate)
                if not registered and C.isBulletPresent(candidate) then
                    Ammo.RegisterAmmoFamily(canonical.family, {{
                        type = candidate,
                        enum = canonical.entry.enum,
                        profile = canonical.entry.profile
                    }})
                    added = added + 1
                end
            end
        end
    end
    applied = true
    C.log("Gunworks ammunition aliases added: " .. added)
end
-- OnGameBoot is after shared Lua initialization. Execute once immediately if
-- possible, and retry at the early boot event for reordered mod sets.
register()
if Events and Events.OnGameBoot then Events.OnGameBoot.Add(register) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(register) end
