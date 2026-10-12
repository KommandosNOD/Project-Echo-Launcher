-- PROJECT ECHO / Build 42.21 -- admin/debug context-menu UI filter.
-- Does NOT alter access levels, server commands, gameplay, or saves.
-- Never edits or replaces any original mod file.

require "ISUI/ISContextMenu"

PE_HideAdminContext = PE_HideAdminContext or {}
local H = PE_HideAdminContext

local function isTarget(name)
    if type(name) ~= "string" then return false end

    -- Exact independent mod labels visible in the user's context menu.
    if name == "TheMission Config" or name == "Ban Music List" then
        return true
    end

    -- Only ADMIN and Debug entries from PROJECT ECHO, NOT the field journal.
    local ascii = string.lower(name)
    if string.find(ascii, "project echo", 1, true) then
        if string.find(ascii, "[admin]", 1, true)
            or string.find(ascii, "debug console", 1, true)
            or string.find(ascii, "debug menu", 1, true) then
            return true
        end
    end

    -- Also hide the old Companion Dogs root if that addon is ever re-enabled.
    if (string.find(ascii, "companion dogs", 1, true)
            or string.find(ascii, "companiondogs", 1, true))
            and string.find(ascii, "debug", 1, true) then
        return true
    end
    if string.find(name, getText("UI_ProjectEcho_Extra_zz_ProjectEcho_HideAdminContext_001"), 1, true)
            and string.find(name, getText("UI_ProjectEcho_Extra_zz_ProjectEcho_HideAdminContext_002"), 1, true) then
        return true
    end
    return false
end

local function strip(menu)
    if not menu or type(menu.options) ~= "table" then return end
    local options = menu.options
    if #options == 0 then return end

    local removed = 0
    for i = #options, 1, -1 do
        local option = options[i]
        if option and isTarget(option.name) then
            -- Don't leave an already-open submenu floating after its root vanishes.
            if option.subOption and menu.getSubMenu and menu.subMenu then
                local sub = menu:getSubMenu(option.subOption)
                if sub and sub == menu.subMenu then
                    if sub.hideAndChildren then sub:hideAndChildren() end
                    menu.subMenu = nil
                end
            end
            table.remove(options, i)
            removed = removed + 1
        end
    end

    if removed == 0 then return end
    for i, option in ipairs(options) do option.id = i end
    menu.numOptions = #options + 1
    menu.mouseOver = -1
    if menu.calcHeight then menu:calcHeight() end
    if menu.calcWidth and menu.setWidth then menu:setWidth(menu:calcWidth()) end
    if #options == 0 and menu.setVisible then menu:setVisible(false) end

    H.hiddenCount = (H.hiddenCount or 0) + removed
    if not H.logged then
        H.logged = true
        print("[PROJECT ECHO HIDE ADMIN CONTEXT] filtering active; admin rights unchanged")
    end
end

-- World and inventory event filters cover regular right-click menus.
if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
        if not test then strip(context) end
    end)
end
if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)
        strip(context)
    end)
end

-- Viewpoint may build/modify its 3D menu outside regular context-menu events.
-- Filter just before rendering as a fallback, AFTER the menu has been filled.
local function installRenderFilter()
    if not ISContextMenu or type(ISContextMenu.render) ~= "function" then return end
    if ISContextMenu.render == H.ourRender then return end
    local previous = ISContextMenu.render
    local wrapped = function(self, ...)
        strip(self)
        return previous(self, ...)
    end
    H.ourRender = wrapped
    ISContextMenu.render = wrapped
end

installRenderFilter()
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(installRenderFilter)
end
-- If a later-loaded mod replaces render, re-install the chain only if needed.
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        if ISContextMenu and ISContextMenu.render ~= H.ourRender then
            installRenderFilter()
        end
    end)
end
