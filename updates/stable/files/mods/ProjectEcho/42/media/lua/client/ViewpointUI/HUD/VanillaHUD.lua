--
-- Viewpoint UI - vanilla HUD hider.
--
-- While the interface is active (Viewpoint's view on, the interface enabled,
-- "Allow legacy UI" off) and "Hide the vanilla HUD" is on, the isometric
-- game's screen chrome is hidden, because the Viewpoint interface replaces it:
--
--   left sidebar (ISEquippedItem)          -> keys still work; screens via the hub
--                                             (kept with "Keep the left sidebar")
--   inventory + loot windows (ISInventoryPage) -> Viewpoint inventory
--   moodles column (Java MoodlesUI)        -> Viewpoint status readout
--                                             (kept with "Keep the game's moodles")
--   inventory windows with "Use the game's inventory windows": hidden once
--   when the view comes on, then opened and closed by the inventory key
--   hotbar (ISHotbar)                      -> Viewpoint hotbar (drawing only)
--
-- Only visibility changes: every element keeps running (key handlers, timed
-- actions, the hotbar's slots). Each element is re-hidden every tick, since the
-- game re-shows some on its own (resolution change, sidebar size option), and
-- only what this module hid is shown again when the interface stands down.
-- The minimap, the vehicle dashboard, the clock and the speed controls are
-- left alone.
--
-- APIs (verified against the game's Lua and classes):
--   getPlayerData(n).equipped / .playerInventory / .lootInventory   ISPlayerDataObject
--   UIManager.getMoodleUI(double) -> MoodlesUI extends UIElement     (setVisible/isVisible)
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.HUD = VPUI.HUD or {}
if VPUI.HUD.Vanilla then return end

local Vanilla = {}
VPUI.HUD.Vanilla = Vanilla

local Log = VPUI.Log

-- element -> true for each element this module hid while it was visible
local hiddenByUs = {}
local hiding = false

local function luaVisible(el)
    local ok, v = pcall(function() return el:getIsVisible() end)
    return ok and v == true
end

local function javaVisible(el)
    local ok, v = pcall(function() return el:isVisible() end)
    return ok and v == true
end

local function moodleUI(pn)
    local ok, ui = pcall(function() return UIManager.getMoodleUI(pn) end)
    if ok then return ui end
    return nil
end

local function hideLua(el)
    if luaVisible(el) then
        hiddenByUs[el] = "lua"
        local ok, err = pcall(function() el:setVisible(false) end)
        if not ok then Log.once(Log.WARN, "vanillaHide:" .. tostring(el.Type), "could not hide " .. tostring(el.Type) .. ": " .. tostring(err)) end
    end
end

local function hideJava(el)
    if javaVisible(el) then
        hiddenByUs[el] = "java"
        pcall(function() el:setVisible(false) end)
    end
end

-- Gives back one element this module hid (an option turned off mid-game).
local function giveBack(el)
    if el and hiddenByUs[el] then
        hiddenByUs[el] = nil
        if not VPUI.Util.uiHidden() then pcall(function() el:setVisible(true) end) end
    end
end

-- Inventory pages kept for inventory mods: hidden once when the view comes on
-- (they sit open in isometric view), then left to the inventory key.
local inventoryHiddenOnce = false

-- Per tick while the interface is active and the option is on.
-- keep: { sidebar = bool, inventory = bool, moodles = bool } - parts other
-- mods use, left to the game.
function Vanilla.hide(pn, keep)
    pn = pn or 0
    keep = keep or {}
    hiding = true
    local pd = getPlayerData and getPlayerData(pn)
    if pd then
        if pd.equipped then
            if keep.sidebar then giveBack(pd.equipped) else hideLua(pd.equipped) end
        end
        if keep.inventory then
            if not inventoryHiddenOnce then
                if pd.playerInventory then hideLua(pd.playerInventory) end
                if pd.lootInventory then hideLua(pd.lootInventory) end
                inventoryHiddenOnce = true
            end
        else
            inventoryHiddenOnce = false
            if pd.playerInventory then hideLua(pd.playerInventory) end
            if pd.lootInventory then hideLua(pd.lootInventory) end
        end
    end
    local moodles = moodleUI(pn)
    if moodles then
        if keep.moodles then giveBack(moodles) else hideJava(moodles) end
    end
    if VPUI.Perf then VPUI.Perf.count("vanillaHide") end
end

-- Shows again only what was hidden here.
function Vanilla.restore()
    if not hiding then return end
    -- with the whole UI toggled off, showing these would put them back on
    -- screen; they are shown once the UI is back
    if VPUI.Util.uiHidden() then return end
    hiding = false
    inventoryHiddenOnce = false
    for el, kind in pairs(hiddenByUs) do
        pcall(function() el:setVisible(true) end)
    end
    hiddenByUs = {}
end

function Vanilla.isHiding()
    return hiding
end

---------------------------------------------------------------------------
-- Minimap
--
-- The game opens its minimap only from the left sidebar's map button (or a
-- controller radial), and that sidebar is hidden here. So when Viewpoint's view
-- comes on the minimap is opened for you (once; close it and it stays closed
-- until the view comes on again), and when the view goes off it is closed again
-- if it was opened here. Opened with addToUIManager like ISMiniMap.ToggleMiniMap
-- does, but without changing the game's saved "MiniMap.StartVisible" choice.
-- Only where the server allows it (ISMiniMap.IsAllowed: SandboxVars.Map.AllowMiniMap).
---------------------------------------------------------------------------

local minimapChecked = false   -- done for this activation
local minimapOpenedByUs = nil

local function minimapAllowed()
    if not (ISMiniMap and ISMiniMap.IsAllowed) then return false end
    local ok, v = pcall(ISMiniMap.IsAllowed)
    return ok and v == true
end

-- Per tick while the interface is active and "Show the minimap" is on.
function Vanilla.minimap(pn)
    if minimapChecked or VPUI.Util.uiHidden() then return end
    minimapChecked = true
    if not minimapAllowed() then
        Log.once(Log.INFO, "minimapNotAllowed", "the minimap is turned off in this server's sandbox options (Map > Allow Mini-Map)")
        return
    end
    local mm = getPlayerMiniMap and getPlayerMiniMap(pn or 0)
    if not mm then return end
    local ok, err = pcall(function()
        if mm:isReallyVisible() then return end
        if not mm:getIsVisible() then mm:setVisible(true) end
        mm:addToUIManager()
        minimapOpenedByUs = mm
    end)
    if not ok then Log.once(Log.WARN, "minimapOpen", "could not open the minimap: " .. tostring(err)) end
end

-- When the interface stands down (view off, interface off, legacy UI on).
function Vanilla.minimapEnd()
    minimapChecked = false
    if minimapOpenedByUs then
        local mm = minimapOpenedByUs
        minimapOpenedByUs = nil
        pcall(function() mm:removeFromUIManager() end)
    end
end
