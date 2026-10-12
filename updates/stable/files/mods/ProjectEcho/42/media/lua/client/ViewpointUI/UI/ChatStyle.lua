--
-- Viewpoint UI - chat box in the Viewpoint style.
--
-- The game's chat window (client/Chat/ISChat.lua) stays the authority: its
-- tabs, streams, commands, fade, lock/gear buttons, resizing and saved layout
-- are untouched. While the interface is active only the drawing changes:
--   - the window and title bar use the Viewpoint panel colours instead of the
--     vanilla title-bar texture and snail icon; the slow-mode title is amber
--   - a thin amber line marks the chat as focused, and the text entry gets a
--     Viewpoint border instead of the vanilla frame
--   - the tab strip (servers with several chat tabs) is drawn as Viewpoint tabs
--   - the window keeps the game's own fade, so it still dims when idle
-- When the interface stands down the vanilla drawing comes back unchanged.
--
-- Reproduced from ISChat:prerender (fade, gear button hookup, instance),
-- ISCollapsableWindow:render (resize grip, clear stencil) and ISTabPanel:render
-- (tab x positions: inset 1, gap 1, scrollX, tabWidth per view).
--

require "Chat/ISChat"
require "ISUI/ISTabPanel"
require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.ChatStyle then return end

local ChatStyle = {}
VPUI.UI.ChatStyle = ChatStyle

local Theme = VPUI.UI.Theme
local C = Theme.color
local Log = VPUI.Log

ChatStyle.on = false

-- Called by the controller every tick.
function ChatStyle.set(on)
    on = on == true and not ChatStyle.broken
    if on == ChatStyle.on then return end
    ChatStyle.on = on
    local chat = ISChat and ISChat.instance
    if chat and chat.textEntry then
        -- the vanilla text-entry frame is a texture; our border replaces it
        pcall(function() chat.textEntry:setHasFrame(not on) end)
        chat.vpFrameOff = on
        if not on and chat.textEntry.backgroundColor then
            chat.textEntry.backgroundColor.r, chat.textEntry.backgroundColor.g, chat.textEntry.backgroundColor.b = 0, 0, 0
        end
        if not on and chat.panel and chat.panel.vpOriginalBg then
            local bg, o = chat.panel.backgroundColor, chat.panel.vpOriginalBg
            bg.r, bg.g, bg.b = o.r, o.g, o.b
        end
    end
end

---------------------------------------------------------------------------
-- tab strip
---------------------------------------------------------------------------

local function styledTabs(panel)
    if not ChatStyle.on then return end
    if not panel.viewList or #panel.viewList < 2 or panel.isDragging then return end
    local widthOfAll = panel:getWidthOfAllTabs()
    if widthOfAll > panel.width then return end -- overflowing strip keeps the vanilla arrows
    local x = 1
    if panel.centerTabs then
        x = (panel:getWidth() - widthOfAll) / 2
    else
        x = x + (panel.scrollX or 0)
    end
    local th = panel.tabHeight - 1
    local alpha = panel.tabTransparency or 1
    local textAlpha = panel.textTransparency or 1
    -- cover the vanilla tab textures with one strip
    panel:drawRect(0, 0, panel.width, th, alpha, C.panel.r, C.panel.g, C.panel.b)
    for _, view in ipairs(panel.viewList) do
        local tw = panel.equalTabWidth and panel.maxLength or view.tabWidth
        local current = panel.activeView and view.id == panel.activeView.id
        if current then
            panel:drawRect(x, 0, tw, th, alpha, C.panelHi.r, C.panelHi.g, C.panelHi.b)
            panel:drawRect(x, th - 2, tw, 2, alpha, C.accent.r, C.accent.g, C.accent.b)
        end
        local c = current and C.text or C.dim
        local blink = panel.blinkTab == view.name
        if not blink and panel.blinkTabs then
            for _, name in ipairs(panel.blinkTabs) do
                if name == view.name then blink = true end
            end
        end
        if blink and not current then c = C.accent end
        panel:drawTextCentre(view.name, x + tw / 2, 3, c.r, c.g, c.b, textAlpha, UIFont.Small)
        x = x + tw + 1
    end
end

local function hookPanel(chat)
    local panel = chat.panel
    if not panel or panel.vpWrapped then return end
    panel.vpWrapped = true
    local bg = panel.backgroundColor
    if bg then panel.vpOriginalBg = { r = bg.r, g = bg.g, b = bg.b } end
    local original = panel.render
    panel.render = function(self)
        original(self)
        local ok, err = pcall(styledTabs, self)
        if not ok then Log.once(Log.WARN, "chatTabs", "chat tab styling failed: " .. tostring(err)) end
    end
end

---------------------------------------------------------------------------
-- window
---------------------------------------------------------------------------

local function styledPrerender(self)
    ISChat.instance = self
    self.gearButton.onclick = self.onGearButtonClick
    self:setDrawFrame(true)
    if not ISChat.focused then
        self.fade:update()
    end
    hookPanel(self)
    -- colours first; makeFade only sets the alphas
    if self.textEntry and not self.vpFrameOff then
        -- a chat created after the style came on (reconnect) loses its frame here
        self.textEntry:setHasFrame(false)
        self.vpFrameOff = true
    end
    if self.textEntry and self.textEntry.backgroundColor then
        local t = self.textEntry.backgroundColor
        t.r, t.g, t.b = C.panelHi.r, C.panelHi.g, C.panelHi.b
    end
    if self.panel and self.panel.backgroundColor then
        local p = self.panel.backgroundColor
        p.r, p.g, p.b = C.panel.r, C.panel.g, C.panel.b
    end
    self:makeFade(self.fade:fraction())

    local a = self.backgroundColor.a or 0
    local th = self:titleBarHeight()
    self:drawRect(0, 0, self.width, self.height, a * 0.85, C.panel.r, C.panel.g, C.panel.b)
    local barAlpha = self:calcAlpha(ISChat.minControlOpaque, ISChat.maxGeneralOpaque, self.fade:fraction())
    self:drawRect(0, 0, self.width, th, barAlpha * 0.8, C.panelHi.r, C.panelHi.g, C.panelHi.b)
    if ISChat.focused then
        self:drawRect(0, th - 1, self.width, 1, 0.9, C.accent.r, C.accent.g, C.accent.b)
    end
    if self.title ~= nil and self.drawFrame then
        self:drawTextCentre(self.title, self.width / 2, 1, C.accent.r, C.accent.g, C.accent.b, 1, self.titleBarFont)
    end
end

local function styledRender(self)
    local th = self:titleBarHeight()
    local height = self.isCollapsed and th or self:getHeight()
    local fade = self.backgroundColor.a or 0
    if not self.isCollapsed and self.resizable and self.drawFrame and self.resizeWidget:getIsVisible() then
        local rh = self:resizeWidgetHeight()
        local wa = self.widgetTextureColor and self.widgetTextureColor.a or 1
        self:drawRect(0, height - rh, self.width, rh, wa * 0.6, C.panelHi.r, C.panelHi.g, C.panelHi.b)
        self:drawTextureScaled(self.resizeimage, self.width - rh + 1, height - rh + 1, rh - 2, rh - 2, wa, C.dim.r, C.dim.g, C.dim.b)
    end
    if self.clearStentil then
        self:clearStencilRect()
    end
    if self.drawFrame then
        local b = self.borderColor
        if self.showSlowModeFeedback and b and b.a > 0 then
            self:drawRectBorder(0, 0, self.width, height, b.a, b.r, b.g, b.b)
        else
            self:drawRectBorder(0, 0, self.width, height, math.max(C.edge.a, 0.12 * fade), 1, 1, 1)
        end
    end
    local te = self.textEntry
    if te and te:getIsVisible() and not self.isCollapsed then
        if ISChat.focused then
            self:drawRectBorder(te:getX() - 1, te:getY() - 1, te:getWidth() + 2, te:getHeight() + 2, 0.8, C.accent.r, C.accent.g, C.accent.b)
        else
            self:drawRectBorder(te:getX() - 1, te:getY() - 1, te:getWidth() + 2, te:getHeight() + 2, 0.15 * fade, 1, 1, 1)
        end
    end
    if self.drawJoypadFocus then
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, C.accent.r, C.accent.g, C.accent.b)
    end
end

local wrapped = false
local function wrap()
    if wrapped or not ISChat then return end
    wrapped = true
    local prerender, render = ISChat.prerender, ISChat.render
    ISChat.prerender = function(self)
        if ChatStyle.on then
            local ok, err = pcall(styledPrerender, self)
            if ok then return end
            Log.once(Log.WARN, "chatPrerender", "chat styling failed, vanilla look kept: " .. tostring(err))
            ChatStyle.broken = true
            ChatStyle.set(false)
        end
        return prerender(self)
    end
    ISChat.render = function(self)
        if ChatStyle.on then
            local ok, err = pcall(styledRender, self)
            if ok then return end
            Log.once(Log.WARN, "chatRender", "chat styling failed, vanilla look kept: " .. tostring(err))
            ChatStyle.broken = true
            ChatStyle.set(false)
        end
        return render(self)
    end
end
wrap()
