-- PROJECT ECHO - Safe Sleep Approach Fix 0.1.0 (B42.21 MP)
-- Fixes: ISWorldObjectContextMenu.onConfirmSleep queues a pathToNearest()
-- action with zero coordinates when a multi-tile couch / chair / bed has no
-- vanilla access points. Java pathToNearestTable() rejects an empty table.
-- Scope: confirmed sleep on sprite-grid furniture only. No teleportation,
-- no mutation of sprite data, no change to sleep checks or sleep rules.

require "ISUI/ISWorldObjectContextMenu"

local TAG = "[PE SleepApproach v0.1.0]"

local function report(message)
    print(TAG .. " " .. tostring(message))
end

local function playerMessage(playerObj, message)
    report(message)
    if not playerObj then return end
    if HaloTextHelper and HaloTextHelper.addBadText then
        pcall(HaloTextHelper.addBadText, playerObj,
            "Нет безопасного подхода к месту сна")
    end
end

local function getSquare(obj)
    if not obj then return nil end
    local ok, sq = pcall(function() return obj:getSquare() end)
    if ok then return sq end
    return nil
end

local function collectGridObjects(bed)
    local objects = {}
    if not ArrayList or not ArrayList.new then return objects end
    local array = ArrayList.new()
    local ok = pcall(function() bed:getSpriteGridObjectsIncludingSelf(array) end)
    if not ok then return objects end
    for i = 0, array:size() - 1 do
        local obj = array:get(i)
        if getSquare(obj) then objects[#objects + 1] = obj end
    end
    return objects
end

-- Mirror vanilla B42.21 preflight: any valid cardinal neighboring target?
-- If yes, do not interfere and let the original menu action handle it.
local function vanillaHasApproach(objects, playerSq)
    if not playerSq or not AdjacentFreeTileFinder or not IsoDirections then return true end
    local dirs = { IsoDirections.N, IsoDirections.S, IsoDirections.W, IsoDirections.E }
    for _, obj in ipairs(objects) do
        local sq = getSquare(obj)
        if sq then
            local dx, dy = sq:getX() - playerSq:getX(), sq:getY() - playerSq:getY()
            if not (dx ~= 0 and dy ~= 0) and
                AdjacentFreeTileFinder.isTileOrAdjacent(sq, playerSq) then
                return true
            end
            for _, dir in ipairs(dirs) do
                local target = sq:getAdjacentSquare(dir)
                if target and AdjacentFreeTileFinder.isTileOrAdjacent(sq, target) then
                    return true
                end
            end
        end
    end
    return false
end

-- Use PZ's own AdjacentFreeTileFinder to locate a real adjacent square.
-- We never select a nonadjacent square or bypass physical obstructions.
local function bestAccessibleSquare(objects, playerObj)
    if not AdjacentFreeTileFinder or not AdjacentFreeTileFinder.Find then return nil, nil end
    local current = playerObj:getCurrentSquare()
    if not current then return nil, nil end
    local selected, selectedObject, nearest = nil, nil, math.huge
    for _, obj in ipairs(objects) do
        local sq = getSquare(obj)
        if sq and sq:getZ() == current:getZ() then
            local ok, target = pcall(AdjacentFreeTileFinder.Find, sq, playerObj)
            if ok and target and target:getZ() == sq:getZ() then
                local dx = math.abs(target:getX() - sq:getX())
                local dy = math.abs(target:getY() - sq:getY())
                -- Finder should return a neighboring tile. Do not allow an
                -- unrelated distant result to be treated as a valid sleep spot.
                if math.max(dx, dy) <= 1 and (dx + dy) > 0 then
                    local d = (target:getX() - current:getX()) ^ 2 +
                              (target:getY() - current:getY()) ^ 2
                    if d < nearest then
                        selected, selectedObject, nearest = target, obj, d
                    end
                end
            end
        end
    end
    return selected, selectedObject
end

local function install()
    if not ISWorldObjectContextMenu or
       type(ISWorldObjectContextMenu.onConfirmSleep) ~= "function" then
        report("vanilla sleep hook not ready")
        return false
    end
    if ISWorldObjectContextMenu.PE_SleepApproach_Installed then return true end

    local original = ISWorldObjectContextMenu.onConfirmSleep
    ISWorldObjectContextMenu.onConfirmSleep = function(this, button, player, bed)
        if not button or button.internal ~= "YES" or not bed then
            return original(this, button, player, bed)
        end

        local okGrid, spriteGrid = pcall(function() return bed:hasSpriteGrid() end)
        if not okGrid or not spriteGrid then
            return original(this, button, player, bed)
        end

        local playerObj = getSpecificPlayer and getSpecificPlayer(player)
        if not playerObj or not playerObj:getCurrentSquare() then
            return original(this, button, player, bed)
        end

        local objects = collectGridObjects(bed)
        -- Preserve vanilla's shortcut when the player is already seated
        -- on any part of the selected multi-tile furniture.
        if playerObj.isSittingOnFurniture and playerObj:isSittingOnFurniture() then
            local seated = playerObj:getSitOnFurnitureObject()
            for _, part in ipairs(objects) do
                if part == seated then
                    return original(this, button, player, bed)
                end
            end
        end
        if #objects == 0 then
            -- If the sprite grid is malformed, do not attempt vanilla's
            -- empty list pathfinding. The bed itself can still be checked.
            if getSquare(bed) then objects = { bed } end
        end

        if vanillaHasApproach(objects, playerObj:getCurrentSquare()) then
            return original(this, button, player, bed)
        end

        -- Vanilla would queue a Nearest path action with {} and throw.
        -- Reuse its normal walk-to and sleep-complete callbacks instead.
        ISWorldObjectContextMenu.sleepDialog = nil
        local target, chosenObject = bestAccessibleSquare(objects, playerObj)
        if not target then
            playerMessage(playerObj, "no reachable tile at multi-tile sleep furniture; cancelled")
            return
        end

        -- Apply the same pre-sleep exercise flags that vanilla applies.
        playerObj:setVariable("ExerciseStarted", false)
        playerObj:setVariable("ExerciseEnded", true)
        ISTimedActionQueue.clear(playerObj)

        -- Keep the originally selected piece for bed quality and sleep
        -- (matching vanilla semantics). Walking only changes the approach.
        if target == playerObj:getCurrentSquare() then
            report("already at fallback approach tile; continuing vanilla sleep checks")
            return ISWorldObjectContextMenu.onSleepWalkToComplete(player, bed)
        end

        local action = ISWalkToTimedAction:new(playerObj, target)
        action:setOnComplete(ISWorldObjectContextMenu.onSleepWalkToComplete, player, bed)
        ISTimedActionQueue.add(action)
        local sq = getSquare(chosenObject)
        report(string.format("fallback walk-to (%d,%d,%d) near furniture (%d,%d,%d)",
            target:getX(), target:getY(), target:getZ(),
            sq:getX(), sq:getY(), sq:getZ()))
    end

    ISWorldObjectContextMenu.PE_SleepApproach_Installed = true
    report("installed: multi-tile sleep only; vanilla paths preserved")
    return true
end

if not install() and Events and Events.OnGameStart then
    Events.OnGameStart.Add(install)
end
