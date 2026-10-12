--
-- Viewpoint UI - the mouse cursor in the pause menu.
--
-- Viewpoint frees the cursor when the game is paused (GameTime.isGamePaused).
-- In multiplayer the Esc menu does not pause the game, so the cursor stayed
-- captured for mouse-look and the menu could not be clicked. While the in-game
-- main menu (MainScreen.instance with inGame = true, opened by ToggleEscapeMenu)
-- is visible, the cursor is freed through Viewpoint's own cursor mode; when the
-- menu closes it goes back to what it was. In single player, where the menu
-- pauses the game, Viewpoint restores its own state on unpause, so only the
-- freeing is done here.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.PauseCursor then return end

local PauseCursor = {}
VPUI.UI.PauseCursor = PauseCursor

local Bridge = VPUI.Bridge

local managing = false
local before = nil     -- cursor mode before the menu opened (nil: Viewpoint restores it)

function PauseCursor.menuOpen()
    local ms = MainScreen and MainScreen.instance
    if not ms or ms.inGame ~= true then return false end
    local ok, v = pcall(function() return ms:isVisible() end)
    return ok and v == true
end

-- Per tick (OnTickEvenPaused).
function PauseCursor.tick()
    if not Bridge.ready() then return end
    local open = PauseCursor.menuOpen()
    if open then
        if not managing then
            managing = true
            if isGamePaused() then
                before = nil
            else
                before = Bridge.call("cursorFree", false) == true
            end
        end
        if Bridge.call("cursorFree", false) ~= true then
            Bridge.call("setCursorFree", false, true)
        end
    elseif managing then
        managing = false
        if before ~= nil then Bridge.call("setCursorFree", false, before) end
        before = nil
    end
end

function PauseCursor.isManaging()
    return managing
end
