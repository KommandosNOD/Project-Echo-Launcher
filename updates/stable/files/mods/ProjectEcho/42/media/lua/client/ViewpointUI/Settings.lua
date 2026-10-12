--
-- Viewpoint UI - settings, on the game's own Mod Options page
-- (Options > Mods > Viewpoint Interface). Values persist in ModOptions.ini
-- through PZAPI.ModOptions, like every other mod option.
--

require "ViewpointUI/Core"
require "PZAPI/ModOptions"

local VPUI = ViewpointUI
if VPUI.Settings then return end

local Settings = {}
VPUI.Settings = Settings

local PAGE_ID = "VPInterface"

-- Defaults double as the fallback when the options page could not be built.
local DEFAULTS = {
    enabled = true,
    interactKey = Keyboard.KEY_E,
    cancelKey = Keyboard.KEY_BACK,
    buildKey = Keyboard.KEY_K,
    adminKey = Keyboard.KEY_F7,
    holdTime = 0.35,
    quickLoot = true,
    quickLootTakeAllKey = Keyboard.KEY_NONE,
    interactStyle = 2, -- index into the combo: 1 Hold for the menu, 2 Scroll, 3 Vanilla
    uiScale = 1.0,
    showPrompt = true,
    showReticle = true,
    statusHud = true,
    vitalsHud = true,
    weaponHud = true,
    hotbarHud = true,
    progressHud = true,
    hideVanillaHud = true,
    styleChat = true,
    radialMouse = true,
    vanillaCrafting = false,
    compactUI = false,
    quickDropKey = Keyboard.KEY_G,
    itemTileSize = 1, -- index into the combo: 1 Small, 2 Medium, 3 Large
    showMinimap = true,
    vanillaInventory = false,
    keepSidebar = false,
    keepMoodles = false,
    freeCursorWindows = true,
    legacyFallback = false,
    logLevel = 2, -- index into the combo: 1 Errors .. 5 Trace
}

local page

local function build()
    if page or not (PZAPI and PZAPI.ModOptions) then return end
    page = PZAPI.ModOptions:create(PAGE_ID, getText("UI_ProjectEcho_VPUI_Settings_RU_001"))

    page:addTitle(getText("UI_ProjectEcho_VPUI_Settings_RU_002"))
    page:addTickBox("enabled", getText("UI_ProjectEcho_VPUI_Settings_RU_003"), DEFAULTS.enabled,
        getText("UI_ProjectEcho_VPUI_Settings_RU_004"))
    page:addKeyBind("interactKey", getText("UI_ProjectEcho_VPUI_Settings_RU_005"), DEFAULTS.interactKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_006"))
    page:addKeyBind("cancelKey", getText("UI_ProjectEcho_VPUI_Settings_RU_007"), DEFAULTS.cancelKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_008"))
    page:addKeyBind("buildKey", getText("UI_ProjectEcho_VPUI_Settings_RU_009"), DEFAULTS.buildKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_010"))
    page:addKeyBind("adminKey", getText("UI_ProjectEcho_VPUI_Settings_RU_011"), DEFAULTS.adminKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_012"))
    local style = page:addComboBox("interactStyle", getText("UI_ProjectEcho_VPUI_Settings_RU_013"),
        getText("UI_ProjectEcho_VPUI_Settings_RU_014"))
    style:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_015"), DEFAULTS.interactStyle == 1)
    style:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_016"), DEFAULTS.interactStyle == 2)
    style:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_017"), DEFAULTS.interactStyle == 3)
    page:addTickBox("quickLoot", getText("UI_ProjectEcho_VPUI_Settings_RU_018"), DEFAULTS.quickLoot,
        getText("UI_ProjectEcho_VPUI_Settings_RU_019"))
    page:addKeyBind("quickLootTakeAllKey", getText("UI_ProjectEcho_VPUI_Settings_RU_020"), DEFAULTS.quickLootTakeAllKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_021"))
    page:addSlider("holdTime", getText("UI_ProjectEcho_VPUI_Settings_RU_022"), 0.15, 1.0, 0.05, DEFAULTS.holdTime,
        getText("UI_ProjectEcho_VPUI_Settings_RU_023"))

    page:addTitle(getText("UI_ProjectEcho_VPUI_Settings_RU_024"))
    page:addSlider("uiScale", getText("UI_ProjectEcho_VPUI_Settings_RU_025"), 0.75, 2.0, 0.05, DEFAULTS.uiScale,
        getText("UI_ProjectEcho_VPUI_Settings_RU_026"))
    page:addTickBox("showPrompt", getText("UI_ProjectEcho_VPUI_Settings_RU_027"), DEFAULTS.showPrompt,
        getText("UI_ProjectEcho_VPUI_Settings_RU_028"))
    page:addTickBox("showReticle", getText("UI_ProjectEcho_VPUI_Settings_RU_029"), DEFAULTS.showReticle,
        getText("UI_ProjectEcho_VPUI_Settings_RU_030"))
    page:addTickBox("progressHud", getText("UI_ProjectEcho_VPUI_Settings_RU_031"), DEFAULTS.progressHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_032"))
    page:addTickBox("statusHud", getText("UI_ProjectEcho_VPUI_Settings_RU_033"), DEFAULTS.statusHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_034"))
    page:addTickBox("vitalsHud", getText("UI_ProjectEcho_VPUI_Settings_RU_035"), DEFAULTS.vitalsHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_036"))
    page:addTickBox("weaponHud", getText("UI_ProjectEcho_VPUI_Settings_RU_037"), DEFAULTS.weaponHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_038"))
    page:addTickBox("hotbarHud", getText("UI_ProjectEcho_VPUI_Settings_RU_039"), DEFAULTS.hotbarHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_040"))
    page:addTickBox("radialMouse", getText("UI_ProjectEcho_VPUI_Settings_RU_041"), DEFAULTS.radialMouse,
        getText("UI_ProjectEcho_VPUI_Settings_RU_042"))
    page:addTickBox("vanillaCrafting", getText("UI_ProjectEcho_VPUI_Settings_RU_043"), DEFAULTS.vanillaCrafting,
        getText("UI_ProjectEcho_VPUI_Settings_RU_044"))
    page:addKeyBind("quickDropKey", getText("UI_ProjectEcho_VPUI_Settings_RU_045"), DEFAULTS.quickDropKey,
        getText("UI_ProjectEcho_VPUI_Settings_RU_046"))
    local tiles = page:addComboBox("itemTileSize", getText("UI_ProjectEcho_VPUI_Settings_RU_047"),
        getText("UI_ProjectEcho_VPUI_Settings_RU_048"))
    tiles:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_049"), DEFAULTS.itemTileSize == 1)
    tiles:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_050"), DEFAULTS.itemTileSize == 2)
    tiles:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_051"), DEFAULTS.itemTileSize == 3)
    page:addTickBox("compactUI", getText("UI_ProjectEcho_VPUI_Settings_RU_052"), DEFAULTS.compactUI,
        getText("UI_ProjectEcho_VPUI_Settings_RU_053"))
    page:addTickBox("styleChat", getText("UI_ProjectEcho_VPUI_Settings_RU_054"), DEFAULTS.styleChat,
        getText("UI_ProjectEcho_VPUI_Settings_RU_055"))
    page:addTickBox("showMinimap", getText("UI_ProjectEcho_VPUI_Settings_RU_056"), DEFAULTS.showMinimap,
        getText("UI_ProjectEcho_VPUI_Settings_RU_057"))
    page:addTickBox("hideVanillaHud", getText("UI_ProjectEcho_VPUI_Settings_RU_058"), DEFAULTS.hideVanillaHud,
        getText("UI_ProjectEcho_VPUI_Settings_RU_059"))

    page:addTitle(getText("UI_ProjectEcho_VPUI_Settings_RU_060"))
    page:addTickBox("vanillaInventory", getText("UI_ProjectEcho_VPUI_Settings_RU_061"), DEFAULTS.vanillaInventory,
        getText("UI_ProjectEcho_VPUI_Settings_RU_062"))
    page:addTickBox("keepSidebar", getText("UI_ProjectEcho_VPUI_Settings_RU_063"), DEFAULTS.keepSidebar,
        getText("UI_ProjectEcho_VPUI_Settings_RU_064"))
    page:addTickBox("keepMoodles", getText("UI_ProjectEcho_VPUI_Settings_RU_065"), DEFAULTS.keepMoodles,
        getText("UI_ProjectEcho_VPUI_Settings_RU_066"))
    page:addTickBox("freeCursorWindows", getText("UI_ProjectEcho_VPUI_Settings_RU_067"), DEFAULTS.freeCursorWindows,
        getText("UI_ProjectEcho_VPUI_Settings_RU_068"))

    page:addTitle(getText("UI_ProjectEcho_VPUI_Settings_RU_069"))
    page:addTickBox("legacyFallback", getText("UI_ProjectEcho_VPUI_Settings_RU_070"), DEFAULTS.legacyFallback,
        getText("UI_ProjectEcho_VPUI_Settings_RU_071"))
    local combo = page:addComboBox("logLevel", getText("UI_ProjectEcho_VPUI_Settings_RU_072"), getText("UI_ProjectEcho_VPUI_Settings_RU_073"))
    combo:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_074"), false)
    combo:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_075"), true)
    combo:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_076"), false)
    combo:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_077"), false)
    combo:addItem(getText("UI_ProjectEcho_VPUI_Settings_RU_078"), false)

    page.apply = function()
        VPUI.Events.fire("SettingsChanged")
    end
end

function Settings.get(id)
    local option = page and page:getOption(id)
    if option then
        local value = option:getValue()
        if value ~= nil then return value end
    end
    return DEFAULTS[id]
end

-- "hold", "scroll" or "vanilla"
function Settings.interactStyle()
    local v = tonumber(Settings.get("interactStyle")) or DEFAULTS.interactStyle
    if v == 1 then return "hold" elseif v == 3 then return "vanilla" end
    return "scroll"
end

function Settings.default(id)
    return DEFAULTS[id]
end

function Settings.page()
    return page
end

local function syncLogLevel()
    local level = tonumber(Settings.get("logLevel")) or DEFAULTS.logLevel
    VPUI.Log.level = VPUI.Util.clamp(math.floor(level), 1, 5)
end

VPUI.Events.add("SettingsChanged", syncLogLevel)

build()
Events.OnGameStart.Add(function()
    -- Viewpoint does the same on game start; loading twice is harmless.
    PZAPI.ModOptions:load()
    syncLogLevel()
end)
