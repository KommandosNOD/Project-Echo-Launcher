--
-- Viewpoint UI - input. Every key the interface reacts to is read here, once
-- per tick, and the rest of the add-on asks this module by action name
-- ("interact", "cancel") instead of testing raw keys. Rebinding happens on the
-- Mod Options page; a controller layer can later feed the same action names.
--

require "ViewpointUI/Core"
require "ViewpointUI/Settings"

local VPUI = ViewpointUI
if VPUI.Input then return end

local Input = {}
VPUI.Input = Input

-- The game's own Interact key (Options > Keyboard > Interact), via
-- getCore():getKey(KeybindId.X) as vanilla does (ISMoveableCursor, ISPlace3DItemCursor).
local function gameInteractKey()
    local ok, key = pcall(function() return getCore():getKey(KeybindId.INTERACT) end)
    if ok then return tonumber(key) or 0 end
    return 0
end
Input.gameInteractKey = gameInteractKey

-- One Interact key. Left at its default, this add-on's Interact follows the
-- game's own Interact key (Options > Keyboard), so rebinding that is enough.
-- Changed on the Mod Options page, only the key chosen there acts, and the
-- game's own key keeps its vanilla job (it is still held back from the game
-- while this interface owns a target, so one press never fires twice).
local function interactKeys()
    local own = tonumber(VPUI.Settings.get("interactKey")) or 0
    local game = gameInteractKey()
    if own > 0 and own ~= VPUI.Settings.default("interactKey") then return { own } end
    if game > 0 then return { game } end
    return { own }
end

-- True when this add-on's Interact is the game's own Interact key: only then
-- must the game's handling be held back (or one press would fire twice). With
-- a different key, the game's Interact works as in vanilla.
function Input.sharesGameKey()
    local keys = interactKeys()
    local game = gameInteractKey()
    if game <= 0 then return true end   -- unknown: hold it back, as before
    return keys[1] == game
end

-- action name -> function returning the key code (or a list of key codes,
-- first one shown in prompts) bound to it
local bindings = {
    interact = interactKeys,
    cancel = function() return VPUI.Settings.get("cancelKey") end,
    build = function() return VPUI.Settings.get("buildKey") end,
}

-- action name -> { down, pressed, released, since }
local state = {}

function Input.bind(name, keyFn)
    bindings[name] = keyFn
end

local function keysOf(name)
    local fn = bindings[name]
    if not fn then return {} end
    local v = fn()
    if type(v) == "table" then return v end
    return { tonumber(v) or 0 }
end

-- The key shown for an action (the first of its keys).
function Input.key(name)
    return tonumber(keysOf(name)[1]) or 0
end

-- Display text for the key bound to an action, e.g. "E".
function Input.label(name)
    local key = Input.key(name)
    if key <= 0 then return "?" end
    return getKeyName(key) or "?"
end

local function read(key)
    if key <= 0 then return false end
    return isKeyDown(key) == true
end

function Input.update(now)
    for name, _ in pairs(bindings) do
        local s = state[name]
        if not s then
            s = { down = false, pressed = false, released = false, since = 0 }
            state[name] = s
        end
        local down = false
        for _, key in ipairs(keysOf(name)) do
            if read(tonumber(key) or 0) then down = true break end
        end
        s.pressed = down and not s.down
        s.released = s.down and not down
        if s.pressed then s.since = now end
        s.down = down
    end
end

function Input.down(name)
    local s = state[name]
    return s ~= nil and s.down
end

function Input.pressed(name)
    local s = state[name]
    return s ~= nil and s.pressed
end

function Input.released(name)
    local s = state[name]
    return s ~= nil and s.released
end

-- Milliseconds the action's key has been held, 0 when up.
function Input.heldMs(name, now)
    local s = state[name]
    if not s or not s.down then return 0 end
    return now - s.since
end

-- Forget edges, e.g. after the game was paused with a key held.
function Input.reset()
    for _, s in pairs(state) do
        s.pressed, s.released = false, false
    end
end
