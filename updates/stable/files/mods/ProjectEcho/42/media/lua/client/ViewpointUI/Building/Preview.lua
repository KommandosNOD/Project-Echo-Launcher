--
-- Viewpoint UI - build and place previews.
--
-- What you are about to build or put down is shown on its real square (Java:
-- vpui.Preview), so Viewpoint draws it like the finished thing: in 3D where
-- its model packs have the object, otherwise as Viewpoint draws that tile,
-- standing on the floor or the surface. Only this computer has it; nothing is
-- sent to the server, and it goes away when you stop, save or die.
--
-- The previews are in the world, so the aim ray hits them. Aim.point treats a
-- hit on a preview as see-through: the point then comes from where the same
-- ray meets the floor (or the preview's surface), which does not depend on the
-- preview, so it cannot push itself away.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.Building = VPUI.Building or {}
if VPUI.Building.Preview then return end

local Preview = {}
VPUI.Building.Preview = Preview

local Log = VPUI.Log
local Bridge = VPUI.Bridge

local function native(name)
    local n = VPUI.Native
    return n and n[name] or nil
end

local function callNative(name, ...)
    local fn = native(name)
    if not fn then return nil end
    local ok, v = pcall(fn, ...)
    if not ok then
        Log.once(Log.WARN, "preview:" .. name, "build/place preview: " .. name .. " failed: " .. tostring(v))
        return nil
    end
    return v
end

function Preview.available()
    return native("previewTileAdd") ~= nil
end

---------------------------------------------------------------------------
-- Tiles (build mode)
---------------------------------------------------------------------------

local tileKey = nil
Preview.tileBoxes = {}   -- { x, y, z, wall } of the tiles shown

-- tiles: list of { x, y, z, sprite, wall }. Rebuilt only when it changes.
function Preview.showTiles(tiles)
    local parts = {}
    for _, t in ipairs(tiles) do
        if t.sprite then table.insert(parts, t.x .. "," .. t.y .. "," .. t.z .. "," .. t.sprite) end
    end
    local key = table.concat(parts, ";")
    if key == tileKey then return end
    callNative("previewTilesClear")
    tileKey = key
    Preview.tileBoxes = {}
    if key == "" then return end
    local cell = getCell()
    local base = nil
    for _, t in ipairs(tiles) do
        if t.sprite and (not base or t.z < base) then base = t.z end
    end
    for _, t in ipairs(tiles) do
        if t.sprite then
            local sq = cell:getGridSquare(t.x, t.y, t.z)
            if sq == nil and getWorld():isValidSquare(t.x, t.y, t.z) then
                sq = cell:createNewGridSquare(t.x, t.y, t.z, true)
            end
            if sq and callNative("previewTileAdd", sq, t.sprite) == true then
                table.insert(Preview.tileBoxes, { x = t.x, y = t.y, z = t.z, base = base, wall = t.wall })
            end
        end
    end
end

function Preview.clearTiles()
    if tileKey == nil then return end
    callNative("previewTilesClear")
    tileKey = nil
    Preview.tileBoxes = {}
end

-- Runs fn() with the tile previews out of the world (the game's checks look
-- at the square's objects), then puts them back. Nothing is redrawn.
function Preview.withoutTiles(fn, ...)
    if tileKey == nil then return fn(...) end
    callNative("previewTilesDetach")
    local res = { pcall(fn, ...) }
    callNative("previewTilesAttach")
    if not res[1] then error(res[2], 0) end
    return unpack(res, 2)
end

---------------------------------------------------------------------------
-- Placed item (place mode)
---------------------------------------------------------------------------

local itemState = nil   -- { key, item, worldObject, square, x, y, z (world), top }

-- Items whose drop puts something else in the world (a generator object, a
-- body, a live animal: IsoGridSquare.AddWorldInventoryItem branches off for
-- these) get no preview, only the ring on the floor.
function Preview.canPreviewItem(item)
    local ok, can = pcall(function()
        if instanceof(item, "AnimalInventoryItem") then return false end
        if item:isHumanCorpse() or item:isAnimalCorpse() then return false end
        if item:getType() == "Generator" or item:hasTag(ItemTag.GENERATOR) then return false end
        if string.find(tostring(item:getFullType()), ".Generator", 1, true) then return false end
        return true
    end)
    return ok and can == true
end

local function snap(v, step) return math.floor(v / step + 0.5) * step end

-- Shows a copy of `item` (same type) at square + offsets, turned `rot` degrees.
-- Positions are snapped to 5 cm and 5 degrees, so small mouse moves do not
-- make a new copy every frame.
function Preview.showItem(item, square, xoff, yoff, zoff, rot)
    if not item or not square or not Preview.canPreviewItem(item) then Preview.clearItem() return end
    xoff, yoff, rot = snap(xoff, 0.05), snap(yoff, 0.05), snap(rot, 5)
    local key = tostring(item:getFullType()) .. "|" .. tostring(square) .. "|" ..
        string.format("%.2f|%.2f|%.3f|%d", xoff, yoff, zoff, rot)
    if itemState and itemState.key == key then return end
    Preview.clearItem()
    local ok, err = pcall(function()
        local copy = instanceItem(item:getFullType())
        if not copy then return end
        local placed = square:AddWorldInventoryItem(copy, xoff, yoff, zoff, false)
        if not placed then return end
        local wo = placed:getWorldItem()
        if not wo then return end
        -- tracked first, so nothing below can leave it behind
        if callNative("previewItemSet", wo) ~= true then
            pcall(function() wo:removeFromWorld(); wo:removeFromSquare() end)
            return
        end
        itemState = { key = key, item = placed, worldObject = wo, square = square,
                      x = square:getX() + xoff, y = square:getY() + yoff, z = square:getZ() + zoff }
        placed:setWorldZRotation(rot)
    end)
    if not ok then Log.once(Log.WARN, "previewItem", "place preview failed: " .. tostring(err)) end
end

function Preview.clearItem()
    if not itemState then return end
    callNative("previewItemClear")
    itemState = nil
end

function Preview.itemBox()
    return itemState
end

function Preview.withoutItem(fn, ...)
    if not itemState then return fn(...) end
    callNative("previewItemDetach")
    local res = { pcall(fn, ...) }
    callNative("previewItemAttach")
    if not res[1] then error(res[2], 0) end
    return unpack(res, 2)
end

-- Is `item` (an InventoryItem) or `obj` the place preview? Lists of what lies
-- on the floor leave it out.
function Preview.isPreviewItem(item)
    return itemState ~= nil and item ~= nil and item == itemState.item
end

function Preview.clearAll()
    Preview.clearTiles()
    Preview.clearItem()
    callNative("previewClearAll")
end

---------------------------------------------------------------------------
-- Aim that looks through the previews
---------------------------------------------------------------------------

local Aim = {}
Preview.Aim = Aim

local function hit()
    local hx, hy, hz = Bridge.call("hitX", nil), Bridge.call("hitY", nil), Bridge.call("hitZ", nil)
    if not hx or hx ~= hx or not hy or hy ~= hy or not hz or hz ~= hz then return nil end
    local dx, dy, du = Bridge.call("hitDirX", 0), Bridge.call("hitDirY", 0), Bridge.call("hitDirUp", 0)
    if dx ~= dx then dx = 0 end
    if dy ~= dy then dy = 0 end
    if du ~= du then du = 0 end
    return hx, hy, hz, dx, dy, du
end
Aim.hit = hit

-- Where the aim ray (through the hit, direction d) meets the level plane z,
-- going on away from the eye, and not further than MAX_THROUGH tiles past the
-- hit. Returns x, y or nil (looking level or up at it, or too far).
local MAX_THROUGH = 3
function Aim.onPlane(hx, hy, hz, dx, dy, du, z)
    if math.abs(du) < 1e-4 then return nil end
    local t = (z - hz) / du
    if t <= 0 then return nil end
    local len = math.sqrt(dx * dx + dy * dy)
    if len * t > MAX_THROUGH then return nil end
    return hx + dx * t, hy + dy * t
end

-- Is the hit on one of the tile previews (inside its tile, above its floor, or
-- right on a preview wall's face)?
local function onTilePreview(hx, hy, hz)
    for _, b in ipairs(Preview.tileBoxes) do
        if hz >= b.z - 0.02 and hz <= b.z + 1.05 then
            if b.wall == "N" then
                if hx >= b.x - 0.05 and hx <= b.x + 1.05 and math.abs(hy - b.y) <= 0.2 then return b end
            elseif b.wall == "W" then
                if hy >= b.y - 0.05 and hy <= b.y + 1.05 and math.abs(hx - b.x) <= 0.2 then return b end
            elseif hx >= b.x and hx < b.x + 1 and hy >= b.y and hy < b.y + 1 and hz > b.z + 0.02 then
                return b
            end
        end
    end
    return nil
end

-- The point to build at: the hit, unless it is on a build preview, then where
-- the ray meets that preview's floor. Returns x, y, z (z a level, may be
-- fractional) and the raw hit, or nil.
local lastBuild = nil
function Aim.buildPoint()
    local hx, hy, hz, dx, dy, du = hit()
    if not hx then return nil end
    local b = onTilePreview(hx, hy, hz)
    if b then
        -- the floor the whole object stands on (tall objects have upper tiles)
        local floor = b.base or b.z
        local px, py = Aim.onPlane(hx, hy, hz, dx, dy, du, floor)
        if px then
            lastBuild = { px, py, floor, dx, dy, du }
            return px, py, floor, dx, dy, du
        end
        -- no floor point along the ray (looking at the preview level or from
        -- below): stay where the preview is rather than jump
        if lastBuild then return unpack(lastBuild) end
        return b.x + 0.5, b.y + 0.5, b.base or b.z, dx, dy, du
    end
    lastBuild = { hx, hy, hz, dx, dy, du }
    return hx, hy, hz, dx, dy, du
end

-- The point to put an item at: the hit, unless it is on the item preview,
-- then where the ray meets the plane the preview stands on.
function Aim.placePoint()
    local hx, hy, hz, dx, dy, du = hit()
    if not hx then return nil end
    local s = itemState
    if s then
        local ddx, ddy = hx - s.x, hy - s.y
        if ddx * ddx + ddy * ddy <= 0.45 * 0.45 and hz >= s.z - 0.02 and hz <= s.z + 0.6 then
            local px, py = Aim.onPlane(hx, hy, hz, dx, dy, du, s.z)
            if px then return px, py, s.z, dx, dy, du, true end
            return s.x, s.y, s.z, dx, dy, du, true   -- stay put
        end
    end
    return hx, hy, hz, dx, dy, du, false
end

---------------------------------------------------------------------------
-- Never left behind
---------------------------------------------------------------------------

local function clear() pcall(Preview.clearAll) end
Events.OnGameStart.Add(clear)   -- after a Lua reload the Java side may still hold some
Events.OnSave.Add(clear)
Events.OnPlayerDeath.Add(clear)
Events.OnDisconnect.Add(clear)

return Preview
