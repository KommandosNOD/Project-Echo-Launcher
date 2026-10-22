-- PROJECT ECHO - Hide Zombie Interaction Menu, v1.0.0 (B42.21 MP)
-- Client-only compatibility patch for ViewpointUI 0.13.1.
-- Filters the ViewpointUI action list for IsoZombie targets (native PERSON
-- and ViewpointUI NPC adapter). No changes to Workshop/Java/server files.
-- IsoDeadBody, players, vehicles, doors and other world objects are unaffected.

require "ViewpointUI/Interaction/Registry"

local VPUI = ViewpointUI
local registry = VPUI and VPUI.Interaction and VPUI.Interaction.Registry
if not registry or type(registry.resolve) ~= "function" then
    print("[PROJECT ECHO][HideZombieInteraction] ViewpointUI Registry missing; patch not installed")
    return
end

-- Avoid installing the wrapper twice on a Lua reload.
if registry._PEHideZombieInteractionInstalled then return end

local originalResolve = registry.resolve
local KIND = VPUI.Bridge and VPUI.Bridge.KIND or {}

local function isZombieTarget(target)
    if not target or not target.object then return false end
    -- PERSON = target from Viewpoint Java; NPC = character adapter.
    -- Do NOT filter BODY: corpses are IsoDeadBody with normal loot actions.
    local kind = target.kind
    if kind ~= (KIND.PERSON or 6) and kind ~= (KIND.NPC or 100) then
        return false
    end
    -- instanceof works on Java userdata. Fail open for unknown modded objects.
    local ok, zombie = pcall(instanceof, target.object, "IsoZombie")
    return ok and zombie == true
end

registry.resolve = function(target, player, ...)
    if isZombieTarget(target) then
        -- ViewpointUI Controller only displays a prompt/list when actions exist.
        -- This also avoids harvesting unnecessary actions on a zombie.
        return { actions = {}, primary = nil, blocked = nil, title = nil }
    end
    return originalResolve(target, player, ...)
end
registry._PEHideZombieInteractionInstalled = true
print("[PROJECT ECHO][HideZombieInteraction] v1.0.0 active: IsoZombie menus hidden (PERSON/NPC); corpses untouched")
