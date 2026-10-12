--
-- Viewpoint UI - building tab, on the game's BuildLogic (the object behind the
-- vanilla build window). Choosing "Place" closes the screen and starts build
-- mode with that recipe; see Building/BuildMode.lua.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Screens/RecipeBrowser"
require "ViewpointUI/Building/BuildMode"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Build then return end

local T = VPUI.Text
local BuildMode = VPUI.Building.BuildMode

VPUI.Screens.Build = {}

local function create(screen)
    local tab = {}
    local browser = VPUI.Screens.RecipeBrowser.new(screen, {
        actionLabel = T.place,
        batch = false,
        makeLogic = function(player)
            return BuildLogic.new(player, nil, nil)
        end,
        loadRecipes = function(logic)
            logic:setRecipes(logic:getAllBuildableRecipes())
        end,
        refresh = function(logic, player)
            logic:setContainers(ISInventoryPaneContextMenu.getContainers(player))
            if not logic:isCraftActionInProgress() then logic:autoPopulateInputs() end
        end,
        computeCan = function(logic)
            -- placement may start even when materials are missing: the ghost then
            -- shows what is needed, and the game refuses to build it (blockBuild)
            return not logic:isCraftActionInProgress()
        end,
        action = function(b)
            local player = VPUI.Util.player()
            if not player then return end
            VPUI.Hub.close()
            BuildMode.start(player, b.logic)
        end,
    })
    tab.browser = browser
    browser:attach(tab)
    tab.consumes = { [Keyboard.KEY_UP] = true, [Keyboard.KEY_DOWN] = true, [Keyboard.KEY_RETURN] = true }
    for _, name in ipairs({ "open", "close", "layout", "render", "update", "mouseDown", "doubleClick", "wheel", "keyPressed" }) do
        tab[name] = function(self, ...) return browser[name](browser, ...) end
    end
    tab.mouseUp = function() browser.recipeList:mouseUp(); browser.categoryList:mouseUp() end
    return tab
end

VPUI.Hub.register({
    id = "build",
    label = T.tabBuild,
    order = 30,
    key = function() return VPUI.Settings.get("buildKey") end,
    create = create,
})
