--
-- Viewpoint UI - inventory model.
--
-- The list of containers comes from the game's own inventory and loot pages
-- (ISInventoryPage:refreshBackpacks): that is where the game decides which bags
-- count as worn, which nearby containers the player can reach (line of reach,
-- safehouse loot rules, locked containers, vehicle part access, the 3x3 floor),
-- and it fills unexplored containers through the server. Reusing it keeps the
-- rules identical to vanilla and to mods that hook OnRefreshInventoryWindowContainers.
-- The pages stay hidden; only their data is read.
--
-- Items are grouped the way the vanilla pane groups them (same type and name),
-- and rebuilt only when a container reports a change, not every frame.
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.Inventory = VPUI.Inventory or {}
if VPUI.Inventory.Model then return end

local Model = {}
VPUI.Inventory.Model = Model

local Log = VPUI.Log

-- Containers from a vanilla page. Each: { container, title, icon, capacity, floor, depth }
local function fromPage(page, player, refresh)
    local out = {}
    if not page then return out end
    if refresh then
        local ok, err = pcall(page.refreshBackpacks, page)
        if not ok then Log.error("refreshBackpacks failed: " .. tostring(err)) end
    end
    for _, button in ipairs(page.backpacks or {}) do
        local container = button.inventory
        if container then
            local depth = 0
            local holder = container:getContainingItem()
            local guard = 0
            while holder and guard < 6 do
                depth = depth + 1
                local parent = holder:getContainer()
                holder = parent and parent:getContainingItem() or nil
                guard = guard + 1
            end
            table.insert(out, {
                container = container,
                title = button.name or container:getType(),
                icon = button.image,
                capacity = button.capacity or container:getEffectiveCapacity(player),
                floor = container:getType() == "floor",
                depth = depth,
            })
        end
    end
    return out
end

function Model.playerContainers(player, refresh)
    local list = fromPage(getPlayerInventory(player:getPlayerNum()), player, refresh)
    if #list > 0 then
        -- the main inventory's real limit is the character's carry weight
        list[1].capacity = player:getMaxWeight()
    end
    return list
end

function Model.lootContainers(player, refresh)
    return fromPage(getPlayerLoot(player:getPlayerNum()), player, refresh)
end

-- What keeps two items of the same type apart: a different condition (a
-- worn knife does not hide among new ones) and, for magazines and other
-- items that hold rounds, a different count (loaded and empty magazines are
-- separate lines).
local function stateKey(item)
    local parts = ""
    local ok, max = pcall(function() return item:getConditionMax() end)
    if ok and type(max) == "number" and max > 0 then
        local okC, c = pcall(function() return item:getCondition() end)
        if okC and c ~= nil and c ~= max then parts = parts .. "|c" .. tostring(c) end
    end
    local okA, maxAmmo = pcall(function() return item:getMaxAmmo() end)
    if okA and type(maxAmmo) == "number" and maxAmmo > 0 then
        local okN, n = pcall(function() return item:getCurrentAmmoCount() end)
        if okN and n ~= nil then parts = parts .. "|a" .. tostring(n) end
    end
    return parts
end
Model.stateKey = stateKey

-- Groups a container's items like the vanilla pane: same full type and name
-- stack, equipped and hotbar items stay separate. hideEquipped leaves out what
-- is held, worn or attached (the gear slots show those).
function Model.groups(container, player, hideEquipped)
    local groups, order = {}, {}
    local items = container:getItems()
    local hotbar = getPlayerHotbar(player:getPlayerNum())
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local preview = VPUI.Building and VPUI.Building.Preview and VPUI.Building.Preview.isPreviewItem(item)
        if not item:isHidden() and not preview then
            local equipped = player:isEquipped(item)
            local inHotbar = hotbar ~= nil and hotbar:isInHotbar(item)
            if hideEquipped and (equipped or inHotbar) then
                -- shown in a gear slot instead
            else
            local name = item:getName()
            local key = (equipped and "equipped:" or (inHotbar and "hotbar:" or "")) .. item:getFullType() .. "|" .. name .. stateKey(item)
            local g = groups[key]
            if not g then
                g = { key = key, items = {}, name = name, first = item, weight = 0, equipped = equipped,
                      hotbar = inHotbar, favorite = false, container = container }
                groups[key] = g
                table.insert(order, g)
            end
            table.insert(g.items, item)
            g.weight = g.weight + item:getUnequippedWeight()
            if item:isFavorite() then g.favorite = true end
            end
        end
    end
    table.sort(order, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped end
        return a.name < b.name
    end)
    return order
end

-- 0..1 fill of a condition or uses bar, or nil when the item has none to show.
function Model.barOf(item)
    if instanceof(item, "HandWeapon") or instanceof(item, "Clothing") then
        local max = item:getConditionMax()
        if max and max > 0 then return item:getCondition() / max end
    elseif instanceof(item, "DrainableComboItem") then
        return item:getCurrentUsesFloat()
    end
    return nil
end

-- Weight shown for a container: what is in it now and its limit.
function Model.weightOf(entry)
    local used = entry.container:getCapacityWeight()
    return used, entry.capacity
end

-- Worn items with their body location, in the order the game stores them.
function Model.worn(player)
    local out = {}
    local worn = player:getWornItems()
    if not worn then return out end
    for i = 0, worn:size() - 1 do
        local wi = worn:get(i)
        local item = wi and wi:getItem()
        if item then
            table.insert(out, { item = item, location = wi:getLocation() })
        end
    end
    return out
end

-- "base:hat" -> "Hat", "base:torso1legs1" -> "Torso1legs1": a readable label from
-- the location id (the game has no translated names for body locations).
function Model.locationLabel(location)
    if not location then return "" end
    local id = tostring(location)
    local colon = string.find(id, ":", 1, true)
    if colon then id = string.sub(id, colon + 1) end
    id = string.gsub(id, "_", " ")
    return string.upper(string.sub(id, 1, 1)) .. string.lower(string.sub(id, 2))
end
