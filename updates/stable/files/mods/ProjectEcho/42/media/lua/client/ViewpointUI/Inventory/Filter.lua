--
-- Viewpoint UI - inventory search, category chips and sorting.
--
-- Categories come from the item itself: its class (HandWeapon, Food, Clothing,
-- InventoryContainer) and the display category set in the item scripts
-- (InventoryItem:getDisplayCategory(), the same value the vanilla pane shows as
-- IGUI_ItemCat_<category>). Modded items that set a display category sort
-- themselves into the right chip.
--

require "ViewpointUI/Core"
require "ViewpointUI/Inventory/Model"

local VPUI = ViewpointUI
VPUI.Inventory = VPUI.Inventory or {}
if VPUI.Inventory.Filter then return end

local Filter = {}
VPUI.Inventory.Filter = Filter

local Model = VPUI.Inventory.Model

local function category(item)
    local ok, cat = pcall(function() return item:getDisplayCategory() end)
    if ok and cat then return tostring(cat) end
    ok, cat = pcall(function() return item:getCategory() end)
    if ok and cat then return tostring(cat) end
    return ""
end
Filter.category = category

local function is(item, class)
    local ok, v = pcall(instanceof, item, class)
    return ok and v == true
end

local function has(cat, ...)
    for _, c in ipairs({ ... }) do
        if cat == c then return true end
    end
    return false
end

-- id, label key (VPUI.Text), test(item, cat)
Filter.chips = {
    { id = "all",      text = "chipAll",      test = function() return true end },
    { id = "weapons",  text = "chipWeapons",  test = function(item, cat)
        return (is(item, "HandWeapon") and cat ~= "Ammo") or string.find(cat, "Weapon", 1, true) ~= nil end },
    { id = "ammo",     text = "chipAmmo",     test = function(item, cat) return has(cat, "Ammo", "WeaponPart") end },
    { id = "food",     text = "chipFood",     test = function(item, cat) return is(item, "Food") or has(cat, "Food", "Water", "Cooking") end },
    { id = "medical",  text = "chipMedical",  test = function(item, cat) return has(cat, "FirstAid", "Bandage", "FirstAidWeapon") end },
    { id = "clothing", text = "chipClothing", test = function(item, cat)
        return (is(item, "Clothing") and not is(item, "InventoryContainer")) or has(cat, "Clothing", "Accessory", "ProtectiveGear") end },
    { id = "bags",     text = "chipBags",     test = function(item, cat) return is(item, "InventoryContainer") or has(cat, "Bag", "Container") end },
    { id = "tools",    text = "chipTools",    test = function(item, cat)
        return has(cat, "Tool", "ToolWeapon", "Material", "VehicleMaintenance", "Electronics", "Household", "Gardening", "Fishing", "Trapping", "Camping", "LightSource", "FireSource") end },
}

local byId = {}
for _, c in ipairs(Filter.chips) do byId[c.id] = c end

-- Does a grouped row pass the search text and the chip?
function Filter.match(group, search, chipId)
    local item = group.first
    if not item then return true end
    if search and search ~= "" then
        local name = string.lower(group.name or "")
        if not string.find(name, search, 1, true) then
            local cat = string.lower(category(item))
            if not string.find(cat, search, 1, true) then return false end
        end
    end
    local chip = byId[chipId or "all"]
    if chip and chip.id ~= "all" then
        return chip.test(item, category(item)) == true
    end
    return true
end

Filter.sorts = { "name", "weight", "type", "condition" }

local function cond(g)
    local v = Model.barOf(g.first)
    if v == nil then return 2 end
    return v
end

-- Sorts grouped rows in place. Equipped and favourite items stay first.
function Filter.sort(groups, mode)
    table.sort(groups, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped end
        if a.favorite ~= b.favorite then return a.favorite end
        if mode == "weight" then
            if a.weight ~= b.weight then return a.weight > b.weight end
        elseif mode == "type" then
            local ca, cb = a.cat or "", b.cat or ""
            if ca ~= cb then return ca < cb end
        elseif mode == "condition" then
            local va, vb = cond(a), cond(b)
            if va ~= vb then return va < vb end
        end
        return (a.name or "") < (b.name or "")
    end)
end
