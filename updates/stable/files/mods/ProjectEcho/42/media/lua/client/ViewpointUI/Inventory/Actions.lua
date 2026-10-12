--
-- Viewpoint UI - inventory actions. Every change to items goes through the game's
-- own timed actions and helpers (the same calls the vanilla inventory panes and
-- context menu make), so the server validates and synchronises them in
-- multiplayer and nothing is moved client-side.
--

require "ViewpointUI/Core"
require "ViewpointUI/Util/Harvest"

local VPUI = ViewpointUI
VPUI.Inventory = VPUI.Inventory or {}
if VPUI.Inventory.Actions then return end

local Actions = {}
VPUI.Inventory.Actions = Actions

local Log = VPUI.Log
local Harvest = VPUI.Util.Harvest

local function guarded(name, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then Log.error(name .. " failed: " .. tostring(err)) end
    return ok
end

-- One console line per item request (Console log: Info), so a report of an
-- item lost or doubled can be matched to exactly what was asked of the game.
local function where(c)
    if not c then return "nil" end
    local ok, t = pcall(function() return c:getType() end)
    return ok and tostring(t) or "?"
end
local function itemText(item)
    local ok, t = pcall(function()
        return tostring(item:getFullType()) .. "#" .. tostring(item:getID()) .. " in " .. where(item:getContainer())
    end)
    return ok and t or tostring(item)
end
Actions.itemText = itemText
local function note(what, items, extra)
    if VPUI.Log.level < VPUI.Log.INFO then return end
    local parts = {}
    for i, it in ipairs(items) do
        if i > 6 then table.insert(parts, "+" .. tostring(#items - 6) .. " more") break end
        table.insert(parts, itemText(it))
    end
    VPUI.Log.info("item request: " .. what .. " " .. table.concat(parts, ", ") .. (extra and (" " .. extra) or ""))
end
Actions.note = note

local function isFloor(container)
    return container ~= nil and container:getType() == "floor"
end
Actions.isFloor = isFloor

-- Moves items into dest (a container, or the floor container to drop them).
-- Walks to the world container involved first, unequips what is worn or held,
-- and queues one transfer per item, like ISInventoryPaneContextMenu.onMoveItemsTo
-- (which only walks to the destination; taking from a world container needs the
-- walk to the source).
function Actions.move(player, items, dest)
    if not player or not dest or #items == 0 then return end
    note("move", items, "-> " .. where(dest))
    local pn = player:getPlayerNum()
    if isFloor(dest) then
        guarded("drop", ISInventoryPaneContextMenu.onDropItems, items, pn)
        return
    end
    local src = items[1]:getContainer()
    local world = dest
    if src and not src:isInCharacterInventory(player) and not isFloor(src) then world = src end
    if not luautils.walkToContainer(world, pn) then return end
    for _, item in ipairs(items) do
        if item:getContainer() ~= dest and dest:isItemAllowed(item) then
            if corpseStorageCheck and corpseStorageCheck.isPlayerGrabbingCorpseItem
                    and corpseStorageCheck.isPlayerGrabbingCorpseItem(pn, item, dest) then
                if not player:getVehicle() then ISTimedActionQueue.add(ISGrabCorpseItem:new(player, item)) end
                break
            end
            if player:isEquipped(item) then
                ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
            end
            ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(player, item, item:getContainer(), dest))
        end
    end
end

-- Takes everything from a world container, the vanilla "Loot all" way
-- (ISInventoryPane:lootAll): unwanted items stay, a heavy item (corpse,
-- generator) is picked up into the hands instead.
function Actions.takeAll(player, container)
    if not player or not container then return end
    VPUI.Log.info("item request: take all from " .. where(container) .. " (" .. tostring(container:getItems():size()) .. " items)")
    local pn = player:getPlayerNum()
    if not luautils.walkToContainer(container, pn) then return end
    local list, heavy = {}, nil
    local it = container:getItems()
    for i = 0, it:size() - 1 do
        local item = it:get(i)
        if not item:isUnwanted(player) then
            if isForceDropHeavyItem(item) then heavy = item else table.insert(list, item) end
        end
    end
    if #list == 0 then
        if heavy then guarded("equip heavy", ISInventoryPaneContextMenu.equipHeavyItem, player, heavy) end
        return
    end
    local pane = getPlayerLoot(pn).inventoryPane
    guarded("take all", pane.transferItemsByWeight, pane, list, getPlayerInventory(pn).inventory)
end

-- Puts every unequipped, non-favourite, non-hotbar item of the main inventory
-- into dest, like ISInventoryPane:transferAll.
function Actions.storeAll(player, dest)
    local pn = player:getPlayerNum()
    local hotbar = getPlayerHotbar(pn)
    local items = {}
    local it = player:getInventory():getItems()
    for i = 0, it:size() - 1 do
        local item = it:get(i)
        -- same test as ISInventoryPane:transferAll
        local keyRing = item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING)
        if not item:isEquipped() and not keyRing and not (hotbar and hotbar:isInHotbar(item))
                and not item:isFavorite() and not item:isHidden() then
            table.insert(items, item)
        end
    end
    Actions.move(player, items, dest)
end

-- Fills dest with the loose items of the main inventory that are already in
-- it (same full type): ammo with ammo, cans with cans. Same exclusions as
-- storeAll (equipped, favourites, hotbar, key rings).
function Actions.storeMatching(player, dest)
    if not player or not dest then return 0 end
    local want = {}
    local di = dest:getItems()
    for i = 0, di:size() - 1 do want[di:get(i):getFullType()] = true end
    local pn = player:getPlayerNum()
    local hotbar = getPlayerHotbar(pn)
    local items = {}
    local it = player:getInventory():getItems()
    for i = 0, it:size() - 1 do
        local item = it:get(i)
        local keyRing = item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING)
        if want[item:getFullType()] and item ~= dest:getContainingItem() and not item:isEquipped() and not keyRing
                and not (hotbar and hotbar:isInHotbar(item)) and not item:isFavorite() and not item:isHidden() then
            table.insert(items, item)
        end
    end
    if #items > 0 then Actions.move(player, items, dest) end
    return #items
end

function Actions.equip(player, item, primary)
    note(primary and "hold (primary)" or "hold (secondary)", { item })
    local twoHands = item:isTwoHandWeapon() and primary
    guarded("equip", ISInventoryPaneContextMenu.equipWeapon, item, primary, twoHands, player:getPlayerNum())
end

function Actions.canWear(item)
    return item:getBodyLocation() ~= nil or item:canBeEquipped() ~= nil
end

function Actions.wear(player, item)
    note("wear", { item })
    guarded("wear", ISInventoryPaneContextMenu.wearItem, item, player:getPlayerNum())
end

function Actions.unequip(player, item)
    note("take off", { item })
    guarded("unequip", ISInventoryPaneContextMenu.unequipItem, item, player:getPlayerNum())
end

function Actions.toggleFavorite(items)
    local fav = not items[1]:isFavorite()
    for _, item in ipairs(items) do item:setFavorite(fav, true) end
end

-- The game's full item context menu for these items, harvested (every vanilla
-- and modded item action: eat, read, reload, attach to hotbar, craft from it...).
-- Returns { label, enabled, run } entries; empty while the game is paused (the
-- game itself builds no item menu then).
function Actions.itemMenu(player, items, inPlayerInventory)
    local pn = player:getPlayerNum()
    return Harvest.run(pn, function()
        return ISInventoryPaneContextMenu.createMenu(pn, inPlayerInventory, items, 0, 0)
    end)
end

-- Picking up one item lying in the world (the IsoWorldInventoryObject Viewpoint
-- aims at), the way ISWorldObjectContextMenu.onGrabWItem does.
function Actions.grabWorldItem(player, worldItem)
    if not worldItem or not worldItem:getItem() then return end
    local item = worldItem:getItem()
    note("pick up", { item })
    if isForceDropHeavyItem(item) then
        ISInventoryPaneContextMenu.equipHeavyItem(player, item)
        return
    end
    guarded("pick up", ISWorldObjectContextMenu.onGrabWItem, nil, worldItem, player:getPlayerNum())
end

---------------------------------------------------------------------------
-- Menu grouping
--
-- The harvested item menu can run to thirty entries. They are sorted into
-- Use / Equip / Craft / Move / Other by the game function each entry calls
-- (its name in ISInventoryPaneContextMenu, ISInventoryMenuElements, ISHotbar...,
-- so it does not depend on the language), entries the game marks unavailable
-- go to the end of their group, and the action last used on that item type
-- comes first.
---------------------------------------------------------------------------

local fnNames = nil

local function scan(tbl, depth)
    if type(tbl) ~= "table" or depth > 2 then return end
    for k, v in pairs(tbl) do
        if type(v) == "function" and type(k) == "string" then
            if fnNames[v] == nil then fnNames[v] = string.lower(k) end
        elseif type(v) == "table" and type(k) == "string" and depth < 2 then
            scan(v, depth + 1)
        end
    end
end

local function buildNames()
    fnNames = {}
    for _, name in ipairs({ "ISInventoryPaneContextMenu", "ISInventoryMenuElements", "ISHotbar",
                            "ISWorldObjectContextMenu", "ISCraftingUI", "ISRecipeTooltip" }) do
        local t = _G[name]
        if type(t) == "table" then pcall(scan, t, 1) end
    end
end

Actions.groups = {
    { id = "use",   text = "menuUse",   words = { "eat", "drink", "read", "literature", "pill", "bandage", "apply", "makeup",
        "activate", "dry", "wring", "reload", "magazine", "bullet", "rack", "eject", "insert", "firemode", "alarm", "timer",
        "remote", "dye", "lure", "hook", "line", "media", "map", "write", "rename", "transferwater", "empty", "dump",
        "extinguish", "light", "smoke", "consolidate", "fluid", "fill", "pour", "turn", "play", "listen", "use" } },
    { id = "equip", text = "menuEquip", words = { "equip", "wear", "unequip", "primaryweapon", "secondweapon", "twohands",
        "attach", "hotbar", "clothingitemextra", "puton", "takeoff", "heavy" } },
    { id = "craft", text = "menuCraft", words = { "craft", "recipe", "research", "upgrade", "patch", "repair", "rip",
        "disassemble", "scrap", "build", "fix", "evo" } },
    { id = "move",  text = "menuMove",  words = { "drop", "grab", "move", "transfer", "place", "favorite", "wanted", "put" } },
}

local function groupOf(fn)
    if not fnNames then buildNames() end
    local name = fnNames[fn]
    if not name then return "other" end
    for _, g in ipairs(Actions.groups) do
        for _, w in ipairs(g.words) do
            if string.find(name, w, 1, true) then return g.id end
        end
    end
    return "other"
end
Actions.groupOf = groupOf

Actions.lastUsed = {}   -- item full type -> label of the action last run from its menu

-- entries: harvested { label, enabled, run, fn } ; returns the menu list with
-- { header = true, label } separators.
function Actions.groupMenu(entries, item)
    local Text = VPUI.Text
    local buckets = { use = {}, equip = {}, craft = {}, move = {}, other = {} }
    local fullType = item and item:getFullType() or nil
    local last = fullType and Actions.lastUsed[fullType] or nil
    local recent = nil
    for _, e in ipairs(entries) do
        -- remember what gets used, per item type
        local run = e.run
        local label = e.label
        e.run = function()
            if fullType then Actions.lastUsed[fullType] = label end
            return run()
        end
        if last and label == last and e.enabled ~= false and not recent then
            recent = e
        else
            table.insert(buckets[groupOf(e.fn)] or buckets.other, e)
        end
    end
    local out = {}
    if recent then
        recent.recent = true
        table.insert(out, recent)
    end
    local order = { "use", "equip", "craft", "move", "other" }
    local names = { use = Text.menuUse, equip = Text.menuEquip, craft = Text.menuCraft, move = Text.menuMove, other = Text.menuOther }
    for _, id in ipairs(order) do
        local list = buckets[id]
        if #list > 0 then
            -- what can be done first, the rest greyed out after it
            local ok, no = {}, {}
            for _, e in ipairs(list) do
                if e.enabled ~= false then table.insert(ok, e) else table.insert(no, e) end
            end
            table.insert(out, { header = true, label = names[id], enabled = false })
            for _, e in ipairs(ok) do table.insert(out, e) end
            for _, e in ipairs(no) do table.insert(out, e) end
        end
    end
    return out
end
