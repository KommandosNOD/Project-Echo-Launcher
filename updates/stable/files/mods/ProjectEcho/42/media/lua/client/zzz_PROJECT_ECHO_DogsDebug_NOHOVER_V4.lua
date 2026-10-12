-- PROJECT ECHO | Companion Dogs debug root hiding V4 | PZ Build 42.21
-- Inspected against Companion Dogs 0.7.4 source supplied by the player.
-- Client display only: DOES NOT alter CD.debugAllowed, CD.adminAllowed,
-- spawn logic, zombies, dog AI, access levels, or server commands.
-- The world context menu may open automatically while a 3D target is hovered.
-- Filtering during ISContextMenu.render covers that path as well as RMB.

require "ISUI/ISContextMenu"

local FILTER_TAG = "[PROJECT ECHO DOGS DEBUG V4]"
local FILTER_FILE = "zzz_PROJECT_ECHO_DogsDebug_NOHOVER_V4.lua"
local didLogHide = false
local installedRender = nil

local function isTarget(name, expected)
    if type(name) ~= "string" then return false end
    return name == expected
        or name == "Companion Dogs (debug)"
        or name == getText("UI_ProjectEcho_Extra_zzz_PROJECT_ECHO_DogsDebug_NOHOVER_V4_001")
end

local function stripDebugRoot(menu)
    if not menu or type(menu.options) ~= "table" then return end
    local opts = menu.options
    if #opts == 0 then return end

    local expected = getText("IGUI_PD_DebugRoot")
    local changed = false
    for i = #opts, 1, -1 do
        local opt = opts[i]
        if opt and isTarget(opt.name, expected) then
            -- Only close the sub-menu of THIS option if already expanded.
            if opt.subOption and menu.subMenu and menu.getSubMenu then
                local sub = menu:getSubMenu(opt.subOption)
                if sub and menu.subMenu == sub then
                    if sub.hideAndChildren then sub:hideAndChildren() end
                    menu.subMenu = nil
                end
            end
            table.remove(opts, i)
            changed = true
        end
    end

    if not changed then return end
    -- Vanilla ISContextMenu adds options with 1-based IDs, numOptions=next ID.
    for i, opt in ipairs(opts) do opt.id = i end
    menu.numOptions = #opts + 1
    menu.mouseOver = -1
    if menu.calcHeight then menu:calcHeight() end
    if menu.calcWidth and menu.setWidth then menu:setWidth(menu:calcWidth()) end
    if #opts == 0 and menu.setVisible then menu:setVisible(false) end

    if not didLogHide then
        didLogHide = true
        print(FILTER_TAG .. " hidden=1 (root option, all input methods)")
    end
end

local function installRenderFilter()
    if not ISContextMenu or type(ISContextMenu.render) ~= "function" then return end
    if ISContextMenu.render == installedRender then return end
    -- Keep any earlier wrappers installed by other mods.
    local previousRender = ISContextMenu.render
    local thisRender = function(self, ...)
        stripDebugRoot(self)
        return previousRender(self, ...)
    end
    installedRender = thisRender
    ISContextMenu.render = thisRender
    print(FILTER_TAG .. " render filter active (" .. FILTER_FILE .. ")")
end

installRenderFilter()
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(installRenderFilter)
end
-- Some mods replace render after client Lua loads; restore our wrapper if needed.
-- This is a cheap identity check; menu scanning only runs on render.
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        if ISContextMenu and ISContextMenu.render ~= installedRender then
            installRenderFilter()
        end
    end)
end
