--
-- Viewpoint UI - visual language: colours, fonts, spacing and the scale rule
-- every widget uses, so the interface reads as one system and follows the
-- game's font-size option plus the add-on's own size slider.
--

require "ViewpointUI/Core"
require "ViewpointUI/Settings"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.Theme then return end

local Theme = {}
VPUI.UI.Theme = Theme

-- Understated, slightly warm greys with one amber accent; red only for danger.
Theme.color = {
    panel   = { r = 0.045, g = 0.050, b = 0.055, a = 0.66 },
    panelHi = { r = 0.090, g = 0.095, b = 0.100, a = 0.80 },
    edge    = { r = 1.00, g = 1.00, b = 1.00, a = 0.07 },
    text    = { r = 0.93, g = 0.92, b = 0.88, a = 1.00 },
    dim     = { r = 0.64, g = 0.64, b = 0.61, a = 1.00 },
    off     = { r = 0.46, g = 0.46, b = 0.45, a = 1.00 },
    accent  = { r = 0.94, g = 0.69, b = 0.30, a = 1.00 },
    danger  = { r = 0.86, g = 0.31, b = 0.26, a = 1.00 },
    good    = { r = 0.58, g = 0.78, b = 0.52, a = 1.00 },
    keycap  = { r = 1.00, g = 1.00, b = 1.00, a = 0.10 },
    track   = { r = 1.00, g = 1.00, b = 1.00, a = 0.12 },
}

local fontHeights = {}

function Theme.fontHeight(font)
    local h = fontHeights[font]
    if not h then
        h = getTextManager():getFontHeight(font)
        fontHeights[font] = h
    end
    return h
end

-- Body font: one step larger when the size slider is well above 1.
function Theme.font()
    local scale = tonumber(VPUI.Settings.get("uiScale")) or 1
    if scale >= 1.45 then return UIFont.Medium end
    return UIFont.Small
end

function Theme.smallFont()
    return UIFont.Small
end

-- Spacing in pixels for a design value given at 1080p with the default font.
-- Follows the game's own font size option (the small font's height) and the
-- add-on's size slider, so it holds from 720p to 4K.
function Theme.px(n)
    local scale = tonumber(VPUI.Settings.get("uiScale")) or 1
    local unit = Theme.fontHeight(UIFont.Small) / 15
    return math.floor(n * scale * unit + 0.5)
end

local widths = {}
local widthCount = 0

-- Cached string width; the cache is dropped when it grows past a few hundred
-- entries, so a long session cannot leak memory through it.
function Theme.textWidth(font, text)
    local byFont = widths[font]
    if not byFont then
        byFont = {}
        widths[font] = byFont
    end
    local w = byFont[text]
    if not w then
        if widthCount > 400 then
            widths = {}
            widthCount = 0
            byFont = {}
            widths[font] = byFont
        end
        w = getTextManager():MeasureStringX(font, text)
        byFont[text] = w
        widthCount = widthCount + 1
    end
    return w
end

function Theme.screenCenter()
    local core = getCore()
    return math.floor(core:getScreenWidth() / 2), math.floor(core:getScreenHeight() / 2)
end

function Theme.resetCaches()
    fontHeights = {}
    widths = {}
    widthCount = 0
end

Events.OnResolutionChange.Add(function()
    Theme.resetCaches()
    VPUI.Events.fire("LayoutChanged")
end)
VPUI.Events.add("SettingsChanged", function()
    Theme.resetCaches()
    VPUI.Events.fire("LayoutChanged")
end)
