--
-- Viewpoint UI - bridge to the add-on's Java part (ViewpointUI.Native, exposed
-- by ZombieBuddy). Every call goes through here so a missing or failing Java
-- side turns the interface off cleanly instead of erroring every tick.
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
if VPUI.Bridge then return end

local Bridge = {}
VPUI.Bridge = Bridge

local Log = VPUI.Log
local checked, ready = false, false

-- Target kinds as Viewpoint numbers them (viewpoint.interact.LootTargets).
Bridge.KIND = {
    NONE = -1, GROUND = 0, BODY = 1, OBJECT = 2, VEHICLE = 3, THING = 4, ANIMAL = 5, PERSON = 6,
}
Bridge.KIND_NAME = {
    [-1] = "none", [0] = "ground", [1] = "body", [2] = "object", [3] = "vehicle",
    [4] = "thing", [5] = "animal", [6] = "person",
}

-- True once the Java part is loaded and found Viewpoint.
function Bridge.ready()
    if checked then return ready end
    checked = true
    local native = VPUI.Native
    if native == nil or native.available == nil then
        Log.warn("Java part not loaded. Check that ZombieBuddy is installed and that ViewpointUI was approved in its prompt.")
        ready = false
        return ready
    end
    local ok, result = pcall(native.available)
    ready = ok and result == true
    if ready then
        local okV, v = pcall(native.version)
        Log.info("Java part " .. tostring(okV and v or "?") .. " bridged to Viewpoint")
    else
        Log.warn("Java part loaded but could not bridge to Viewpoint (see [ViewpointUI] lines in console.txt)")
    end
    return ready
end

-- Calls a Native function; on failure logs once and returns the fallback.
function Bridge.call(name, fallback, a, b)
    if not Bridge.ready() then return fallback end
    local fn = VPUI.Native[name]
    if fn == nil then
        Log.once(Log.ERROR, "native-missing:" .. name, "Native." .. name .. " missing; Java and Lua parts are from different versions")
        return fallback
    end
    local ok, result
    if b ~= nil then
        ok, result = pcall(fn, a, b)
    elseif a ~= nil then
        ok, result = pcall(fn, a)
    else
        ok, result = pcall(fn)
    end
    if not ok then
        Log.once(Log.ERROR, "native-fail:" .. name, "Native." .. name .. " failed: " .. tostring(result))
        return fallback
    end
    if result == nil then return fallback end
    return result
end

function Bridge.viewOn() return Bridge.call("viewOn", false) == true end
function Bridge.thirdPerson() return Bridge.call("thirdPerson", false) == true end

-- Flags expire in Java after 0.3 s unless refreshed, so these are sent every tick.
-- Interact stays claimed from a press made while the interface owned it until
-- the key comes up: if the aim slips off the crate (or a screen opens) while E
-- is still held, the game must not see the rest of that press - it would act
-- on whatever is next to the player, such as the door beside the crate.
local interactHeld = false
function Bridge.ownInteract(on)
    local Input = VPUI.Input
    local down = Input ~= nil and Input.down("interact")
    if on == true and down then interactHeld = true end
    if not down then interactHeld = false end
    local claim = on == true or interactHeld
    if claim and Input ~= nil and Input.sharesGameKey and not Input.sharesGameKey() then claim = false end
    Bridge.call("setOwnInteract", nil, claim)
end
function Bridge.hideLootPanel(on) Bridge.call("setHideLootPanel", nil, on == true) end
function Bridge.menuOpen(on) Bridge.call("setMenuOpen", nil, on == true) end
function Bridge.takeWheel() return Bridge.call("takeWheel", 0) end

-- Releases every flag at once (interface off, player dead, error).
function Bridge.releaseAll()
    if not ready then return end
    interactHeld = false
    Bridge.call("setOwnInteract", nil, false)
    Bridge.hideLootPanel(false)
    Bridge.menuOpen(false)
end
