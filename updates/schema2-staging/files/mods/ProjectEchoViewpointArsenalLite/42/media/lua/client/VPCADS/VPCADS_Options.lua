require "VPCADS/VPCADS_Weapons"
require "VPCADS/VPCADS_Compat_XannyArms"

--[[
Client options (Settings > Mods > Viewpoint Arsenal ADS). Everything here is a personal visual/control
preference, plus a local shooter spread selection. Spread selection changes local shooting accuracy.
]]

VPCADS.Settings = {
    recoilRecovery = true, spreadSystem = 1, freeAimADS = false, breathEnabled = true, breathKey = Keyboard.KEY_LSHIFT,
    mode = 4,               -- 1 aim = ADS, 2 hold key, 3 toggle key, 4 click aim (default since 1.7.0: DayZ, click = sights, hold = hip)
    key = Keyboard.KEY_V,
    speedMul = 1.0, adsSens = 0.85, scopeSens = 1.0,
    hideCrosshair = true, adsSharp = true, thirdAds = true, closeClip = true, sway = true, swayAmount = 1.0, cameraRecoil = true, recoilAmount = 1.0,
    eyeBox = true, inertia = true, brightness = 1.0, color = 1, lensSize = 0.84, ironDistance = 1.0, scopeZoom = 1.0, pip = false, pipQuality = 3, hipSpread = true, aimPriority = true,
    presence = true, presenceStart = 8, presenceStrength = 1.0, presenceSmoothing = 1.0, lowReady = false, lowReadyAmount = 0.5, presenceDebug = false, presenceOthers = true,
    developer = false, calibKey = Keyboard.KEY_F9,
    variableZoom = false, wheelZoom = true, zoomInKey = 0, zoomOutKey = 0,
    zeroUpKey = Keyboard.KEY_PRIOR, zeroDownKey = Keyboard.KEY_NEXT, scopeHud = true,
}

VPCADS.ReticleColors = {
    { r = 1.00, g = 0.12, b = 0.10 },   -- red
    { r = 0.25, g = 1.00, b = 0.30 },   -- green
    { r = 1.00, g = 0.70, b = 0.15 },   -- amber
    { r = 0.05, g = 0.05, b = 0.05 },   -- black (non-illuminated)
}

local ID = "ProjectEchoViewpointArsenalLite"
local opts

local function val(id, default)
    local o = opts and opts:getOption(id)
    if not o then return default end
    local v = o:getValue()
    if v == nil then return default end
    return v
end

function VPCADS.applySettings()
    local s = VPCADS.Settings
    if opts then
        s.recoilRecovery = val("recoilRecovery", s.recoilRecovery)
        s.spreadSystem = val("spreadSystem", s.spreadSystem)
        s.freeAimADS = val("freeAimADSOptIn", s.freeAimADS)
        s.breathEnabled = val("breathEnabled", s.breathEnabled)
        s.breathKey = val("breathKey", s.breathKey)
        s.mode = val("adsControl", s.mode)       -- new id in 1.7.0: the DayZ-style default reaches everyone once
        s.key = val("key", s.key)
        s.speedMul = val("speed", s.speedMul)
        s.adsSens = val("adsSens", s.adsSens)
        s.scopeSens = val("scopeSens", s.scopeSens)
        s.hideCrosshair = val("hideCrosshair", s.hideCrosshair)
        s.adsSharp = val("adsSharp", s.adsSharp)
        s.thirdAds = val("thirdAds", s.thirdAds)
        s.closeClip = val("closeClip", s.closeClip)
        s.sway = val("sway", s.sway)
        s.swayAmount = val("swayAmount", s.swayAmount)
        s.cameraRecoil = val("cameraRecoil", s.cameraRecoil)
        s.recoilAmount = val("recoilAmount", s.recoilAmount)
        s.eyeBox = val("eyeBox", s.eyeBox)
        s.inertia = val("inertia", s.inertia)
        s.brightness = val("brightness", s.brightness)
        s.color = val("color", s.color)
        s.lensSize = val("lensSize", s.lensSize)
        s.ironDistance = val("ironDist", s.ironDistance)
        s.scopeZoom = val("scopeZoom", s.scopeZoom)
        s.pip = false          -- PROJECT ECHO Lite: native PiP permanently bypassed
        s.hipSpread = val("hipSpread", s.hipSpread)
        s.pipQuality = 3  -- irrelevant with PiP disabled
        s.aimPriority = val("aimPriority", s.aimPriority)
        s.presence = val("presence", s.presence)
        s.presenceStart = val("presenceStart", s.presenceStart)
        s.presenceStrength = val("presenceStrength", s.presenceStrength)
        s.presenceSmoothing = val("presenceSmoothing", s.presenceSmoothing)
        s.lowReady = val("lowReady", s.lowReady)
        s.lowReadyAmount = val("lowReadyAmount", s.lowReadyAmount)
        s.presenceDebug = val("presenceDebug", s.presenceDebug)
        s.presenceOthers = val("presenceOthers", s.presenceOthers)
        s.developer = val("developer", s.developer)
        s.calibKey = val("calibKey", s.calibKey)
        s.variableZoom = val("variableZoom", s.variableZoom)
        s.wheelZoom = val("wheelZoom", s.wheelZoom)
        s.zoomInKey = val("zoomInKey", s.zoomInKey)
        s.zoomOutKey = val("zoomOutKey", s.zoomOutKey)
        s.zeroUpKey = val("zeroUpKey", s.zeroUpKey)
        s.zeroDownKey = val("zeroDownKey", s.zeroDownKey)
        s.scopeHud = val("scopeHud", s.scopeHud)
    end
    s.sway = false; s.cameraRecoil = false; s.recoilAmount = 0; s.hipSpread = false
    s.inertia = false; s.presence = false; s.presenceOthers = false; s.thirdAds = true
    VPCADS.developer = s.developer
    if VPCADS_setSettings then
        VPCADS_setSettings({
            freeAimADS = s.freeAimADS, breathEnabled = s.breathEnabled, recoilRecovery = s.recoilRecovery, customSpread = s.spreadSystem == 1, trueBallisticsSpread = s.spreadSystem == 3,
            enabled = true, hideCrosshair = s.hideCrosshair, adsSharp = s.adsSharp, thirdAds = s.thirdAds, closeClip = s.closeClip, sway = s.sway, cameraRecoil = s.cameraRecoil,
            eyeBox = s.eyeBox, inertia = s.inertia, speedMul = s.speedMul, adsSens = s.adsSens,
            scopeSens = s.scopeSens, swayAmount = s.swayAmount, recoilAmount = s.recoilAmount, lensSize = s.lensSize, ironDistance = s.ironDistance, scopeZoom = s.scopeZoom,
            pip = s.pip and true or false, hipSpread = s.hipSpread and true or false,
            pipQuality = 3 - (tonumber(s.pipQuality) or 2),   -- combo 1 High, 2 Mid, 3 Low -> Java 2, 1, 0
            presence = s.presence and true or false,
            presenceStart = (tonumber(s.presenceStart) or 8) / 100,   -- option in cm, Java in metres
            presenceStrength = tonumber(s.presenceStrength) or 1.0,
            presenceSmoothing = tonumber(s.presenceSmoothing) or 1.0,
            lowReady = s.lowReady and true or false,
            lowReadyAmount = tonumber(s.lowReadyAmount) or 0.5,
            presenceDebug = (s.presenceDebug and s.developer) and true or false,
            presenceOthers = s.presenceOthers and true or false,
        })
        VPCADS_setDeveloper(s.developer and true or false)
        if VPCADS_setClickAim then VPCADS_setClickAim(s.mode == 4) end
        if VPCADS._loggedMode ~= s.mode then   -- once per session, and again only if the option changes
            VPCADS._loggedMode = s.mode
            local names = { "aim (right mouse) raises the sights", "hold the ADS key while aiming",
                            "ADS key toggles the sights", "DayZ: click right mouse = sights, hold = hip fire" }
            VPCADS.log("ADS control: " .. tostring(s.mode) .. " = " .. tostring(names[s.mode] or "unknown"))
        end
        if VPCADS.Controller then VPCADS.Controller.aimAllowed = nil end
    end
end

local function build()
    if not (PZAPI and PZAPI.ModOptions) or opts then return end
    opts = PZAPI.ModOptions:create(ID, "PROJECT ECHO Arsenal Lite ADS")
    local s = VPCADS.Settings
    opts:addTitle("Aim down sights")
    local m = opts:addComboBox("adsControl", "ADS control", "How sights are raised with a firearm. DayZ style: click the aim button (right mouse) to bring the sights up and keep them there, click again to lower them; hold it for ordinary hip aiming. Leave the game's own 'Toggle aim' option off with it.")
    m:addItem("Aim (right mouse) raises the sights", s.mode == 1)
    m:addItem("Hold the ADS key while aiming", s.mode == 2)
    m:addItem("Hip fire; ADS key toggles sights (remembered)", s.mode == 3)
    m:addItem("DayZ: click right mouse = sights, hold = hip fire", s.mode == 4)
    opts:addKeyBind("key", "ADS key", s.key, "Used by the hold and toggle modes.")
    opts:addTickBox("aimPriority", "Aiming takes priority over menus", s.aimPriority, "While you hold a firearm, the ADS key does not open the vehicle / animal radial menu that shares it (V), and Viewpoint Interface's interaction prompt and action menu step aside while you aim. Lower the gun or holster it to use them.")
    opts:addSlider("speed", "ADS transition speed", 0.5, 2.0, 0.05, s.speedMul, "Multiplies every weapon's raise time (higher = faster).")
    opts:addTickBox("hideCrosshair", "Hide Viewpoint's crosshair while aiming down sights", s.hideCrosshair)
    opts:addTickBox("closeClip", "Stop the gun clipping open near the camera while aiming", s.closeClip, "Moves the camera's near clip plane from 5 cm to about 1 cm while sights are up, so the receiver and stock right under your eye are drawn instead of being cut open.")
    opts:addTickBox("adsSharp", "No depth-of-field blur while aiming down sights", s.adsSharp, "Viewpoint shader packs with depth of field focus on the screen centre, which is your sights when ADS, so the world blurs. This keeps the view sharp while sights are up.")
    opts:addSlider("ironDist", "Iron sight / red dot distance (long guns)", 0.8, 1.6, 0.05, s.ironDistance, "How far in front of your eye the gun sits when aiming down sights. Higher = smaller front sight, more of the target visible and less of your hands near the camera, but past about 1.3 the arms stretch to reach. Pistols are not affected. Does not change where you hit.")
    opts:addTitle("Weapon handling")
    opts:addTickBox("freeAimADSOptIn", "Free Aim during ADS", s.freeAimADS, "Off by default; enable here to opt in. Requires Viewpoint Free Aim and PIP scopes enabled. Automatically uses centred ADS when PIP scopes are off; hip-fire Free Aim remains available. The weapon and sights move inside its aim zone while the camera turns at the edge. Arsenal retains control of the grip, optics and final sight ray. Off: centred ADS.")
    opts:addTickBox("breathEnabled", "Hold breath while ADS", s.breathEnabled, "Steadies ADS camera sway and adds a subtle zoom. Six-second budget, eight-second refill and a release requirement after exhaustion. Recoil and spread are unaffected.")
    opts:addKeyBind("breathKey", "Hold breath key", s.breathKey, "Hold while the sights are fully raised. Default: Left Shift.")
    local spread = opts:addComboBox("spreadSystem", "Spread and crosshair system", "Arsenal: distance-based hip spread, movement and sustained-fire bloom, with a matching aim ring. Weapon damage worsens hip accuracy and adds ADS dispersion; pristine guns retain precise ADS. True Ballistics: its own spread, bloom and crosshair ring, including its ADS dispersion; requires True Ballistics enabled. Without it, falls back to native Viewpoint behaviour. Viewpoint: previous native spread behaviour with Arsenal ADS precision. Weapon alignment, optics and camera recoil are unchanged.")
    spread:addItem("Arsenal", s.spreadSystem == 1)
    spread:addItem("Viewpoint", s.spreadSystem == 2)
    spread:addItem("True Ballistics", s.spreadSystem == 3)
    opts:addTickBox("recoilRecovery", "Automatic recoil recovery", s.recoilRecovery, "On: ADS camera recoil returns smoothly after firing. Off: camera recoil stays where it kicks; compensate manually with the mouse. Applies to Arsenal camera recoil in first and third person.")
    opts:addDescription("Arsenal camera recoil applies in hip fire and ADS. Hip sway and accuracy remain native; ADS uses Arsenal sway and precision.")
    opts:addTitle("Optics")
    opts:addTickBox("eyeBox", "Scope eye box (lens shadow when misaligned)", s.eyeBox)
    opts:addSlider("lensSize", "Scope lens size on screen", 0.5, 1.1, 0.02, s.lensSize)
    opts:addSlider("scopeZoom", "Scope zoom", 1.0, 2.5, 0.05, s.scopeZoom, "Multiplies the zoom of 2x/4x/8x scopes. 1.0 = the scope's own number against Viewpoint's wide view; 1.5 = a 4x scope zooms 6x.")
    opts:addSlider("brightness", "Reticle brightness", 0.2, 1.5, 0.05, s.brightness)
    local c = opts:addComboBox("color", "Illuminated reticle colour")
    c:addItem("Red", s.color == 1); c:addItem("Green", s.color == 2); c:addItem("Amber", s.color == 3); c:addItem("Black", s.color == 4)
    opts:addDescription("PROJECT ECHO Arsenal Lite: native picture-in-picture is disabled in Java. Classic full-screen scope is active for higher FPS.")
    opts:addDescription("Without picture-in-picture, magnified scopes magnify the whole first-person view behind a lens mask.")
    opts:addTitle("Scope zoom")
    opts:addTickBox("variableZoom", "Variable zoom on high-power scopes", s.variableZoom, "Scopes of 4x and up zoom in steps: an 8x goes 2x / 4x / 8x, a 6x 1.5x / 3x / 6x, a 4x 2x / 4x. Optics registered with their own zoom levels always use them.")
    opts:addTickBox("wheelZoom", "Mouse wheel changes scope zoom", s.wheelZoom, "While looking through a variable scope: wheel up zooms in, wheel down zooms out.")
    opts:addKeyBind("zoomInKey", "Scope zoom in (key)", s.zoomInKey, "Optional key, as well as the wheel.")
    opts:addKeyBind("zoomOutKey", "Scope zoom out (key)", s.zoomOutKey, "Optional key, as well as the wheel.")
    opts:addTickBox("scopeHud", "Show zoom and zero when changed", s.scopeHud, "A small readout in the lower right corner for a moment after you change the zoom or the zero.")
    opts:addTitle("Developer")
    opts:addTickBox("developer", "Developer / calibration mode", s.developer, "Enables the calibration window, extra logging and the validator.")
    opts:addKeyBind("calibKey", "Open calibrator", s.calibKey)
    opts.apply = function() VPCADS.applySettings() end
end

build()
Events.OnGameBoot.Add(build)
Events.OnGameStart.Add(function()
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.load then PZAPI.ModOptions:load() end
    VPCADS.applySettings()
end)
