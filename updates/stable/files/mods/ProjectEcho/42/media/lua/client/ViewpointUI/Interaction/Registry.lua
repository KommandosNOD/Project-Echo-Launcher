--
-- Viewpoint UI - interaction registry and action resolver.
--
-- A provider is a table:
--   id        unique string, e.g. "mymod.radio"
--   priority  higher runs first and wins the primary action (default 0)
--   collect   function(target, player, add) - calls add{...} once per action
--
-- An action passed to add{} is:
--   label     text shown in the prompt and menu (required)
--   run       function(player, target) - must start the work through the game's
--             own mechanics (timed actions, context-menu functions, server
--             commands); never change world state directly from here
--   enabled   false greys it out (default true)
--   primary   true makes it the tap-Interact action
--   id        optional stable id
--
-- Providers are called only when the target or Viewpoint's harvested actions
-- change (and at most once a second otherwise), never every frame.
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.Interaction = VPUI.Interaction or {}
if VPUI.Interaction.Registry then return end

local Log = VPUI.Log

local Registry = { providers = {} }
VPUI.Interaction.Registry = Registry

local function sortProviders()
    table.sort(Registry.providers, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.id < b.id
    end)
end

function Registry.register(provider)
    if type(provider) ~= "table" or type(provider.id) ~= "string" or type(provider.collect) ~= "function" then
        Log.error("Interactions.register needs { id = string, collect = function }")
        return false
    end
    Registry.unregister(provider.id)
    provider.priority = tonumber(provider.priority) or 0
    table.insert(Registry.providers, provider)
    sortProviders()
    Log.debug("provider registered: " .. provider.id)
    return true
end

function Registry.unregister(id)
    for i = #Registry.providers, 1, -1 do
        if Registry.providers[i].id == id then table.remove(Registry.providers, i) end
    end
end

-- Builds the action list for a target. Returns { actions = {...}, primary = action|nil, title = string|nil }.
function Registry.resolve(target, player)
    local result = { actions = {}, primary = nil, title = nil }
    if not target or not player then return result end
    for _, provider in ipairs(Registry.providers) do
        local function add(action)
            if type(action) ~= "table" or action.label == nil or type(action.run) ~= "function" then
                Log.once(Log.WARN, "bad-action:" .. provider.id, "provider " .. provider.id .. " added an action without label/run")
                return
            end
            action.enabled = action.enabled ~= false
            action.provider = provider.id
            action.id = action.id or (provider.id .. ":" .. tostring(#result.actions + 1))
            table.insert(result.actions, action)
        end
        local ok, err = pcall(provider.collect, target, player, add, result)
        if not ok then
            Log.once(Log.ERROR, "provider-fail:" .. provider.id, "provider " .. provider.id .. " failed: " .. tostring(err))
        end
    end
    -- built-in ordering rules (Providers: Enter Vehicle first on a vehicle...)
    for _, arrange in ipairs(Registry.arrangers or {}) do
        local ok, err = pcall(arrange, target, result, player)
        if not ok then Log.once(Log.ERROR, "arrange-fail", "arranging actions failed: " .. tostring(err)) end
    end
    for _, action in ipairs(result.actions) do
        if action.primary and action.enabled then
            result.primary = action
            break
        end
    end
    -- Nothing marked primary but only one thing to do: that is the primary.
    if not result.primary then
        local only, count = nil, 0
        for _, action in ipairs(result.actions) do
            if action.enabled then
                only = action
                count = count + 1
            end
        end
        if count == 1 then result.primary = only end
    end
    -- A primary that cannot run (locked door) still shows, greyed, as feedback.
    if not result.primary then
        for _, action in ipairs(result.actions) do
            if action.primary then
                result.blocked = action
                break
            end
        end
    end
    return result
end
