require("StoryItemDefinitions_Example.lua")
require("SpritesSurfacesDimensions.lua")


StoryItemSpawner = StoryItemSpawner or {}

-- enable this when debugging
StoryItemSpawner.testMode = false

StoryItemSpawner.storyList = StoryItemSpawner.storyList or {}

StoryItemSpawner.settings = {
    MaxStoriesPerRoom = 500,
    GlobalStoriesChanceMultiplier = 1,
    offsetFloor = 2,
    weightChanceDefault = 20,
    sizeToIgnoreRoom = 1000,
}

StoryItemSpawner.tickCounter = 0
StoryItemSpawner.tickInterval = 1
StoryItemSpawner.roomsList = {}
StoryItemSpawner.lastRoomCount = 0
StoryItemSpawner.lastPlayerPosition = {}
StoryItemSpawner.ChanceOnFloorMultiplier = 1
StoryItemSpawner.ChanceOnFurnitureMultiplier = 1

StoryItemSpawner.spritesListToIgnoreOffset = {
    -- high counters 
    fixtures_counters_01_26 = 1,
    fixtures_counters_01_27 = 1,
    -- bathroom cabinets
    fixtures_bathroom_01_28 = 1,
    fixtures_bathroom_01_29 = 1,
    fixtures_bathroom_01_37 = 1,
    fixtures_bathroom_01_38 = 1,
}


StoryItemSpawner.ignoreFurnitureListForRoomLoot = {
    freezer = 1,
    fridge = 1,
    displaycasebutcher = 1,
    displaycasebakery = 1,
    
    isShop = 1,
    totalFurnitureChance = 1,

    bat = 1, -- compatibility with Trelai
}

---@param _text string|boolean
function StoryItemSpawner.noise(_text)
    if StoryItemSpawner.testMode then print(_text); end
end

---@param _roomLootTable table
---@return string|boolean
function StoryItemSpawner.PickRandomFurnitureTable(_roomLootTable)

    if _roomLootTable.totalFurnitureChance then
        local totalChance = _roomLootTable.totalFurnitureChance
        local cumulativeFurnitureChance = 0;
        local furnitureRandomNum = ZombRand(1, totalChance*10000)/10000

        for furnitureKey, furnitureTable in pairs(_roomLootTable) do
            if not StoryItemSpawner.ignoreFurnitureListForRoomLoot[furnitureKey] and _roomLootTable[furnitureKey].procedural then
                cumulativeFurnitureChance = cumulativeFurnitureChance + furnitureTable.totalProcListWeightChance
                if furnitureRandomNum <= cumulativeFurnitureChance then
                    return furnitureKey;
                end
            end
        end
    end

    local furnitureList = {};
    local index = 1;
    for k, v in pairs(_roomLootTable) do
        if not StoryItemSpawner.ignoreFurnitureListForRoomLoot[k] and _roomLootTable[k].procedural then
            furnitureList[index] = k;
            index = index + 1;
        end
    end
    if #furnitureList > 0 then
        local furniturePicked = furnitureList[ZombRand(1, #furnitureList)]
        return furniturePicked
    else
        return false
    end
end


---@param _lootTable table
---@return string|nil
function StoryItemSpawner.PickRandomItemFromLootTable(_lootTable)
    if not _lootTable then return nil; end
    local totalChance = _lootTable and (_lootTable.totalChanceProcedural or _lootTable.totalChanceNonProcedural or _lootTable.totalChance) or 20
    local randomNum = ZombRand(1, totalChance*10000)/10000
    local cumulativeChance = 0

    if _lootTable.items and type(_lootTable.items) == "table" then
        for i=1, #_lootTable.items, 2 do
            if _lootTable.items[i + 1] and type(_lootTable.items[i + 1]) == "number" and _lootTable.items[i + 1] > 0 then
                cumulativeChance = cumulativeChance + _lootTable.items[i + 1]
                if randomNum <= cumulativeChance then
                    local itemPicked = _lootTable.items[i]
                    if not string.match(itemPicked, "%p") then
                        itemPicked = "Base."..itemPicked;
                    end
                    return itemPicked
                end
            end
        end
    end
end


---@param _square IsoGridSquare|nil
---@param roomName string|nil
---@param _building IsoBuilding|nil
---@param _tallestObjectSpriteName string|nil
---@return string|boolean
function StoryItemSpawner.SelectRandomItemFromVanillaDistributions(_square, roomName, _building, _tallestObjectSpriteName)
    if not SuburbsDistributions[roomName] then
        roomName = "all"
    end
    local furnitureRoomLootTable = StoryItemSpawner.PickRandomFurnitureTable(SuburbsDistributions[roomName])
    if furnitureRoomLootTable and SuburbsDistributions[roomName][furnitureRoomLootTable] and SuburbsDistributions[roomName][furnitureRoomLootTable].totalProcListWeightChance then
        local randomNumFurnitureLoot = ZombRand(1, SuburbsDistributions[roomName][furnitureRoomLootTable].totalProcListWeightChance*10000)/10000
        -- StoryItemSpawner.noise("randomNumFurnitureLoot : "..randomNumFurnitureLoot)
        local cumulativeFurnitureLootChance = 0
        local procList = SuburbsDistributions[roomName][furnitureRoomLootTable].procList
        for k, procEntry in pairs(procList) do -- first loop to look for forced for Tiles, forced for Rooms, and forced for Zones
            if _tallestObjectSpriteName and procEntry.tilesForcedList then
                if procEntry.tilesForcedList[_tallestObjectSpriteName] then
                    local procEntryName = procEntry.name
                    return StoryItemSpawner.PickRandomItemFromLootTable(ProceduralDistributions.list[procEntryName])
                end
            end
            if roomName and procEntry.roomsForcedList then
                for roomName, v in pairs(procEntry.roomsForcedList) do
                    if _building and _building:containsRoom(roomName) then
                        local procEntryName = procEntry.name
                        return StoryItemSpawner.PickRandomItemFromLootTable(ProceduralDistributions.list[procEntryName])
                    end
                end
            end
            if _square and procEntry.zonesForcedList then
                local zone = _square:getZone()
                if zone and procEntry.zonesForcedList[zone:getName()] then
                    local procEntryName = procEntry.name
                    return StoryItemSpawner.PickRandomItemFromLootTable(ProceduralDistributions.list[procEntryName])
                end
            end
        end
        for k, procEntry in pairs(procList) do
            if not procEntry.tilesForcedList and not procEntry.roomsForcedList and not procEntry.zonesForcedList then
                local weightChance = StoryItemSpawner.settings.weightChanceDefault
                if procEntry.weightChance then
                    weightChance = procEntry.weightChance
                end
                cumulativeFurnitureLootChance = cumulativeFurnitureLootChance + weightChance
                if randomNumFurnitureLoot <= cumulativeFurnitureLootChance then
                    local procEntryName = procEntry.name
                    return StoryItemSpawner.PickRandomItemFromLootTable(ProceduralDistributions.list[procEntryName])
                end
            end
        end
        for k, procEntry in pairs(procList) do
            local weightChance = StoryItemSpawner.settings.weightChanceDefault
            if procEntry.weightChance then
                weightChance = procEntry.weightChance
            end
            cumulativeFurnitureLootChance = cumulativeFurnitureLootChance + weightChance
            if randomNumFurnitureLoot <= cumulativeFurnitureLootChance then
                local procEntryName = procEntry.name
                return StoryItemSpawner.PickRandomItemFromLootTable(ProceduralDistributions.list[procEntryName])
            end
        end
    end
    return false
end


---@param _story table
---@param _square IsoGridSquare
---@param roomName string
---@param _building IsoBuilding
---@param _tallestObjectSpriteName string
---@return string|boolean|table, string
function StoryItemSpawner.SelectRandomItem(_story, _square, roomName, _building, _tallestObjectSpriteName)
    local randomNum = ZombRand(1, _story.totalChance*100000)/100000
    local cumulativeChance = 0
    if _story.items and type(_story.items) == "table" then
        for _, entry in ipairs(_story.items) do
            if entry and entry.chance and type(entry.chance) == "number" then
                cumulativeChance = cumulativeChance + entry.chance
                if randomNum <= cumulativeChance then
                    if entry.itemId then
                        local itemPicked =  entry.itemId
                        if not string.match(itemPicked, "%p") then
                            itemPicked = "Base."..itemPicked;
                        end
                        return itemPicked, "item"
                    end
                    if entry.proceduralTable then
                        return StoryItemSpawner.PickRandomItemFromLootTable(entry.table) , "item"
                    end
                    if entry.roomLoot then

                        return StoryItemSpawner.SelectRandomItemFromVanillaDistributions(_square, roomName, _building, _tallestObjectSpriteName), "item";
                        
                    end
                    if entry.TileObject then
                        return entry , 'TileObject'
                    end

                end
            end
        end
    end
    return false, "false";
end

---@param _item InventoryItem
---@param _roomName string
function StoryItemSpawner.TweakItem(_item , _roomName)

    -- PZ42Compat04: already initialized when created as a world item.

    if _item:IsWeapon() or _item:getCondition() ~= 10 then -- 10 is default condition on items that don't have condition
        if ZombRand(100) < 60 then  -- 60% chance to damage item
            _item:randomizeCondition()
            _item:randomizeGeneralCondition()
            if _item:hasHeadCondition() then
                 _item:randomizeHeadCondition()
            end
            if _item:hasSharpness() then
                _item:randomizeSharpness()
            end
        end
    end

    if _item:isFluidContainer() and _item:getFluidContainer() then
        local fluidContainer = _item:getFluidContainer()
        if ZombRand(100) < 50 then 
            fluidContainer:unseal()
            if fluidContainer:isFull() then
                fluidContainer:removeFluid(ZombRand(5,95)/100)
            end
        end

    end

    if _item:hasBlood() then
        if ZombRand(100) < 50 then  -- 50% chance to damage sharpness
            _item:setBloodLevel(ZombRand(1, 100)/100)
        end
    end

    if _item:IsDrainable() then
        if ZombRand(100) < 90 then 
            _item:setUsedDelta(math.floor(ZombRand(ZombRand(1, 90), 100))/100)
        end
    end

    
    if _item:IsFood() then
        _item:setAutoAge()
    end

    if _item:getType() == "VHS" or _item:getType() == "VHS_Home" or _item:getType() == "VHS_Retail" then
        local mediaList = getZomboidRadio():getRecordedMedia():getAllMediaForCategory(_item:getScriptItem():getRecordedMediaCat());
        local mediaData = mediaList:get(ZombRand(mediaList:size()-1));
        if mediaData == nil then
            _item:setRecordedMediaIndexInteger(-1)
        else
            _item:setRecordedMediaData(mediaData);
        end
        -- _item:getContainer():setDrawDirty(true);
    end
    if _item:IsInventoryContainer() then
        local itemTable = SuburbsDistributions[_item:getType()]
        if itemTable and itemTable.items and itemTable.items[2] and itemTable.rolls and itemTable.rolls > 0 then
            local itemContainer = _item:getItemContainer()
            for r=1, itemTable.rolls do
                local itemPicked = StoryItemSpawner.PickRandomItemFromLootTable(itemTable)
                if itemPicked then 
                    itemContainer:AddItem(itemPicked);
                    if itemTable.onlyOne then
                        break;
                    end
                end
            end
        else
            local itemContainer = _item:getItemContainer()
            for i = 1, ZombRand(1, 5) do
                local itemPicked = StoryItemSpawner.SelectRandomItemFromVanillaDistributions(nil, _roomName, nil, nil);
                if itemPicked then
                    local itemSpawed = itemContainer:AddItem(itemPicked);
                    if itemSpawed and not itemSpawed:IsInventoryContainer() then StoryItemSpawner.TweakItem(itemSpawed , _roomName); end
                end
            end
        end
    end
end


function StoryItemSpawner.PlaceTileObject(_square, _pick)


    -- TODO 
    local sprite = getSprite( _pick.TileObject )
    local spriteProperties = sprite and sprite:getProperties()
    local TileIsoObjectType = sprite:getType()
    local isoType = "IsoObject";

    if spriteProperties:Val("IsoType") ~= nil then
        isoType = spriteProperties:Val("IsoType")
    end
    local isoObject;
    local container = spriteProperties:Is("container") and spriteProperties:Val("container") or nil

    if isoType == "IsoBarbecue" then
        
        if sprite then
            isoObject = IsoBarbecue.new( getCell(), _square, sprite );
            isoObject:setMovedThumpable(true);
        end
    elseif isoType == "IsoCombinationWasherDryer" then
        if sprite then
            isoObject = IsoCombinationWasherDryer.new(getCell(), _square, sprite)
            isoObject:setMovedThumpable(true);
        end
    elseif isoType == "IsoClothingDryer" then
        if sprite then
            isoObject = IsoClothingDryer.new(getCell(), _square, sprite)
            isoObject:setMovedThumpable(true);
        end
        -- isoObject:setMovedThumpable(true);
    elseif isoType == "IsoClothingWasher" then
        if sprite then
            isoObject = IsoClothingWasher.new(getCell(), _square, sprite)
            isoObject:setMovedThumpable(true);
        end
        -- isoObject:setMovedThumpable(true);
    elseif isoType == "IsoCompost" then
        if sprite then
            isoObject = IsoCompost.new(getCell(), _square, sprite)
        end
        -- isoObject:setMovedThumpable(true);
    elseif isoType == "IsoJukebox" then
        if sprite then
            isoObject = IsoJukebox.new( getCell(), _square, sprite );
            isoObject:setMovedThumpable(true);
        end
        -- isoType:setMovedThumpable(true);
    else
        isoObject = IsoObject.new(_square, _pick.TileObject, nil, false)
        isoObject:setMovedThumpable(true);
    end

    if not container then
        container = isoObject:getContainer()
        if not container then
            container = isoObject:getItemContainer()
        end
    end
    if _pick.containerLoot and _pick.containerLoot.items and _pick.containerLoot.itemCount then
        if not container then
            container = ItemContainer.new(_pick.TileObject, _square, isoObject, 1, 1)
            isoObject:setContainer(container)
        end
        -- container:emptyIt()
        local itemCount = ZombRand(_pick.containerLoot.itemCount)
        if container and itemCount > 0 then
            for i=1, itemCount do
                local itemPicked = _pick.containerLoot.items[ZombRand(1, #_pick.containerLoot.items)]
                if not string.match(itemPicked, "%p") then
                    itemPicked = "Base."..itemPicked;
                end
                container:AddItem(itemPicked)
            end
        end
    end
    -- if _pick.props then
    --     isoObject:setBlockAllTheSquare(_pick.props.blockAllSquare and true or false);
    --     isoObject:setCanPassThrough(_pick.props.canPassThrough and true or false);
    --     isoObject:setHoppable(_pick.props.hoppable and true or false);
    -- end
    _square:AddTileObject(isoObject)
    triggerEvent("OnObjectAdded", isoObject)
    ItemPickerJava.updateOverlaySprite(isoObject)
    MapObjects.debugLoadSquare(_square:getX(), _square:getY() , _square:getZ())
    if isClient() then isoObject:transmitCompleteItemToServer(); end
end


---@param _story table
---@param _tallestObjectSpriteName string
---@param _square IsoGridSquare
---@param _squareSurfaceOffset integer
---@param _room IsoRoom
---@return integer
function StoryItemSpawner.RollStory(_story, _tallestObjectSpriteName, _square, _squareSurfaceOffset, _room)
    
    if not _story or not _tallestObjectSpriteName or not _square or not _room then return 0; end
    local ss = SpriteDimensions.MiddleSmall;
    local chance;
    
    if _squareSurfaceOffset == 0 then
        chance = (_story.chanceOnFloor or 0) * (StoryItemSpawner.ChanceOnFloorMultiplier or 1);
        ss = SpriteDimensions.MiddleLarge;

    else
        chance = (_story.chanceOnFurniture or 0) * (StoryItemSpawner.ChanceOnFurnitureMultiplier or 1) ;
        
        if _squareSurfaceOffset < (_story.furnitureMinOffsetZ or 5) or _squareSurfaceOffset > (_story.furnitureMaxOffsetZ or 95) then return 0; end

        if _story.sprites and _story.sprites[_tallestObjectSpriteName] then
            -- StoryItemSpawner.noise("Detected sprite ".._tallestObjectSpriteName)
            ss = _story.sprites[_tallestObjectSpriteName]
        else
            if _story.spritesMatch then
                for k, v in pairs(_story.spritesMatch) do
                    if string.match(_tallestObjectSpriteName, k) then
                        ss = _story.spritesMatch[k];
                        break;
                    end
                end
            else
                if SpriteDimensions.list[_tallestObjectSpriteName] then
                    ss = SpriteDimensions.list[_tallestObjectSpriteName]
                else
                    ss = SpriteDimensions.MiddleSmall;
                end
            end
        end
    end



    local roomName = _room:getName()
    if _story.rooms and _story.rooms[roomName] then
        chance = chance * _story.rooms[roomName]
    end
    if ss.chanceModifier then
        chance = chance * ss.chanceModifier;
    end

    if chance <= 0 then return 0; end
    -- StoryItemSpawner.noise("chance to pass : "..chance)


    local zSpawnHeight = StoryItemSpawner.normalizeSurfaceOffset(_squareSurfaceOffset, _tallestObjectSpriteName)

    local rollChance = ZombRand(0, 10000)/100
    if rollChance <= chance then
        local itemCount = 1
        if _story.itemCountPerTileMin or 1 < _story.itemCountPerTileMax or 1 then
            itemCount = ZombRand(_story.itemCountPerTileMin or 1, _story.itemCountPerTileMax or 1)
        else
            itemCount = _story.itemCountPerTileMin or 1
        end
        -- StoryItemSpawner.noise("Chance = "..rollChance.."/"..chance)
        for i=1, itemCount do
            local building = _room:getBuilding()
            local pick, type = StoryItemSpawner.SelectRandomItem(_story, _square, roomName, building, _tallestObjectSpriteName)
            if pick and type == "item" then
                local itemSpawned = _square:AddWorldInventoryItem(pick, ZombRand(ss.minOffsetX or 20, ss.maxOffsetX or 80)/100, ZombRand(ss.minOffsetY or 20, ss.maxOffsetY or 80)/100, zSpawnHeight/100 or 0);
                StoryItemSpawner.noise("Spawned item : "..pick)
                if itemSpawned then
                    StoryItemSpawner.TweakItem(itemSpawned, roomName)
                end
            elseif pick and type == "TileObject" then
                StoryItemSpawner.PlaceTileObject(_square, pick)
                
            end
        end
        return 1
    else
        -- StoryItemSpawner.noise("Chance = "..rollChance.."/"..chance..": Failed chance to spawn story on offset ".._squareSurfaceOffset.." in room "..roomName)
    end
    return 0
end



---@param tallestObjectSpriteName string
---@param squareSurfaceOffset integer
---@param _room IsoRoom
---@param itemCountSpawnedByStories integer
---@return table|boolean
function StoryItemSpawner.GetPossibleStoriesForThisTile(tallestObjectSpriteName, squareSurfaceOffset, _room, itemCountSpawnedByStories, square)
    local tableOfPossibleStories = {};
    tableOfPossibleStories.totalWeightChances = 0;
    tableOfPossibleStories.stories = {};
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    for k, story in pairs(StoryItemSpawner.storyList) do
        -- StoryItemSpawner.noise("checking story "..(story.name or "none"))
        if (not story.rooms or story.rooms[_room:getName()] or story.rooms.allRooms and (not story.rooms[_room:getName()] or story.rooms[_room:getName()] > 0)) 
            and (not story.maxStoryCountPerRoom or not itemCountSpawnedByStories[story.name] or itemCountSpawnedByStories[story.name] < story.maxStoryCountPerRoom)
            and (not story.spritesToIgnore or not story.spritesToIgnore[tallestObjectSpriteName])
            and (not story.coordonatesToIgnore or not (x > story.coordonatesToIgnore.xmin and x < story.coordonatesToIgnore.xmax and y > story.coordonatesToIgnore.ymin and y < story.coordonatesToIgnore.ymax and z > story.coordonatesToIgnore.zmin and z < story.coordonatesToIgnore.zmax))
            and (not story.coordonatesMatch or (x > story.coordonatesMatch.xmin and x < story.coordonatesMatch.xmax and y > story.coordonatesMatch.ymin and y < story.coordonatesMatch.ymax and z > story.coordonatesMatch.zmin and z < story.coordonatesMatch.zmax))
            then

            -- StoryItemSpawner.noise("tallestObjectSpriteName  = "..(tallestObjectSpriteName or "false"))
            -- StoryItemSpawner.noise("story "..(story.name or "none").." passed 1st IF")

                
            -- if story.sprites then
            --     StoryItemSpawner.noise("story.sprites = true")
            --     if story.sprites[tallestObjectSpriteName] then
            --         StoryItemSpawner.noise("story.sprites[tallestObjectSpriteName]  = true")
            --     else
            --         StoryItemSpawner.noise("story.sprites[tallestObjectSpriteName]  = false")
            --     end
            -- else
            --     StoryItemSpawner.noise("story.sprites = false")
            -- end
            

            if  squareSurfaceOffset <= (StoryItemSpawner.settings.offsetFloor or 1)
                and story.chanceOnFloor and story.chanceOnFloor > 0
                then
                -- StoryItemSpawner.noise("story "..(story.name or "none").." passed 2nd IF")
                -- StoryItemSpawner.noise("adding story "..(story.name or "none").." to possible stories")
                tableOfPossibleStories.stories[story.name] = story
                tableOfPossibleStories.totalWeightChances = tableOfPossibleStories.totalWeightChances + (story.storyWeightChance or 10)

            elseif (not story.sprites or story.sprites[tallestObjectSpriteName])
                and (squareSurfaceOffset <= (story.furnitureMaxOffsetZ or 100) ) 
                and (squareSurfaceOffset >= (story.furnitureMinOffsetZ or 0.001) )
                and story.chanceOnFurniture and story.chanceOnFurniture > 0
                then
                -- StoryItemSpawner.noise("story "..(story.name or "none").." passed 3rd IF")
                if story.spritesMatch then
                    for spriteKey, v in pairs(story.spritesMatch) do
                        if string.match(tallestObjectSpriteName, spriteKey) then
                            if not tableOfPossibleStories[story.name] then
                                -- StoryItemSpawner.noise("adding story "..(story.name or "none").." to possible stories")
                                tableOfPossibleStories.stories[story.name] = story
                                tableOfPossibleStories.totalWeightChances = tableOfPossibleStories.totalWeightChances + (story.storyWeightChance or 10)
                                break;
                            end
                        end
                    end
                else
                    -- StoryItemSpawner.noise("adding story "..(story.name or "none").." to possible stories")
                    tableOfPossibleStories.stories[story.name] = story
                    tableOfPossibleStories.totalWeightChances = tableOfPossibleStories.totalWeightChances + (story.storyWeightChance or 10)
                end
            end
        end
    end
    if tableOfPossibleStories.totalWeightChances > 0 then
        return tableOfPossibleStories;
    else
        return false
    end
end

---@param _possibleStoriesForThisTile table
---@return table|boolean
function StoryItemSpawner.SelectRandomStory(_possibleStoriesForThisTile)
    local cumulativeChance = 0
    local randomNum = ZombRand(1, _possibleStoriesForThisTile.totalWeightChances*10000)/10000
    for k, story in pairs(_possibleStoriesForThisTile.stories) do
        cumulativeChance = cumulativeChance + (story.storyWeightChance or StoryItemSpawner.settings.weightChanceDefault)
        if randomNum <= cumulativeChance then
            return story
        end
    end
    return false
end


---@param _squareSurfaceOffset integer
function StoryItemSpawner.normalizeSurfaceOffset( _squareSurfaceOffset, _spriteName)

    
    -- construction_01_05 = 7
    local surfaceOffsetsTable = {
        -- here we could redefine surface offsets for sprites that have the wrong numbers... But it's too much work for me.
        construction_01_05 = 7
    }

    if surfaceOffsetsTable[_spriteName] then
        return surfaceOffsetsTable[_spriteName]
    end

    -- extra surfaceOffsets breakoffs : 
    -- +0 => ?
    -- +1 => 15, 16, 18, 26,30, 32 , 33, 34
    -- +2 => 36, 40, 41, 48, 51, 57
    -- +3 => 63, 64, 66, 73, 80
    if(_squareSurfaceOffset < 12) then
        return _squareSurfaceOffset;
    elseif (_squareSurfaceOffset < 35) then
        return _squareSurfaceOffset + 1;
    elseif (_squareSurfaceOffset < 60) then
        return _squareSurfaceOffset + 2;
    else
        return _squareSurfaceOffset + 3;
    end
end

---@param _room IsoRoom
function StoryItemSpawner.CheckRoom(_room)

    local itemCountSpawnedByStories = {};
    local storySpawnedInRoomCount = 0;
    StoryItemSpawner.noise("Checking room ".._room:getName())
    local roomSquares = _room:getSquares()
    local roomSize = roomSquares:size()
    if roomSize > StoryItemSpawner.settings.sizeToIgnoreRoom then return; end
    for i = 0, roomSize-1 do
        if storySpawnedInRoomCount > StoryItemSpawner.settings.MaxStoriesPerRoom then break; end
        local square = roomSquares:get(i);
        local squareModData = square:getModData()
        if not squareModData.StoryItemSpawnerChecked then
            squareModData.StoryItemSpawnerChecked = true;
            square:transmitModdata()

            local tileObjects = square:getLuaTileObjectList();
            local squareSurfaceOffset = -1;
            local tallestObject;

            -- get the object with the highest offset
            for k, object in pairs(tileObjects) do
                local objectSprite = object:getSprite()
                local objectSpriteName = false
                if objectSprite then
                    objectSpriteName = objectSprite:getName()
                end
                local objectSurfaceOffsetNoTable = object:getSurfaceOffsetNoTable()
                if objectSurfaceOffsetNoTable and objectSurfaceOffsetNoTable > squareSurfaceOffset then
                    if not objectSpriteName or not StoryItemSpawner.spritesListToIgnoreOffset[objectSpriteName] or squareSurfaceOffset < 5 then
                        squareSurfaceOffset = objectSurfaceOffsetNoTable
                        tallestObject = object
                    end
                end
                local objectSurfaceOffset = object:getSurfaceOffset()
                if objectSurfaceOffset and objectSurfaceOffset > squareSurfaceOffset then
                    if not objectSpriteName or not StoryItemSpawner.spritesListToIgnoreOffset[objectSpriteName] or squareSurfaceOffset < 5 then
                        squareSurfaceOffset = objectSurfaceOffset
                        tallestObject = object
                    end
                end
                local props = object:getProperties() or objectSprite and objectSprite:getProperties()
                if props then
                    local objectItemHeight = props:getItemHeight()
                    if objectItemHeight and objectItemHeight and objectItemHeight > squareSurfaceOffset then
                        if not objectSpriteName or not StoryItemSpawner.spritesListToIgnoreOffset[objectSpriteName] or squareSurfaceOffset < 5 then
                            squareSurfaceOffset = objectItemHeight
                            tallestObject = object
                        end
                    end
                end
            end

            
            if tallestObject then
                local tallestObjectSprite = tallestObject:getSprite()
                if tallestObjectSprite then
                    local tallestObjectSpriteName = tallestObjectSprite:getName()
                    if tallestObjectSpriteName then

                        local possibleStoriesForThisTile = StoryItemSpawner.GetPossibleStoriesForThisTile(tallestObjectSpriteName, squareSurfaceOffset, _room, itemCountSpawnedByStories, square)

                        if possibleStoriesForThisTile then 
                            local story = StoryItemSpawner.SelectRandomStory(possibleStoriesForThisTile)
                            
                            if story then
                                -- StoryItemSpawner.noise("Selected story "..story.name)
                                
                                local storySpawned =  StoryItemSpawner.RollStory(story, tallestObjectSpriteName, square, squareSurfaceOffset, _room);
                                if not itemCountSpawnedByStories[story.name] then itemCountSpawnedByStories[story.name] = 0 end
                                itemCountSpawnedByStories[story.name] = itemCountSpawnedByStories[story.name] + (storySpawned or 0)
                                storySpawnedInRoomCount = storySpawnedInRoomCount + (storySpawned or 0)
                            else
                                -- StoryItemSpawner.noise("Failed SelectRandomStory")
                            end
                        else
                            -- StoryItemSpawner.noise("Failed GetPossibleStoriesForThisTile")
                        end
                        
                    end
                end
            end
        end
    end
end


---@param _player IsoPlayer
function StoryItemSpawner.CheckPlayerStarterHouse(_player)
    if StoryItemSpawner.EnsureModRunsOnlyOnce(_player) then return end;
    local IS_SINGLEPLAYER = not (isClient() or isServer());
    if not IS_SINGLEPLAYER then return; end
    if getActivatedMods():contains("ImmersiveBarricadedStart") then return; end
    local allRooms = StoryItemSpawner.GetBuildingRooms(_player);
    if allRooms == nil then return; end

    for k,room in pairs(allRooms) do
        StoryItemSpawner.CheckRoom(room)
        room:getRoomDef():setExplored(true)
    end
end


---@param _player IsoPlayer
---@return table|nil
function StoryItemSpawner.GetBuildingRooms(_player)
    local buildingRooms = {};

    local buildingDef = _player:getCurrentBuildingDef();
    if buildingDef == nil then return nil; end

    local arrayOfRooms = buildingDef:getRooms();
    for i = 0, arrayOfRooms:size()-1 do
        local currentRoom = arrayOfRooms:get(i);
        local currentIsoRoom = currentRoom:getIsoRoom();
        table.insert(buildingRooms, currentIsoRoom)
    end

    return buildingRooms;
end


---@param _player IsoPlayer
---@return boolean
function StoryItemSpawner.EnsureModRunsOnlyOnce(_player)
    _player:getModData().StoryItemSpawner = _player:getModData().StoryItemSpawner or {}
    local hasModBeenRan = _player:getModData().StoryItemSpawner.HasModBeenRan or false;
    if hasModBeenRan then
        return hasModBeenRan;
    else
        _player:getModData().StoryItemSpawner.HasModBeenRan = true;
        return false;
    end;
end

---@param inputstr string
---@param sep string
---@return table
local function stringsplit(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end


-- To save on performance, this function generates weight chances when the game loads, so we don't have to do it on each CheckRoom.
function StoryItemSpawner.GenerateTotalChances()

    for storyKey, story in pairs(StoryItemSpawner.storyList) do
        local totalChance = 0
        for j = 1, #story.items, 1 do
        -- for _, entry in ipairs(story.items) do
            totalChance = totalChance + story.items[j].chance
            if story.items[j].proceduralTable then
                local totalChanceTable = 0
                if story.items[j].table and story.items[j].table.items and story.items[j].table.items[2] then
                    for i = 2, #story.items[j].table.items, 2 do
                        if story.items[j].table.items[i] and story.items[j].table.items[i] == "number" then
                            totalChanceTable = totalChanceTable + story.items[j].table.items[i]
                        end
                    end
                end
                StoryItemSpawner.storyList[storyKey].items[j].totalChance = totalChanceTable
            end
        end
        StoryItemSpawner.storyList[storyKey].totalChance = totalChance;
    end


    for k, v in pairs(ProceduralDistributions.list) do
        if v.items and type(v.items)=="table" and #v.items > 1 then
            local totalChanceTable = 0
            for l, v in pairs(v.items) do
                if type(v) == "number" and v > 0 then
                    totalChanceTable = totalChanceTable + v
                end
            end
            ProceduralDistributions.list[k].totalChanceProcedural = totalChanceTable
        end
    end

    for roomKey, roomLootTable in pairs(SuburbsDistributions) do

        if roomLootTable.rolls and roomLootTable.items then
            if roomLootTable.rolls > 0 and roomLootTable.items and type(roomLootTable.items)=="table" and #roomLootTable.items > 1 then
                local totalChanceNonProcedural = 0
                for i= 2, #roomLootTable.items, 2 do
                    if roomLootTable.items[i] and type(roomLootTable.items[i]) =="number" and roomLootTable.items[i] > 0 then
                        totalChanceNonProcedural = totalChanceNonProcedural + roomLootTable.items[i]
                    end
                end
                SuburbsDistributions[roomKey].totalChanceNonProcedural = totalChanceNonProcedural
            end
        else
            local totalFurnitureChance = 0
            for furnitureKey, furnitureLootTable in pairs(SuburbsDistributions[roomKey]) do
                
                if type(furnitureLootTable) == "table" and furnitureLootTable.procedural then
                    if #furnitureLootTable.procList > 1 then
                        local totalProcEntryWeightChance = 0;
                        for indexEntry, procEntry in pairs(furnitureLootTable.procList) do
                            if procEntry.forceForTiles then
                                SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].tilesForcedList = {}
                                for tileK, tile in pairs(stringsplit(procEntry.forceForTiles, ';')) do
                                    SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].tilesForcedList[tile] = 1
                                end
                            end
                            if procEntry.forceForRooms then
                                SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].roomsForcedList = {}
                                for roomK, room in pairs(stringsplit(procEntry.forceForRooms, ';')) do
                                    SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].roomsForcedList[room] = 1
                                end
                            end
                            if procEntry.forceForZones then
                                SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].zonesForcedList = {}
                                for zoneK, zone in pairs(stringsplit(procEntry.forceForZones, ';')) do
                                    SuburbsDistributions[roomKey][furnitureKey].procList[indexEntry].zonesForcedList[zone] = 1
                                end
                            end
                            totalProcEntryWeightChance = totalProcEntryWeightChance + (procEntry.weightChance or StoryItemSpawner.settings.weightChanceDefault);
                        end
                        SuburbsDistributions[roomKey][furnitureKey].totalProcListWeightChance = totalProcEntryWeightChance
                    else
                        SuburbsDistributions[roomKey][furnitureKey].totalProcListWeightChance = StoryItemSpawner.settings.weightChanceDefault
                    end
                    if not StoryItemSpawner.ignoreFurnitureListForRoomLoot[furnitureKey] then
                        totalFurnitureChance = totalFurnitureChance + SuburbsDistributions[roomKey][furnitureKey].totalProcListWeightChance
                    end
                else
                    if type(furnitureLootTable) == "table" and furnitureLootTable.rolls and furnitureLootTable.rolls > 0  and #furnitureLootTable.items > 1 then
                        
                        local totalChanceNonProcedural = 0
                        for i= 2, #furnitureLootTable.items, 2 do
                            if furnitureLootTable.items[i] and type(furnitureLootTable.items[i]) == "number" and furnitureLootTable.items[i] > 0 then
                                totalChanceNonProcedural = totalChanceNonProcedural + furnitureLootTable.items[i]
                            end
                        end
                        SuburbsDistributions[roomKey][furnitureKey].totalChanceNonProcedural = totalChanceNonProcedural
                        if not StoryItemSpawner.ignoreFurnitureListForRoomLoot[furnitureKey] then
                            totalFurnitureChance = totalFurnitureChance + SuburbsDistributions[roomKey][furnitureKey].totalChanceNonProcedural
                        end
                    end
                end
            end
            SuburbsDistributions[roomKey].totalFurnitureChance = totalFurnitureChance
        end
    end
end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function StoryItemSpawner.calculateDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = (z2 - z1)*2 -- multiply z diff because one z level is equal to about 3 to 4 tiles , and rooms and different levels should be prioritized less anyway
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end


---@param value1 number
---@param value2 number
---@param number number
---@return number
function StoryItemSpawner.nearestValue(value1, value2, number)
    local diff1 = math.abs(number-value1)
    local diff2 = math.abs(number-value2)
    if diff1 < diff2 then
        return diff1
    end
    return diff2
end


---@param room1 IsoRoom
---@param room2 IsoRoom
---@param playerX number
---@param playerY number
---@param playerZ number
---@return boolean
function StoryItemSpawner.compareDistance(room1, room2, playerX, playerY, playerZ)
    -- local room1Def = room1:getRoomDef()
    -- local room1DefX1 = room1Def:getX()
    -- local room1DefX2 = room1Def:getX2()
    -- local room1DefY1 = room1Def:getX()
    -- local room1DefY2 = room1Def:getX2()
    -- local room1Z = room1Def:getZ()
    -- if room1Z == playerZ and room1DefX1 >= playerX and  room1DefX2 <= playerX and room1DefY1 >= playerY and room1DefY2 <= playerY then -- player is in room 1
    --     return true
    -- end
    -- local room2Def = room2:getRoomDef()
    -- local room2DefX1 = room2Def:getX()
    -- local room2DefX2 = room2Def:getX2()
    -- local room2DefY1 = room2Def:getX()
    -- local room2DefY2 = room2Def:getX2()
    -- local room2Z = room2Def:getZ()
    -- if room2Z == playerZ and room2DefX1 >= playerX and  room2DefX2 <= playerX and room2DefY1 >= playerY and room2DefY2 <= playerY then -- player is in room 2
    --     return false
    -- end
    -- local room1X = StoryItemSpawner.nearestValue(room1DefX1, room1DefX2, playerX)
    -- local room1Y = StoryItemSpawner.nearestValue(room1DefY1, room1DefY2, playerY)
    -- local room2X = StoryItemSpawner.nearestValue(room2DefX1, room2DefX2, playerX)
    -- local room2Y = StoryItemSpawner.nearestValue(room2DefY1, room2DefY2, playerY)
    -- return StoryItemSpawner.calculateDistance(playerX, playerY, playerZ, room1X, room1Y, room1Z) < StoryItemSpawner.calculateDistance(playerX, playerY, playerZ, room2X, room2Y, room2Z)

    return math.abs(playerZ - room1:getRoomDef():getZ()) < math.abs(playerZ - room2:getRoomDef():getZ())
end


function StoryItemSpawner.SortRoomsList()
    -- Every minute, we check to sort the roomsList from closest to fursthest to the player
    if #StoryItemSpawner.roomsList > 1 then
        local player = getPlayer()
        local playerX = player:getX()
        local playerY = player:getY()
        local playerZ = player:getZ()
        -- if not StoryItemSpawner.lastPlayerPosition or not StoryItemSpawner.lastPlayerPosition.x or not StoryItemSpawner.lastPlayerPosition.y or not StoryItemSpawner.lastPlayerPosition.z then
        --     StoryItemSpawner.lastPlayerPosition = {
        --         x = playerX,
        --         y = playerY,
        --         z = playerZ,
        --     }
        -- end
        -- the compareDistance sorting function can cause a little lag when the roomsList contains 100+ rooms. So we check if the player has moved far since last time we sorted the table, or if a lot of rooms have been seen at the same time, before sorting the table again
        local roomCountDiff = #StoryItemSpawner.roomsList - (StoryItemSpawner.lastRoomCount or 0)
        local playerDistanceToLastPosition = StoryItemSpawner.calculateDistance(playerX, playerY, playerZ*4, StoryItemSpawner.lastPlayerPosition.x or playerX, StoryItemSpawner.lastPlayerPosition.y or playerY, StoryItemSpawner.lastPlayerPosition.z or playerZ)
        if roomCountDiff > 20 or playerDistanceToLastPosition > 20
            then
            table.sort(StoryItemSpawner.roomsList, function (a, b) return StoryItemSpawner.compareDistance(a, b, playerX, playerY, playerZ) end)
            StoryItemSpawner.lastPlayerPosition = {
                x = playerX,
                y = playerY,
                z = playerZ,
            }
            -- StoryItemSpawner.noise("Sorting RoomsList table !")
            -- StoryItemSpawner.noise("Room Count diff : "..roomCountDiff)
            -- StoryItemSpawner.noise("Player Distance To Last Position : "..math.floor(playerDistanceToLastPosition*100)/100)

        end
        StoryItemSpawner.lastRoomCount = #StoryItemSpawner.roomsList
    end
    StoryItemSpawner.noise("Rooms List count = "..#StoryItemSpawner.roomsList)
end

---@param _room IsoRoom
function StoryItemSpawner.AddRoomToList(_room)
    -- if #StoryItemSpawner.roomsList - (StoryItemSpawner.lastRoomCount or 0) > 20 then
    --     local player = getPlayer()
    --     local playerX = player:getX()
    --     local playerY = player:getY()
    --     local playerZ = player:getZ()
    --     table.sort(StoryItemSpawner.roomsList, function (a, b) return StoryItemSpawner.compareDistance(a, b, playerX, playerY, playerZ) end)
    --     StoryItemSpawner.lastRoomCount = #StoryItemSpawner.roomsList
    -- end
    if StoryItemSpawner.tickCounter >= StoryItemSpawner.tickInterval and not StoryItemSpawner.roomsList[1] then
        StoryItemSpawner.CheckRoom(_room)
        StoryItemSpawner.tickCounter = 0
    else
        StoryItemSpawner.roomsList[#StoryItemSpawner.roomsList+1] = _room
    end
end

function StoryItemSpawner.AddCellsRoomsToList()
    -- PROJECT ECHO B42.21: this is CLIENT exploration logic. Dedicated
    -- servers have no local player; do not dereference a missing player.
    if isServer and isServer() then return end
    local player = getPlayer and getPlayer()
    if not player then return end
    local playerCell = player:getCell()
    if not playerCell then return end
    local cellRooms = playerCell:getRoomList()
    if not cellRooms then return end
    if cellRooms:size() > 0 then
        for i=0, cellRooms:size()-1, 1 do
            local room = cellRooms:get(i)
            local roomDef = room:getRoomDef()
            if not roomDef:isExplored() then
                local buildingDef = roomDef:getBuilding()
                if buildingDef:isFullyStreamedIn() then
                    -- StoryItemSpawner.AddRoomToList(room)
                    playerCell:roomSpotted(room)
                    roomDef:setExplored(true)
                end
            -- elseif roomDef:getH()*roomDef:getW() < (StoryItemSpawner.settings.sizeToIgnoreRoom or 500)
            --     and StoryItemSpawner.calculateDistance(roomDef:getX(), roomDef:getY(), roomDef:getZ(), player:getX(), player:getY(), player:getZ()) < 150
            --     and StoryItemSpawner.calculateDistance(roomDef:getX2(), roomDef:getY2(), roomDef:getZ(), player:getX(), player:getY(), player:getZ()) < 150 then
            --         StoryItemSpawner.AddRoomToList(room)
            --         playerCell:roomSpotted(room)
            --         roomDef:setExplored(true)



            end
        end
    end
end

-- function StoryItemSpawner.pickRoomIndexWithBuildingFullyStreamedIn()
--     for i = 1, #StoryItemSpawner.roomsList, 1 do
--         if StoryItemSpawner.roomsList[i]:getBuilding():getDef():isFullyStreamedIn() then
--             return i
--         end
--     end
--     return false
-- end

function StoryItemSpawner.TriggerClosestRoomInList()
    StoryItemSpawner.tickCounter = StoryItemSpawner.tickCounter + 1
    if StoryItemSpawner.tickCounter >= StoryItemSpawner.tickInterval then
        if StoryItemSpawner.roomsList[1] then
            -- local indexRoom = StoryItemSpawner.pickRoomIndexWithBuildingFullyStreamedIn()
            -- if indexRoom then
                local room = table.remove(StoryItemSpawner.roomsList, 1)
                StoryItemSpawner.CheckRoom(room)
                StoryItemSpawner.tickCounter = 0
            -- end
        end
    end
    if StoryItemSpawner.tickCounter >= StoryItemSpawner.tickInterval * 50 then
        StoryItemSpawner.tickCounter = 0
    end
end


function StoryItemSpawner.CleanupTables()

end

Events.OnSeeNewRoom.Add(StoryItemSpawner.AddRoomToList)
Events.OnTick.Add(StoryItemSpawner.TriggerClosestRoomInList)
-- Events.EveryOneMinute.Add(StoryItemSpawner.SortRoomsList)
-- This callback relies on getPlayer(): never register it on a dedicated server.
if not (isServer and isServer()) then
    Events.EveryOneMinute.Add(StoryItemSpawner.AddCellsRoomsToList)
end



Events.OnPlayerUpdate.Add(StoryItemSpawner.CheckPlayerStarterHouse)

-- Events.OnNewGame.Add(StoryItemSpawner.GenerateTotalChances)
-- Events.OnGameStart.Add(StoryItemSpawner.GenerateTotalChances)

local function addGenerateTotalChancesEvent() -- necessary to ensure the chances are always generated after all the loot from other mod has been added to the tables
    Events.OnPostDistributionMerge.Add(StoryItemSpawner.GenerateTotalChances)

    -- Events.OnInitWorld.Add(StoryItemSpawner.GenerateTotalChances)
end

Events.OnGameBoot.Add(addGenerateTotalChancesEvent)


-- compatibility fix for More Loot Settings
if getActivatedMods():contains("MoreLootSettings") then
    local function checkDistributionsTweaked()
        ProceduralDistributions = ProceduralDistributions or {}
        if ProceduralDistributions and ProceduralDistributions.tweaked then
            Events.EveryOneMinute.Remove(checkDistributionsTweaked)
            StoryItemSpawner.GenerateTotalChances()
        end
    end
    Events.EveryOneMinute.Add(checkDistributionsTweaked)
end




return StoryItemSpawner