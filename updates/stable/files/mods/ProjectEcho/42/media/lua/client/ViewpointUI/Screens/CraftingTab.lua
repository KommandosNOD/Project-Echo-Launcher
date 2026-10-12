--
-- Viewpoint UI - crafting tab, on the game's HandcraftLogic (the same object the
-- vanilla handcraft window uses). Starting a craft follows
-- ISWidgetHandCraftControl:startHandcraft step by step: inputs not in the
-- player's inventory are fetched (unless the recipe works from the floor),
-- ISEntityUI.HandcraftStartMultiple builds the actions (it walks to the craft
-- surface when needed), and items that go back are returned afterwards.
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Screens/RecipeBrowser"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Crafting then return end

local Log = VPUI.Log
local T = VPUI.Text

local Crafting = {}
VPUI.Screens.Crafting = Crafting

local QUERY = "InHandCraft;AnySurfaceCraft"   -- ISHandcraftWindow's default query

function Crafting.start(player, logic, times)
    if logic:isCraftActionInProgress() then return false end
    local returnTo = {}
    local data = logic:getRecipeData()
    local items = data:getAllInputItems()
    local putBack = data:getAllPutBackInputItems()
    if logic:isUsingRecipeAtHandBenefit() then
        local atHand = logic:getUsingRecipeAtHandItem()
        if atHand then
            items:add(atHand)
            putBack:add(atHand)
        end
    end
    if not logic:getRecipe():isCanBeDoneFromFloor() then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item:getContainer() ~= player:getInventory() then
                ISInventoryPaneContextMenu.transferIfNeeded(player, item)
                if putBack:contains(item) then table.insert(returnTo, item) end
            end
        end
    end
    logic:updateManualInputAllowedItemTypes()
    local actions = ISEntityUI.HandcraftStartMultiple(player, logic, false, times, false)
    if not actions then return false end
    for _, action in ipairs(actions) do
        if not action then return false end
        action:setOnStart(function(_, a) logic:startCraftAction(a) end, nil)
        action:setOnComplete(function() logic:stopCraftAction() end, nil)
        action:setOnCancel(function() logic:stopCraftAction(true) end, nil)
        ISTimedActionQueue.add(action)
    end
    ISCraftingUI.ReturnItemsToOriginalContainer(player, returnTo)
    return true
end

local function create(screen)
    local tab = {}
    local browser = VPUI.Screens.RecipeBrowser.new(screen, {
        actionLabel = T.craft,
        batch = true,
        makeLogic = function(player)
            local surface = ISEntityUI.FindCraftSurface(player, 1)
            local logic = HandcraftLogic.new(player, nil, surface)
            logic:setManualSelectInputs(true)
            return logic
        end,
        loadRecipes = function(logic)
            logic:setRecipes(CraftRecipeManager.queryRecipes(QUERY))
        end,
        refresh = function(logic, player, full)
            -- like ISHandCraftPanel:update: leave the logic alone while a craft runs
            if logic:isCraftActionInProgress() then return end
            local surface = ISEntityUI.FindCraftSurface(player, 2)
            if surface ~= logic:getIsoObject() then logic:setIsoObject(surface) end
            logic:setContainers(ISInventoryPaneContextMenu.getContainers(player))
            -- the recipe query runs once per opening (loadRecipes); the logic
            -- re-checks what can be made from the new containers itself
            logic:autoPopulateInputs()
        end,
        computeCan = function(logic, player)
            if logic:isCraftActionInProgress() then return false end
            return logic:canPerformCurrentRecipe() or player:isBuildCheat()
        end,
        action = function(b, recipe, quantity)
            local player = VPUI.Util.player()
            if not player then return end
            if Crafting.start(player, b.logic, math.max(1, quantity or 1)) then
                Log.debug("crafting " .. tostring(recipe:getName()) .. " x" .. tostring(quantity))
                b.nextRefresh = 0
            end
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
    id = "crafting",
    label = T.tabCrafting,
    order = 20,
    key = function() return getCore():getKey(KeybindId.CRAFTING_UI) end,
    create = create,
})
