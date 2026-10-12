--
-- Viewpoint UI - skills and character tabs.
--
-- Skills: every perk the game registers (PerkFactory.PerkList, so modded skills
-- appear), grouped under its parent category like the vanilla skills panel,
-- with level, progress to the next level (ISSkillProgressBar's own formula),
-- XP multiplier and the starting boost colour.
--
-- Character: profession, traits (CharacterTraitDefinition labels and
-- descriptions), per body part bite/scratch protection from worn clothing
-- (getBodyPartClothingDefense, as ISCharacterProtection), and body temperature.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Skills then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local T = VPUI.Text
local Log = VPUI.Log

---------------------------------------------------------------------------
-- Skills
---------------------------------------------------------------------------

local Skills = {}
Skills.__index = Skills
VPUI.Screens.Skills = Skills

local BOOST_COLOR = {
    [0] = { r = 0.54, g = 0.54, b = 0.54 },
    [1] = { r = 0.8, g = 0.8, b = 0.8 },
    [2] = { r = 1, g = 1, b = 1 },
    [3] = { r = 1, g = 0.83, b = 0 },
}

local function previousXp(perk, level)
    -- ISSkillProgressBar.getPreviousXpLvl
    if level == 0 then return 0 end
    local steps = {
        function() return perk:getXp1() end, function() return perk:getXp2() end, function() return perk:getXp3() end,
        function() return perk:getXp4() end, function() return perk:getXp5() end, function() return perk:getXp6() end,
        function() return perk:getXp7() end, function() return perk:getXp8() end, function() return perk:getXp9() end,
        function() return perk:getXp10() end,
    }
    local sum = 0
    for i = 1, math.min(level, 10) do sum = sum + steps[i]() end
    return sum
end

function Skills.read(player)
    local groups, order = {}, {}
    local list = PerkFactory.PerkList
    for i = 0, list:size() - 1 do
        local perk = list:get(i)
        local parent = perk:getParent()
        if parent ~= Perks.None then
            local key = tostring(parent)
            if not groups[key] then
                local parentPerk = PerkFactory.getPerk(parent)
                groups[key] = { name = parentPerk and parentPerk:getName() or key, passive = parentPerk and parentPerk:isPassiv(), perks = {} }
                table.insert(order, groups[key])
            end
            table.insert(groups[key].perks, perk)
        end
    end
    table.sort(order, function(a, b)
        if a.passive ~= b.passive then return a.passive == true end
        return a.name < b.name
    end)
    local rows = {}
    local xp = player:getXp()
    for _, g in ipairs(order) do
        table.insert(rows, { kind = "header", key = "h:" .. g.name, name = g.name })
        table.sort(g.perks, function(a, b) return a:getName() < b:getName() end)
        for _, perk in ipairs(g.perks) do
            local level = player:getPerkLevel(perk)
            local fraction = 1
            local xpHave, xpNeed = nil, nil
            if level < 10 then
                local need = perk:getXpForLevel(level + 1)
                local have = xp:getXP(perk:getType()) - previousXp(perk, level)
                fraction = (need and need > 0) and VPUI.Util.clamp(have / need, 0, 1) or 0
                xpHave, xpNeed = math.max(0, have or 0), need
            end
            table.insert(rows, { kind = "perk", key = perk:getId(), perk = perk, name = perk:getName(), level = level,
                                 fraction = fraction, xpHave = xpHave, xpNeed = xpNeed, multiplier = xp:getMultiplier(perk:getType()),
                                 boost = xp:getPerkBoost(perk:getType()) })
        end
    end
    return rows
end

function Skills.create(screen)
    local self = setmetatable({}, Skills)
    self.nextRead = 0
    self.list = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(12) end,
        drawRow = function(ui, row, x, y, w, h)
            if row.kind == "header" then
                ui:drawText(row.name, x + Theme.px(4), y + Theme.px(6), C.accent.r, C.accent.g, C.accent.b, 1, Theme.font())
                ui:drawRect(x, y + h - 1, w, 1, 0.1, 1, 1, 1)
                return
            end
            local c = BOOST_COLOR[row.boost or 0] or C.text
            ui:drawText(row.name, x + Theme.px(16), y + Theme.px(5), c.r, c.g, c.b, 1, Theme.font())
            local pip = Theme.px(10)
            local px0 = x + math.floor(w * 0.42)
            for i = 1, 10 do
                local filled = i <= row.level
                local nextOne = i == row.level + 1
                local bx = px0 + (i - 1) * (pip + Theme.px(3))
                local by = y + math.floor((h - pip) / 2)
                ui:drawRect(bx, by, pip, pip, filled and 0.95 or C.track.a, filled and C.accent.r or C.track.r, filled and C.accent.g or C.track.g, filled and C.accent.b or C.track.b)
                if nextOne and row.fraction > 0 then
                    ui:drawRect(bx, by + pip - Theme.px(3), math.max(1, math.floor(pip * row.fraction)), Theme.px(3), 1, C.text.r, C.text.g, C.text.b)
                end
            end
            -- progress to the next level as a real bar with the numbers
            local small = Theme.smallFont()
            local barX = px0 + 10 * (pip + Theme.px(3)) + Theme.px(12)
            local multW = (row.multiplier and row.multiplier > 0) and Theme.px(52) or 0
            local barW = (x + w - Theme.px(8) - multW) - barX
            if barW > Theme.px(60) then
                local by = y + math.floor(h / 2) + Theme.px(2)
                ui:drawRect(barX, by, barW, Theme.px(4), C.track.a, C.track.r, C.track.g, C.track.b)
                if row.level >= 10 then
                    ui:drawRect(barX, by, barW, Theme.px(4), 0.9, C.accent.r, C.accent.g, C.accent.b)
                    ui:drawText(getText("UI_ProjectEcho_VPUI_Screens_CharacterTabs_RU_001"), barX, by - Theme.fontHeight(small) - Theme.px(1), C.accent.r, C.accent.g, C.accent.b, 1, small)
                else
                    if row.fraction > 0 then
                        ui:drawRect(barX, by, math.max(1, math.floor(barW * row.fraction)), Theme.px(4), 1, C.good.r, C.good.g, C.good.b)
                    end
                    local label = string.format("%d%%", math.floor(row.fraction * 100))
                    if row.xpNeed and row.xpNeed > 0 then
                        label = label .. string.format("   %s / %s xp", tostring(math.floor((row.xpHave or 0) * 10 + 0.5) / 10), tostring(math.floor(row.xpNeed)))
                    end
                    ui:drawText(label, barX, by - Theme.fontHeight(small) - Theme.px(1), C.dim.r, C.dim.g, C.dim.b, 1, small)
                end
            end
            if row.multiplier and row.multiplier > 0 then
                ui:drawTextRight(string.format("x%.2f", row.multiplier), x + w - Theme.px(8), y + Theme.px(5), C.good.r, C.good.g, C.good.b, 1, Theme.smallFont())
            end
        end,
    })
    return self
end

function Skills:open() self.nextRead = 0 end

function Skills:update(now)
    if now < self.nextRead then return end
    self.nextRead = now + 1000
    local player = VPUI.Util.player()
    if not player then return end
    local ok, rows = pcall(Skills.read, player)
    if ok then self.list:setRows(rows) else Log.once(Log.ERROR, "skills", "reading skills failed: " .. tostring(rows)) end
end

function Skills:layout(x, y, w, h) self.list:layout(x, y, math.min(w, Theme.px(760)), h) end
function Skills:render(ui, mx, my) self.list:draw(ui, mx, my) end
function Skills:wheel(x, y, del) return self.list:wheel(x, y, del) end

VPUI.Hub.register({
    id = "skills",
    label = T.tabSkills,
    order = 50,
    key = function() return getCore():getKey(KeybindId.TOGGLE_SKILL_PANEL) end,
    create = Skills.create,
})

---------------------------------------------------------------------------
-- Character
---------------------------------------------------------------------------

local Character = {}
Character.__index = Character
VPUI.Screens.Character = Character

-- Trait descriptions are the game's rich text (ISRichTextPanel markup:
-- <INDENT:n>, <SETX:n>, <RGB:r,g,b>, <GHC>/<BHC> good/bad highlight, <LINE>,
-- <BR>, newlines). They are turned into plain, coloured, wrapped lines here;
-- drawn raw they showed the tags and ran over each other.
local function richLines(text, width, font)
    local out = {}
    if not text or text == "" then return out end
    text = string.gsub(text, "<LINE>", "\n")
    text = string.gsub(text, "<BR>", "\n")
    local tm = getTextManager()
    local function measure(str) return tm:MeasureStringX(font, str) end
    for raw in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local color, indent, firstX = nil, 0, nil
        for tag in string.gmatch(raw, "<([^>]+)>") do
            local name, arg = string.match(tag, "^([A-Z]+):?(.*)$")
            if name == "RGB" then
                local r, g, b = string.match(arg, "([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)")
                if r then color = { r = tonumber(r), g = tonumber(g), b = tonumber(b) } end
            elseif name == "GHC" then color = C.good
            elseif name == "BHC" then color = C.danger
            elseif name == "INDENT" then indent = tonumber(arg) or 0
            elseif name == "SETX" then firstX = tonumber(arg)
            end
        end
        local plain = string.gsub(raw, "<[^>]*>", "")
        plain = string.gsub(plain, "^%s+", "")
        plain = string.gsub(plain, "%s+$", "")
        if plain ~= "" then
            local x0 = firstX or indent
            -- word wrap; continuation lines hang at the indent
            local line, x = "", x0
            for word in string.gmatch(plain, "%S+") do
                local try = line == "" and word or (line .. " " .. word)
                if line ~= "" and x + measure(try) > width then
                    table.insert(out, { text = line, x = x, color = color })
                    line, x = word, indent
                else
                    line = try
                end
            end
            if line ~= "" then table.insert(out, { text = line, x = x, color = color }) end
        end
    end
    return out
end
Character.richLines = richLines

function Character.read(player)
    local info = {}
    -- profession
    pcall(function()
        local def = CharacterProfessionDefinition.getCharacterProfessionDefinition(player:getDescriptor():getCharacterProfession())
        info.profession = def and def:getUIName() or nil
    end)
    info.name = player:getDisplayName()
    -- traits
    info.traits = {}
    pcall(function()
        local traits = player:getCharacterTraits():getKnownTraits()
        for i = 0, traits:size() - 1 do
            local def = CharacterTraitDefinition.getCharacterTraitDefinition(traits:get(i))
            if def then table.insert(info.traits, { label = def:getLabel(), description = def:getDescription(), cost = def:getCost() }) end
        end
    end)
    -- protection per body part
    info.protection = {}
    pcall(function()
        for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
            local t = BodyPartType.FromIndex(i)
            local bite = math.floor(player:getBodyPartClothingDefense(i, true, false) + 0.5)
            local scratch = math.floor(player:getBodyPartClothingDefense(i, false, false) + 0.5)
            table.insert(info.protection, { name = BodyPartType.getDisplayName(t), bite = bite, scratch = scratch })
        end
    end)
    -- temperature
    pcall(function()
        local thermo = player:getBodyDamage():getThermoregulator()
        if thermo then info.core = thermo:getCoreTemperature() end
    end)
    return info
end

function Character.create(screen)
    local self = setmetatable({}, Character)
    self.nextRead = 0
    -- one row per line: a trait's name, then its wrapped description lines
    self.traitList = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(4) end,
        drawRow = function(ui, row, x, y, w, h)
            if row.title then
                local c = (row.cost or 0) < 0 and C.danger or C.good
                ui:drawText(row.text, x + Theme.px(8), y + Theme.px(2), c.r, c.g, c.b, 1, Theme.font())
            elseif row.text then
                local c = row.color or C.dim
                ui:drawText(row.text, x + Theme.px(16) + (row.x or 0), y + Theme.px(3), c.r, c.g, c.b, 1, Theme.smallFont())
            end
        end,
        emptyText = T.charNoTraits,
    })
    self.protList = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.smallFont()) + Theme.px(6) end,
        drawRow = function(ui, row, x, y, w, h)
            ui:drawText(row.name, x + Theme.px(8), y + Theme.px(3), C.text.r, C.text.g, C.text.b, 1, Theme.smallFont())
            ui:drawTextRight(tostring(row.bite) .. "%", x + w - Theme.px(90), y + Theme.px(3), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
            ui:drawTextRight(tostring(row.scratch) .. "%", x + w - Theme.px(8), y + Theme.px(3), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
        end,
    })
    return self
end

function Character:open() self.nextRead = 0 end

function Character:update(now)
    if now < self.nextRead then return end
    self.nextRead = now + 1000
    local player = VPUI.Util.player()
    if not player then return end
    local ok, info = pcall(Character.read, player)
    if not ok then
        Log.once(Log.ERROR, "character", "reading character info failed: " .. tostring(info))
        return
    end
    self.info = info
    for i, p in ipairs(info.protection) do p.key = p.name end
    self:buildTraitRows()
    self.protList:setRows(info.protection)
end

-- Trait rows for the list's current width (rebuilt on layout and when the
-- traits change, not every frame).
function Character:buildTraitRows()
    local info = self.info
    if not info then return end
    local width = math.max(Theme.px(120), self.traitList.w - Theme.px(32))
    local sig = tostring(width)
    for _, t in ipairs(info.traits) do sig = sig .. "|" .. tostring(t.label) end
    if sig == self.traitSig then return end
    self.traitSig = sig
    local rows = {}
    for i, t in ipairs(info.traits) do
        table.insert(rows, { key = "t" .. i, title = true, text = t.label, cost = t.cost })
        local ok, lines = pcall(richLines, t.description, width, Theme.smallFont())
        if ok then
            for j, l in ipairs(lines) do
                table.insert(rows, { key = "t" .. i .. "l" .. j, text = l.text, x = l.x, color = l.color })
            end
        end
        table.insert(rows, { key = "t" .. i .. "gap" })
    end
    self.traitList:setRows(rows)
end

function Character:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local headH = Theme.fontHeight(UIFont.Large) + Theme.fontHeight(Theme.font()) * 2 + Theme.px(20)
    local half = math.floor((w - Theme.px(24)) / 2)
    local titleH = Theme.fontHeight(Theme.smallFont()) + Theme.px(8)
    self.traitList:layout(x, y + headH + titleH, half, h - headH - titleH)
    self.traitSig = nil
    self:buildTraitRows()
    self.protList:layout(x + half + Theme.px(24), y + headH + titleH, half, h - headH - titleH)
end

function Character:render(ui, mx, my)
    local a, info = self.area, self.info
    if not info then return end
    ui:drawText(info.name or "", a.x, a.y, C.text.r, C.text.g, C.text.b, 1, UIFont.Large)
    local y = a.y + Theme.fontHeight(UIFont.Large) + Theme.px(4)
    if info.profession then
        ui:drawText(info.profession, a.x, y, C.accent.r, C.accent.g, C.accent.b, 1, Theme.font())
        y = y + Theme.fontHeight(Theme.font()) + Theme.px(2)
    end
    if info.core then
        ui:drawText(string.format(T.charCoreTemp, info.core), a.x, y, C.dim.r, C.dim.g, C.dim.b, 1, Theme.font())
    end
    local small = Theme.smallFont()
    ui:drawText(T.charTraits, self.traitList.x, self.traitList.y - Theme.fontHeight(small) - Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, small)
    local p = self.protList
    ui:drawText(T.charProtection, p.x, p.y - Theme.fontHeight(small) - Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, small)
    ui:drawTextRight(getText("IGUI_health_Bite"), p.x + p.w - Theme.px(90), p.y - Theme.fontHeight(small) - Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, small)
    ui:drawTextRight(getText("IGUI_health_Scratch"), p.x + p.w - Theme.px(8), p.y - Theme.fontHeight(small) - Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, small)
    self.traitList:draw(ui, mx, my)
    self.protList:draw(ui, mx, my)
end

function Character:wheel(x, y, del) return self.traitList:wheel(x, y, del) or self.protList:wheel(x, y, del) end

VPUI.Hub.register({
    id = "character",
    label = T.tabCharacter,
    order = 60,
    key = function() return getCore():getKey(KeybindId.TOGGLE_INFO_PANEL) end,
    create = Character.create,
})
