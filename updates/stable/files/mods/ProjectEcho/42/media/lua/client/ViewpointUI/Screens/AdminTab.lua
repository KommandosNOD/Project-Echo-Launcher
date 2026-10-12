--
-- Viewpoint UI - admin tab (Phase 7). Visible only to staff: on a server, a role
-- with admin tools (Role:hasAdminTool) or the legacy admin/moderator access
-- level; in single player, only with debug mode on (as the vanilla debug menus).
--
-- Every action is a vanilla admin path, so the server checks the role's
-- capabilities exactly as it does for the vanilla scoreboard and admin panels:
--   players   /teleport, /teleportplayer, /kickuser, /banuser, /godmodplayer,
--             /invisibleplayer (ISScoreboard:onContext), player stats window
--   self      god mode, invisible, no clip + sendPlayerExtraInfo (ISAdminPowerUI)
--   target    the last thing aimed at before opening: coordinates, teleport
--             there (/teleportto, DebugContextMenu.onTeleportValid), horde
--             manager on that square, remove vehicle (ISVehicleMechanics.onCheatRemove)
--   tools     admin panel, item list, spawn vehicle, remove-item tool, teleport
-- Buttons a role cannot use are greyed by the same capability checks vanilla uses.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Legacy"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Admin then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local T = VPUI.Text
local Log = VPUI.Log

local Admin = {}
Admin.__index = Admin
VPUI.Screens.Admin = Admin

-- Last target aimed at (kept by the controller), so the tab can act on it.
Admin.lastTarget = nil

function Admin.isStaff(player)
    if not player then return false end
    if isClient() then
        local ok, tool = pcall(function() return player:getRole():hasAdminTool() end)
        if ok and tool then return true end
        -- vanilla shows its admin button on Role:hasAdminTool (ISEquippedItem); isAdmin
        -- covers the legacy admin access level. Role names (user, priority...) are not checks.
        local okA, admin = pcall(isAdmin)
        return okA and admin == true
    end
    return isDebugEnabled() == true
end

-- Same capability gate vanilla uses; single player debug may do everything.
function Admin.can(player, capability)
    if not isClient() then return isDebugEnabled() == true end
    if not capability then return false end
    local ok, v = pcall(function() return player:getRole():hasCapability(capability) end)
    return ok and v == true
end

local function quoted(name) return '"' .. tostring(name) .. '"' end

local function command(text)
    Log.info("admin command: " .. text)
    SendCommandToServer(text)
end

function Admin.teleportTo(player, x, y, z)
    if isClient() then
        command("/teleportto " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
    else
        player:teleportTo(x, y, z)
    end
end

function Admin.create(screen)
    local self = setmetatable({}, Admin)
    self.screen = screen
    self.players = {}
    self.confirm = nil       -- { id, until } two-step confirmation for kick/ban
    self.playerList = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.px(8) end,
        emptyText = isClient() and T.adminNoPlayers or T.adminSinglePlayer,
        drawRow = function(ui, row, x, y, w, h)
            ui:drawText(row.display, x + Theme.px(8), y + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, Theme.font())
            if row.display ~= row.username then
                ui:drawTextRight(row.username, x + w - Theme.px(8), y + Theme.px(4), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
            end
        end,
    })
    local function selected()
        local rows = self.playerList:selectedRows()
        return rows[1]
    end
    local function me() return VPUI.Util.player() end
    local function confirmed(id)
        local now = VPUI.Util.now()
        if self.confirm and self.confirm.id == id and now < self.confirm.untilMs then
            self.confirm = nil
            return true
        end
        self.confirm = { id = id, untilMs = now + 3000 }
        VPUI.UI.toast(T.adminConfirm, 3)
        return false
    end
    local function playerButton(label, capability, fn, needsConfirm)
        return Region.Button.new({ label = label,
            enabled = function() return selected() ~= nil and Admin.can(me(), capability) end,
            onClick = function()
                local row = selected()
                if not row then return end
                if needsConfirm and not confirmed(label .. row.username) then return end
                fn(row)
            end })
    end
    self.playerButtons = {
        playerButton(T.adminGoTo, Capability.TeleportToPlayer, function(r) command("/teleport " .. quoted(r.username)) end),
        playerButton(T.adminBring, Capability.TeleportPlayerToAnotherPlayer, function(r)
            command("/teleportplayer " .. quoted(r.username) .. " " .. quoted(me():getUsername())) end),
        playerButton(T.adminGod, Capability.ToggleGodModEveryone, function(r) command("/godmodplayer " .. quoted(r.username)) end),
        playerButton(T.adminInvisible, Capability.ToggleInvisibleEveryone, function(r) command("/invisibleplayer " .. quoted(r.username)) end),
        playerButton(T.adminStats, Capability.CanSeePlayersStats, function(r)
            local target = getPlayerFromUsername(r.username)
            if not target then VPUI.UI.toast(T.adminNotLoaded, 3) return end
            VPUI.Hub.close()
            VPUI.Legacy.openWindow(function()
                local ui = ISPlayerStatsUI:new(50, 50, 800 + (getCore():getOptionFontSizeReal() * 50), 800, target, me())
                ui:initialise()
                ui:addToUIManager()
            end)
        end),
        playerButton(T.adminKick, Capability.KickUser, function(r) command("/kickuser " .. quoted(r.username)) end, true),
        playerButton(T.adminBan, Capability.BanUnbanUser, function(r) command("/banuser " .. quoted(r.username)) end, true),
    }
    local function selfToggle(label, capability, get, set)
        return Region.Button.new({ label = label,
            enabled = function() return Admin.can(me(), capability) end,
            onClick = function()
                local p = me()
                set(p, not get(p))
                sendPlayerExtraInfo(p)
            end })
    end
    self.selfButtons = {
        selfToggle(T.adminSelfGod, Capability.ToggleGodModHimself, function(p) return p:isGodMod() end, function(p, v) p:setGodMod(v) end),
        selfToggle(T.adminSelfInvisible, Capability.ToggleInvisibleHimself, function(p) return p:isInvisible() end, function(p, v) p:setInvisible(v) end),
        selfToggle(T.adminSelfNoClip, Capability.ToggleNoclipHimself, function(p) return p:isNoClip() end, function(p, v) p:setNoClip(v) end),
    }
    local function window(label, capability, opener)
        return Region.Button.new({ label = label,
            enabled = function()
                if capability then return Admin.can(me(), capability) end
                -- the admin panel itself: same gate as the vanilla admin button
                if not isClient() then return isDebugEnabled() == true end
                local ok, tool = pcall(function() return me():getRole():hasAdminTool() end)
                return ok and tool == true
            end,
            onClick = function()
                VPUI.Hub.close()
                VPUI.Legacy.openWindow(opener)
            end })
    end
    local function target() return Admin.lastTarget end
    self.targetButtons = {
        Region.Button.new({ label = T.adminTeleportHere,
            enabled = function() return target() ~= nil and Admin.can(me(), Capability.TeleportToCoordinates) end,
            onClick = function()
                local t = target()
                VPUI.Hub.close()
                Admin.teleportTo(me(), t.x, t.y, t.z)
            end }),
        window(T.adminHorde, Capability.CreateHorde, function()
            local t = target()
            local sq = t and getCell():getGridSquare(t.x, t.y, t.z) or me():getCurrentSquare()
            AdminContextMenu.onHordeManager(sq, me())
        end),
        Region.Button.new({ label = T.adminRemoveVehicle,
            enabled = function()
                local t = target()
                return t ~= nil and t.vehicle ~= nil and Admin.can(me(), Capability.ManipulateVehicle)
            end,
            onClick = function()
                local t = target()
                VPUI.Hub.close()
                ISVehicleMechanics.onCheatRemove(me(), t.vehicle)
            end }),
    }
    self.toolButtons = {
        window(T.adminPanel, nil, function()
            if ISAdminPanelUI.instance then ISAdminPanelUI.instance:close() end
            local modal = ISAdminPanelUI:new(200, 200, 350, 400)
            modal:initialise()
            modal:addToUIManager()
        end),
        window(T.adminItems, Capability.AddItem, function()
            local modal = ISItemsListViewer:new(50, 200, 1050 + (getCore():getOptionFontSizeReal() * 100), 650 + (getCore():getOptionFontSizeReal() * 50), me())
            modal:initialise()
            modal:addToUIManager()
        end),
        window(T.adminSpawnVehicle, Capability.ManipulateVehicle, function() AdminContextMenu.onSpawnVehicle(me()) end),
        window(T.adminRemoveItems, Capability.UseLootZed, function() AdminContextMenu.onRemoveItemTool(me()) end),
        window(T.adminTeleportUI, Capability.TeleportToCoordinates, function() AdminContextMenu.onTeleportUI(me()) end),
    }
    return self
end

function Admin:open()
    self.players = {}
    if isClient() then
        local ok = pcall(scoreboardUpdate)
        if not ok then Log.warn("scoreboard request failed") end
    end
end

-- The server answers scoreboardUpdate() with this event (ISMiniScoreboardUI does the same).
Events.OnScoreboardUpdate.Add(function(usernames, displayNames, steamIDs)
    local screen = VPUI.Hub.screen()
    local inst = screen and screen.instances and screen.instances.admin
    if not inst then return end
    local rows = {}
    for i = 0, usernames:size() - 1 do
        local name = usernames:get(i)
        table.insert(rows, { key = name, username = name, display = displayNames:get(i) or name })
    end
    table.sort(rows, function(a, b) return string.lower(a.display) < string.lower(b.display) end)
    inst.playerList:setRows(rows)
end)

function Admin:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local half = math.floor((w - Theme.px(32)) / 2)
    local btnH = Theme.fontHeight(Theme.smallFont()) + Theme.px(10)
    local titleH = Theme.fontHeight(Theme.smallFont()) + Theme.px(8)
    local listH = math.floor(h * 0.6)
    self.playerList:layout(x, y + titleH, half, listH)
    local bx, by = x, y + titleH + listH + Theme.px(10)
    for _, b in ipairs(self.playerButtons) do
        local bw = b:preferredWidth()
        if bx + bw > x + half then bx = x; by = by + btnH + Theme.px(6) end
        b:layout(bx, by, bw, btnH)
        bx = bx + bw + Theme.px(6)
    end
    local rx = x + half + Theme.px(32)
    self.rightX = rx
    local ry = y
    local function row(list)
        ry = ry + titleH
        local cx = rx
        for _, b in ipairs(list) do
            local bw = b:preferredWidth()
            if cx + bw > rx + half then cx = rx; ry = ry + btnH + Theme.px(6) end
            b:layout(cx, ry, bw, btnH)
            cx = cx + bw + Theme.px(6)
        end
        ry = ry + btnH + Theme.px(18)
    end
    self.selfY = ry; row(self.selfButtons)
    self.targetY = ry; ry = ry + Theme.fontHeight(Theme.font()) * 2 + Theme.px(4); row(self.targetButtons)
    self.toolsY = ry; row(self.toolButtons)
end

local function allButtons(self)
    local list = {}
    for _, group in ipairs({ self.playerButtons, self.selfButtons, self.targetButtons, self.toolButtons }) do
        for _, b in ipairs(group) do table.insert(list, b) end
    end
    return list
end

function Admin:render(ui, mx, my)
    local small = Theme.smallFont()
    local function title(text, x, y) ui:drawText(text, x, y, C.dim.r, C.dim.g, C.dim.b, 1, small) end
    title(T.adminPlayers, self.area.x, self.area.y)
    self.playerList:draw(ui, mx, my)
    local p = VPUI.Util.player()
    local selfTitle = T.adminSelf
    if p then
        selfTitle = selfTitle .. "   " .. string.format(T.adminState, p:isGodMod() and T.on or T.off,
            p:isInvisible() and T.on or T.off, p:isNoClip() and T.on or T.off)
    end
    title(selfTitle, self.rightX, self.selfY)
    title(T.adminTarget, self.rightX, self.targetY)
    local t = Admin.lastTarget
    local desc = t and string.format("%s   %d, %d, %d", t.name or "?", t.x, t.y, t.z) or T.adminNoTarget
    ui:drawText(desc, self.rightX, self.targetY + Theme.fontHeight(small) + Theme.px(4), C.text.r, C.text.g, C.text.b, 1, Theme.font())
    title(T.adminTools, self.rightX, self.toolsY)
    for _, b in ipairs(allButtons(self)) do b:draw(ui, mx, my) end
end

function Admin:mouseDown(x, y, mods)
    for _, b in ipairs(allButtons(self)) do
        if b:mouseDown(x, y) then return true end
    end
    return self.playerList:mouseDown(x, y, mods)
end
function Admin:mouseUp() self.playerList:mouseUp() end
function Admin:wheel(x, y, del) return self.playerList:wheel(x, y, del) end

VPUI.Hub.register({
    id = "admin",
    label = T.tabAdmin,
    order = 90,
    key = function() return VPUI.Settings.get("adminKey") end,
    visible = function(player) return Admin.isStaff(player) end,
    create = Admin.create,
})
