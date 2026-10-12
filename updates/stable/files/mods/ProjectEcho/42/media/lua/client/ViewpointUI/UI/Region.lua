--
-- Viewpoint UI - regions: lightweight, non-UIElement building blocks that a
-- VPScreen lays out, draws and routes mouse events to. Keeping lists, buttons
-- and tabs as plain tables (instead of one Java UIElement each) means a full
-- inventory screen costs one UIElement, and hit-testing stays in one place.
--
--   Region.Button  - a labelled clickable rectangle
--   Region.List    - a scrolling list of rows with selection, hover, activation,
--                    context click and drag start
--   Region.TabBar  - a row of tabs
--
-- All drawing goes through the owning screen (an ISUIElement), so stencils,
-- fonts and colours stay consistent.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.Region then return end

local Theme = VPUI.UI.Theme
local C = Theme.color

local Region = {}
VPUI.UI.Region = Region

local function inside(r, x, y)
    return r.visible ~= false and x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h
end
Region.inside = inside

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------

local Button = {}
Button.__index = Button
Region.Button = Button

-- spec: { label, onClick = fn(), enabled = fn()|bool, accent = bool, font }
function Button.new(spec)
    local o = setmetatable({}, Button)
    o.label = spec.label or ""
    o.onClick = spec.onClick
    o.enabledFn = spec.enabled
    o.accent = spec.accent == true
    o.font = spec.font
    o.tooltip = spec.tooltip
    o.x, o.y, o.w, o.h = 0, 0, 0, 0
    return o
end

function Button:isEnabled()
    if type(self.enabledFn) == "function" then
        local ok, v = pcall(self.enabledFn)
        return ok and v ~= false
    end
    return self.enabledFn ~= false
end

function Button:preferredWidth()
    local font = self.font or Theme.smallFont()
    return Theme.textWidth(font, self.label) + Theme.px(20)
end

function Button:layout(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w or self:preferredWidth(), h or (Theme.fontHeight(self.font or Theme.smallFont()) + Theme.px(8))
end

function Button:draw(ui, mx, my)
    if self.visible == false then return end
    local enabled = self:isEnabled()
    local hover = enabled and inside(self, mx, my)
    local bg = hover and C.panelHi or C.panel
    ui:drawRect(self.x, self.y, self.w, self.h, bg.a, bg.r, bg.g, bg.b)
    local edge = (self.accent and enabled) and C.accent or C.edge
    ui:drawRectBorder(self.x, self.y, self.w, self.h, self.accent and 0.8 or 0.25, edge.r, edge.g, edge.b)
    local font = self.font or Theme.smallFont()
    local tw = Theme.textWidth(font, self.label)
    local c = enabled and (self.accent and C.accent or C.text) or C.off
    ui:drawText(self.label, self.x + math.floor((self.w - tw) / 2), self.y + math.floor((self.h - Theme.fontHeight(font)) / 2), c.r, c.g, c.b, c.a, font)
end

function Button:mouseDown(x, y)
    if not inside(self, x, y) then return false end
    if self:isEnabled() and self.onClick then
        local ok, err = pcall(self.onClick)
        if not ok then VPUI.Log.error("button '" .. tostring(self.label) .. "' failed: " .. tostring(err)) end
    end
    return true
end

---------------------------------------------------------------------------
-- List
---------------------------------------------------------------------------

local List = {}
List.__index = List
Region.List = List

-- spec:
--   rowHeight      pixels (or function)
--   drawRow        fn(ui, row, x, y, w, h, state) state = { selected, hovered, index }
--   onSelect       fn(row, index, mods)          single click
--   onActivate     fn(row, index, mods)          double click
--   onContext      fn(row, index, screenX, screenY)  right click
--   onDragStart    fn(row, index) -> payload|nil
--   onQuick        fn(row, index, mods) -> true when it handled a Ctrl/Alt click
--   multiSelect    bool (Shift+click adds to the selection)
--   emptyText      string shown when there are no rows
-- Grid mode (setGrid(true)): rows with kind "header" stay full-width bars;
-- every other row becomes a square tile drawn by spec.drawTile (same
-- signature as drawRow), spec.cellSize pixels wide (number or function).
function List.new(spec)
    local o = setmetatable({}, List)
    o.spec = spec
    o.rows = {}
    o.rects = {}
    o.scroll = 0
    o.selected = {}
    o.anchor = nil
    o.grid = false
    o.x, o.y, o.w, o.h = 0, 0, 0, 0
    return o
end

function List:rowHeight()
    local rh = self.spec.rowHeight
    if type(rh) == "function" then return rh() end
    return rh or (Theme.fontHeight(Theme.font()) + Theme.px(8))
end

function List:cellSize()
    local c = self.spec.cellSize
    if type(c) == "function" then return c() end
    return c or Theme.px(64)
end

-- Row rectangles, relative to the list's top (before scrolling).
function List:computeRects()
    local rects = {}
    local rh = self:rowHeight()
    if not self.grid or not self.spec.drawTile then
        for i = 1, #self.rows do rects[i] = { x = 0, y = (i - 1) * rh, w = self.w, h = rh } end
        self.rects = rects
        self.content = #self.rows * rh
        return
    end
    local cell = self:cellSize()
    local gap = Theme.px(4)
    local avail = self.w - Theme.px(6)   -- room for the scrollbar
    local cols = math.max(1, math.floor((avail + gap) / (cell + gap)))
    -- spec.fillWidth: the tiles stretch so the row ends at the scrollbar
    -- (no wide empty strip on the right); leftover pixels are spread evenly
    local step = cell + gap
    if self.spec.fillWidth then
        step = (avail + gap) / cols
        cell = math.floor(step) - gap
    elseif self.spec.spread then
        -- tiles keep their size; the columns spread so the row still ends at
        -- the scrollbar (used to match another list's tile size exactly)
        step = cols > 1 and (avail - cell) / (cols - 1) or cell + gap
    end
    local function colX(c) return math.floor(c * step) end
    local function colW(c) return math.floor((c + 1) * step) - math.floor(c * step) - gap end
    local y, col = 0, 0
    for i, row in ipairs(self.rows) do
        if row.kind == "header" then
            if col > 0 then y = y + cell + gap; col = 0 end
            rects[i] = { x = 0, y = y, w = self.w, h = rh }
            y = y + rh + gap
        else
            rects[i] = { x = colX(col), y = y, w = self.spec.fillWidth and colW(col) or cell, h = cell }
            col = col + 1
            if col >= cols then col = 0; y = y + cell + gap end
        end
    end
    if col > 0 then y = y + cell + gap end
    self.rects = rects
    self.content = y
end

-- The tile size this list draws at its current width (after fillWidth).
function List:tileSize()
    local cell = self:cellSize()
    if not self.spec.fillWidth or self.w <= 0 then return cell end
    local gap = Theme.px(4)
    local avail = self.w - Theme.px(6)
    local cols = math.max(1, math.floor((avail + gap) / (cell + gap)))
    return math.floor((avail + gap) / cols) - gap
end

function List:setGrid(on)
    on = on == true
    if on == self.grid then return end
    self.grid = on
    self:computeRects()
    self:clampScroll()
end

function List:setRows(rows)
    self.rows = rows or {}
    -- keep selection by identity where possible
    local keep = {}
    for i, row in ipairs(self.rows) do
        if row.key and self.selectedKeys and self.selectedKeys[row.key] then keep[i] = true end
    end
    self.selected = keep
    self:computeRects()
    self:clampScroll()
end

function List:layout(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    self:computeRects()
    self:clampScroll()
end

function List:contentHeight()
    return self.content or (#self.rows * self:rowHeight())
end

function List:clampScroll()
    local maxScroll = math.max(0, self:contentHeight() - self.h)
    if self.scroll > maxScroll then self.scroll = maxScroll end
    if self.scroll < 0 then self.scroll = 0 end
end

function List:indexAt(x, y)
    if not inside(self, x, y) then return nil end
    local ly = y - self.y + self.scroll
    local lx = x - self.x
    if not self.grid then
        local i = math.floor(ly / self:rowHeight()) + 1
        if i >= 1 and i <= #self.rows then return i end
        return nil
    end
    for i, r in ipairs(self.rects) do
        if ly >= r.y and ly < r.y + r.h and lx >= r.x and lx < r.x + r.w then return i end
        if r.y > ly then break end
    end
    return nil
end

-- The section (header row index) a point falls in: the last header at or
-- above it, by position, so gaps between tiles and the empty space after a
-- section's last tile still count as that section.
function List:sectionAt(x, y)
    if not inside(self, x, y) then return nil end
    local ly = y - self.y + self.scroll
    local found = nil
    for i, row in ipairs(self.rows) do
        if row.kind == "header" then
            local r = self.rects[i]
            if r and r.y <= ly then found = i elseif r and r.y > ly then break end
        end
    end
    return found
end

function List:rememberSelection()
    self.selectedKeys = {}
    for i, on in pairs(self.selected) do
        if on and self.rows[i] and self.rows[i].key then self.selectedKeys[self.rows[i].key] = true end
    end
end

function List:selectedRows()
    local out = {}
    for i = 1, #self.rows do
        if self.selected[i] then table.insert(out, self.rows[i]) end
    end
    return out
end

-- Shift+hover: the tile under the mouse joins the selection.
function List:paintSelect(x, y)
    if not self.spec.multiSelect then return end
    local i = self:indexAt(x, y)
    -- a tile Shift+clicked off stays off until the mouse leaves it
    if self.paintSkip and self.paintSkip ~= i then self.paintSkip = nil end
    if not i or self.selected[i] or self.paintSkip == i then return end
    local row = self.rows[i]
    if not row or row.kind == "header" then return end
    self.selected[i] = true
    self.anchor = i
    self:rememberSelection()
end

function List:clearSelection()
    self.selected = {}
    self.selectedKeys = {}
end

function List:draw(ui, mx, my)
    if self.visible == false then return end
    ui:setStencilRect(self.x, self.y, self.w, self.h)
    if #self.rows == 0 and self.spec.emptyText then
        local font = Theme.smallFont()
        ui:drawText(self.spec.emptyText, self.x + Theme.px(8), self.y + Theme.px(6), C.off.r, C.off.g, C.off.b, C.off.a, font)
    end
    local hovered = self:indexAt(mx, my)
    for i, r in ipairs(self.rects) do
        local ry = self.y + r.y - self.scroll
        if ry + r.h >= self.y and ry <= self.y + self.h then
            local rx = self.x + r.x
            local row = self.rows[i]
            local tile = self.grid and row.kind ~= "header" and self.spec.drawTile
            local state = { selected = self.selected[i] == true, hovered = hovered == i, index = i }
            if tile then
                local bg = state.selected and C.panelHi or C.panel
                ui:drawRect(rx, ry, r.w, r.h, state.hovered and 0.9 or bg.a, bg.r, bg.g, bg.b)
                if state.selected then
                    ui:drawRectBorder(rx, ry, r.w, r.h, 0.9, C.accent.r, C.accent.g, C.accent.b)
                else
                    ui:drawRectBorder(rx, ry, r.w, r.h, state.hovered and 0.3 or 0.12, 1, 1, 1)
                end
            elseif state.selected then
                ui:drawRect(rx, ry, r.w, r.h - 1, C.panelHi.a, C.panelHi.r, C.panelHi.g, C.panelHi.b)
                ui:drawRect(rx, ry, Theme.px(2), r.h - 1, C.accent.a, C.accent.r, C.accent.g, C.accent.b)
            elseif state.hovered then
                ui:drawRect(rx, ry, r.w, r.h - 1, 0.05, 1, 1, 1)
            end
            local ok, err = pcall(tile or self.spec.drawRow, ui, row, rx, ry, r.w, r.h, state)
            if not ok then VPUI.Log.once(VPUI.Log.ERROR, "drawRow", "list row draw failed: " .. tostring(err)) end
        elseif ry > self.y + self.h then
            break
        end
    end
    ui:clearStencilRect()
    -- scrollbar
    local content = self:contentHeight()
    if content > self.h and self.h > 0 then
        local barH = math.max(Theme.px(16), math.floor(self.h * self.h / content))
        local barY = self.y + math.floor((self.h - barH) * self.scroll / (content - self.h))
        ui:drawRect(self.x + self.w - Theme.px(3), barY, Theme.px(2), barH, 0.35, 1, 1, 1)
    end
end

-- mods: { shift = bool, ctrl = bool }
function List:mouseDown(x, y, mods)
    local i = self:indexAt(x, y)
    if not inside(self, x, y) then return false end
    if not i then
        self:clearSelection()
        return true
    end
    -- Alt+click: a quick action at once. Ctrl+click: a quick action on release,
    -- because Ctrl+drag is something else (split a stack, see dragCheck)
    self.pendingQuick = nil
    if self.spec.onQuick and mods and mods.alt then
        local ok, used = pcall(self.spec.onQuick, self.rows[i], i, mods)
        if ok and used then return true end
    end
    if self.spec.onQuick and mods and mods.ctrl and self.rows[i] and self.rows[i].kind ~= "header" then
        self.pendingQuick = { index = i, mods = mods, row = self.rows[i] }
        self.pressIndex = i
        self.pressX, self.pressY = x, y
        return true
    end
    self.collapseOnUp = nil
    if self.spec.multiSelect and mods and mods.shift then
        -- Shift+click adds to / removes from the selection
        self.selected[i] = not self.selected[i] or nil
        self.anchor = i
        self.paintSkip = i
    elseif self.selected[i] and self:selectionCount() > 1 then
        -- pressed on part of a selection: keep it, so a drag takes all of it;
        -- a plain click (released without dragging) picks this one alone
        self.collapseOnUp = i
        self.anchor = i
    else
        self.selected = { [i] = true }
        self.anchor = i
    end
    self:rememberSelection()
    self.pressIndex = i
    self.pressX, self.pressY = x, y
    if self.spec.onSelect then pcall(self.spec.onSelect, self.rows[i], i, mods) end
    return true
end

-- Returns a drag payload once the mouse has moved far enough from the press.
function List:dragCheck(x, y)
    if not self.pressIndex or not self.spec.onDragStart then return nil end
    if math.abs(x - self.pressX) + math.abs(y - self.pressY) < Theme.px(6) then return nil end
    local i = self.pressIndex
    self.pressIndex = nil
    local split = self.pendingQuick ~= nil
    self.pendingQuick = nil
    if split then
        -- a split is about this one stack, whatever else was selected
        self.selected = { [i] = true }
        self.anchor = i
        self:rememberSelection()
    end
    local ok, payload = pcall(self.spec.onDragStart, self.rows[i], i)
    if ok and type(payload) == "table" then
        if split then payload.split = true end
        return payload
    end
    return nil
end

function List:selectionCount()
    local n = 0
    for _, on in pairs(self.selected) do if on then n = n + 1 end end
    return n
end

function List:mouseUp()
    if self.collapseOnUp and self.pressIndex == self.collapseOnUp then
        self.selected = { [self.collapseOnUp] = true }
        self:rememberSelection()
    end
    self.collapseOnUp = nil
    self.pressIndex = nil
    local q = self.pendingQuick
    self.pendingQuick = nil
    if q and self.rows[q.index] == q.row and self.spec.onQuick then
        pcall(self.spec.onQuick, q.row, q.index, q.mods)
    end
end

function List:doubleClick(x, y, mods)
    local i = self:indexAt(x, y)
    if not i then return inside(self, x, y) end
    if self.spec.onActivate then pcall(self.spec.onActivate, self.rows[i], i, mods) end
    return true
end

function List:rightClick(x, y, screenX, screenY)
    local i = self:indexAt(x, y)
    if not i then return inside(self, x, y) end
    if not self.selected[i] then
        self.selected = { [i] = true }
        self.anchor = i
        self:rememberSelection()
    end
    if self.spec.onContext then pcall(self.spec.onContext, self.rows[i], i, screenX, screenY) end
    return true
end

function List:wheel(x, y, del)
    if not inside(self, x, y) then return false end
    self.scroll = self.scroll + del * self:rowHeight() * 2
    self:clampScroll()
    return true
end

-- Keyboard / gamepad navigation: move the single selection.
function List:moveSelection(step)
    local n = #self.rows
    if n == 0 then return end
    local cur = self.anchor or 0
    local i = VPUI.Util.clamp(cur + step, 1, n)
    self.selected = { [i] = true }
    self.anchor = i
    self:rememberSelection()
    local r = self.rects[i]
    if r then
        if r.y < self.scroll then self.scroll = r.y end
        if r.y + r.h > self.scroll + self.h then self.scroll = r.y + r.h - self.h end
    end
    if self.spec.onSelect then pcall(self.spec.onSelect, self.rows[i], i, {}) end
end

---------------------------------------------------------------------------
-- TabBar
---------------------------------------------------------------------------

local TabBar = {}
TabBar.__index = TabBar
Region.TabBar = TabBar

-- tabs: { { id, label }, ... }
function TabBar.new(onPick)
    local o = setmetatable({}, TabBar)
    o.tabs = {}
    o.active = nil
    o.onPick = onPick
    o.x, o.y, o.w, o.h = 0, 0, 0, 0
    o.rects = {}
    return o
end

function TabBar:setTabs(tabs, active)
    self.tabs = tabs
    self.active = active
end

function TabBar:layout(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    local font = UIFont.Medium
    local cx = x
    self.rects = {}
    for _, tab in ipairs(self.tabs) do
        local tw = Theme.textWidth(font, tab.label) + Theme.px(28)
        table.insert(self.rects, { x = cx, y = y, w = tw, h = h, id = tab.id, label = tab.label })
        cx = cx + tw
    end
end

function TabBar:draw(ui, mx, my)
    local font = UIFont.Medium
    for _, r in ipairs(self.rects) do
        local active = r.id == self.active
        local hover = inside(r, mx, my)
        local c = active and C.text or (hover and C.text or C.dim)
        local tw = Theme.textWidth(font, r.label)
        ui:drawText(r.label, r.x + math.floor((r.w - tw) / 2), r.y + math.floor((r.h - Theme.fontHeight(font)) / 2), c.r, c.g, c.b, c.a, font)
        if active then
            ui:drawRect(r.x + Theme.px(8), r.y + r.h - Theme.px(3), r.w - Theme.px(16), Theme.px(2), C.accent.a, C.accent.r, C.accent.g, C.accent.b)
        end
    end
end

function TabBar:mouseDown(x, y)
    for _, r in ipairs(self.rects) do
        if inside(r, x, y) then
            if self.onPick then self.onPick(r.id) end
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Rail: icon tabs down the left edge (label shown while hovered)
---------------------------------------------------------------------------

local Rail = {}
Rail.__index = Rail
Region.Rail = Rail

local function utf8Prefix(value, limit)
    -- Return at most limit UTF-8 characters. Byte positions are never split.
    value = tostring(value or "")
    limit = math.max(0, limit or 0)
    local characters = 0
    for i = 1, #value do
        local b = string.byte(value, i)
        if b < 128 or b >= 192 then
            characters = characters + 1
            if characters > limit then return string.sub(value, 1, i - 1) end
        end
    end
    return value
end

-- tabs: { { id, label, icon = Texture|nil }, ... }
function Rail.new(onPick)
    local o = setmetatable({}, Rail)
    o.tabs = {}
    o.active = nil
    o.onPick = onPick
    o.x, o.y, o.w, o.h = 0, 0, 0, 0
    o.rects = {}
    return o
end

function Rail:setTabs(tabs, active)
    self.tabs = tabs
    self.active = active
end

function Rail:layout(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    self.rects = {}
    local cy = y
    for _, tab in ipairs(self.tabs) do
        table.insert(self.rects, { x = x, y = cy, w = w, h = w, id = tab.id, label = tab.label, icon = tab.icon })
        cy = cy + w + Theme.px(4)
    end
end

function Rail:hovered(mx, my)
    for _, r in ipairs(self.rects) do
        if inside(r, mx, my) then return r end
    end
    return nil
end

function Rail:draw(ui, mx, my)
    local small = Theme.smallFont()
    for _, r in ipairs(self.rects) do
        local active = r.id == self.active
        local hover = inside(r, mx, my)
        if active then
            ui:drawRect(r.x, r.y, r.w, r.h, C.panelHi.a, C.panelHi.r, C.panelHi.g, C.panelHi.b)
            ui:drawRect(r.x, r.y, Theme.px(3), r.h, 1, C.accent.r, C.accent.g, C.accent.b)
        elseif hover then
            ui:drawRect(r.x, r.y, r.w, r.h, 0.06, 1, 1, 1)
        end
        local alpha = (active or hover) and 1 or 0.55
        local size = math.floor(r.w * 0.55)
        if r.icon then
            ui:drawTextureScaledAspect(r.icon, r.x + math.floor((r.w - size) / 2), r.y + math.floor((r.h - size) / 2), size, size, alpha, 1, 1, 1)
        else
            -- no icon texture: the first two letters
            local text = utf8Prefix(r.label or "?", 2)
            local c = active and C.accent or C.text
            ui:drawText(text, r.x + math.floor((r.w - Theme.textWidth(UIFont.Medium, text)) / 2),
                r.y + math.floor((r.h - Theme.fontHeight(UIFont.Medium)) / 2), c.r, c.g, c.b, alpha, UIFont.Medium)
        end
    end
end

-- The hovered tab's name, drawn last so it sits above the content.
function Rail:drawLabel(ui, mx, my)
    local r = self:hovered(mx, my)
    if not r or r.id == self.active then return end
    local small = Theme.smallFont()
    local w = Theme.textWidth(small, r.label) + Theme.px(16)
    local h = Theme.fontHeight(small) + Theme.px(8)
    local x = r.x + r.w + Theme.px(6)
    local y = r.y + math.floor((r.h - h) / 2)
    ui:drawRect(x, y, w, h, 0.95, C.panel.r, C.panel.g, C.panel.b)
    ui:drawRectBorder(x, y, w, h, 0.5, C.accent.r, C.accent.g, C.accent.b)
    ui:drawText(r.label, x + Theme.px(8), y + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, small)
end

function Rail:mouseDown(x, y)
    local r = self:hovered(x, y)
    if r then
        if self.onPick then self.onPick(r.id) end
        return true
    end
    return false
end
