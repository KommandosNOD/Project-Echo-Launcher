-- ProjectEchoDeadDaysRU - game-safe UI localization overlay for B42.
require "ProjectEchoDeadDaysRU/PEDeadDaysRU_Dictionary"
local R = PEDeadDaysRU
local installed = false
local function install()
    if installed then return end
    if not DDS or not DDS.UI or not DDS.UI.sentence or not DDS.UI.wrap or not DDSPanel then return end
    local UI = DDS.UI
    local sentence0, wrap0 = UI.sentence, UI.wrap
    UI.sentence = function(s)
        return sentence0(R.translate(s))
    end
    UI.wrap = function(text, font, width)
        return wrap0(R.translate(text), font, width)
    end
    -- The text animation in the original mod uses byte-based string.sub.
    -- UTF-8 Cyrillic is multibyte. Reveal translated lines at once instead
    -- of cutting a Cyrillic character in the middle of its bytes.
    if DDSDialogue and DDSDialogue.setView then
        local setView0 = DDSDialogue.setView
        DDSDialogue.setView = function(self, view)
            local isTranslated = false
            if view then
                if type(view.text) == 'string' then
                    local ru = R.translate(view.text)
                    if ru ~= view.text then view.text = ru; isTranslated = true end
                end
                if view.title then view.title = R.translate(view.title) end
                if view.speaker then view.speaker = R.translate(view.speaker) end
                for _, choice in ipairs(view.choices or {}) do
                    if choice.text then choice.text = R.translate(choice.text) end
                end
            end
            setView0(self, view)
            if isTranslated then self.shownAt = 0 end
        end
    end
    -- Translate on-screen toasts without changing original server messages.
    if UI.Toast and UI.Toast.push then
        local push0 = UI.Toast.push
        UI.Toast.push = function(txt, tone, ...)
            return push0(R.translate(txt), tone, ...)
        end
    end
    -- Only rewrite recognised Dead Days context options, never other mods' menus.
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
            if test or not context or not context.options then return end
            local function process(menu, level)
                if not menu or not menu.options or level > 3 then return end
                for _, option in ipairs(menu.options) do
                    if option.name then option.name = R.translate(option.name) end
                    if option.subOption then process(option.subOption, level + 1) end
                end
            end
            process(context, 0)
        end)
    end
    installed = true
    print('[PROJECT ECHO] Dead Days RU client text overlay enabled')
end
Events.OnGameStart.Add(install)
Events.OnCreatePlayer.Add(install)
-- Some installs lazy-load DDS UI; remove this probe as soon as it succeeds.
local function probe()
    install()
    if installed then Events.OnTick.Remove(probe) end
end
Events.OnTick.Add(probe)
