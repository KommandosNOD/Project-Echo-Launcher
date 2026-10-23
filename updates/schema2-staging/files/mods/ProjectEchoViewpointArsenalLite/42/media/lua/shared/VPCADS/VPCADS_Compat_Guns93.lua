require "VPCADS/VPCADS_Weapons"
-- Guns of 93 0.8.2.7A: generated from installed firearm/attachment scripts.
local function active()
 local ok, mods = pcall(getActivatedMods)
 if not ok or not mods then return false end
 for i=0,mods:size()-1 do if tostring(mods:get(i)):gsub("^\\+", "")=="guns93" then return true end end
 return false
end
local applied=false
local function apply()
 if applied or not active() then return end
 applied=true
 VPCADS.RegisterWeaponProfile("Base.83Cheetah", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.AC556K", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.AKM", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.AKSport", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.AR15", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.AR180", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Anaconda", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Auto5", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Auto5_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.BHP", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.BenelliM3", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.BenelliM3_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Beretta682", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Beretta682_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Beretta92FS", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Bobcat", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Brown3006BAR", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Brown308BAR", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.BrownCitori", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.BrownCitori_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Buckmark", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.CAR15", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.CZ75B", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.CalicoPistol", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.CalicoRifle", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Colt9mm", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.ColtArmy", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtArmy357", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtArmy357_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtDet", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtLawman", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtLawman_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtTrooper", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.ColtTrooper_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Command1911", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.DE357", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.DE44", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.DR200", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.DWK1A", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.DWK1A1", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.DWK2", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.DeltaElite", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Diamondback", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Diamondback22", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Dissy", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.FAL", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.FNC", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.GP100", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.GP100_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock17", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock17L", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock19", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock20", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock21", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock22", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock23", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Glock24", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Gov1911", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.HBAR", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.HK91", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Hammerless", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37MP", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37MP_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37Riot", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37Riot_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Ithaca37_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.J22", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Javelina", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.KingCobra", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.KingCobra_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.L395K", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.L395K_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Longslide", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.M14308", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M16A2", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M1903", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.M1911", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.M1917", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.M1A", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M1ABush", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M1Carbine", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M1Garand", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M24", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.M249", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M37", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M37_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M3GreaseGun", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M590", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M590_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M60", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M635", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M723", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M727", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M733", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.M870", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M870_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.M9", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MAC10", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MP5", { family = "smg" })
 VPCADS.RegisterWeaponProfile("Base.Marlin3363030", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Marlin33644", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Marlin39A", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Marlin45", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Marlin60", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Marlin9", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Mauser98K", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.MicroUzi", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MicroUzi45", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Mini14", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Mini14GB", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Mini30", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.MiniUzi", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MiniUzi45", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MiniUziCar", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.MiniUziCar45", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Moss500", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Moss500_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Moss590", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Moss590_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Officer1911", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.P226", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.P228", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.P380", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.P7M13", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.P7M8", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.PPK", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Python", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Python_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.R223Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R223Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R223RugM77", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R3006Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R3006RugM77", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R3030Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R308Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R308Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R308RugM77", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.R44Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Raven25", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Rem1100", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem1100_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem1187P", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem1187P_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem223760", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Rem30067400", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Rem3006760", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Rem3087400", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.Rem308760", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Rem870", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem870P", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem870P_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rem870_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Rug1022", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.RugP89", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.RugP90", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Rugmark", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SKS", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.SOAuto5", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOAuto5_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOBeretta682", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOBeretta682_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOBrownCitori", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOBrownCitori_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOIthaca37", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOIthaca37_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOL395K", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOL395K_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOM24", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOMoss500", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOMoss500_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOR223Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR223Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR3006Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR3030Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR308Rem700", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR308Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOR44Rem788", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SORem1100", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SORem1100_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SORem870", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SORem870_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOSavageFox", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOSavageFox_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOStoegerUplander", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOStoegerUplander_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOW223WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOW3006WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOW308WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1200", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1200_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1400", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1400_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1912", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin1912_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin37", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SOWin37_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SP101", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SP101_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SPAS12", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SPAS12_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SW10", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW17", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW29", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW36", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW4006", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW4506", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW586", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW586_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW5906", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW625", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW65", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SW65_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SavageFox", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SavageFox_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.SecuritySix", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.SecuritySix_Alt", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.StoegerUplander", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.StoegerUplander_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.T56", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.TEC9", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.USP40", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.USP9", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Uzi", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Uzi45", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.UziCarbine", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.UziCarbine45", { family = "pistol" })
 VPCADS.RegisterWeaponProfile("Base.Valmet", { family = "assault" })
 VPCADS.RegisterWeaponProfile("Base.W223WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.W3006WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.W308WinM70", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win1200", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1200Def", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1200Def_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1200_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1400", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1400_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1912", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win1912_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win37", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win37_Alt", { family = "shotgun" })
 VPCADS.RegisterWeaponProfile("Base.Win61", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win69", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win943030", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win94357", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win94357_Alt", { family = "sniper" })
 VPCADS.RegisterWeaponProfile("Base.Win9445", { family = "sniper" })
 VPCADS.RegisterOpticProfile("Base.ARTScope", { kind = "scope", mag = 9, reticle = "mildot_real", zoomLevels = { 2, 4, 6, 9 } })
 VPCADS.RegisterOpticProfile("Base.AccuDot", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.AccuDotSilver", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.AccuDotSilver_On", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.AccuDot_On", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.ArmsonM16", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.ArmsonRail", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.CMore", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.CMore_On", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.M14ARTScope", { kind = "scope", mag = 9, reticle = "mildot_real", zoomLevels = { 2, 4, 6, 9 } })
 VPCADS.RegisterOpticProfile("Base.RedDot", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.RedDot_On", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.SinglePoint", { kind = "scope", mag = 1, reticle = "dot" })
 VPCADS.RegisterOpticProfile("Base.x10Scope", { kind = "scope", mag = 10, reticle = "mildot_real" })
 VPCADS.RegisterOpticProfile("Base.x10ScopeSilver", { kind = "scope", mag = 10, reticle = "mildot_real" })
 VPCADS.RegisterOpticProfile("Base.x2Scope", { kind = "scope", mag = 2, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x2ScopePistol", { kind = "scope", mag = 2, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x2ScopePistolSilver", { kind = "scope", mag = 2, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x2ScopeSilver", { kind = "scope", mag = 2, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x3Handle", { kind = "scope", mag = 3, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x3Scope", { kind = "scope", mag = 3, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x3ScopePistol", { kind = "scope", mag = 3, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x3ScopePistolSilver", { kind = "scope", mag = 3, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x3ScopeSilver", { kind = "scope", mag = 3, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4ACOG", { kind = "scope", mag = 4, reticle = "acog_ta31f" })
 VPCADS.RegisterOpticProfile("Base.x4AR180", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4Handle", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4Scope", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4ScopePistol", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4ScopePistolSilver", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x4ScopeSilver", { kind = "scope", mag = 4, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x6Scope", { kind = "scope", mag = 6, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x6ScopeSilver", { kind = "scope", mag = 6, reticle = "duplex_real" })
 VPCADS.RegisterOpticProfile("Base.x8Scope", { kind = "scope", mag = 8, reticle = "mildot_real" })
 VPCADS.RegisterOpticProfile("Base.x8ScopeSilver", { kind = "scope", mag = 8, reticle = "mildot_real" })
 VPCADS.RegisterADSAdapter("Guns93 optic power", function(weapon,p,part)
  if not part then return end
  local id=part:getFullType()
  if id=="Base.AccuDot" then p.reticle="none" end
  if id=="Base.AccuDotSilver" then p.reticle="none" end
  if id=="Base.CMore" then p.reticle="none" end
  if id=="Base.RedDot" then p.reticle="none" end
 end)
 -- Keep the visibility-first pose local to the installed Guns93 models, including colour variants.
 local clearanceModels = {
  ["308M14"] = true,
  ["308M14Camo"] = true,
  ["308M14SS"] = true,
  ["AC556K"] = true,
  ["AC556KSS"] = true,
  ["AKM"] = true,
  ["AKMSport"] = true,
  ["AR15A1Black"] = true,
  ["AR15A1Gray"] = true,
  ["AR15A2Black"] = true,
  ["AR15A2Gray"] = true,
  ["AR180"] = true,
  ["Auto5"] = true,
  ["BenelliM3"] = true,
  ["Beretta682"] = true,
  ["BrownBAR"] = true,
  ["BrownCitori"] = true,
  ["CAR15Black"] = true,
  ["CAR15Gray"] = true,
  ["CalicoRifle"] = true,
  ["Colt9mm"] = true,
  ["DR200"] = true,
  ["Dissy"] = true,
  ["FAL"] = true,
  ["FNCBlack"] = true,
  ["FNCGrey"] = true,
  ["HBAR"] = true,
  ["HK91"] = true,
  ["HK93"] = true,
  ["HK94"] = true,
  ["Ithaca37Blued"] = true,
  ["Ithaca37Gold"] = true,
  ["Ithaca37MPBlued"] = true,
  ["Ithaca37MPPark"] = true,
  ["Ithaca37MPSS"] = true,
  ["Ithaca37Park"] = true,
  ["Ithaca37RiotBlued"] = true,
  ["Ithaca37RiotPark"] = true,
  ["Ithaca37RiotSS"] = true,
  ["Ithaca37SS"] = true,
  ["Ithaca37Scene"] = true,
  ["K1A"] = true,
  ["K1A1"] = true,
  ["K2"] = true,
  ["L395K"] = true,
  ["M1903"] = true,
  ["M1917"] = true,
  ["M1ABush"] = true,
  ["M1Carbine"] = true,
  ["M1Garand"] = true,
  ["M24"] = true,
  ["M249"] = true,
  ["M24Camo"] = true,
  ["M3GreaseGun"] = true,
  ["M590"] = true,
  ["M60"] = true,
  ["M635"] = true,
  ["M723"] = true,
  ["M723Camo"] = true,
  ["M727"] = true,
  ["M727Camo"] = true,
  ["M733"] = true,
  ["M733Camo"] = true,
  ["M870"] = true,
  ["M870Blue"] = true,
  ["MP5"] = true,
  ["MP5SD"] = true,
  ["Marlin336"] = true,
  ["Marlin39A"] = true,
  ["Marlin60"] = true,
  ["MarlinCamp"] = true,
  ["Mauser98K"] = true,
  ["Mini14"] = true,
  ["Mini14Bullpup"] = true,
  ["Mini14GB"] = true,
  ["Mini14GBSS"] = true,
  ["Mini14SS"] = true,
  ["Mini14SSBullpup"] = true,
  ["Moss500Blue"] = true,
  ["Moss500Camo"] = true,
  ["Moss500Gray"] = true,
  ["Moss590Blue"] = true,
  ["Moss590Gray"] = true,
  ["Moss590Mariner"] = true,
  ["Rem1100Blue"] = true,
  ["Rem1100Gold"] = true,
  ["Rem1187PBlue"] = true,
  ["Rem1187PPark"] = true,
  ["Rem1187Park"] = true,
  ["Rem700"] = true,
  ["Rem700Bolt"] = true,
  ["Rem700Park"] = true,
  ["Rem7400"] = true,
  ["Rem760"] = true,
  ["Rem788"] = true,
  ["Rem870"] = true,
  ["Rem870Marine"] = true,
  ["Rem870P"] = true,
  ["Rem870PBlue"] = true,
  ["Rem870Park"] = true,
  ["Rug1022"] = true,
  ["RugM77"] = true,
  ["SKS"] = true,
  ["SOAuto5"] = true,
  ["SOBeretta682"] = true,
  ["SOBrownCitori"] = true,
  ["SOIthaca37Blued"] = true,
  ["SOIthaca37Gold"] = true,
  ["SOIthaca37Park"] = true,
  ["SOIthaca37SS"] = true,
  ["SOIthaca37Scene"] = true,
  ["SOL395K"] = true,
  ["SOM24"] = true,
  ["SOM24Camo"] = true,
  ["SOM870"] = true,
  ["SOMoss500Blue"] = true,
  ["SOMoss500Camo"] = true,
  ["SOMoss500Gray"] = true,
  ["SORem1100Blue"] = true,
  ["SORem1100Gold"] = true,
  ["SORem1100Park"] = true,
  ["SORem700"] = true,
  ["SORem700Bolt"] = true,
  ["SORem700Park"] = true,
  ["SORem788"] = true,
  ["SORem870"] = true,
  ["SORem870Marine"] = true,
  ["SORem870Park"] = true,
  ["SOSavageFox"] = true,
  ["SOSavageFox2Tone"] = true,
  ["SOSavageFoxCase"] = true,
  ["SOStoegerUplander"] = true,
  ["SOStoegerUplander2Tone"] = true,
  ["SOWin1200"] = true,
  ["SOWin1400"] = true,
  ["SOWin1912"] = true,
  ["SOWin37"] = true,
  ["SOWinM70"] = true,
  ["SOWinM70Bolt"] = true,
  ["SOWinM70SS"] = true,
  ["SPAS12"] = true,
  ["SavageFox"] = true,
  ["SavageFox2Tone"] = true,
  ["SavageFoxCase"] = true,
  ["StoegerUplander"] = true,
  ["StoegerUplander2Tone"] = true,
  ["T56"] = true,
  ["TommyM1928NoFins"] = true,
  ["TommyM1A1"] = true,
  ["UltraMatch"] = true,
  ["Valmet"] = true,
  ["Win1200"] = true,
  ["Win1200Def"] = true,
  ["Win1400"] = true,
  ["Win1912"] = true,
  ["Win37"] = true,
  ["Win61"] = true,
  ["Win69"] = true,
  ["Win94"] = true,
  ["WinM70"] = true,
  ["WinM70Bolt"] = true,
  ["WinM70SS"] = true,
 }
 VPCADS.RegisterADSAdapter("Guns93 clear receiver view", function(weapon,p,part)
  if part or p.family == "pistol" then return end
  local model = weapon.getWeaponSprite and weapon:getWeaponSprite()
  if model then model = tostring(model):gsub("^Base%.", "") end
  if clearanceModels[model] then p.guns93Clearance = true end
 end)
 local pistolModels = {
  ["BHPOld"] = true,
  ["BHPBlue"] = true,
  ["BHPMaria"] = true,
  ["M9"] = true,
  ["Beretta92Inox"] = true,
  ["Beretta92Ghost"] = true,
  ["DE44"] = true,
  ["DE44Black"] = true,
  ["DE44Gold"] = true,
  ["Gov1911Park"] = true,
  ["Gov1911Blue"] = true,
  ["Gov1911SS"] = true,
  ["Gov1911Black"] = true,
  ["Gov1911BiToneBlue"] = true,
  ["Gov1911BiToneSS"] = true,
  ["Com1911Park"] = true,
  ["Com1911Blue"] = true,
  ["Com1911SS"] = true,
  ["Com1911Black"] = true,
  ["Com1911BiToneBlue"] = true,
  ["Com1911BiToneSS"] = true,
  ["Officer1911Park"] = true,
  ["Officer1911Blue"] = true,
  ["Officer1911SS"] = true,
  ["Officer1911Black"] = true,
  ["Officer1911BiToneBlue"] = true,
  ["Officer1911BiToneSS"] = true,
  ["Longslide"] = true,
  ["Glock"] = true,
  ["GlockLong"] = true,
  ["GlockCompact"] = true,
  ["SW5906"] = true,
  ["SW4506"] = true,
  ["RugP89"] = true,
  ["P226"] = true,
  ["P228"] = true,
  ["P7M8"] = true,
  ["USP"] = true,
  ["CZ75B"] = true,
  ["TEC9"] = true,
  ["MAC10"] = true,
  ["Uzi"] = true,
  ["UziCarbine"] = true,
  ["MiniUzi"] = true,
  ["MiniUziCar"] = true,
  ["MicroUzi"] = true,
  ["CalicoPistol"] = true,
  ["Raven25"] = true,
  ["J22"] = true,
  ["P380"] = true,
  ["83Cheetah"] = true,
  ["Hammerless"] = true,
  ["PPK"] = true,
  ["Bobcat"] = true,
  ["Buckmark"] = true,
  ["Rugmark"] = true,
  ["SW625"] = true,
  ["SW29"] = true,
  ["SW629"] = true,
  ["SW36"] = true,
  ["SW60"] = true,
  ["SW10"] = true,
  ["SW64"] = true,
  ["SW586"] = true,
  ["SW686"] = true,
  ["SW17"] = true,
  ["GP100"] = true,
  ["SP101"] = true,
  ["SecuritySix"] = true,
  ["SecuritySixSS"] = true,
  ["Python"] = true,
  ["PythonSS"] = true,
  ["ColtTrooper"] = true,
  ["ColtTrooperNickel"] = true,
  ["ColtLawman"] = true,
  ["ColtLawmanNickel"] = true,
  ["Anaconda"] = true,
  ["KingCobra"] = true,
  ["ColtDet"] = true,
  ["ColtDetNickle"] = true,
  ["Diamondback"] = true,
  ["DiamondbackSS"] = true,
  ["ColtArmy"] = true,
  ["ColtArmyBlue"] = true,
  ["ColtArmyBlue2"] = true,
  ["ColtArmyBiTone"] = true,
  ["ColtArmyCase"] = true,
  ["ColtArmyGold"] = true,
  ["ColtArmyGrey"] = true,
  ["ColtArmyRust"] = true,
  ["ColtArmyPit"] = true,
 }
 VPCADS.RegisterADSAdapter("Guns93 verified pistol models", function(weapon,p,part)
  if p.family ~= "pistol" then return end
  local model = weapon.getWeaponSprite and weapon:getWeaponSprite()
  if model then model = tostring(model):gsub("^Base%.", "") end
  if pistolModels[model] then p.guns93Pistol = true end
 end)
 VPCADS.log("Guns of 93 profiles: 247 firearms, 35 optics")
end
apply()
Events.OnGameBoot.Add(apply)
Events.OnGameStart.Add(function()
 apply()
 if not active() or not VPCADS_setOpticShape then return end
 VPCADS_setOpticShape("10Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("10ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("2Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("2ScopePistol",0.03,0.12,0.012)
 VPCADS_setOpticShape("2ScopePistolSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("2ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("3Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("3ScopePistol",0.03,0.12,0.012)
 VPCADS_setOpticShape("3ScopePistolSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("3ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("4AR180",0.03,0.12,0.012)
 VPCADS_setOpticShape("4Handle",0.03,0.12,0.012)
 VPCADS_setOpticShape("4Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("4ScopePistol",0.03,0.12,0.012)
 VPCADS_setOpticShape("4ScopePistolSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("4ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("6Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("6ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("8Scope",0.03,0.12,0.012)
 VPCADS_setOpticShape("8ScopeSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("ACOGMount",0.03,0.12,0.012)
 VPCADS_setOpticShape("ARTScope",0.03,0.12,0.012)
 VPCADS_setOpticShape("AccuDot",0.03,0.12,0.012)
 VPCADS_setOpticShape("AccuDotSilver",0.03,0.12,0.012)
 VPCADS_setOpticShape("ArmsonM16",0.03,0.12,0.012)
 VPCADS_setOpticShape("ArmsonRail",0.03,0.12,0.012)
 VPCADS_setOpticShape("CMore",0.03,0.12,0.012)
 VPCADS_setOpticShape("M14ARTScope",0.03,0.12,0.012)
 VPCADS_setOpticShape("RedDotPistol",0.03,0.12,0.012)
 VPCADS_setOpticShape("SinglePoint",0.03,0.12,0.012)
end)
