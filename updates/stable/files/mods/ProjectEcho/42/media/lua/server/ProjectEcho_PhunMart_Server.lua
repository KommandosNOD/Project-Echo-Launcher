-- PROJECT ECHO - optional PhunMart 2 wallet adapter (v0.9.11)
if type(isServer) ~= "function" or not isServer() then return end

require "ProjectEcho_RewardTiers"
ProjectEcho = ProjectEcho or {}
local PE=ProjectEcho

local function resolvePhunMart()
    if type(PhunMart)=="table" and type(PhunMart.wallet)=="table" and type(PhunMart.wallet.adjust)=="function" then
        return PhunMart
    end
    pcall(require,"PhunMart/wallet")
    if type(PhunMart)=="table" and type(PhunMart.wallet)=="table" and type(PhunMart.wallet.adjust)=="function" then
        return PhunMart
    end
    return nil
end

function PE.getPhunMartAdapterStatus()
    local pm=resolvePhunMart()
    if not pm then return false,"wallet API unavailable" end
    local dev=(type(isModActive)=="function" and isModActive("phunmart2dev"))==true
    local stable=(type(isModActive)=="function" and isModActive("phunmart2"))==true
    local market=(type(isModActive)=="function" and isModActive("phleamarket"))==true
    return true,(dev and "phunmart2dev" or (stable and "phunmart2" or "PhunMart API")).."; phleamarket="..tostring(market)
end

local function syncWallet(pm,player)
    if not player or type(sendServerCommand)~="function" then return false end
    if not pm.commands or not pm.commands.getWallet then return false end
    local ok=pcall(function()
        sendServerCommand(player,pm.name or "PhunMart",pm.commands.getWallet,{
            username=player:getUsername(),
            wallet=pm.wallet:get(player)
        })
    end)
    return ok
end

local function removePayoutReceipt(player,itemType)
    if not player or not itemType then return false end
    local inv=player:getInventory()
    if not inv then return false end
    local item=inv:getFirstTypeRecurse(itemType)
    if not item then return false end
    local container=item:getContainer() or inv
    container:Remove(item)
    if type(sendRemoveItemFromContainer)=="function" then pcall(sendRemoveItemFromContainer,container,item) end
    return true
end

function PE.grantPhunMartMissionReward(player,missionID)
    if not player then return false,"no player" end
    local pm=resolvePhunMart()
    if not pm then return false,"PhunMart wallet API unavailable" end
    local cents=math.max(0,math.floor((tonumber(PE.getMissionCreditAmount(missionID)) or 0)+0.5))
    local payoutItem=PE.getMissionPayoutItem and PE.getMissionPayoutItem(missionID) or nil
    local before=tonumber(pm.wallet:getBalance(player,"change")) or 0
    local quarters=math.floor(cents/25)
    local remainderCoins=cents-(quarters*25)
    local ok,err=pcall(function()
        if quarters>0 then pm.wallet:adjust(player,"PhunMart.Quarter",quarters) end
        if remainderCoins>=10 then
            local dimes=math.floor(remainderCoins/10); pm.wallet:adjust(player,"PhunMart.Dime",dimes); remainderCoins=remainderCoins-dimes*10
        end
        if remainderCoins>=5 then
            local nickels=math.floor(remainderCoins/5); pm.wallet:adjust(player,"PhunMart.Nickel",nickels); remainderCoins=remainderCoins-nickels*5
        end
    end)
    if not ok then return false,"wallet adjust failed: "..tostring(err) end
    local after=tonumber(pm.wallet:getBalance(player,"change")) or before
    local credited=math.max(0,after-before)
    local overflow=math.max(0,cents-credited)
    local overflowWrapped=false
    if overflow>0 and type(pm.wallet.addChangeToContainer)=="function" then
        local okWrap=pcall(function()
            pm.wallet:addChangeToContainer(player:getInventory(),{{pool="change",amount=overflow}})
        end)
        overflowWrapped=okWrap
    end
    syncWallet(pm,player)
    local complete=(credited>=cents) or overflowWrapped
    local receiptRemoved=false
    if complete then receiptRemoved=removePayoutReceipt(player,payoutItem) end
    return complete,string.format("mission=%s requested=%dc credited=%dc overflow=%dc wrapped=%s receiptRemoved=%s balance=%dc",
        tostring(missionID),cents,credited,overflow,tostring(overflowWrapped),tostring(receiptRemoved),after)
end
