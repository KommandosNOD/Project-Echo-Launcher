-- PROJECT ECHO / Neat Building B42.21 context menu guard
-- Source analysis: Neat_Building/patch/disablecontextmenuwhendrag.lua:9.
-- Fixes indexing ISEntityUI.players[playerNum] when ISEntityUI.players == nil.
-- Preserves the rest of the createMenu chain captured by Neat Building.
local tag = "[PE-NeatBuilding-NilGuard v1.0] "
local knownNeatWrapper = nil
local ourWrapper = nil
local installedOnce = false

local function install()
    local menu = ISWorldObjectContextMenu
    if not menu or type(menu.createMenu) ~= "function" then return end
    local original = menu._NB_old_createMenu
    if type(original) ~= "function" then return end
    local current = menu.createMenu
    if current == ourWrapper then return end
    -- Respect the Neat Building settings toggle when its guard is disabled.
    if current == original then return end
    -- Never overwrite another mod's newly installed wrapper.
    if knownNeatWrapper and current ~= knownNeatWrapper then return end
    if not knownNeatWrapper then knownNeatWrapper = current end

    local function safeCreateMenu(player, worldobjects, x, y, test)
        local playerObj = getSpecificPlayer(player)
        if playerObj then
            local playerNum = playerObj:getPlayerNum()
            local ui = ISEntityUI
            local players = ui and ui.players
            local state = type(players) == "table" and players[playerNum] or nil
            local windows = type(state) == "table" and state.windows or nil
            local build = type(windows) == "table" and windows.BuildWindow or nil
            if build and build.instance then
                local cell = getCell()
                if cell and cell:getDrag(player) ~= nil then return end
            end
        end
        return original(player, worldobjects, x, y, test)
    end

    ourWrapper = safeCreateMenu
    menu.createMenu = ourWrapper
    if not installedOnce then
        print(tag .. "installed: Neat Building guard is nil-safe; downstream menus preserved")
        installedOnce = true
    else
        print(tag .. "restored after Neat Building UI toggle")
    end
end

Events.OnGameBoot.Add(install)
Events.OnGameStart.Add(install)
Events.OnCreatePlayer.Add(function() install() end)

-- Check occasionally for the original Neat toggle re-enabling its broken guard.
-- No wrapping on each tick; other mods are never overwritten.
local ticks = 0
Events.OnTick.Add(function()
    ticks = ticks + 1
    if ticks >= 180 then
        ticks = 0
        install()
    end
end)
