-- PROJECT ECHO - Guns93 Spawner Guard v0.1.0 TEST (B42.21)
-- Does NOT override Guns93SpawnerItemsReplacer.lua. Runs after Guns93's handlers.
-- Dedicated server authority only: replacement, NOT silent deletion.
if isClient() then return end

local PREFIX = "[PE Guns93 SpawnerGuard v0.1.0]"
local TICK_INTERVAL = 240
local tickCount = 0
local lastFailure = {}
local stats = { containers = 0, world = 0, failed = 0 }

local CATEGORY_WEIGHTS = { {"Common", 34}, {"Uncommon", 30}, {"Rare", 30}, {"VaryRare", 6} }
local CAPS = { ["Base.SPAS12"] = 6, ["Base.HK91"] = 10, ["Base.HK93"] = 10 }

local function isSpawner(item)
    if not item or not item.getFullType then return false end
    local full = item:getFullType()
    return type(full) == "string" and full:match("^Base%.Guns93[%w_]+Spawner$") ~= nil
end

local function canSpawn(full)
    local cap = CAPS[full]
    if not cap then return true end
    if not ModData or not ModData.getOrCreate then return true end
    local ok, state = pcall(ModData.getOrCreate, "Guns93_ItemSpawnCounts")
    if not ok or not state or not state.counts then return true end
    return (state.counts[full] or 0) < cap
end

local function countSpawn(full)
    if not CAPS[full] or not ModData or not ModData.getOrCreate then return end
    local ok, state = pcall(ModData.getOrCreate, "Guns93_ItemSpawnCounts")
    if not ok or not state then return end
    state.counts = state.counts or {}
    state.counts[full] = (state.counts[full] or 0) + 1
    if ModData.transmit then pcall(ModData.transmit, "Guns93_ItemSpawnCounts") end
end

local function itemTypeValid(full)
    return ScriptManager and ScriptManager.instance and ScriptManager.instance:getItem(full)
end

local function rollGun(spawner)
    local category = spawner:getFullType():match("^Base%.Guns93([%w_]+)Spawner$")
    if not category then return nil end
    -- The upstream Guns93 table stores short names (e.g. 'M9') rather than 'Base.M9'.
    local pools = {}
    local total = 0
    for _, entry in ipairs(CATEGORY_WEIGHTS) do
        local list = _G["Spawn" .. category .. entry[1]]
        if type(list) == "table" and #list > 0 then
            local valid = {}
            for i = 1, #list do
                local raw = list[i]
                if type(raw) == "string" then
                    local full = raw:find("%.") and raw or ("Base." .. raw)
                    if itemTypeValid(full) and canSpawn(full) then
                        valid[#valid + 1] = full
                    end
                end
            end
            if #valid > 0 then
                pools[#pools + 1] = { valid = valid, weight = entry[2] }
                total = total + entry[2]
            end
        end
    end
    if total <= 0 then return nil end
    local d = ZombRand(total)
    for _, pool in ipairs(pools) do
        if d < pool.weight then
            local full = pool.valid[ZombRand(#pool.valid) + 1]
            -- Some Guns93 guns have alternative caliber script variants.
            if ZombRand(10) >= 7 and itemTypeValid(full .. "_Alt") then
                full = full .. "_Alt"
            end
            local gun = instanceItem(full)
            if gun and not isSpawner(gun) and instanceof(gun, "HandWeapon") then
                return gun
            end
            return nil
        end
        d = d - pool.weight
    end
    return nil
end

local function logFailure(spawner, reason)
    stats.failed = stats.failed + 1
    local k = spawner:getFullType() .. "|" .. tostring(reason)
    if not lastFailure[k] then
        lastFailure[k] = true
        print(PREFIX .. " unresolved " .. k .. " (original kept)")
    end
end

local function processContainer(container, depth, seen)
    if not container or depth > 3 or seen[container] then return end
    seen[container] = true
    if not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    local snapshot = {}
    for i = 0, items:size() - 1 do snapshot[#snapshot+1] = items:get(i) end
    for _, item in ipairs(snapshot) do
        if item and isSpawner(item) then
            if container:contains(item) then
                local gun = rollGun(item)
                if gun then
                    local ok, err = pcall(function()
                        -- Add first: never remove placeholder if the actual gun cannot be inserted.
                        local inserted = container:AddItem(gun)
                        if not inserted then error("AddItem returned nil") end
                        container:DoRemoveItem(item)
                        if sendRemoveItemFromContainer then sendRemoveItemFromContainer(container, item) end
                        if sendAddItemToContainer then sendAddItemToContainer(container, gun) end
                        if container.setDirty then container:setDirty(true) end
                        if container.setExplored then container:setExplored(true) end
                    end)
                    if ok then
                        countSpawn(gun:getFullType())
                        stats.containers = stats.containers + 1
                        print(PREFIX .. " converted in container " .. item:getFullType() .. " -> " .. gun:getFullType())
                    else
                        logFailure(item, err)
                    end
                else
                    logFailure(item, "no valid weapon in Guns93 spawn pools")
                end
            end
        elseif item and instanceof(item, "InventoryContainer") and item.getInventory then
            local nested = item:getInventory()
            if nested then processContainer(nested, depth+1, seen) end
        end
    end
end

local function processWorld(square)
    local worlds = square:getWorldObjects()
    if not worlds then return end
    local snapshot = {}
    for i = 0, worlds:size() - 1 do snapshot[#snapshot + 1] = worlds:get(i) end
    for _, worldItem in ipairs(snapshot) do
        local item = worldItem and worldItem.getItem and worldItem:getItem()
        if isSpawner(item) then
            local gun = rollGun(item)
            if gun then
                local ok, err = pcall(function()
                    -- Keep the dropped object's location; no arbitrary new loot is created.
                    local x, y, z = 0.5, 0.5, 0
                    if worldItem.getXoff then x = worldItem:getXoff() end
                    if worldItem.getYoff then y = worldItem:getYoff() end
                    if worldItem.getZoff then z = worldItem:getZoff() end
                    local newWorld = square:AddWorldInventoryItem(gun, x, y, z)
                    if not newWorld then error("AddWorldInventoryItem returned nil") end
                    square:removeWorldObject(worldItem)
                    square:transmitRemoveItemFromSquare(worldItem)
                end)
                if ok then
                    countSpawn(gun:getFullType())
                    stats.world = stats.world + 1
                    print(PREFIX .. " converted on ground " .. item:getFullType() .. " -> " .. gun:getFullType())
                else
                    logFailure(item, err)
                end
            else
                logFailure(item, "no valid weapon in Guns93 spawn pools")
            end
        end
    end
end

local function inspectSquare(square, seenContainers, seenBodies)
    if not square then return end
    processWorld(square)
    -- IsoDeadBody is commonly in the STATIC moving-object collection, not getObjects().
    local collections = {}
    if square.getStaticMovingObjects then collections[#collections + 1] = square:getStaticMovingObjects() end
    if square.getMovingObjects then collections[#collections + 1] = square:getMovingObjects() end
    if square.getObjects then collections[#collections + 1] = square:getObjects() end
    for _, objs in ipairs(collections) do
        if objs then
            for i = 0, objs:size() - 1 do
                local obj = objs:get(i)
                if obj and not seenBodies[obj] and (instanceof(obj, "IsoDeadBody") or instanceof(obj, "IsoZombie")) then
                    seenBodies[obj] = true
                    if obj.getContainer then processContainer(obj:getContainer(), 0, seenContainers) end
                end
            end
        end
    end
    if square.getDeadBody then
        local body = square:getDeadBody()
        if body and not seenBodies[body] then
            seenBodies[body] = true
            if body.getContainer then processContainer(body:getContainer(), 0, seenContainers) end
        end
    end
end

local function onFillContainer(roomType, containerType, container)
    if not container then return end
    -- Registered after upstream via zzzz filename; acts only if upstream left a placeholder.
    processContainer(container, 0, {})
end

local function scanPlayers()
    local online = getOnlinePlayers and getOnlinePlayers() or nil
    local players = {}
    if online and online:size() > 0 then
        for i = 0, online:size()-1 do players[#players+1] = online:get(i) end
    elseif getPlayer then
        local player = getPlayer()
        if player then players[1] = player end
    end
    local cell = getCell and getCell()
    if not cell then return end
    local seenContainers = {}
    local seenBodies = {}
    local seenSquares = {}
    for _, player in ipairs(players) do
        if player and player.getSquare and player:getSquare() then
            if player.getInventory then processContainer(player:getInventory(), 0, seenContainers) end
            local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
            for dz = -1, 1 do
                local z = pz + dz
                if z >= 0 then
                    for dx = -3, 3 do
                        for dy = -3, 3 do
                            local x, y = px + dx, py + dy
                            local k = x .. ":" .. y .. ":" .. z
                            if not seenSquares[k] then
                                seenSquares[k] = true
                                inspectSquare(cell:getGridSquare(x, y, z), seenContainers, seenBodies)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function onTick()
    tickCount = tickCount + 1
    if tickCount < TICK_INTERVAL then return end
    tickCount = 0
    local ok, err = pcall(scanPlayers)
    if not ok then print(PREFIX .. " ERROR during scan: " .. tostring(err)) end
end

Events.OnFillContainer.Add(onFillContainer)
Events.OnTick.Add(onTick)
print(PREFIX .. " ACTIVE server-only, checks player bags, corpses, nearby floor; original Guns93 patch remains")
