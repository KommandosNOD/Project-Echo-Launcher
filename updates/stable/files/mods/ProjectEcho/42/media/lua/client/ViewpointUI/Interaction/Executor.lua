--
-- Viewpoint UI - action executor. Runs one resolved action, guarding against
-- a list that went stale between showing it and pressing the key.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.Interaction = VPUI.Interaction or {}
if VPUI.Interaction.Executor then return end

local Bridge = VPUI.Bridge
local Log = VPUI.Log

local Executor = {}
VPUI.Interaction.Executor = Executor

-- Returns true when the action was handed to the game.
function Executor.run(action, target, player)
    if not action or not player then return false end
    if not action.enabled then
        Log.debug("not run (unavailable): " .. tostring(action.label))
        return false
    end
    -- Actions harvested by Viewpoint are addressed by index; if Viewpoint has
    -- harvested again since the list was shown, the index may now mean
    -- something else. Refuse rather than guess.
    if action.source == "viewpoint" and action.version ~= Bridge.call("actionsVersion", -1) then
        Log.debug("not run (list changed): " .. tostring(action.label))
        return false
    end
    local ok, result = pcall(action.run, player, target)
    if not ok then
        Log.error("action '" .. tostring(action.label) .. "' from " .. tostring(action.provider) .. " failed: " .. tostring(result))
        return false
    end
    if result == false then
        Log.debug("action refused: " .. tostring(action.label))
        return false
    end
    Log.debug("ran: " .. tostring(action.label) .. " [" .. tostring(action.provider) .. "]")
    VPUI.Events.fire("ActionRun", action, target)
    return true
end
