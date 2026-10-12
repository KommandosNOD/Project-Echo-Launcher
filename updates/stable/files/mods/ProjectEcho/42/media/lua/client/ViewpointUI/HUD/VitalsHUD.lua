--
-- Viewpoint UI - vitals: a stamina bar and a health bar, bottom left above the
-- status readout. Each shows only while it says something: stamina while it
-- is below full (it fills back and fades out), health while you are hurt.
-- Values are the game's own: CharacterStat.ENDURANCE (0..1, as
-- forageSystem.lua reads it) and BodyDamage:getHealth() (0..100, as the
-- health panel reads it).
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Widgets"

local VPUI = ViewpointUI
VPUI.HUD = VPUI.HUD or {}
if VPUI.HUD.Vitals then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local VPElement = VPUI.UI.VPElement
local T = VPUI.Text

local VitalsHUD = VPElement:derive("VPVitalsHUD")
VPUI.HUD.Vitals = VitalsHUD

local FADE_MS = 1500

function VitalsHUD:new()
    local o = VPElement.new(self, 1, 1)
    o.stamina, o.health = 1, 100
    o.staminaSeenAt, o.healthSeenAt = -math.huge, -math.huge
    o.rows = 0
    return o
end

function VitalsHUD:read(player, now)
    local okS, s = pcall(function() return player:getStats():get(CharacterStat.ENDURANCE) end)
    if okS and type(s) == "number" then self.stamina = VPUI.Util.clamp(s, 0, 1) end
    local okH, h = pcall(function() return player:getBodyDamage():getHealth() end)
    if okH and type(h) == "number" then self.health = VPUI.Util.clamp(h, 0, 100) end
    if self.stamina < 0.995 then self.staminaSeenAt = now end
    if self.health < 99.5 then self.healthSeenAt = now end
    self.now = now
    local rows = 0
    if now - self.staminaSeenAt < FADE_MS then rows = rows + 1 end
    if now - self.healthSeenAt < FADE_MS then rows = rows + 1 end
    if rows ~= self.rows then self.rows = rows; self.dirty = true end
end

function VitalsHUD:active()
    return self.rows > 0
end

-- above: the top of the status readout (or nil when it is hidden)
function VitalsHUD:setAbove(y)
    if y ~= self.aboveY then self.aboveY = y; self.dirty = true end
end

function VitalsHUD:layout()
    local small = Theme.smallFont()
    local rowH = Theme.fontHeight(small) + Theme.px(6)
    local w = Theme.px(190)
    local h = self.rows * rowH + Theme.px(8)
    local sh = getCore():getScreenHeight()
    local bottom = self.aboveY and (self.aboveY - Theme.px(6)) or (sh - Theme.px(96))
    self:place(Theme.px(18), bottom - h, w, h)
    self.rowH = rowH
    self.dirty = false
end

local function alphaFor(now, seenAt)
    local left = FADE_MS - (now - seenAt)
    return VPUI.Util.clamp(left / 600, 0, 1)
end

function VitalsHUD:render()
    if self.dirty then self:layout() end
    local small = Theme.smallFont()
    local now = VPUI.Util.now()
    self:panel(0, 0, self.width, self.height)
    local y = Theme.px(4)
    local labelW = Theme.px(58)
    local barX = Theme.px(7) + labelW
    local barW = self.width - barX - Theme.px(8)
    local function row(label, frac, color, seenAt)
        local a = alphaFor(now, seenAt)
        self:text(label, Theme.px(7), y, C.dim, small, a)
        local by = y + math.floor((self.rowH - Theme.px(5)) / 2)
        self:fill(barX, by, barW, Theme.px(5), C.track, a)
        if frac > 0 then self:fill(barX, by, math.max(1, math.floor(barW * frac)), Theme.px(5), color, a) end
        y = y + self.rowH
    end
    if now - self.staminaSeenAt < FADE_MS then
        local c = self.stamina < 0.25 and C.danger or (self.stamina < 0.5 and C.accent or C.text)
        row(T.hudStamina, self.stamina, c, self.staminaSeenAt)
    end
    if now - self.healthSeenAt < FADE_MS then
        local f = self.health / 100
        local c = f < 0.4 and C.danger or (f < 0.7 and C.accent or C.good)
        row(T.hudHealth, f, c, self.healthSeenAt)
    end
end

return VitalsHUD
