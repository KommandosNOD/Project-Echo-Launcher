--
-- Viewpoint UI - firearm readout (HUD foundation).
--
-- In the bottom-right corner of the screen (above the minimap when the minimap
-- is open there), only while an aimable firearm is in the primary hand:
--   rounds loaded / capacity, +1 when a round is chambered, fire mode, JAMMED,
--   "no magazine" when a magazine-fed gun has none in.
-- Every value is read from the item itself (HandWeapon), so modded firearms
-- that use the game's ammo fields (VFE and the like) show correctly.
-- Spare ammunition carried is not shown yet: counting it the way the game's
-- reload does needs the inventory model of Phase 3.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Widgets"

local VPUI = ViewpointUI
VPUI.HUD = VPUI.HUD or {}
if VPUI.HUD.Weapon then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local VPElement = VPUI.UI.VPElement

local WeaponHUD = VPElement:derive("VPWeaponHUD")
VPUI.HUD.Weapon = WeaponHUD

local REFRESH_MS = 150
local MARGIN = 14

-- The minimap's rectangle while it is shown, or nil (ISMiniMapOuter via
-- getPlayerMiniMap, client/ISUI/PlayerData/ISPlayerData.lua).
local function minimapRect()
    local mm = getPlayerMiniMap and getPlayerMiniMap(0)
    if not mm then return nil end
    local ok, r = pcall(function()
        if not mm:isReallyVisible() then return nil end
        return { x = mm:getX(), y = mm:getY(), w = mm:getWidth(), h = mm:getHeight() }
    end)
    if ok then return r end
    return nil
end

local function overlaps(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function WeaponHUD:new()
    local o = VPElement.new(self, 1, 1)
    o.state = nil
    o.signature = ""
    o.nextRead = 0
    return o
end

local function firearm(player)
    local item = player:getPrimaryHandItem()
    if item and instanceof(item, "HandWeapon") and item:isAimedFirearm() then return item end
    return nil
end

function WeaponHUD:read(player, now)
    if now < self.nextRead then return end
    self.nextRead = now + REFRESH_MS
    local gun = firearm(player)
    -- follow the minimap opening, closing or being moved
    local mm = minimapRect()
    local mmSig = mm and (mm.x .. "," .. mm.y .. "," .. mm.w .. "," .. mm.h) or ""
    if mmSig ~= self.minimapSig then
        self.minimapSig = mmSig
        self.minimap = mm
        self.dirty = true
    end
    if not gun then
        if self.state then
            self.state = nil
            self.signature = ""
        end
        return
    end
    local loaded = gun:getCurrentAmmoCount()
    local capacity = gun:getMaxAmmo()
    local chambered = gun:haveChamber() and gun:isRoundChambered()
    local mode = gun:getFireMode()
    local jammed = gun:isJammed()
    local magType = gun:getMagazineType()
    local noMag = magType ~= nil and magType ~= "" and not gun:isContainsClip()
    local name = gun:getDisplayName()
    local sig = tostring(loaded) .. "/" .. tostring(capacity) .. tostring(chambered) .. tostring(mode)
        .. tostring(jammed) .. tostring(noMag) .. tostring(name)
    if sig ~= self.signature then
        self.signature = sig
        self.state = { loaded = loaded, capacity = capacity, chambered = chambered, mode = mode,
                       jammed = jammed, noMag = noMag, name = name }
        self.dirty = true
    end
end

function WeaponHUD:active()
    return self.state ~= nil
end

local function countText(s)
    local text = tostring(s.loaded) .. " / " .. tostring(s.capacity)
    if s.chambered then text = text .. "  +1" end
    return text
end

local function detailText(s)
    if s.jammed then return "JAMMED" end
    if s.noMag then return getText("UI_ProjectEcho_VPUI_HUD_WeaponHUD_RU_001") end
    if s.mode and s.mode ~= "" then return string.upper(tostring(s.mode)) end
    return nil
end

function WeaponHUD:layout()
    local s = self.state
    local big = UIFont.Medium
    local small = Theme.smallFont()
    local w = math.max(Theme.textWidth(big, countText(s)), Theme.textWidth(small, s.name or ""))
    local detail = detailText(s)
    if detail then w = math.max(w, Theme.textWidth(small, detail)) end
    w = w + Theme.px(20)
    local h = Theme.fontHeight(big) + Theme.fontHeight(small) * (detail and 2 or 1) + Theme.px(12)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local m = Theme.px(MARGIN)
    local box = { x = sw - w - m, y = sh - h - m, w = w, h = h }
    local mm = self.minimap
    if mm and overlaps(box, mm) then
        -- stack above the minimap; if there is no room, sit to its left
        if mm.y - h - Theme.px(8) >= 0 then
            box.y = mm.y - h - Theme.px(8)
        else
            box.x = mm.x - w - Theme.px(8)
        end
    end
    self:place(box.x, box.y, w, h)
    self.dirty = false
end

function WeaponHUD:render()
    if not self.state then return end
    if self.dirty then self:layout() end
    local s = self.state
    local big = UIFont.Medium
    local small = Theme.smallFont()
    self:panel(0, 0, self.width, self.height)
    local right = self.width - Theme.px(10)
    local y = Theme.px(5)
    self:textRight(s.name or "", right, y, C.dim, small)
    y = y + Theme.fontHeight(small)
    local empty = (tonumber(s.loaded) or 0) <= 0 and not s.chambered
    self:textRight(countText(s), right, y, empty and C.danger or C.text, big)
    y = y + Theme.fontHeight(big) + Theme.px(1)
    local detail = detailText(s)
    if detail then
        self:textRight(detail, right, y, (s.jammed or s.noMag) and C.danger or C.accent, small)
    end
end
