--
-- Viewpoint UI - status readout (HUD foundation).
--
-- Adaptive: nothing shows while the character is fine. A need appears, bottom
-- left, once the game's own moodle for it reaches level 2, with the game's own
-- moodle name and level (1-4 pips) - no thresholds or values of our own, and
-- nothing the vanilla moodles would not already reveal.
-- Full mode (the vanilla moodles column is hidden): every active moodle from
-- level 1, good ones (Moodles.GoodMoodleType = 1) in the "good" colour.
-- Read twice a second, not every frame.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Widgets"

local VPUI = ViewpointUI
VPUI.HUD = VPUI.HUD or {}
if VPUI.HUD.Status then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local VPElement = VPUI.UI.VPElement

local StatusHUD = VPElement:derive("VPStatusHUD")
VPUI.HUD.Status = StatusHUD

-- Order shown, most urgent first. Names come from the game at runtime.
StatusHUD.watched = {
    "BLEEDING", "INJURED", "PAIN", "THIRST", "HUNGRY", "ENDURANCE", "TIRED",
    "HYPOTHERMIA", "HYPERTHERMIA", "SICK", "PANIC", "HEAVY_LOAD", "DRUNK",
}

-- The rest of MoodleType (zombie.scripting.objects.MoodleType), shown in full mode.
StatusHUD.extra = {
    "STRESS", "UNHAPPY", "BORED", "WET", "HAS_A_COLD", "WINDCHILL", "UNCOMFORTABLE",
    "NOXIOUS_SMELL", "ANGRY", "CANT_SPRINT", "ZOMBIE", "FOOD_EATEN",
}

local REFRESH_MS = 500
local MIN_LEVEL = 2
local GOOD = 1

-- Moodle types resolved once; a name missing from this game version is skipped.
local types = nil

local function resolveTypes()
    types = {}
    local names = {}
    for _, name in ipairs(StatusHUD.watched) do table.insert(names, { name = name }) end
    for _, name in ipairs(StatusHUD.extra) do table.insert(names, { name = name, extra = true }) end
    for _, n in ipairs(names) do
        local name = n.name
        local ok, mt = pcall(function() return MoodleType[name] end)
        if ok and mt ~= nil then
            table.insert(types, { name = name, type = mt, extra = n.extra })
        else
            VPUI.Log.once(VPUI.Log.DEBUG, "moodle:" .. name, "moodle type " .. name .. " not in this game version")
        end
    end
end

function StatusHUD:new()
    local o = VPElement.new(self, 1, 1)
    o.rows = {}
    o.nextRead = 0
    o.signature = ""
    o.full = false
    return o
end

function StatusHUD:setFull(on)
    on = on == true
    if on ~= self.full then
        self.full = on
        self.nextRead = 0
    end
end

function StatusHUD:read(player, now)
    if now < self.nextRead then return end
    self.nextRead = now + REFRESH_MS
    local moodles = player:getMoodles()
    if not moodles then return end
    local rows, sig = {}, ""
    if not types then resolveTypes() end
    local minLevel = self.full and 1 or MIN_LEVEL
    for _, entry in ipairs(types) do
        if self.full or not entry.extra then
            local level = moodles:getMoodleLevel(entry.type)
            if level >= minLevel then
                local good = false
                if self.full then
                    local ok, gbn = pcall(function() return moodles:getGoodBadNeutral(entry.type) end)
                    good = ok and gbn == GOOD
                end
                table.insert(rows, { label = moodles:getMoodleDisplayString(entry.type), level = level, good = good })
                sig = sig .. entry.name .. tostring(level) .. ";"
            end
        end
    end
    if sig ~= self.signature then
        self.signature = sig
        self.rows = rows
        self.dirty = true
    end
end

function StatusHUD:hasRows()
    return #self.rows > 0
end

function StatusHUD:layout()
    local small = Theme.smallFont()
    local rowH = Theme.fontHeight(small) + Theme.px(4)
    local pip = Theme.px(5)
    local w = 0
    for _, row in ipairs(self.rows) do
        w = math.max(w, Theme.textWidth(small, row.label))
    end
    w = w + Theme.px(10) + 4 * (pip + Theme.px(2)) + Theme.px(14)
    local h = #self.rows * rowH + Theme.px(10)
    local sh = getCore():getScreenHeight()
    self:place(Theme.px(18), sh - h - Theme.px(96), w, h)
    self.rowH, self.pip = rowH, pip
    self.dirty = false
end

function StatusHUD:render()
    if self.dirty then self:layout() end
    local small = Theme.smallFont()
    self:panel(0, 0, self.width, self.height)
    local y = Theme.px(5)
    local pipX = self.width - Theme.px(7) - 4 * (self.pip + Theme.px(2))
    for _, row in ipairs(self.rows) do
        local c = row.good and (C.good or C.text) or (row.level >= 4 and C.danger or (row.level >= 3 and C.accent or C.text))
        self:text(row.label, Theme.px(7), y, c, small)
        local py = y + math.floor((self.rowH - self.pip) / 2) - Theme.px(1)
        for i = 1, 4 do
            local x = pipX + (i - 1) * (self.pip + Theme.px(2))
            if i <= row.level then
                self:fill(x, py, self.pip, self.pip, c, 0.9)
            else
                self:fill(x, py, self.pip, self.pip, C.track)
            end
        end
        y = y + self.rowH
    end
end
