--
-- Viewpoint UI - target resolution.
--
-- Viewpoint already solves "what is the player aiming at" in Java every frame:
-- a camera ray, reach limits, line of sight and its own outline of the target
-- (viewpoint.interact.LootTargets, driven by its loot menu). This module reads
-- that answer through the bridge instead of casting a second, cheaper and less
-- accurate ray in Lua, so both views (first and third person) agree with the
-- outline the player sees.
--
-- Reading costs a handful of field reads per tick; the expensive part (building
-- the action list) only reruns when the target or its harvested actions change.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/Interaction/NPC"

local VPUI = ViewpointUI
VPUI.Interaction = VPUI.Interaction or {}
if VPUI.Interaction.Target then return end

local Bridge = VPUI.Bridge
local Log = VPUI.Log

local Target = {}
VPUI.Interaction.Target = Target

-- The live target, or nil. Fields:
--   kind, kindName   Viewpoint's target kind (see Bridge.KIND)
--   object           IsoObject / BaseVehicle / IsoDeadBody / character, may be nil (ground)
--   square           IsoGridSquare
--   loot             true when Viewpoint's loot panel lists items for it
--   locked           Viewpoint judged it locked
--   containers       number of item containers Viewpoint found on it
--   key              identity used to detect a change
local current = nil

local function identity(kind, object, square)
    -- Objects and squares are Java userdata; tostring gives a stable identity
    -- for the life of the object, which is all a change check needs.
    return tostring(kind) .. "|" .. tostring(object) .. "|" .. tostring(square)
end

function Target.get()
    return current
end

-- A character from an NPC mod under the crosshair, when NPC mods gave it
-- right-click entries (see Interaction/NPC.lua). Viewpoint's own person target
-- (a real player) is left to Viewpoint.
local function npcTarget(kind)
    if kind == Bridge.KIND.PERSON or kind == Bridge.KIND.VEHICLE then return nil end
    if VPUI.Settings and VPUI.Settings.interactStyle and VPUI.Settings.interactStyle() == "vanilla" then return nil end
    local player = VPUI.Util.player()
    if not player then return nil end
    local NPC = VPUI.Interaction.NPC
    local npc = NPC.aimedCached(player)
    if not npc then return nil end
    local res = NPC.actions(player, npc)
    if not res or #res.list == 0 then return nil end
    local square = npc:getCurrentSquare()
    local key = identity(NPC.KIND, npc, nil)
    if current and current.key == key then
        current.square = square
        return current
    end
    return { kind = NPC.KIND, kindName = "npc", object = npc, square = square,
             loot = false, locked = false, containers = 0, key = key }
end

-- Reads Viewpoint's target. Fires "TargetChanged" (new, old) on change.
function Target.update()
    local kind = Bridge.call("targetKind", -1)
    local nextTarget = npcTarget(kind)
    if nextTarget and current == nextTarget then return current end
    if nextTarget then
        -- an NPC in front wins over what is behind it
    elseif kind >= 0 then
        local object = Bridge.call("targetObject", nil)
        local square = Bridge.call("targetSquare", nil)
        local key = identity(kind, object, square)
        if current and current.key == key then
            current.loot = Bridge.call("targetIsLoot", false) == true
            current.locked = Bridge.call("targetLocked", false) == true
            current.containers = Bridge.call("targetContainerCount", 0)
            return current
        end
        nextTarget = {
            kind = kind,
            kindName = Bridge.KIND_NAME[kind] or tostring(kind),
            object = object,
            square = square,
            loot = Bridge.call("targetIsLoot", false) == true,
            locked = Bridge.call("targetLocked", false) == true,
            containers = Bridge.call("targetContainerCount", 0),
            key = key,
        }
    end
    if nextTarget == nil and current == nil then return nil end
    local old = current
    current = nextTarget
    if current then
        Log.debug("target " .. current.kindName .. " " .. tostring(current.object or current.square)
            .. (current.loot and " (loot)" or ""))
    else
        Log.trace("target cleared")
    end
    VPUI.Events.fire("TargetChanged", current, old)
    return current
end

function Target.clear()
    if current then
        local old = current
        current = nil
        VPUI.Events.fire("TargetChanged", nil, old)
    end
end
