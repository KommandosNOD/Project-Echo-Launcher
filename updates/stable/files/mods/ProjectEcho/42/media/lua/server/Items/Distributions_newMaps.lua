require 'Items/ProceduralDistributions'
require 'Items/Distributions'
-- RM_ServerCompatPatch: B42 Vehicles/Distributions compatibility; table is initialized below.

SuburbsDistributions = SuburbsDistributions or {}
ProceduralDistributions = ProceduralDistributions or {}
ProceduralDistributions.list = ProceduralDistributions.list or {}
VehicleDistributions = VehicleDistributions or {}
VehicleDistributions[1] = VehicleDistributions[1] or {}

local function getNextKeyAfterMatch(table, value)
    local found = false
    for key, v in pairs(table) do
        if found then
            return v
        end
        if v == value or v == "Base." .. value then
            found = true
        end
    end
    return false
end

local function insertItemIntoTable(_item, _table, _lootChance)
    table.insert(_table, _item)
    table.insert(_table, _lootChance)
end

local function addMapsToLootTables(_table)
    local lootChance =  getNextKeyAfterMatch(_table, "MuldraughMap") 
    if lootChance and not getNextKeyAfterMatch(_table, "EchoCreekMap")  then
        insertItemIntoTable("Base.EchoCreekMap", _table, lootChance)
        insertItemIntoTable("Base.IrvingtonMap",_table,  lootChance)
        insertItemIntoTable("Base.BrandenburgMap",_table,  lootChance)
        insertItemIntoTable("Base.EkronMap", _table, lootChance)
        insertItemIntoTable("Base.FallasLakeMap", _table, lootChance)
        -- rarer maps
        insertItemIntoTable("Base.DixieMap", _table, lootChance*0.6)
        insertItemIntoTable("Base.ScenicGroveMap", _table, lootChance*0.6)
        insertItemIntoTable("Base.MuldraughRailyardMap", _table, lootChance*0.2)
        insertItemIntoTable("Base.DoeValleyMap", _table, lootChance*0.1)
    end
end

local function loopOnTable(table)
    if not table then return; end
    for zoneKey, zone in pairs(table) do
        if type(zone) == "table" then
            if zone.items then
                if zone.items[2] then
                    addMapsToLootTables(zone.items)
                end
                if zone.junk and zone.junk.items and zone.junk.items[2] then
                    addMapsToLootTables(zone.junk.items)
                end
            else
                if zone and not zone.procedural then
                    loopOnTable(zone)
                end
            end
        end
    end 
end

local function initMapDistributions()
    loopOnTable(SuburbsDistributions)
    loopOnTable(ProceduralDistributions.list)
    loopOnTable(VehicleDistributions[1])
end

Events.OnPostDistributionMerge.Add(initMapDistributions)
