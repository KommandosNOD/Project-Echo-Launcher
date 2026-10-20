-- PROJECT ECHO - ViewpointUI RU adapter for the Workshop add-on.
-- ASCII-only executable Lua; the Cyrillic text stays in Translate/RU/UI.json.
-- This file does NOT replace ViewpointUI/Core.lua, Text.lua, Settings.lua or Java.
-- Requires the official ViewpointUI Workshop mod (Mod ID ViewpointUI).

local existing = rawget(_G, "ProjectEchoViewpointRU")
if existing and existing.registered then return end
local PE_RU = existing or {}
ProjectEchoViewpointRU = PE_RU
PE_RU.registered = true
PE_RU.applied = false

local keys = {
    "holdPrefix",
    "moreActions",
    "actions",
    "menuFooter",
    "listFooter",
    "npc",
    "amountTitle",
    "gearTurnModel",
    "gearPrimary",
    "gearEquipment",
    "invCharacter",
    "gearSecondary",
    "gearDropOnModel",
    "amountHalf",
    "amountAll",
    "amountMove",
    "amountCancel",
    "inventoryModHint",
    "on",
    "javaMissing",
    "bridgeFailed",
    "disabledAfterErrors",
    "search",
    "searchLocked",
    "searchBody",
    "searchGround",
    "pickUp",
    "inspect",
    "ground",
    "body",
    "tabInventory",
    "tabCrafting",
    "tabBuild",
    "tabHealth",
    "tabSkills",
    "tabCharacter",
    "tabVehicle",
    "tabAdmin",
    "tabFailed",
    "invEquipment",
    "invYou",
    "invNearby",
    "invPrimary",
    "invSecondary",
    "invEmpty",
    "invEquipped",
    "invHotbar",
    "invNothingNear",
    "invTakeAll",
    "invStoreAll",
    "invUserPanel",
    "invFillMatching",
    "invTakeVerb",
    "invMoveVerb",
    "invPartOne",
    "invPartHalf",
    "invPartAmount",
    "invFilled",
    "invNothingMatching",
    "invDropped",
    "invTake",
    "invMoveToContainer",
    "invFavorite",
    "invUnfavorite",
    "invUnequip",
    "invHelp",
    "invSearch",
    "invSort",
    "sort_name",
    "sort_weight",
    "sort_type",
    "sort_condition",
    "chipAll",
    "chipWeapons",
    "chipAmmo",
    "chipFood",
    "chipMedical",
    "chipClothing",
    "chipBags",
    "chipTools",
    "invGrid",
    "invList",
    "invGear",
    "gearTwoHanded",
    "gearAttached",
    "gearNoAttach",
    "gearDoesNotFit",
    "gearWornElsewhere",
    "gearDetach",
    "hotbarMoveLeft",
    "hotbarMoveRight",
    "hotbarBusy",
    "gearShow",
    "menuUse",
    "menuEquip",
    "menuCraft",
    "menuMove",
    "menuOther",
    "gearWornWeight",
    "gearCover",
    "gearOpenBag",
    "gearSwapped",
    "craft",
    "place",
    "allCategories",
    "noRecipes",
    "pickRecipe",
    "searchPlaceholder",
    "recipeTool",
    "recipeKept",
    "recipeSkill",
    "recipeLearned",
    "recipeNotLearned",
    "recipeTime",
    "recipeMax",
    "recipeFavourite",
    "recipeUnfavourite",
    "favourites",
    "buildHint",
    "build_valid",
    "build_blocked",
    "build_missing",
    "build_none",
    "placeHint",
    "placeSurfaceHint",
    "place_valid",
    "place_valid_all",
    "place_blocked",
    "place_far",
    "movePickUpAction",
    "moveRotateAction",
    "movePickup",
    "movePlace",
    "moveRotate",
    "moveScrap",
    "moveRepair",
    "moveReady",
    "moveCannot",
    "moveNothing",
    "moveNotEmpty",
    "moveTooHeavy",
    "moveNeedsTool",
    "moveHint",
    "destroyTitle",
    "destroyDismantle",
    "destroyReady",
    "destroyCannot",
    "destroyNothing",
    "destroyHint",
    "hudStamina",
    "hudHealth",
    "qlTake",
    "qlTakeAll",
    "qlOpen",
    "qlSelect",
    "qlEmpty",
    "qlYou",
    "qlMore",
    "qlTook",
    "qlCondition",
    "qlLeft",
    "place_none",
    "healthFine",
    "healthPick",
    "healthTreatments",
    "healthNoTreatment",
    "healthApply",
    "charTraits",
    "charNoTraits",
    "charProtection",
    "charCoreTemp",
    "vehSeatsInfo",
    "vehSit",
    "vehStorage",
    "vehMechanics",
    "vehTooFar",
    "vehMechanicsFailed",
    "vehMissing",
    "vehNone",
    "vehEngineQuality",
    "adminPlayers",
    "adminNoPlayers",
    "adminSinglePlayer",
    "adminGoTo",
    "adminBring",
    "adminGod",
    "adminInvisible",
    "adminStats",
    "adminKick",
    "adminBan",
    "adminConfirm",
    "adminNotLoaded",
    "adminSelf",
    "adminState",
    "adminSelfGod",
    "adminSelfInvisible",
    "adminSelfNoClip",
    "adminTarget",
    "adminNoTarget",
    "adminTeleportHere",
    "adminHorde",
    "adminRemoveVehicle",
    "adminTools",
    "adminPanel",
    "adminItems",
    "adminSpawnVehicle",
    "adminRemoveItems",
    "adminTeleportUI",
    "off",
}
local formatTokens = {
    actions = { "%s" },
    adminState = { "%s", "%s", "%s" },
    amountTitle = { "%s" },
    buildHint = { "%s", "%s", "%s" },
    charCoreTemp = { "%.1f" },
    destroyHint = { "%s", "%s" },
    gearCover = { "%d", "%%", "%d", "%%", "%d", "%%" },
    gearDoesNotFit = { "%s", "%s" },
    gearShow = { "%s" },
    gearSwapped = { "%s" },
    gearWornElsewhere = { "%s", "%s" },
    gearWornWeight = { "%.1f" },
    holdPrefix = { "%s" },
    hotbarMoveLeft = { "%d" },
    hotbarMoveRight = { "%d" },
    invDropped = { "%s" },
    invFilled = { "%s" },
    invPartAmount = { "%s" },
    invPartHalf = { "%s", "%s" },
    invPartOne = { "%s" },
    invSort = { "%s" },
    inventoryModHint = { "%s" },
    listFooter = { "%s" },
    menuFooter = { "%s", "%s" },
    moreActions = { "%s" },
    moveHint = { "%s", "%s" },
    movePickUpAction = { "%s" },
    moveRotateAction = { "%s" },
    pickUp = { "%s" },
    placeHint = { "%s", "%s", "%s" },
    placeSurfaceHint = { "%s" },
    qlCondition = { "%s", "%%" },
    qlLeft = { "%s", "%%" },
    qlMore = { "%s" },
    qlTook = { "%s" },
    recipeSkill = { "%s", "%s", "%s" },
    recipeTime = { "%d", "%02d" },
    searchGround = { "%s" },
}

local function translation(key)
    if type(getTextOrNull) == "function" then
        local value = getTextOrNull(key)
        if type(value) == "string" and value ~= "" then return value end
    end
    if type(getText) == "function" then
        local value = getText(key)
        if type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return nil
end

local function localize()
    -- Do not overwrite the Workshop author's English text on non-RU clients.
    if translation("UI_ProjectEcho_VPUI_LocaleMarker") ~= "RU" then
        PE_RU.applied = true
        return true
    end
    local vp = rawget(_G, "ViewpointUI")
    if type(vp) ~= "table" or type(vp.Text) ~= "table" then return false end
    local target = vp.Text
    local applied = 0
    for i = 1, #keys do
        local name = keys[i]
        -- Only edit string entries actually defined by the installed Workshop version.
        if type(target[name]) == "string" then
            local value = translation("UI_ProjectEcho_VPUI_" .. name)
            if value then
                local tokens = formatTokens[name]
                if tokens then
                    value = string.gsub(value, "@@ECHO_FMT_(%d+)@@", function(number)
                        return tokens[tonumber(number)] or ""
                    end)
                end
                value = string.gsub(value, "@@ECHO_PERCENT@@", function() return "%%" end)
                -- Never break a string.format call by shipping unresolved placeholders.
                if not string.find(value, "@@ECHO_", 1, true) then
                    target[name] = value
                    applied = applied + 1
                end
            end
        end
    end
    PE_RU.applied = true
    PE_RU.lastCount = applied
    -- A single line at startup, not a log line each render frame.
    print("[PROJECT ECHO][ViewpointUI RU] Workshop text translations applied: " .. tostring(applied))
    return true
end

local attempts = 0
local function onTick()
    attempts = attempts + 1
    if attempts % 30 == 1 and localize() then
        Events.OnTick.Remove(onTick)
    elseif attempts >= 600 then
        Events.OnTick.Remove(onTick)
        print("[PROJECT ECHO][ViewpointUI RU] official ViewpointUI Text not found; adapter inactive")
    end
end

local function onBoot()
    if localize() then
        if Events.OnTick then Events.OnTick.Remove(onTick) end
    elseif Events.OnTick then
        Events.OnTick.Remove(onTick)
        Events.OnTick.Add(onTick)
    end
end

local function onPlayer()
    -- Reapply AFTER the original Workshop add-on finishes its startup setup.
    localize()
end

if Events.OnGameBoot then Events.OnGameBoot.Add(onBoot) end
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onPlayer) end
if Events.OnGameStart then Events.OnGameStart.Add(onPlayer) end
-- No ISContextMenu hooks, no patching of Workshop files, no native code.
