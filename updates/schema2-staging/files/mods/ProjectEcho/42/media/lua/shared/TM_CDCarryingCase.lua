-- TM_CDCase.lua
-- Adds Cassette Case as a container (like a backpack)
-- RM_ServerCompatPatch: TrueMoozic Items/Distributions server guard
-- On a dedicated server this require currently fails in B42.21.
-- Skip only that failed server-side call; clients/SP keep the original require.
if not (isServer and isServer()) then
    require("Items/Distributions")
end

local function initCDCarryingCase()
    -- Add to loot tables if needed
    -- Example: table.insert(SuburbsDistributions.all.shelves.items, "CDCarryingCase")
    -- table.insert(SuburbsDistributions.all.shelves.items, 1)
end

Events.OnGameStart.Add(initCDCarryingCase)

-- Container functionality is handled by item.txt, but you can add custom logic here if needed
-- For example, restrict what can be placed inside:

local function CDCarryingCase_AllowPutItemInContainer(container, item)
    if container and type(container.getType) == "function" then
        local containingItem = container.getContainingItem and container:getContainingItem() or nil
        local isCarryingCase = containingItem
            and containingItem.getFullType
            and containingItem:getFullType() == "TM.CDCarryingCase"
        if isCarryingCase then
            -- Only allow cds (example: items with "CD" in type)
            return string.find(item:getType(), "CD") ~= nil
        end
    end
    return true
end

-- Note: no auto-fill here; loot filling is handled by Distributions and server OnCreate.
Events.OnContainerUpdate.Add(CDCarryingCase_AllowPutItemInContainer)
