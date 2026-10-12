-- PROJECT ECHO | Clean Admin Menu (B42.21) | client-only
-- Add this file to the existing local PZ42SpecialLootCallbackGuard/42/media/lua/client mod.
-- No server settings, role changes, or mod API calls are made.
require "ISUI/ISContextMenu"

local EchoClean = {
    hidden = true,
    -- Extend this exact-title list if a mod uses another translation.
    exact = {
        ["TheMission Config"] = true,
        [getText("UI_ProjectEcho_Extra_PZ42_PROJECT_ECHO_CleanAdmin_F9_001")] = true,
        ["Ban Music List"] = true,
        ["PROJECT ECHO — Debug Console"] = true,
        ["PROJECT ECHO - Debug Console"] = true,
        ["PROJECT ECHO [ADMIN]"] = true,
        ["Debug"] = true,
        ["DEBUG"] = true,
        [getText("UI_ProjectEcho_Extra_PZ42_PROJECT_ECHO_CleanAdmin_F9_002")] = true,
    },
}

local function isHiddenName(name)
    if type(name) ~= "string" then return false end
    if EchoClean.exact[name] then return true end
    -- Only explicitly debug-related captions. Never hide gameplay entries
    -- such as farming, movement, building, or the PROJECT ECHO field journal.
    local lower = string.lower(name)
    if string.find(lower, "project echo", 1, true) then
        if string.find(lower, "debug", 1, true) or
           string.find(lower, "[admin]", 1, true) then
            return true
        end
    end
    return false
end

local function filterMenu(menu)
    if not EchoClean.hidden then return end
    local options = menu and menu.options
    if type(options) ~= "table" then return end
    local removed = false
    for i = #options, 1, -1 do
        local option = options[i]
        if option and isHiddenName(option.name) then
            table.remove(options, i)
            removed = true
        end
    end
    if not removed then return end

    -- ISContextMenu stores a 1-based option ID plus a next-ID counter.
    -- Rebuild them after removal so controller navigation stays in sync.
    for i, option in ipairs(options) do option.id = i end
    menu.numOptions = #options + 1
    menu.mouseOver = -1
    if menu.calcHeight then menu:calcHeight() end
    if menu.calcWidth and menu.setWidth then menu:setWidth(menu:calcWidth()) end
end

local wrappedPrerender = nil
local function install()
    if not ISContextMenu or type(ISContextMenu.prerender) ~= "function" then return end
    if ISContextMenu.prerender == wrappedPrerender then return end
    local original = ISContextMenu.prerender
    wrappedPrerender = function(self, ...)
        filterMenu(self)
        return original(self, ...)
    end
    ISContextMenu.prerender = wrappedPrerender
    print("[PROJECT ECHO Clean Admin F9] installed; custom debug entries initially HIDDEN")
end

local F9 = (Keyboard and Keyboard.KEY_F9) or 67
local function onKeyPressed(key)
    if key ~= F9 then return end
    EchoClean.hidden = not EchoClean.hidden
    local state = EchoClean.hidden and "HIDDEN" or "VISIBLE"
    print("[PROJECT ECHO Clean Admin F9] debug entries " .. state .. "; reopen context menu")
    -- Optional local visual feedback, if the built-in text helper is present.
    local player = getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, "PROJECT ECHO: debug " .. (EchoClean.hidden and "OFF" or "ON"))
    end
end

install()
Events.OnGameStart.Add(install)
Events.OnKeyPressed.Add(onKeyPressed)
