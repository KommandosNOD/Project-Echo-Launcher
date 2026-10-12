--
-- Viewpoint UI - recipe browser: the shared body of the crafting and building
-- tabs. Search box and categories on the left, recipes in the middle (green
-- can do now, grey something missing, dim not available), details and the
-- action on the right.
--
-- A tab built on it supplies:
--   makeLogic(player)          -> HandcraftLogic / BuildLogic
--   loadRecipes(logic, player)    fills the logic with recipes
--   refresh(logic, player)        per-second upkeep (containers, surface...)
--   actionLabel, action(self, recipe, quantity), canAct(self, recipe)
--   batch = true                  shows a quantity selector
--

require "ISUI/ISTextEntryBox"
require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/Crafting/Recipes"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.RecipeBrowser then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local Recipes = VPUI.Crafting.Recipes
local T = VPUI.Text
local Log = VPUI.Log

local Browser = {}
Browser.__index = Browser
VPUI.Screens.RecipeBrowser = Browser

-- Performance (0.5.2): the game's crafting logic is expensive (container scans,
-- input auto-fill, the can-craft check over every recipe). It is now driven by
-- changes, not by the clock:
--   * one logic object per tab for the whole session (a new one per opening
--     piled up live logic objects, each watching containers)
--   * every CHECK_MS only a cheap signature is taken (square, containers, item
--     counts); the logic is refreshed and the list re-filtered only when it
--     changes, and never more often than MIN_HEAVY_MS (longer if it was slow)
--   * the search is applied 250 ms after the last keystroke, not per key
--   * recipes are queried from the game once per opening, not on every change
local CHECK_MS = 1000
local MIN_HEAVY_MS = 2000
local SLOW_MS = 40           -- a refresh slower than this backs off to SLOW_BACKOFF_MS
local SLOW_BACKOFF_MS = 6000
local SEARCH_DELAY_MS = 250

local STATE_COLOR = { ok = C.good, missing = C.dim, invalid = C.off }

-- Favourites are the game's own (player mod data under
-- BaseCraftingLogic.getFavouriteModDataString, as ISWidgetTitleHeader sets
-- them), so they are shared with the vanilla crafting and build windows, and
-- the game's recipe filter lists them under the "*" category.
local function favKey(recipe)
    local ok, k = pcall(function() return BaseCraftingLogic.getFavouriteModDataString(recipe) end)
    return ok and k or nil
end

function Browser.isFavourite(player, recipe)
    local k = player and recipe and favKey(recipe)
    return k ~= nil and player:getModData()[k] == true
end

function Browser.setFavourite(player, recipe, on)
    local k = player and recipe and favKey(recipe)
    if not k then return end
    player:getModData()[k] = on == true
    pcall(function() player:transmitModData() end)
end

-- Splits text into lines no wider than w.
local function wrap(text, font, w)
    local lines, line = {}, ""
    for word in string.gmatch(tostring(text or ""), "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and Theme.textWidth(font, try) > w then
            table.insert(lines, line)
            line = word
        else
            line = try
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

function Browser.new(screen, spec)
    local self = setmetatable({}, Browser)
    self.screen = screen
    self.spec = spec
    self.search = ""
    self.category = ""
    self.quantity = 1
    self.nextRefresh = 0
    self.nextHeavy = 0
    self.heavyEvery = MIN_HEAVY_MS
    self.signature = nil
    self.filterAt = nil

    self.categoryList = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(8) end,
        drawRow = function(ui, row, x, y, w, h, state)
            local c = row.id == self.category and C.accent or C.text
            ui:drawText(row.label, x + Theme.px(8), y + Theme.px(4), c.r, c.g, c.b, 1, Theme.font())
        end,
        onSelect = function(row) self:setCategory(row.id) end,
    })
    self.recipeList = Region.List.new({
        rowHeight = function() return math.max(Theme.fontHeight(Theme.font()) + Theme.px(10), Theme.px(30)) end,
        emptyText = T.noRecipes,
        drawRow = function(ui, row, x, y, w, h, state)
            local icon = h - Theme.px(8)
            local tex = row.recipe:getIconTexture()
            if tex then ui:drawTextureScaledAspect(tex, x + Theme.px(6), y + Theme.px(4), icon, icon, 1, 1, 1, 1) end
            local c = STATE_COLOR[row.state] or C.text
            ui:drawText(row.label, x + icon + Theme.px(14), y + math.floor((h - Theme.fontHeight(Theme.font())) / 2), c.r, c.g, c.b, 1, Theme.font())
            if row.favourite then
                ui:drawTextRight("*", x + w - Theme.px(10), y + math.floor((h - Theme.fontHeight(Theme.font())) / 2), C.accent.r, C.accent.g, C.accent.b, 1, Theme.font())
            end
        end,
        onSelect = function(row) self:select(row.recipe) end,
        onActivate = function(row) self:select(row.recipe); self:act() end,
    })
    self.actionButton = Region.Button.new({ label = spec.actionLabel, accent = true, font = UIFont.Medium,
        onClick = function() self:act() end,
        enabled = function() return self:canAct() end })
    self.minus = Region.Button.new({ label = "-", onClick = function() self.quantity = math.max(1, self.quantity - 1) end })
    self.plus = Region.Button.new({ label = "+", onClick = function() self.quantity = math.min(self:maxQuantity(), self.quantity + 1) end })
    self.max = Region.Button.new({ label = T.recipeMax, onClick = function() self.quantity = math.max(1, self:maxQuantity()) end })
    self.favButton = Region.Button.new({ label = T.recipeFavourite, onClick = function() self:toggleFavourite() end })

    local entry = ISTextEntryBox:new("", 0, 0, 100, 20)
    entry.font = Theme.font()
    entry.backgroundColor = { r = C.panel.r, g = C.panel.g, b = C.panel.b, a = 0.9 }
    entry.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    entry.onTextChange = function()
        self.search = entry:getInternalText() or ""
        self.filterAt = getTimestampMs() + SEARCH_DELAY_MS
    end
    -- Esc while typing reaches only the box (see InventoryTab): it lets go
    entry.onOtherKey = function(box, key)
        if key == Keyboard.KEY_ESCAPE then pcall(box.unfocus, box) end
    end
    self.entry = entry
    return self
end

function Browser:attach(tab)
    self.screen:addTabChild(tab, self.entry)
    if self.entry.setPlaceholderText then pcall(function() self.entry:setPlaceholderText(T.searchPlaceholder) end) end
end

function Browser:player()
    return VPUI.Util.player()
end

function Browser:open(args)
    local player = self:player()
    if not player then return end
    if not self.logic or self.logicPlayer ~= player then
        local ok, logic = pcall(self.spec.makeLogic, player)
        if not ok or not logic then
            Log.error("could not create crafting logic: " .. tostring(logic))
            return
        end
        self.logic = logic
        self.logicPlayer = player
    end
    self.signature = self:computeSignature(player)
    self:reload(true)
    self.nextHeavy = getTimestampMs() + self.heavyEvery
    if args and args.recipe then self:select(args.recipe) end
end

function Browser:close()
    if self.logic and self.spec.onClose then pcall(self.spec.onClose, self, self.logic) end
end

function Browser:reload(full)
    local player = self:player()
    if not player or not self.logic then return end
    if self.spec.refresh then
        local ok, err = pcall(self.spec.refresh, self.logic, player, full)
        if not ok then Log.error("recipe refresh failed: " .. tostring(err)) end
    end
    if full then
        local ok, err = pcall(self.spec.loadRecipes, self.logic, player)
        if not ok then Log.error("loading recipes failed: " .. tostring(err)) end
        local cats = { { id = "", label = Recipes.categoryLabel("") },
                       { id = "*", label = getTextOrNull("IGUI_CraftingCategories_Favourites") or T.favourites } }
        for _, cat in ipairs(Recipes.categories(self.logic)) do
            table.insert(cats, { id = cat, label = Recipes.categoryLabel(cat) })
        end
        self.categoryList:setRows(cats)
    end
    self:applyFilter()
end

function Browser:setCategory(id)
    self.category = id or ""
    self:applyFilter()
end

function Browser:applyFilter()
    if not self.logic then return end
    VPUI.Perf.count("recipeFilters")
    Recipes.filter(self.logic, self.search, self.category)
    local player = self:player()
    local rows = {}
    for _, recipe in ipairs(Recipes.flatten(self.logic, player)) do
        table.insert(rows, { key = recipe:getName(), recipe = recipe, label = recipe:getTranslationName(),
                             state = Recipes.status(self.logic, recipe, player),
                             favourite = Browser.isFavourite(player, recipe) })
    end
    -- what can be done now first, then by name
    local rank = { ok = 1, missing = 2, invalid = 3 }
    table.sort(rows, function(a, b)
        if rank[a.state] ~= rank[b.state] then return rank[a.state] < rank[b.state] end
        return a.label < b.label
    end)
    self.recipeList:setRows(rows)
    if self.selected then
        for i, row in ipairs(rows) do
            if row.recipe == self.selected then self.recipeList.selected = { [i] = true } end
        end
    end
end

function Browser:toggleFavourite()
    local player = self:player()
    if not player or not self.selected then return end
    Browser.setFavourite(player, self.selected, not Browser.isFavourite(player, self.selected))
    self:applyFilter()
end

function Browser:select(recipe)
    if not recipe or not self.logic then return end
    self.selected = recipe
    self.quantity = 1
    -- the recipe's own description (what the vanilla info box shows:
    -- getText(recipe:getTooltip()))
    self.description = nil
    local okT, key = pcall(function() return recipe:getTooltip() end)
    if okT and key and key ~= "" then self.description = getText(key) end
    local ok, err = pcall(function() self.logic:setRecipe(recipe) end)
    if not ok then Log.error("selecting recipe failed: " .. tostring(err)) end
    self:refreshDetails()
end

function Browser:refreshDetails()
    local player = self:player()
    if not self.selected or not player then
        self.details = nil
        return
    end
    local ok, lines = pcall(Recipes.details, self.logic, self.selected, player)
    self.details = ok and lines or { { text = tostring(lines), state = "missing" } }
    -- whether the action can run now, cached once a second (the check walks
    -- every container, too costly to repeat every frame)
    if self.spec.computeCan then
        local okCan, can = pcall(self.spec.computeCan, self.logic, player, self.selected)
        self.can = okCan and can == true
    end
end

function Browser:maxQuantity()
    if not self.logic or not self.selected then return 1 end
    local ok, n = pcall(function() return self.logic:getPossibleCraftCount(false) end)
    return (ok and n and n > 0) and n or 1
end

function Browser:canAct()
    if not self.selected or not self.logic then return false end
    if self.spec.computeCan and not self.can then return false end
    if self.spec.canAct then
        local ok, v = pcall(self.spec.canAct, self, self.selected)
        return ok and v == true
    end
    return true
end

function Browser:act()
    if not self:canAct() then return end
    local ok, err = pcall(self.spec.action, self, self.selected, self.quantity)
    if not ok then Log.error(tostring(self.spec.actionLabel) .. " failed: " .. tostring(err)) end
end

-- Cheap change detector: where the player stands and what is in reach.
function Browser:computeSignature(player)
    local parts = { tostring(player:getCurrentSquare()) }
    local ok = pcall(function()
        local list = ISInventoryPaneContextMenu.getContainers(player)
        table.insert(parts, tostring(list:size()))
        for i = 0, list:size() - 1 do
            local c = list:get(i)
            table.insert(parts, tostring(c:getItems():size()))
        end
    end)
    if not ok then table.insert(parts, tostring(getTimestampMs())) end
    return table.concat(parts, "|")
end

function Browser:update(now)
    -- typed search, applied once typing pauses
    if self.filterAt and now >= self.filterAt then
        self.filterAt = nil
        self:applyFilter()
    end
    if now < self.nextRefresh then return end
    self.nextRefresh = now + CHECK_MS
    local player = self:player()
    if not player or not self.logic then return end
    local ok, busy = pcall(function() return self.logic:isCraftActionInProgress() end)
    if ok and busy then return end
    local sig = self:computeSignature(player)
    if sig == self.signature or now < self.nextHeavy then return end
    self.signature = sig
    local started = getTimestampMs()
    self:reload(false)
    self:refreshDetails()
    local took = getTimestampMs() - started
    self.heavyEvery = took > SLOW_MS and SLOW_BACKOFF_MS or MIN_HEAVY_MS
    if took > SLOW_MS then Log.once(Log.INFO, "craftSlow", "crafting list refresh took " .. tostring(took) .. " ms; refreshing it less often") end
    self.nextHeavy = getTimestampMs() + self.heavyEvery
end

function Browser:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local gap = Theme.px(16)
    local leftW = math.floor(w * 0.18)
    local midW = math.floor(w * 0.38)
    local entryH = Theme.fontHeight(Theme.font()) + Theme.px(10)
    self.entry:setX(x)
    self.entry:setY(y)
    self.entry:setWidth(leftW)
    self.entry:setHeight(entryH)
    self.categoryList:layout(x, y + entryH + Theme.px(10), leftW, h - entryH - Theme.px(10))
    self.recipeList:layout(x + leftW + gap, y, midW, h)
    self.detailArea = { x = x + leftW + midW + gap * 2, y = y, w = w - leftW - midW - gap * 2, h = h }
    local d = self.detailArea
    local btnH = Theme.fontHeight(UIFont.Medium) + Theme.px(12)
    self.actionButton:layout(d.x, d.y + d.h - btnH, Theme.px(180), btnH)
    local fbH = Theme.fontHeight(Theme.smallFont()) + Theme.px(8)
    local fbW = math.max(Theme.textWidth(Theme.smallFont(), T.recipeFavourite), Theme.textWidth(Theme.smallFont(), T.recipeUnfavourite)) + Theme.px(20)
    self.favButton:layout(d.x + d.w - fbW, d.y, fbW, fbH)
    local small = Theme.fontHeight(Theme.smallFont()) + Theme.px(8)
    local qy = d.y + d.h - btnH - small - Theme.px(10)
    self.minus:layout(d.x, qy, small, small)
    self.plus:layout(d.x + small + Theme.px(60), qy, small, small)
    self.max:layout(d.x + small * 2 + Theme.px(68), qy)
end

function Browser:render(ui, mx, my)
    self.categoryList:draw(ui, mx, my)
    self.recipeList:draw(ui, mx, my)
    local d = self.detailArea
    if not self.selected then
        ui:drawText(T.pickRecipe, d.x, d.y, C.off.r, C.off.g, C.off.b, 1, Theme.font())
        return
    end
    local y = d.y
    local tex = self.selected:getIconTexture()
    local iconSize = Theme.px(48)
    if tex then ui:drawTextureScaledAspect(tex, d.x, y, iconSize, iconSize, 1, 1, 1, 1) end
    ui:drawText(self.selected:getTranslationName(), d.x + iconSize + Theme.px(12), y + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, UIFont.Medium)
    local cat = self.selected:getCategory()
    if cat then
        ui:drawText(Recipes.categoryLabel(cat), d.x + iconSize + Theme.px(12), y + Theme.px(4) + Theme.fontHeight(UIFont.Medium), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
    end
    y = y + iconSize + Theme.px(14)
    local player = self:player()
    self.favButton.label = Browser.isFavourite(player, self.selected) and T.recipeUnfavourite or T.recipeFavourite
    self.favButton.accent = Browser.isFavourite(player, self.selected)
    self.favButton:draw(ui, mx, my)
    if self.description then
        local small = Theme.smallFont()
        if self.wrapFor ~= self.description or self.wrapW ~= d.w then
            self.wrapLines = wrap(self.description, small, d.w)
            self.wrapFor, self.wrapW = self.description, d.w
        end
        for _, line in ipairs(self.wrapLines or {}) do
            ui:drawText(line, d.x, y, C.dim.r, C.dim.g, C.dim.b, 1, small)
            y = y + Theme.fontHeight(small) + Theme.px(2)
        end
        y = y + Theme.px(8)
    end
    local lineH = Theme.fontHeight(Theme.font()) + Theme.px(4)
    for _, line in ipairs(self.details or {}) do
        local mark = line.state == "ok" and "+ " or (line.state == "missing" and "x " or "  ")
        local c = line.state == "ok" and C.good or (line.state == "missing" and C.danger or C.text)
        ui:drawText(mark .. line.text, d.x, y, c.r, c.g, c.b, 1, Theme.font())
        y = y + lineH
    end
    if self.spec.extra then pcall(self.spec.extra, self, ui, d.x, y) end
    if self.spec.batch and self.selected:isAllowBatchCraft() then
        self.minus:draw(ui, mx, my)
        self.plus:draw(ui, mx, my)
        self.max:draw(ui, mx, my)
        local q = tostring(self.quantity)
        ui:drawText(q, self.minus.x + self.minus.w + Theme.px(30) - math.floor(Theme.textWidth(Theme.font(), q) / 2), self.minus.y + Theme.px(2), C.text.r, C.text.g, C.text.b, 1, Theme.font())
    else
        self.quantity = 1
    end
    self.actionButton:draw(ui, mx, my)
end

function Browser:mouseDown(x, y, mods)
    if self.actionButton:mouseDown(x, y) then return true end
    if self.selected and self.favButton:mouseDown(x, y) then return true end
    if self.spec.batch and self.selected and self.selected:isAllowBatchCraft() then
        if self.minus:mouseDown(x, y) or self.plus:mouseDown(x, y) or self.max:mouseDown(x, y) then return true end
    end
    if self.categoryList:mouseDown(x, y, mods) then return true end
    if self.recipeList:mouseDown(x, y, mods) then return true end
    return false
end

function Browser:doubleClick(x, y, mods)
    return self.recipeList:doubleClick(x, y, mods)
end

function Browser:wheel(x, y, del)
    return self.recipeList:wheel(x, y, del) or self.categoryList:wheel(x, y, del)
end

function Browser:keyPressed(key)
    if key == Keyboard.KEY_UP then self.recipeList:moveSelection(-1) return true end
    if key == Keyboard.KEY_DOWN then self.recipeList:moveSelection(1) return true end
    if key == Keyboard.KEY_RETURN then self:act() return true end
    return false
end
