--
-- Viewpoint UI - gear panel: the equipment column as slots you drag onto.
--
--   centre:     [PRIMARY] [ your character ] [SECONDARY]   hands beside the 3D model
--               ATTACHED the game's hotbar slots (belt, holster, back
--               sheath...) in an even row under it, same numbers as the hotbar
--   top right:  EQUIPMENT small clothing slots (Inventory/Gear.lua groups) in
--               three rows of six by body area; worn weight and cover
--
-- The 3D model itself is a UI3DModel the inventory tab owns (placed on
-- modelRect); this panel draws its backdrop. Dropping an item on the character
-- wears it (or holds it when it cannot be worn).
--
-- Drop an item on a hand slot to hold it, on a clothing slot to wear it, on an
-- attachment slot to attach it. While dragging, the slots the item fits are
-- outlined. Drag a slot's item out (to your bags, a container or Ground) to
-- take it off and move it. Double-click takes off / puts away. Right-click
-- lists every action the game has for the item. A slot holding several items
-- shows the outermost with "+n"; its right-click menu switches between them.
--
-- A plain table drawn by the inventory tab (see UI/Region.lua for why).
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/Inventory/Gear"
require "ViewpointUI/Inventory/Model"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.GearPanel then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Gear = VPUI.Inventory.Gear
local Model = VPUI.Inventory.Model

local Panel = {}
Panel.__index = Panel
VPUI.Screens.GearPanel = Panel


local function utf8TrimLast(value)
    -- Remove one complete UTF-8 code point, never part of a Cyrillic character.
    value = tostring(value or "")
    local i = #value
    if i == 0 then return "" end
    while i > 1 do
        local b = string.byte(value, i)
        if not b or b < 128 or b >= 192 then break end
        i = i - 1
    end
    return string.sub(value, 1, i - 1)
end

-- The clothing slots in two rows of equal length: head and upper body, then
-- base layers, legs and what is carried.
local SLOT_ROWS = {
    { "head", "eyes", "face", "neck", "hands", "wrist", "outer", "jacket", "vest" },
    { "top", "under", "armor", "back", "bag", "belt", "legs", "socks", "feet" },
}

-- Text cut to a width (measured once per text and width).
local fitCache = {}
local function fit(text, font, maxW)
    text = tostring(text or "")
    local key = text .. "|" .. tostring(maxW) .. "|" .. tostring(font)
    local hit = fitCache[key]
    if hit then return hit end
    local tm = getTextManager()
    local out = text
    if tm:MeasureStringX(font, out) > maxW then
        while #out > 0 and tm:MeasureStringX(font, out .. "..") > maxW do out = utf8TrimLast(out) end
        out = out .. ".."
    end
    fitCache[key] = out
    return out
end

function Panel.new()
    local o = setmetatable({}, Panel)
    o.x, o.y, o.w, o.h = 0, 0, 0, 0
    o.cells = {}
    o.pick = {}          -- slot id -> index of the item shown when several are worn there
    o.selected = nil     -- cell key
    o.lastItem = {}      -- cell key -> item shown last refresh (to flash changes)
    o.flashAt = {}       -- cell key -> time the slot's item changed
    o.summary = nil
    return o
end

-- Builds the cells (geometry + content) for the player. Cheap; called on the
-- inventory tab's rebuild and on layout. Two areas, as DayZ has them:
--
--   centre (layout):         +------+ +--------------+ +------+
--                            |PRIM. | | 3D character | | SEC. |
--                            +------+ +--------------+ +------+
--                            ATTACHED  [1][2][3][4]...   (even rows)
--   top right (layoutSlots): EQUIPMENT [hd][ey][fc][nk][gl][wr][ou][jk][vs]
--                                      [tp][bs][pd][bk][bg][bt][lg][sk][ft]   2 x 9
--                            worn weight · cover
function Panel:refresh(player)
    self.player = player
    if self.w <= 0 or not player then return end
    local gap = Theme.px(6)
    local small = Theme.smallFont()
    local labelH = Theme.fontHeight(small) + Theme.px(4)
    local cells = {}

    -- centre: the character with a hand slot either side, the hotbar
    -- attachments in an even row (or rows) under it
    local attachments, bar = Gear.attachments(player)
    self.bar = bar
    local agap = Theme.px(6)
    local maxAtt = VPUI.Settings.get("compactUI") == true and Theme.px(52) or Theme.px(62)
    local nAtt = math.max(1, #attachments)
    local attRows = math.max(1, math.ceil((nAtt * (Theme.px(48) + agap)) / math.max(1, self.w)))
    local attCols = math.ceil(nAtt / attRows)
    local attCell = math.max(Theme.px(38), math.min(maxAtt, math.floor((self.w - agap * (attCols - 1)) / attCols)))
    local attH = attRows * (attCell + agap)
    -- the character takes the room: slim hand slots either side of it
    local modelH = math.max(Theme.px(180), self.h - attH - gap)
    local handW = math.max(Theme.px(56), math.floor(self.w * 0.15))
    local handH = math.max(Theme.px(72), math.min(math.floor(modelH * 0.33), Theme.px(150)))
    local modelW = math.max(Theme.px(60), self.w - (handW + gap) * 2)
    local bx = self.x
    -- level with the character's middle (the tab places the model and tells us where)
    local handY = self.modelMidY and math.floor(self.modelMidY - handH / 2) or (self.y + math.floor((modelH - handH) / 2))
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    local twoHanded = primary ~= nil and secondary == primary
    table.insert(cells, { key = "hand:primary", kind = "hand", hand = "primary", label = VPUI.Text.gearPrimary,
                          items = primary and { primary } or {}, x = bx, y = handY, w = handW, h = handH })
    table.insert(cells, { key = "hand:secondary", kind = "hand", hand = "secondary", label = VPUI.Text.gearSecondary,
                          items = (secondary and not twoHanded) and { secondary } or {}, twoHanded = twoHanded,
                          x = bx + handW + gap + modelW + gap, y = handY, w = handW, h = handH })
    self.modelRect = { x = bx + handW + gap, y = self.y, w = modelW, h = modelH }

    -- the hotbar attachments in an even row (or rows) under the character, no title
    -- centred in the space between the character's feet and the bottom
    local ay = self.y + modelH + gap
    if self.modelFeet then
        local blockH = attRows * attCell + (attRows - 1) * agap
        local bottom = self.y + self.h
        ay = math.floor(self.modelFeet + (bottom - self.modelFeet - blockH) / 2)
    end
    local rowW = attCols * attCell + (attCols - 1) * agap
    local ax = self.x + math.floor((self.w - rowW) / 2)
    self.attachY = ay
    self.attachX = ax
    self.attachCount = #attachments
    for i, at in ipairs(attachments) do
        local col = (i - 1) % attCols
        local row = math.floor((i - 1) / attCols)
        table.insert(cells, { key = "attach:" .. tostring(at.index), kind = "attach", entry = at, label = at.name,
                              items = at.item and { at.item } or {}, number = at.index, small = true,
                              x = ax + col * (attCell + agap), y = ay + row * (attCell + agap), w = attCell, h = attCell })
    end

    -- top right: the clothing slots in two even rows, grouped by body area; "Other" only when something
    -- is worn there, at the end of the last row
    local area = self.slotsArea
    if area and area.w > 0 then
        local sgap = Theme.px(3)
        local worn = Gear.worn(player)
        local rows = {}
        for r, ids in ipairs(SLOT_ROWS) do
            rows[r] = {}
            for _, id in ipairs(ids) do
                local slot = Gear.slot(id)
                if slot then table.insert(rows[r], slot) end
            end
        end
        local cols = 0
        for _, r in ipairs(rows) do cols = math.max(cols, #r) end
        local otherSlot = Gear.slot("other")
        local other = otherSlot and worn.other and #worn.other > 0
        -- the rows fill the column exactly: the first slot starts at its left
        -- edge (under "Equipment"), the last ends at its right edge (under the
        -- carried weight); leftover pixels are spread so every gap is equal
        local step = (area.w + sgap) / cols
        local cell = math.max(Theme.px(26), math.floor(step) - sgap)
        local function colX(c) return area.x + math.floor((c - 1) * step) end
        local function colW(c) return math.floor(c * step) - math.floor((c - 1) * step) - sgap end
        local y = area.y   -- no "Equipment" title: the slots speak for themselves
        self.slotCell = cell
        self.slotsX = area.x
        for r, list in ipairs(rows) do
            for c, slot in ipairs(list) do
                table.insert(cells, { key = "wear:" .. slot.id, kind = "wear", slot = slot.id, label = slot.label, items = worn[slot.id] or {},
                                      small = true, x = colX(c), y = y + (r - 1) * (cell + sgap), w = colW(c), h = cell })
            end
        end
        local nRows = #rows
        if other then
            -- a third row of its own, so the two full rows stay fitted
            table.insert(cells, { key = "wear:other", kind = "wear", slot = "other", label = otherSlot.label, items = worn.other,
                                  small = true, x = colX(1), y = y + nRows * (cell + sgap), w = colW(1), h = cell })
            nRows = nRows + 1
        end
        y = y + nRows * (cell + sgap)
        self.summaryY = y + Theme.px(2)
        self.summaryX = area.x
        self.slotsBottom = self.summaryY + labelH + Theme.px(6)
        self.slotsRect = { x = area.x, y = area.y, w = area.w, h = self.slotsBottom - area.y }
    end

    -- a slot whose item changed flashes for a moment
    local now = VPUI.Util.now()
    for _, c in ipairs(cells) do
        local item = c.items[1]
        if item ~= nil and self.lastItem[c.key] ~= item and self.cells and #self.cells > 0 then
            self.flashAt[c.key] = now
        end
        self.lastItem[c.key] = item
    end
    self.cells = cells
    self:readSummary(player)
end

-- The equipment slots' area (top of the right column); refresh fills it and
-- sets slotsBottom, where the rest of that column starts.
function Panel:layoutSlots(x, y, w)
    self.slotsArea = { x = x, y = y, w = w }
    if self.player then self:refresh(self.player) end
end

-- Is (x, y) on the character (not on a slot)?
function Panel:onModel(x, y)
    local r = self.modelRect
    return r ~= nil and x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h
end

-- Worn weight and how well the clothes cover the body: the average over body
-- parts of the game's own per-part defence (IsoGameCharacter:
-- getBodyPartClothingDefense, as the vanilla protection panel shows it).
function Panel:readSummary(player)
    local ok, err = pcall(function()
        local weight = 0
        local worn = player:getWornItems()
        for i = 0, worn:size() - 1 do
            local item = worn:get(i):getItem()
            if item then weight = weight + item:getEquippedWeight() end
        end
        local parts = BodyPartType.ToIndex(BodyPartType.MAX)
        local bite, scratch, bullet = 0, 0, 0
        for i = 0, parts - 1 do
            bite = bite + player:getBodyPartClothingDefense(i, true, false)
            scratch = scratch + player:getBodyPartClothingDefense(i, false, false)
            bullet = bullet + player:getBodyPartClothingDefense(i, false, true)
        end
        if parts > 0 then bite, scratch, bullet = bite / parts, scratch / parts, bullet / parts end
        self.summary = { weight = weight, bite = bite, scratch = scratch, bullet = bullet }
    end)
    if not ok then
        self.summary = nil
        VPUI.Log.once(VPUI.Log.DEBUG, "gearSummary", "gear summary unavailable: " .. tostring(err))
    end
end

function Panel:layout(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    if self.player then self:refresh(self.player) end
end

-- The item a cell shows (several worn at one slot: the picked one).
function Panel:shown(cell)
    if not cell or #cell.items == 0 then return nil end
    local i = self.pick[cell.key] or 1
    if i > #cell.items then i = 1 end
    return cell.items[i]
end

function Panel:cellAt(x, y)
    for _, cell in ipairs(self.cells) do
        if x >= cell.x and y >= cell.y and x < cell.x + cell.w and y < cell.y + cell.h then return cell end
    end
    return nil
end

function Panel:inside(x, y)
    local r = self.slotsRect
    if r and x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h then return true end
    return x >= self.x and y >= self.y and x < self.x + self.w and y < self.y + self.h
end

-- Would dropping `item` on `cell` do something?
function Panel:accepts(cell, item)
    if not cell or not item then return false end
    if cell.kind == "hand" then return true end
    if cell.kind == "wear" then return Gear.slotForItem(item) == cell.slot end
    if cell.kind == "attach" then return Gear.canAttach(self.bar, cell.entry, item) end
    return false
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function bar(ui, item, x, y, w)
    local v = Model.barOf(item)
    if not v then return end
    v = VPUI.Util.clamp(v, 0, 1)
    ui:drawRect(x, y, w, Theme.px(3), C.track.a, C.track.r, C.track.g, C.track.b)
    local c = v < 0.25 and C.danger or (v < 0.5 and C.accent or C.good)
    ui:drawRect(x, y, math.max(1, math.floor(w * v)), Theme.px(3), 1, c.r, c.g, c.b)
end

function Panel:drawCell(ui, cell, mx, my, dragItem)
    local small = Theme.smallFont()
    local item = self:shown(cell)
    local hover = mx >= cell.x and my >= cell.y and mx < cell.x + cell.w and my < cell.y + cell.h
    local bg = (hover or self.selected == cell.key) and C.panelHi or C.panel
    ui:drawRect(cell.x, cell.y, cell.w, cell.h, item and bg.a or bg.a * 0.6, bg.r, bg.g, bg.b)

    -- outline: accent where a dragged item fits, red where it is hovered and does not
    local edge, edgeA = C.edge, item and 0.18 or 0.10
    if dragItem then
        if self:accepts(cell, dragItem) then
            edge, edgeA = C.accent, hover and 1 or 0.55
        elseif hover then
            edge, edgeA = C.danger, 0.7
        end
    elseif self.selected == cell.key then
        edge, edgeA = C.accent, 0.8
    end
    ui:drawRectBorder(cell.x, cell.y, cell.w, cell.h, edgeA, edge.r, edge.g, edge.b)
    local flash = self.flashAt[cell.key]
    if flash then
        local t = VPUI.Util.now() - flash
        if t < 450 then
            local a = 0.35 * (1 - t / 450)
            ui:drawRect(cell.x, cell.y, cell.w, cell.h, a, C.accent.r, C.accent.g, C.accent.b)
        else
            self.flashAt[cell.key] = nil
        end
    end

    local labelC = item and C.dim or C.off
    local fh = Theme.fontHeight(small)
    if cell.kind == "hand" then
        -- tall slot beside the character: label on top, icon in the middle,
        -- name and condition at the bottom
        local inner = cell.w - Theme.px(10)
        ui:drawText(fit(cell.label, small, inner), cell.x + Theme.px(5), cell.y + Theme.px(4), labelC.r, labelC.g, labelC.b, 1, small)
        if item then
            local icon = math.max(Theme.px(16), math.min(cell.w - Theme.px(12), cell.h - fh * 3 - Theme.px(16)))
            ui:drawItemIcon(item, cell.x + math.floor((cell.w - icon) / 2), cell.y + math.floor((cell.h - icon) / 2), 1, icon, icon)
            ui:drawText(fit(item:getDisplayName(), small, inner), cell.x + Theme.px(5), cell.y + cell.h - fh - Theme.px(9),
                C.text.r, C.text.g, C.text.b, 1, small)
            bar(ui, item, cell.x + Theme.px(5), cell.y + cell.h - Theme.px(5), cell.w - Theme.px(10))
        else
            local text = cell.twoHanded and VPUI.Text.gearTwoHanded or VPUI.Text.invEmpty
            ui:drawText(fit(text, small, inner), cell.x + Theme.px(5), cell.y + cell.h - fh - Theme.px(8),
                C.off.r, C.off.g, C.off.b, 1, small)
        end
        return
    end

    if cell.small then
        -- DayZ-style small slot: the item fills it; an empty one shows its name dimly
        local side = math.min(cell.w, cell.h)
        local pad = math.max(Theme.px(3), math.floor(side * 0.12))
        local icon = side - pad * 2
        local ix, iy = cell.x + math.floor((cell.w - icon) / 2), cell.y + math.floor((cell.h - icon) / 2)
        if item then
            ui:drawItemIcon(item, ix, iy, 1, icon, icon)
            if #cell.items > 1 then
                ui:drawTextRight("+" .. tostring(#cell.items - 1), cell.x + cell.w - Theme.px(2), cell.y, C.accent.r, C.accent.g, C.accent.b, 1, small)
            end
            bar(ui, item, cell.x + Theme.px(3), cell.y + cell.h - Theme.px(4), cell.w - Theme.px(6))
        else
            -- empty: a faded picture of what goes there (its name on hover),
            -- or the name when there is no picture for it
            local ph = Gear.placeholder(cell)
            local drawn = false
            if ph then
                drawn = pcall(function() ui:drawTextureScaledAspect(ph, ix, iy, icon, icon, hover and 0.45 or 0.22, 1, 1, 1) end)
            end
            if not drawn or hover then
                local text = fit(cell.label, small, cell.w - Theme.px(4))
                local tw = Theme.textWidth(small, text)
                local ty = drawn and (cell.y + cell.h - fh - Theme.px(1)) or (cell.y + math.floor((cell.h - fh) / 2))
                ui:drawText(text, cell.x + math.floor((cell.w - tw) / 2), ty, C.dim.r, C.dim.g, C.dim.b, drawn and 1 or 0.8, small)
            end
        end
        if cell.number then
            ui:drawText(tostring(cell.number), cell.x + Theme.px(2), cell.y, C.off.r, C.off.g, C.off.b, 1, small)
        end
        local fill = item and self:bagFill(item)
        if fill then
            local bh = cell.h - Theme.px(8)
            local fc = fill > 1 and C.danger or (fill > 0.8 and C.accent or C.good)
            local f = math.min(1, fill)
            ui:drawRect(cell.x + cell.w - Theme.px(4), cell.y + Theme.px(4), Theme.px(2), bh, C.track.a, C.track.r, C.track.g, C.track.b)
            ui:drawRect(cell.x + cell.w - Theme.px(4), cell.y + Theme.px(4) + bh - math.floor(bh * f), Theme.px(2), math.floor(bh * f), 1, fc.r, fc.g, fc.b)
        end
        return
    end

    -- square slot: label top-left, icon centred, +n and condition at the bottom
    ui:drawText(fit(cell.label, small, cell.w - Theme.px(8)), cell.x + Theme.px(4), cell.y + Theme.px(2), labelC.r, labelC.g, labelC.b, item and 0.9 or 0.7, small)
    if cell.number then
        ui:drawTextRight(tostring(cell.number), cell.x + cell.w - Theme.px(4), cell.y + Theme.px(2), C.off.r, C.off.g, C.off.b, 1, small)
    end
    if item then
        local top = cell.y + fh + Theme.px(2)
        local avail = cell.h - fh - Theme.px(10)
        local icon = math.max(Theme.px(12), math.min(avail, cell.w - Theme.px(12)))
        ui:drawItemIcon(item, cell.x + math.floor((cell.w - icon) / 2), top, 1, icon, icon)
        if #cell.items > 1 then
            ui:drawTextRight("+" .. tostring(#cell.items - 1), cell.x + cell.w - Theme.px(4), cell.y + cell.h - fh - Theme.px(4),
                C.accent.r, C.accent.g, C.accent.b, 1, small)
        end
        bar(ui, item, cell.x + Theme.px(4), cell.y + cell.h - Theme.px(5), cell.w - Theme.px(8))
        -- a worn bag: how full it is, as a bar up the right edge
        local fill = self:bagFill(item)
        if fill then
            local bh = cell.h - fh - Theme.px(12)
            local by = cell.y + fh + Theme.px(4)
            local fc = fill > 1 and C.danger or (fill > 0.8 and C.accent or C.good)
            ui:drawRect(cell.x + cell.w - Theme.px(5), by, Theme.px(3), bh, C.track.a, C.track.r, C.track.g, C.track.b)
            local f = math.min(1, fill)
            ui:drawRect(cell.x + cell.w - Theme.px(5), by + bh - math.floor(bh * f), Theme.px(3), math.floor(bh * f), 1, fc.r, fc.g, fc.b)
        end
    end
end

-- 0..1+ fill of a bag (InventoryContainer), or nil for anything else.
function Panel:bagFill(item)
    local ok, v = pcall(function()
        if not instanceof(item, "InventoryContainer") then return nil end
        local cap = item:getEffectiveCapacity(self.player)
        if not cap or cap <= 0 then return nil end
        return item:getInventory():getCapacityWeight() / cap
    end)
    if ok then return v end
    return nil
end

function Panel:draw(ui, mx, my, dragItem)
    local small = Theme.smallFont()
    local r = self.modelRect
    if r then
        -- no box, outline or highlight round the character, not even while an
        -- item is dragged over it
        local over = dragItem and self:onModel(mx, my)
        -- while an item is dragged over the character, a short "drop to wear"
        -- line above its head (clear of the attachment slots under its feet)
        if over then
            local hint = VPUI.Text.gearDropOnModel
            local tw = Theme.textWidth(small, hint)
            ui:drawText(hint, r.x + math.floor((r.w - tw) / 2), r.y + Theme.px(2), C.accent.r, C.accent.g, C.accent.b, 1, small)
        end
    end
    for _, cell in ipairs(self.cells) do
        local ok, err = pcall(self.drawCell, self, ui, cell, mx, my, dragItem)
        if not ok then VPUI.Log.once(VPUI.Log.ERROR, "gearCell", "gear slot draw failed: " .. tostring(err)) end
    end
    local sm = self.summary
    if sm and self.summaryY then
        local line = string.format(VPUI.Text.gearWornWeight, sm.weight) .. "    " ..
            string.format(VPUI.Text.gearCover, math.floor(sm.bite + 0.5), math.floor(sm.scratch + 0.5), math.floor(sm.bullet + 0.5))
        ui:drawText(line, self.summaryX, self.summaryY, C.dim.r, C.dim.g, C.dim.b, 1, small)
    end
    if (self.attachCount or 0) == 0 and self.attachY then
        -- nothing to attach to (no belt): a quiet line where the slots would be
        local text = VPUI.Text.gearNoAttach
        local tw = Theme.textWidth(small, text)
        ui:drawText(text, self.x + math.floor((self.w - tw) / 2), self.attachY, C.off.r, C.off.g, C.off.b, 1, small)
    end
end
