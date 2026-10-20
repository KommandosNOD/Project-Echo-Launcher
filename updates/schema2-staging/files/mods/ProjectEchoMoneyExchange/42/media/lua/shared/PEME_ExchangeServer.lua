-- PROJECT ECHO Money Exchange 1.0.0, PZ 42.21, PhunMart 2.
-- Shared script: runs on the authoritative dedicated server and on singleplayer.
-- Never trust an amount, a player name or a balance supplied by a client.

if isClient() and not isServer() then return end

ProjectEchoMoneyExchange = ProjectEchoMoneyExchange or {}
local Exchange = ProjectEchoMoneyExchange
local MODULE = "ProjectEchoMoneyExchange"
local CASH = "Base.Money"
local CENTS_PER_BILL = 5
local MAX_PER_REQUEST = 250 -- bound inventory sync burst; use F8 again for more
local active = {}
local lastExchange = {}

-- PhunMart's own official Lua module exposes the wallet APIs used below.
local loaded, loadErr = pcall(require, "PhunMart/wallet")
if not loaded then
    print("[PE Money Exchange] Could not load PhunMart/wallet: " .. tostring(loadErr))
end

local function result(player, ok, code, used, cents, balance)
    if not player then return end
    local data = {
        ok = ok == true, code = code or "error", count = used or 0,
        cents = cents or 0, balance = balance or 0
    }
    if isServer() then
        sendServerCommand(player, MODULE, "result", data)
    elseif Exchange.onResult then
        Exchange.onResult(data)  -- SP: same Lua environment
    end
end

local function moneyCount(inv)
    local count = inv and inv:getItemCount(CASH, true) or 0
    return math.max(0, tonumber(count) or 0)
end

local function perform(player, requested)
    if not player or not player.getInventory then return end
    local wallet = PhunMart and PhunMart.wallet
    if not wallet or not wallet.getCap or not wallet.getBalance or not wallet.adjustByPool or not wallet.get then
        result(player, false, "missing_phunmart")
        return
    end
    if PhunMart.getOption and PhunMart.getOption("EnableChangePool", true) == false then
        result(player, false, "wallet_disabled")
        return
    end

    -- Whitelist only the four visible UI commands. Arbitrary counts are rejected.
    if requested ~= "all" and requested ~= 1 and requested ~= 10 and requested ~= 50 then
        result(player, false, "invalid")
        return
    end

    local inv = player:getInventory()
    if not inv then result(player, false, "no_money"); return end
    local owned = moneyCount(inv)
    if owned < 1 then result(player, false, "no_money"); return end
    if requested ~= "all" and owned < requested then
        result(player, false, "not_enough", 0, 0, wallet:getBalance(player, "change"))
        return
    end

    local balance = wallet:getBalance(player, "change")
    local cap = wallet:getCap("change") -- nil means unlimited
    local space = cap and math.max(0, math.floor((cap - balance) / CENTS_PER_BILL)) or MAX_PER_REQUEST
    if space < 1 then
        result(player, false, "wallet_full", 0, 0, balance)
        return
    end
    local asked = requested == "all" and owned or requested
    local count = math.min(asked, owned, MAX_PER_REQUEST, space)
    if requested ~= "all" and count < asked then
        result(player, false, "wallet_full", 0, 0, balance)
        return
    end

    -- The server finds and removes the REAL items in the player's inventory,
    -- including worn/carried backpacks. No client-provided itemId is accepted.
    local removed = 0
    for i = 1, count do
        local before = moneyCount(inv)
        local item = inv:getFirstTypeRecurse(CASH)
        if not item or item:getFullType() ~= CASH then break end
        local container = item:getContainer()
        if not container then break end
        local ok, err = pcall(function() container:Remove(item) end)
        if not ok then
            print("[PE Money Exchange] Cannot remove money: " .. tostring(err))
            break
        end
        -- Extra anti-dupe check: an item counts only if the SERVER's owned
        -- inventory now contains one fewer bill. No silent credit on Remove no-op.
        local after = moneyCount(inv)
        if after >= before then
            print("[PE Money Exchange] Removal not confirmed; stopping exchange")
            break
        end
        removed = removed + 1
        -- Notify the owning client after each authoritative B42 inventory change.
        if isServer() and sendRemoveItemFromContainer then
            local syncOk, syncErr = pcall(sendRemoveItemFromContainer, container, item)
            if not syncOk then
                print("[PE Money Exchange] Inventory sync warning: " .. tostring(syncErr))
            end
        end
    end

    -- Credit ONLY the number actually taken; never the requested amount.
    if removed == 0 then
        result(player, false, "remove_failed", 0, 0, balance)
        return
    end
    local cents = removed * CENTS_PER_BILL
    wallet:adjustByPool(player, "current", "change", cents)
    local updated = wallet:getBalance(player, "change")

    -- PhunMart's native wallet notification makes shops/HUD see the new balance.
    if isServer() and PhunMart.commands and PhunMart.commands.getWallet then
        sendServerCommand(player, PhunMart.name, PhunMart.commands.getWallet, {
            username = player:getUsername(), wallet = wallet:get(player)
        })
    end
    print("[PE Money Exchange] " .. tostring(player:getUsername()) ..
        " bills=" .. tostring(removed) .. " credited_cents=" .. tostring(cents) ..
        " new_cents=" .. tostring(updated))
    result(player, true, "success", removed, cents, updated)
end

function Exchange.exchange(player, requested)
    if not player then return end
    local who = tostring(player:getUsername() or "player")
    if active[who] then return end
    local now = os.time()
    if lastExchange[who] and now - lastExchange[who] < 1 then
        result(player, false, "slow_down")
        return
    end
    active[who] = true
    local ok, err = pcall(perform, player, requested)
    active[who] = nil
    lastExchange[who] = now
    if not ok then
        print("[PE Money Exchange] Transaction exception for " .. who .. ": " .. tostring(err))
        result(player, false, "error")
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= "exchange" then return end
    if not isServer() then return end -- SP calls Exchange.exchange directly
    Exchange.exchange(player, args and args.quantity)
end
Events.OnClientCommand.Add(onClientCommand)
print("[PE Money Exchange] Server transaction handler ready (5c per Base.Money, max 250 per call)")
