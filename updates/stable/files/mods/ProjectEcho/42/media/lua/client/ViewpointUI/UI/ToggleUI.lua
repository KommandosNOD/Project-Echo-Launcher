--
-- Viewpoint UI - the game's Toggle UI key.
--
-- The game hides its UI in ISUIHandler (client/ISUI/ISUIHandler.lua):
-- onKeyPressed -> toggleUI flips ISUIHandler.allUIVisible and calls
-- setVisibleAllUI, which walks UIManager.getUI(), hides every visible element and
-- remembers it by toString() so the same ones come back. (UIManager.visibleAllUi
-- itself only hides the moodles and speed controls; the walk does the rest.)
--
-- Three things make that dependable with this add-on loaded:
--
--   * The walk runs element by element under pcall, so one element that fails
--     cannot stop it half way (the vanilla loop has no protection: an error
--     leaves allUIVisible flipped with only part of the UI hidden).
--   * Every toggle is written to console.txt, so a report can be checked.
--   * A fallback: the game only runs toggleUI from OnKeyPressed, which is not
--     sent while any text box holds keyboard focus, or when a visible UI element
--     takes the key. When the Toggle UI key is let go, the game's own conditions
--     hold (no vehicle or animal to interact with, not the tutorial, nothing
--     being typed, no map or modal window up) and the game did not toggle within
--     a few frames, it is toggled here, once, with a warning in the log.
--
-- Our own widgets stay hidden while the UI is off through Util.uiHidden()
-- (VPElement:display, the vanilla HUD hider, the hotbar, the controller).
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.ToggleUI then return end

local ToggleUI = {}
VPUI.UI.ToggleUI = ToggleUI

local Log = VPUI.Log

local FALLBACK_MS = 120    -- the game's OnKeyPressed runs in the same frame as the release

local toggledAt = 0        -- last ISUIHandler.toggleUI call
local wasDown = false
local releasedAt = 0       -- pending release of the Toggle UI key, 0 = none
local releaseFrom = 0      -- the release happened after this time (the tick before)
local lastTick = 0

---------------------------------------------------------------------------
-- The walk, element by element
---------------------------------------------------------------------------

local function safeSetVisibleAll(visible)
    local ui = UIManager.getUI()
    local failed = 0
    if not visible then
        for i = 0, ui:size() - 1 do
            local ok = pcall(function()
                local el = ui:get(i)
                if el:isVisible() then
                    table.insert(ISUIHandler.visibleUI, el:toString())
                    el:setVisible(false)
                end
            end)
            if not ok then failed = failed + 1 end
        end
    else
        for _, name in ipairs(ISUIHandler.visibleUI) do
            for i = 0, ui:size() - 1 do
                local ok, done = pcall(function()
                    local el = ui:get(i)
                    if name == el:toString() and not el:isVisible() then
                        el:setVisible(true)
                        return true
                    end
                    return false
                end)
                if not ok then failed = failed + 1 end
                if ok and done then break end
            end
        end
        table.wipe(ISUIHandler.visibleUI)
    end
    UIManager.setVisibleAllUI(visible)
    return failed
end

local installed = false
function ToggleUI.install()
    if installed or not ISUIHandler then return end
    installed = true

    local originalSet = ISUIHandler.setVisibleAllUI
    ISUIHandler.setVisibleAllUI = function(visible)
        local ok, failed = pcall(safeSetVisibleAll, visible)
        if not ok then
            Log.error("hiding/showing the UI failed (" .. tostring(failed) .. "); using the game's own walk")
            return originalSet(visible)
        end
        if failed > 0 then
            Log.warn("Toggle UI: " .. tostring(failed) .. " UI element(s) could not be " .. (visible and "shown" or "hidden"))
        end
    end

    local originalToggle = ISUIHandler.toggleUI
    ISUIHandler.toggleUI = function(...)
        toggledAt = getTimestampMs()
        releasedAt = 0
        local r = originalToggle(...)
        Log.info("Toggle UI: the UI is now " .. (ISUIHandler.allUIVisible and "shown" or "hidden"))
        return r
    end
    Log.info("Toggle UI support installed")
end

---------------------------------------------------------------------------
-- Fallback for a release the game never saw
---------------------------------------------------------------------------

local function toggleKey()
    local ok, k = pcall(function() return getCore():getKey(KeybindId.TOGGLE_UI) end)
    if ok and type(k) == "number" and k > 0 then return k end
    return nil
end

local function visible(el)
    if not el then return false end
    local ok, v = pcall(function() return el:isReallyVisible() end)
    return ok and v == true
end

-- The same conditions ISUIHandler.onKeyPressed checks, plus what would have
-- taken the key on purpose.
local function gameWouldToggle()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return false end
    local ok, v = pcall(function() return getCore():getGameMode() end)
    if ok and v == "Tutorial" then return false end
    ok, v = pcall(function() return getCore():isDoingTextEntry() end)
    if not ok or v == true then return false end
    if ISChat and ISChat.focused then return false end
    ok, v = pcall(function() return UIManager.isModalVisible() end)
    if ok and v == true then return false end
    if MainScreen and MainScreen.instance and visible(MainScreen.instance) then return false end
    if ISWorldMap and visible(ISWorldMap.instance) then return false end
    ok, v = pcall(ISVehicleMenu.getVehicleToInteractWith, player)
    if not ok or v then return false end
    if AnimalContextMenu and AnimalContextMenu.getAnimalToInteractWith then
        ok, v = pcall(AnimalContextMenu.getAnimalToInteractWith, player)
        if not ok or v then return false end
    end
    return true
end

-- Per tick (OnTickEvenPaused).
function ToggleUI.tick()
    if not installed then return end
    local key = toggleKey()
    if not key then wasDown = false return end
    local down = isKeyDown(key) == true
    local now = getTimestampMs()
    if wasDown and not down then
        -- judged now, before the vehicle/animal or a text box can change; the
        -- game handles the release between the previous tick and this one
        releasedAt = gameWouldToggle() and now or 0
        releaseFrom = lastTick
    end
    wasDown = down
    lastTick = now
    if releasedAt > 0 and now - releasedAt >= FALLBACK_MS then
        local missed = toggledAt < releaseFrom
        releasedAt = 0
        if missed then
            Log.warn("Toggle UI: the game did not see the key (another UI element or a text box took it); toggling here")
            ISUIHandler.toggleUI()
        end
    end
end

return ToggleUI
