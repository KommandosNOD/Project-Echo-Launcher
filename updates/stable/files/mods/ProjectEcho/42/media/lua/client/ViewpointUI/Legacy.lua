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
local freedByUs = false

-- Other mods' windows: element -> true (weak), and the ones that may free the
-- cursor this activation (seen closed, or added, while the view was on).
-- (Kahlua has no weak tables: entries leave when the window is removed from
-- the UI manager, see the removeFromUIManager wrap below.)
local others = {}
local armed = {}

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

local function isOtherWindow(el)
    if el.parent ~= nil then return false end
    local t = tostring(el.Type or "")
    if string.sub(t, 1, 2) == "VP" then return false end
    if string.find(t, "ToolTip", 1, true) or string.find(t, "Tooltip", 1, true) then return false end
    for _, class in ipairs({ ISChat, ISInventoryPage, ISContextMenu, ISRadialMenu, ISEquippedItem, MainScreen }) do
        if class and derives(el, class) then return false end
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

local function describe(el)
    local t = tostring(el.Type or "?")
    local title = el.title or el.name
    if title and tostring(title) ~= "" then t = t .. " \"" .. tostring(title) .. "\"" end
    return t
end

-- Remember top-level vanilla windows added while an opener is pending.
local originalAdd = ISUIElement.addToUIManager
function ISUIElement:addToUIManager()
    local okW, other = pcall(isOtherWindow, self)
    if okW and other then
        others[self] = true
        if Legacy.active then armed[self] = true end
    elseif okW and Legacy.active and self.parent == nil then
        -- for reports like "this window can't be dragged": name what was left alone
        pcall(function()
            local t = tostring(self.Type or "")
            if t == "" or string.sub(t, 1, 2) == "VP" or string.find(t, "ool[Tt]ip") or string.find(t, "ContextMenu", 1, true) then return end
            Log.once(Log.WARN, "leftAlone:" .. t, "a window opened that does not free the cursor (middle mouse frees it): "
                .. describe(self) .. " " .. tostring(self.width) .. "x" .. tostring(self.height)
                .. (self.moveWithMouse == true and " draggable" or ""))
        end)
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
    return originalRemove(self)
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

-- Game windows that always need the cursor when shown in Viewpoint's view,
-- whoever opened them (the world map from its own key).
Legacy.alwaysFree = {
    function() return ISWorldMap and ISWorldMap.instance end,
    function() return ISVehicleMechanics and getPlayerMechanicsUI and getPlayerMechanicsUI(0) end,
    -- the game's inventory windows, when they are used instead of the Viewpoint
    -- inventory (VanillaHUD hides them when the view comes on)
    function() return VPUI.Settings.get("vanillaInventory") == true and getPlayerInventory and getPlayerInventory(0) end,
    function() return VPUI.Settings.get("vanillaInventory") == true and getPlayerLoot and getPlayerLoot(0) end,
}

-- Per tick: does any other mod's window want the cursor?
local function otherWindowOpen()
    if VPUI.Settings.get("freeCursorWindows") ~= true then return false end
    local any = false
    for el in pairs(others) do
        if visible(el) then
            if armed[el] then
                if not any then
                    local okD, d = pcall(describe, el)
                    Log.once(Log.WARN, "freeFor:" .. tostring(okD and d or el),
                        "another mod's window is open, so the cursor is free (and Viewpoint aims at nothing until it closes): "
                        .. tostring(okD and d or "?"))
                end
                any = true
            end
        else
            armed[el] = true   -- closed while the view is on: its next opening counts
        end
    end
    return any
end

-- Per tick from the controller.
function Legacy.tick(now)
    if pendingUntil > 0 and now > pendingUntil then pendingUntil = 0 end
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
    if any and not freedByUs then
        if Bridge.call("setCursorFree", false, true) == true then freedByUs = true end
    elseif not any and freedByUs and pendingUntil == 0 then
        Bridge.call("setCursorFree", false, false)
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
    if freedByUs then
        Bridge.call("setCursorFree", false, false)
        freedByUs = false
    end
end
