--
-- Viewpoint UI - quick loot.
--
-- Aiming at a container or a body in reach lists what is in it beside the
-- crosshair, so most looting needs no screen at all:
--   wheel            picks a line
--   tap Interact     takes the picked stack (or runs the picked line)
--   hold Interact    opens the full Viewpoint inventory on it (the Search action)
--   take-all key     takes everything (optional key; also the Take all line)
-- The target's other actions (pick up, disassemble...) follow the items, so
-- nothing the action list offered is lost.
--
-- Which containers count is the game's own answer: the hidden loot page
-- (ISInventoryPage:refreshBackpacks) decides reach and loot rules and fills
-- unexplored containers through the server, as for the Viewpoint inventory.
-- Every move is the game's timed transfer (Inventory/Actions), checked by the
-- server in multiplayer.
--

require "ViewpointUI/Core"
require "ViewpointUI/Settings"
require "ViewpointUI/Text"
require "ViewpointUI/Bridge"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/Inventory/Model"
require "ViewpointUI/Inventory/Actions"

local VPUI = ViewpointUI
VPUI.Interaction = VPUI.Interaction or {}
if VPUI.Interaction.QuickLoot then return end

local QuickLoot = {}
VPUI.Interaction.QuickLoot = QuickLoot

local Log, Settings, Bridge = VPUI.Log, VPUI.Settings, VPUI.Bridge
local T = VPUI.Text
local Theme = VPUI.UI.Theme
local C = Theme.color
local VPElement = VPUI.UI.VPElement
local Model = VPUI.Inventory.Model
local Actions = VPUI.Inventory.Actions
local KIND = Bridge.KIND

local REACH_EVERY_MS = 1000   -- how often reach is asked again (the loot page refresh)
local ROWS_EVERY_MS = 250     -- how often the item lines are read again
local MAX_ROWS = 8            -- lines shown at once; the rest scroll

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------

local VPQuickLoot = VPElement:derive("VPQuickLoot")
VPUI.UI.VPQuickLoot = VPQuickLoot

function VPQuickLoot:new()
    local o = VPElement.new(self, 1, 1)
    o.title = nil
    o.used, o.cap = 0, 0
    o.rows = {}
    o.selected = 1
    o.top = 1
    o.hold = 0
    o.carry = nil
    o.keys = {}
    return o
end

local function selectable(row)
    return row and row.kind ~= "header" and row.kind ~= "sep" and row.kind ~= "empty" and row.enabled ~= false
end

function VPQuickLoot:setContent(title, used, cap, rows, keepKey)
    self.title, self.used, self.cap = title, used, cap
    self.rows = rows
    local pick, first = nil, nil
    for i, r in ipairs(rows) do
        if selectable(r) then
            if keepKey and r.key == keepKey then pick = i end
            if not first and r.kind == "item" then first = i end
        end
    end
    if not first then
        for i, r in ipairs(rows) do if selectable(r) then first = i break end end
    end
    self.selected = pick or first or 1
    self:scrollTo()
    self.dirty = true
end

function VPQuickLoot:setFooter(keys, carry)
    local sig = tostring(carry ~= nil)
    for _, k in ipairs(keys) do sig = sig .. "|" .. k.key .. k.text end
    if sig ~= self.footerSig then
        self.footerSig = sig
        self.dirty = true
    end
    self.keys = keys
    self.carry = carry
end

function VPQuickLoot:current()
    local r = self.rows[self.selected]
    if selectable(r) then return r end
    return nil
end

function VPQuickLoot:move(steps)
    local n = #self.rows
    if n == 0 or steps == 0 then return end
    local dir = steps > 0 and 1 or -1
    for _ = 1, math.abs(steps) do
        local i = self.selected
        for _ = 1, n do
            i = i + dir
            if i > n then i = 1 elseif i < 1 then i = n end
            if selectable(self.rows[i]) then break end
        end
        self.selected = i
    end
    self:scrollTo()
    self.dirty = true
end

function VPQuickLoot:scrollTo()
    local n = #self.rows
    if self.selected < self.top then self.top = self.selected end
    if self.selected > self.top + MAX_ROWS - 1 then self.top = self.selected - MAX_ROWS + 1 end
    self.top = VPUI.Util.clamp(self.top, 1, math.max(1, n - MAX_ROWS + 1))
end

function VPQuickLoot:setHold(fraction)
    self.hold = fraction or 0
end

-- A narrow column: taller than wide, small type, names cut to fit.
local WIDTH = 176      -- inner width (px at 1x)
local MIN_ROWS = 6     -- the list keeps at least this much height


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

local function fit(text, font, maxW)
    text = tostring(text or "")
    if Theme.textWidth(font, text) <= maxW then return text end
    local out = text
    while #out > 0 and Theme.textWidth(font, out .. "..") > maxW do
        out = utf8TrimLast(out)
    end
    return out .. ".."
end

function VPQuickLoot:layout()
    local small = Theme.smallFont()
    local fh = Theme.fontHeight(small)
    local padX, padY = Theme.px(8), Theme.px(7)
    local w = Theme.px(WIDTH)
    local icon = math.max(Theme.px(20), fh + Theme.px(2))
    local rowH = icon + Theme.px(4)
    local sepH = Theme.px(7)
    local headH = fh + Theme.px(4)
    local shown = math.min(#self.rows, MAX_ROWS)
    local h = 0
    for i = self.top, self.top + shown - 1 do
        local r = self.rows[i]
        if r and r.kind == "sep" then h = h + sepH
        elseif r and r.kind == "header" then h = h + headH
        else h = h + rowH end
    end
    h = math.max(h, rowH * MIN_ROWS)
    if #self.rows > MAX_ROWS then h = h + fh end   -- "n more"
    local titleH = fh + Theme.px(8)
    local keyH = fh + Theme.px(5)
    -- key hints wrap to the width
    local lines, kx = 1, 0
    for _, k in ipairs(self.keys) do
        local need = VPElement.keycapWidth(k.key, small) + Theme.px(4) + Theme.textWidth(small, k.text)
        if kx > 0 and kx + need > w then lines = lines + 1; kx = 0 end
        kx = kx + need + Theme.px(10)
    end
    local footH = Theme.px(7) + keyH * lines
    local carryH = self.carry and (fh + Theme.px(8)) or 0
    self.box = { w = w + padX * 2, inner = w, padX = padX, padY = padY, icon = icon, rowH = rowH, sepH = sepH,
                 headH = headH, titleH = titleH, listH = h, keyH = keyH, footH = footH, carryH = carryH, fh = fh }
    self.box.h = padY * 2 + titleH + h + footH + carryH
    local cx, cy = Theme.screenCenter()
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local x = math.min(cx + Theme.px(40), sw - self.box.w - Theme.px(8))
    local y = VPUI.Util.clamp(cy - math.floor(self.box.h / 2), Theme.px(8), math.max(Theme.px(8), sh - self.box.h - Theme.px(8)))
    self:place(x, y, self.box.w, self.box.h)
    self.dirty = false
end

local function fmtKg(v) return string.format("%.1f", v or 0) end

function VPQuickLoot:render()
    if self.dirty then self:layout() end
    local b = self.box
    local small = Theme.smallFont()
    local fh = b.fh
    self:panel(0, 0, b.w, b.h)
    local x0, y = b.padX, b.padY
    -- title, fill and the hold-to-open progress
    local capText = (self.cap and self.cap > 0) and (fmtKg(self.used) .. "/" .. tostring(math.floor(self.cap + 0.5))) or nil
    local capW = capText and (Theme.textWidth(small, capText) + Theme.px(6)) or 0
    if self.title then self:text(fit(self.title, small, b.inner - capW), x0, y, C.text, small) end
    if capText then
        self:textRight(capText, b.w - b.padX, y, C.off, small)
        self:bar(x0, y + fh + Theme.px(2), b.inner, Theme.px(2), self.used / self.cap, C.accent)
    end
    if self.hold > 0 then
        self:bar(x0, y + fh + Theme.px(2), b.inner, Theme.px(2), self.hold, C.text)
    end
    y = y + b.titleH
    local listEnd = y + b.listH
    -- lines
    local last = math.min(#self.rows, self.top + MAX_ROWS - 1)
    for i = self.top, last do
        local r = self.rows[i]
        if r.kind == "sep" then
            self:fill(x0, y + math.floor(b.sepH / 2), b.inner, 1, C.edge, 1.5)
            y = y + b.sepH
        elseif r.kind == "header" then
            self:text(fit(r.label, small, b.inner), x0, y + Theme.px(2), C.off, small)
            y = y + b.headH
        else
            local sel = i == self.selected and selectable(r)
            if sel then
                self:fill(Theme.px(2), y, b.w - Theme.px(4), b.rowH - Theme.px(1), C.panelHi)
                self:fill(Theme.px(2), y, Theme.px(2), b.rowH - Theme.px(1), C.accent)
            end
            local tx = x0 + Theme.px(2)
            if r.item then
                local iy = y + math.floor((b.rowH - b.icon) / 2)
                pcall(self.drawItemIcon, self, r.item, tx, iy, 1, b.icon, b.icon)
                tx = tx + b.icon + Theme.px(5)
            end
            local enabled = r.enabled ~= false
            local c = not enabled and C.off or (sel and C.text or C.dim)
            if r.kind == "takeAll" or r.kind == "action" then c = not enabled and C.off or (sel and C.accent or C.dim) end
            local room = b.w - b.padX - tx
            local countW = r.count and (Theme.textWidth(small, r.count) + Theme.px(4)) or 0
            local ty = y + math.floor((b.rowH - fh) / 2)
            local name = fit(r.label, small, room - countW)
            self:text(name, tx, ty, c, small)
            if r.count then
                self:text(r.count, tx + Theme.textWidth(small, name) + Theme.px(4), ty, C.accent, small)
            end
            y = y + b.rowH
        end
    end
    -- what is hidden above / below
    local below = #self.rows - last
    if below > 0 then
        self:textRight(string.format(T.qlMore, tostring(below)), b.w - b.padX, listEnd - fh, C.off, small)
    end
    if self.top > 1 then
        self:textRight("^", b.w - b.padX, b.padY, C.off, small)
    end
    -- the picked line's weight and condition, under the list
    y = listEnd + Theme.px(2)
    self:fill(x0, y, b.inner, 1, C.edge, 1.5)
    y = y + Theme.px(5)
    local kx = x0
    for _, k in ipairs(self.keys) do
        local kw = VPElement.keycapWidth(k.key, small)
        local need = kw + Theme.px(4) + Theme.textWidth(small, k.text)
        if kx > x0 and kx + need > x0 + b.inner then kx = x0; y = y + b.keyH end
        self:keycap(k.key, kx, y, small)
        self:text(k.text, kx + kw + Theme.px(4), y + Theme.px(1), k.main and C.text or C.dim, small)
        kx = kx + need + Theme.px(10)
    end
    -- carry weight, and what it becomes with the picked line
    if self.carry then
        local cy = b.h - b.padY - fh
        local cw = self.carry
        local label = fmtKg(cw.after and cw.after > cw.now + 0.001 and cw.after or cw.now) .. "/" .. tostring(cw.max)
        local lw = Theme.textWidth(small, label)
        local over = (cw.after or cw.now) > cw.max
        self:textRight(label, b.w - b.padX, cy, over and C.danger or C.dim, small)
        local bx = x0
        local bw = b.inner - lw - Theme.px(8)
        if bw > Theme.px(20) then
            local by = cy + math.floor(fh / 2) - 1
            self:fill(bx, by, bw, Theme.px(3), C.track)
            if cw.after and cw.after > cw.now then
                self:fill(bx, by, math.max(1, math.floor(bw * math.min(1, cw.after / cw.max))), Theme.px(3), over and C.danger or C.accent, 0.6)
            end
            self:fill(bx, by, math.max(1, math.floor(bw * math.min(1, cw.now / cw.max))), Theme.px(3), cw.now > cw.max and C.danger or C.good)
        end
    end
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local panel = nil
local shown = false
local reach = { key = nil, at = 0, list = {} }      -- target key -> reachable page entries
local rowsAt, rowsKey, rowsSig = 0, nil, nil
local holdStart, holdFired = nil, false
local takeAllWas = false

local function getPanel()
    if not panel then panel = VPQuickLoot:new() end
    return panel
end

function QuickLoot.shown()
    return shown
end

function QuickLoot.hide()
    if shown and panel then panel:display(false) end
    shown = false
    holdStart, holdFired = nil, false
end

local function targetContainers(target)
    local list = {}
    for i = 1, target.containers or 0 do
        local c = Bridge.call("targetContainer", nil, i)
        if c then table.insert(list, c) end
    end
    return list
end

-- The target's containers the game lets the player loot from here, as loot
-- page entries ({ container, title, capacity }). Asked again once a second.
local function reachable(target, player, now)
    if reach.key == target.key and now - reach.at < REACH_EVERY_MS then return reach.list end
    local wanted = {}
    for _, c in ipairs(targetContainers(target)) do wanted[c] = true end
    local list = {}
    -- the page is rebuilt (refreshBackpacks: reach, loot rules, filling
    -- unexplored containers) for a new target, while it is still out of reach,
    -- and every few seconds; otherwise its last answer is read again
    local refresh = reach.key ~= target.key or #reach.list == 0 or now - (reach.refreshedAt or 0) > 3000
    if refresh then reach.refreshedAt = now end
    local ok, entries = pcall(Model.lootContainers, player, refresh)
    if ok then
        for _, e in ipairs(entries) do
            if wanted[e.container] and not e.floor then table.insert(list, e) end
        end
    else
        Log.once(Log.WARN, "ql-reach", "quick loot: reading the loot containers failed: " .. tostring(entries))
    end
    reach.key, reach.at, reach.list = target.key, now, list
    return list
end

local function searchAction(resolved)
    for _, a in ipairs(resolved and resolved.actions or {}) do
        if a.provider == "vpui.loot" then return a end
    end
    return nil
end

-- Does quick loot take this target? Returns the reachable entries or nil.
function QuickLoot.wants(target, player, resolved, now)
    if Settings.get("quickLoot") ~= true or not target or target.locked then return nil end
    local k = target.kind
    if k ~= KIND.OBJECT and k ~= KIND.BODY and k ~= KIND.THING then return nil end
    if (target.containers or 0) <= 0 then return nil end
    local search = searchAction(resolved)
    if not search or not search.enabled then return nil end
    local list = reachable(target, player, now)
    if #list == 0 then return nil end
    return list
end

local function detailOf(item)
    local ok, text = pcall(function()
        if instanceof(item, "DrainableComboItem") then
            return string.format(T.qlLeft, tostring(math.floor(item:getCurrentUsesFloat() * 100 + 0.5)))
        end
        if instanceof(item, "HandWeapon") or instanceof(item, "Clothing") then
            local max = item:getConditionMax()
            if max and max > 0 then
                return string.format(T.qlCondition, tostring(math.floor(item:getCondition() / max * 100 + 0.5)))
            end
        end
        return nil
    end)
    return ok and text or nil
end

local function buildRows(entries, player, resolved)
    local rows, any = {}, false
    local multi = #entries > 1
    for _, e in ipairs(entries) do
        if multi then table.insert(rows, { kind = "header", label = e.title or "" }) end
        local groups = Model.groups(e.container, player, false)
        if #groups == 0 and multi then
            table.insert(rows, { kind = "empty", label = T.qlEmpty })
        end
        for _, g in ipairs(groups) do
            any = true
            local n = #g.items
            table.insert(rows, {
                kind = "item", key = "item:" .. tostring(g.key), group = g, item = g.first,
                label = g.first:getDisplayName(), count = n > 1 and ("x" .. tostring(n)) or nil,
                weight = g.weight, detail = n == 1 and detailOf(g.first) or nil, container = e.container,
            })
        end
    end
    if any then
        table.insert(rows, 1, { kind = "takeAll", key = "takeAll", label = T.qlTakeAll })
    elseif not multi then
        table.insert(rows, { kind = "empty", label = T.qlEmpty })
    end
    -- the target's other actions after the items
    local others = {}
    for _, a in ipairs(resolved and resolved.actions or {}) do
        if a.provider ~= "vpui.loot" then table.insert(others, a) end
    end
    if #others > 0 then
        table.insert(rows, { kind = "sep" })
        for _, a in ipairs(others) do
            table.insert(rows, { kind = "action", key = "action:" .. tostring(a.label), action = a,
                                 label = a.label, enabled = a.enabled })
        end
    end
    return rows
end

local function signature(entries, resolved)
    local parts = {}
    for _, e in ipairs(entries) do
        local items = e.container:getItems()
        table.insert(parts, tostring(e.container) .. ":" .. tostring(items:size()) .. ":" .. string.format("%.2f", e.container:getCapacityWeight()))
    end
    for _, a in ipairs(resolved and resolved.actions or {}) do
        table.insert(parts, tostring(a.label) .. tostring(a.enabled))
    end
    return table.concat(parts, "|")
end

local function takeRow(row, player, entries, toast)
    if row.kind == "takeAll" then
        for _, e in ipairs(entries) do Actions.takeAll(player, e.container) end
        toast(string.format(T.qlTook, T.qlTakeAll))
        return true
    end
    if row.kind == "item" then
        local first = row.group.first
        if isForceDropHeavyItem and isForceDropHeavyItem(first) then
            pcall(ISInventoryPaneContextMenu.equipHeavyItem, player, first)
        else
            Actions.move(player, row.group.items, player:getInventory())
        end
        toast(string.format(T.qlTook, row.label .. (row.count and (" " .. row.count) or "")))
        return true
    end
    return false
end

local function takeAllKeyDown()
    local key = tonumber(Settings.get("quickLootTakeAllKey")) or 0
    return key > 0 and isKeyDown(key) == true, key
end

-- One tick while quick loot has the target. ctx: { input, runAction(action),
-- toast(message), interactLabel }
function QuickLoot.tick(target, player, resolved, entries, now, ctx)
    local p = getPanel()
    local Input = ctx.input
    -- lines
    local sig = signature(entries, resolved)
    if rowsKey ~= target.key or sig ~= rowsSig or now - rowsAt > ROWS_EVERY_MS * 8 then
        local keep = nil
        if rowsKey == target.key then
            local cur = p:current()
            keep = cur and cur.key
        end
        local title = (resolved and resolved.title) or (entries[1] and entries[1].title) or ""
        local used, cap = 0, 0
        for _, e in ipairs(entries) do
            used = used + e.container:getCapacityWeight()
            cap = cap + (tonumber(e.capacity) or 0)
        end
        p:setContent(title, used, cap, buildRows(entries, player, resolved), keep)
        if rowsKey ~= target.key then Bridge.takeWheel() end   -- notches from before
        rowsKey, rowsSig, rowsAt = target.key, sig, now
    end
    -- wheel
    local wheel = tonumber(Bridge.takeWheel()) or 0
    if wheel ~= 0 then p:move(wheel > 0 and -math.min(wheel, 5) or math.min(-wheel, 5)) end
    -- keys
    local ilabel = ctx.interactLabel
    local keys = {
        { key = ilabel, text = T.qlTake, main = true },
        { key = string.format(T.holdPrefix, ilabel), text = T.qlOpen },
    }
    local down, takeKey = takeAllKeyDown()
    if takeKey > 0 then table.insert(keys, { key = getKeyName(takeKey) or "?", text = T.qlTakeAll }) end
    -- carry weight with the picked line added
    local cur = p:current()
    local carry = { now = player:getInventoryWeight(), max = player:getMaxWeight() }
    if cur and cur.kind == "item" then carry.after = carry.now + (cur.weight or 0) end
    p:setFooter(keys, carry)
    -- take-all key
    if down and not takeAllWas then
        takeRow({ kind = "takeAll" }, player, entries, ctx.toast)
    end
    takeAllWas = down
    -- tap: take / run; hold: the full inventory
    local holdMs = (tonumber(Settings.get("holdTime")) or 0.35) * 1000
    if Input.pressed("interact") then holdStart, holdFired = now, false end
    if holdStart and Input.down("interact") and not holdFired then
        local held = now - holdStart
        if held >= holdMs then
            holdFired = true
            p:setHold(0)
            local search = searchAction(resolved)
            if search then ctx.runAction(search) end
        else
            p:setHold(held / holdMs)
        end
    elseif holdStart and not Input.down("interact") then
        if not holdFired then
            local row = p:current()
            if row then
                if row.kind == "action" then
                    if row.action.enabled then ctx.runAction(row.action) end
                else
                    takeRow(row, player, entries, ctx.toast)
                end
                rowsAt = 0   -- read the lines again soon
            end
        end
        holdStart, holdFired = nil, false
        p:setHold(0)
    else
        p:setHold(0)
    end
    p:display(true)
    shown = true
end

-- Forget cached reach (containers moved, a new target).
function QuickLoot.reset()
    reach = { key = nil, at = 0, list = {} }
    rowsKey, rowsSig = nil, nil
    QuickLoot.hide()
end

return QuickLoot
