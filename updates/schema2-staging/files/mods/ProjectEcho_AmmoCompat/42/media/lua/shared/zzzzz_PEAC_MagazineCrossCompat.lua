-- PROJECT ECHO: magazine adapter Guns of 93 <-> Guns of Marz (B42.21 MP)
-- Additive registration only. Preserves existing magazine instances, calibers,
-- counts, Gunworks AmmoList, and Guns93 custom reload/weapon handling.
-- NOTE: registration compatibility does NOT bypass vanilla server reload checks.
local C = require("PEAC_Registry")
if C.MAG_COMPAT_REGISTERED_MODULE then return end
C.MAG_COMPAT_REGISTERED_MODULE = true

local families = {
    { name="STANAG 5.56", profile="STANAG", guns93={
        "Base.AR15", "Base.M733", "Base.Dissy", "Base.HBAR", "Base.CAR15",
        "Base.M16A2", "Base.M723", "Base.M727", "Base.DWK1A", "Base.DWK1A1",
        "Base.DWK2", "Base.DR200", "Base.FNC", "Base.M249"
      },
    },
    { name="AK 7.62x39", profile="762x39", guns93={
        "Base.AKM", "Base.AKSport", "Base.T56"
      },
    },
    { name="MP5 9x19", profile="9x19mm MP5", guns93={
        "Base.MP5", "Base.HK94"
      },
    },
    { name="Beretta 9x19", profile="9x19 M92FS M93R", guns93={
        "Base.M9", "Base.Beretta92FS"
      },
    },
    { name="Thompson .45 ACP", profile=".45 Thompson", guns93={
        "Base.TommyM1A1", "Base.TommyM1928"
      },
      -- M1A1 does not accept drum magazines; M1928 does.
      gun93Filter=function(gunType, marzMag)
          if gunType == "Base.TommyM1A1" then
              return marzMag:find("Magazine100_", 1, true) == nil
          end
          return true
      end,
    },
    { name="MAC10 .45 ACP", profile="45 MAC10", guns93={
        "Base.MAC10"
      },
    },
}

-- Do not include Mini14: Guns93 mags use 5.56; Marz MINI_14 mags use .223.
-- Neither family name nor caliber alone authorizes compatibility.

local function installed(t)
    local sm = getScriptManager and getScriptManager()
    if not sm or not sm.FindItem then return false end
    return sm:FindItem(t) ~= nil
end

local function pushUnique(t, what)
    if type(t) ~= "table" or type(what) ~= "string" then return false end
    for _, v in ipairs(t) do
        if v == what then return false end
    end
    t[#t + 1] = what
    return true
end

-- Only the original Guns93 groups are used. This avoids sharing magazines
-- based on superficial caliber equality (AK vs SKS, Beretta vs Glock, etc.).
local function apply()
    local gun93 = rawget(_G, "MagazineGunSet")
    if type(gun93) ~= "table" then return false end
    local ok, Mag = pcall(require, "WeaponSystems/Utils/Magazine")
    if not ok or not Mag or type(Mag.MagazineProfiles) ~= "table"
        or type(Mag.RegisterMagazineProfile) ~= "function" then return false end
    local count93, countMarz, found = 0, 0, 0
    for _, family in ipairs(families) do
        local profile = Mag.MagazineProfiles[family.profile]
        if profile and #profile > 0 then
            local original93 = {}
            local seen = {}
            for _, gunType in ipairs(family.guns93) do
                local list = gun93[gunType]
                if type(list) == "table" then
                    for _, mag in ipairs(list) do
                        -- Capture Base.* originals only; this is re-entrant.
                        if type(mag) == "string" and mag:sub(1, 5) == "Base."
                            and not seen[mag] and installed(mag) then
                            seen[mag] = true
                            original93[#original93 + 1] = mag
                        end
                    end
                end
            end
            local nativeMarz = {}
            for _, mag in ipairs(profile) do
                if type(mag) == "string" and mag:sub(1, 9) == "MarzGuns."
                    and installed(mag) then
                    nativeMarz[#nativeMarz + 1] = mag
                end
            end
            if #nativeMarz > 0 and #original93 > 0 then
                for _, gunType in ipairs(family.guns93) do
                    local list = gun93[gunType]
                    if type(list) == "table" then
                        for _, marzMag in ipairs(nativeMarz) do
                            if (not family.gun93Filter or family.gun93Filter(gunType, marzMag))
                                and pushUnique(list, marzMag) then
                                count93 = count93 + 1
                            end
                        end
                    end
                end
                -- Gunworks central registry drives Marz weapon reload menus/radials.
                -- Registration also updates ProfileMagazineSet for the native hooks.
                local marzSet = Mag.ProfileMagazineSet[family.profile] or {}
                local toRegister = {}
                for _, baseMag in ipairs(original93) do
                    if not marzSet[baseMag] then
                        toRegister[#toRegister + 1] = baseMag
                    end
                end
                if #toRegister > 0 then
                    Mag.RegisterMagazineProfile(family.profile, toRegister)
                    countMarz = countMarz + #toRegister
                end
                found = found + 1
            end
        end
    end
    if found == 0 then return false end
    if not C.MAG_COMPAT_LOGGED then
        C.MAG_COMPAT_LOGGED = true
        C.log("Magazine cross-registration: " .. found .. "/" .. #families
            .. " families; Guns93 added " .. count93
            .. "; Gunworks added " .. countMarz)
    end
    return found == #families
end

-- Register after source mods populate their tables, on client and server.
-- Repeated calls are safe; no duplicate magazine keys are added.
apply()
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
    if Events.OnGameStart then Events.OnGameStart.Add(apply) end
    if Events.OnServerStarted then Events.OnServerStarted.Add(apply) end
end
