--
-- Viewpoint UI - public extension API for other mods.
--
-- Stable entry points (everything else under ViewpointUI is internal):
--
--   ViewpointUI.Interactions.register(provider)   see Interaction/Registry.lua
--   ViewpointUI.Interactions.unregister(id)
--   ViewpointUI.Interactions.current()            -> target, resolved  (read-only)
--   ViewpointUI.Events.add(name, fn) / remove(name, fn)
--       "TargetChanged"   (newTarget|nil, oldTarget|nil)
--       "ActionsResolved" (target, resolved)
--       "MenuOpened"      (resolved)
--       "MenuClosed"      ()
--       "ActionRun"       (action, target)
--       "SettingsChanged" ()
--       "LayoutChanged"   ()
--   ViewpointUI.UI.toast(message, seconds, danger)
--   ViewpointUI.UI.VPElement / VPPrompt / VPActionMenu / VPProgressBar / VPReticle / VPToast
--   ViewpointUI.UI.Theme
--   ViewpointUI.isActive()
--   ViewpointUI.Log
--   ViewpointUI.Hub.register(tab) / open(id, args) / close() / isOpen()
--       add a full-screen tab (see UI/Screen.lua for the tab fields)
--   ViewpointUI.Inventory.Actions   move / takeAll / equip / wear / itemMenu ...
--   ViewpointUI.Building.BuildMode  start(player, buildLogic) / stop() / isActive()
--   ViewpointUI.Util.Harvest        run a game context-menu builder and read it
--       "HubOpened" / "HubClosed" / "HubTabOpened" (id)
--       "BuildModeStarted" (recipe) / "BuildModeStopped"
--
-- Example: a radio mod adding "Tune to 98.2" when aiming at its radio object.
--
--   ViewpointUI.Interactions.register({
--       id = "myradio.tune",
--       priority = 10,
--       collect = function(target, player, add)
--           local obj = target.object
--           if obj and instanceof(obj, "IsoWaveSignal") then
--               add({ label = "Tune to 98.2", primary = false,
--                     run = function(p) MyRadio.queueTune(p, obj, 98200) end })
--           end
--       end,
--   })
--
-- Admin actions: register a tab with visible = function(player) return
-- ViewpointUI.Screens.Admin.isStaff(player) end, or call into
-- ViewpointUI.Screens.Admin.can(player, Capability.X) for capability gates.
--

require "ViewpointUI/Core"
require "ViewpointUI/Interaction/Registry"
require "ViewpointUI/Controller"

local VPUI = ViewpointUI
if VPUI.Interactions then return end

local Registry = VPUI.Interaction.Registry

VPUI.Interactions = {
    register = Registry.register,
    unregister = Registry.unregister,
    current = function() return VPUI.Controller.current() end,
}

VPUI.UI = VPUI.UI or {}
VPUI.UI.toast = function(message, seconds, danger)
    VPUI.Controller.toast(tostring(message), seconds, danger)
end

VPUI.isActive = function()
    return VPUI.Controller.isActive()
end
