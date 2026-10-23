require "VPCADS/VPCADS_Weapons"

--[[
Guns of Marz (Workshop 3722134990, module MarzGuns) compatibility.

Read from the pack's own scripts (items/weapons/*.txt, items/attachments/scopes.txt):
- GoM optics are ordinary weapon parts (PartType = Scope) whose models attach at the gun's "scope" attachment,
  so the runtime systems (iron sights measured on the loaded mesh, scope tube measurement, upside-down model
  detection, picture-in-picture) apply as they are. This file only says what each gun and optic IS.
- Magnifications follow the item names ("LR4X" = 4x, "TR06X" = 6x, "LR10X" = 10x, "LRX12X" = 12x, "Elcan X2" = 2x).
  GoM's "Sight" items are 1x red dot / holographic sights and are shown like the vanilla red dot.
Harmless when Guns of Marz is not installed: entries are only read for items that exist.
]]

local function fam(family, ids, extra)
    for _, id in ipairs(ids) do
        local def = { family = family }
        if extra then for k, v in pairs(extra) do def[k] = v end end
        VPCADS.RegisterWeaponProfile("MarzGuns." .. id, def)
    end
end

-- ---------------------------------------------------------------- weapons (by the pack's own file categories)
fam("assault",     { "M16A1", "M16A2", "M16A2_M203", "M16A3", "AR15", "FNC", "FAMAS", "G36", "AK74", "AK47" })
fam("carbine",     { "CAR15", "XM177", "M4A1", "G36C", "AKS74U", "ASVAL" })
fam("battlerifle", { "M14", "M1_GARAND", "FAL", "G3" })
fam("sniper",      { "MOSIN", "M24", "M1903", "REMINGTON_700", "MODEL_70", "SVD", "PSG1" })
fam("carbine",     { "SKS", "CAMP_CARBINE", "MINI_14", "W1894", "M1895", "W1873", "W1873_CARBINE" })
fam("shotgun",     { "BENELLI_M4", "SPAS12", "AA12" })
-- bead sight only (no rear sight): the eye looks along the top of the receiver to the bead
fam("shotgun",     { "W1887", "MOSSBERG_590", "TRENCHGUN", "STEVENS_555", "DOUBLEBARREL", "REMINGTON_870", "TOZ34" }, { bead = true })
fam("machinegun",  { "M60", "BAR" })
fam("smg",         { "THOMPSON", "MP5", "MP5SD", "MP5A2" })
fam("smg",         { "MP5K", "MAC10" }, { relief = 0.16 })       -- handgun-held SMGs: closer, like the folded MAC-10
fam("pistol",      { "M92FS", "M93R", "HIPOWER", "P226", "M1911", "USP", "DEAGLE", "VP70M", "TEC9" })
fam("pistol",      { "SW629", "PYTHON", "RHINO", "MP412", "COLT_SINGLE", "DETECTIVE_38" })

-- ---------------------------------------------------------------- optics
-- glass: the lens faces of each sight in its own mesh space { x0, x1, z0, z1, y, round }, read from
-- GunsOfMarz media/models_X/weapons/parts/scopes.fbx (the light faces facing along the bore; checked on a
-- rear-view render of every sight). The clear view and the eye are placed on exactly that glass.
local function redDot(id, reticle, glass)
    VPCADS.RegisterOpticProfile("MarzGuns." .. id, { kind = "scope", mag = 1.3, reticle = reticle or "dot", lensScale = 0.95, swayMul = 0.87, zero = 50, glass = glass })
end
local function scope(id, mag, reticle, zero)
    VPCADS.RegisterOpticProfile("MarzGuns." .. id, { kind = "scope", mag = mag, reticle = reticle, zero = zero or 100 })
end

-- long-gun red dots / holographic sights
redDot("ReflexS2_Sight", nil,   { -0.0079, 0.0079, -0.0190, -0.0100, 0.0140 })
redDot("Kobra_Sight", nil,      { -0.0087, 0.0087, -0.0301, -0.0127, 0.0270, true })
redDot("OKP3_Sight", nil,       { -0.0094, 0.0094, -0.0336, -0.0148, 0.0251, true })
redDot("JS14_Sight", nil,       { -0.0070, 0.0070, -0.0258, -0.0118, -0.0031, true })
redDot("Aimpoint_Sight", nil,   { -0.0100, 0.0100, -0.0445, -0.0203, 0.0239, true })
redDot("EXPS3_Sight", "holo",   { -0.0069, 0.0069, -0.0269, -0.0145, 0.0167 })
redDot("EXPS1_Sight", "holo",   { -0.0095, 0.0095, -0.0372, -0.0211, -0.0245 })
-- pistol red dots
redDot("PL4_Sight", nil,        { -0.0091, 0.0091, 0.0161, 0.0278, 0.0098 })
redDot("PS1_Sight", nil,        { -0.0073, 0.0073, 0.0137, 0.0245, 0.0090 })
redDot("PM2_Sight", nil,        { -0.0072, 0.0072, 0.0185, 0.0351, 0.0262, true })

-- magnified scopes
scope("ElcanX2_Scope", 2,  "elcan_post")
scope("LR4X_Scope",    4,  "german4")
scope("TA28_Scope",    4,  "acog_ta31f")
scope("PSO1_Scope",    4,  "pso1_real")
scope("TR06X_Scope",   6,  "accupoint_triangle")
scope("LR10X_Scope",   10, "mildot_real", 150)
scope("LRX12X_Scope",  12, "tmr_real", 200)
scope("PRL1_Scope",    2,  "duplex_real", 25)                         -- pistol / revolver scope

-- ---------------------------------------------------------------- calibration (1.6.2)
-- Tuned in game with the F9 calibrator by tester Brian21699 [TPCR] (Discord #calibration, 2026-10-07).
-- Only values that differ from what the profiles above already resolve to are listed: assault/shotgun family
-- relief, ADS FOV and ADS time, the red dots' 0.95 lens size and the scopes' 0.80 lens size are unchanged.
-- Per weapon + optic (optic "" = iron sights), so nothing carries over to other guns or sights.
local function cal(weapon, optic, def)
    VPCADS.RegisterWeaponOpticOverride("MarzGuns." .. weapon, optic == "" and "" or ("MarzGuns." .. optic), def)
end

-- AA12 (no optics on this gun)
cal("AA12", "",                { adjZ = 0.0006, adjPitch = -0.375 })

-- AK47
cal("AK47", "",                { adjZ = 0.0012, adjPitch = -0.80 })
cal("AK47", "LRX12X_Scope",    { pipScale = 1.02, pipZoom = 1.20 })
cal("AK47", "TA28_Scope",      { pipY = -0.05, pipScale = 1.02 })
cal("AK47", "ElcanX2_Scope",   { pipScale = 1.025 })
cal("AK47", "ReflexS2_Sight",  { pipZ = 0.020 })
cal("AK47", "Kobra_Sight",     { pipZ = 0.058 })
cal("AK47", "OKP3_Sight",      { pipZ = 0.016 })
cal("AK47", "JS14_Sight",      { pipScale = 1.30 })
cal("AK47", "EXPS1_Sight",     { pipScale = 1.90 })
-- AK47 LR10X, LR4X, TR06X, PSO1 and EXPS3: already right

-- AK74
cal("AK74", "",                { adjPitch = -1.70 })
cal("AK74", "TA28_Scope",      { pipY = -0.05 })
cal("AK74", "ReflexS2_Sight",  { pipScale = 0.80 })
cal("AK74", "Kobra_Sight",     { pipScale = 0.60 })
cal("AK74", "OKP3_Sight",      { pipZ = 0.016 })
cal("AK74", "JS14_Sight",      { pipScale = 1.30 })
cal("AK74", "EXPS1_Sight",     { pipScale = 1.90 })
-- AK74 EXPS3 (PiP lens size 1.00), LR4X, ElcanX2, TR06X, PSO1 and LRX12X: already right

-- Newer Marz pistols and break-action shotgun use the existing family handling.
fam("pistol", { "GLOCK17" })
fam("shotgun", { "DOUBLE_DEUCE" }, { bead = true })

-- The G36's lens is built into its body, so findOptic() cannot discover it as an attachment.
-- A mounted sight takes priority over the built-in 1x red dot.
VPCADS.RegisterADSAdapter("Marz G36 integrated sight", function(weapon, p, part)
    if weapon:getFullType() == "MarzGuns.G36" and not part then
        p.integratedOptic = true
        p.nativeOpticProfile = true
        p.mode = "scope"; p.mag = 1; p.reticle = "dot"
        p.opticId = "MarzGuns.G36.integrated"
        p.opticWindow = 0.0062; p.relief = 0.11; p.lensScale = 0.8
        p.zero = 50
    end
end)
