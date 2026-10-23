--[[
Project Viewpoint - ADS & Optics : core profile system and public compatibility API.

Profile hierarchy (later wins):
    generated (meshscan of the installed scripts/meshes)
  > weapon family defaults            VPCADS.RegisterWeaponFamily
  > individual weapon profile         VPCADS.RegisterWeaponProfile
  > optic profile                     VPCADS.RegisterOpticProfile
  > weapon + optic override           VPCADS.RegisterWeaponOpticOverride
  > adapters (code)                   VPCADS.RegisterADSAdapter
  > the player's own calibration      (saved by the in-game calibrator)

Geometry is in weapon model space: Y = barrel forward, Z = up, same units as script attachments.
]]

VPCADS = VPCADS or {}
VPCADS.VERSION = "1.7.2"

-- Bind the Java side (table VPCADSJ, exposed by ZombieBuddy) to the VPCADS_* functions used everywhere.
-- On a dedicated server or without ZombieBuddy the table is absent and these stay nil (ADS disabled).
function VPCADS.bindJava()
    if VPCADS_available then return true end
    if not VPCADSJ then return false end
    local J = VPCADSJ
    VPCADS_version = function() return J.version() end
    VPCADS_available = function() return J.available() end
    VPCADS_firstPerson = function() return J.firstPerson() end
    VPCADS_canAds = function() return J.canAds() end
    VPCADS_setWant = function(b) J.setWant(b) end
    VPCADS_setBreath = function(b) J.setBreath(b) end
    VPCADS_setDeveloper = function(b) J.setDeveloper(b) end
    VPCADS_setSwayFactor = function(v) J.setSwayFactor(v) end
    VPCADS_setOpticShape = function(m, h, l, w) J.setOpticShape(m, h, l, w) end
    VPCADS_clearProfile = function() J.clearProfile() end
    VPCADS_setProfile = function(t) J.setProfile(t) end
    VPCADS_setSettings = function(t) J.setSettings(t) end
    VPCADS_getState = function(t) return J.getState(t) end
    VPCADS_setPipReticle = function(r, g, m, cr, cg, cb, br, d) J.setPipReticle(r, g, m, cr, cg, cb, br, d) end
    VPCADS_probe = function() return J.probe() end
    VPCADS_presenceTick = J.presenceTick and function() J.presenceTick() end or nil
    VPCADS_getPresence = J.getPresence and function(t) return J.getPresence(t) end or nil
    VPCADS_setScopeMag = J.setScopeMag and function(m, instant) J.setScopeMag(m, instant and true or false) end or nil
    VPCADS_setZero = J.setZero and function(m) J.setZero(m) end or nil
    VPCADS_setClickAim = J.setClickAim and function(b) J.setClickAim(b and true or false) end or nil
    VPCADS_setAimAllowed = J.setAimAllowed and function(b, why) J.setAimAllowed(b and true or false, why and tostring(why) or "") end or nil
    VPCADS_aimLocked = J.aimLocked and function() return J.aimLocked() == true end or nil
    VPCADS_clearAimLock = J.clearAimLock and function() J.clearAimLock() end or nil
    VPCADS_setSuspended = J.setSuspended and function(b) J.setSuspended(b and true or false) end or nil
    return true
end
VPCADS.bindJava()
VPCADS.Families = VPCADS.Families or {}
VPCADS.Weapons = VPCADS.Weapons or {}
VPCADS.Optics = VPCADS.Optics or {}
VPCADS.OpticKinds = VPCADS.OpticKinds or {}
VPCADS.WeaponOptic = VPCADS.WeaponOptic or {}
VPCADS.Adapters = VPCADS.Adapters or {}
VPCADS.User = VPCADS.User or {}
VPCADS.Generated = VPCADS.Generated or { weapons = {}, optics = {} }
VPCADS.Registry = VPCADS.Registry or { duplicates = {}, owners = {} }

local function copyInto(dst, src)
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do
        if type(v) == "table" then
            local t = {}
            for k2, v2 in pairs(v) do t[k2] = v2 end
            dst[k] = t
        else
            dst[k] = v
        end
    end
    return dst
end
VPCADS.copyInto = copyInto

local function note(kind, key)
    local reg = VPCADS.Registry
    local id = kind .. ":" .. tostring(key)
    if reg.owners[id] then table.insert(reg.duplicates, id) end
    reg.owners[id] = true
end

function VPCADS.log(msg) print("[ProjectViewpoint] " .. tostring(msg)) end
function VPCADS.dev(msg) if VPCADS.developer then print("[ProjectViewpoint][dev] " .. tostring(msg)) end end

-- ---------------------------------------------------------------------------------------------- public API
--- Family defaults. Fields: adsTime, relief, fovMul, swayMul, recoilMul, kickMul, ironHeight, zero (m).
function VPCADS.RegisterWeaponFamily(name, def)
    note("family", name)
    VPCADS.Families[name] = copyInto(VPCADS.Families[name] or {}, def)
end

--- Per-weapon profile. Any family field plus:
---   family, rear={x,y,z}, front={x,y,z} (iron sight points), adjX/adjY/adjZ/adjPitch/adjYaw/adjRoll,
---   noIrons=true (weapon has no usable irons; ADS needs an optic)
---   physical weapon presence (all optional; measured from the model when absent):
---   weaponLength (m, rear of stock/grip to muzzle), muzzleOffset (m added past the muzzle, e.g. a bayonet),
---   collisionRadius (m, half the barrel's width for the probe), compressedPoseScale (0.3..1.8, how far it gives way)
---   1.6.0: zeroLevels={25,50,100} (iron sight zeroing ranges, metres; {} = fixed irons)
function VPCADS.RegisterWeaponProfile(fullType, def)
    note("weapon", fullType)
    VPCADS.Weapons[fullType] = copyInto(VPCADS.Weapons[fullType] or {}, def)
end

--- Optic item profile. Fields: kind ("iron"|"reflex"|"scope"), mag, reticle, height, window,
---   relief, fovMul, lensScale, windowScale, color={r,g,b}, zero (m; omit to keep the weapon's iron zero)
---   1.6.0: zoomLevels={2,4,8} (variable scope: magnifications the wheel steps through, top = mag),
---          zeroLevels={25,50,100,200} (ranges the zeroing keys step through, metres; used with True Ballistics)
function VPCADS.RegisterOpticProfile(fullType, def)
    note("optic", fullType)
    VPCADS.Optics[fullType] = copyInto(VPCADS.Optics[fullType] or {}, def)
end

--- Defaults for a whole optic kind ("iron", "reflex", "scope").
function VPCADS.RegisterOpticKind(kind, def)
    VPCADS.OpticKinds[kind] = copyInto(VPCADS.OpticKinds[kind] or {}, def)
end

--- Override for one weapon wearing one optic (e.g. a scope that sits unusually high on one rifle).
--- opticType "" = the weapon's own iron sights (no optic attached), the same key the calibrator saves irons under;
--- unlike RegisterWeaponProfile these values do not carry over to the weapon's optics.
function VPCADS.RegisterWeaponOpticOverride(weaponType, opticType, def)
    note("weaponoptic", weaponType .. "|" .. opticType)
    VPCADS.WeaponOptic[weaponType] = VPCADS.WeaponOptic[weaponType] or {}
    VPCADS.WeaponOptic[weaponType][opticType] = copyInto(VPCADS.WeaponOptic[weaponType][opticType] or {}, def)
end

--- Adapter: function(weaponItem, profile, opticItemOrNil) that may edit the resolved profile in place.
function VPCADS.RegisterADSAdapter(name, fn)
    note("adapter", name)
    VPCADS.Adapters[name] = fn
end

-- ---------------------------------------------------------------------------------------------- resolution
local OPTIC_PART_TYPES = { Scope = true, Sight = true, Optic = true }

--- Returns the optic WeaponPart on the weapon (or nil) and its full type.
function VPCADS.findOptic(weapon)
    if not weapon or not weapon.getAllWeaponParts then return nil end
    local parts = weapon:getAllWeaponParts()
    if not parts then return nil end
    local best
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part then
            local ft = part:getFullType()
            local known = VPCADS.Optics[ft] or VPCADS.Generated.optics[ft]
            if known then return part, ft end
            if OPTIC_PART_TYPES[part:getPartType() or ""] then best = part end
        end
    end
    if best then return best, best:getFullType() end
    return nil
end

local function guessFamily(weapon)
    local swing = weapon.getSwingAnim and weapon:getSwingAnim() or ""
    if swing == "Handgun" then return "pistol" end
    local n = string.lower(weapon:getFullType() .. " " .. (weapon:getDisplayName() or ""))
    if string.find(n, "shotgun") then return "shotgun" end
    if string.find(n, "sniper") then return "sniper" end
    return "carbine"
end

local function norm3(x, y, z)
    local l = math.sqrt(x * x + y * y + z * z)
    if l < 1e-6 then return 0, 1, 0 end
    return x / l, y / l, z / l
end

--- Iron sight point + line from the best data available.
local function ironGeometry(p, gen, man, fam)
    local rear = (man and man.rear) or (gen and gen.rear)
    local front = (man and man.front) or (gen and gen.front)
    local length = (gen and gen.length) or 0.5
    if rear and front and front[2] > rear[2] then
        p.sx, p.sy, p.sz = rear[1], rear[2], rear[3]
        p.dx, p.dy, p.dz = norm3(front[1] - rear[1], front[2] - rear[2], front[3] - rear[3])
        p.ironSource = "rear+front"
    elseif front then
        p.sx, p.sy, p.sz = front[1], front[2] - 0.45 * length, front[3]
        p.dx, p.dy, p.dz = 0, 1, 0
        p.ironSource = "front post"
    else
        local m = (gen and (gen.muzzleEstimated or gen.muzzle)) or { 0, 0.3, 0.02 }
        local mount = gen and (gen.scopeMount or gen.reddotMount)
        local h = (fam.ironHeight or 0.035)
        p.sx, p.sy = m[1], m[2] * 0.25
        p.sz = mount and math.max(mount[3], m[3] + h) or (m[3] + h)
        p.dx, p.dy, p.dz = 0, 1, 0
        p.ironSource = "family default"
    end
end

--- Builds the flat profile table handed to Java (VPCADS_setProfile).
function VPCADS.ResolveProfile(weapon)
    local id = weapon:getFullType()
    local gen = VPCADS.Generated.weapons[id]
    local man = VPCADS.Weapons[id]
    local famName = (man and man.family) or (gen and gen.family) or guessFamily(weapon)
    local fam = VPCADS.Families[famName] or VPCADS.Families.carbine or {}

    local p = { weaponId = id, family = famName, mode = "iron", mag = 1, reticle = "none" }
    for _, k in ipairs({ "adsTime", "relief", "fovMul", "swayMul", "recoilMul", "kickMul", "zero", "climb", "side", "recover", "gunKick", "gunBack", "hipCone", "bead", "weaponLength", "muzzleOffset", "collisionRadius", "compressedPoseScale" }) do p[k] = fam[k] end
    ironGeometry(p, gen, man, fam)
    if man and type(man.zeroLevels) == "table" then p.zeroLevels = copyInto({}, man.zeroLevels) end
    -- physical weapon presence: the meshscan's length and muzzle (weapon units) as the second-best source
    if gen then
        p.genLength = gen.length
        p.genMuzzleY = (gen.muzzle and gen.muzzle[2]) or (gen.muzzleEstimated and gen.muzzleEstimated[2])
    end
    -- without hand-set sight points the Java side measures the irons on the mesh the game actually loaded
    p.ironAuto = not (man and (man.rear or man.front)) and true or false
    if man then
        for _, k in ipairs({ "adsTime", "relief", "fovMul", "swayMul", "recoilMul", "kickMul", "zero", "climb", "side", "recover", "gunKick", "gunBack", "hipCone", "bead", "adjX", "adjY", "adjZ", "adjPitch", "adjYaw", "adjRoll", "weaponLength", "muzzleOffset", "collisionRadius", "compressedPoseScale" }) do
            if man[k] ~= nil then p[k] = man[k] end
        end
    end

    -- weapon weight / power nudges (presentation only)
    local wgt = weapon.getWeight and weapon:getWeight() or 3
    p.swayMul = (p.swayMul or 1) * math.min(1.6, math.max(0.8, 0.85 + wgt * 0.05))
    local dmg = weapon.getMaxDamage and weapon:getMaxDamage() or 1.5
    p.recoilMul = (p.recoilMul or 1) * math.min(1.4, math.max(0.75, 0.8 + dmg * 0.12))   -- visible gun kick only

    -- optic
    local part, opticId = VPCADS.findOptic(weapon)
    p.opticId = opticId
    if part then
        local og = VPCADS.Generated.optics[opticId] or {}
        local kind = (VPCADS.Optics[opticId] and VPCADS.Optics[opticId].kind) or og.kind or "reflex"
        local od = copyInto(copyInto({}, VPCADS.OpticKinds[kind]), VPCADS.Optics[opticId])
        local model = gen and gen.opticModels and gen.opticModels[string.match(opticId, "[^%.]+$")]
        p.opticModel = model
        local shape = og.shapes and model and og.shapes[model]
        p.mode = (kind == "iron") and "reflex" or kind     -- flip-up iron parts are aligned like an optic (no reticle)
        p.mag = od.mag or og.mag or 1
        p.reticle = (od.reticles and model and od.reticles[model]) or od.reticle or "none"
        p.opticHeight = od.height or (shape and shape.height) or 0.03
        p.opticWindow = od.window or (shape and shape.window) or 0.012
        p.opticLength = (shape and shape.length) or 0.12
        if od.relief then p.relief = od.relief end
        if od.fovMul then p.fovMul = od.fovMul end
        if kind ~= "iron" and od.zero then p.zero = od.zero end
        if type(od.zoomLevels) == "table" then p.zoomLevels = copyInto({}, od.zoomLevels) end
        if kind ~= "iron" and type(od.zeroLevels) == "table" then p.zeroLevels = copyInto({}, od.zeroLevels) end
        if od.glass then   -- open sight's glass in its own mesh space: { x0, x1, z0, z1, y, round }
            p.glassX0, p.glassX1, p.glassZ0, p.glassZ1, p.glassY = od.glass[1], od.glass[2], od.glass[3], od.glass[4], od.glass[5]
            p.glassRound = od.glass[6] and true or false
        end
        p.lensScale = od.lensScale or 1
        p.windowScale = od.windowScale or 1
        p.color = od.color
        if kind == "scope" then p.swayMul = p.swayMul * (od.swayMul or 1) end
        local wo = VPCADS.WeaponOptic[id] and VPCADS.WeaponOptic[id][opticId]
        if wo then copyInto(p, wo) end
    elseif man and man.noIrons then
        p.noIrons = true
    end
    if not part then   -- iron sights: calibration registered for this weapon's irons only (optic key "")
        local wi = VPCADS.WeaponOptic[id] and VPCADS.WeaponOptic[id][""]
        if wi then copyInto(p, wi) end
    end

    for name, fn in pairs(VPCADS.Adapters) do
        local ok, err = pcall(fn, weapon, p, part)
        if not ok then VPCADS.log("adapter '" .. tostring(name) .. "' failed: " .. tostring(err)) end
    end

    -- the player's own calibration wins
    local u = VPCADS.User[id .. "|" .. tostring(opticId or "")]
    if u then copyInto(p, u) end
    if opticId and VPCADSJ and not p.nativeOpticProfile then
        local legacy = VPCADSJ.legacyMag(opticId)
        if legacy and legacy > 1 then p.mag = legacy; p.mode = "scope" end
        if VPCADSJ.legacyRedDot(opticId) then p.mag = 1 end
    end
    p.fovMul = 1
    return p
end

--- Key used by the calibrator / user file for the current weapon+optic.
function VPCADS.userKey(weapon)
    local _, opticId = VPCADS.findOptic(weapon)
    return weapon:getFullType() .. "|" .. tostring(opticId or "")
end

return VPCADS
