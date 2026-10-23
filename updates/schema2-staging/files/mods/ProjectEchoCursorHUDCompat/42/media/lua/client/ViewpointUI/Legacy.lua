--
-- Viewpoint UI - legacy UI policy (Phase 8).
--
-- 1. Key redirects. While the interface is active (Viewpoint's view on, the
--    interface enabled, "Allow legacy UI" off), the game's own window keys open
--    the matching Viewpoint tab instead of the vanilla window:
--      Toggle Inventory -> Inventory     Crafting  -> Crafting
--      Building         -> Build         Skills    -> Skills
--      Health           -> Health        Info / Protection -> Character
--      Switch Seat (in a vehicle)        -> Vehicle
--    The vanilla handlers are wrapped, not removed: in isometric view, with the
--    interface off, or with Allow legacy UI on, they run unchanged.
--
-- 2. Fallback windows. Some features keep the game's own window for now
--    (mechanics, admin panels, the item list, horde manager...). Viewpoint
--    holds the mouse for mouse-look, so a vanilla window would be unusable;
--    windows opened through Legacy.openWindow get the cursor freed while they
--    are visible, and mouse-look comes back when the last one closes.
--
-- 3. Other mods. With "Use the game's inventory windows" the inventory key is
--    left to the game (and to inventory mods), and the cursor is freed while
--    those windows are open. With "Free the cursor for other mods' windows",
--    any window another mod opens in first or third person (a top-level
--    ISCollapsableWindow, or a panel that can be dragged) frees the cursor while
--    it is shown. Windows already up when the view came on count only once they
--    have been closed and opened again, so a pinned overlay never keeps the
--    cursor free.
--
-- 4. The game's dialogs. Questions and value boxes (ISModalDialog, ISTextBox,
--    the padlock code, alarm and bomb timers, rich-text notes, the animal zone
--    note, the death screen) are ISPanelJoypad panels that never set
--    moveWithMouse, or set it only after addToUIManager (the MP trade,
--    safehouse, faction and medical-check requests), so they could not be
--    answered. They count by class, whatever their size, and a window that
--    becomes draggable a moment after opening is caught by a late check. One
--    that opens over the hub closes the hub so it is not buried under it.
--

require "ISUI/ISUIElement"
require "ViewpointUI/Core"
require "ViewpointUI/Settings"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
if VPUI.Legacy then return end

local Legacy = {}
VPUI.Legacy = Legacy

local Log = VPUI.Log
local Bridge = VPUI.Bridge
print("[PROJECT ECHO][CursorHUDCompat v0.1.0] ViewpointUI 0.13.2 Legacy override active; TM42_MiniTracker will not hold free cursor")

-- Set by the controller every tick.
Legacy.active = false

local function isKey(id, key)
    local ok, v = pcall(function() return getCore():isKey(id, key) end)
    return ok and v == true
end

-- Returns the tab a vanilla window key maps to, or nil.
function Legacy.tabForKey(key, player)
    if isKey(KeybindId.TOGGLE_INVENTORY, key) then
        -- left to the game's windows (inventory mods)
        if VPUI.Settings.get("vanillaInventory") == true then return nil end
        return "inventory"
    end
    if isKey(KeybindId.CRAFTING_UI, key) then return "crafting" end
    if isKey(KeybindId.BUILDING_UI, key) then return "build" end
    if isKey(KeybindId.TOGGLE_SKILL_PANEL, key) then return "skills" end
    if isKey(KeybindId.TOGGLE_HEALTH_PANEL, key) then return "health" end
    if isKey(KeybindId.TOGGLE_INFO_PANEL, key) then return "character" end
    if isKey(KeybindId.TOGGLE_CLOTHING_PROTECTION_PANEL, key) then return "character" end
    if player and player:getVehicle() and isKey(KeybindId.VEHICLE_SWITCH_SEAT, key) then return "vehicle" end
    return nil
end

local function redirect(key, onlyTab)
    if not Legacy.active then return false end
    local player = VPUI.Util.player()
    if not player then return false end
    local tab = Legacy.tabForKey(key, player)
    if not tab or (onlyTab and tab ~= onlyTab) then return false end
    -- workaround option: the game's own crafting window, with the cursor freed
    if tab == "crafting" and VPUI.Settings.get("vanillaCrafting") == true then return "vanilla" end
    -- the same for health when a mod replaces the game's health panel
    if tab == "health" and VPUI.Settings.vanillaHealth() then return "vanilla" end
    -- the open screen handles its own keys (isKeyConsumed); only act when closed
    if not VPUI.Hub.isOpen() then VPUI.Hub.open(tab) end
    return true
end
Legacy.redirect = redirect

-- Replaces a registered key handler with a wrapper that redirects first.
local function wrap(eventName, owner, field, onlyTab)
    local original = owner and owner[field]
    if type(original) ~= "function" then
        Log.warn("legacy redirect: " .. tostring(field) .. " not found; that key keeps its vanilla window")
        return
    end
    local event = Events[eventName]
    event.Remove(original)
    local wrapped = function(key, ...)
        local ok, handled = pcall(redirect, key, onlyTab)
        if ok and handled == "vanilla" then
            local args = { ... }
            Legacy.openWindow(function() original(key, unpack(args)) end)
            return
        end
        if ok and handled then return end
        return original(key, ...)
    end
    owner[field] = wrapped
    event.Add(wrapped)
end

local installed = false
function Legacy.install()
    if installed then return end
    installed = true
    wrap("OnKeyPressed", ISInventoryPage, "onKeyPressed")
    wrap("OnKeyPressed", xpUpdate, "displayCharacterInfo")
    -- OnKeyStartPressed fires on key down; the hub's own key handling acts on
    -- release, so only the seat key (which has no release handler) goes here.
    wrap("OnKeyStartPressed", ISVehicleMenu, "onKeyStartPressed", "vehicle")
    Log.info("legacy key redirects installed")
end

-- Our own keys (build mode, admin) while the screen is closed.
Events.OnKeyPressed.Add(function(key)
    if not Legacy.active or VPUI.Hub.isOpen() then return end
    local build = VPUI.Settings.get("buildKey")
    local admin = VPUI.Settings.get("adminKey")
    if build and build > 0 and key == build then
        local BuildMode = VPUI.Building and VPUI.Building.BuildMode
        if BuildMode and BuildMode.isActive() then return end
        if BuildMode and BuildMode.swallowBuildKey then
            BuildMode.swallowBuildKey = false   -- this release ended build mode
            return
        end
        VPUI.Hub.open("build")
    elseif admin and admin > 0 and key == admin then
        VPUI.Hub.open("admin")
    end
end)

Events.OnGameStart.Add(Legacy.install)

---------------------------------------------------------------------------
-- Fallback windows and the cursor
---------------------------------------------------------------------------

local watching = {}        -- vanilla windows opened through us
local pendingUntil = 0     -- windows added before this time are ours
local managing = false     -- a window (or one of our screens) is up and the cursor is ours
local freedByUs = false    -- ... and it was captured when we took it over
local heldForWindow = false -- a window, not only a screen of ours, is a reason

-- Other mods' windows: element -> true (weak), and the ones that may free the
-- cursor this activation (seen closed, or added, while the view was on).
-- (Kahlua has no weak tables: entries leave when the window is removed from
-- the UI manager, see the removeFromUIManager wrap below.)
local others = {}
local armed = {}
-- The game's own dialogs among `others` (see dialogClasses): they free the
-- cursor whatever the "other mods' windows" option says, since they ask a
-- question that cannot be answered otherwise.
local dialogs = {}
-- Counted windows seen visible last tick (one that becomes visible while the
-- hub is open closes the hub, so it is not buried under the capture screen).
local shown = {}
-- Top-level elements not counted when added: { el, at, active }, re-checked
-- once ~100 ms later for a moveWithMouse set after addToUIManager (the MP
-- request dialogs: ISTradingUI.ReceiveTradeRequest, ISSafehouseUI.
-- ReceiveSafehouseInvite, ISFactionUI.ReceiveFactionInvite and ISHealthPanel.
-- ReceiveMedicalCheckRequest all set `modal.moveWithMouse = true` after
-- `modal:addToUIManager()`).
local pending = {}
local PENDING_MAX = 32
local LATE_CHECK_MS = 100

local function derives(obj, class)
    if type(obj) ~= "table" or type(class) ~= "table" then return false end
    local t = getmetatable(obj)
    for _ = 1, 40 do
        if t == nil then return false end
        if t == class then return true end
        t = getmetatable(t)
    end
    return false
end
Legacy.derives = derives

-- Windows left alone on purpose: handled elsewhere in this add-on (the radial
-- menu by RadialAim, the inventory pages by VanillaHUD / alwaysFree, the
-- minimap opened by VanillaHUD.minimap: ISMiniMapOuter / ISMiniMapInner,
-- client/ISUI/Maps/ISMiniMap.lua) or part of the game's chrome. Checked by
-- name as well as by class (ISMiniMapOuter = ISPanelJoypad:derive(...),
-- ISMiniMapInner = ISUIElement:derive(...); Type is the derive name).
-- PROJECT ECHO: TM42_MiniTracker is a persistent mission HUD, not a modal window.
-- Let Viewpoint keep mouse-look while it is visible. Other windows keep
-- their original cursor behavior; middle mouse can free the cursor manually.
local handledTypes = { ISMiniMapOuter = true, ISMiniMapInner = true, TM42_MiniTracker = true }

-- The game's dialogs that need the cursor whatever their size and whether or
-- not they can be dragged (ISPanelJoypad:derive, none sets moveWithMouse in
-- :new, all client/ISUI/):
--   ISModalDialog (ISModalDialog.lua; `o.moveWithMouse = false` in :new, the
--     MP request dialogs set it true only after addToUIManager), ISTextBox
--     (ISTextBox.lua: naming bags, maps, food, renames; its own drag code),
--     ISDigitalCode (ISDigitalCode.lua: padlocks), ISAlarmClockDialog,
--     ISBombTimerDialog, ISModalRichText, ISAnimalZoneFirstInfo
--     (Animal/ISAnimalZoneFirstInfo.lua), ISPostDeathUI (ISPostDeathUI.lua:
--     Respawn / Exit / Quit buttons on a full-screen panel).
-- Resolved on each call: a class a build does not have is nil and left out
-- (a nil in the middle of a list would stop ipairs early).
local function dialogClasses()
    local list = {}
    for _, class in pairs({ ISModalDialog, ISTextBox, ISDigitalCode, ISAlarmClockDialog, ISBombTimerDialog,
                            ISModalRichText, ISAnimalZoneFirstInfo, ISPostDeathUI }) do
        if type(class) == "table" then table.insert(list, class) end
    end
    return list
end

-- Returns (isOther, handledElsewhere, isDialog): a second true means the
-- window is one this add-on deals with on purpose, so it is not worth a "left
-- alone" note; a third true means one of the game's dialogs above.
local function isOtherWindow(el)
    if el.parent ~= nil then return false, false end
    local t = tostring(el.Type or "")
    if string.sub(t, 1, 2) == "VP" then return false, true end
    if string.find(t, "ToolTip", 1, true) or string.find(t, "Tooltip", 1, true) then return false, true end
    if handledTypes[t] then return false, true end
    for _, class in ipairs({ ISChat, ISInventoryPage, ISContextMenu, ISRadialMenu, ISEquippedItem, MainScreen,
                             ISMiniMapOuter, ISMiniMapInner }) do
        if class and derives(el, class) then return false, true end
    end
    for _, class in ipairs(dialogClasses()) do
        if derives(el, class) then return true, false, true end
    end
    if ISCollapsableWindow and derives(el, ISCollapsableWindow) then return true end
    if ISCollapsableWindowJoypad and derives(el, ISCollapsableWindowJoypad) then return true end
    -- Many of the game's own windows are plain panels the player drags around
    -- (ISAdminPanelUI = ISPanel:derive, moveWithMouse = true; 48 such panels in
    -- the vanilla UI). They count too, when window-sized: small draggable boxes
    -- are usually HUD widgets that stay up for good, and a free cursor makes
    -- Viewpoint aim at nothing (no door prompts). Each one that frees the cursor
    -- is named once in the console.
    if el.moveWithMouse == true then
        local w, h = tonumber(el.width) or 0, tonumber(el.height) or 0
        return w >= 200 and h >= 150
    end
    return false
end
Legacy.isOtherWindow = isOtherWindow

local function describe(el)
    local t = tostring(el.Type or "?")
    local title = el.title or el.name
    if title and tostring(title) ~= "" then t = t .. " \"" .. tostring(title) .. "\"" end
    return t
end

-- True for a window-sized panel the player can drag (the rule isOtherWindow
-- applies to plain panels), read again later for flags set after adding.
local function draggableWindow(el)
    if el.moveWithMouse ~= true then return false end
    local w, h = tonumber(el.width) or 0, tonumber(el.height) or 0
    return w >= 200 and h >= 150
end

-- A top-level element not counted when it was added: looked at once more a
-- moment later (Legacy.tick), in case its opener set moveWithMouse afterwards.
local function addPending(el)
    for _, p in ipairs(pending) do if p.el == el then return end end
    if #pending >= PENDING_MAX then table.remove(pending, 1) end
    table.insert(pending, { el = el, at = getTimestampMs(), active = Legacy.active })
end

local function dropPending(el)
    for i = #pending, 1, -1 do
        if pending[i].el == el then table.remove(pending, i) end
    end
end

-- Remember top-level vanilla windows added while an opener is pending.
local originalAdd = ISUIElement.addToUIManager
function ISUIElement:addToUIManager()
    local okW, other, handled, dialog = pcall(isOtherWindow, self)
    if okW and other then
        others[self] = true
        -- a dialog is never a pinned overlay: it counts even when it was
        -- opened before the view came on
        if Legacy.active or dialog then armed[self] = true end
        if dialog then dialogs[self] = true end
    elseif okW and not handled and self.parent == nil then
        pcall(addPending, self)
        if Legacy.active then
            -- for reports like "this window can't be dragged": name what was left alone
            pcall(function()
                local t = tostring(self.Type or "")
                if t == "" or string.sub(t, 1, 2) == "VP" or string.find(t, "ool[Tt]ip") or string.find(t, "ContextMenu", 1, true) then return end
                Log.once(Log.WARN, "leftAlone:" .. t, "a window opened that does not free the cursor (middle mouse frees it): "
                    .. describe(self) .. " " .. tostring(self.width) .. "x" .. tostring(self.height)
                    .. (self.moveWithMouse == true and " draggable" or ""))
            end)
        end
    end
    if pendingUntil > 0 and getTimestampMs() <= pendingUntil and self.parent == nil then
        local t = tostring(self.Type or "")
        if string.sub(t, 1, 2) ~= "VP" and not string.find(t, "ToolTip", 1, true) and not string.find(t, "ContextMenu", 1, true) then
            table.insert(watching, self)
        end
    end
    return originalAdd(self)
end

local originalRemove = ISUIElement.removeFromUIManager
function ISUIElement:removeFromUIManager()
    others[self] = nil
    armed[self] = nil
    dialogs[self] = nil
    shown[self] = nil
    pcall(dropPending, self)
    return originalRemove(self)
end

-- The late check: an element added `LATE_CHECK_MS` ago that is draggable and
-- window-sized by now counts as another window from here on.
local function checkPending(now)
    for i = #pending, 1, -1 do
        local p = pending[i]
        if now - p.at >= LATE_CHECK_MS then
            table.remove(pending, i)
            local el = p.el
            local ok, late = pcall(function() return el.parent == nil and draggableWindow(el) end)
            if ok and late then
                others[el] = true
                if p.active or Legacy.active then armed[el] = true end
                pcall(function()
                    Log.once(Log.INFO, "lateWindow:" .. tostring(el.Type or "?"),
                        "a window became draggable after opening, so it frees the cursor: " .. describe(el))
                end)
            end
        end
    end
end

-- Opens a vanilla window through `opener`. Windows it creates (now or, for timed
-- actions such as walking to a hood, within `waitMs`) free the cursor while shown.
function Legacy.openWindow(opener, waitMs)
    pendingUntil = getTimestampMs() + (waitMs or 2000)
    local ok, err = pcall(opener)
    if not ok then Log.error("opening a game window failed: " .. tostring(err)) end
end

local function visible(el)
    local ok, v = pcall(function() return el:isReallyVisible() end)
    return ok and v == true
end

-- The death screen (ISPostDeathUI.instance[playerIndex], set in :new and
-- :prerender, client/ISUI/ISPostDeathUI.lua): its Respawn / Exit / Quit
-- buttons need the mouse. The controller stands down once the player is dead,
-- so Legacy.deathTick frees the cursor for it on its own.
local function deathScreen()
    if ISPostDeathUI and type(ISPostDeathUI.instance) == "table" then return ISPostDeathUI.instance[0] end
    return nil
end
Legacy.deathScreen = deathScreen

-- Game windows that always need the cursor when shown in Viewpoint's view,
-- whoever opened them (the world map from its own key).
Legacy.alwaysFree = {
    function() return ISWorldMap and ISWorldMap.instance end,
    function() return ISVehicleMechanics and getPlayerMechanicsUI and getPlayerMechanicsUI(0) end,
    -- the game's inventory windows, when they are used instead of the Viewpoint
    -- inventory (VanillaHUD hides them when the view comes on)
    function() return VPUI.Settings.get("vanillaInventory") == true and getPlayerInventory and getPlayerInventory(0) end,
    function() return VPUI.Settings.get("vanillaInventory") == true and getPlayerLoot and getPlayerLoot(0) end,
    deathScreen,
}

-- Per tick: does any other mod's window (or one of the game's dialogs) want
-- the cursor? One that has just come up while the hub is open closes the hub,
-- so it is not buried under the capture screen; the cursor stays free for it
-- (Hub.close does not touch Viewpoint's cursor mode, Legacy.tick does).
local function otherWindowOpen()
    local option = VPUI.Settings.get("freeCursorWindows") == true
    local any = false
    for el in pairs(others) do
        if visible(el) then
            if armed[el] and (option or dialogs[el]) then
                if not any then
                    local okD, d = pcall(describe, el)
                    Log.once(Log.WARN, "freeFor:" .. tostring(okD and d or el),
                        (dialogs[el] and "a game dialog is open" or "another mod's window is open")
                        .. ", so the cursor is free (and Viewpoint aims at nothing until it closes): "
                        .. tostring(okD and d or "?"))
                end
                any = true
                if not shown[el] then
                    shown[el] = true
                    if VPUI.Hub and VPUI.Hub.isOpen() then
                        local okD, d = pcall(describe, el)
                        Log.info("closing the screen for a window that opened over it: " .. tostring(okD and d or "?"))
                        VPUI.Hub.close()
                    end
                end
            end
        else
            armed[el] = true   -- closed while the view is on: its next opening counts
            shown[el] = nil
        end
    end
    return any
end

-- Per tick from the controller.
function Legacy.tick(now)
    if pendingUntil > 0 and now > pendingUntil then pendingUntil = 0 end
    pcall(checkPending, now)
    local any = false
    for _, find in ipairs(Legacy.alwaysFree) do
        local ok, el = pcall(find)
        if ok and el and visible(el) then any = true end
    end
    for i = #watching, 1, -1 do
        if visible(watching[i]) then any = true
        elseif pendingUntil == 0 then table.remove(watching, i) end
    end
    local okO, open = pcall(otherWindowOpen)
    if okO and open then any = true end
    -- One of this interface's own screens is up: it is a capture screen, so the
    -- game reports a modal and Viewpoint frees the cursor for it on its own
    -- (viewpoint.FP.viewInput: wantCapture = !cursorMode && !dead &&
    -- !UIManager.isModalVisible()). That is a signal we do not own, and a single
    -- frame in which it reads false captures the cursor; see the note below for
    -- what that costs. Claiming the cursor outright while a screen is open takes
    -- that frame out of the picture.
    local hubOpen = VPUI.Hub and VPUI.Hub.isOpen and VPUI.Hub.isOpen() == true
    if any or hubOpen then
        -- Only a cursor we captured is ours to give back: setCursorFree just
        -- writes Viewpoint's cursor mode and reports true whatever it was, so
        -- the player's own free cursor (middle mouse) is read first and left
        -- alone, as UI/PauseCursor.lua does.
        if not managing then
            managing = true
            freedByUs = Bridge.call("cursorFree", false) ~= true
        end
        if any then heldForWindow = true end
        -- Written every tick the window is up, not only on the tick it opened.
        -- Whenever Viewpoint lets capture go it warps the pointer to the middle
        -- of the screen (input/Look.onUpdateMouseCursor: glfwSetInputMode(NORMAL)
        -- then glfwSetCursorPos(width / 2, height / 2)), so anything that takes
        -- the cursor back for even one tick while a window is open - a context
        -- menu opening and closing, Viewpoint's own loot menu, another add-on -
        -- used to cost one jump to the middle of the screen, over and over while
        -- you worked through a list of items. Re-asserting it the same tick means
        -- the capture never lands and the pointer stays where the player left it.
        if Bridge.call("cursorFree", false) ~= true then
            Bridge.call("setCursorFree", false, true)
            Log.once(Log.INFO, "cursorReclaimed",
                "something else captured the mouse cursor while a window was open; it was freed again the same tick")
        end
    elseif managing and (pendingUntil == 0 or not heldForWindow) then
        -- pendingUntil holds the cursor for a window that has not appeared yet
        -- (walking to a car hood); one of our own screens closing is not that,
        -- so it gives the cursor back at once.
        managing = false
        heldForWindow = false
        if freedByUs then Bridge.call("setCursorFree", false, false) end
        freedByUs = false
    end
end

-- Mod ids that look like an inventory overhaul (a hint only: nothing is
-- switched without the player).
function Legacy.inventoryMods()
    local found = {}
    local ok, list = pcall(getActivatedMods)
    if not ok or not list then return found end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i))
        local low = string.lower(id)
        if string.find(low, "inventor", 1, true) and not string.find(low, "viewpoint", 1, true) then
            table.insert(found, id)
        end
    end
    return found
end

function Legacy.reset()
    watching = {}
    pendingUntil = 0
    armed = {}
    shown = {}
    -- only a cursor freed here is captured again (see Legacy.tick)
    managing = false
    heldForWindow = false
    if freedByUs then
        Bridge.call("setCursorFree", false, false)
        freedByUs = false
    end
    -- the dialogs stay armed: they are never pinned overlays
    for el in pairs(dialogs) do armed[el] = true end
end

---------------------------------------------------------------------------
-- The death screen
---------------------------------------------------------------------------

-- Once the player is dead, Util.player() is nil and the controller stands
-- down (Legacy.reset above), so Legacy.tick no longer runs; the game's
-- ISPostDeathUI (Respawn / Exit / Quit) would sit under a captured cursor.
-- This runs on its own tick while the view is on and the panel is shown, and
-- gives the cursor back the same way Legacy.tick does when it goes
-- (ISPostDeathUI:onRespawn only hides the panel, it stays in the UI manager).
local deathFreed = false
function Legacy.deathTick()
    if not Bridge.ready() then return end
    local shownNow = false
    if Bridge.viewOn() then
        local okP, p = pcall(getSpecificPlayer, 0)
        local dead = okP and p ~= nil and p:isDead() == true
        if dead then
            local okE, el = pcall(deathScreen)
            shownNow = okE and el ~= nil and visible(el)
        end
    end
    if shownNow and not deathFreed then
        if Bridge.call("cursorFree", false) ~= true then
            Bridge.call("setCursorFree", false, true)
            deathFreed = true
        end
    elseif not shownNow and deathFreed then
        Bridge.call("setCursorFree", false, false)
        deathFreed = false
    end
end

Events.OnTickEvenPaused.Add(function()
    local ok, err = pcall(Legacy.deathTick)
    if not ok then Log.once(Log.ERROR, "deathTick", "death screen cursor failed: " .. tostring(err)) end
end)
