--
-- Viewpoint UI - inventory tab, laid out like DayZ's inventory.
--
--   NEARBY (left)          | CHARACTER (centre)            | YOU (right)
--   the ground and every   | your character in 3D (drag   | equipment slots on top
--   container in reach,    | to turn) with a hand slot     | (small, DayZ-style) and
--   as a grid of tiles     | either side                   | attachments, then your
--                          |                               | inventory and bags
--
-- Mouse:   click select · Ctrl+click add to selection · Shift+click range
--          double-click move (to the other side; a gear slot: take off)
--          drag onto a gear slot (hold / wear / attach), a section, or Ground (drop)
--          drag a gear slot's item out to take it off and move it
--          right-click: every action the game offers for the item(s)
--          Ctrl+click: quick move (whole stack) · Alt+click: equip / wear
--          Ctrl+drag: move part of a stack (asks how many)
--          Shift+click: pick several
--          drag on the character: turn it · drop an item on it: wear / hold
-- Toolbar: search (name or category) · sort (name, weight, type, condition)
--          category chips · items are shown as a grid of tiles
-- Keys:    R take all from the focused container · T put your loose items into it
--          F favourite · Esc or the inventory key close
-- Hovering an item shows the game's own item tooltip (exact values, mods' too).
--

require "ISUI/ISToolTipInv"
require "ISUI/ISTextEntryBox"
require "ISUI/ISUI3DModel"
require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Inventory/Model"
require "ViewpointUI/Inventory/Actions"
require "ViewpointUI/Inventory/Gear"
require "ViewpointUI/Inventory/Filter"
require "ViewpointUI/Screens/GearPanel"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Inventory then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local Model = VPUI.Inventory.Model
local Actions = VPUI.Inventory.Actions
local Gear = VPUI.Inventory.Gear
local Filter = VPUI.Inventory.Filter
local Log = VPUI.Log
local T = VPUI.Text

local Tab = {}
Tab.__index = Tab
VPUI.Screens.Inventory = Tab


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

local REFRESH_MS = 400       -- poll for container changes at most this often
local TOOLTIP_DELAY_MS = 250

local function compact()
    return VPUI.Settings.get("compactUI") == true
end

local function rowH()
    if compact() then return math.max(Theme.fontHeight(Theme.smallFont()) + Theme.px(6), Theme.px(22)) end
    return math.max(Theme.fontHeight(Theme.font()) + Theme.px(10), Theme.px(30))
end

-- Item tiles: Small (icons only, the default), Medium (icon and name) or
-- Large, from the options; the list then stretches them to fill its width.
local function tileMode()
    local v = tonumber(VPUI.Settings.get("itemTileSize")) or 1
    if v == 2 then return "medium" elseif v == 3 then return "large" end
    return "small"
end

local function tileSize(tab)
    local mode = tileMode()
    local base = mode == "small" and 40 or (mode == "large" and 72 or 56)
    if compact() then base = math.floor(base * 0.85) end
    return Theme.px(base)
end

---------------------------------------------------------------------------
-- Row drawing
---------------------------------------------------------------------------

local function drawHeader(ui, row, x, y, w, h)
    local small = Theme.smallFont()
    local indent = (row.depth or 0) * Theme.px(12)
    ui:drawRect(x, y + h - 1, w, 1, 0.10, 1, 1, 1)
    if row.flashAt then
        local t = VPUI.Util.now() - row.flashAt
        if t < 900 then ui:drawRect(x, y, w, h, 0.3 * (1 - t / 900), C.accent.r, C.accent.g, C.accent.b) end
    end
    local icon = row.icon
    local tx = x + Theme.px(6) + indent
    if icon then
        ui:drawTextureScaledAspect(icon, tx, y + Theme.px(4), h - Theme.px(8), h - Theme.px(8), 0.9, 1, 1, 1)
        tx = tx + h - Theme.px(4)
    end
    local arrow = row.collapsed and "+ " or "- "
    local c = row.focused and C.accent or C.text
    local title = row.matches and (row.title .. "  (" .. tostring(row.matches) .. ")") or row.title
    ui:drawText(arrow .. title, tx, y + math.floor((h - Theme.fontHeight(small)) / 2), c.r, c.g, c.b, 1, small)
    if row.used then
        local text = string.format("%.1f / %s", row.used, tostring(row.capacity))
        local over = row.capacity and row.used > row.capacity
        local cc = over and C.danger or C.dim
        ui:drawTextRight(text, x + w - Theme.px(8), y + math.floor((h - Theme.fontHeight(small)) / 2), cc.r, cc.g, cc.b, 1, small)
    end
end

local function drawItem(ui, row, x, y, w, h)
    local font = Theme.font()
    local small = Theme.smallFont()
    local item = row.first
    local icon = h - Theme.px(8)
    local ix = x + Theme.px(8) + (row.depth or 0) * Theme.px(12)
    ui:drawItemIcon(item, ix, y + Theme.px(4), 1, icon, icon)
    local tx = ix + icon + Theme.px(8)
    local name = row.name
    if #row.items > 1 then name = name .. "  x" .. tostring(#row.items) end
    local c = row.equipped and C.accent or C.text
    ui:drawText(name, tx, y + Theme.px(3), c.r, c.g, c.b, 1, font)
    -- markers
    local tags = {}
    if row.equipped then table.insert(tags, T.invEquipped) end
    if row.hotbar then table.insert(tags, T.invHotbar) end
    if row.favorite then table.insert(tags, "*") end
    if #tags > 0 then
        ui:drawText(table.concat(tags, "  "), tx, y + h - Theme.fontHeight(small) - Theme.px(2), C.dim.r, C.dim.g, C.dim.b, 1, small)
    end
    -- condition / uses bar
    local bar = Model.barOf(item)
    if bar then
        local bw = Theme.px(46)
        local bx = x + w - bw - Theme.px(64)
        local by = y + math.floor(h / 2) - 1
        ui:drawRect(bx, by, bw, Theme.px(3), C.track.a, C.track.r, C.track.g, C.track.b)
        local bc = bar < 0.25 and C.danger or (bar < 0.5 and C.accent or C.good)
        ui:drawRect(bx, by, math.max(1, math.floor(bw * VPUI.Util.clamp(bar, 0, 1))), Theme.px(3), 1, bc.r, bc.g, bc.b)
    end
    ui:drawTextRight(string.format("%.2f", row.weight), x + w - Theme.px(8), y + math.floor((h - Theme.fontHeight(small)) / 2), C.dim.r, C.dim.g, C.dim.b, 1, small)
end

-- Grid mode tile: icon, stack count, short name, equipped / hotbar / favourite
-- marks and the condition bar.
local function drawTile(ui, row, x, y, w, h, state)
    local small = Theme.smallFont()
    local item = row.first
    local fh = Theme.fontHeight(small)
    local icon
    if tileMode() == "small" then
        icon = math.max(Theme.px(12), math.min(w, h) - Theme.px(8))
        ui:drawItemIcon(item, x + math.floor((w - icon) / 2), y + math.floor((h - icon) / 2), 1, icon, icon)
    else
        icon = math.max(Theme.px(12), math.min(w - Theme.px(14), h - fh - Theme.px(12)))
        ui:drawItemIcon(item, x + math.floor((w - icon) / 2), y + Theme.px(4), 1, icon, icon)
    end
    if #row.items > 1 then
        ui:drawTextRight("x" .. tostring(#row.items), x + w - Theme.px(3), y + Theme.px(1), C.text.r, C.text.g, C.text.b, 1, small)
    end
    local mark = row.equipped and "E" or (row.hotbar and "H" or nil)
    if mark then ui:drawText(mark, x + Theme.px(3), y + Theme.px(1), C.accent.r, C.accent.g, C.accent.b, 1, small) end
    if row.favorite then ui:drawText("*", x + Theme.px(3), y + fh, C.accent.r, C.accent.g, C.accent.b, 1, small) end
    -- rounds in a magazine (or anything else that holds them): loaded and
    -- empty ones are separate lines, this says which is which
    local maxAmmo = item:getMaxAmmo()
    if maxAmmo and maxAmmo > 0 then
        local n = item:getCurrentAmmoCount() or 0
        local ac = n > 0 and C.text or C.off
        ui:drawText(tostring(n) .. "/" .. tostring(maxAmmo), x + Theme.px(3) + (mark and Theme.px(10) or 0), y + Theme.px(1), ac.r, ac.g, ac.b, 1, small)
    end
    -- name, cut to the tile width (Small tiles show the icon only)
    if tileMode() == "small" then
        local bar0 = Model.barOf(item)
        if bar0 then
            bar0 = VPUI.Util.clamp(bar0, 0, 1)
            local bc = bar0 < 0.25 and C.danger or (bar0 < 0.5 and C.accent or C.good)
            ui:drawRect(x + Theme.px(3), y + h - Theme.px(4), math.max(1, math.floor((w - Theme.px(6)) * bar0)), Theme.px(2), 1, bc.r, bc.g, bc.b)
        end
        return
    end
    local maxW = w - Theme.px(6)
    if row.tileW ~= maxW then
        -- measured once per row and width, not every frame
        local tm = getTextManager()
        local name = row.name or ""
        if tm:MeasureStringX(small, name) > maxW then
            local cut = name
            while #cut > 0 and tm:MeasureStringX(small, cut .. "..") > maxW do cut = utf8TrimLast(cut) end
            name = cut .. ".."
        end
        row.tileName, row.tileW = name, maxW
    end
    local name = row.tileName
    local c = row.equipped and C.accent or C.dim
    ui:drawText(name, x + Theme.px(3), y + h - fh - Theme.px(5), c.r, c.g, c.b, 1, small)
    local bar = Model.barOf(item)
    if bar then
        bar = VPUI.Util.clamp(bar, 0, 1)
        local bc = bar < 0.25 and C.danger or (bar < 0.5 and C.accent or C.good)
        ui:drawRect(x + Theme.px(3), y + h - Theme.px(4), math.max(1, math.floor((w - Theme.px(6)) * bar)), Theme.px(2), 1, bc.r, bc.g, bc.b)
    end
end

local function drawRow(ui, row, x, y, w, h, state)
    if row.kind == "header" then
        drawHeader(ui, row, x, y, w, h)
    elseif row.kind == "slot" then
        local small = Theme.smallFont()
        ui:drawText(row.label, x + Theme.px(8), y + Theme.px(3), C.dim.r, C.dim.g, C.dim.b, 1, small)
        if row.first then
            local icon = h - Theme.px(8)
            ui:drawItemIcon(row.first, x + w - icon - Theme.px(8), y + Theme.px(4), 1, icon, icon)
            ui:drawText(row.first:getDisplayName(), x + Theme.px(8), y + h - Theme.fontHeight(Theme.font()) - Theme.px(3),
                C.text.r, C.text.g, C.text.b, 1, Theme.font())
        else
            ui:drawText(T.invEmpty, x + Theme.px(8), y + h - Theme.fontHeight(Theme.font()) - Theme.px(3), C.off.r, C.off.g, C.off.b, 1, Theme.font())
        end
    else
        drawItem(ui, row, x, y, w, h)
    end
end

---------------------------------------------------------------------------
-- Tab
---------------------------------------------------------------------------

function Tab.create(screen)
    local self = setmetatable({}, Tab)
    self.screen = screen
    self.collapsed = {}
    self.focusLoot = nil      -- container the R/T keys and quick moves aim at
    self.dirtyAt = 0
    self.signature = ""
    self.hoverItem, self.hoverSince = nil, 0
    self.tooltip = nil
    self.consumes = setmetatable({ [Keyboard.KEY_R] = true, [Keyboard.KEY_T] = true, [Keyboard.KEY_F] = true },
        { __index = function(_, key) return key ~= nil and key > 0 and key == tonumber(VPUI.Settings.get("quickDropKey")) end })

    local function makeList(side)
        return Region.List.new({
            rowHeight = function() return rowH() end,
            -- ground tiles are exactly the size of your inventory's tiles
            cellSize = side == "loot"
                and function() return self.lists and self.lists.player:tileSize() or tileSize(self) end
                or function() return tileSize(self) end,
            fillWidth = side ~= "loot",
            spread = side == "loot",
            drawRow = drawRow,
            drawTile = drawTile,
            multiSelect = true,
            emptyText = side == "loot" and T.invNothingNear or nil,
            onSelect = function(row) self:onSelect(side, row) end,
            onQuick = function(row, i, mods) return self:quick(side, row, mods) end,
            onActivate = function(row, i, mods) self:onActivate(side, row, mods) end,
            onContext = function(row, i, sx, sy) self:onContext(side, row, sx, sy) end,
            onDragStart = function(row) return self:dragPayload(side, row) end,
        })
    end
    self.lists = { player = makeList("player"), loot = makeList("loot") }
    for _, list in pairs(self.lists) do list:setGrid(true) end   -- always a grid of tiles
    self.gear = VPUI.Screens.GearPanel.new()
    self.groupCache = {}

    -- toolbar: search, sort, category chips (shared by both sides)
    self.sortButton = Region.Button.new({ label = "", onClick = function() self:cycleSort() end })
    self.chipButtons = {}
    for _, chip in ipairs(Filter.chips) do
        local id = chip.id
        local b = Region.Button.new({ label = T[chip.text] or id,
            onClick = function() Tab.chip = id; self:rebuild(false) end })
        b.chipId = id
        table.insert(self.chipButtons, b)
    end
    local entry = ISTextEntryBox:new("", 0, 0, 100, 20)
    entry.font = Theme.smallFont()
    entry.backgroundColor = { r = C.panel.r, g = C.panel.g, b = C.panel.b, a = 0.9 }
    entry.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    entry.onTextChange = function()
        Tab.search = string.lower(entry:getInternalText() or "")
        self:rebuild(false)
    end
    -- Esc while typing: the game sends it only to the box (Core.updateKeyboardAux
    -- calls onOtherKey(Esc) and eats the press), so the box itself lets go
    entry.onOtherKey = function(box, key)
        if key == Keyboard.KEY_ESCAPE then pcall(box.unfocus, box) end
    end
    self.searchEntry = entry
    screen:addTabChild(self, entry)
    if entry.setPlaceholderText then pcall(function() entry:setPlaceholderText(T.invSearch) end) end

    -- your character in 3D, the game's own UI3DModel (as the vanilla character
    -- screen shows it); it takes no mouse events, the tab turns it
    local ok, err = pcall(function()
        local model = ISUI3DModel:new(0, 0, 100, 200)
        model.onMouseDown = function() return false end
        model.onMouseUp = function() return false end
        model.onMouseMove = function() return false end
        model.onMouseUpOutside = function() return false end
        model.onMouseMoveOutside = function() return false end
        model.onRightMouseDown = function() return false end
        model.onRightMouseUp = function() return false end
        model.onMouseWheel = function() return false end
        screen:addTabChild(self, model)
        if model.javaObject and model.javaObject.setConsumeMouseEvents then model.javaObject:setConsumeMouseEvents(false) end
        model:setState("idle")
        model:setDirection(IsoDirections.S)
        model:setIsometric(false)
        self.model = model
    end)
    if not ok then Log.once(Log.WARN, "invModel", "the 3D character could not be shown: " .. tostring(err)) end
    self.modelSig = nil

    self.buttons = {
        takeAll = Region.Button.new({ label = T.invTakeAll, accent = true,
            onClick = function() self:takeAll() end,
            enabled = function() return self.focusLoot ~= nil end }),
        storeAll = Region.Button.new({ label = T.invStoreAll,
            onClick = function() self:storeAll() end,
            enabled = function() return self.focusLoot ~= nil end }),
        -- the game's User Panel (factions, safehouse, tickets, server options):
        -- on a server it is the sidebar's USERPANEL button, which is hidden in
        -- Viewpoint's view; opened as ISEquippedItem:onOptionMouseDown does
        userPanel = Region.Button.new({ label = T.invUserPanel,
            onClick = function() Tab.openUserPanel(self:player()) end }),
    }
    return self
end

function Tab:player()
    return VPUI.Util.player()
end

-- Opens (or closes, when it is up) the game's User Panel, the way the vanilla
-- sidebar button does (ISEquippedItem:onOptionMouseDown "USERPANEL").
function Tab.openUserPanel(player)
    if not player or not isClient() or not ISUserPanelUI then return end
    if ISUserPanelUI.instance then
        ISUserPanelUI.instance:close()
        return
    end
    VPUI.Hub.close()
    VPUI.Legacy.openWindow(function()
        local modal = ISUserPanelUI:new(200, 200, 400, 250, player)
        modal:initialise()
        modal:addToUIManager()
    end)
end

-- Search, chip and sort are remembered for the session.
Tab.search = Tab.search or ""
Tab.chip = Tab.chip or "all"
Tab.sortMode = Tab.sortMode or "name"

function Tab:cycleSort()
    local i = 1
    for k, m in ipairs(Filter.sorts) do if m == Tab.sortMode then i = k end end
    Tab.sortMode = Filter.sorts[(i % #Filter.sorts) + 1]
    self:rebuild(false)
end

function Tab:open(args)
    args = args or {}
    -- the vanilla inventory and loot windows are the data source here, not the
    -- interface: if they were left open from isometric view, put them away
    local pn = self:player() and self:player():getPlayerNum() or 0
    for _, page in ipairs({ getPlayerInventory(pn), getPlayerLoot(pn) }) do
        if page and page:getIsVisible() then page:setVisible(false) end
    end
    self.wanted = args.containers   -- containers to focus (from aiming at something)
    self.wantedUntil = VPUI.Util.now() + 15000
    self.selectItem = args.item
    self.modelSig = nil
    self:rebuild(true)
end

-- Keeps the model an exact copy of the player (the way DayZ's preview does):
-- clothing with its blood, dirt, holes and patches, body blood and dirt, belt /
-- holster / back attachments, and what is in the hands with the matching grip
-- pose. The Java part (ModelMirror) copies it all and fingerprints it, so the
-- model is rebuilt only when something visible changed. Without the Java part
-- the game's setCharacter still copies everything but the held items.
local MODEL_CHECK_MS = 300
local MODEL_FILL = 0.88   -- share of the column height the character stands in

function Tab:refreshModel(player, force)
    local model = self.model
    if not model or not player then return end
    local now = VPUI.Util.now()
    if not force and now < (self.modelCheckAt or 0) then return end
    self.modelCheckAt = now + MODEL_CHECK_MS
    local native = VPUI.Native
    if native and native.mirrorModel and native.modelSignature and model.javaObject then
        local okS, sig = pcall(native.modelSignature, player)
        sig = okS and (tostring(player) .. "|" .. tostring(sig)) or nil
        if sig and sig == self.modelSig then return end
        local okM, done = pcall(native.mirrorModel, model.javaObject, player)
        if okM and done == true then
            self.modelSig = sig
            self.modelAngleDirty = true
            return
        end
        Log.once(Log.WARN, "invModelMirror", "the inventory character could not copy held items; showing clothing only")
    end
    -- fallback: worn items and hands as the signature, the game's own copy
    local sig = tostring(player) .. "|" .. tostring(player:getPrimaryHandItem()) .. "|" .. tostring(player:getSecondaryHandItem())
    local worn = player:getWornItems()
    for i = 0, worn:size() - 1 do sig = sig .. "," .. tostring(worn:get(i):getItem()) end
    if sig == self.modelSig then return end
    self.modelSig = sig
    local ok, err = pcall(function() model:setCharacter(player) end)
    if not ok then Log.once(Log.WARN, "invModelChar", "the 3D character could not be updated: " .. tostring(err)) end
end

-- Turning the character. With the Java part it turns to any angle and eases
-- there (drag follows the mouse, the wheel turns a little); without it the
-- game's eight directions are the only ones, a step at a time.
local TURN_PER_PX = 0.012      -- radians per pixel dragged
local TURN_PER_WHEEL = math.pi / 10
local TURN_EASE = 0.25         -- fraction of the way to the target per frame

local function smoothTurning(model)
    local native = VPUI.Native
    return native ~= nil and native.setModelAngle ~= nil and model ~= nil and model.javaObject ~= nil
end

-- Turns the model by `rad` radians (positive: to its left as you see it).
function Tab:turnModelBy(rad)
    local model = self.model
    if not model then return end
    if smoothTurning(model) then
        -- the game's steps go N -> NW (rotate +1); Vector2.rotate turns the
        -- other way, so the angle runs opposite to keep the same feel
        self.modelTarget = (self.modelTarget or 0) - rad
        return
    end
    -- the game's 45-degree steps: gather small turns until one is due
    self.turnRest = (self.turnRest or 0) + rad
    local step = math.pi / 4
    while math.abs(self.turnRest) >= step do
        local dir = self.turnRest > 0 and 1 or -1
        self.turnRest = self.turnRest - dir * step
        pcall(function() model:setDirection(IsoDirectionSet.rotate(model:getDirection(), dir)) end)
    end
end

-- Kept for callers that turn in steps.
function Tab:turnModel(steps)
    self:turnModelBy(steps * math.pi / 4)
end

-- Eases the model toward its target angle (every frame).
function Tab:easeModel()
    local model = self.model
    if not smoothTurning(model) then return end
    local target = self.modelTarget or 0
    local angle = self.modelAngle
    if angle == nil then
        angle = target
    else
        local d = target - angle
        if math.abs(d) < 0.002 then angle = target else angle = angle + d * TURN_EASE end
    end
    if angle == self.modelAngleSet and not self.modelAngleDirty then
        self.modelAngle = angle
        return
    end
    self.modelAngle = angle
    local ok, done = pcall(VPUI.Native.setModelAngle, model.javaObject, angle)
    if ok and done == true then
        self.modelAngleSet = angle
        self.modelAngleDirty = false
    end
end

function Tab:close()
    self:hideTooltip()
    self.wanted = nil
    self.turning = nil
end

function Tab:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local gap = Theme.px(16)
    local lootW = math.floor(w * 0.28)
    local gearW = math.floor(w * 0.33)
    local youW = w - lootW - gearW - gap * 2
    local headH = Theme.fontHeight(UIFont.Medium) + Theme.px(10)
    local footH = compact() and 0 or (Theme.fontHeight(Theme.smallFont()) + Theme.px(14))
    local btnH = Theme.fontHeight(Theme.smallFont()) + Theme.px(8)
    local barH = btnH + Theme.px(8)
    -- toolbar across the top: search, sort, category chips
    local searchW = math.floor(lootW * 0.7)
    self.searchEntry:setX(x)
    self.searchEntry:setY(y)
    self.searchEntry:setWidth(searchW)
    self.searchEntry:setHeight(btnH)
    local bx = x + searchW + Theme.px(8)
    self.sortButton.label = string.format(T.invSort, T["sort_" .. Tab.sortMode] or Tab.sortMode)
    self.sortButton:layout(bx, y, Theme.textWidth(Theme.smallFont(), string.format(T.invSort, T.sort_condition or "condition")) + Theme.px(20), btnH)
    bx = bx + self.sortButton.w + Theme.px(12)
    for _, b in ipairs(self.chipButtons) do
        b:layout(bx, y, nil, btnH)
        bx = bx + b.w + Theme.px(4)
    end
    -- User Panel at the right end of the toolbar, on a server only (the game
    -- only has the panel in multiplayer)
    local up = self.buttons.userPanel
    if isClient() then
        up.visible = true
        local uw = up:preferredWidth()
        up:layout(math.max(bx + Theme.px(8), x + w - uw), y, uw, btnH)
    else
        up.visible = false
        up:layout(x, y, 0, 0)
    end
    local colY = y + barH
    local listY = colY + headH
    local listH = h - barH - headH - footH
    local gearX = x + lootW + gap
    local youX = gearX + gearW + gap
    self.cols = {
        loot = { x = x, y = colY, w = lootW, title = T.invNearby },
        equip = { x = gearX, y = colY, w = gearW },   -- no title: the character speaks for itself
        player = { x = youX, y = colY, w = youW, title = T.invYou },
    }
    self.gear.slotsArea = { x = youX, y = listY, w = youW }
    self.gear:layout(gearX, listY, gearW, listH)
    self:placeModel()
    self.lists.loot:layout(x, listY, lootW, listH - btnH - Theme.px(8))
    self:placeYouList()
    local lby = listY + listH - btnH
    self.buttons.takeAll:layout(x, lby)
    self.buttons.storeAll:layout(x + self.buttons.takeAll.w + Theme.px(8), lby)
    self.footY = y + h - footH + Theme.px(4)
end

-- Your items start under the equipment slots.
function Tab:placeYouList()
    local col, a = self.cols and self.cols.player, self.area
    if not col or not a then return end
    local top = self.gear.slotsBottom or (col.y + Theme.fontHeight(UIFont.Medium) + Theme.px(10))
    local footH = compact() and 0 or (Theme.fontHeight(Theme.smallFont()) + Theme.px(14))
    local bottom = a.y + a.h - footH
    self.lists.player:layout(col.x, top, col.w, math.max(Theme.px(60), bottom - top))
    -- the ground list takes its tile size from this one: lay it out again
    self.lists.loot:computeRects()
    self.lists.loot:clampScroll()
end

-- The 3D model sits on the gear panel's model area.
function Tab:placeModel()
    local model, r = self.model, self.gear.modelRect
    if not model or not r then return end
    -- the game draws the character into a 1:2 box; keep that shape, as big
    -- as the area allows, centred (no text under it any more)
    local room = r.h - Theme.px(4)
    -- a little under the full height: between the old size and filling the column
    local mw = math.min(r.w, math.floor(room / 2 * MODEL_FILL))
    local mh = mw * 2
    model:setX(r.x + math.floor((r.w - mw) / 2))
    -- raised a little: a third of the spare height above, two thirds below
    local my = r.y + Theme.px(2) + math.floor((room - mh) / 3)
    model:setY(my)
    self.gear.modelFeet = my + mh
    local mid = my + math.floor(mh / 2)
    if self.gear.modelMidY ~= mid then
        self.gear.modelMidY = mid
        if self.gear.player then self.gear:refresh(self.gear.player) end
    end
    model:setWidth(mw)
    model:setHeight(mh)
end

-- Rebuilds every list from the game's containers. `refresh` also asks the
-- vanilla pages to re-scan nearby containers (walking around, opening a door).
function Tab:rebuild(refresh)
    local player = self:player()
    if not player then return end
    VPUI.Perf.count(refresh and "inventoryRescans" or "inventoryRebuilds")
    self.playerEntries = Model.playerContainers(player, refresh)
    self.lootEntries = Model.lootContainers(player, refresh)
    if self.wanted then
        -- focus the container the player aimed at once it is in reach (the
        -- player may still be walking to it)
        for _, e in ipairs(self.lootEntries) do
            for _, want in ipairs(self.wanted) do
                if e.container == want then
                    self.focusLoot = want
                    self.wanted = nil
                end
            end
            if not self.wanted then break end
        end
    end
    local stillThere = false
    for _, e in ipairs(self.lootEntries) do
        if e.container == self.focusLoot then stillThere = true end
    end
    if not stillThere then
        self.focusLoot = nil
        for _, e in ipairs(self.lootEntries) do
            if not e.floor then self.focusLoot = e.container break end
        end
        if not self.focusLoot and self.lootEntries[1] then self.focusLoot = self.lootEntries[1].container end
    end
    self.lists.player:setRows(self:rowsFor(self.playerEntries, player, true))
    self.lists.loot:setRows(self:rowsFor(self.lootEntries, player, false))
    self.gear:refresh(player)
    self:placeModel()
    self:placeYouList()
    self:refreshModel(player, true)
    if self.selectItem then
        for _, list in pairs(self.lists) do
            for i, row in ipairs(list.rows) do
                if row.items then
                    for _, it in ipairs(row.items) do
                        if it == self.selectItem then list.selected = { [i] = true }; list.anchor = i; list:rememberSelection() end
                    end
                end
            end
        end
        self.selectItem = nil
    end
    self.signature = self:computeSignature()
end

-- Grouped items of one container, rebuilt only when that container changed
-- (item count, weight, what is held or worn), not on every refresh.
function Tab:groupsOf(container, player, hideEquipped, equipSig)
    local key = tostring(container) .. (hideEquipped and "|h" or "")
    local sig = tostring(container:getItems():size()) .. "|" .. string.format("%.2f", container:getCapacityWeight()) .. "|" .. equipSig
    local c = self.groupCache[key]
    if c and c.sig == sig then return c.groups end
    local groups = Model.groups(container, player, hideEquipped)
    for _, g in ipairs(groups) do g.cat = Filter.category(g.first) end
    self.groupCache[key] = { sig = sig, groups = groups }
    return groups
end

function Tab:rowsFor(entries, player, hideEquipped)
    local rows = {}
    local equipSig = tostring(player:getPrimaryHandItem()) .. tostring(player:getSecondaryHandItem()) .. tostring(player:getWornItems():size())
    local filtering = (Tab.search or "") ~= "" or (Tab.chip or "all") ~= "all"
    for _, e in ipairs(entries) do
        local used, capacity = Model.weightOf(e)
        local key = tostring(e.container)
        local flash = self.bagFlash and self.bagFlash.container == e.container and self.bagFlash.at or nil
        local header = { kind = "header", key = "h:" .. key, title = e.title, icon = e.icon, container = e.container, flashAt = flash,
                         used = used, capacity = capacity, depth = e.depth, floor = e.floor,
                         collapsed = self.collapsed[key] == true, focused = e.container == self.focusLoot }
        table.insert(rows, header)
        if not self.collapsed[key] then
            local shown = {}
            for _, g in ipairs(self:groupsOf(e.container, player, hideEquipped, equipSig)) do
                if not filtering or Filter.match(g, Tab.search, Tab.chip) then
                    g.kind = "item"
                    g.depth = e.depth
                    table.insert(shown, g)
                end
            end
            Filter.sort(shown, Tab.sortMode)
            for _, g in ipairs(shown) do table.insert(rows, g) end
            if filtering then header.matches = #shown end
        end
    end
    return rows
end

-- Cheap change detector: item counts and weights of every listed container.
function Tab:computeSignature()
    local player = self:player()
    if not player then return "" end
    local parts = {}
    local function add(entries)
        for _, e in ipairs(entries or {}) do
            table.insert(parts, tostring(e.container:getItems():size()))
            table.insert(parts, string.format("%.2f", e.container:getCapacityWeight()))
        end
    end
    add(self.playerEntries)
    add(self.lootEntries)
    table.insert(parts, tostring(player:getPrimaryHandItem()))
    table.insert(parts, tostring(player:getSecondaryHandItem()))
    table.insert(parts, tostring(player:getWornItems():size()))
    table.insert(parts, tostring(player:getCurrentSquare()))
    local _, bar = Gear.attachments(player)
    if bar and bar.attachedItems then
        for i, it in pairs(bar.attachedItems) do table.insert(parts, tostring(i) .. tostring(it)) end
        table.insert(parts, tostring(#bar.availableSlot))
    end
    return table.concat(parts, "|")
end

function Tab:update(now)
    local player = self:player()
    if not player then
        VPUI.Hub.close()
        return
    end
    if self.wanted and now > (self.wantedUntil or 0) then self.wanted = nil end
    if now >= self.dirtyAt then
        self.dirtyAt = now + REFRESH_MS
        local moved = self.lastSquare ~= player:getCurrentSquare()
        self.lastSquare = player:getCurrentSquare()
        local sig = self:computeSignature()
        -- OnContainerUpdate sets this; the vanilla pages clear it when they draw,
        -- but they are hidden here, so clear it once it has been acted on
        local dirty = ISInventoryPage.renderDirty == true
        if moved or sig ~= self.signature or dirty or self.wanted then
            if dirty then ISInventoryPage.renderDirty = false end
            self:rebuild(moved or dirty or self.wanted ~= nil)
        end
    end
    self:refreshModel(player)   -- blood, dirt, attachments change without an inventory change
    self:updateTooltip(now)
end

---------------------------------------------------------------------------
-- Rendering
---------------------------------------------------------------------------

function Tab:render(ui, mx, my)
    self:easeModel()
    local medium = UIFont.Medium
    for _, col in pairs(self.cols) do
        if col.title then ui:drawText(col.title, col.x, col.y, C.dim.r, C.dim.g, C.dim.b, 1, medium) end
    end
    -- carried weight
    local player = self:player()
    if player then
        local inv = player:getInventory()
        local text = string.format("%.1f / %d", inv:getCapacityWeight(), player:getMaxWeight())
        local over = inv:getCapacityWeight() > player:getMaxWeight()
        local c = over and C.danger or C.dim
        ui:drawTextRight(text, self.cols.player.x + self.cols.player.w, self.cols.player.y + Theme.px(4), c.r, c.g, c.b, 1, Theme.smallFont())
    end
    -- Shift held: whatever the mouse passes over joins the selection
    if isShiftKeyDown() and not ui.drag and not ui.popup and not isMouseButtonDown(0) then
        for _, list in pairs(self.lists) do list:paintSelect(mx, my) end
    end
    for _, list in pairs(self.lists) do list:draw(ui, mx, my) end
    for _, b in pairs(self.buttons) do b:draw(ui, mx, my) end
    self.sortButton:draw(ui, mx, my)
    for _, b in ipairs(self.chipButtons) do
        b.accent = b.chipId == Tab.chip
        b:draw(ui, mx, my)
    end
    local dragItem = ui.drag and ui.drag.items and ui.drag.items[1] or nil
    self.gear:draw(ui, mx, my, dragItem)
    -- drop target highlight while dragging
    if ui.drag then
        local target = self:dropTarget(mx, my)
        if target and target.rect and target.kind ~= "gear" then
            local r = target.rect
            ui:drawRectBorder(r.x, r.y, r.w, r.h, 0.9, C.accent.r, C.accent.g, C.accent.b)
        end
    end
    if not compact() then
        ui:drawText(T.invHelp, self.area.x, self.footY, C.off.r, C.off.g, C.off.b, 1, Theme.smallFont())
    end
end

---------------------------------------------------------------------------
-- Tooltip (the game's own ISToolTipInv, restyled)
---------------------------------------------------------------------------

function Tab:rowUnder(mx, my)
    local cell = self.gear:cellAt(mx, my)
    if cell then
        local item = self.gear:shown(cell)
        return "gear", item and { first = item, items = { item } } or nil
    end
    for side, list in pairs(self.lists) do
        local i = list:indexAt(mx, my)
        if i then return side, list.rows[i] end
    end
    return nil, nil
end

function Tab:hideTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

function Tab:updateTooltip(now)
    local screen = self.screen
    local mx, my = screen:getMouseX(), screen:getMouseY()
    local _, row = self:rowUnder(mx, my)
    local item = row and row.first or nil
    if screen.popup or screen.drag then item = nil end
    if item ~= self.hoverItem then
        self.hoverItem = item
        self.hoverSince = now
        self:hideTooltip()
        return
    end
    if not item or self.tooltip or now - self.hoverSince < TOOLTIP_DELAY_MS then return end
    local tip = ISToolTipInv:new(item)
    tip:initialise()
    tip:setCharacter(self:player())
    tip.followMouse = true
    tip.backgroundColor = { r = C.panel.r, g = C.panel.g, b = C.panel.b, a = 0.94 }
    tip.borderColor = { r = C.accent.r, g = C.accent.g, b = C.accent.b, a = 0.6 }
    tip:addToUIManager()
    tip:setAlwaysOnTop(true)
    tip:bringToTop()
    self.tooltip = tip
end

---------------------------------------------------------------------------
-- Interaction
---------------------------------------------------------------------------

function Tab:selectedItems(side, fallbackRow)
    local items = {}
    local rows = self.lists[side]:selectedRows()
    if #rows == 0 and fallbackRow then rows = { fallbackRow } end
    for _, row in ipairs(rows) do
        for _, it in ipairs(row.items or {}) do table.insert(items, it) end
    end
    return items
end

function Tab:onSelect(side, row)
    if row and row.kind == "header" then
        -- clicking a header focuses that container (or collapses it on a second click)
        local key = tostring(row.container)
        if side == "loot" and self.focusLoot ~= row.container then
            self.focusLoot = row.container
        else
            self.collapsed[key] = not self.collapsed[key] or nil
        end
        self:rebuild(false)
    end
    -- selections stay on one side at a time
    for other, list in pairs(self.lists) do
        if other ~= side then list:clearSelection() end
    end
    if side ~= "gear" then self.gear.selected = nil end
end

-- Where a quick move from this side goes.
function Tab:otherSide(side)
    local player = self:player()
    if side == "loot" or side == "gear" then return player:getInventory() end
    return self.focusLoot or ISInventoryPage.GetFloorContainer(player:getPlayerNum())
end

-- Ctrl+click: move the whole stack to the other side. Alt+click: wear what can
-- be worn, hold anything else.
function Tab:quick(side, row, mods)
    local player = self:player()
    if not player or not row or row.kind == "header" or not row.items then return false end
    if mods.alt then
        local item = row.items[1]
        if Actions.canWear(item) and Gear.slotForItem(item) then
            if not player:isEquippedClothing(item) then Actions.wear(player, item) end
        else
            Actions.equip(player, item, true)
        end
        return true
    end
    if mods.ctrl then
        Actions.move(player, row.items, self:otherSide(side))
        return true
    end
    return false
end

function Tab:onActivate(side, row, mods)
    local player = self:player()
    if not player or not row then return end
    if row.kind == "header" then return end
    local items = mods and mods.shift and row.items or { row.items[1] }
    Actions.move(player, items, self:otherSide(side))
end

function Tab:onContext(side, row, sx, sy)
    local player = self:player()
    if not player or not row or row.kind == "header" then
        local function fill()
            local n = Actions.storeMatching(player, row.container)
            self.screen:notify(n > 0 and string.format(T.invFilled, tostring(n)) or T.invNothingMatching, 2, n == 0)
        end
        if row and row.kind == "header" and side == "loot" and row.container then
            self.screen:openMenu(sx, sy, row.title, {
                { label = T.invTakeAll, run = function() Actions.takeAll(player, row.container) end },
                { label = T.invStoreAll, run = function() Actions.storeAll(player, row.container) end },
                { label = T.invFillMatching, run = fill },
            })
        elseif row and row.kind == "header" and row.container and row.container ~= player:getInventory() then
            -- a bag you carry: fill it from your main inventory
            self.screen:openMenu(sx, sy, row.title, { { label = T.invFillMatching, run = fill } })
        end
        return
    end
    local items = self:selectedItems(side, row)
    if #items == 0 then return end
    local inPlayer = side ~= "loot"
    local actions = Actions.itemMenu(player, items, inPlayer)
    -- Quick entries of our own first, then everything the game offers.
    local list = {}
    do
        local dest = self:otherSide(side)
        table.insert(list, { label = side == "loot" and T.invTake or T.invMoveToContainer,
                             run = function() Actions.move(player, items, dest) end })
        if #items > 1 then
            -- part of the stack: one, half, or a number you choose
            local function part(n)
                local out = {}
                for k = 1, math.min(n, #items) do out[k] = items[k] end
                Actions.move(player, out, dest)
            end
            local verb = side == "loot" and T.invTakeVerb or T.invMoveVerb
            table.insert(list, { label = string.format(T.invPartOne, verb), run = function() part(1) end })
            if #items > 2 then
                table.insert(list, { label = string.format(T.invPartHalf, verb, tostring(math.floor(#items / 2))),
                                     run = function() part(math.floor(#items / 2)) end })
            end
            table.insert(list, { label = string.format(T.invPartAmount, verb), run = function()
                self.screen:openAmount(sx, sy, {
                    title = string.format(T.amountTitle, items[1]:getDisplayName()),
                    max = #items,
                    initial = math.max(1, math.floor(#items / 2)),
                    onConfirm = function(n) part(n) end,
                })
            end })
        end
        table.insert(list, { label = items[1]:isFavorite() and T.invUnfavorite or T.invFavorite,
                             run = function() Actions.toggleFavorite(items) end })
    end
    for _, a in ipairs(Actions.groupMenu(actions, items[1])) do table.insert(list, a) end
    local title = row.name or (row.first and row.first:getDisplayName())
    if #items > 1 then title = tostring(title) .. "  x" .. tostring(#items) end
    self.screen:openMenu(sx, sy, title, list)
end

function Tab:dragPayload(side, row)
    if not row or row.kind == "header" then return nil end
    local items = self:selectedItems(side, row)
    if #items == 0 then return nil end
    local label = row.name or (row.first and row.first:getDisplayName()) or "?"
    if #items > 1 then label = label .. "  x" .. tostring(#items) end
    return { kind = "items", items = items, from = side, label = label }
end

-- A bag the point is over, or nil: a bag tile in a list, or a worn bag in an
-- equipment slot. Items dropped there go inside it.
local function bagOf(item)
    if not item then return nil end
    local ok, inv = pcall(function()
        if instanceof(item, "InventoryContainer") then return item:getInventory() end
        return nil
    end)
    return ok and inv or nil
end

-- What is under the mouse when dropping: a gear slot, a container, or nothing.
function Tab:dropTarget(mx, my)
    if self.gear:inside(mx, my) then
        local cell = self.gear:cellAt(mx, my)
        -- a worn bag's slot (back, bag, belt...): the item goes inside, unless it
        -- is something to wear there
        if cell and cell.kind == "wear" then
            local bag = bagOf(self.gear:shown(cell))
            if bag then return { kind = "container", container = bag, cell = cell, bagCell = true, rect = cell } end
        end
        return { kind = "gear", cell = cell }
    end
    for _, side in ipairs({ "player", "loot" }) do
        local list = self.lists[side]
        if Region.inside(list, mx, my) then
            -- right on a bag tile: into that bag
            local i = list:indexAt(mx, my)
            local row = i and list.rows[i]
            if row and row.kind ~= "header" then
                local bag = bagOf(row.items and row.items[1] or row.first)
                if bag then
                    local r = list.rects[i]
                    return { kind = "container", container = bag, bagRow = row,
                             rect = { x = list.x + r.x, y = list.y + r.y - list.scroll, w = r.w, h = r.h } }
                end
            end
            -- anywhere else in a section (tiles, gaps, the empty space after
            -- them, the header): that section's container
            local h = list:sectionAt(mx, my)
            local container = h and list.rows[h] and list.rows[h].container or nil
            if not container then
                container = side == "player" and self:player():getInventory() or self.focusLoot
            end
            return { kind = "container", container = container, rect = list }
        end
    end
    return nil
end

-- Puts `item` into a gear slot: hold, wear or attach.
function Tab:toGear(player, item, cell)
    local function swapped(old)
        if old and old ~= item then self.screen:notify(string.format(T.gearSwapped, old:getDisplayName()), 2) end
    end
    if cell and cell.kind == "hand" then
        if cell.items[1] == item then return end
        swapped(cell.items[1])
        Actions.equip(player, item, cell.hand == "primary")
        return
    end
    if cell and cell.kind == "attach" then
        if cell.items[1] == item then return end
        if not Gear.attach(self.gear.bar, cell.entry, item) then
            self.screen:notify(string.format(T.gearDoesNotFit, item:getDisplayName(), cell.label), 3, true)
        else
            swapped(cell.items[1])
        end
        return
    end
    if cell and cell.kind == "wear" then
        -- the game's wear action takes off what is at the same body location;
        -- say which item that was
        local loc = Gear.norm((function() local ok, v = pcall(function() return item:getBodyLocation() or item:canBeEquipped() end) return ok and v or nil end)())
        for _, old in ipairs(cell.items) do
            local ok, ol = pcall(function() return old:getBodyLocation() or old:canBeEquipped() end)
            if ok and loc and Gear.norm(ol) == loc then swapped(old) end
        end
    end
    if cell and cell.kind == "wear" and cell.items[1] == item then return end
    -- a clothing slot or the panel itself: wear what can be worn, else hold it
    if Actions.canWear(item) and Gear.slotForItem(item) then
        if cell and cell.kind == "wear" and Gear.slotForItem(item) ~= cell.slot then
            self.screen:notify(string.format(T.gearWornElsewhere, item:getDisplayName(),
                (Gear.slot(Gear.slotForItem(item)) or {}).label or "?"), 3)
        end
        if not player:isEquippedClothing(item) then Actions.wear(player, item) end
    elseif cell and cell.kind == "wear" then
        self.screen:notify(string.format(T.gearDoesNotFit, item:getDisplayName(), cell.label), 3, true)
    else
        Actions.equip(player, item, true)
    end
end

-- Takes the item in a gear slot off (into the main inventory).
function Tab:fromGear(player, cell, item)
    if not item then return end
    if cell.kind == "attach" then
        Gear.detach(self.gear.bar, item)
    else
        Actions.unequip(player, item)
    end
end

function Tab:drop(mx, my, payload)
    local player = self:player()
    if not player or not payload or payload.kind ~= "items" then return end
    local target = self:dropTarget(mx, my)
    if not target then return end
    if target.kind == "gear" then
        -- a hotbar slot dropped on another hotbar slot: when its item does not
        -- go in that slot, or Shift is held, the slot moves there in the
        -- hotbar order (it takes that position's key)
        local from, to = payload.from == "gear" and payload.cell, target.cell
        if from and to and from.kind == "attach" and to.kind == "attach" and from.entry and to.entry
                and from.entry.index ~= to.entry.index
                and (isShiftKeyDown() or not Gear.canAttach(self.gear.bar, to.entry, payload.items[1])) then
            local busy = false
            pcall(function() busy = not player:getCharacterActions():isEmpty() end)
            if busy then
                self.screen:notify(T.hotbarBusy, 2, true)
            elseif Gear.moveSlot(self.gear.bar, from.entry.index, to.entry.index) then
                self.gear:refresh(player)
            end
            return
        end
        self:toGear(player, payload.items[1], target.cell)
        return
    end
    if target.bagCell and target.cell and Gear.slotForItem(payload.items[1]) == target.cell.slot then
        -- a bag dropped on the bag slot: wear it (swap), not put it inside
        self:toGear(player, payload.items[1], target.cell)
        return
    end
    if target.container then
        -- never into itself
        local into = {}
        for _, it in ipairs(payload.items) do
            if bagOf(it) ~= target.container then table.insert(into, it) end
        end
        if #into == 0 then return end
        payload = { kind = payload.kind, items = into, from = payload.from, cell = payload.cell, split = payload.split }
        if payload.from == "gear" and payload.cell then
            local it = payload.items[1]
            local okC, here = pcall(function() return it:getContainer() end)
            if (payload.cell.kind == "attach" and target.container == player:getInventory())
                    or (okC and here == target.container) then
                -- onto the container it is already in (your inventory): take it
                -- off, let go of it or detach it, as double-clicking the slot does
                self:fromGear(player, payload.cell, it)
                return
            end
        end
        local items = payload.items
        if (payload.split or isCtrlKeyDown()) and #items > 1 then
            -- Ctrl+drag: how many of them?
            local name = payload.items[1]:getDisplayName()
            self.screen:openAmount(mx, my, {
                title = string.format(T.amountTitle, name),
                max = #items,
                initial = math.max(1, math.floor(#items / 2)),
                onConfirm = function(n)
                    local part = {}
                    for i = 1, math.min(n, #items) do part[i] = items[i] end
                    Actions.move(player, part, target.container)
                end,
            })
            return
        end
        Actions.move(player, items, target.container)
    end
end

function Tab:takeAll()
    local player = self:player()
    if player and self.focusLoot then Actions.takeAll(player, self.focusLoot) end
end

function Tab:storeAll()
    local player = self:player()
    if player and self.focusLoot then Actions.storeAll(player, self.focusLoot) end
end

function Tab:mouseDown(x, y, mods)
    for _, b in pairs(self.buttons) do
        if b:mouseDown(x, y) then return true end
    end
    if self.sortButton:mouseDown(x, y) then return true end
    for _, b in ipairs(self.chipButtons) do
        if b:mouseDown(x, y) then return true end
    end
    local cell = self.gear:cellAt(x, y)
    if cell then
        self.gear.selected = cell.key
        self.gearPress = { cell = cell, x = x, y = y }
        self:onSelect("gear", nil)
        return true
    end
    if self.gear:onModel(x, y) then
        self.turning = { x = x }
        return true
    end
    for _, list in pairs(self.lists) do
        if list:mouseDown(x, y, mods) then return true end
    end
    return false
end

function Tab:mouseMove(x, y)
    local t = self.turning
    if not t then return end
    local dx = x - t.x
    t.x = x
    if dx ~= 0 then self:turnModelBy(dx * TURN_PER_PX) end
end

function Tab:dragCheck(x, y)
    local p = self.gearPress
    if p and math.abs(x - p.x) + math.abs(y - p.y) >= Theme.px(6) then
        self.gearPress = nil
        local item = self.gear:shown(p.cell)
        if item then
            return { kind = "items", items = { item }, from = "gear", cell = p.cell, item = item, label = item:getDisplayName() }
        end
        return nil
    end
    for _, list in pairs(self.lists) do
        local payload = list:dragCheck(x, y)
        if payload then return payload end
    end
    return nil
end

function Tab:mouseUp(x, y)
    self.gearPress = nil
    self.turning = nil
    for _, list in pairs(self.lists) do list:mouseUp() end
end

function Tab:doubleClick(x, y, mods)
    local cell = self.gear:cellAt(x, y)
    if cell then
        local player = self:player()
        if player then self:fromGear(player, cell, self.gear:shown(cell)) end
        return true
    end
    for _, list in pairs(self.lists) do
        if list:doubleClick(x, y, mods) then return true end
    end
    return false
end

-- Hotbar order: move an attachment slot one place left or right (its item
-- and its Hotbar key go with the position).
local function slotOrderEntries(self, cell)
    local out = {}
    if not cell or cell.kind ~= "attach" or not cell.entry then return out end
    local bar = self.gear.bar
    local i = cell.entry.index
    local n = 0
    while bar and bar.availableSlot and bar.availableSlot[n + 1] do n = n + 1 end
    local function busy()
        local player = self:player()
        local b = false
        pcall(function() b = not player:getCharacterActions():isEmpty() end)
        return b
    end
    local function move(to)
        if busy() then self.screen:notify(T.hotbarBusy, 2, true) return end
        if Gear.moveSlot(bar, i, to) then self.gear:refresh(self:player()) end
    end
    if i > 1 then table.insert(out, { label = string.format(T.hotbarMoveLeft, i - 1), run = function() move(i - 1) end }) end
    if i < n then table.insert(out, { label = string.format(T.hotbarMoveRight, i + 1), run = function() move(i + 1) end }) end
    return out
end

function Tab:gearMenu(cell, sx, sy)
    local player = self:player()
    local item = self.gear:shown(cell)
    if not player then return end
    if not item then
        -- an empty hotbar slot can still be moved
        local order = slotOrderEntries(self, cell)
        if #order > 0 then self.screen:openMenu(sx, sy, cell.label or "", order) end
        return
    end
    local list = {}
    for _, e in ipairs(slotOrderEntries(self, cell)) do table.insert(list, e) end
    table.insert(list, { label = cell.kind == "attach" and T.gearDetach or T.invUnequip,
                         run = function() self:fromGear(player, cell, item) end })
    if self.focusLoot then
        table.insert(list, { label = T.invMoveToContainer, run = function() Actions.move(player, { item }, self.focusLoot) end })
    end
    if instanceof(item, "InventoryContainer") then
        table.insert(list, { label = T.gearOpenBag, run = function() self:focusBag(item:getInventory()) end })
    end
    -- several items at one slot: switch which one the slot shows
    if #cell.items > 1 then
        for i, other in ipairs(cell.items) do
            if other ~= item then
                table.insert(list, { label = string.format(T.gearShow, other:getDisplayName()),
                                     run = function() self.gear.pick[cell.key] = i end })
            end
        end
    end
    for _, a in ipairs(Actions.groupMenu(Actions.itemMenu(player, { item }, true), item)) do table.insert(list, a) end
    self.screen:openMenu(sx, sy, item:getDisplayName(), list)
end

-- Shows a worn bag's section in the You list: expanded, scrolled to, flashed.
function Tab:focusBag(container)
    if not container then return end
    self.collapsed[tostring(container)] = nil
    self.bagFlash = { container = container, at = VPUI.Util.now() }
    self:rebuild(false)
    local list = self.lists.player
    for i, row in ipairs(list.rows) do
        if row.kind == "header" and row.container == container then
            local r = list.rects[i]
            if r then list.scroll = r.y; list:clampScroll() end
            break
        end
    end
end

function Tab:rightClick(x, y, sx, sy)
    local cell = self.gear:cellAt(x, y)
    if cell then
        self.gear.selected = cell.key
        self:gearMenu(cell, sx, sy)
        return true
    end
    for _, list in pairs(self.lists) do
        if list:rightClick(x, y, sx, sy) then return true end
    end
    return false
end

function Tab:wheel(x, y, del)
    if self.gear:onModel(x, y) then
        self:turnModelBy(del > 0 and TURN_PER_WHEEL or -TURN_PER_WHEEL)
        return true
    end
    for _, list in pairs(self.lists) do
        if list:wheel(x, y, del) then return true end
    end
    return false
end

-- Quick drop: the selected items you carry, or the one under the mouse.
function Tab:quickDrop()
    local player = self:player()
    if not player then return end
    local items = self:selectedItems("player")
    if #items == 0 then
        local side, row = self:rowUnder(self.screen:getMouseX(), self.screen:getMouseY())
        if (side == "player" or side == "gear") and row and row.items then items = { row.items[1] } end
    end
    local mine = {}
    for _, it in ipairs(items) do
        -- favourites are never dropped (as in vanilla)
        local ok, inside = pcall(function() return it:isInPlayerInventory() and not it:isFavorite() end)
        if ok and inside then table.insert(mine, it) end
    end
    if #mine == 0 then return end
    Actions.move(player, mine, ISInventoryPage.GetFloorContainer(player:getPlayerNum()))
    self.lists.player:clearSelection()
    self.screen:notify(string.format(T.invDropped, mine[1]:getDisplayName() .. (#mine > 1 and ("  x" .. tostring(#mine)) or "")), 2)
end

function Tab:keyPressed(key)
    local player = self:player()
    if not player then return false end
    local dropKey = tonumber(VPUI.Settings.get("quickDropKey")) or 0
    if dropKey > 0 and key == dropKey then
        self:quickDrop()
        return true
    end
    if key == Keyboard.KEY_R then
        self:takeAll()
        return true
    elseif key == Keyboard.KEY_T then
        self:storeAll()
        return true
    elseif key == Keyboard.KEY_F then
        for _, side in ipairs({ "player", "loot" }) do
            local items = self:selectedItems(side)
            if #items > 0 then Actions.toggleFavorite(items) return true end
        end
    end
    return false
end

VPUI.Hub.register({
    id = "inventory",
    label = T.tabInventory,
    order = 10,
    key = function() return getCore():getKey(KeybindId.TOGGLE_INVENTORY) end,
    create = Tab.create,
})
