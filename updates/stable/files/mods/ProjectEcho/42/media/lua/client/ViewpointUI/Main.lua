--
-- Viewpoint UI - boot. Wires the controller to the game's events and keeps a
-- failing tick from taking the game's input down with it.
--

require "ViewpointUI/Core"
require "ViewpointUI/Settings"
require "ViewpointUI/Text"
require "ViewpointUI/Bridge"
require "ViewpointUI/Controller"
require "ViewpointUI/Legacy"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Inventory/Model"
require "ViewpointUI/Inventory/Actions"
require "ViewpointUI/Screens/InventoryTab"
require "ViewpointUI/Screens/CraftingTab"
require "ViewpointUI/Screens/BuildTab"
require "ViewpointUI/Screens/HealthTab"
require "ViewpointUI/Screens/CharacterTabs"
require "ViewpointUI/Screens/VehicleTab"
require "ViewpointUI/Screens/AdminTab"
require "ViewpointUI/API"
require "ViewpointUI/UI/PauseCursor"
require "ViewpointUI/UI/RadialAim"
require "ViewpointUI/UI/ToggleUI"
require "ViewpointUI/UI/DeviceMedia"

local VPUI = ViewpointUI
if VPUI.booted then return end
VPUI.booted = true

local Log = VPUI.Log
local MAX_ERRORS = 5
local errors = 0
local stopped = false

local pauseFailed = false

local function pauseTick()
    -- the pause-menu cursor is independent of the interface (and its errors);
    -- it runs after the controller so nothing in this tick undoes it
    if pauseFailed then return end
    local okP, errP = pcall(VPUI.UI.PauseCursor.tick)
    if not okP then
        pauseFailed = true
        Log.error("pause menu cursor failed: " .. tostring(errP))
    end
end

local function controllerTick()
    if stopped then return end
    local ok, err = pcall(VPUI.Controller.tick)
    if ok then
        errors = 0
        return
    end
    errors = errors + 1
    Log.error("tick failed (" .. tostring(errors) .. "): " .. tostring(err))
    pcall(VPUI.Controller.reset)
    if errors >= MAX_ERRORS then
        stopped = true
        pcall(VPUI.Bridge.releaseAll)
        Log.error("stopped after " .. tostring(MAX_ERRORS) .. " failed ticks in a row; the game's own input is back")
        pcall(VPUI.Controller.toast, VPUI.Text.disabledAfterErrors, 8, true)
    end
end

local function gameStart()
    Log.info("Viewpoint Interface " .. VPUI.VERSION .. " starting")
    local okT, errT = pcall(VPUI.UI.ToggleUI.install)
    if not okT then Log.error("Toggle UI support failed to install: " .. tostring(errT)) end
    if VPUI.Settings.get("enabled") ~= true then return end
    -- another inventory mod: point at the option that leaves the inventory to it
    if VPUI.Settings.get("vanillaInventory") ~= true then
        local okM, mods = pcall(VPUI.Legacy.inventoryMods)
        if okM and #mods > 0 then
            Log.warn("inventory mod(s) active: " .. table.concat(mods, ", ") .. "; turn on 'Use the game's inventory windows' to use them in first person")
            VPUI.Controller.toast(string.format(VPUI.Text.inventoryModHint, mods[1]), 10, false)
        end
    end
    if VPUI.Native == nil then
        VPUI.Controller.toast(VPUI.Text.javaMissing, 10, true)
    elseif not VPUI.Bridge.ready() then
        VPUI.Controller.toast(VPUI.Text.bridgeFailed, 8, true)
    end
end

Events.OnGameStart.Add(gameStart)
local radialFailed = false

local function radialTick()
    if radialFailed then return end
    local ok, err = pcall(VPUI.UI.RadialAim.tick, not stopped and VPUI.Controller.isActive())
    if not ok then
        radialFailed = true
        Log.error("radial menu steering failed: " .. tostring(err))
    end
end

local toggleFailed = false

local function toggleTick()
    if toggleFailed then return end
    local ok, err = pcall(function()
        -- no hidden search box of ours may keep the keyboard (see Screen.lua)
        VPUI.Hub.releaseFocus()
        if VPUI.Settings.get("enabled") == true then VPUI.UI.ToggleUI.tick() end
    end)
    if not ok then
        toggleFailed = true
        Log.error("Toggle UI check failed: " .. tostring(err))
    end
end

local function tick()
    controllerTick()
    pauseTick()
    radialTick()
    toggleTick()
end

Events.OnTickEvenPaused.Add(tick)
Events.OnPlayerDeath.Add(function(player)
    if player and player:isLocalPlayer() then
        pcall(VPUI.Hub.reset)
        pcall(VPUI.Controller.reset)
    end
end)
