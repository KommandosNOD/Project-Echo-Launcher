-- COPIED FROM TWISTONFIRE - All credit to him.
-- Layering: BodyLocationsTweaker (Build 42.13+) 
-- Uses ItemBodyLocation registries directly (vanilla ItemBodyLocation.* and modded XX.ItemBodyLocation.*).

-- RM_ServerCompatPatch: BodyLocations fallback guard.
-- B42.21 usually exposes BodyLocations before this shared file. Avoid trying an
-- obsolete path when the global is already available, while preserving both
-- original fallbacks if it is genuinely missing.
if not BodyLocations then
    pcall(require, "Definitions/BodyLocations")
end
if not BodyLocations then
    pcall(require, "NPCs/BodyLocations")
end

-- Layering: BodyLocationsTweaker (Build 42.13+)
-- Reorders via group:moveLocationToIndex() (no mutable list / no reflection).

BodyLocationsTweaker = BodyLocationsTweaker or {}
BodyLocationsTweaker.group = BodyLocations.getGroup("Human")


function BodyLocationsTweaker:_clampIndex(idx)
    local g = self.group
    if not g then return 0 end

    local size = g:size()
    if size <= 0 then return 0 end
    if idx < 0 then return 0 end
    -- moveLocationToIndex usually accepts 0..size (size == append).
    if idx > size then return size end
    return idx
end

function BodyLocationsTweaker:moveOrCreateBeforeOrAfter(toRelocateOrCreate, anchorLocation, afterBoolean)
    local g = self.group
    if not g or not toRelocateOrCreate or not anchorLocation then return nil end

    -- Ensure both exist
    g:getOrCreateLocation(anchorLocation)
    g:getOrCreateLocation(toRelocateOrCreate)

    local anchorIndex = g:indexOf(anchorLocation)
    if not anchorIndex or anchorIndex < 0 then
        return g:getLocation(toRelocateOrCreate)
    end

    local curIndex = g:indexOf(toRelocateOrCreate)
    if not curIndex then curIndex = -1 end

    local targetIndex = anchorIndex + (afterBoolean and 1 or 0)

    -- If the item is removed from before the insertion point, the insertion point shifts left by 1.
    if curIndex >= 0 and curIndex < targetIndex then
        targetIndex = targetIndex - 1
    end

    targetIndex = self:_clampIndex(targetIndex)

    local ok, err = pcall(function()
        g:moveLocationToIndex(toRelocateOrCreate, targetIndex)
    end)

    if not ok then
        print("[TWA] moveLocationToIndex failed. Cannot reorder bodylocations safely. Err=" .. tostring(err))
    end

    return g:getLocation(toRelocateOrCreate)
end

function BodyLocationsTweaker:moveOrCreateBefore(toRelocateOrCreate, anchorLocation)
    return self:moveOrCreateBeforeOrAfter(toRelocateOrCreate, anchorLocation, false)
end

function BodyLocationsTweaker:moveOrCreateAfter(toRelocateOrCreate, anchorLocation)
    return self:moveOrCreateBeforeOrAfter(toRelocateOrCreate, anchorLocation, true)
end

BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWSLEEVES, ItemBodyLocation.HANDS)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWHARNESSUNDER, ItemBodyLocation.UNDERWEAR_EXTRA1)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWHARNESSOVER, ItemBodyLocation.SCARF)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWLEGHARNESSUNDER, ItemBodyLocation.UNDERWEAR_EXTRA2)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWLEGHARNESSOVER, ItemBodyLocation.SCARF)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWTRENCHCOAT, ItemBodyLocation.JACKET_SUIT)
BodyLocationsTweaker:moveOrCreateBefore(TWA.ItemBodyLocation.TWJACKET, ItemBodyLocation.JACKET)
BodyLocationsTweaker:moveOrCreateAfter(TWA.ItemBodyLocation.TWDUFFEL, ItemBodyLocation.BACK)
BodyLocationsTweaker:moveOrCreateAfter(TWA.ItemBodyLocation.TWDUFFELLOW, ItemBodyLocation.BACK)
BodyLocationsTweaker:moveOrCreateAfter(TWA.ItemBodyLocation.TWXLCOFFIN, ItemBodyLocation.BACK)

local SL 								= TWA.ItemBodyLocation.TWSLEEVES
local HU								= TWA.ItemBodyLocation.TWHARNESSUNDER
local HO								= TWA.ItemBodyLocation.TWHARNESSOVER
local LHU								= TWA.ItemBodyLocation.TWLEGHARNESSUNDER
local LHO								= TWA.ItemBodyLocation.TWLEGHARNESSOVER
local TR								= TWA.ItemBodyLocation.TWTRENCHCOAT
local J									= TWA.ItemBodyLocation.TWJACKET
local D									= TWA.ItemBodyLocation.TWDUFFEL
local DL								= TWA.ItemBodyLocation.TWDUFFELLOW
local XL								= TWA.ItemBodyLocation.TWXLCOFFIN

-- Debug / dev toggles
local TWA_DEBUG_DUMP_BODYLOCATION_ORDER = false           -- set true if you want the dump in console.txt

local group                             = BodyLocationsTweaker.group

-- Bidirectional exclusive helper (A blocks B AND B blocks A)
local function ex(a, b)
    group:setExclusive(a, b)
    group:setExclusive(b, a)
end

ex(TR, J)

ex(D, DL)

ex(XL, D)
ex(XL, DL)

ex(XL, ItemBodyLocation.BACK)
ex(D, ItemBodyLocation.BACK)

ex(TR, ItemBodyLocation.JACKET)
ex(TR, ItemBodyLocation.JACKET_DOWN)
ex(TR, ItemBodyLocation.JACKET_BULKY)
ex(TR, ItemBodyLocation.JACKET_HAT)
ex(TR, ItemBodyLocation.JACKET_HAT_BULKY)
ex(TR, ItemBodyLocation.SWEATER)
ex(TR, ItemBodyLocation.JACKET_SUIT)
ex(TR, ItemBodyLocation.FULL_SUIT)
ex(TR, ItemBodyLocation.BOILERSUIT)
ex(TR, ItemBodyLocation.BATH_ROBE)
ex(TR, ItemBodyLocation.FULL_ROBE)

ex(J, ItemBodyLocation.JACKET)
ex(J, ItemBodyLocation.JACKET_DOWN)
ex(J, ItemBodyLocation.JACKET_BULKY)
ex(J, ItemBodyLocation.JACKET_HAT)
ex(J, ItemBodyLocation.JACKET_HAT_BULKY)
ex(J, ItemBodyLocation.SWEATER)
ex(J, ItemBodyLocation.JACKET_SUIT)
ex(J, ItemBodyLocation.FULL_SUIT)
ex(J, ItemBodyLocation.BOILERSUIT)
ex(J, ItemBodyLocation.BATH_ROBE)
ex(J, ItemBodyLocation.FULL_ROBE)

group:setHideModel(TR, ItemBodyLocation.JERSEY)
group:setHideModel(J, ItemBodyLocation.JERSEY)

------------------------------------------------------------
-- HideModel rules
------------------------------------------------------------

local function hideTargets(sourceSlot, targets)
    for i = 1, #targets do
        group:setHideModel(sourceSlot, targets[i])
    end
end

local function hideTargetWhenWearing(wearSlots, targetSlot)
    for i = 1, #wearSlots do
        group:setHideModel(wearSlots[i], targetSlot)
    end
end



-- optional dump in your console.txt to see your current bodylocation order
function BodyLocationsTweaker:dumpOrder(label)
    local g = self.group
    label = label or "Human"
    print("[TWA] Dumping BodyLocation order for group: " .. label)

    for i = 0, g:size() - 1 do
        local loc = g:getLocationByIndex(i)
        local id = loc and loc:getId()
        print(string.format("[TWA] [%03d] %s", i, tostring(id)))
    end
end

if TWA_DEBUG_DUMP_BODYLOCATION_ORDER then
    BodyLocationsTweaker:dumpOrder("Human")
end

