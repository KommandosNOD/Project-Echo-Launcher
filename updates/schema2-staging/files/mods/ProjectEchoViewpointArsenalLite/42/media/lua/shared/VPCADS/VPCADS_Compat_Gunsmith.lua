-- Arsenal compatibility adapted from Gunsmith/JGUAR supplied ADS adapter.
require "VPCADS/VPCADS_Weapons"
if not pcall(require, "Gunsmith/Core") or not Gunsmith then return end
local G = Gunsmith

-- family = how the gun handles in ADS (that mod's own families). bead = bead sight only; noIrons = needs an optic
local FAMILIES = {
    pistol = { "GS45.M1911A1", "GSB9.Beretta92FS", "GSGL.Glock17", "GSGL.Glock17L", "GSGL.Glock19", "GSGL.Glock20", "GSGL.Glock21",
               "GSGL.Glock22", "GSGL.Glock23", "GSHP.HiPointC", "GSJN.JenningsJ22", "GSLR.LorcinL380", "GSRV.RavenMP25",
               "GSTT.TokarevTT33", "GSPY.ColtPython", "GS29.SWModel29", "GS36.SWModel36", "GSDE.DesertEagle" },
    smg = { "GSMP.MP5SD" },
    carbine = { "GSMC.MarlinCamp45", "GSM14.Mini14Ranch", "GS92.Rossi92", "GS94.Winchester94", "GSSKS.SKSType56", "GSSKS.SKSType56DM" },
    assault = { "ARGS.AR15A2", "GSAK.AKM", "GSAK.AK101", "GSAK.MAK90" },
    battlerifle = { "GSFAL.FAL5063", "GSHK.HK91", "GSGAR.M1Garand", "GSSR.SR25" },
    sniper = { "GS700.R700BDL", "GS700.R700PSS", "GS700.R700VS", "GSMN.MosinM9130", "GSK98.MauserK98k", "GSCAR.CarcanoM9138" },
    shotgun = { "GSBEN.BenelliM1", "GS870.R870", "GS870.R870Sawn", "GS311.Stevens311", "GS311.Stevens311Sawn" },
}
local EXTRA = {
    ["GS870.R870"] = { bead = true }, ["GS870.R870Sawn"] = { bead = true },
    ["GS311.Stevens311"] = { bead = true }, ["GS311.Stevens311Sawn"] = { bead = true },
    -- heavy-barrel and flat-top rifles come without iron sights
    ["GS700.R700PSS"] = { noIrons = true }, ["GS700.R700VS"] = { noIrons = true }, ["GSSR.SR25"] = { noIrons = true },
}

-- optics: kind "scope" (magnified, picture in the lens) or "reflex" (red dot); zoomLevels = a variable scope's steps
local OPTICS = {
    ["Gunsmith.Acc_ScopeACOG"]     = { kind = "scope", mag = 4, reticle = "acog_ta31f" },
    ["Gunsmith.Acc_ScopeLeupold"]  = { kind = "scope", mag = 5, zoomLevels = { 1.5, 3, 5 }, reticle = "duplex_real", color = { r = 0.04, g = 0.04, b = 0.04 } },
    ["Gunsmith.Acc_ScopeM3"]       = { kind = "scope", mag = 10, reticle = "mildot_real", zeroLevels = { 100, 200, 300 }, color = { r = 0.04, g = 0.04, b = 0.04 } },
    ["Gunsmith.Acc_DotAimpoint"]   = { kind = "reflex", reticle = "dot" },
    ["Gunsmith.Acc_DotTasco"]      = { kind = "reflex", reticle = "dot" },
    ["ARGS.Part_Scope4x20"]        = { kind = "scope", mag = 4, reticle = "colt_4x20", color = { r = 0.04, g = 0.04, b = 0.04 } },
    ["ARGS.Part_ScopeBushnell"]    = { kind = "scope", mag = 9, zoomLevels = { 3, 6, 9 }, reticle = "bushnell_3030", color = { r = 0.04, g = 0.04, b = 0.04 } },
    ["ARGS.Part_ScopePVS4"]        = { kind = "scope", mag = 3.6, reticle = "pvs4_m16", color = { r = 0.25, g = 1.0, b = 0.35 } },
    ["GSAK.Part_Optic1P29"]        = { kind = "scope", mag = 4, reticle = "1p29_pointer", color = { r = 0.25, g = 1.0, b = 0.35 } },
    ["GSAK.Part_OpticPKA"]         = { kind = "reflex", reticle = "dot" },
    ["GSAK.Part_OpticPO35"]        = { kind = "scope", mag = 3.5, reticle = "po35_bdc", color = { r = 1.0, g = 0.15, b = 0.1 } },
    ["GSAK.Part_OpticPSO1"]        = { kind = "scope", mag = 4, reticle = "pso1_real" },
    ["GSSKS.Part_OpticKengs4x28"]  = { kind = "scope", mag = 4, reticle = "kengs_crosshair", color = { r = 0.04, g = 0.04, b = 0.04 } },
    ["GSMN.Part_OpticMosinPU"]     = { kind = "scope", mag = 3.5, reticle = "mosin_pu", color = { r = 0.04, g = 0.04, b = 0.04 } },
}

-- an optic not listed above (a later pack's): read what it is from its name ("3-9x40", "4x", "Red Dot")
local function guessOptic(fullType)
    local name = fullType
    pcall(function() name = getScriptManager():FindItem(fullType):getDisplayName() end)
    local lo, hi = string.match(name, "(%d+%.?%d*)%-(%d+%.?%d*)x")
    if hi then return { kind = "scope", mag = tonumber(hi), zoomLevels = { tonumber(lo), tonumber(hi) }, reticle = "duplex_real" } end
    local mag = string.match(name, "(%d+%.?%d*)x")
    if mag then return { kind = "scope", mag = tonumber(mag), reticle = "duplex_real" } end
    return { kind = "reflex", reticle = "dot" }
end

local applied = false
local function apply()
    if applied or not VPCADS or not VPCADS.RegisterWeaponProfile or not VPCADS.RegisterOpticProfile then return end
    applied = true
    local guns, optics = 0, 0
    local known = {}
    for family, ids in pairs(FAMILIES) do
        for _, id in ipairs(ids) do
            local def = { family = family }
            for k, v in pairs(EXTRA[id] or {}) do def[k] = v end
            VPCADS.RegisterWeaponProfile(id, def)
            known[id] = true; guns = guns + 1
        end
    end
    -- a gun a later pack adds: a handgun is a pistol, anything else a carbine, until it gets its own line above
    for id, def in pairs(G.Guns or {}) do
        if not known[id] then
            local pistol = false
            pcall(function() pistol = getScriptManager():FindItem(id):getSwingAnim() == "Handgun" end)
            VPCADS.RegisterWeaponProfile(id, { family = pistol and "pistol" or "carbine" })
            guns = guns + 1
        end
    end
    for id, def in pairs(OPTICS) do VPCADS.RegisterOpticProfile(id, def); optics = optics + 1 end
    for id, def in pairs(G.Parts or {}) do
        if not OPTICS[id] and (def.provides and def.provides.optic) then
            VPCADS.RegisterOpticProfile(id, guessOptic(id)); optics = optics + 1
        end
    end
    G.log("Viewpoint ADS: " .. guns .. " guns and " .. optics .. " optics registered")
end


apply()                                   -- that mod loaded before us
Events.OnGameBoot.Add(apply)              -- or after us

local function registerShapes()
 if not VPCADS_setOpticShape then return end
 VPCADS_setOpticShape("ARGS_DotAimpoint", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_DotTasco", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_Scope4x20", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_ScopeACOG", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_ScopeBushnell", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_ScopeLeupold", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("ARGS_ScopePVS4", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSAK_1P29", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSAK_PKA", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSAK_PO35", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSAK_PSO1", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSMN_ScopePU", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GSSKS_ScopeKengs", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GS_ScopeM3", 0.03, 0.12, 0.012)
 VPCADS_setOpticShape("GS_ScopeM3R7", 0.03, 0.12, 0.012)
end
Events.OnGameStart.Add(registerShapes)
