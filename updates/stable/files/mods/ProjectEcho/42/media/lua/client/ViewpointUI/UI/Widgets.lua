--
-- Viewpoint UI - widget framework.
--
-- VPElement is the base every Viewpoint widget derives from: a vanilla
-- ISUIElement that never takes the mouse (so it can sit near the crosshair
-- without eating clicks meant for the world), stays on top, and only lays
-- itself out again when its content or the screen changes.
--
-- Widgets here: VPPrompt, VPActionMenu, VPProgressBar, VPReticle, VPToast.
-- Shared drawing helpers: panel, keycap, bar.
--

require "ISUI/ISUIElement"
require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.VPElement then return end

local Theme = VPUI.UI.Theme
local C = Theme.color

---------------------------------------------------------------------------
-- VPElement
---------------------------------------------------------------------------

local VPElement = ISUIElement:derive("VPElement")
VPUI.UI.VPElement = VPElement

function VPElement:new(width, height)
    local o = ISUIElement:new(0, 0, width or 1, height or 1)
    setmetatable(o, self)
    self.__index = self
    o.wantMouseEvents = false
    o.wantKeyEvents = false
    o.dirty = true
    o.added = false
    return o
end

-- The game treats nil from right-click handlers as consumed, even when
-- wantMouseEvents is false. All display-only widgets must pass it through.
function VPElement:onRightMouseDown(x, y)
    return false
end

function VPElement:onRightMouseUp(x, y)
    return false
end

-- Adds to the UI manager on first use; afterwards only toggles visibility.
function VPElement:display(on)
    -- the game's Toggle UI hides everything; stay hidden until it comes back
    if on and VPUI.Util.uiHidden() then on = false end
    if on and not self.added then
        self:initialise()
        self:instantiate()
        self:addToUIManager()
        self:setAlwaysOnTop(true)
        self.added = true
    end
    if self.added and self:getIsVisible() ~= on then
        self:setVisible(on)
    end
end

function VPElement:destroy()
    if self.added then
        self:removeFromUIManager()
        self.added = false
    end
end

function VPElement:markDirty()
    self.dirty = true
end

function VPElement:place(x, y, w, h)
    x, y = math.floor(x), math.floor(y)
    w, h = math.floor(w), math.floor(h)
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
end

-- Drawing helpers ---------------------------------------------------------

function VPElement:fill(x, y, w, h, c, alpha)
    self:drawRect(x, y, w, h, (alpha or 1) * c.a, c.r, c.g, c.b)
end

function VPElement:panel(x, y, w, h, hi)
    self:fill(x, y, w, h, hi and C.panelHi or C.panel)
    self:drawRectBorder(x, y, w, h, C.edge.a, C.edge.r, C.edge.g, C.edge.b)
end

function VPElement:text(str, x, y, c, font, alpha)
    self:drawText(str, x, y, c.r, c.g, c.b, (alpha or 1) * c.a, font)
end

function VPElement:textRight(str, x, y, c, font, alpha)
    self:drawTextRight(str, x, y, c.r, c.g, c.b, (alpha or 1) * c.a, font)
end

-- Width of a keycap for the given key text.
function VPElement.keycapWidth(key, font)
    local pad = Theme.px(5)
    return math.max(Theme.textWidth(font, key) + pad * 2, Theme.fontHeight(font) + Theme.px(2))
end

-- Draws a keycap and returns its width.
function VPElement:keycap(key, x, y, font, c)
    local w = VPElement.keycapWidth(key, font)
    local h = Theme.fontHeight(font) + Theme.px(2)
    self:fill(x, y, w, h, C.keycap)
    self:drawRectBorder(x, y, w, h, 0.25, 1, 1, 1)
    local tw = Theme.textWidth(font, key)
    self:text(key, x + math.floor((w - tw) / 2), y + Theme.px(1), c or C.text, font)
    return w
end

function VPElement:bar(x, y, w, h, fraction, c)
    self:fill(x, y, w, h, C.track)
    local f = VPUI.Util.clamp(fraction or 0, 0, 1)
    if f > 0 then self:fill(x, y, math.max(1, math.floor(w * f)), h, c or C.accent) end
end

---------------------------------------------------------------------------
-- VPPrompt: "[E] Open Door" / "[Hold E] More actions (4)" under the crosshair.
---------------------------------------------------------------------------

local VPPrompt = VPElement:derive("VPPrompt")
VPUI.UI.VPPrompt = VPPrompt

function VPPrompt:new()
    local o = VPElement.new(self, 1, 1)
    o.title = nil
    o.lines = {}
    o.hold = 0
    return o
end

-- lines: { { key = "E", text = "Open Door", enabled = true }, ... }
function VPPrompt:setContent(title, lines)
    self.title = title
    self.lines = lines or {}
    self.dirty = true
end

-- The item aimed at (an item lying in the world), drawn as an icon with its
-- condition beside the lines; nil for anything else.
function VPPrompt:setItem(item)
    if item ~= self.item then
        self.item = item
        self.dirty = true
    end
end

function VPPrompt:setHold(fraction)
    self.hold = fraction or 0
end

function VPPrompt:layout()
    local font = Theme.font()
    local small = Theme.smallFont()
    local gap = Theme.px(6)
    local padX, padY = Theme.px(8), Theme.px(5)
    local lineH = Theme.fontHeight(font) + Theme.px(5)
    local w = 0
    if self.title then w = Theme.textWidth(small, self.title) end
    for _, line in ipairs(self.lines) do
        local lw = VPElement.keycapWidth(line.key, small) + gap + Theme.textWidth(font, line.text)
        if lw > w then w = lw end
    end
    local h = #self.lines * lineH
    if self.title then h = h + Theme.fontHeight(small) + Theme.px(2) end
    local iconW = 0
    if self.item then
        iconW = math.max(Theme.px(28), math.min(h, Theme.px(40)))
        w = w + iconW + Theme.px(8)
    end
    self.box = { w = w + padX * 2, h = h + padY * 2 + Theme.px(3), padX = padX, padY = padY, lineH = lineH, gap = gap, iconW = iconW }
    local cx, cy = Theme.screenCenter()
    self:place(cx - self.box.w / 2, cy + Theme.px(34), self.box.w, self.box.h)
    self.dirty = false
end

function VPPrompt:render()
    if self.dirty then self:layout() end
    local b = self.box
    local font = Theme.font()
    local small = Theme.smallFont()
    self:panel(0, 0, b.w, b.h)
    local y = b.padY
    local x0 = b.padX
    if self.item and b.iconW > 0 then
        local ok = pcall(function()
            self:drawItemIcon(self.item, b.padX, b.padY, 1, b.iconW, b.iconW)
            local v = VPUI.Inventory and VPUI.Inventory.Model and VPUI.Inventory.Model.barOf(self.item)
            if v then
                v = math.max(0, math.min(1, v))
                local c = v < 0.25 and C.danger or (v < 0.5 and C.accent or C.good)
                self:fill(b.padX, b.padY + b.iconW + Theme.px(2), b.iconW, Theme.px(3), C.track)
                self:fill(b.padX, b.padY + b.iconW + Theme.px(2), math.max(1, math.floor(b.iconW * v)), Theme.px(3), c)
            end
        end)
        if ok then x0 = b.padX + b.iconW + Theme.px(8) end
    end
    if self.title then
        self:text(self.title, x0, y, C.dim, small)
        y = y + Theme.fontHeight(small) + Theme.px(2)
    end
    for _, line in ipairs(self.lines) do
        local enabled = line.enabled ~= false
        local kw = self:keycap(line.key, x0, y + math.floor((b.lineH - Theme.fontHeight(small)) / 2) - Theme.px(2), small)
        self:text(line.text, x0 + kw + b.gap, y + Theme.px(1), enabled and C.text or C.off, font)
        y = y + b.lineH
    end
    -- Hold progress: a hairline along the bottom edge while Interact is held.
    if self.hold > 0 then
        self:bar(0, b.h - Theme.px(2), b.w, Theme.px(2), self.hold, C.accent)
    end
end

---------------------------------------------------------------------------
-- VPActionMenu: compact list beside the crosshair, wheel to move, Interact to do.
---------------------------------------------------------------------------

local VPActionMenu = VPElement:derive("VPActionMenu")
VPUI.UI.VPActionMenu = VPActionMenu

function VPActionMenu:new()
    local o = VPElement.new(self, 1, 1)
    o.title = nil
    o.items = {}
    o.selected = 1
    o.footer = nil
    return o
end

-- items: { { label = "...", enabled = bool }, ... }
function VPActionMenu:setContent(title, items, footer)
    self.title = title
    self.items = items or {}
    self.footer = footer
    self.selected = 1
    for i, item in ipairs(self.items) do
        if item.enabled ~= false then
            self.selected = i
            break
        end
    end
    self.dirty = true
end

-- Moves the selection, skipping greyed entries, wrapping at the ends.
function VPActionMenu:move(steps)
    local n = #self.items
    if n == 0 or steps == 0 then return end
    local dir = steps > 0 and 1 or -1
    for _ = 1, math.abs(steps) do
        local i = self.selected
        for _ = 1, n do
            i = i + dir
            if i > n then i = 1 elseif i < 1 then i = n end
            if self.items[i].enabled ~= false then break end
        end
        self.selected = i
    end
end

-- Selects entry i (when it can be chosen).
function VPActionMenu:select(i)
    local item = self.items[i]
    if item and item.enabled ~= false then self.selected = i end
end

function VPActionMenu:current()
    return self.items[self.selected], self.selected
end

function VPActionMenu:layout()
    local font = Theme.font()
    local small = Theme.smallFont()
    local padX, padY = Theme.px(10), Theme.px(7)
    local rowH = Theme.fontHeight(font) + Theme.px(7)
    local w = Theme.px(150)
    if self.title then w = math.max(w, Theme.textWidth(small, self.title)) end
    for _, item in ipairs(self.items) do
        w = math.max(w, Theme.textWidth(font, item.label) + Theme.px(14))
    end
    if self.footer then w = math.max(w, Theme.textWidth(small, self.footer)) end
    local h = #self.items * rowH
    local titleH = self.title and (Theme.fontHeight(small) + Theme.px(6)) or 0
    local footH = self.footer and (Theme.fontHeight(small) + Theme.px(8)) or 0
    self.box = { w = w + padX * 2, h = h + padY * 2 + titleH + footH, padX = padX, padY = padY,
                 rowH = rowH, titleH = titleH, footH = footH }
    local cx, cy = Theme.screenCenter()
    local x = cx + Theme.px(36)
    local y = cy - math.floor(self.box.h / 2)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    x = math.min(x, sw - self.box.w - Theme.px(8))
    y = VPUI.Util.clamp(y, Theme.px(8), math.max(Theme.px(8), sh - self.box.h - Theme.px(8)))
    self:place(x, y, self.box.w, self.box.h)
    self.dirty = false
end

function VPActionMenu:render()
    if self.dirty then self:layout() end
    local b = self.box
    local font = Theme.font()
    local small = Theme.smallFont()
    self:panel(0, 0, b.w, b.h)
    local y = b.padY
    if self.title then
        self:text(self.title, b.padX, y, C.dim, small)
        y = y + b.titleH
        self:fill(b.padX, y - Theme.px(4), b.w - b.padX * 2, 1, C.edge, 1.5)
    end
    for i, item in ipairs(self.items) do
        local enabled = item.enabled ~= false
        if i == self.selected and enabled then
            self:fill(Theme.px(3), y, b.w - Theme.px(6), b.rowH - Theme.px(1), C.panelHi)
            self:fill(Theme.px(3), y, Theme.px(2), b.rowH - Theme.px(1), C.accent)
        end
        local c = enabled and (i == self.selected and C.text or C.dim) or C.off
        self:text(item.label, b.padX + Theme.px(6), y + Theme.px(3), c, font)
        y = y + b.rowH
    end
    if self.footer then
        self:text(self.footer, b.padX, b.h - b.padY - Theme.fontHeight(small), C.off, small)
    end
end

---------------------------------------------------------------------------
-- VPProgressBar: slim bar and label for an action the player started.
---------------------------------------------------------------------------

local VPProgressBar = VPElement:derive("VPProgressBar")
VPUI.UI.VPProgressBar = VPProgressBar

function VPProgressBar:new()
    local o = VPElement.new(self, 1, 1)
    o.label = nil
    o.fraction = 0
    return o
end

function VPProgressBar:set(label, fraction)
    if label ~= self.label then
        self.label = label
        self.dirty = true
    end
    self.fraction = fraction or 0
end

function VPProgressBar:layout()
    local small = Theme.smallFont()
    local w = Theme.px(170)
    if self.label then w = math.max(w, Theme.textWidth(small, self.label) + Theme.px(8)) end
    local h = Theme.fontHeight(small) + Theme.px(9)
    local cx, cy = Theme.screenCenter()
    self:place(cx - w / 2, cy + Theme.px(92), w, h)
    self.dirty = false
end

function VPProgressBar:render()
    if self.dirty then self:layout() end
    local small = Theme.smallFont()
    if self.label then
        local tw = Theme.textWidth(small, self.label)
        self:text(self.label, math.floor((self.width - tw) / 2), 0, C.dim, small)
    end
    self:bar(0, self.height - Theme.px(4), self.width, Theme.px(3), self.fraction, C.accent)
end

---------------------------------------------------------------------------
-- VPReticle: four corner marks round the crosshair (Viewpoint draws the
-- crosshair itself; this only adds the interaction state).
--   "interact" amber, "blocked" red, "menu" dim
---------------------------------------------------------------------------

local VPReticle = VPElement:derive("VPReticle")
VPUI.UI.VPReticle = VPReticle

function VPReticle:new()
    local o = VPElement.new(self, 1, 1)
    o.state = "interact"
    return o
end

function VPReticle:setState(state)
    self.state = state
end

function VPReticle:layout()
    local size = Theme.px(24)
    local cx, cy = Theme.screenCenter()
    self:place(cx - size / 2, cy - size / 2, size, size)
    self.dirty = false
end

function VPReticle:render()
    if self.dirty then self:layout() end
    local c = self.state == "blocked" and C.danger or (self.state == "menu" and C.dim or C.accent)
    local s = self.width
    local arm = Theme.px(5)
    local t = math.max(1, Theme.px(1.5))
    local a = 0.85
    -- top-left
    self:fill(0, 0, arm, t, c, a); self:fill(0, 0, t, arm, c, a)
    -- top-right
    self:fill(s - arm, 0, arm, t, c, a); self:fill(s - t, 0, t, arm, c, a)
    -- bottom-left
    self:fill(0, s - t, arm, t, c, a); self:fill(0, s - arm, t, arm, c, a)
    -- bottom-right
    self:fill(s - arm, s - t, arm, t, c, a); self:fill(s - t, s - arm, t, arm, c, a)
end

---------------------------------------------------------------------------
-- VPToast: one short message, top centre, fades out.
---------------------------------------------------------------------------

local VPToast = VPElement:derive("VPToast")
VPUI.UI.VPToast = VPToast

function VPToast:new()
    local o = VPElement.new(self, 1, 1)
    o.message = nil
    o.untilMs = 0
    o.danger = false
    return o
end

function VPToast:show(message, seconds, danger)
    self.message = message
    self.untilMs = VPUI.Util.now() + (seconds or 4) * 1000
    self.danger = danger == true
    self.dirty = true
    self:display(true)
end

function VPToast:layout()
    local font = Theme.font()
    local w = Theme.textWidth(font, self.message or "") + Theme.px(24)
    local h = Theme.fontHeight(font) + Theme.px(12)
    local cx = Theme.screenCenter()
    self:place(cx - w / 2, Theme.px(64), w, h)
    self.dirty = false
end

function VPToast:render()
    local left = self.untilMs - VPUI.Util.now()
    if left <= 0 or not self.message then
        self:display(false)
        return
    end
    if self.dirty then self:layout() end
    local alpha = VPUI.Util.clamp(left / 600, 0, 1)
    self:drawRect(0, 0, self.width, self.height, C.panel.a * alpha, C.panel.r, C.panel.g, C.panel.b)
    local edge = self.danger and C.danger or C.accent
    self:fill(0, 0, Theme.px(2), self.height, edge, alpha)
    self:text(self.message, Theme.px(12), Theme.px(6), C.text, Theme.font(), alpha)
end
