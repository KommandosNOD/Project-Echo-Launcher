--
-- Viewpoint UI - gear slots (the Tarkov-style equipment layout).
--
-- Project Zomboid has ~120 body locations (ItemBodyLocation, registered in
-- shared/NPCs/BodyLocations.lua), far too many to show one slot each. They are
-- grouped into the slots a player thinks in - head, eyes, face, jacket, vest,
-- back, belt, hands, pants, feet... A slot shows what is worn at any of its
-- locations (several items: the outermost first, with a "+n" badge). Anything
-- worn at a location no group lists (modded locations too) lands in "Other",
-- so nothing worn is ever hidden.
--
-- Location ids are compared normalised (lower case, no namespace, no "_"):
-- "base:Jacket_Bulky" -> "jacketbulky". The ids come from ItemBodyLocation's
-- registered names (AmmoStrap ... ZedDmg in the game's classes).
--
-- Hands come from getPrimaryHandItem / getSecondaryHandItem; hotbar
-- attachments (belt, holster, back sheath...) from the game's ISHotbar.
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.Inventory = VPUI.Inventory or {}
if VPUI.Inventory.Gear then return end

local Gear = {}
VPUI.Inventory.Gear = Gear

-- id, label, locations (normalised). Order = layout order (4 per row).
Gear.slots = {
    { id = "head",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_001"),    locs = { "hat", "fullhat", "jackethat", "jackethatbulky", "sweaterhat", "fullsuithead", "fullsuitheadscba" } },
    { id = "eyes",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_002"),    locs = { "eyes", "lefteye", "righteye" } },
    { id = "face",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_003"),    locs = { "mask", "maskeyes", "maskfull", "scba", "scbanotank" } },
    { id = "neck",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_004"),    locs = { "neck", "necktexture", "necklace", "necklacelong", "scarf", "gorget" } },

    { id = "outer",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_005"),   locs = { "tail", "fullrobe", "bathrobe", "boilersuit", "fullsuit", "dress", "longdress", "bodycostume" } },
    { id = "jacket",  label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_006"),  locs = { "jacket", "jacketbulky", "jacketdown", "jacketsuit" } },
    { id = "vest",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_007"),    locs = { "torsoextravest", "torsoextravestbullet", "torsoextra", "webbing", "cuirass", "vesttexture" } },
    { id = "top",     label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_008"),     locs = { "sweater", "jersey", "fulltop", "shirt", "shortsleeveshirt" } },

    { id = "under",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_009"),    locs = { "tshirt", "tanktop", "torso1", "torso1legs1", "underweartop", "underwear", "underwearbottom", "underwearextra1", "underwearextra2" } },
    { id = "back",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_010"),    locs = { "back" } },
    { id = "bag",     label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_011"),     locs = { "satchel", "fannypackfront", "fannypackback" } },
    { id = "belt",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_012"),    locs = { "belt", "beltextra", "ammostrap", "shoulderholster", "ankleholster" } },

    { id = "hands",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_013"),  locs = { "hands", "handsleft", "handsright" } },
    { id = "legs",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_014"),    locs = { "pants", "pantsskinny", "pantsextra", "shortpants", "shortsshort", "legs1", "legs5", "skirt", "longskirt", "codpiece" } },
    { id = "socks",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_015"),   locs = { "socks" } },
    { id = "feet",    label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_016"),    locs = { "shoes" } },

    { id = "armor",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_017"),    locs = { "shoulderpadleft", "shoulderpadright", "sportshoulderpad", "sportshoulderpadontop",
                                                  "elbowleft", "elbowright", "forearmleft", "forearmright", "kneeleft", "kneeright",
                                                  "thighleft", "thighright", "calfleft", "calfright", "calflefttexture", "calfrighttexture",
                                                  "gaiterleft", "gaiterright", "leftarm", "rightarm" } },
    { id = "wrist",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_018"),  locs = { "leftwrist", "rightwrist", "leftmiddlefinger", "rightmiddlefinger", "leftringfinger", "rightringfinger" } },
    { id = "other",   label = getText("UI_ProjectEcho_VPUI_Inventory_Gear_RU_019"),   locs = {} },   -- everything not listed above
}

-- Faded picture in an empty slot (DayZ-style): the icon of a vanilla item that
-- goes there. Icon names are the items' own (Icon = ... in
-- media/scripts/generated/items), and every "Item_<name>" texture was found in
-- the game's texture packs (UI.pack / UI2.pack).
Gear.placeholderIcons = {
    head = "HelmetArmyGreen", eyes = "GlassesBlack", face = "GasMask", neck = "ScarfGeneric",
    outer = "BoilerSuitWhite", jacket = "JacketPadded_White", vest = "BulletVestPolice", top = "ShirtGeneric",
    under = "TshirtGeneric", back = "AliceBag", bag = "FannyPack", belt = "Belt",
    hands = "GlovesLeatherBlackpng", legs = "TrousersDenimBlue", socks = "SocksAnkleWhite", feet = "BootsARmy",
    armor = "KneePad_Black", wrist = "DigitalWatch_Black",
}
-- hotbar attachment slots, by the slot type prefix (ISHotbarAttachDefinition)
Gear.attachPlaceholderIcons = {
    { prefix = "SmallBelt", icon = "HuntingKnife" },
    { prefix = "Holster", icon = "HandGun3" },
    { prefix = "Back", icon = "Firearm_PumpShotgun" },
    { prefix = "Bag", icon = "Firearm_PumpShotgun" },
    { prefix = "Bedroll", icon = "Sleepingbag2_Rolled" },
    { prefix = "Webbing", icon = "HuntingKnife" },
}

local texCache = {}

local function iconTexture(name)
    if not name then return nil end
    local hit = texCache[name]
    if hit ~= nil then return hit or nil end
    local ok, tex = pcall(getTexture, "Item_" .. name)
    texCache[name] = (ok and tex) or false
    return (ok and tex) or nil
end

-- The texture drawn faded in an empty cell, or nil (then its name shows).
function Gear.placeholder(cell)
    if not cell then return nil end
    if cell.kind == "wear" then return iconTexture(Gear.placeholderIcons[cell.slot]) end
    if cell.kind == "attach" and cell.entry and cell.entry.slot then
        local t = tostring(cell.entry.slot.slotType or "")
        for _, p in ipairs(Gear.attachPlaceholderIcons) do
            if string.sub(t, 1, #p.prefix) == p.prefix then return iconTexture(p.icon) end
        end
    end
    return nil
end

-- never shown: bandages and wounds are the health tab's, ZedDmg is cosmetic
Gear.hidden = { bandage = true, wound = true, zeddmg = true }

local byLoc = {}
local byId = {}
for _, slot in ipairs(Gear.slots) do
    byId[slot.id] = slot
    for _, loc in ipairs(slot.locs) do byLoc[loc] = slot.id end
end

-- "base:Jacket_Bulky" -> "jacketbulky"
function Gear.norm(location)
    if location == nil then return nil end
    local s = string.lower(tostring(location))
    local colon = string.find(s, ":", 1, true)
    if colon then s = string.sub(s, colon + 1) end
    s = string.gsub(s, "[_%s%-]", "")
    if s == "" or s == "nil" then return nil end
    return s
end

function Gear.slotForLocation(location)
    local n = Gear.norm(location)
    if not n or Gear.hidden[n] or string.sub(n, 1, 6) == "makeup" then return nil end
    return byLoc[n] or "other"
end

function Gear.slot(id)
    return byId[id]
end

-- The slot an item would go to if worn (nil when it cannot be worn).
function Gear.slotForItem(item)
    if not item then return nil end
    local loc = nil
    local ok, v = pcall(function() return item:getBodyLocation() end)
    if ok and v ~= nil then loc = v end
    if not loc then
        ok, v = pcall(function() return item:canBeEquipped() end)
        if ok and v ~= nil then loc = v end
    end
    if not loc then return nil end
    return Gear.slotForLocation(loc)
end

-- slot id -> list of worn items (outermost first: the game stores worn items in
-- render order, inner layers first, so the list is reversed)
function Gear.worn(player)
    local out = {}
    local worn = player and player:getWornItems()
    if not worn then return out end
    for i = worn:size() - 1, 0, -1 do
        local wi = worn:get(i)
        local item = wi and wi:getItem()
        if item then
            local id = Gear.slotForLocation(wi:getLocation())
            if id then
                out[id] = out[id] or {}
                table.insert(out[id], item)
            end
        end
    end
    return out
end

-- The game's hotbar slots: { index, name, item, slot } (slot = ISHotbar's entry)
function Gear.attachments(player)
    local out = {}
    local bar = player and getPlayerHotbar(player:getPlayerNum())
    if not bar or not bar.availableSlot then return out, nil end
    local i = 1
    while bar.availableSlot[i] do
        local slot = bar.availableSlot[i]
        local name = getTextOrNull("IGUI_HotbarAttachment_" .. tostring(slot.slotType)) or slot.name or tostring(slot.slotType)
        table.insert(out, { index = i, name = name, item = bar.attachedItems and bar.attachedItems[i] or nil, slot = slot })
        i = i + 1
    end
    return out, bar
end

-- Can `item` go into hotbar slot `entry` (ISHotbar:canBeAttached)?
function Gear.canAttach(bar, entry, item)
    if not bar or not entry or not item then return false end
    local ok, v = pcall(bar.canBeAttached, bar, entry.slot, item)
    return ok and v == true
end

-- Attach the way ISHotbar:onMouseUp does for a dropped item.
function Gear.attach(bar, entry, item)
    if not Gear.canAttach(bar, entry, item) then return false end
    local def = entry.slot.def
    if VPUI.Inventory.Actions and VPUI.Inventory.Actions.note then VPUI.Inventory.Actions.note("attach to " .. tostring(entry.slot.slotType), { item }) end
    local ok, err = pcall(bar.attachItem, bar, item, def.attachments[item:getAttachmentType()], entry.index, def, true)
    if not ok then VPUI.Log.error("attach failed: " .. tostring(err)) end
    return ok
end

-- Moves hotbar slot `from` to position `to` (the slots in between shift by
-- one), so its item answers another Hotbar key. Done the way ISHotbar:refresh
-- re-orders slots after a clothing change: the availableSlot table rebuilt,
-- each attached item re-attached without animation at its slot's new index
-- (removeItem(item, false) + attachItem(..., false)), savePosition() (player
-- modData "hotbar", transmitted in multiplayer) and reloadIcons().
function Gear.moveSlot(bar, from, to)
    if not bar or not bar.availableSlot or from == to then return false end
    local n = 0
    while bar.availableSlot[n + 1] do n = n + 1 end
    if from < 1 or from > n or to < 1 or to > n then return false end
    local chr = bar.chr
    local ok, err = pcall(function()
        -- what is attached where, by slot entry
        local attached = {}
        for i = 1, n do
            local item = bar.attachedItems and bar.attachedItems[i]
            if item then attached[bar.availableSlot[i]] = item end
        end
        local order = {}
        for i = 1, n do order[i] = bar.availableSlot[i] end
        local moved = table.remove(order, from)
        table.insert(order, to, moved)
        for _, item in pairs(attached) do bar:removeItem(item, false) end
        for i = 1, n do bar.availableSlot[i] = order[i] end
        for i = 1, n do
            local slot = bar.availableSlot[i]
            local item = attached[slot]
            if item and chr:getInventory():contains(item) and not item:isBroken() then
                bar:attachItem(item, slot.def.attachments[item:getAttachmentType()], i, slot.def, false)
            end
        end
        bar:savePosition()
        bar:reloadIcons()
    end)
    if not ok then VPUI.Log.error("hotbar reorder failed: " .. tostring(err)) end
    return ok
end

-- Detach with the animation (ISHotbar:removeItem(item, true)).
function Gear.detach(bar, item)
    if not bar or not item then return end
    if VPUI.Inventory.Actions and VPUI.Inventory.Actions.note then VPUI.Inventory.Actions.note("detach", { item }) end
    local ok, err = pcall(bar.removeItem, bar, item, true)
    if not ok then VPUI.Log.error("detach failed: " .. tostring(err)) end
end
