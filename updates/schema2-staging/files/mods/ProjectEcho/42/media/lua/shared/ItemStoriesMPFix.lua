--[[
    Item Stories - Multiplayer Fix   (v2, 2026-08-08)
    -------------------------------------------------
    Makes "Item Stories [b42] [All-in-one]" (ItemStoriesB42) spawn items that
    actually exist on the server, so they can be picked up in multiplayer.

    THE BUG
    Item Stories spawns world items from StoryItemSpawner.RollStory:
        _square:AddWorldInventoryItem(pick, x, y, z)
    with no transmit afterwards, driven by Events.OnSeeNewRoom - which needs a
    local player seeing a room, i.e. it runs on each player's CLIENT. The server
    never learns the item exists. Picking it up opens a server-validated
    createItemTransaction, the server rejects it, and ISGrabItemAction aborts.
    The item sits there forever.

    WHY v1 OF THIS MOD DID NOT WORK
    v1 tried to make the server authoritative by overriding CheckRoom,
    PlaceTileObject and AddCellsRoomsToList, and running its own cell sweep.
    None of it could work, because:

      * A B42 dedicated server does not load media/lua/client/ (measured on
        42.20 with a probe mod: a marker global set in a mod's own client folder
        reads back nil from its server folder, as do ISVehicleMenu and
        ISVehicleDashboard). Every function v1 tried to override lives in
        ItemStories' client folder and is simply absent server-side.
      * v1's `if not StoryItemSpawner then return end` guard nevertheless passed,
        because nine of ItemStories' *server*-folder definition files each open
        with `StoryItemSpawner = StoryItemSpawner or {}`. The namespace exists
        server-side; the functions do not. So v1 logged "applied" and then
        no-op'd every override (`if originalX then` was false throughout), and
        its sweep returned immediately because StoryItemSpawner.roomsList is
        also client-side.

    Guard on the function you need, not the namespace. v2 does.

    THE FIX
    Keep the decision on the client, where all of upstream's logic, chances and
    sandbox options live and work. Move only the ACT of spawning to the server,
    where the engine replicates world items automatically:

      1. Wrap RollStory. Note what upstream added to the square, delete those
         client-side ghosts, and send the server the item types and offsets.
      2. The server spawns them for real, once per square, and re-applies an
         equivalent randomisation. Everything TweakItem does is random anyway,
         so a server-side re-roll is indistinguishable to the player - and the
         client's own copy is removed, so there is nothing to disagree with.
      3. Per-square dedup, persisted, so several players walking into the same
         building do not each get a spawn.

    Singleplayer and co-op host are left completely untouched.
]]

ItemStoriesMPFix = ItemStoriesMPFix or {}

local MODULE = "ItemStoriesMPFix"

ItemStoriesMPFix.applied = false
ItemStoriesMPFix.suppressedTileObjects = 0

---@param _text string
function ItemStoriesMPFix.noise(_text)
    if StoryItemSpawner and StoryItemSpawner.testMode then
        print("[ItemStoriesMPFix] " .. tostring(_text))
    end
end

--------------------------------------------------------------------------
-- SERVER: spawn for real, once per square
--------------------------------------------------------------------------

local function store()
    return ModData.getOrCreate(MODULE)
end

--- Upstream's TweakItem, condensed to what can run server-side. Upstream's
--- version lives in client/ and calls client-only helpers; every call below is
--- a plain Java method on InventoryItem, so it works here. The point is not to
--- reproduce a specific roll - it is all random - but to give the same kind of
--- wear, contents and age that upstream would have.
local function tweakItem(item, roomName)
    if not item then return end

    -- PZ42Compat04: already initialized when created as a world item.

    if item:IsWeapon() or item:getCondition() ~= 10 then
        if ZombRand(100) < 60 then
            item:randomizeCondition()
            item:randomizeGeneralCondition()
            if item:hasHeadCondition() then item:randomizeHeadCondition() end
            if item:hasSharpness() then item:randomizeSharpness() end
        end
    end

    if item:isFluidContainer() then
        local fluidContainer = item:getFluidContainer()
        if fluidContainer and ZombRand(100) < 50 then
            fluidContainer:unseal()
            if fluidContainer:isFull() then
                fluidContainer:removeFluid(ZombRand(5, 95) / 100)
            end
        end
    end

    if item:hasBlood() and ZombRand(100) < 50 then
        item:setBloodLevel(ZombRand(1, 100) / 100)
    end

    if item:IsDrainable() and ZombRand(100) < 90 then
        item:setUsedDelta(math.floor(ZombRand(ZombRand(1, 90), 100)) / 100)
    end

    if item:IsFood() then item:setAutoAge() end

    -- Containers: fill from the vanilla distribution the same way upstream
    -- does. SuburbsDistributions is server-side data, so this is available.
    if item:IsInventoryContainer() then
        local itemTable = SuburbsDistributions and SuburbsDistributions[item:getType()]
        local container = item:getItemContainer()
        if container and itemTable and itemTable.items and itemTable.rolls and itemTable.rolls > 0 then
            for _ = 1, itemTable.rolls do
                local index = ZombRand(1, #itemTable.items / 2 + 1) * 2 - 1
                local picked = itemTable.items[index]
                if picked then
                    if not string.find(picked, "%.") then picked = "Base." .. picked end
                    container:AddItem(picked)
                end
                if itemTable.onlyOne then break end
            end
        end
    end
end

--- Upstream's PlaceTileObject, vendored so it can run on the server.
---
--- Only this one function is copied, not the spawner: the client still decides
--- WHICH tile object goes WHERE using all of upstream's logic and chances, and
--- sends that decision over. Two substitutions are needed server-side:
---   * getCell() -> getWorld():getCell(), the same swap upstream's own cell
---     sweep needs, because there is no local player to hang a cell off.
---   * transmitCompleteItemToServer() -> transmitCompleteItemToClients(). The
---     former does not exist anywhere in the engine (upstream calls it and it
---     throws on clients); the latter is the correct direction from here and is
---     what makes the object real for everyone.
---
--- Re-check this against upstream after an Item Stories update - it is the only
--- copied code in this mod.
local function placeTileObject(square, entry)
    local spriteName = entry and entry.tileObject
    if not spriteName then return end

    local sprite = getSprite(spriteName)
    if not sprite then return end

    local spriteProperties = sprite:getProperties()
    local isoType = "IsoObject"
    if spriteProperties and spriteProperties:Val("IsoType") ~= nil then
        isoType = spriteProperties:Val("IsoType")
    end

    local cell = getWorld() and getWorld():getCell()
    if not cell then return end

    local container = spriteProperties and spriteProperties:Is("container")
        and spriteProperties:Val("container") or nil

    local isoObject
    if isoType == "IsoBarbecue" then
        isoObject = IsoBarbecue.new(cell, square, sprite)
        isoObject:setMovedThumpable(true)
    elseif isoType == "IsoCombinationWasherDryer" then
        isoObject = IsoCombinationWasherDryer.new(cell, square, sprite)
        isoObject:setMovedThumpable(true)
    elseif isoType == "IsoClothingDryer" then
        isoObject = IsoClothingDryer.new(cell, square, sprite)
        isoObject:setMovedThumpable(true)
    elseif isoType == "IsoClothingWasher" then
        isoObject = IsoClothingWasher.new(cell, square, sprite)
        isoObject:setMovedThumpable(true)
    elseif isoType == "IsoCompost" then
        isoObject = IsoCompost.new(cell, square, sprite)
    elseif isoType == "IsoJukebox" then
        isoObject = IsoJukebox.new(cell, square, sprite)
        isoObject:setMovedThumpable(true)
    else
        isoObject = IsoObject.new(square, spriteName, nil, false)
        isoObject:setMovedThumpable(true)
    end

    if not isoObject then return end

    if not container then
        container = isoObject:getContainer()
        if not container then container = isoObject:getItemContainer() end
    end

    local loot = entry.containerLoot
    if loot and loot.items and loot.itemCount then
        if not container then
            container = ItemContainer.new(spriteName, square, isoObject, 1, 1)
            isoObject:setContainer(container)
        end
        local itemCount = ZombRand(loot.itemCount)
        if container and itemCount > 0 then
            for _ = 1, itemCount do
                local picked = loot.items[ZombRand(1, #loot.items)]
                if picked then
                    if not string.match(picked, "%p") then picked = "Base." .. picked end
                    container:AddItem(picked)
                end
            end
        end
    end

    square:AddTileObject(isoObject)
    triggerEvent("OnObjectAdded", isoObject)

    -- Cosmetic on a server and not guaranteed to exist there; never let them
    -- take the placement down with them.
    pcall(function() ItemPickerJava.updateOverlaySprite(isoObject) end)

    isoObject:transmitCompleteItemToClients()
end

local function onClientCommand(module, command, player, args)
    if module ~= MODULE or command ~= "spawnStoryItems" then return end
    if not args then return end
    if not args.items and not args.tiles then return end

    local key = tostring(args.x) .. "," .. tostring(args.y) .. "," .. tostring(args.z)
    local done = store()
    if done[key] then
        ItemStoriesMPFix.noise("square " .. key .. " already spawned, dropping duplicate request")
        return
    end

    local square = getSquare(args.x, args.y, args.z)
    if not square then
        -- Not streamed in server-side. Do NOT mark it done: a later request for
        -- the same square should still be able to spawn.
        ItemStoriesMPFix.noise("square " .. key .. " not loaded server-side")
        return
    end

    done[key] = true

    local spawned = 0
    if args.items then
        for i = 1, #args.items do
            local entry = args.items[i]
            if entry and entry.type then
                local item = square:AddWorldInventoryItem(entry.type,
                    entry.ox or 0.5, entry.oy or 0.5, entry.oz or 0)
                if item then
                    tweakItem(item, args.room)
                    spawned = spawned + 1
                end
            end
        end
    end

    local tiles = 0
    if args.tiles then
        for i = 1, #args.tiles do
            -- One bad sprite must not cost the rest of the square.
            local ok = pcall(placeTileObject, square, args.tiles[i])
            if ok then tiles = tiles + 1 end
        end
    end

    ItemStoriesMPFix.noise("spawned " .. spawned .. " item(s) and " .. tiles ..
        " tile object(s) server-side at " .. key)
end

--------------------------------------------------------------------------
-- CLIENT: decide as upstream does, then hand the spawn to the server
--------------------------------------------------------------------------

-- Set to a table for the duration of one RollStory call, so the PlaceTileObject
-- replacement below can hand its decision back up rather than placing anything.
local pendingTiles = nil

--- Wraps RollStory. RollStory is reached by table lookup from CheckRoom, so
--- replacing it here takes effect even though CheckRoom itself was captured by
--- value when it was registered.
local function wrapRollStory()
    local originalRollStory = StoryItemSpawner.RollStory
    if not originalRollStory then return false end

    StoryItemSpawner.RollStory = function(_story, _tallestObjectSpriteName, _square, _squareSurfaceOffset, _room)
        if not isClient() or not _square then
            return originalRollStory(_story, _tallestObjectSpriteName, _square, _squareSurfaceOffset, _room)
        end

        local worldObjects = _square:getWorldObjects()
        local before = worldObjects and worldObjects:size() or 0

        pendingTiles = {}
        local result = originalRollStory(_story, _tallestObjectSpriteName, _square, _squareSurfaceOffset, _room)
        local tiles = pendingTiles
        pendingTiles = nil

        worldObjects = _square:getWorldObjects()
        local after = worldObjects and worldObjects:size() or 0
        if after <= before and #tiles == 0 then return result end

        local sx, sy, sz = _square:getX(), _square:getY(), _square:getZ()
        local payload = {}
        local ghosts = {}

        for i = before, after - 1 do
            local obj = worldObjects:get(i)
            local item = obj and obj:getItem()
            if item then
                payload[#payload + 1] = {
                    type = item:getFullType(),
                    ox = obj:getWorldPosX() - sx,
                    oy = obj:getWorldPosY() - sy,
                    oz = obj:getWorldPosZ() - sz,
                }
                ghosts[#ghosts + 1] = obj
            end
        end

        -- Drop the client-local copies. They are invisible to the server and
        -- can never be picked up; the server's replicated versions replace them.
        for i = 1, #ghosts do
            ghosts[i]:removeFromWorld()
        end

        if #payload > 0 or #tiles > 0 then
            sendClientCommand(getPlayer(), MODULE, "spawnStoryItems", {
                x = sx, y = sy, z = sz,
                room = _room and _room:getName() or nil,
                items = payload,
                tiles = tiles,
            })
            ItemStoriesMPFix.noise("handed " .. #payload .. " item(s) and " .. #tiles ..
                " tile object(s) to the server at " .. sx .. "," .. sy .. "," .. sz)
        end

        return result
    end

    return true
end

--- Tile objects (furniture, crates, containers) cannot be handed to the server
--- the way a finished item can: there is no API to register a client-created
--- IsoObject with it. `transmitCompleteItemToServer`, which upstream calls at
--- the end of PlaceTileObject, does not exist anywhere in the engine - verified
--- by scanning every class under zombie/iso/ in projectzomboid.jar, and it
--- appears nowhere in vanilla's own Lua either. On a client that call throws,
--- aborting the rest of the roll and leaving furniture only that player sees.
---
--- So the client places nothing and instead reports WHAT upstream chose. The
--- server builds it for real via the vendored placeTileObject above. Upstream's
--- selection logic, chances and container loot tables are untouched - only the
--- construction moves.
local function divertTileObjectsToServer()
    local originalPlaceTileObject = StoryItemSpawner.PlaceTileObject
    if not originalPlaceTileObject then return false end

    StoryItemSpawner.PlaceTileObject = function(_square, _pick)
        if not isClient() then
            return originalPlaceTileObject(_square, _pick)
        end

        if pendingTiles and _pick and _pick.TileObject then
            local loot = _pick.containerLoot
            pendingTiles[#pendingTiles + 1] = {
                tileObject = _pick.TileObject,
                containerLoot = (loot and loot.items and loot.itemCount) and {
                    items = loot.items,
                    itemCount = loot.itemCount,
                } or nil,
            }
        else
            -- Outside a RollStory call there is nobody to hand it to. Dropping
            -- it is still better than placing scenery only this player can see.
            ItemStoriesMPFix.suppressedTileObjects = ItemStoriesMPFix.suppressedTileObjects + 1
        end
    end

    return true
end

--------------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------------

function ItemStoriesMPFix.init()
    if ItemStoriesMPFix.applied then return end

    -- Singleplayer and co-op host: upstream works there, leave it alone.
    if not (isClient() or isServer()) then return end

    if isServer() then
        ItemStoriesMPFix.applied = true
        Events.OnClientCommand.Add(onClientCommand)
        print("[ItemStoriesMPFix] v2 server half ready")
        return
    end

    -- Client. Guard on the FUNCTIONS, not the namespace - see the header.
    if not StoryItemSpawner or not StoryItemSpawner.RollStory then
        print("[ItemStoriesMPFix] StoryItemSpawner.RollStory not found - host mod " ..
            "missing or restructured; standing down.")
        return
    end

    ItemStoriesMPFix.applied = true

    local wrappedRoll = wrapRollStory()
    local wrappedTile = divertTileObjectsToServer()

    -- Upstream's own cell sweep dereferences getPlayer(), which is nil on a
    -- client before the player exists (main menu, loading), and threw a stack
    -- trace every EveryOneMinute tick. Deregister it and guard the function
    -- itself in case something re-adds it.
    if StoryItemSpawner.AddCellsRoomsToList then
        Events.EveryOneMinute.Remove(StoryItemSpawner.AddCellsRoomsToList)

        local originalAddCells = StoryItemSpawner.AddCellsRoomsToList
        StoryItemSpawner.AddCellsRoomsToList = function(...)
            local player = getPlayer and getPlayer()
            if not player or not player:getCell() then return end
            return originalAddCells(...)
        end
    end

    print("[ItemStoriesMPFix] v2 client half applied (rollStory=" .. tostring(wrappedRoll) ..
        " tileObjects=" .. tostring(wrappedTile) .. ")")
end

Events.OnGameBoot.Add(ItemStoriesMPFix.init)
-- Belt and braces: OnGameBoot can land before the host mod's client files have
-- defined RollStory. OnGameStart always runs after them, and init is idempotent.
Events.OnGameStart.Add(ItemStoriesMPFix.init)
Events.OnServerStarted.Add(ItemStoriesMPFix.init)
