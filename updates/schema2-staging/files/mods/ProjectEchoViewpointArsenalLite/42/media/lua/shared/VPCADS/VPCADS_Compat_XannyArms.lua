require "VPCADS/VPCADS_Weapons"
-- Xanny Arms GunPack 0.2.4-release-tech1: native model mounts remain owned by the pack.
local models, optics = {}, {}
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M1", d)
models["XannyArms.XA_M1"] = d
models["XA_M1"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_ColtPython", d)
models["XannyArms.XA_ColtPython"] = d
models["XA_ColtPython"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_COP357", d)
models["XannyArms.XA_COP357"] = d
models["XA_COP357"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Marlin1894", d)
models["XannyArms.XA_Marlin1894"] = d
models["XA_Marlin1894"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M1910", d)
models["XannyArms.XA_M1910"] = d
models["XA_M1910"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M1911A1", d)
models["XannyArms.XA_M1911A1"] = d
models["XA_M1911A1"] = d
local d = { family = "smg", relief = 0.16 }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MAC10", d)
models["XannyArms.XA_MAC10"] = d
models["XA_MAC10"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MK23", d)
models["XannyArms.XA_MK23"] = d
models["XA_MK23"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_UMP45", d)
models["XannyArms.XA_UMP45"] = d
models["XA_UMP45"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_USP45", d)
models["XannyArms.XA_USP45"] = d
models["XA_USP45"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_S_WM500", d)
models["XannyArms.XA_S_WM500"] = d
models["XA_S_WM500"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_RSh12", d)
models["XannyArms.XA_RSh12"] = d
models["XA_RSh12"] = d
local d = { family = "shotgun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_DP12", d)
models["XannyArms.XA_DP12"] = d
models["XA_DP12"] = d
local d = { family = "shotgun", bead = true }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Mossberg590", d)
models["XannyArms.XA_Mossberg590"] = d
models["XA_Mossberg590"] = d
local d = { family = "shotgun", bead = true }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Remington870", d)
models["XannyArms.XA_Remington870"] = d
models["XA_Remington870"] = d
local d = { family = "shotgun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Saiga12K", d)
models["XannyArms.XA_Saiga12K"] = d
models["XA_Saiga12K"] = d
local d = { family = "shotgun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_USAS12", d)
models["XannyArms.XA_USAS12"] = d
models["XA_USAS12"] = d
local d = { family = "shotgun", bead = true }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Winchester1887", d)
models["XannyArms.XA_Winchester1887"] = d
models["XA_Winchester1887"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_AK74M", d)
models["XannyArms.XA_AK74M"] = d
models["XA_AK74M"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_ADAR215", d)
models["XannyArms.XA_ADAR215"] = d
models["XA_ADAR215"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_AR15SAIGRY", d)
models["XannyArms.XA_AR15SAIGRY"] = d
models["XA_AR15SAIGRY"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Colt723", d)
models["XannyArms.XA_Colt723"] = d
models["XA_Colt723"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_G36K", d)
models["XannyArms.XA_G36K"] = d
models["XA_G36K"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_HK416A5", d)
models["XannyArms.XA_HK416A5"] = d
models["XA_HK416A5"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_HoneyBadger", d)
models["XannyArms.XA_HoneyBadger"] = d
models["XA_HoneyBadger"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M16A1", d)
models["XannyArms.XA_M16A1"] = d
models["XA_M16A1"] = d
local d = { family = "machinegun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M249", d)
models["XannyArms.XA_M249"] = d
models["XA_M249"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.M4A1", d)
models["XannyArms.Xanny_M4A1"] = d
models["Xanny_M4A1"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M4SOPMODII", d)
models["XannyArms.XA_M4SOPMODII"] = d
models["XA_M4SOPMODII"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Mini14", d)
models["XannyArms.XA_Mini14"] = d
models["XA_Mini14"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Remington700", d)
models["XannyArms.XA_Remington700"] = d
models["XA_Remington700"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_SG552", d)
models["XannyArms.XA_SG552"] = d
models["XA_SG552"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_TT33", d)
models["XannyArms.XA_TT33"] = d
models["XA_TT33"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Type64", d)
models["XannyArms.XA_Type64"] = d
models["XA_Type64"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_AK15", d)
models["XannyArms.XA_AK15"] = d
models["XA_AK15"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_AK47", d)
models["XannyArms.XA_AK47"] = d
models["XA_AK47"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_AKM", d)
models["XannyArms.XA_AKM"] = d
models["XA_AKM"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MD63", d)
models["XannyArms.XA_MD63"] = d
models["XA_MD63"] = d
local d = { family = "machinegun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_RPD", d)
models["XannyArms.XA_RPD"] = d
models["XA_RPD"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_SKS", d)
models["XannyArms.XA_SKS"] = d
models["XA_SKS"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Type56", d)
models["XannyArms.XA_Type56"] = d
models["XA_Type56"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Type56C", d)
models["XannyArms.XA_Type56C"] = d
models["XA_Type56C"] = d
local d = { family = "carbine" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Type63", d)
models["XannyArms.XA_Type63"] = d
models["XA_Type63"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Type81", d)
models["XannyArms.XA_Type81"] = d
models["XA_Type81"] = d
local d = { family = "assault" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Vz58", d)
models["XannyArms.XA_Vz58"] = d
models["XA_Vz58"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_DVL10", d)
models["XannyArms.XA_DVL10"] = d
models["XA_DVL10"] = d
local d = { family = "battlerifle" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_FAL", d)
models["XannyArms.XA_FAL"] = d
models["XA_FAL"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M110", d)
models["XannyArms.XA_M110"] = d
models["XA_M110"] = d
local d = { family = "battlerifle" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M14", d)
models["XannyArms.XA_M14"] = d
models["XA_M14"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M24", d)
models["XannyArms.XA_M24"] = d
models["XA_M24"] = d
local d = { family = "machinegun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M60", d)
models["XannyArms.XA_M60"] = d
models["XA_M60"] = d
local d = { family = "battlerifle" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MCXSpear", d)
models["XannyArms.XA_MCXSpear"] = d
models["XA_MCXSpear"] = d
local d = { family = "battlerifle" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MK17", d)
models["XannyArms.XA_MK17"] = d
models["XA_MK17"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MK20", d)
models["XannyArms.XA_MK20"] = d
models["XA_MK20"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Remington788", d)
models["XannyArms.XA_Remington788"] = d
models["XA_Remington788"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MosinNagant", d)
models["XannyArms.XA_MosinNagant"] = d
models["XA_MosinNagant"] = d
local d = { family = "machinegun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_PKM", d)
models["XannyArms.XA_PKM"] = d
models["XA_PKM"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_SVD", d)
models["XannyArms.XA_SVD"] = d
models["XA_SVD"] = d
local d = { family = "sniper" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Kar98K", d)
models["XannyArms.XA_Kar98K"] = d
models["XA_Kar98K"] = d
local d = { family = "machinegun" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MG42", d)
models["XannyArms.XA_MG42"] = d
models["XA_MG42"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_APS", d)
models["XannyArms.XA_APS"] = d
models["XA_APS"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_PB", d)
models["XannyArms.XA_PB"] = d
models["XA_PB"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_PM", d)
models["XannyArms.XA_PM"] = d
models["XA_PM"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Glock18", d)
models["XannyArms.XA_Glock18"] = d
models["XA_Glock18"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_M9", d)
models["XannyArms.XA_M9"] = d
models["XA_M9"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MP443", d)
models["XannyArms.XA_MP443"] = d
models["XA_MP443"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_MP5SD", d)
models["XannyArms.XA_MP5SD"] = d
models["XA_MP5SD"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_P226", d)
models["XannyArms.XA_P226"] = d
models["XA_P226"] = d
local d = { family = "pistol" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_P38", d)
models["XannyArms.XA_P38"] = d
models["XA_P38"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_RO635", d)
models["XannyArms.XA_RO635"] = d
models["XA_RO635"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_UMP9", d)
models["XannyArms.XA_UMP9"] = d
models["XA_UMP9"] = d
local d = { family = "smg" }
VPCADS.RegisterWeaponProfile("XannyArms.XA_Vector", d)
models["XannyArms.XA_Vector"] = d
models["XA_Vector"] = d
local d = { kind = "scope", mag = 10, reticle = "tmr_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_1P69_x10Scope", d)
optics["XannyArms.XA_1P69_x10Scope"] = d
optics["XA_1P69_x10Scope"] = d
local d = { kind = "scope", mag = 4, reticle = "pso1_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_PSO1_x4Scope", d)
optics["XannyArms.XA_PSO1_x4Scope"] = d
optics["XA_PSO1_x4Scope"] = d
local d = { kind = "scope", mag = 1, reticle = "holo", zero = 50 }
VPCADS.RegisterOpticProfile("XannyArms.Holo", d)
optics["XannyArms.Xanny_EOTech"] = d
optics["Xanny_EOTech"] = d
local d = { kind = "scope", mag = 6, reticle = "tmr_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_EOTech_Vudu_x6Scope", d)
optics["XannyArms.XA_EOTech_Vudu_x6Scope"] = d
optics["XA_EOTech_Vudu_x6Scope"] = d
local d = { kind = "scope", mag = 1, reticle = "holo", zero = 50 }
VPCADS.RegisterOpticProfile("XannyArms.XA_EOTech_XPS3_2_x1Scope", d)
optics["XannyArms.XA_EOTech_XPS3_2_x1Scope"] = d
optics["XA_EOTech_XPS3_2_x1Scope"] = d
local d = { kind = "scope", mag = 6, reticle = "tmr_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_SIG_Sauer_TANGO6T_x6Scope", d)
optics["XannyArms.XA_SIG_Sauer_TANGO6T_x6Scope"] = d
optics["XA_SIG_Sauer_TANGO6T_x6Scope"] = d
local d = { kind = "scope", mag = 4, reticle = "acog_ta31f", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_Trijicon_ACOG_Black_x4Scope", d)
optics["XannyArms.XA_Trijicon_ACOG_Black_x4Scope"] = d
optics["XA_Trijicon_ACOG_Black_x4Scope"] = d
local d = { kind = "scope", mag = 4, reticle = "acog_ta31f", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_Trijicon_ACOG_FDE_x4Scope", d)
optics["XannyArms.XA_Trijicon_ACOG_FDE_x4Scope"] = d
optics["XA_Trijicon_ACOG_FDE_x4Scope"] = d
local d = { kind = "scope", mag = 6, reticle = "tmr_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.Scope", d)
optics["XannyArms.Xanny_Razor"] = d
optics["Xanny_Razor"] = d
local d = { kind = "scope", mag = 8, reticle = "tmr_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_Vortex_Strike_Eagle_x8Scope", d)
optics["XannyArms.XA_Vortex_Strike_Eagle_x8Scope"] = d
optics["XA_Vortex_Strike_Eagle_x8Scope"] = d
local d = { kind = "scope", mag = 6, reticle = "duplex_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_LeupoldM8_x6Scope", d)
optics["XannyArms.XA_LeupoldM8_x6Scope"] = d
optics["XA_LeupoldM8_x6Scope"] = d
local d = { kind = "scope", mag = 3, reticle = "duplex_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_PU_x3Scope", d)
optics["XannyArms.XA_PU_x3Scope"] = d
optics["XA_PU_x3Scope"] = d
local d = { kind = "scope", mag = 9, reticle = "mildot_real", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_RedfieldART_x9Scope", d)
optics["XannyArms.XA_RedfieldART_x9Scope"] = d
optics["XA_RedfieldART_x9Scope"] = d
local d = { kind = "scope", mag = 4, reticle = "german4", zero = 100 }
VPCADS.RegisterOpticProfile("XannyArms.XA_ZF39_x4Scope", d)
optics["XannyArms.XA_ZF39_x4Scope"] = d
optics["XA_ZF39_x4Scope"] = d
VPCADS.RegisterADSAdapter("Xanny Arms loaded models", function(weapon, p, part)
    local model = weapon.getWeaponSprite and weapon:getWeaponSprite()
    local d = model and models[model]
    if d then
        if p.family ~= d.family then
            p.family = d.family
            for k, v in pairs(VPCADS.Families[d.family] or {}) do
                if k ~= "ironHeight" then p[k] = v end
            end
        end
        if not part and d.bead then p.bead = true end
        if d.relief then p.relief = d.relief end
    end
    if part then
        local model = part.getStaticModel and part:getStaticModel()
        local o = model and optics[model]
        if o then
            p.nativeOpticProfile = true
            p.mode = "scope"; p.mag = o.mag; p.reticle = o.reticle; p.zero = o.zero
            p.opticModel = model
        end
    end
end)
