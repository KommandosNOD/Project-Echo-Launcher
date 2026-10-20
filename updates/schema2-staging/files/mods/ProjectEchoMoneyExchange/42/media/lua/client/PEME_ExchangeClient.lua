-- PROJECT ECHO Money Exchange 1.0.0 (client UI only).
-- F8: exchange all Base.Money carried by the player.
-- Right click a Base.Money stack: exchange 1, 10, 50, all.
-- The MP server is the only authority that can remove cash / credit PhunMart.

local MODULE = "ProjectEchoMoneyExchange"
local CASH = "Base.Money"
local function tr(key, fallback)
    local ok, value = pcall(getText, "UI_PEME_" .. key)
    if not ok or value == nil or value == ("UI_PEME_" .. key) then return fallback end
    return value
end

local function flash(message, success)
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper then
        local ok = pcall(function()
            if success then HaloTextHelper.addGoodText(player, message)
            else HaloTextHelper.addBadText(player, message) end
        end)
        if ok then return end
    end
    print("[PE Money Exchange] " .. message)
end

local MESSAGES = {
    no_money = {"NoCash", "No Base.Money in your inventory"},
    not_enough = {"NotEnough", "Not enough banknotes in your inventory"},
    wallet_full = {"WalletFull", "PhunWallet change balance limit reached"},
    wallet_disabled = {"WalletDisabled", "PhunMart change wallet is disabled"},
    missing_phunmart = {"MissingPhunMart", "PhunMart wallet API unavailable"},
    remove_failed = {"RemoveFailed", "Unable to remove banknotes"},
    slow_down = {"SlowDown", "Please wait a second before exchanging again"},
    invalid = {"Invalid", "Invalid exchange request"},
    error = {"Error", "Exchange error; see server console"}
}

local function onResult(data)
    if not data then return end
    if data.ok then
        local dollars = (tonumber(data.cents) or 0) / 100
        local total = (tonumber(data.balance) or 0) / 100
        flash(tr("Success", "Exchanged") .. " " .. tostring(data.count) ..
            " Base.Money -> $" .. string.format("%.2f", dollars) ..
            " (" .. tr("Balance", "balance") .. " $" .. string.format("%.2f", total) .. ")", true)
    else
        local entry = MESSAGES[data.code] or MESSAGES.error
        flash(tr(entry[1], entry[2]), false)
    end
end

-- In singleplayer server and client scripts share a Lua state.
ProjectEchoMoneyExchange = ProjectEchoMoneyExchange or {}
ProjectEchoMoneyExchange.onResult = onResult

local function request(player, quantity)
    if not player then return end
    if isClient() then
        sendClientCommand(player, MODULE, "exchange", {quantity = quantity})
    elseif ProjectEchoMoneyExchange.exchange then
        ProjectEchoMoneyExchange.exchange(player, quantity)
    else
        flash(tr("MissingServer", "Exchange handler was not loaded"), false)
    end
end

local function isMoney(item)
    return item ~= nil and instanceof(item, "InventoryItem") and
        item:getFullType() == CASH
end

local function selectedMoney(items)
    -- Prefer the vanilla helper, which unwraps stacked inventory entries.
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, actual = pcall(ISInventoryPane.getActualItems, items)
        if ok and actual then
            for _, item in ipairs(actual) do
                if isMoney(item) then return true end
            end
        end
    end
    for _, wrapped in ipairs(items or {}) do
        if isMoney(wrapped) then return true end
        if type(wrapped) == "table" and wrapped.items then
            for _, item in ipairs(wrapped.items) do
                if isMoney(item) then return true end
            end
        end
    end
    return false
end

local function onInventoryMenu(playerNum, context, items)
    if not context or not selectedMoney(items) then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local heading = context:addOption(tr("Title", "PROJECT ECHO: Exchange banknotes"), nil, nil)
    local sub = context:getNew(context)
    context:addSubMenu(heading, sub)
    sub:addOption(tr("One", "1 bill -> $0.05"), player, request, 1)
    sub:addOption(tr("Ten", "10 bills -> $0.50"), player, request, 10)
    sub:addOption(tr("Fifty", "50 bills -> $2.50"), player, request, 50)
    sub:addOption(tr("All", "All bills (max 250 per exchange)"), player, request, "all")
end
Events.OnFillInventoryObjectContextMenu.Add(onInventoryMenu)

local function onKeyPressed(key)
    -- LWJGL KEY_F8 = 66. Use constant if exposed by the game.
    local f8 = Keyboard and Keyboard.KEY_F8 or 66
    if key ~= f8 then return end
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    request(player, "all")
end
Events.OnKeyPressed.Add(onKeyPressed)

local function onServerCommand(module, command, data)
    if module == MODULE and command == "result" then onResult(data) end
end
Events.OnServerCommand.Add(onServerCommand)
print("[PE Money Exchange] Context menu and F8 loaded")
