require "VPCADS/VPCADS_Defaults"

--[[
Hand-set per-weapon data that the mesh scan cannot know. Everything else comes from
VPCADS_GeneratedProfiles.lua (measured from the installed meshes) and the family defaults.
These entries are harmless when the pack is not installed: they are only read for items that exist.
]]

-- Families the name heuristics get wrong
VPCADS.RegisterWeaponProfile("Base.SPRSD",        { family = "sniper" })
VPCADS.RegisterWeaponProfile("Base.AssaultRifleM1", { family = "battlerifle" })
VPCADS.RegisterWeaponProfile("Base.M2400_Rifle",  { family = "sniper" })
VPCADS.RegisterWeaponProfile("Base.Revolver_Long", { relief = 0.19 })
VPCADS.RegisterWeaponProfile("Base.Vector45",     { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.Vector9",      { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.P90",          { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.MP7",          { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.MAC10Unfolded", { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.MAC10Folded",  { family = "smg", relief = 0.16 })
VPCADS.RegisterWeaponProfile("Base.UziUnfolded",  { family = "smg" })
VPCADS.RegisterWeaponProfile("Base.UziFolded",    { family = "smg", relief = 0.16 })
VPCADS.RegisterWeaponProfile("Base.Tec9",         { family = "pistol" })
VPCADS.RegisterWeaponProfile("Base.Glock18",      { family = "pistol", recoilMul = 0.8, kickMul = 0.55, recover = 0.45 })

-- Rifles whose mesh has no usable irons (scope-only bolt guns): ADS still works, aligned on the
-- receiver top; with an optic mounted the optic takes over.
VPCADS.RegisterWeaponProfile("Base.SniperRifle",  { family = "sniper" })
VPCADS.RegisterWeaponProfile("Base.MSR7T_Rifle",  { family = "sniper" })

-- Sawn-off guns are pointed, not aimed: shorter, quicker, a little less zoom.
for _, id in ipairs({ "Base.ShotgunSawnoff", "Base.ShotgunSawnoffNoStock", "Base.DoubleBarrelShotgunSawnoff",
                      "Base.DoubleBarrelShotgunSawnoffNoStock", "Base.MP153sawn" }) do
    VPCADS.RegisterWeaponProfile(id, { adsTime = 0.2, fovMul = 0.95, relief = 0.15 })
end

-- Toys
VPCADS.RegisterWeaponProfile("Base.Revolver_CapGun", { family = "pistol", recoilMul = 0.1, kickMul = 0.1 })
VPCADS.RegisterWeaponProfile("Base.Rifle_CapGun",    { family = "carbine", recoilMul = 0.1, kickMul = 0.1 })

VPCADS.Registry.duplicates = {}
