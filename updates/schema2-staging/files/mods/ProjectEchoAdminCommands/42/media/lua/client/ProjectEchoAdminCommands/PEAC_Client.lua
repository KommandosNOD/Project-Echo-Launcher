-- PROJECT ECHO Admin Commands v0.1.2 TEST - PZ B42.21 MP
-- Fix chat focus/input lock regression from 0.1.0.
-- SAFE: NEVER overwrite ISChat.onCommandEntered (class method).
-- Intercepts only current chat textEntry; delegates every other chat message.

local PREFIX = "[PE-AdminCmd] "
local MODULE = "ProjectEchoAdminCommands"
local boundEntry = nil
local wrappedCallback = nil
local previousCallback = nil
local retries = 0

local function log(value)
    print(PREFIX .. tostring(value))
end

-- The game's chat window accepts ChatMessage-like objects via ISChat.addLineInChat.
-- We keep our responses local (never broadcast) and never send text to halo/speech.
-- Unlike direct edits to chatTextLines, this preserves chatMessages for font changes.
local function addLocalChatLine(line)
    local chat = ISChat and ISChat.instance
    if not chat or not chat.chatText or not chat.chatText.tabID or not ISChat.addLineInChat then
        return false, "Chat UI not initialized"
    end
    -- Escape markup: the rich text widget uses angle bracket directives.
    local safe = tostring(line or ""):gsub("<", "["):gsub(">", "]")
    local fake = {text = "[PE] " .. safe}
    function fake:getTextWithPrefix() return self.text end
    function fake:getAuthor() return nil end
    function fake:setText(v) self.text = tostring(v or "") end
    local ok, err = pcall(function()
        ISChat.addLineInChat(fake, chat.chatText.tabID)
        if chat.fade then
            chat.fade:reset()
            chat.fade:update()
        end
    end)
    if not ok then return false, tostring(err) end
    return true
end

local function show(message, bad)
    message = tostring(message or "")
    log((bad and "ERROR: " or "") .. message)
    local lineCount = 0
    -- Keep each help command readable as its own chat line.
    for part in (message .. "\n"):gmatch("(.-)\n") do
        lineCount = lineCount + 1
        if lineCount > 15 then break end
        local ok, err = addLocalChatLine((bad and "! " or "") .. part)
        if not ok then
            log("chat output unavailable: " .. tostring(err))
            break
        end
    end
end

local function parseLine(s)
    if type(s) ~= "string" then return nil end
    local command, arguments = s:match("^%s*/(%S+)%s*(.-)%s*$")
    if command and command:lower() == "pe" then return arguments end
    return nil
end

local function closeChat(chat)
    -- Reproduce the native completion flow from ISChat:onCommandEntered.
    -- On this game build these calls are important for restoring movement keys.
    local ok, err = pcall(function() chat:unfocus() end)
    if not ok then
        log("unfocus failed: " .. tostring(err))
        pcall(function()
            chat.textEntry:unfocus()
            chat.textEntry:setText("")
            chat.textEntry:setEditable(false)
        end)
        pcall(function() ISChat.focused = false end)
    end
    pcall(function() doKeyPress(false) end)
    pcall(function() chat.timerTextEntry = 20 end)
end

local function wrapEntry(entry)
    if not entry or type(entry.onCommandEntered) ~= "function" then return false end
    -- Never stack wrappers or continually replace other mods' chat handlers.
    if entry == boundEntry then return true end

    local original = entry.onCommandEntered
    local function handle(entrySelf, ...)
        local chat = ISChat and ISChat.instance
        if not chat or chat.textEntry ~= entry then
            return original(entrySelf, ...)
        end
        local okText, raw = pcall(function() return chat.textEntry:getText() end)
        if not okText then
            return original(entrySelf, ...)
        end
        local line = parseLine(raw)
        if line == nil then
            -- All normal chat commands and game key bindings keep vanilla behavior.
            return original(entrySelf, ...)
        end

        pcall(function() chat:logChatCommand(raw) end)
        -- Even if networking fails, release text field + gameplay keyboard focus.
        closeChat(chat)

        local player = getPlayer()
        if not player then
            show("Not connected to a game server.", true)
            return
        end
        if type(sendClientCommand) ~= "function" then
            show("Client command API is unavailable.", true)
            return
        end
        local okSend, errSend = pcall(function()
            sendClientCommand(player, MODULE, "run", {line = line})
        end)
        if not okSend then show("Command failed: " .. tostring(errSend), true) end
    end
    entry.onCommandEntered = handle
    boundEntry = entry
    wrappedCallback = handle
    previousCallback = original
    log("v0.1.2 entry callback wrapped; vanilla ISChat left unchanged")
    return true
end

local function install()
    if not ISChat or not ISChat.instance then return false end
    return wrapEntry(ISChat.instance.textEntry)
end

local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    args = args or {}
    if command == "result" then
        show(args.text, args.bad == true)
    elseif command == "invisibleLocal" then
        -- Server authorizes this first; apply on owning client for visual/gameplay sync.
        local p = getPlayer()
        if p and type(args.enabled) == "boolean" then
            local ok, err = pcall(function() p:setInvisible(args.enabled) end)
            if not ok then log("client invisible sync failed: " .. tostring(err)) end
        end
    elseif command == "healLocal" then
        local p = getPlayer()
        if p and not p:isDead() then
            local ok, err = pcall(function()
                p:getBodyDamage():RestoreToFullHealth()
            end)
            if not ok then log("client heal error: " .. tostring(err)) end
        end
    end
end

local function onTick()
    retries = retries + 1
    if retries % 30 ~= 1 then return end
    -- Stop polling as soon as we locate the chat input. No constant re-patching.
    if install() or retries > 900 then
        Events.OnTick.Remove(onTick)
    end
end

Events.OnServerCommand.Add(onServerCommand)
if Events.OnChatWindowInit then Events.OnChatWindowInit.Add(install) end
if Events.OnGameStart then Events.OnGameStart.Add(install) end
Events.OnTick.Add(onTick)
log("v0.1.2 client loaded (local chat feedback; invisible sync)")
