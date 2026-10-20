-- PROJECT ECHO Ammo Compat v0.2.8 - Guns93 B42.21 MP AmmoSwitch dedicated fix.
-- Source audit: Guns93Test 0.8.2.7A, Guns93AmmoSwitch.lua:52
-- The original call getPlayerHotbar(player:getPlayerNum()) crashes on dedicated
-- servers. This file patches only that client UI access; all standard swapping,
-- ammo modes, weapon parts, inventory replacement and networking remain intact.
-- Source patch review: compared to the original Guns93 AmmoSwitch function.

function PEAC_Guns93_SafeAmmoSwitch(item, index, player)
    if not item or not instanceof(item, "HandWeapon") or not item:isRanged() or not player then return end
    local switchingToAlt = true
    if item:hasTag(Gun93Registries.guns93.AltAmmo) then
        switchingToAlt = false
    end
    local newFullType = switchingToAlt and (item:getFullType() .. "_Alt") or string.gsub(item:getFullType(), "_Alt", "")
    local newItem = instanceItem(newFullType)
    if not newItem then return end
    newItem:setContainsClip(false)
    local remparts = newItem:getAllWeaponParts()
    for i = remparts:size(), 1, -1 do
        local part = remparts:get(i - 1)
        if part then newItem:detachWeaponPart(part) end
    end
    local parts = item:getAllWeaponParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if part then newItem:attachWeaponPart(part) end
    end
    newItem:copyModData(item:getModData())
    newItem:setWeaponSprite(item:getWeaponSprite())
    newItem:setTexture(item:getTexture())
    newItem:setCondition(item:getCondition())
    newItem:setHaveBeenRepaired(item:getHaveBeenRepaired())
    newItem:setBloodLevel(item:getBloodLevel())
    newItem:getModData().mod_fouling = item:getModData().mod_fouling
    newItem:setFavorite(item:isFavorite())
    newItem:setActivated(item:isActivated())
--    newItem:setAttachedSlot(item:getAttachedSlot())
    newItem:setMaxAmmo(item:getMaxAmmo())
    newItem:setCurrentAmmoCount(item:getCurrentAmmoCount())
    if newItem:haveChamber() and item:isRoundChambered() then
        newItem:setRoundChambered(true)
    end
    local baseName = item:getDisplayName()
    local cleanName = baseName:gsub(" %(.+%)", ""):gsub(getText("Tooltip_clothing_bloody"), ""):gsub("^%s+", ""):gsub("%s+$", "")
    local ammoName1 = string.gsub(getItemNameFromFullType(item:getAmmoType():getItemKey()), " Round", "")
    local ammoName2 = string.gsub(getItemNameFromFullType(newItem:getAmmoType():getItemKey()), " Round", "")
    cleanName = string.gsub(cleanName, ammoName1, ammoName2)
    newItem:setName(cleanName)
    local wasPrimary = (player:getPrimaryHandItem() == item)
    local wasSecondary = (player:getSecondaryHandItem() == item)
    local twoHand = wasPrimary and wasSecondary
    if wasPrimary then
        player:setPrimaryHandItem(nil)
        if twoHand then player:setSecondaryHandItem(nil) end
    end
    player:getInventory():AddItem(newItem)
    player:getInventory():Remove(item)
    sendReplaceItemInContainer(player:getInventory(), item, newItem)
	local hotBar = nil
    -- Dedicated B42 multiplayer server: getPlayerHotbar is a CLIENT UI function.
    -- Guns93 0.8.2.7A directly calls it in the shared AmmoSwitch implementation,
    -- raising 'Object tried to call nil in AmmoSwitch' on server.
    -- Do not fake a global hotbar or alter the server's other mod behavior.
    if type(getPlayerHotbar) == "function" then
        local ok, value = pcall(getPlayerHotbar, player:getPlayerNum())
        if ok then hotBar = value end
    end
    if hotBar and hotBar:isInHotbar(item) then -- hotbar (client only)
        local itemSlot = item:getAttachedSlot()
        hotBar:removeItem(item, false)
        local available = hotBar.availableSlot and hotBar.availableSlot[itemSlot]
        local slotDef = available and available.def
        local attachment = slotDef and slotDef.attachments
            and slotDef.attachments[newItem:getAttachmentType()]
        if slotDef and attachment then
            hotBar:attachItem(newItem, attachment, itemSlot, slotDef, false)
        else
            -- Don't drop the new weapon if another UI mod changed hotbar slots.
            print("[PE AmmoCompat v0.2.8] Guns93 hotbar slot unavailable; weapon kept in inventory")
        end
        hotBar.needsRefresh = true
        hotBar:update()
    end
    syncHandWeaponFields(player, newItem)
    player:getInventory():setDirty(true)
    return newItem
end


local function peacInstallSafeSwitch()
    -- Guns93 is optional, and other mods might redefine the action at boot.
    if type(AmmoSwitch) ~= "function"
       or type(Guns93AmmoSwitchAction) ~= "table" then return end
    if AmmoSwitch ~= PEAC_Guns93_SafeAmmoSwitch then
        AmmoSwitch = PEAC_Guns93_SafeAmmoSwitch
        print("[PE AmmoCompat v0.2.8] Guns93 AmmoSwitch dedicated hotbar fix installed")
    end
end

peacInstallSafeSwitch()
if Events and Events.OnGameBoot then Events.OnGameBoot.Add(peacInstallSafeSwitch) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(peacInstallSafeSwitch) end
