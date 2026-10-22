--
-- Viewpoint UI - player-facing strings in one table, so a translation is one
-- file (B42's translation files changed format mid-version; a Lua table keeps
-- working either way). Game-provided names (actions, moodles, items, body parts,
-- recipes, seats) are already translated by the game and never pass through here.
--
-- Where the game has the same word in its own translations, that is used on
-- game boot instead (see GAME_KEYS), so those labels follow the game language.
--

ViewpointUI = ViewpointUI or {}
if ViewpointUI.Text then return end

ViewpointUI.Text = {
    -- prompt / menu
    holdPrefix = "Hold %s",
    moreActions = "More actions (%s)",
    actions = "Actions (%s)",
    menuFooter = "Wheel: choose   %s: do   %s: close",
    listFooter = "Wheel: choose   %s: do",
    npc = "Person",
    amountTitle = "Move how many %s?",
    gearTurnModel = "Drag to turn",
    gearPrimary = "Primary",
    gearEquipment = "Equipment",
    invCharacter = "Character",
    gearSecondary = "Secondary",
    gearDropOnModel = "Drop to wear or hold",
    amountHalf = "Half",
    amountAll = "All",
    amountMove = "Move",
    amountCancel = "Cancel",
    inventoryModHint = "%s is active: turn on Options > Mods > Viewpoint Interface > Use the game's inventory windows to use it in first person.",
    on = "on", off = "off",

    -- startup
    javaMissing = "Viewpoint Interface: Java part not loaded. Approve ViewpointUI in ZombieBuddy's prompt, then restart the game.",
    bridgeFailed = "Viewpoint Interface could not reach Viewpoint; it stays off. See console.txt.",
    disabledAfterErrors = "Viewpoint Interface stopped after repeated errors. See console.txt.",

    -- world interactions
    search = "Search",
    searchLocked = "Search (locked)",
    searchBody = "Search body",
    searchGround = "Search the ground (%s)",
    pickUp = "Pick up %s",
    inspect = "Inspect",
    ground = "Ground",
    body = "Body",

    -- tabs
    tabInventory = "INVENTORY",
    tabCrafting = "CRAFTING",
    tabBuild = "BUILD",
    tabHealth = "HEALTH",
    tabSkills = "SKILLS",
    tabCharacter = "CHARACTER",
    tabVehicle = "VEHICLE",
    tabAdmin = "ADMIN",
    tabFailed = "That screen could not open. See console.txt.",

    -- inventory
    invEquipment = "Equipment",
    invYou = "You",
    invNearby = "Nearby",
    invPrimary = "Primary hand",
    invSecondary = "Secondary hand",
    invEmpty = "empty",
    invEquipped = "equipped",
    invHotbar = "hotbar",
    invNothingNear = "Nothing in reach.",
    invTakeAll = "Take all",
    invStoreAll = "Put my items in",
    invUserPanel = "User panel",
    invFillMatching = "Fill with items like these",
    invDeleteAll = "Delete All",
    invDeleteAsk = "Delete all these items?",
    invDeleteAskCount = "Delete all %s items? They are gone for good.",
    invDeleteSure = "Last chance - really delete them?",
    invDeleteYes = "Yes, delete them",
    invDeleteCancel = "Keep them",
    invDeleteSent = "Emptying the bin...",
    invDeleteBlocked = "This server does not allow deleting items.",
    ammoLoading = "Loading %s rounds",
    ammoNoFit = "Those rounds do not go in there.",
    invTakeVerb = "Take",
    invMoveVerb = "Move",
    invPartOne = "%s one",
    invPartHalf = "%s half (%s)",
    invPartAmount = "%s how many...",
    invFilled = "%s item(s) put in",
    invNothingMatching = "Nothing in your inventory matches what is in it",
    invDropped = "Dropped %s",
    invTake = "Take",
    invMoveToContainer = "Move to container",
    invFavorite = "Favourite",
    invUnfavorite = "Unfavourite",
    invUnequip = "Take off",
    invHelp = "Drag onto a slot or your character: hold, wear, attach   Ctrl+drag: move part of a stack   Ctrl+click: quick move   Alt+click: equip / wear   Shift+click: pick several   Double-click: move one   Right-click: actions   R / T: take all / put in   F: favourite",
    invSearch = "Search",
    invSort = "Sort: %s",
    sort_name = "Name",
    sort_weight = "Weight",
    sort_type = "Type",
    sort_condition = "Condition",
    chipAll = "All",
    chipWeapons = "Weapons",
    chipAmmo = "Ammo",
    chipFood = "Food",
    chipMedical = "Medical",
    chipClothing = "Clothing",
    chipBags = "Bags",
    chipTools = "Tools",
    invGrid = "Grid",
    invList = "List",
    invGear = "Gear",
    invFavouriteKept = "%s is a favourite and stays with you",
    invBroken = "%s is broken",
    gearTwoHanded = "both hands",
    gearAttached = "Attached",
    gearNoAttach = "Wear a belt, holster or bag to get attachment slots.",
    gearDoesNotFit = "%s does not go in %s.",
    gearWornElsewhere = "%s is worn at %s.",
    gearDetach = "Detach",
    hotbarMoveLeft = "Hotbar: move left (slot %d)",
    hotbarMoveRight = "Hotbar: move right (slot %d)",
    hotbarBusy = "Finish what you are doing first",
    gearShow = "Show %s",
    menuUse = "USE",
    menuEquip = "EQUIP",
    menuCraft = "CRAFT",
    menuMove = "MOVE",
    menuOther = "OTHER",
    gearWornWeight = "Worn: %.1f kg",
    gearCover = "Body cover - bite %d%%   scratch %d%%   bullet %d%%",
    gearOpenBag = "Open bag",
    gearSwapped = "Swapped for %s",

    -- crafting / building
    craft = "Craft",
    place = "Place",
    allCategories = "All",
    noRecipes = "No recipes match.",
    pickRecipe = "Choose a recipe.",
    searchPlaceholder = "Search",
    recipeTool = "  (tool)",
    recipeKept = "  (kept)",
    recipeSkill = "%s %s (you: %s)",
    recipeLearned = "Recipe known",
    recipeNotLearned = "Recipe not learned",
    recipeTime = "Time %d:%02d",
    recipeMax = "Max",
    recipeFavourite = "Favourite",
    recipeUnfavourite = "Unfavourite",
    favourites = "Favourites",
    buildHint = "%s: place   %s: rotate   %s: stop",
    build_valid = "Can build here",
    build_blocked = "Can't build here",
    build_missing = "Missing materials, tools or skill",
    build_none = "Aim at the ground",
    placeHint = "%s: put down   %s / wheel: turn   %s: stop",
    placeSurfaceHint = "%s: other surface",
    place_valid = "Put it here (Shift: the whole stack)",
    place_valid_all = "Put the whole stack here",
    place_blocked = "Can't put it here",
    place_far = "Too far",
    -- moving furniture
    movePickUpAction = "Pick up %s",
    moveRotateAction = "Rotate %s",
    movePickup = "Pick up",
    movePlace = "Place",
    moveRotate = "Rotate",
    moveScrap = "Disassemble",
    moveRepair = "Repair",
    moveReady = "Ready",
    moveCannot = "Not possible here",
    moveNothing = "Aim at a spot",
    moveNotEmpty = "empty it first",
    moveTooHeavy = "too heavy to carry",
    moveNeedsTool = "tool or skill needed",
    moveHint = "%s: do it   wheel: turn / next   %s: stop",
    destroyTitle = "Destroy",
    destroyDismantle = "Dismantle",
    destroyReady = "Ready",
    destroyCannot = "Can't destroy this here",
    destroyNothing = "Aim at what to destroy",
    destroyHint = "%s: destroy   wheel: next object   %s: stop",
    -- vitals HUD
    hudStamina = "Stamina",
    hudHealth = "Health",
    -- quick loot
    qlTake = "Take",
    qlTakeAll = "Take all",
    qlOpen = "Open",
    qlSelect = "Select",
    qlEmpty = "Empty",
    qlYou = "You",
    qlMore = "%s more",
    qlTook = "Taking %s",
    qlCondition = "Condition %s%%",
    qlLeft = "%s%% left",
    place_none = "Aim at the floor or a surface",

    -- health / character
    healthFine = "No injuries.",
    healthPick = "Choose a body part.",
    healthTreatments = "Treatments",
    healthNoTreatment = "Nothing you carry treats this.",
    healthApply = "Treat",
    charTraits = "Traits",
    charNoTraits = "No traits.",
    charProtection = "Protection from clothing",
    charCoreTemp = "Body temperature %.1f C",

    -- vehicle
    vehSeatsInfo = "Seats and condition",
    vehSit = "Sit here",
    vehStorage = "Storage",
    vehMechanics = "Mechanics",
    vehTooFar = "Walk closer to the vehicle first.",
    vehMechanicsFailed = "Could not get to the vehicle's hood. Stand by the front of it and try again.",
    vehMissing = "missing",
    vehNone = "No vehicle. Aim at one or sit in one first.",
    vehEngineQuality = "Engine quality",

    -- admin
    adminPlayers = "Players online",
    adminNoPlayers = "Waiting for the server's player list...",
    adminSinglePlayer = "Single player (debug mode).",
    adminGoTo = "Go to",
    adminBring = "Bring here",
    adminGod = "God mode",
    adminInvisible = "Invisible",
    adminStats = "Stats",
    adminKick = "Kick",
    adminBan = "Ban",
    adminConfirm = "Click again to confirm.",
    adminNotLoaded = "That player is too far away to inspect from here.",
    adminSelf = "Yourself",
    adminState = "god %s  invisible %s  no clip %s",
    adminSelfGod = "God mode",
    adminSelfInvisible = "Invisible",
    adminSelfNoClip = "No clip",
    adminTarget = "Last target",
    adminNoTarget = "Aim at something, then open this tab.",
    adminTeleportHere = "Teleport there",
    adminHorde = "Horde manager there",
    adminRemoveVehicle = "Remove vehicle",
    adminTools = "Tools",
    adminPanel = "Admin panel",
    adminItems = "Item list",
    adminSpawnVehicle = "Spawn vehicle",
    adminRemoveItems = "Remove items",
    adminTeleportUI = "Teleport to...",
    build_building = "Building...",
    -- confirm prompt
    confirmYes = "yes",
    confirmNo = "no",
    -- the game's other tile cursors (Building/CursorMode.lua)
    cursorTitle = "Cursor",
    cursorReady = "Ready",
    cursorCannot = "Can't do that here",
    cursorNothing = "Aim at a spot",
    cursorObjects = "%d of %d",
    cursorHint = "%s: do it   wheel: turn / next   %s: stop",
    -- repair / disassemble furniture (Interaction/Providers.lua, vpui.moveable)
    moveRepairAction = "Repair %s",
    moveScrapAction = "Disassemble %s",
    moveNeedsParts = "parts needed",
    moveTooBroken = "too broken to repair",
    -- PvP safety and war readout (HUD/PvPHUD.lua)
    pvpOn = "PvP: ON",
    pvpOff = "PvP: OFF",
    pvpSafeZone = "Safe zone",
    pvpCountdown = "PvP %s in %.1f s",
    pvpCooldown = "Toggle cooldown %d s",
    pvpWar = "War: %s  %s",
    -- character tab additions (Screens/CharacterTabs.lua)
    charWarManager = "War manager",
    charSafetyOn = "PvP safety: on",
    charSafetyOff = "PvP safety: off",
    charSafetyWait = "PvP safety: switching",
    tabMap = "Map",
    healthOpening = "Opening the game's health window...",
    mapOpening = "Opening the world map...",
    charZones = "Zones",
    charInsulation = "Clothing insulation",
    charWeightTrend = { inc = "(gaining)", incLot = "(gaining fast)", dec = "(losing)" },
    -- foraging (Interaction/Forage.lua, HUD/SearchHUD.lua, Screens/SearchTab.lua)
    forageTitle = "Search",
    tabSearch = "Search",
    hudSearching = "Searching: %s",
    hudSpotted = "%s spotted",
    searchOn = "Search mode is on",
    searchOff = "Search mode is off",
    searchTurnOn = "Turn on search mode",
    searchTurnOff = "Turn off search mode",
    searchKeyHint = "%s toggles search mode",
    searchFocus = "Focus",
    searchSpotted = "Spotted",
    searchNoneSpotted = "Nothing spotted yet. With search mode on, look around slowly; what you notice is listed here.",
    searchOffHint = "Turn on search mode to look for things.",
    searchPickUp = "Pick up",
    searchUnavailable = "Search mode is not available.",
    searchDistance = "%.1f tiles",
}

-- PE RU v1.3: Keep Lua sources ASCII-only. Cyrillic literals in a Lua table
-- were truncated to their low Unicode byte by this B42/3D loading path:
-- the word for disassemble appeared as ASCII punctuation and digits.
-- Read translations from the game's Unicode-aware text manager instead.
local function peTranslated(key)
    if type(getTextOrNull) == "function" then
        local ok, value = pcall(getTextOrNull, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then
            return value
        end
    end
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then
            return value
        end
    end
    return nil
end

-- Our key -> the game's translation key with the same meaning.
local GAME_KEYS = {
    invTakeAll = "IGUI_invpage_Loot_all",
    -- the game already names these in every language
    invDeleteAll = "IGUI_invpage_RemoveAll",
    invDeleteAsk = "IGUI_ConfirmDeleteItems",
    invUnequip = "ContextMenu_Unequip",
    invUnfavorite = "ContextMenu_Unfavorite",
    craft = "IGUI_CraftingWindow_Craft",
    destroyTitle = "ContextMenu_Destroy",
    destroyDismantle = "ContextMenu_Dismantle",
}

local function useGameText()
    local text = ViewpointUI.Text
    for ours, key in pairs(GAME_KEYS) do
        local value = peTranslated(key)
        if value then text[ours] = value end
    end
    -- Vanilla RU fallback works even if our custom translation is absent.
    local scrap = peTranslated("ContextMenu_Disassemble") or peTranslated("IGUI_Scrap") or "Disassemble"
    text.moveScrap = peTranslated("UI_ProjectEcho_VPUI_moveScrap") or scrap
    text.moveScrapAction = peTranslated("UI_ProjectEcho_VPUI_moveScrapAction") or (scrap .. " %s")
end

-- B42 can initialize translations during boot; refresh again on join.
Events.OnGameBoot.Add(useGameText)
Events.OnGameStart.Add(useGameText)
