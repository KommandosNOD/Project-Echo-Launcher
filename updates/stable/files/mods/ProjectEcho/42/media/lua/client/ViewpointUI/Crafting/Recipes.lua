--
-- Viewpoint UI - recipe helpers shared by the crafting and building tabs.
--
-- Both use the game's own crafting logic objects (HandcraftLogic, BuildLogic),
-- exactly as the vanilla handcraft and build windows do (ISHandCraftPanel,
-- ISBuildPanel): the logic discovers recipes (vanilla and modded), filters and
-- categorises them, picks the input items, and decides whether a recipe can be
-- done right now. Nothing here keeps a recipe list of its own.
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.Crafting = VPUI.Crafting or {}
if VPUI.Crafting.Recipes then return end

local Recipes = {}
VPUI.Crafting.Recipes = Recipes

local Log = VPUI.Log

-- Flattens the logic's (filtered) recipe tree into a list, honouring each
-- recipe's OnAddToMenu Lua check like ISRecipeScrollingListBox:addGroup.
function Recipes.flatten(logic, player)
    local out = {}
    local function walk(nodes)
        for i = 0, nodes:size() - 1 do
            local node = nodes:get(i)
            local nodeType = node:getType()
            if nodeType == CraftRecipeListNode.CraftRecipeListNodeType.RECIPE then
                local recipe = node:getRecipe()
                local show = recipe ~= nil
                if show and recipe:getOnAddToMenu() then
                    local ok, result = pcall(callLuaBool, recipe:getOnAddToMenu(),
                        { player = player, recipe = recipe, shouldShowAll = false })
                    show = ok and result == true
                end
                if show then table.insert(out, recipe) end
            elseif nodeType == CraftRecipeListNode.CraftRecipeListNodeType.GROUP then
                walk(node:getChildren())
            end
        end
    end
    local ok, err = pcall(function() walk(logic:getRecipeList():getNodes()) end)
    if not ok then Log.error("reading the recipe list failed: " .. tostring(err)) end
    return out
end

-- "ok" (can do now), "missing" (valid but something is missing), "invalid"
-- (not available to this character), matching ISRecipeScrollingListBox's colours.
function Recipes.status(logic, recipe, player)
    if player:isBuildCheat() then return "ok" end
    local info = logic:getCachedRecipeInfo(recipe)
    if not info then return "missing" end
    if not info:isValid() then return "invalid" end
    if not info:isCanPerform() then return "missing" end
    return "ok"
end

function Recipes.categoryLabel(category)
    if category == nil or category == "" then return VPUI.Text.allCategories end
    local key = "IGUI_CraftingCategories_" .. string.upper(string.sub(category, 1, 1)) .. string.sub(category, 2)
    return getTextOrNull(key) or category
end

function Recipes.categories(logic)
    local list = {}
    local ok, cats = pcall(function() return logic:getCategoryList() end)
    if ok and cats then
        for i = 0, cats:size() - 1 do table.insert(list, cats:get(i)) end
    end
    return list
end

-- Applies the search text and category the way the vanilla panels do (the
-- filter mode rides on the search string, cut apart in Java).
function Recipes.filter(logic, search, category)
    local text = (search or "") .. "-@-" .. "RecipeName"
    local ok, err = pcall(function() logic:filterRecipeList(text, category or "") end)
    if not ok then Log.error("filtering recipes failed: " .. tostring(err)) end
end

local NAMERS = {
    getDisplayName = function(o) return o:getDisplayName() end,
    getFluidTypeString = function(o) return o:getFluidTypeString() end,
    getEnergyTypeString = function(o) return o:getEnergyTypeString() end,
}

local function firstName(list, method)
    if list and list:size() > 0 then
        local first = list:get(0)
        local ok, name = pcall(NAMERS[method], first)
        if ok and name then
            if list:size() > 1 then return tostring(name) .. " (+" .. tostring(list:size() - 1) .. ")" end
            return tostring(name)
        end
    end
    return "?"
end

-- Lines describing a recipe: { text, state } with state "ok" / "missing" / "info".
function Recipes.details(logic, recipe, player)
    local lines = {}
    local function add(text, state) table.insert(lines, { text = text, state = state or "info" }) end
    -- inputs
    local inputs = recipe:getInputs()
    for i = 0, inputs:size() - 1 do
        local input = inputs:get(i)
        local kind = input:getResourceType()
        local satisfied = false
        pcall(function() satisfied = logic:isInputSatisfied(input) end)
        local text
        if kind == ResourceType.Item then
            local amount = tostring(input:getIntAmount())
            if input:isVariableAmount() then amount = amount .. "-" .. tostring(input:getIntMaxAmount()) end
            local name = firstName(input:getPossibleInputItems(), "getDisplayName")
            local role = (input:isKeep() and input:isTool()) and VPUI.Text.recipeTool
                or (input:isKeep() and VPUI.Text.recipeKept or "")
            text = amount .. " x " .. name .. role
        elseif kind == ResourceType.Fluid then
            text = string.format("%.2f L ", input:getAmount()) .. firstName(input:getPossibleInputFluids(), "getFluidTypeString")
        else
            text = firstName(input:getPossibleInputEnergies(), "getEnergyTypeString")
        end
        add(text, satisfied and "ok" or "missing")
    end
    -- skills
    for i = 0, recipe:getRequiredSkillCount() - 1 do
        local req = recipe:getRequiredSkill(i)
        local perk = req:getPerk()
        local has = player:getPerkLevel(perk)
        add(string.format(VPUI.Text.recipeSkill, tostring(perk:getName()), tostring(req:getLevel()), tostring(has)),
            has >= req:getLevel() and "ok" or "missing")
    end
    if recipe:needToBeLearn() then
        local learned = CraftRecipeManager.hasPlayerLearnedRecipe(recipe, player)
        add(learned and VPUI.Text.recipeLearned or VPUI.Text.recipeNotLearned, learned and "ok" or "missing")
    end
    -- outputs
    local outputs = recipe:getOutputs()
    for i = 0, outputs:size() - 1 do
        local out = outputs:get(i)
        if out:getResourceType() == ResourceType.Item then
            add("-> " .. tostring(out:getIntAmount()) .. " x " .. firstName(out:getPossibleResultItems(), "getDisplayName"), "info")
        end
    end
    -- time
    local seconds = recipe:getTime(player)
    if seconds and seconds > 0 then
        add(string.format(VPUI.Text.recipeTime, math.floor(seconds / 60), math.floor(seconds % 60)), "info")
    end
    return lines
end
