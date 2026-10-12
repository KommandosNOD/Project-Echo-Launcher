--
-- Viewpoint UI - hotbar.
--
-- The game's hotbar (ISHotbar) stays the authority: its slots come from what
-- the character wears (belt, holster, back...), its keys (Hotbar 1..8) equip,
-- and attaching/detaching goes through its timed actions. This widget only
-- draws it in the Viewpoint style, bottom centre, with the bound key, the
-- attached item and which one is in hand. While it is on, the vanilla bar's
-- drawing is skipped (its update and key handling keep running).
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Widgets"

local VPUI = ViewpointUI
VPUI.HUD = VPUI.HUD or {}
if VPUI.HUD.Hotbar then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local VPElement = VPUI.UI.VPElement

local Hotbar = VPElement:derive("VPHotbar")
VPUI.HUD.Hotbar = Hotbar

local replacing = false

function Hotbar.replacing()
    return replacing
end

-- The vanilla bar we hid, to show again when replacing ends.
local hiddenBar = nil

-- Called every tick. While replacing, the vanilla bar (getPlayerHotbar(0)) is
-- set invisible: ISHotbar has no children and its key handling and update()
-- never check visibility (the game itself hides it this way for split-screen
-- and controllers, see ISHotbar:render), so slots and keys keep working.
-- Re-applied every tick because ISHotbar:update can show it again.
function Hotbar.setReplacing(on)
    replacing = on == true
    local bar = getPlayerHotbar and getPlayerHotbar(0)
    if replacing then
        if bar and bar.getIsVisible and bar:getIsVisible() then
            bar:setVisible(false)
            hiddenBar = bar
        end
    elseif hiddenBar and not VPUI.Util.uiHidden() then
        pcall(function() hiddenBar:setVisible(true) end)
        hiddenBar = nil
    end
end

-- Also skip the vanilla bar's drawing (background and slots) while ours is
-- shown, for any frame drawn before it is hidden. Installed once, after the
-- game's hotbar file has loaded.
local function wrapVanilla()
    if not ISHotbar or ISHotbar.viewpointWrapped then return end
    local render = ISHotbar.render
    ISHotbar.render = function(self)
        if replacing and self.playerNum == 0 then return end
        return render(self)
    end
    local prerender = ISHotbar.prerender
    ISHotbar.prerender = function(self)
        if replacing and self.playerNum == 0 then return end
        if prerender then return prerender(self) end
    end
    ISHotbar.viewpointWrapped = true
end
Events.OnGameStart.Add(wrapVanilla)

function Hotbar:new()
    local o = VPElement.new(self, 1, 1)
    o.slots = {}
    o.signature = ""
    o.nextRead = 0
    return o
end

function Hotbar:read(player, now)
    if now < self.nextRead then return end
    self.nextRead = now + 200
    local bar = getPlayerHotbar(player:getPlayerNum())
    local slots, sig = {}, ""
    if bar and bar.availableSlot then
        for i, slot in pairs(bar.availableSlot) do
            local item = bar.attachedItems and bar.attachedItems[i] or nil
            local key = bar:getKeyForIndex(i)
            local inHand = item ~= nil and (player:getPrimaryHandItem() == item or player:getSecondaryHandItem() == item)
            slots[i] = { item = item, key = key, inHand = inHand,
                         name = getTextOrNull("IGUI_HotbarAttachment_" .. tostring(slot.slotType)) or slot.name }
            sig = sig .. tostring(i) .. tostring(item) .. tostring(inHand) .. tostring(key) .. ";"
        end
    end
    if sig ~= self.signature then
        self.signature = sig
        self.slots = slots
        self.dirty = true
    end
end

function Hotbar:count()
    local n = 0
    for _ in pairs(self.slots) do n = n + 1 end
    return n
end

function Hotbar:layout()
    local size = Theme.px(44)
    local gap = Theme.px(4)
    local n = self:count()
    local w = n * size + math.max(0, n - 1) * gap
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    self:place(math.floor((sw - w) / 2), sh - size - Theme.px(14), math.max(w, 1), size)
    self.size, self.gap = size, gap
    self.dirty = false
end

function Hotbar:render()
    if self:count() == 0 then return end
    if self.dirty then self:layout() end
    local small = Theme.smallFont()
    local x = 0
    local i = 1
    while self.slots[i] do
        local s = self.slots[i]
        self:fill(x, 0, self.size, self.size, s.inHand and C.panelHi or C.panel)
        local edge = s.inHand and C.accent or C.edge
        self:drawRectBorder(x, 0, self.size, self.size, s.inHand and 0.9 or C.edge.a, edge.r, edge.g, edge.b)
        if s.item then
            local icon = self.size - Theme.px(14)
            self:drawItemIcon(s.item, x + Theme.px(7), Theme.px(8), 1, icon, icon)
        end
        local keyText = (s.key and s.key > 0) and getKeyName(s.key) or tostring(i)
        self:text(keyText, x + Theme.px(3), Theme.px(1), s.inHand and C.accent or C.dim, small)
        x = x + self.size + self.gap
        i = i + 1
    end
end
