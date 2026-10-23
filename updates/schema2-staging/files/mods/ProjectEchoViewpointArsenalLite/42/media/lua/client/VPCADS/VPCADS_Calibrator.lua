require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "VPCADS/VPCADS_Overlay"

--[[
Developer calibration window (Mod Options > Developer / calibration mode, then the calibrator key).
Aim the weapon, press "Hold ADS", and nudge the values until the cyan cross (Viewpoint's true aim ray)
sits on the front post / dot / reticle. Changes apply live. "Save" writes them to
Zomboid/Lua/VPCADS_UserProfiles.txt (loaded automatically next time); "Copy" puts a ready-to-paste
VPCADS.RegisterWeaponOpticOverride / RegisterWeaponProfile line on the clipboard for shipping in a mod.

Values (weapon units ~ 0.55 m; angles in degrees):
  X/Y/Z      shift of the sight point (Z up, Y forward)     Pitch/Yaw/Roll  sight-line correction
  Relief     eye distance behind the sight                  FOV            ADS zoom for irons/dots
  Height     optic sight-axis height above its mount        Lens           scope lens size
Picture-in-picture (1.5.6, per weapon + optic, saved the same way):
  PiP lens X/Y   move the lens picture (share of the lens radius, + = right / up)
  PiP lens size  lens radius multiplier       PiP zoom   zoom multiplier for this sight
  PiP reticle X/Y  move the reticle inside the lens (share of the lens radius)
  PiP depth      red dots / holos: extra clear distance past the glass (metres)
Every value can be typed into its box (Enter or click away applies). The step button cycles the +/- step size.
]]

local Cal = { stepLevel = 2 }
-- +/- step = field's base step x this; level 2 (x1) is the old "Fine" step, the old default "Coarse" was x10
Cal.STEPS = { { mul = 5, name = "Step x5" }, { mul = 1, name = "Step x1" }, { mul = 0.2, name = "Step x0.2" }, { mul = 0.05, name = "Step x0.05" } }
VPCADS.Calibrator = Cal

-- base = step at "x1"; def = value when the profile has none
local FIELDS = {
    { key = "adjX", label = "Sight X", base = 0.0002 },
    { key = "adjY", label = "Sight Y", base = 0.0005 },
    { key = "adjZ", label = "Sight Z", base = 0.0002 },
    { key = "adjPitch", label = "Pitch", base = 0.025 },
    { key = "adjYaw", label = "Yaw", base = 0.025 },
    { key = "adjRoll", label = "Roll", base = 0.1 },
    { key = "relief", label = "Relief", base = 0.001 },
    { key = "fovMul", label = "ADS FOV", base = 0.005 },
    { key = "opticHeight", label = "Optic height", base = 0.0002 },
    { key = "lensScale", label = "Lens size", base = 0.01, def = 1 },
    { key = "adsTime", label = "ADS time", base = 0.005 },
    { section = "Picture-in-picture (scopes / red dots)" },
    { key = "pipX", label = "PiP lens X", base = 0.005 },
    { key = "pipY", label = "PiP lens Y", base = 0.005 },
    { key = "pipZ", label = "PiP lens Z", base = 0.002 },
    { key = "pipScale", label = "PiP lens size", base = 0.005, def = 1 },
    { key = "pipZoom", label = "PiP zoom", base = 0.01, def = 1 },
    { key = "pipRetX", label = "PiP reticle X", base = 0.005 },
    { key = "pipRetY", label = "PiP reticle Y", base = 0.005 },
    { key = "pipDepth", label = "PiP depth (dots)", base = 0.002 },
}

-- ------------------------------------------------------------------ persistence
local FILE = "VPCADS_UserProfiles.txt"

function VPCADS.loadUserProfiles()
    VPCADS.User = {}
    local r = getFileReader(FILE, false)
    if not r then return end
    while true do
        local line = r:readLine()
        if not line then break end
        local key, rest = string.match(line, "^([^=]+)=>(.*)$")
        if key then
            local t = {}
            for k, v in string.gmatch(rest, "([%w_]+)=([%-%d%.eE]+)") do t[k] = tonumber(v) end
            VPCADS.User[key] = t
        end
    end
    r:close()
end

function VPCADS.saveUserProfiles()
    local w = getFileWriter(FILE, true, false)
    if not w then return false end
    w:write("# Viewpoint Arsenal ADS - personal calibration. Format: weapon|optic=>key=value;...\r\n")
    for key, t in pairs(VPCADS.User) do
        local s = key .. "=>"
        for k, v in pairs(t) do s = s .. k .. "=" .. string.format("%.5f", v) .. ";" end
        w:write(s .. "\r\n")
    end
    w:close()
    return true
end

-- ------------------------------------------------------------------ helpers
local function current()
    local pl = getSpecificPlayer(0)
    local w = VPCADS.Controller.weapon(pl)
    if not w then return nil end
    return w, VPCADS.userKey(w)
end

local function value(key, def)
    local p = VPCADS.Controller.profile
    local v = p and p[key]
    if v == nil then return def or 0 end
    return v
end

local function setValue(key, v)
    local w, uk = current()
    if not w then return end
    VPCADS.User[uk] = VPCADS.User[uk] or {}
    VPCADS.User[uk][key] = v
    VPCADS.Controller.refresh(true)
end

function Cal.snippet()
    local w, uk = current()
    if not w then return "-- no firearm equipped" end
    local u = VPCADS.User[uk] or {}
    local fields = {}
    for k, v in pairs(u) do table.insert(fields, k .. " = " .. string.format("%.4f", v)) end
    table.sort(fields)
    local weaponId, opticId = string.match(uk, "^([^|]*)|(.*)$")
    -- irons use optic "" so the values stay with the iron sights (a weapon profile would carry them onto its optics)
    return string.format('VPCADS.RegisterWeaponOpticOverride("%s", "%s", { %s })', weaponId, opticId or "", table.concat(fields, ", "))
end

-- ------------------------------------------------------------------ window
VPCADSCalibWindow = ISCollapsableWindow:derive("VPCADSCalibWindow")

function VPCADSCalibWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local y = self:titleBarHeight() + 6
    local fh = getTextManager():getFontHeight(UIFont.Small)
    local bh = fh + 6
    self.rows = {}
    self.sections = {}
    for _, f in ipairs(FIELDS) do
        if f.section then
            table.insert(self.sections, { text = f.section, y = y + 4 })
            y = y + fh + 8
        else
            -- typed value: Enter (or clicking elsewhere) applies it
            local e = ISTextEntryBox:new(string.format("%.5f", value(f.key, f.def)), 112, y, 92, bh)
            e.font = UIFont.Small
            e:initialise(); e:instantiate()
            e.pvField = f; e.pvWin = self
            e.onCommandEntered = function(box) box.pvWin:applyTyped(box) end
            e.onLostFocus = function(box) box.pvWin:applyTyped(box) end
            self:addChild(e)
            local minus = ISButton:new(210, y, 28, bh, "-", self, VPCADSCalibWindow.onStep)
            minus.internal = { f = f, sign = -1 }
            minus:initialise(); self:addChild(minus)
            local plus = ISButton:new(242, y, 28, bh, "+", self, VPCADSCalibWindow.onStep)
            plus.internal = { f = f, sign = 1 }
            plus:initialise(); self:addChild(plus)
            table.insert(self.rows, { f = f, y = y, entry = e })
            y = y + bh + 3
        end
    end
    local function btn(x, label, fn)
        local b = ISButton:new(x, y, 82, bh, label, self, fn)
        b:initialise(); self:addChild(b); return b
    end
    y = y + 4
    self.btnHold = btn(8, "Hold ADS", VPCADSCalibWindow.onHold)
    self.btnFine = btn(94, Cal.STEPS[Cal.stepLevel].name, VPCADSCalibWindow.onFine)
    btn(180, "Reset", VPCADSCalibWindow.onReset)
    btn(266, "Copy", VPCADSCalibWindow.onCopy)
    y = y + bh + 4
    btn(8, "Save", VPCADSCalibWindow.onSave)
    btn(94, "Probe", VPCADSCalibWindow.onProbe)
    btn(180, "Validate", VPCADSCalibWindow.onValidate)
    btn(266, "Close", VPCADSCalibWindow.close)
    self.infoY = y + bh + 6
    self:setHeight(self.infoY + 150)
end

--- A value typed into a row's box. Anything that is not a number is put back to the current value.
function VPCADSCalibWindow:applyTyped(box)
    local f = box.pvField
    if not f then return end
    local v = tonumber(box:getText())
    if v == nil then
        self.message = "Not a number for " .. f.label .. ": '" .. tostring(box:getText()) .. "'"
        box:setText(string.format("%.5f", value(f.key, f.def)))
        return
    end
    if math.abs(v - value(f.key, f.def)) > 1e-9 then
        setValue(f.key, v)
        self.message = f.label .. " = " .. string.format("%.5f", v)
    end
end

function VPCADSCalibWindow:onStep(button)
    local f, sign = button.internal.f, button.internal.sign
    local step = f.base * Cal.STEPS[Cal.stepLevel].mul
    setValue(f.key, value(f.key, f.def) + sign * step)
end

function VPCADSCalibWindow:onHold()
    VPCADS.Controller.forceADS = not VPCADS.Controller.forceADS
    self.btnHold:setTitle(VPCADS.Controller.forceADS and "Release" or "Hold ADS")
end

function VPCADSCalibWindow:onFine()
    Cal.stepLevel = Cal.stepLevel % #Cal.STEPS + 1
    self.btnFine:setTitle(Cal.STEPS[Cal.stepLevel].name)
end

function VPCADSCalibWindow:onReset()
    local w, uk = current()
    if uk then VPCADS.User[uk] = nil; VPCADS.Controller.refresh(true) end
end

function VPCADSCalibWindow:onCopy()
    local s = Cal.snippet()
    Clipboard.setClipboard(s)
    self.message = "Copied: " .. s
end

function VPCADSCalibWindow:onSave()
    self.message = VPCADS.saveUserProfiles() and ("Saved to Zomboid/Lua/" .. FILE) or "Save failed"
end

function VPCADSCalibWindow:onProbe()
    self.message = VPCADS_probe()
    print("[ProjectViewpoint] probe: " .. self.message)
end

function VPCADSCalibWindow:onValidate()
    if VPCADS.Validate then
        local n = VPCADS.Validate()
        self.message = "Validation: " .. n .. " finding(s), see console / Zomboid/Lua/VPCADS_validation.txt"
    end
end

function VPCADSCalibWindow:close()
    VPCADS.Controller.forceADS = false
    self:setVisible(false)
end

function VPCADSCalibWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed then return end
    local fh = getTextManager():getFontHeight(UIFont.Small)
    for _, sct in ipairs(self.sections) do
        self:drawText(sct.text, 8, sct.y, 0.55, 0.85, 1, 1, UIFont.Small)
    end
    for _, r in ipairs(self.rows) do
        self:drawText(r.f.label, 8, r.y + 3, 1, 1, 1, 1, UIFont.Small)
        -- keep the box showing the live value unless it is being typed in
        if r.entry and not r.entry:isFocused() then
            local txt = string.format("%.5f", value(r.f.key, r.f.def))
            if r.entry:getText() ~= txt then r.entry:setText(txt) end
        end
        self:drawText(string.format("%g", r.f.base * Cal.STEPS[Cal.stepLevel].mul), 276, r.y + 3, 0.5, 0.5, 0.5, 1, UIFont.Small)
    end
    local p = VPCADS.Controller.profile
    local y = self.infoY
    local st = {}
    if VPCADS_getState then VPCADS_getState(st) end
    local lines = {
        p and (p.weaponId .. "  [" .. p.family .. "]") or "no firearm",
        p and ("mode " .. p.mode .. "  optic " .. tostring(p.opticId) .. "  model " .. tostring(p.opticModel)) or "",
        p and ("irons: " .. tostring(p.ironSource) .. "   reticle " .. tostring(p.reticle) .. "   mag " .. tostring(p.mag)) or "",
        string.format("ADS %.2f   misalign %.2f deg   fov %.1f -> %.1f", st.t or 0, st.misalign or 0, st.fovIn or 0, st.fovOut or 0),
        (st.issue and st.issue ~= "") and ("issue: " .. st.issue) or "",
        st.pipMode and string.format("PiP %s   lens (%.0f, %.0f) r %.0f px", st.pip and "drawing" or "not drawn (raise the sight)", st.pipX or 0, st.pipY or 0, st.pipR or 0) or "PiP: not used for this sight",
    }
    for _, l in ipairs(lines) do self:drawText(l, 8, y, 0.85, 0.85, 0.85, 1, UIFont.Small); y = y + fh + 1 end
    if self.message then
        self:drawText(string.sub(self.message, 1, 90), 8, y + 2, 1, 0.9, 0.4, 1, UIFont.Small)
    end
end

function VPCADSCalibWindow:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, 360, 640)
    o.title = "Project Viewpoint - ADS calibrator"
    o.resizable = false
    return o
end

function Cal.toggle()
    if not Cal.window then
        Cal.window = VPCADSCalibWindow:new(60, 120)
        Cal.window:initialise()
        Cal.window:addToUIManager()
        return
    end
    Cal.window:setVisible(not Cal.window:isVisible())
    if not Cal.window:isVisible() then VPCADS.Controller.forceADS = false end
end
