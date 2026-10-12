--[[
    TCLootControl.lua  (server-side; also loads in SP)

    1) Per-container cap: limits how many TrueMoozic media items of EACH category
       (cassette / vinyl / CD) can appear in a single freshly-filled container.
       Sandbox: PZTrueMusicSandbox.MaxMediaPerContainer (0 = no cap, default 5).

    2) Mid-save pack loot: when new music packs are added to an existing save,
       sprinkles their media into already-generated containers as squares load.
       Sandbox: PZTrueMusicSandbox.GenerateNewLootMidSave (default false).
]]

if isClient() then return end

require "TCMusicSandbox"
require "TCMusicDefenitions"

local DEBUG = false
local function dlog(msg)
    if DEBUG then print("[TCLootControl] " .. tostring(msg)) end
end

------------------------------------------------------------
-- Media classification (must match TCSpawnController rules)
------------------------------------------------------------
local function getTypeName(fullType)
    if type(fullType) ~= "string" then return nil end
    local dot = string.find(fullType, "%.")
    if not dot then return fullType end
    return string.sub(fullType, dot + 1)
end

local function isCassetteType(typeName)
    if type(typeName) ~= "string" then return false end
    local lower = string.lower(typeName)
    return string.find(lower, "cassette", 1, true) ~= nil
        and string.find(lower, "cassettecase", 1, true) == nil
end

local function isVinylType(typeName)
    if type(typeName) ~= "string" then return false end
    return string.sub(typeName, 1, 5) == "Vinyl"
end

local function isCDType(typeName)
    if type(typeName) ~= "string" then return false end
    local lower = string.lower(typeName)
    if string.find(lower, "cdplayer", 1, true) or string.find(lower, "cdcase", 1, true) or string.find(lower, "cdcarryingcase", 1, true) then
        return false
    end
    if string.sub(typeName, 1, 3) == "CD_" then return true end
    if string.len(typeName) > 2 and string.sub(typeName, -2) == "CD" then return true end
    return false
end

-- Returns "cassette" | "vinyl" | "cd" | nil
local function getMediaCategory(fullType)
    local typeName = getTypeName(fullType)
    if not typeName then return nil end
    if isCassetteType(typeName) then return "cassette" end
    if isVinylType(typeName) then return "vinyl" end
    if isCDType(typeName) then return "cd" end
    return nil
end

-- Is this a music-media item this mod manages? True for TrueMoozic's own media
-- and any detected pack media (never for vanilla items: vanilla uses Disc_Retail/VHS
-- naming which doesn't match the patterns above, and we require a mod module).
local function isManagedMediaItem(item)
    if not item or not item.getFullType then return false end
    local fullType = item:getFullType()
    if type(fullType) ~= "string" then return false end
    local module = string.match(fullType, "^([^%.]+)%.")
    if not module or module == "Base" then return false end
    return getMediaCategory(fullType) ~= nil
end

------------------------------------------------------------
-- 1) Per-container cap (OnFillContainer)
------------------------------------------------------------

-- RM_ServerCompatPatch: B42 ItemPickerContainer guard.
-- OnFillContainer may occasionally receive ItemPickerJava.ItemPickerContainer
-- (a loot-distribution descriptor) instead of zombie.inventory.ItemContainer.
-- It has no getItems() method, so only operate on real ItemContainer-like values.
local function rmCompatGetItems(container)
    -- RM_LOGFIX_V2: a Java ItemPickerContainer is NOT an ItemContainer.
    -- Avoid a caught Java/Lua exception that still generates red ERROR messages.
    if not container or not instanceof then return nil end
    if not instanceof(container, "ItemContainer") then return nil end
    return container:getItems()
end
local function trimContainerMedia(container)
    local cap = TCMusicSandbox.GetMaxMediaPerContainer and TCMusicSandbox.GetMaxMediaPerContainer() or 5
    if not cap or cap <= 0 then return end

    local items = rmCompatGetItems(container)
    if not items then return end

    -- Collect managed media items per category.
    local byCategory = { cassette = {}, vinyl = {}, cd = {} }
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and isManagedMediaItem(it) then
            local cat = getMediaCategory(it:getFullType())
            if cat then
                table.insert(byCategory[cat], it)
            end
        end
    end

    for cat, list in pairs(byCategory) do
        local excess = #list - cap
        if excess > 0 then
            dlog("Trimming " .. excess .. " " .. cat .. " item(s) from container (cap=" .. cap .. ")")
            -- Remove random extras so the survivors vary between containers.
            for _ = 1, excess do
                local idx = ZombRand(#list) + 1
                local victim = table.remove(list, idx)
                if victim then
                    container:Remove(victim)
                end
            end
        end
    end
end

------------------------------------------------------------
-- CD scratches: CDs looted OUTSIDE a CD case roll a scratch tier.
-- Sandbox: PZTrueMusicSandbox.CDScratchCleanChance (% clean, default 75).
------------------------------------------------------------
local SCRATCH_TIERS = { 25, 50, 75, 100 }

local function stampScratchOnCD(item)
    if not item then return end
    local md = item:getModData()
    if md.TMScratchRolled then return end -- roll once per CD, ever
    md.TMScratchRolled = true

    local clean = 75
    if TCMusicSandbox.GetCDScratchCleanChance then
        clean = TCMusicSandbox.GetCDScratchCleanChance()
    end
    if ZombRand(100) < clean then return end -- clean: no label, no skips

    md.TMScratch = SCRATCH_TIERS[ZombRand(#SCRATCH_TIERS) + 1]
    md.TMScratchDelay = 3 + ZombRand(8)          -- 3-10 seconds, fixed for this CD
    md.TMScratchSafeRoll = ZombRand(1000) / 1000 -- picks the safe track on 50% CDs
    if TCMusic and TCMusic.applyScratchLabel then
        TCMusic.applyScratchLabel(item)
    end
    dlog("Scratched CD " .. tostring(item:getFullType()) .. " tier=" .. tostring(md.TMScratch))
end

-- CDs inside a CD storage case are protected and never scratched.
local function isCDCaseContainer(container)
    if not container then return false end
    local holder = container:getContainingItem()
    if not holder then return false end
    local t = string.lower(holder:getType() or "")
    if string.find(t, "cdcase", 1, true) or string.find(t, "cdbag", 1, true)
        or string.find(t, "cdcarryingcase", 1, true) then
        return true
    end
    -- Generic "cd ... case/bag" item types from packs.
    if string.find(t, "cd", 1, true) and (string.find(t, "case", 1, true) or string.find(t, "bag", 1, true)) then
        return true
    end
    return false
end

local function stampContainerCDScratches(container)
    local items = rmCompatGetItems(container)
    if not items then return end
    if isCDCaseContainer(container) then return end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and isManagedMediaItem(it) and getMediaCategory(it:getFullType()) == "cd" then
            stampScratchOnCD(it)
        end
    end
end

local function onFillContainer(roomName, containerType, container)
    -- Ignore the B42 ItemPickerContainer event variant; it is not an inventory.
    if not rmCompatGetItems(container) then return end

    trimContainerMedia(container)
    stampContainerCDScratches(container)
    -- Stamp freshly-filled containers with the current loot version so the
    -- mid-save sprinkler never touches them.
    local ok = pcall(function()
        local parent = container.getParent and container:getParent() or nil
        if parent and parent.getModData then
            parent:getModData().TMLootV = TCLootControl and TCLootControl.currentVersion or 0
        end
    end)
    if not ok then dlog("stamp on fill failed") end
end

Events.OnFillContainer.Add(onFillContainer)

------------------------------------------------------------
-- 2) Mid-save new pack loot (LoadGridsquare)
------------------------------------------------------------
TCLootControl = TCLootControl or {}
TCLootControl.currentVersion = 0
TCLootControl.newItemsByVersion = {}   -- { [version] = { fullType, ... } }
TCLootControl.initialized = false

-- Containers we consider reasonable homes for music media.
local SPRINKLE_CONTAINER_TYPES = {
    shelves = true, metal_shelves = true, crate = true, counter = true,
    wardrobe = true, dresser = true, desk = true, sidetable = true,
    filingcabinet = true, officedrawers = true, locker = true,
    displaycase = true, shelvesmag = true, dresserdrawer = true,
}

local function collectKnownMediaFullTypes()
    local found = {}
    -- TrueMoozic's own media + everything from any loaded mod, via script scan.
    local allItems = getAllItems and getAllItems() or nil
    if allItems then
        for i = 0, allItems:size() - 1 do
            local script = allItems:get(i)
            if script then
                local fullType = script:getFullName()
                if type(fullType) == "string" then
                    local module = string.match(fullType, "^([^%.]+)%.")
                    if module and module ~= "Base" and getMediaCategory(fullType) then
                        found[fullType] = true
                    end
                end
            end
        end
    end
    return found
end

local function initMidSaveLoot()
    if TCLootControl.initialized then return end
    TCLootControl.initialized = true

    local store = ModData.getOrCreate("TMLootControl")
    store.mediaVersions = store.mediaVersions or {}
    store.version = store.version or 0

    local known = collectKnownMediaFullTypes()

    -- Find media types never seen by this save before.
    local newTypes = {}
    for fullType in pairs(known) do
        if store.mediaVersions[fullType] == nil then
            table.insert(newTypes, fullType)
        end
    end

    if #newTypes > 0 then
        store.version = store.version + 1
        for _, fullType in ipairs(newTypes) do
            store.mediaVersions[fullType] = store.version
        end
        dlog("Registered " .. #newTypes .. " new media type(s) as loot version " .. store.version)
    end

    TCLootControl.currentVersion = store.version

    -- Build version -> item list index for the sprinkler.
    TCLootControl.newItemsByVersion = {}
    for fullType, v in pairs(store.mediaVersions) do
        TCLootControl.newItemsByVersion[v] = TCLootControl.newItemsByVersion[v] or {}
        table.insert(TCLootControl.newItemsByVersion[v], fullType)
    end
end

local function pickSprinkleCandidates(sinceVersion)
    local out = {}
    for v, list in pairs(TCLootControl.newItemsByVersion) do
        if v > sinceVersion then
            for _, fullType in ipairs(list) do
                table.insert(out, fullType)
            end
        end
    end
    return out
end

local function countCategoryInContainer(container, cat)
    local n = 0
    local items = container:getItems()
    if not items then return 0 end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and isManagedMediaItem(it) and getMediaCategory(it:getFullType()) == cat then
            n = n + 1
        end
    end
    return n
end

local function sprinkleContainer(obj, container)
    local md = obj:getModData()
    local stamp = tonumber(md.TMLootV) or 0
    if stamp >= TCLootControl.currentVersion then return end

    -- Mark handled regardless of the roll below: each container gets ONE shot
    -- per loot version so re-loading squares doesn't re-roll.
    md.TMLootV = TCLootControl.currentVersion

    local candidates = pickSprinkleCandidates(stamp)
    if #candidates == 0 then return end

    -- "0 most of the time": 25% of eligible containers get anything at all.
    if ZombRand(100) >= 25 then return end

    local cap = TCMusicSandbox.GetMaxMediaPerContainer and TCMusicSandbox.GetMaxMediaPerContainer() or 5
    if cap <= 0 then cap = 5 end

    local toAdd = 1 + ZombRand(2) -- 1-2 items
    for _ = 1, toAdd do
        local fullType = candidates[ZombRand(#candidates) + 1]
        local cat = getMediaCategory(fullType)
        if cat and countCategoryInContainer(container, cat) < cap then
            local item = instanceItem(fullType)
            if item then
                container:AddItem(item)
                if cat == "cd" then
                    stampScratchOnCD(item)
                end
                dlog("Sprinkled " .. fullType .. " into container")
            end
        end
    end
    container:setDrawDirty(true)
end

local function onLoadGridsquare(square)
    if not TCLootControl.initialized then return end
    if TCLootControl.currentVersion <= 0 then return end
    if not (TCMusicSandbox.IsMidSaveLootEnabled and TCMusicSandbox.IsMidSaveLootEnabled()) then return end
    if not square or not square.getObjects then return end

    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        local container = obj and obj.getContainer and obj:getContainer() or nil
        if container and container.getType then
            local cType = container:getType()
            if cType and SPRINKLE_CONTAINER_TYPES[cType] then
                -- Only touch containers that already generated their loot:
                -- previously stamped, or holding at least one item. Freshly
                -- generated (pre-fill, empty) containers are handled+stamped
                -- by OnFillContainer instead.
                local hasStamp = obj:getModData().TMLootV ~= nil
                local hasItems = container.getItems and container:getItems() and container:getItems():size() > 0
                if hasStamp or hasItems then
                    local okS, err = pcall(sprinkleContainer, obj, container)
                    if not okS then dlog("sprinkle failed: " .. tostring(err)) end
                end
            end
        end
    end
end

local function onBootInit()
    initMidSaveLoot()
end

Events.OnInitGlobalModData.Add(function()
    -- ModData is available here; item scripts are too (OnInitGlobalModData runs late in boot).
    onBootInit()
end)
if Events.OnServerStarted then
    Events.OnServerStarted.Add(onBootInit)
end
Events.OnGameStart.Add(onBootInit)

Events.LoadGridsquare.Add(onLoadGridsquare)
