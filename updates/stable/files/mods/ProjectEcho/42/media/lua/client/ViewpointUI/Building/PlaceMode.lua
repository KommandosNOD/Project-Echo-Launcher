--
-- Viewpoint UI - placing items in first and third person.
--
-- The game's "Place Item" (ISPlace3DItemCursor) is a drag cursor the game
-- drives from the isometric mouse tile (DoTileBuilding / renderOpaqueObjects
-- InWorld) and draws with Render3DItem in the isometric pass. In Viewpoint's
-- view neither happens: the cursor never moves and nothing is shown, so items
-- cannot be put down.
--
-- Place mode drives that same cursor from the crosshair, so the game still
-- decides everything (where you may put it, the weight limit, walking there,
-- the drop action, multiplayer), and adds:
--
--   * the item itself as the preview, on the exact point you look at and on
--     the surface it will sit on (Building/Preview: a local copy Viewpoint
--     draws in 3D, never sent to the server);
--   * the surface chosen from what you aim at: the table top when you look at
--     the table, the floor when you look at the floor (Tab still cycles);
--   * turning with the mouse wheel (15 degrees a notch) as well as the game's
--     Rotate key (tap: 5 degrees, hold: smooth);
--   * the Interact key places, Shift+Interact places the whole stack (the
--     game's Shift rule), the cancel key stops.
--
-- It starts by itself whenever the game's place cursor is up: from the item's
-- right-click menu in the Viewpoint inventory (which then closes), or from any
-- other mod that opens it.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/Building/Preview"

local VPUI = ViewpointUI
VPUI.Building = VPUI.Building or {}
if VPUI.Building.PlaceMode then return end

local PlaceMode = {}
VPUI.Building.PlaceMode = PlaceMode

local Log = VPUI.Log
local Bridge = VPUI.Bridge
local Theme = VPUI.UI.Theme
local C = Theme.color
local T = VPUI.Text
local Preview = VPUI.Building.Preview

local REACH = 4.5          -- tiles: further than this, nothing is shown
local WHEEL_STEP = 15      -- degrees per wheel notch

local state = nil   -- { cursor, player, square, xoff, yoff, zoff, valid, surfSquare, manualSurface, reason }

-- The game's place cursor for this player, if one is up.
function PlaceMode.cursor(player)
    if not player then return nil end
    local ok, drag = pcall(function() return getCell():getDrag(player:getPlayerNum()) end)
    if not ok or type(drag) ~= "table" or not drag.isPlace3DCursor then return nil end
    if type(drag.items) ~= "table" or #drag.items == 0 then return nil end
    return drag
end

function PlaceMode.isActive()
    return state ~= nil
end

function PlaceMode.stop(clearCursor)
    if not state then return end
    local player = state.player
    if clearCursor and player then
        local pn = player:getPlayerNum()
        if getCell():getDrag(pn) == state.cursor then getCell():setDrag(nil, pn) end
    end
    state = nil
    Preview.clearItem()
    if PlaceMode.card then PlaceMode.card:display(false) end
    VPUI.Events.fire("PlaceModeStopped")
end

-- Where the item would be taken from (the game's place cursor needs it to walk
-- there first): the square of the world item, of the container's owner or of
-- the bag lying on the ground; nil when it is in a vehicle.
local function sourceSquare(player, item)
    local sq = nil
    local ok = pcall(function()
        local wo = item:getWorldItem()
        if wo then sq = wo:getSquare() end
        local container = item:getOutermostContainer()
        if container then
            local parent = container:getParent()
            if parent and parent ~= player then sq = parent:getSquare() end
            local holder = container:getContainingItem()
            if holder and holder:getWorldItem() then sq = holder:getWorldItem():getSquare() end
            if container:getVehiclePart() then sq = false end
        end
    end)
    if not ok then return nil end
    if sq == false then return nil end
    return sq
end

local function wrap(deg)
    deg = deg % 360
    if deg < 0 then deg = deg + 360 end
    return deg
end

-- Picks the surface from the aim: near the floor, the floor when the square
-- offers it; higher up, the highest surface (a table top, a shelf).
local function autoSurface(cursor, rel)
    local list = cursor.surfacesPossible
    if type(list) ~= "table" or #list <= 1 then return end
    local best, bestV = nil, nil
    if rel < 0.05 then
        for i, v in ipairs(list) do if v == 0 then best = i end end
    end
    if not best then
        for i, v in ipairs(list) do
            if not bestV or v > bestV then best, bestV = i, v end
        end
    end
    if best then cursor.surfaceSelected = best end
end

-- Per tick from the controller. Returns true while place mode runs.
function PlaceMode.tick(player, now, Input)
    local cursor = PlaceMode.cursor(player)
    if not cursor then
        if state then PlaceMode.stop(false) end
        return false
    end
    if not state or state.cursor ~= cursor then
        Preview.clearItem()
        state = { cursor = cursor, player = player }
        VPUI.Events.fire("PlaceModeStarted", cursor.items[1])
    end
    if Input.pressed("cancel") then
        PlaceMode.stop(true)
        return false
    end

    -- turning: the game's Rotate key (tap / hold), and the wheel
    pcall(cursor.checkRotateKey, cursor)
    local notches = Bridge.takeWheel() or 0
    if notches ~= 0 then
        cursor.render3DItemRot = wrap((cursor.render3DItemRot or 0) + (notches > 0 and WHEEL_STEP or -WHEEL_STEP) * math.abs(notches))
    end

    -- the point under the crosshair (the preview itself is looked through)
    local hx, hy, hz = Preview.Aim.placePoint()
    local square, xoff, yoff = nil, 0.5, 0.5
    state.reason = nil
    if hx then
        local px, py = player:getX(), player:getY()
        local ddx, ddy = hx - px, hy - py
        if ddx * ddx + ddy * ddy > REACH * REACH then
            state.reason = "far"
        else
            local level = math.floor(hz + 0.001)
            if level < 0 then level = 0 end
            square = getCell():getGridSquare(math.floor(hx), math.floor(hy), level)
            if square then
                xoff = math.max(0.05, math.min(0.95, hx - square:getX()))
                yoff = math.max(0.05, math.min(0.95, hy - square:getY()))
            end
        end
    end
    state.square = square

    if not square then
        state.valid = false
        Preview.clearItem()
        PlaceMode.updateCard()
        return true
    end

    -- the surface first: what you aim at, unless you picked one with the
    -- game's key (on a new square the game starts again from the first
    -- surface, as its isValid does)
    if state.surfSquare ~= square then
        state.surfSquare = square
        state.manualSurface = false
        cursor.previousSq = square
        cursor.surfaceSelected = 1
    end
    local before = cursor.surfaceSelected
    pcall(cursor.getSurface, cursor, square)   -- fills surfacesPossible
    pcall(cursor.checkSelectSurfaceKey, cursor)
    if cursor.surfaceSelected ~= before then state.manualSurface = true end
    if not state.manualSurface then autoSurface(cursor, hz - square:getZ()) end
    local okS, zoff = pcall(cursor.getSurface, cursor, square)
    zoff = okS and tonumber(zoff) or 0
    local okZ, apparent = pcall(function()
        if square:HasStairs() or square:hasSlopedSurface() then return square:getApparentZ(xoff, yoff) end
        return nil
    end)
    -- the game's cursor takes getApparentZ as it is (ISPlace3DItemCursor does);
    -- it is an absolute height, so the preview uses it relative to the floor
    local previewZ = zoff
    if okZ and apparent then zoff = apparent; previewZ = apparent - square:getZ() end

    -- then the game's own check (walkable, in sight, not through a wall, the
    -- 50 kg floor limit), without the preview on the square
    cursor.placeAll = isShiftKeyDown()
    local okV, valid = pcall(Preview.withoutItem, cursor.isValid, cursor, square)
    if not okV then
        Log.once(Log.ERROR, "placeValid", "place check failed: " .. tostring(valid))
        valid = false
    end

    cursor.render3DItemXOffset = xoff
    cursor.render3DItemYOffset = yoff
    cursor.render3DItemZOffset = zoff
    cursor.selectedSqDrop = square
    cursor.itemSq = sourceSquare(player, cursor.items[1])
    if cursor.placeAll then
        for _, it in ipairs(cursor.items) do cursor.itemSq = sourceSquare(player, it) end
    end
    state.valid = valid == true
    state.xoff, state.yoff, state.zoff = xoff, yoff, previewZ

    local rot = 0
    local okR, r = pcall(cursor.clamp, cursor, cursor.render3DItemRot or 0)
    if okR and r then rot = r end
    -- no preview while the drop is under way: the game's drop action weighs
    -- what lies on the floor when it starts
    local busy = false
    pcall(function() busy = not player:getCharacterActions():isEmpty() end)
    if busy then
        Preview.clearItem()
    else
        Preview.showItem(cursor.items[1], square, xoff, yoff, previewZ, rot)
    end

    if Input.pressed("interact") then
        if state.valid then
            -- the preview goes before the real one is put down
            Preview.clearItem()
            local ok, err = pcall(cursor.tryBuild, cursor, square:getX(), square:getY(), square:getZ())
            if not ok then Log.error("placing failed: " .. tostring(err)) end
        else
            VPUI.Controller.toast(T.place_blocked, 1.5, true)
        end
    end
    PlaceMode.updateCard()
    return true
end

---------------------------------------------------------------------------
-- Card under the crosshair and a ring round the spot
---------------------------------------------------------------------------

local VPElement = VPUI.UI.VPElement
local Card = VPElement:derive("VPPlaceCard")

function Card:new()
    return VPElement.new(self, getCore():getScreenWidth(), getCore():getScreenHeight())
end

local function proj(x, y, z, lift)
    local native = VPUI.Native
    if not native or not native.project then return nil end
    local ok, visible = pcall(native.project, x, y, z, lift)
    if not ok or not visible then return nil end
    return { native.projectedX(), native.projectedY() }
end

local function line(ui, a, b, c)
    if not a or not b then return end
    ui:drawLine2(a[1], a[2], b[1], b[2], 0.9, c.r, c.g, c.b)
end

function Card:render()
    local s = state
    if not s or not s.cursor then return end
    local cursor = s.cursor
    local c = s.valid and C.good or C.danger
    -- a small ring on the surface round the spot (the item itself is in the world)
    if s.square and s.xoff then
        local x, y, z = s.square:getX() + s.xoff, s.square:getY() + s.yoff, s.square:getZ() + (s.zoff or 0)
        local r = 0.22
        local pts = {}
        for i = 0, 8 do
            local a = i / 8 * math.pi * 2
            pts[i] = proj(x + math.cos(a) * r, y + math.sin(a) * r, z, 0.005)
        end
        for i = 0, 7 do line(self, pts[i], pts[i + 1], c) end
    end
    local font, small = Theme.font(), Theme.smallFont()
    local item = cursor.items and cursor.items[1]
    local name = item and item:getDisplayName() or "?"
    if #cursor.items > 1 then name = name .. "  x" .. tostring(#cursor.items) end
    local stateText
    if s.reason == "far" then stateText = T.place_far
    elseif not s.square then stateText = T.place_none
    elseif s.valid then stateText = cursor.placeAll and T.place_valid_all or T.place_valid
    else stateText = T.place_blocked end
    local rotateKey = getCore():getKey(KeybindId.ROTATE_BUILDING)
    local surfKey = getCore():getKey(KeybindId.TOGGLE_MODE)
    local hint = string.format(T.placeHint, VPUI.Input.label("interact"),
        (rotateKey and rotateKey > 0) and getKeyName(rotateKey) or "?", VPUI.Input.label("cancel"))
    local hint2 = nil
    if type(cursor.surfacesPossible) == "table" and #cursor.surfacesPossible > 1 and surfKey and surfKey > 0 then
        hint2 = string.format(T.placeSurfaceHint, getKeyName(surfKey))
    end
    local w = math.max(Theme.textWidth(font, name), Theme.textWidth(small, hint), Theme.textWidth(small, stateText),
        hint2 and Theme.textWidth(small, hint2) or 0) + Theme.px(20)
    local lines = hint2 and 3 or 2
    local hgt = Theme.fontHeight(font) + Theme.fontHeight(small) * lines + Theme.px(16)
    local cx, cy = Theme.screenCenter()
    local x, y = cx - w / 2, cy + Theme.px(40)
    self:panel(x, y, w, hgt)
    self:fill(x, y, Theme.px(2), hgt, c)
    self:text(name, x + Theme.px(10), y + Theme.px(5), C.text, font)
    local ty = y + Theme.px(6) + Theme.fontHeight(font)
    self:text(stateText, x + Theme.px(10), ty, c, small)
    ty = ty + Theme.fontHeight(small) + Theme.px(2)
    self:text(hint, x + Theme.px(10), ty, C.dim, small)
    if hint2 then self:text(hint2, x + Theme.px(10), ty + Theme.fontHeight(small), C.dim, small) end
end

function Card:layout()
    self:place(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    self.dirty = false
end

function PlaceMode.updateCard()
    if not PlaceMode.card then PlaceMode.card = Card:new() end
    if PlaceMode.card.dirty then PlaceMode.card:layout() end
    PlaceMode.card:display(state ~= nil)
end

return PlaceMode
