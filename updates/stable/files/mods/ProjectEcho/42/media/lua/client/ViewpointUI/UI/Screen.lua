--
-- Viewpoint UI - full-screen hub (VPScreen) and its tab registry (Hub).
--
-- One screen hosts every full-screen part of the interface (inventory, crafting,
-- building, health, skills, character, vehicle, admin) as tabs, so they share
-- one look, one set of keys and one way of freeing the mouse:
--
--   * The screen is a capture ("modal") UI element while open. Viewpoint stops
--     mouse-look whenever a modal UI is visible (UIManager.isModalVisible), so the
--     cursor is free with no private Viewpoint state touched, and comes back to
--     mouse-look the moment the screen closes.
--   * Esc, or the key that opened a tab, closes it. The game keeps running
--     underneath (it is a multiplayer game; nothing pauses).
--
-- Tabs are plain tables registered with Hub.register; see the field list below.
--

require "ISUI/ISUIElement"
require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"

local VPUI = ViewpointUI
if VPUI.Hub then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local Log = VPUI.Log

local Hub = { tabs = {}, byId = {} }
VPUI.Hub = Hub

-- Rail icons: the game's own sidebar art where it has some (the same textures
-- ISEquippedItem loads), item icons otherwise. A missing texture falls back to
-- the tab's first two letters.
Hub.icons = {
    inventory = "media/ui/Sidebar/48/Inventory_On_48.png",
    crafting = "media/ui/Sidebar/48/Carpentry_On_48.png",
    build = "media/ui/Sidebar/48/Build_On_48.png",
    health = "media/ui/Sidebar/48/Heart_On_48.png",
    skills = "Item_Book",
    character = "media/ui/Container_DeadPerson_Male.png",
    vehicle = "media/ui/Container_Carseat.png",
    admin = "media/ui/Sidebar/48/Admin_Icon_On_48.png",
}
local iconCache = {}
local function iconFor(def)
    local path = def.icon or Hub.icons[def.id]
    if not path then return nil end
    if iconCache[path] == nil then
        local ok, tex = pcall(getTexture, path)
        iconCache[path] = (ok and tex) or false
    end
    return iconCache[path] or nil
end

local FADE_MS = 120

local function compact()
    return VPUI.Settings and VPUI.Settings.get("compactUI") == true
end

--[[ A tab definition:
    id        string
    label     string (shown as the page title and on the rail when hovered)
    icon      optional texture path for the side rail (Hub.icons has defaults)
    order     number, smaller first
    key       optional function() -> key code that toggles this tab
    visible   optional function(player) -> bool  (e.g. admin only)
    create    function(screen) -> instance

  The instance may implement any of:
    open(args), close(), layout(x, y, w, h), render(ui, mx, my), update(now),
    mouseDown(x, y, mods) -> bool, mouseUp(x, y), mouseMove(x, y),
    rightClick(x, y, sx, sy) -> bool, doubleClick(x, y, mods) -> bool,
    wheel(x, y, del) -> bool, drop(x, y, payload), keyPressed(key) -> bool,
    consumes = { [key] = true }  keys kept from the game while the tab is open,
    children = { ISUIElement... }   shown only while the tab is active
]]

function Hub.register(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or type(def.create) ~= "function" then
        Log.error("Hub.register needs { id, label, create }")
        return
    end
    if Hub.byId[def.id] then
        for i = #Hub.tabs, 1, -1 do
            if Hub.tabs[i].id == def.id then table.remove(Hub.tabs, i) end
        end
    end
    def.order = def.order or 100
    def.label = def.label or def.id
    Hub.byId[def.id] = def
    table.insert(Hub.tabs, def)
    table.sort(Hub.tabs, function(a, b) return a.order < b.order end)
end

---------------------------------------------------------------------------
-- VPScreen
---------------------------------------------------------------------------

local VPScreen = ISUIElement:derive("VPScreen")
VPUI.UI.VPScreen = VPScreen

-- The screen's last child: draws what must sit above the tabs' own UI elements
-- (the 3D character model, text boxes) - the dragged item, popup menus, the
-- amount picker, notices and the fade. It takes no mouse events.
local VPScreenOverlay = ISUIElement:derive("VPScreenOverlay")

function VPScreenOverlay:new(owner)
    local o = ISUIElement:new(0, 0, owner.width, owner.height)
    setmetatable(o, self)
    self.__index = self
    o.owner = owner
    o.wantMouseEvents = false
    o.wantKeyEvents = false
    return o
end

function VPScreenOverlay:onMouseDown() return false end
function VPScreenOverlay:onMouseUp() return false end
function VPScreenOverlay:onRightMouseDown() return false end
function VPScreenOverlay:onRightMouseUp() return false end
function VPScreenOverlay:onMouseWheel() return false end

-- Draws nothing any more: children are drawn before their parent's render,
-- so what must be on top is drawn at the end of VPScreen:render instead.
function VPScreenOverlay:render()
end

function VPScreen:new()
    local core = getCore()
    local o = ISUIElement:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.wantMouseEvents = true
    o.wantKeyEvents = true
    o.instances = {}
    o.activeId = nil
    o.popup = nil
    o.drag = nil
    o.tabBar = Region.Rail.new(function(id) o:switchTo(id) end)
    o.shownAt = 0
    o.switchedAt = 0
    o.closeButton = Region.Button.new({ label = "X", onClick = function() Hub.close() end })
    return o
end

function VPScreen:createChildren()
end

-- Creates the overlay once and keeps it the topmost child.
function VPScreen:ensureOverlay(raise)
    local ov = self.overlay
    if not ov then
        ov = VPScreenOverlay:new(self)
        ov:initialise()
        ov:instantiate()
        if ov.javaObject and ov.javaObject.setConsumeMouseEvents then
            pcall(function() ov.javaObject:setConsumeMouseEvents(false) end)
        end
        self:addChild(ov)
        self.overlay = ov
    elseif raise then
        self:removeChild(ov)
        self:addChild(ov)
    end
    if ov.width ~= self.width then ov:setWidth(self.width) end
    if ov.height ~= self.height then ov:setHeight(self.height) end
end

function VPScreen:player()
    return VPUI.Util.player()
end

function VPScreen:visibleTabs()
    local list = {}
    local player = self:player()
    for _, def in ipairs(Hub.tabs) do
        local show = true
        if def.visible then
            local ok, v = pcall(def.visible, player)
            show = ok and v == true
        end
        if show then table.insert(list, { id = def.id, label = def.label, icon = iconFor(def) }) end
    end
    return list
end

function VPScreen:instance(id)
    local inst = self.instances[id]
    if inst then return inst end
    local def = Hub.byId[id]
    if not def then return nil end
    local ok, result = pcall(def.create, self)
    if not ok or type(result) ~= "table" then
        Log.error("tab " .. id .. " failed to build: " .. tostring(result))
        return nil
    end
    self.instances[id] = result
    return result
end

local function call(inst, name, ...)
    local fn = inst and inst[name]
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, inst, ...)
    if not ok then
        Log.once(Log.ERROR, "tab:" .. name .. ":" .. tostring(inst.id), "tab " .. tostring(inst.id) .. " " .. name .. " failed: " .. tostring(result))
        return nil
    end
    return result
end
VPScreen.call = call

-- A text box keeps keyboard focus when it is hidden: the game only lets go of
-- it on Esc, a click on another text box, or unfocus() (UITextBox2). While it
-- holds focus, GameKeyboard sends no OnKeyPressed at all (Core.currentTextEntryBox
-- is "doing text entry"), so every key the game handles on release - Toggle UI,
-- the inventory key, the map - silently stops working, and typing goes into the
-- hidden box. So every box of ours is let go of whenever it is hidden.
local function releaseFocus(inst)
    if not inst or not inst.children then return end
    for _, child in ipairs(inst.children) do
        if child.isFocused and child.unfocus then
            local ok, focused = pcall(child.isFocused, child)
            if ok and focused then pcall(child.unfocus, child) end
        end
    end
end

local function showChildren(inst, on)
    if not inst or not inst.children then return end
    if not on then releaseFocus(inst) end
    for _, child in ipairs(inst.children) do
        child:setVisible(on)
    end
end

function VPScreen:switchTo(id, args)
    if self.activeId == id and args == nil then return true end
    local old = self.instances[self.activeId]
    if old then
        call(old, "close")
        showChildren(old, false)
    end
    local inst = self:instance(id)
    if not inst then return false end
    inst.id = id
    self.activeId = id
    self.popup = nil
    self.amount = nil
    self.drag = nil
    self.switchedAt = VPUI.Util.now()
    self:layoutAll()
    showChildren(inst, true)
    call(inst, "open", args)
    VPUI.Events.fire("HubTabOpened", id)
    return true
end

function VPScreen:active()
    return self.instances[self.activeId]
end

function VPScreen:layoutAll()
    local core = getCore()
    local w, h = core:getScreenWidth(), core:getScreenHeight()
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    local pad = compact() and Theme.px(14) or Theme.px(24)
    local barH = Theme.fontHeight(UIFont.Medium) + Theme.px(14)
    local railW = compact() and Theme.px(46) or Theme.px(58)
    self.tabBar:setTabs(self:visibleTabs(), self.activeId)
    local top = pad + barH + Theme.px(12)
    self.tabBar:layout(pad, top, railW, h - top - pad)
    self.closeButton:layout(w - pad - barH, pad, barH, barH)
    self.titleY = pad
    self.railW = railW
    local cx = pad + railW + Theme.px(16)
    self.content = { x = cx, y = top, w = w - cx - pad, h = h - top - pad }
    self:ensureOverlay()
    local inst = self:active()
    if inst then call(inst, "layout", self.content.x, self.content.y, self.content.w, self.content.h) end
end

-- A message drawn above the screen (the HUD toasts sit under this modal).
function VPScreen:notify(text, seconds, danger)
    self.notice = { text = tostring(text), untilMs = VPUI.Util.now() + (seconds or 3) * 1000, danger = danger == true }
end

-- Children (text boxes and the like) for tabs.
function VPScreen:addTabChild(inst, element)
    inst.children = inst.children or {}
    element:initialise()
    element:instantiate()
    self:addChild(element)
    table.insert(inst.children, element)
    element:setVisible(self.instances[self.activeId] == inst)
    self:ensureOverlay(true)   -- stays above the new element
    return element
end

---------------------------------------------------------------------------
-- Amount picker: how many of a stack to move (Ctrl+drag).
--   spec = { title, max, initial, onConfirm = fn(n) }
-- Wheel or -/+ change it, digits type it, Enter or the Move button confirm,
-- Esc, Cancel or a click outside drop it.
---------------------------------------------------------------------------

function VPScreen:openAmount(sx, sy, spec)
    local max = math.max(1, math.floor(spec.max or 1))
    local a = { title = spec.title, max = max, n = math.max(1, math.min(max, math.floor(spec.initial or max))),
                onConfirm = spec.onConfirm, typed = nil }
    local small = Theme.smallFont()
    local font = Theme.font()
    local btnH = Theme.fontHeight(small) + Theme.px(8)
    local pad = Theme.px(10)
    a.w = math.max(Theme.px(260), Theme.textWidth(small, tostring(a.title or "")) + pad * 2)
    a.h = pad + Theme.fontHeight(small) + Theme.px(8) + Theme.fontHeight(UIFont.Large) + Theme.px(10) + btnH + Theme.px(6) + btnH + pad
    a.x = math.max(Theme.px(4), math.min(sx, self.width - a.w - Theme.px(4)))
    a.y = math.max(Theme.px(4), math.min(sy, self.height - a.h - Theme.px(4)))
    local function set(n) a.n = math.max(1, math.min(a.max, n)); a.typed = nil end
    a.set = set
    local B = Region.Button
    a.buttons = {
        B.new({ label = "-10", onClick = function() set(a.n - 10) end }),
        B.new({ label = "-1", onClick = function() set(a.n - 1) end }),
        B.new({ label = "+1", onClick = function() set(a.n + 1) end }),
        B.new({ label = "+10", onClick = function() set(a.n + 10) end }),
        B.new({ label = "1", onClick = function() set(1) end }),
        B.new({ label = VPUI.Text.amountHalf, onClick = function() set(math.floor(a.max / 2)) end }),
        B.new({ label = VPUI.Text.amountAll, onClick = function() set(a.max) end }),
    }
    a.ok = B.new({ label = VPUI.Text.amountMove, accent = true, onClick = function() self:confirmAmount() end })
    a.cancel = B.new({ label = VPUI.Text.amountCancel, onClick = function() self.amount = nil end })
    -- layout
    local y1 = a.y + pad + Theme.fontHeight(small) + Theme.px(8)
    a.numY = y1
    local y2 = y1 + Theme.fontHeight(UIFont.Large) + Theme.px(10)
    local bw = math.floor((a.w - pad * 2 - Theme.px(4) * 3) / 4)
    for i = 1, 4 do a.buttons[i]:layout(a.x + pad + (i - 1) * (bw + Theme.px(4)), y2, bw, btnH) end
    local y3 = y2 + btnH + Theme.px(6)
    local bw3 = math.floor((a.w - pad * 2 - Theme.px(4) * 4) / 5)
    a.buttons[5]:layout(a.x + pad, y3, bw3, btnH)
    a.buttons[6]:layout(a.x + pad + (bw3 + Theme.px(4)), y3, bw3, btnH)
    a.buttons[7]:layout(a.x + pad + (bw3 + Theme.px(4)) * 2, y3, bw3, btnH)
    a.cancel:layout(a.x + pad + (bw3 + Theme.px(4)) * 3, y3, bw3, btnH)
    a.ok:layout(a.x + pad + (bw3 + Theme.px(4)) * 4, y3, bw3, btnH)
    self.popup = nil
    self.amount = a
end

function VPScreen:confirmAmount()
    local a = self.amount
    if not a then return end
    self.amount = nil
    if a.onConfirm then
        local ok, err = pcall(a.onConfirm, a.n)
        if not ok then Log.error("moving the amount failed: " .. tostring(err)) end
    end
end

function VPScreen:renderAmount(ui, mx, my)
    local a = self.amount
    if not a then return end
    local small = Theme.smallFont()
    ui:drawRect(a.x, a.y, a.w, a.h, 0.97, C.panel.r, C.panel.g, C.panel.b)
    ui:drawRectBorder(a.x, a.y, a.w, a.h, 0.8, C.accent.r, C.accent.g, C.accent.b)
    local pad = Theme.px(10)
    ui:drawText(tostring(a.title or ""), a.x + pad, a.y + pad, C.dim.r, C.dim.g, C.dim.b, 1, small)
    local text = (a.typed or tostring(a.n)) .. " / " .. tostring(a.max)
    local tw = Theme.textWidth(UIFont.Large, text)
    ui:drawText(text, a.x + math.floor((a.w - tw) / 2), a.numY, C.text.r, C.text.g, C.text.b, 1, UIFont.Large)
    -- fill bar under the number
    local bx, bw = a.x + pad, a.w - pad * 2
    local by = a.numY + Theme.fontHeight(UIFont.Large) + Theme.px(2)
    ui:drawRect(bx, by, bw, Theme.px(3), C.track.a, C.track.r, C.track.g, C.track.b)
    ui:drawRect(bx, by, math.max(1, math.floor(bw * a.n / a.max)), Theme.px(3), 1, C.accent.r, C.accent.g, C.accent.b)
    for _, b in ipairs(a.buttons) do b:draw(ui, mx, my) end
    a.cancel:draw(ui, mx, my)
    a.ok:draw(ui, mx, my)
end

-- Mouse on the picker: true when it took the click.
local function amountMouseDown(self, x, y)
    local a = self.amount
    if not a then return false end
    if not Region.inside(a, x, y) then
        self.amount = nil
        return true
    end
    for _, b in ipairs(a.buttons) do if b:mouseDown(x, y) then return true end end
    if a.ok:mouseDown(x, y) then return true end
    if a.cancel:mouseDown(x, y) then return true end
    return true
end

local DIGITS = {}
for d = 0, 9 do
    local k = Keyboard["KEY_" .. tostring(d)]
    if k then DIGITS[k] = d end
end
for d = 0, 9 do
    local k = Keyboard["KEY_NUMPAD" .. tostring(d)]
    if k then DIGITS[k] = d end
end

local function amountKey(self, key)
    local a = self.amount
    if not a then return false end
    if key == Keyboard.KEY_ESCAPE then
        self.amount = nil
    elseif key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
        if a.typed then a.set(tonumber(a.typed) or a.n) end
        self:confirmAmount()
    elseif key == Keyboard.KEY_BACK then
        local t = a.typed or tostring(a.n)
        t = string.sub(t, 1, #t - 1)
        a.typed = t ~= "" and t or nil
        if a.typed then a.n = math.max(1, math.min(a.max, tonumber(a.typed) or a.n)) end
    elseif DIGITS[key] then
        local t = (a.typed or "") .. tostring(DIGITS[key])
        if #t > 6 then t = string.sub(t, 1, 6) end
        a.typed = t
        a.n = math.max(1, math.min(a.max, tonumber(t) or a.n))
    end
    return true
end

-- Popup action menu (right click): actions = { { label, enabled, run = fn() }, ... }
function VPScreen:openMenu(sx, sy, title, actions)
    if not actions or #actions == 0 then return end
    local font = Theme.font()
    local rowH = Theme.fontHeight(font) + Theme.px(6)
    local w = Theme.px(140)
    if title then w = math.max(w, Theme.textWidth(Theme.smallFont(), title) + Theme.px(20)) end
    for _, a in ipairs(actions) do w = math.max(w, Theme.textWidth(font, a.label) + Theme.px(28)) end
    local titleH = title and (Theme.fontHeight(Theme.smallFont()) + Theme.px(8)) or 0
    local contentH = #actions * rowH
    local maxH = self.height - Theme.px(8)
    local h = math.min(contentH + titleH + Theme.px(8), maxH)
    local x = math.min(sx, self.width - w - Theme.px(4))
    local y = math.min(sy, self.height - h - Theme.px(4))
    if y < Theme.px(4) then y = Theme.px(4) end
    self.popup = { x = x, y = y, w = w, h = h, rowH = rowH, titleH = titleH, title = title, actions = actions,
                   scroll = 0, maxScroll = math.max(0, contentH + titleH + Theme.px(8) - h) }
end

function VPScreen:closeMenu()
    self.popup = nil
end

function VPScreen:popupIndex(x, y)
    local p = self.popup
    if not p or not Region.inside(p, x, y) then return nil end
    local i = math.floor((y - p.y - p.titleH - Theme.px(4) + (p.scroll or 0)) / p.rowH) + 1
    if i >= 1 and i <= #p.actions then
        if p.actions[i].header then return nil end
        return i
    end
    return nil
end

function VPScreen:startDrag(payload)
    if payload then self.drag = payload end
end

-- Rendering -----------------------------------------------------------------

function VPScreen:prerender()
    self:drawRect(0, 0, self.width, self.height, 0.72, 0.02, 0.025, 0.03)
end

function VPScreen:render()
    if not self.content then self:layoutAll() end
    local mx, my = self:getMouseX(), self:getMouseY()
    -- brand mark
    local pad = self.content.x - self.railW - Theme.px(16)
    self:drawText("VIEWPOINT", pad, self.titleY + Theme.px(8), C.accent.r, C.accent.g, C.accent.b, 1, UIFont.Medium)
    local def = Hub.byId[self.activeId]
    if def then
        local tx = math.max(self.content.x, pad + Theme.textWidth(UIFont.Medium, "VIEWPOINT") + Theme.px(24))
        self:drawText(def.label, tx, self.titleY + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, UIFont.Large)
    end
    self.tabBar:draw(self, mx, my)
    self.closeButton:draw(self, mx, my)
    self:drawRect(pad, self.content.y - Theme.px(6), self.content.x + self.content.w - pad, 1, 0.08, 1, 1, 1)
    local inst = self:active()
    if inst then call(inst, "render", self, mx, my) end
    -- On top of everything: the game draws an element's Lua prerender, then
    -- its child elements (the 3D model, text boxes), then its Lua render
    -- (UIElement.render), so the end of the screen's own render is the very
    -- top. The drag ghost, menus, the amount picker and notices go here.
    self:ensureOverlay()
    local ok, err = pcall(self.renderOverlay, self, self)
    if not ok then Log.once(Log.ERROR, "screenOverlay", "screen overlay draw failed: " .. tostring(err)) end
end

-- Drawn by the overlay element (UI coordinates are the screen's).
function VPScreen:renderOverlay(ui)
    local mx, my = self:getMouseX(), self:getMouseY()
    if self.drag then
        local label = self.drag.label or "..."
        local font = Theme.smallFont()
        local w = Theme.textWidth(font, label) + Theme.px(16)
        local h = Theme.fontHeight(font) + Theme.px(8)
        local item = self.drag.item or (self.drag.items and self.drag.items[1])
        local icon = item and Theme.px(32) or 0
        local x0 = mx + Theme.px(12)
        if item then
            -- the item itself follows the cursor, its name beside it
            ui:drawRect(x0, my + Theme.px(8), icon + Theme.px(8), icon + Theme.px(8), 0.85, C.panelHi.r, C.panelHi.g, C.panelHi.b)
            ui:drawRectBorder(x0, my + Theme.px(8), icon + Theme.px(8), icon + Theme.px(8), 0.9, C.accent.r, C.accent.g, C.accent.b)
            pcall(function() ui:drawItemIcon(item, x0 + Theme.px(4), my + Theme.px(12), 0.9, icon, icon) end)
            x0 = x0 + icon + Theme.px(12)
        end
        ui:drawRect(x0, my + Theme.px(8), w, h, 0.85, C.panelHi.r, C.panelHi.g, C.panelHi.b)
        ui:drawRectBorder(x0, my + Theme.px(8), w, h, 0.9, C.accent.r, C.accent.g, C.accent.b)
        ui:drawText(label, x0 + Theme.px(8), my + Theme.px(12), C.text.r, C.text.g, C.text.b, 1, font)
    end
    local p = self.popup
    if p then
        ui:drawRect(p.x, p.y, p.w, p.h, 0.95, C.panel.r, C.panel.g, C.panel.b)
        ui:drawRectBorder(p.x, p.y, p.w, p.h, 0.3, 1, 1, 1)
        local y = p.y + Theme.px(4)
        if p.title then
            ui:drawText(p.title, p.x + Theme.px(10), y, C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
            y = y + p.titleH
        end
        local hover = self:popupIndex(mx, my)
        local font = Theme.font()
        local small = Theme.smallFont()
        local top = y
        ui:setStencilRect(p.x, top, p.w, p.y + p.h - top)
        y = y - (p.scroll or 0)
        for i, a in ipairs(p.actions) do
            if y + p.rowH >= top and y <= p.y + p.h then
                if a.header then
                    -- group heading: small, dim, with a rule
                    ui:drawRect(p.x + Theme.px(8), y + p.rowH - Theme.px(3), p.w - Theme.px(16), 1, 0.08, 1, 1, 1)
                    ui:drawText(a.label, p.x + Theme.px(10), y + p.rowH - Theme.fontHeight(small) - Theme.px(4),
                        C.off.r, C.off.g, C.off.b, 1, small)
                else
                    local enabled = a.enabled ~= false
                    if hover == i and enabled then
                        ui:drawRect(p.x + Theme.px(2), y, p.w - Theme.px(4), p.rowH, 1, C.panelHi.r, C.panelHi.g, C.panelHi.b)
                        ui:drawRect(p.x + Theme.px(2), y, Theme.px(2), p.rowH, 1, C.accent.r, C.accent.g, C.accent.b)
                    end
                    local c = enabled and (a.recent and C.accent or C.text) or C.off
                    ui:drawText(a.label, p.x + Theme.px(12), y + Theme.px(3), c.r, c.g, c.b, 1, font)
                end
            end
            y = y + p.rowH
        end
        ui:clearStencilRect()
        if (p.maxScroll or 0) > 0 then
            local trackH = p.h - Theme.px(8)
            local barH = math.max(Theme.px(16), math.floor(trackH * p.h / (p.h + p.maxScroll)))
            local barY = p.y + Theme.px(4) + math.floor((trackH - barH) * (p.scroll or 0) / p.maxScroll)
            ui:drawRect(p.x + p.w - Theme.px(4), barY, Theme.px(2), barH, 0.4, 1, 1, 1)
        end
    end
    self.tabBar:drawLabel(ui, mx, my)
    -- notice line
    local n = self.notice
    if n then
        if VPUI.Util.now() > n.untilMs then
            self.notice = nil
        else
            local font = Theme.smallFont()
            local tw = Theme.textWidth(font, n.text) + Theme.px(24)
            local th = Theme.fontHeight(font) + Theme.px(12)
            local nx = math.floor((self.width - tw) / 2)
            local ny = self.height - th - Theme.px(48)
            local edge = n.danger and C.danger or C.accent
            ui:drawRect(nx, ny, tw, th, 0.95, C.panel.r, C.panel.g, C.panel.b)
            ui:drawRectBorder(nx, ny, tw, th, 0.8, edge.r, edge.g, edge.b)
            ui:drawText(n.text, nx + Theme.px(12), ny + Theme.px(6), C.text.r, C.text.g, C.text.b, 1, font)
        end
    end
    -- fade in: the whole screen when it opens, the content on a tab switch
    local now = VPUI.Util.now()
    local t = now - (self.shownAt or 0)
    if t < FADE_MS then
        ui:drawRect(0, 0, self.width, self.height, 1 - t / FADE_MS, 0.02, 0.025, 0.03)
    else
        t = now - (self.switchedAt or 0)
        if t < FADE_MS then
            local c = self.content
            ui:drawRect(c.x, c.y, c.w, c.h, 0.85 * (1 - t / FADE_MS), 0.02, 0.025, 0.03)
        end
    end
    self:renderAmount(ui, mx, my)
end

function VPScreen:update()
    local inst = self:active()
    if inst then call(inst, "update", VPUI.Util.now()) end
end

-- Mouse -----------------------------------------------------------------------

local function mods()
    return { shift = isShiftKeyDown(), ctrl = isCtrlKeyDown(), alt = isAltKeyDown and isAltKeyDown() or false }
end

function VPScreen:onMouseDown(x, y)
    if amountMouseDown(self, x, y) then return true end
    if self.popup then
        local i = self:popupIndex(x, y)
        local p = self.popup
        if not i and Region.inside(p, x, y) then return true end   -- a heading or the gap: stay open
        self.popup = nil
        if i then
            local a = p.actions[i]
            if a.enabled ~= false and a.run then
                local ok, err = pcall(a.run)
                if not ok then Log.error("menu action '" .. tostring(a.label) .. "' failed: " .. tostring(err)) end
            end
        end
        return true
    end
    -- a click anywhere but the text box itself (that click goes to the box)
    -- ends typing, so the tab's keys work again
    releaseFocus(self:active())
    if self.closeButton:mouseDown(x, y) then return true end
    if self.tabBar:mouseDown(x, y) then return true end
    call(self:active(), "mouseDown", x, y, mods())
    return true
end

function VPScreen:onMouseUp(x, y)
    local inst = self:active()
    if self.drag then
        local payload = self.drag
        self.drag = nil
        call(inst, "drop", x, y, payload)
    end
    call(inst, "mouseUp", x, y)
    return true
end

-- Which child element is under (x, y) or holds the mouse: for the console when
-- a click goes to a child instead of the screen.
local function childAt(self, x, y)
    local found = {}
    for _, child in pairs(self.children or {}) do
        local ok, desc = pcall(function()
            if not child:getIsVisible() then return nil end
            local cap = child.javaObject and child.javaObject:isCapture()
            local inside = x >= child:getX() and y >= child:getY() and x < child:getX() + child:getWidth() and y < child:getY() + child:getHeight()
            if not inside and not cap then return nil end
            return string.format("%s at %d,%d %dx%d%s", tostring(child.Type), child:getX(), child:getY(), child:getWidth(), child:getHeight(), cap and " (holds the mouse)" or "")
        end)
        if ok and desc then table.insert(found, desc) end
    end
    return #found > 0 and table.concat(found, "; ") or "none"
end

-- On the screen and not on a text box (a text box is meant to have its own
-- clicks: forwarding them would take the typing focus away).
local function onScreen(self, x, y)
    if x == nil or y == nil or x < 0 or y < 0 or x >= self.width or y >= self.height then return false end
    for _, child in pairs(self.children or {}) do
        local ok, inBox = pcall(function()
            local isBox = (ISTextEntryBox ~= nil and VPUI.Legacy and VPUI.Legacy.derives and VPUI.Legacy.derives(child, ISTextEntryBox))
                or tostring(child.Type) == "ISTextEntryBox"
            return isBox and child:getIsVisible()
                and x >= child:getX() and y >= child:getY() and x < child:getX() + child:getWidth() and y < child:getY() + child:getHeight()
        end)
        if ok and inBox then return false end
    end
    return true
end

-- The game hands a release to the screen as "outside" when one of its child
-- elements (the 3D character, a text box, the overlay) took it. The screen
-- covers the whole display, so a release on it is still the screen's: a drag
-- is dropped where the mouse is, instead of being lost.
function VPScreen:onMouseUpOutside(x, y)
    if onScreen(self, x, y) then
        Log.once(Log.WARN, "upOutside", "a click release went to a child element (" .. childAt(self, x, y) .. "); handled by the screen")
        return self:onMouseUp(x, y)
    end
    self.drag = nil
    call(self:active(), "mouseUp", x, y)
end

function VPScreen:onMouseMove(dx, dy)
    local x, y = self:getMouseX(), self:getMouseY()
    local inst = self:active()
    if not self.drag and inst and inst.dragCheck then
        local ok, payload = pcall(inst.dragCheck, inst, x, y)
        if ok and payload then self.drag = payload end
    end
    call(inst, "mouseMove", x, y)
end

-- Right-click diagnostics: the first few presses and releases are written to
-- console.txt, so a right-click that does nothing shows where it stopped.
-- Logging only; nothing here changes what a right-click does.
local rcLogged = 0
local function rcLog(text)
    if rcLogged >= 6 then return end
    rcLogged = rcLogged + 1
    Log.warn("right-click check: " .. text)
end

function VPScreen:onRightMouseUp(x, y)
    self.popup = nil
    call(self:active(), "rightClick", x, y, x, y)
    rcLog(string.format("released at %d,%d on tab %s; menu %s", x, y, tostring(self.activeId),
        self.popup and ("opened with " .. tostring(#self.popup.actions) .. " entries") or "not opened (nothing under the mouse)"))
    return true
end

function VPScreen:onRightMouseUpOutside(x, y)
    rcLog(string.format("released at %d,%d but a child element took it (%s); screen %dx%d", x or -1, y or -1,
        childAt(self, x or -1, y or -1), self.width or -1, self.height or -1))
    if onScreen(self, x, y) then return self:onRightMouseUp(x, y) end
end

function VPScreen:onRightMouseDownOutside(x, y)
end

function VPScreen:onMouseDownOutside(x, y)
    if onScreen(self, x, y) then
        Log.once(Log.WARN, "downOutside", "a click went to a child element (" .. childAt(self, x, y) .. "); handled by the screen")
        return self:onMouseDown(x, y)
    end
end

function VPScreen:onRightMouseDown(x, y)
    rcLog(string.format("pressed at %d,%d", x, y))
    return true
end

function VPScreen:onMouseDoubleClick(x, y)
    call(self:active(), "doubleClick", x, y, mods())
    return true
end

function VPScreen:onMouseWheel(del)
    local x, y = self:getMouseX(), self:getMouseY()
    if self.amount then
        self.amount.set(self.amount.n - del)
        return true
    end
    local p = self.popup
    if p and Region.inside(p, x, y) then
        p.scroll = math.max(0, math.min(p.maxScroll or 0, (p.scroll or 0) + del * p.rowH * 2))
        return true
    end
    call(self:active(), "wheel", x, y, del)
    return true
end

-- Keys ----------------------------------------------------------------------------

-- True while one of the active tab's text boxes has keyboard focus: then keys
-- belong to the text box, not to tab shortcuts.
function VPScreen:typing()
    local inst = self:active()
    for _, child in ipairs(inst and inst.children or {}) do
        if child.isFocused and child:getIsVisible() then
            local ok, focused = pcall(child.isFocused, child)
            if ok and focused then return true, child end
        end
    end
    return false
end

function VPScreen:isKeyConsumed(key)
    if self.amount then return true end
    if self:typing() then return key == Keyboard.KEY_ESCAPE end
    if key == Keyboard.KEY_ESCAPE then return true end
    local inst = self:active()
    if inst and inst.consumes and inst.consumes[key] then return true end
    for _, def in ipairs(Hub.tabs) do
        if def.key then
            local ok, k = pcall(def.key)
            if ok and k and k > 0 and k == key then return true end
        end
    end
    return false
end

function VPScreen:onKeyRelease(key)
    if amountKey(self, key) then return end
    local typing, box = self:typing()
    if typing then
        if key == Keyboard.KEY_ESCAPE then pcall(box.unfocus, box) end
        return
    end
    if key == Keyboard.KEY_ESCAPE then
        if self.popup then
            self.popup = nil
        elseif self.drag then
            self.drag = nil
        else
            Hub.close()
        end
        return
    end
    local inst = self:active()
    if inst and call(inst, "keyPressed", key) == true then return end
    for _, def in ipairs(Hub.tabs) do
        if def.key then
            local ok, k = pcall(def.key)
            if ok and k and k > 0 and k == key then
                if def.id == self.activeId then Hub.close() else Hub.open(def.id) end
                return
            end
        end
    end
end

---------------------------------------------------------------------------
-- Hub API
---------------------------------------------------------------------------

local screen = nil

function Hub.isOpen()
    return screen ~= nil and screen:getIsVisible()
end

function Hub.activeId()
    return Hub.isOpen() and screen.activeId or nil
end

function Hub.screen()
    return screen
end

function Hub.open(id, args)
    if not Hub.byId[id] then
        Log.warn("no hub tab " .. tostring(id))
        return
    end
    local player = VPUI.Util.player()
    if not player then return end
    local def = Hub.byId[id]
    if def.visible then
        local ok, v = pcall(def.visible, player)
        if not (ok and v) then return end
    end
    if not screen then
        screen = VPScreen:new()
        screen:initialise()
        screen:instantiate()
        screen:layoutAll()
    end
    if not screen:getIsVisible() or not screen.added then
        screen:addToUIManager()
        screen.added = true
        screen:setVisible(true)
        screen.shownAt = VPUI.Util.now()
        screen:setCapture(true)
        screen:setAlwaysOnTop(true)
        screen:bringToTop()
        VPUI.Events.fire("HubOpened")
    end
    if not screen:switchTo(id, args or {}) and not screen:active() then
        -- the tab failed to build and nothing else is open: don't leave an empty modal
        Hub.close()
        VPUI.UI.toast(VPUI.Text.tabFailed, 5, true)
    end
end

function Hub.toggle(id, args)
    if Hub.activeId() == id then Hub.close() else Hub.open(id, args) end
end

function Hub.close()
    if not screen then return end
    local inst = screen:active()
    if inst then
        call(inst, "close")
        showChildren(inst, false)
    end
    screen.activeId = nil
    screen.popup = nil
    screen.amount = nil
    screen.drag = nil
    screen:setCapture(false)
    screen:setVisible(false)
    screen:removeFromUIManager()
    screen.added = false
    VPUI.Events.fire("HubClosed")
end

-- Safety net, per tick while the screen is closed: no box of ours may keep
-- keyboard focus (see releaseFocus).
function Hub.releaseFocus()
    if not screen or Hub.isOpen() then return end
    for _, inst in pairs(screen.instances or {}) do releaseFocus(inst) end
end

-- Throw the screen away (resolution change, death) so it is rebuilt clean.
function Hub.reset()
    if screen then
        Hub.close()
        screen = nil
    end
end

VPUI.Events.add("LayoutChanged", function()
    if screen and screen:getIsVisible() then screen:layoutAll() end
end)
