--
-- Viewpoint UI - health tab.
--
-- Shows exactly what the vanilla health panel shows (ISHealthBodyPartListBox:
-- doDrawItem), with the same doctor-skill gates: wound severity, infection and
-- the like appear only when the character's First Aid level would reveal them
-- in vanilla. Zombie infection is never shown, as in vanilla.
--
-- Treatments come from the game's own body-part menu
-- (ISHealthPanel:doBodyPartContextMenu), harvested from the character's
-- health view: every bandage, disinfectant, stitch, splint, poultice and removal
-- the game (or a mod) offers, run through the game's own timed actions.
--
-- The body: the game's own body-part art (media/ui/BodyParts, the textures the
-- vanilla clothing-protection panel draws with ISBodyPartPanel), your sex's
-- figure with every part tinted by its state - untouched, hurt, badly hurt,
-- bleeding. Click a part to select it (hit-testing as ISBodyPartPanel does:
-- each part's box, the torso parts on top); hover shows its name.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Util/Harvest"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Health then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local Harvest = VPUI.Util.Harvest
local T = VPUI.Text
local Log = VPUI.Log

local Health = {}
Health.__index = Health
VPUI.Screens.Health = Health

-- ISBodyPartPanel's part art, by BodyPartType index (z: which part wins
-- where boxes overlap).
local PART_ART = {
    [0] = { file = "left-hand" }, [1] = { file = "right-hand" },
    [2] = { file = "lower-left-arm" }, [3] = { file = "lower-right-arm" },
    [4] = { file = "upper-left-arm" }, [5] = { file = "upper-right-arm" },
    [6] = { file = "chest", z = 30 }, [7] = { file = "abdomen", z = 50 },
    [8] = { file = "head" }, [9] = { file = "neck" }, [10] = { file = "groin", z = 100 },
    [11] = { file = "left-thigh" }, [12] = { file = "right-thigh" },
    [13] = { file = "left-calf" }, [14] = { file = "right-calf" },
    [15] = { file = "left-foot" }, [16] = { file = "right-foot" },
}
local ART_W, ART_H = 123, 302   -- ISBodyPartPanel's size

local RED = { r = 0.89, g = 0.28, b = 0.28 }
local GREEN = { r = 0.28, g = 0.89, b = 0.28 }
local ORANGE = { r = 1, g = 0.58, b = 0 }

-- The vanilla panel's lines for one body part, in the same order and with the
-- same doctor-level gates.
function Health.lines(bp, doctorLevel)
    local out = {}
    local function add(key, color, suffix) table.insert(out, { text = getText(key) .. (suffix or ""), color = color }) end
    local function sev(key) return " (" .. getText(key) .. ")" end
    if bp:getPlantainFactor() > 0 then add("ContextMenu_PlantainCataplasm", GREEN) end
    if bp:getComfreyFactor() > 0 then add("ContextMenu_ComfreyCataplasm", GREEN) end
    if bp:getGarlicFactor() > 0 then add("ContextMenu_GarlicCataplasm", GREEN) end
    if bp:scratched() then
        local s = ""
        if doctorLevel > 2 then
            if bp:getScratchTime() > 17 then s = sev("IGUI_health_Severe") elseif bp:getScratchTime() > 14 then s = sev("IGUI_health_Moderate") end
        end
        add("IGUI_health_Scratched", RED, s)
    end
    if bp:isCut() then
        local s = ""
        if doctorLevel > 2 then
            if bp:getCutTime() > 17 then s = sev("IGUI_health_Severe") elseif bp:getCutTime() > 14 then s = sev("IGUI_health_Moderate") end
        end
        add("IGUI_health_Cut", RED, s)
    end
    if bp:deepWounded() then
        local s = ""
        if doctorLevel > 4 then
            if bp:getDeepWoundTime() > 10 then s = sev("IGUI_health_Severe") elseif bp:getDeepWoundTime() > 8 then s = sev("IGUI_health_Moderate") end
        end
        add("IGUI_health_DeepWound", RED, s)
    end
    if bp:bitten() then add("IGUI_health_Bitten", RED) end
    if bp:getAdditionalPain() > 10 then
        add(bp:getAdditionalPain() > 50 and "IGUI_health_HeavyPain" or "IGUI_health_Pain", RED)
    end
    local stiff = bp:getStiffness()
    if stiff >= 5 then
        if stiff < 20 then add("IGUI_health_MinorStiffness", ORANGE) else add("IGUI_health_Stiffness", RED) end
    end
    if bp:bleeding() then add("IGUI_health_Bleeding", RED) end
    if bp:getFractureTime() > 0 and bp:getSplintFactor() == 0 then
        local s = ""
        if doctorLevel > 6 then
            if bp:getFractureTime() > 50 then s = sev("IGUI_health_Severe") elseif bp:getFractureTime() > 20 then s = sev("IGUI_health_Moderate") end
        end
        add("IGUI_health_Fracture", RED, s)
    end
    if bp:getSplintFactor() > 0 then
        local s = ""
        if doctorLevel > 4 then
            if bp:getSplintFactor() > 4 then s = sev("IGUI_health_Good") elseif bp:getFractureTime() > 2 then s = sev("IGUI_health_Moderate") end
        end
        add("IGUI_health_Splinted", GREEN, s)
    end
    if bp:bandaged() then
        if bp:getBandageLife() > 0 then add("IGUI_health_Bandaged", GREEN) else add("IGUI_health_DirtyBandage", ORANGE) end
    end
    if bp:isInfectedWound() and not bp:bandaged() then
        if doctorLevel > 8 or (bp:getWoundInfectionLevel() * 10 >= (2.5 - doctorLevel)) then
            add("IGUI_health_Infected", ORANGE)
        end
    end
    if bp:haveBullet() and not bp:bandaged() then add("IGUI_health_LodgedBullet", RED) end
    if bp:getBurnTime() > 0 and not bp:bandaged() then
        local s = ""
        if doctorLevel > 4 and bp:isNeedBurnWash() then s = sev("IGUI_health_NeedCleaning") end
        add("IGUI_health_Burned", RED, s)
    end
    if bp:stitched() then
        local s = ""
        if doctorLevel > 6 then s = bp:getStitchTime() > 40 and sev("IGUI_health_Good") or sev("IGUI_health_NeedTime") end
        add("IGUI_health_Stitched", GREEN, s)
    end
    if bp:haveGlass() and not bp:bandaged() then add("IGUI_health_LodgedGlassShards", RED) end
    return out
end

-- The vanilla overall status text (zombie.ui.NewHealthPanel.getDamageStatusString).
function Health.overall(player)
    if player:isDead() then return getText("IGUI_health_Deceased") end
    local h = player:getBodyDamage():getHealth()
    local key
    if h >= 100 then key = "IGUI_health_ok"
    elseif h > 90 then key = "IGUI_health_Slight_damage"
    elseif h > 80 then key = "IGUI_health_Very_Minor_damage"
    elseif h > 70 then key = "IGUI_health_Minor_damage"
    elseif h > 60 then key = "IGUI_health_Moderate_damage"
    elseif h > 50 then key = "IGUI_health_Severe_damage"
    elseif h > 40 then key = "IGUI_health_Very_Severe_damage"
    elseif h > 20 then key = "IGUI_health_Crital_damage"
    elseif h > 10 then key = "IGUI_health_Highly_Crital_damage"
    else key = "IGUI_health_Terminal_damage" end
    return getText(key), h
end

function Health.create(screen)
    local self = setmetatable({}, Health)
    self.screen = screen
    self.nextRead = 0
    self.parts = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(10) end,
        drawRow = function(ui, row, x, y, w, h)
            local hurt = #row.lines > 0
            local c = hurt and C.text or C.off
            ui:drawText(row.name, x + Theme.px(8), y + Theme.px(5), c.r, c.g, c.b, 1, Theme.font())
            if hurt then
                local first = row.lines[1]
                local more = #row.lines > 1 and ("  +" .. tostring(#row.lines - 1)) or ""
                ui:drawTextRight(first.text .. more, x + w - Theme.px(8), y + Theme.px(5), first.color.r, first.color.g, first.color.b, 1, Theme.smallFont())
            end
        end,
        onSelect = function(row) self:select(row) end,
        onContext = function(row, i, sx, sy) self:select(row); self:openTreatments(sx, sy) end,
    })
    self.treatments = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(8) end,
        emptyText = T.healthNoTreatment,
        drawRow = function(ui, row, x, y, w, h)
            local c = row.enabled ~= false and C.text or C.off
            ui:drawText(row.label, x + Theme.px(8), y + Theme.px(4), c.r, c.g, c.b, 1, Theme.font())
        end,
        onActivate = function(row) self:treat(row) end,
    })
    self.body = nil   -- textures, loaded for the player's sex
    self.applyButton = Region.Button.new({ label = T.healthApply, accent = true, onClick = function()
        local rows = self.treatments:selectedRows()
        if rows[1] then self:treat(rows[1]) end
    end, enabled = function() return #self.treatments:selectedRows() > 0 end })
    -- the game's exercise window, opened as the vanilla health panel's
    -- Exercise button does (ISNewHealthPanel:onClick "FITNESS")
    self.fitnessButton = Region.Button.new({ label = getTextOrNull("ContextMenu_Fitness") or getText("UI_ProjectEcho_VPUI_Screens_HealthTab_RU_001"), onClick = function()
        local player = self:player()
        if not player or not ISFitnessUI then return end
        VPUI.Hub.close()
        VPUI.Legacy.openWindow(function()
            local n = player:getPlayerNum() + 1
            if ISFitnessUI.instance and ISFitnessUI.instance[n] then
                ISFitnessUI.instance[n]:removeFromUIManager()
                ISFitnessUI.instance[n] = nil
            end
            local modal = ISFitnessUI:new(0, 0, 600, 350, player)
            modal:initialise()
            modal:addToUIManager()
        end)
    end, enabled = function() return getCore():getGameMode() ~= "Tutorial" end })
    return self
end

function Health:player() return VPUI.Util.player() end

function Health:open()
    self.nextRead = 0
    self.selectedType = nil
    self:read(VPUI.Util.now())
end

function Health:read(now)
    local player = self:player()
    if not player then return end
    self.nextRead = now + 500
    local doctor = player:getPerkLevel(Perks.Doctor)
    local rows = {}
    local parts = player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        local ok, lines = pcall(Health.lines, bp, doctor)
        table.insert(rows, { key = BodyPartType.ToString(bp:getType()), bp = bp,
                             name = BodyPartType.getDisplayName(bp:getType()), lines = ok and lines or {} })
    end
    -- injured parts first, body order otherwise
    local indexed = {}
    for i, r in ipairs(rows) do r.order = i; table.insert(indexed, r) end
    table.sort(indexed, function(a, b)
        local ha, hb = #a.lines > 0, #b.lines > 0
        if ha ~= hb then return ha end
        return a.order < b.order
    end)
    self.parts:setRows(indexed)
    if self.selectedType then
        for i, r in ipairs(indexed) do
            if r.key == self.selectedType then
                self.parts.selected = { [i] = true }
                self.current = r
            end
        end
    end
    self.status, self.healthValue = Health.overall(player)
end

function Health:select(row)
    self.current = row
    self.selectedType = row.key
    self:loadTreatments()
end

-- Harvests the game's body-part menu from the character's own health view.
function Health:loadTreatments()
    local player = self:player()
    if not player or not self.current then return end
    local pn = player:getPlayerNum()
    local info = getPlayerInfoPanel(pn)
    local view = info and info.healthView
    if not view then
        self.treatments:setRows({})
        Log.once(Log.WARN, "no-health-view", "the game's health view is missing; treatments unavailable")
        return
    end
    view.doctorLevel = player:getPerkLevel(Perks.Doctor)
    local bp = self.current.bp
    local actions = Harvest.run(pn, function()
        view:doBodyPartContextMenu(bp, 0, 0)
        return getPlayerContextMenu(pn)
    end)
    for i, a in ipairs(actions) do a.key = tostring(i) .. a.label end
    self.treatments:setRows(actions)
end

function Health:treat(row)
    if not row or row.enabled == false then return end
    local ok, err = pcall(row.run)
    if not ok then Log.error("treatment failed: " .. tostring(err)) end
    self.nextRead = 0
    self.nextTreatments = 0
end

function Health:openTreatments(sx, sy)
    self:loadTreatments()
    local list = {}
    for _, a in ipairs(self.treatments.rows) do table.insert(list, a) end
    if #list > 0 then self.screen:openMenu(sx, sy, self.current and self.current.name, list) end
end

-- The figure's textures for this player's sex (once; again if it changes).
function Health:bodyArt(player)
    local sex = player:isFemale() and "female" or "male"
    if self.body and self.body.sex == sex then return self.body end
    local art = { sex = sex, parts = {} }
    art.base = getTexture("media/ui/BodyParts/" .. sex .. "_base_white")
    art.outline = getTexture("media/ui/BodyParts/bps_" .. sex .. "_outlines")
    for i = 0, 16 do
        local tex = getTexture("media/ui/BodyParts/bps_" .. sex .. "_" .. PART_ART[i].file)
        if tex then
            table.insert(art.parts, { index = i, tex = tex, z = PART_ART[i].z or 0,
                key = BodyPartType.ToString(BodyPartType.FromIndex(i)),
                ox = tex:getOffsetX(), oy = tex:getOffsetY(), w = tex:getWidth(), h = tex:getHeight() })
        end
    end
    self.body = art
    return art
end

-- Draws a (trimmed) texture at its place in the figure, scaled.
local function drawArt(ui, tex, fig, a, r, g, b)
    if not tex then return end
    local s = fig.scale
    ui:drawTextureScaled(tex, fig.x + tex:getOffsetX() * s, fig.y + tex:getOffsetY() * s,
        tex:getWidth() * s, tex:getHeight() * s, a, r, g, b)
end

-- The part under (x, y), as ISBodyPartPanel:getPartForCoordinate decides.
function Health:partAt(x, y)
    local fig = self.figure
    if not fig or not self.body then return nil end
    local lx, ly = (x - fig.x) / fig.scale, (y - fig.y) / fig.scale
    local best, z = nil, -1
    for _, p in ipairs(self.body.parts) do
        if lx >= p.ox and lx <= p.ox + p.w and ly >= p.oy and ly <= p.oy + p.h and p.z > z then
            best, z = p, p.z
        end
    end
    return best
end

-- Colour of a part: how it is doing.
local function partColor(row)
    if not row or #row.lines == 0 then return 0.55, 0.62, 0.58 end
    local bp = row.bp
    local okB, bleeding = pcall(function() return bp:bleeding() end)
    if okB and bleeding then return RED.r, RED.g, RED.b end
    local okH, hp = pcall(function() return bp:getHealth() end)
    hp = okH and hp or 100
    if hp < 50 then return RED.r, RED.g, RED.b end
    return ORANGE.r, ORANGE.g, ORANGE.b
end

function Health:drawBody(ui, mx, my)
    local fig = self.figure
    local player = self:player()
    if not fig or not player then return end
    local art = self:bodyArt(player)
    local rows = {}
    for _, r in ipairs(self.parts.rows or {}) do rows[r.key] = r end
    drawArt(ui, art.base, fig, 0.25, 1, 1, 1)
    local hover = self:partAt(mx, my)
    for _, p in ipairs(art.parts) do
        local row = rows[p.key]
        local r, g, b = partColor(row)
        local a = 0.8
        if self.selectedType then a = (p.key == self.selectedType) and 1 or 0.35 end
        if hover == p then a = 1 end
        drawArt(ui, p.tex, fig, a, r, g, b)
    end
    drawArt(ui, art.outline, fig, 1, 1, 1, 1)
    if hover then
        local row = rows[hover.key]
        local name = row and row.name or hover.key
        local small = Theme.smallFont()
        local tw = Theme.textWidth(small, name)
        ui:drawText(name, fig.x + math.floor((fig.w - tw) / 2), fig.y + fig.h + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, small)
    end
end

function Health:update(now)
    if now >= self.nextRead then
        self:read(now)
        -- the game's treatment menu checks every reachable container: rebuild it
        -- on selection, after treating, and otherwise only every few seconds
        if self.current and now >= (self.nextTreatments or 0) then
            self.nextTreatments = now + 5000
            self:loadTreatments()
        end
    end
end

function Health:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local headH = Theme.fontHeight(UIFont.Large) + Theme.px(16)
    -- the figure: as big as the height allows (whole steps of a quarter)
    local avail = h - headH - Theme.fontHeight(Theme.smallFont()) - Theme.px(12)
    local scale = math.max(1, math.min(3, math.floor(avail / ART_H * 4) / 4))
    local figW, figH = math.floor(ART_W * scale), math.floor(ART_H * scale)
    self.figure = { x = x + Theme.px(8), y = y + headH, w = figW, h = figH, scale = scale }
    local bodyW = figW + Theme.px(32)
    local listW = math.floor((w - bodyW) * 0.42)
    self.parts:layout(x + bodyW, y + headH, listW, h - headH)
    local dx = x + bodyW + listW + Theme.px(24)
    self.detail = { x = dx, y = y + headH, w = x + w - dx, h = h - headH }
    local d = self.detail
    local btnH = Theme.fontHeight(Theme.font()) + Theme.px(10)
    local listY = d.y + math.floor(d.h * 0.45)
    self.treatments:layout(d.x, listY, d.w, d.y + d.h - listY - btnH - Theme.px(10))
    self.applyButton:layout(d.x, d.y + d.h - btnH, Theme.px(160), btnH)
    local fw = Theme.textWidth(Theme.font(), self.fitnessButton.label or "") + Theme.px(28)
    self.fitnessButton:layout(x + w - fw, y, fw, btnH)
end

function Health:render(ui, mx, my)
    local a = self.area
    if self.status then
        local frac = VPUI.Util.clamp((self.healthValue or 100) / 100, 0, 1)
        local c = frac > 0.7 and C.text or (frac > 0.4 and C.accent or C.danger)
        ui:drawText(self.status, a.x, a.y, c.r, c.g, c.b, 1, UIFont.Large)
        local barW = Theme.px(220)
        ui:drawRect(a.x, a.y + Theme.fontHeight(UIFont.Large) + Theme.px(4), barW, Theme.px(4), C.track.a, C.track.r, C.track.g, C.track.b)
        ui:drawRect(a.x, a.y + Theme.fontHeight(UIFont.Large) + Theme.px(4), math.floor(barW * frac), Theme.px(4), 1, c.r, c.g, c.b)
    end
    local okB, errB = pcall(self.drawBody, self, ui, mx, my)
    if not okB then Log.once(Log.WARN, "healthBody", "the body figure could not be drawn: " .. tostring(errB)) end
    self.parts:draw(ui, mx, my)
    self.fitnessButton:draw(ui, mx, my)
    local d = self.detail
    if self.current then
        ui:drawText(self.current.name, d.x, d.y, C.text.r, C.text.g, C.text.b, 1, UIFont.Medium)
        local y = d.y + Theme.fontHeight(UIFont.Medium) + Theme.px(8)
        if #self.current.lines == 0 then
            ui:drawText(T.healthFine, d.x, y, C.dim.r, C.dim.g, C.dim.b, 1, Theme.font())
        end
        for _, line in ipairs(self.current.lines) do
            ui:drawText("- " .. line.text, d.x, y, line.color.r, line.color.g, line.color.b, 1, Theme.font())
            y = y + Theme.fontHeight(Theme.font()) + Theme.px(3)
        end
        ui:drawText(T.healthTreatments, d.x, self.treatments.y - Theme.fontHeight(Theme.smallFont()) - Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
        self.treatments:draw(ui, mx, my)
        self.applyButton:draw(ui, mx, my)
    else
        ui:drawText(T.healthPick, d.x, d.y, C.off.r, C.off.g, C.off.b, 1, Theme.font())
    end
end

-- Selects the list row for a body part type key.
function Health:selectKey(key)
    for i, r in ipairs(self.parts.rows or {}) do
        if r.key == key then
            self.parts.selected = { [i] = true }
            self.parts.anchor = i
            self:select(r)
            return r
        end
    end
    return nil
end

function Health:mouseDown(x, y, mods)
    if self.applyButton:mouseDown(x, y) then return true end
    if self.fitnessButton:mouseDown(x, y) then return true end
    local part = self:partAt(x, y)
    if part then
        self:selectKey(part.key)
        return true
    end
    return self.parts:mouseDown(x, y, mods) or self.treatments:mouseDown(x, y, mods)
end

function Health:mouseUp() self.parts:mouseUp(); self.treatments:mouseUp() end
function Health:doubleClick(x, y, mods) return self.treatments:doubleClick(x, y, mods) end
function Health:rightClick(x, y, sx, sy)
    local part = self:partAt(x, y)
    if part and self:selectKey(part.key) then
        self:openTreatments(sx, sy)
        return true
    end
    return self.parts:rightClick(x, y, sx, sy)
end
function Health:wheel(x, y, del) return self.parts:wheel(x, y, del) or self.treatments:wheel(x, y, del) end

VPUI.Hub.register({
    id = "health",
    label = T.tabHealth,
    order = 40,
    key = function() return getCore():getKey(KeybindId.TOGGLE_HEALTH_PANEL) end,
    create = Health.create,
})
