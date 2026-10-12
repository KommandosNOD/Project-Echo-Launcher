--
-- Viewpoint UI - sledgehammer (destroy) and dismantle in first and third person.
--
-- The game's Destroy (sledgehammer) and Dismantle use ISDestroyCursor, a drag
-- cursor that IsoCell.render drives from the isometric mouse tile
-- (DoTileBuilding: isValid -> render -> click tryBuild). Its highlight is an
-- isometric ghost sprite (RenderGhostTileColor). Viewpoint replaces
-- IsoCell.render, so in Viewpoint's view the cursor followed nothing and no
-- green highlight showed.
--
-- Destroy mode drives the very same cursor from the crosshair, doing what
-- DoTileBuilding and ISDestroyCursor:render do:
--
--   aimed square -> cursor:isValid(square), renderX/Y/Z, objectIndex as
--   render() keeps it -> outline of the object it will destroy (projected with
--   Viewpoint's camera) -> on Interact: cursor:tryBuild(x, y, z)
--
-- so what can be destroyed, the walk, the sledgehammer equip and the
-- ISDestroyStuffAction / ISDismantleAction (and the server's checks) stay the
-- game's. The wheel cycles the objects on the square (the cursor's own
-- cycleToNextObject / cycleToPreviousObject, as the joypad bumpers and the
-- Rotate key do). The cancel key drops the cursor.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/Building/Preview"

local VPUI = ViewpointUI
VPUI.Building = VPUI.Building or {}
if VPUI.Building.DestroyMode then return end

local DestroyMode = {}
VPUI.Building.DestroyMode = DestroyMode

local Log = VPUI.Log
local Bridge = VPUI.Bridge
local Theme = VPUI.UI.Theme
local C = Theme.color
local T = VPUI.Text
local Preview = VPUI.Building.Preview

local REACH = 6       -- tiles from the player to the aimed point
local EDGE = 0.05     -- how far either side of a hit surface the squares are tried

local state = nil     -- { cursor, player, square, valid, object, reason }

-- The game's destroy cursor for this player (ISDestroyCursor or a subclass).
function DestroyMode.cursor(player)
    if not player or not ISDestroyCursor then return nil end
    local ok, drag = pcall(function() return getCell():getDrag(player:getPlayerNum()) end)
    if not ok or type(drag) ~= "table" then return nil end
    local mt = getmetatable(drag)
    for _ = 1, 8 do
        if mt == nil then return nil end
        if mt == ISDestroyCursor then return drag end
        mt = getmetatable(mt)
    end
    return nil
end

function DestroyMode.isActive()
    return state ~= nil
end

function DestroyMode.stop(clearCursor)
    if not state then return end
    local player = state.player
    if clearCursor and player then
        local pn = player:getPlayerNum()
        if getCell():getDrag(pn) == state.cursor then getCell():setDrag(nil, pn) end
    end
    state = nil
    if DestroyMode.card then DestroyMode.card:display(false) end
end

-- The cursor's object list for a square, read as ISDestroyCursor:render does
-- (isValid, then renderX/Y/Z on the square - isValid skips that when only the
-- safehouse rule applies).
local function look(cursor, square)
    local okV, valid = pcall(cursor.isValid, cursor, square)
    if not okV then
        Log.once(Log.ERROR, "destroyValid", "destroy check failed: " .. tostring(valid))
        valid = false
    end
    cursor.renderX, cursor.renderY, cursor.renderZ = square:getX(), square:getY(), square:getZ()
    local okL, objects = pcall(cursor.getObjectList, cursor)
    if not okL or type(objects) ~= "table" then objects = {} end
    return valid == true, objects
end

local function indexOf(list, object)
    if not object then return nil end
    for i, o in ipairs(list) do if o == object then return i end end
    return nil
end

-- Squares to try for the aimed point: the one Viewpoint's target sits on
-- first, then the squares either side of the hit surface. A wall belongs to
-- the square whose west or north edge it is, which is the one with the larger
-- x or y when the hit lies on the boundary between two squares.
local function candidates(player)
    local list, seen = {}, {}
    local function add(sq) if sq and not seen[sq] then seen[sq] = true; table.insert(list, sq) end end
    local t = VPUI.Interaction and VPUI.Interaction.Target and VPUI.Interaction.Target.get()
    local preferred = t and t.object or nil
    if t and t.square and t.object then add(t.square) end
    local hx, hy, hz, dx, dy, du = Preview.Aim.buildPoint()
    if not hx then return list, preferred end
    local ddx, ddy = hx - player:getX(), hy - player:getY()
    if ddx * ddx + ddy * ddy > REACH * REACH then return list, preferred, "far" end
    local function sq(sx, sy, sz)
        local z = math.floor(sz + 0.001)
        if z < 0 then z = 0 end
        return getCell():getGridSquare(math.floor(sx), math.floor(sy), z)
    end
    local back = sq(hx - dx * EDGE, hy - dy * EDGE, hz - du * EDGE)
    local front = sq(hx + dx * EDGE, hy + dy * EDGE, hz)
    if back and front and back ~= front and (front:getX() > back:getX() or front:getY() > back:getY()) then
        add(front); add(back)
    else
        add(back); add(front)
    end
    return list, preferred
end

-- Per tick from the controller. Returns true while destroy mode runs.
function DestroyMode.tick(player, now, Input)
    local cursor = DestroyMode.cursor(player)
    if not cursor then
        if state then DestroyMode.stop(false) end
        return false
    end
    if not state or state.cursor ~= cursor then
        state = { cursor = cursor, player = player }
    end
    if Input.pressed("cancel") then
        DestroyMode.stop(true)
        return false
    end

    -- the square under the crosshair that has something to destroy
    local squares, preferred, reason = candidates(player)
    local square, valid, objects = nil, false, {}
    for _, sq in ipairs(squares) do
        local v, list = look(cursor, sq)
        if #list > 0 then
            square, valid, objects = sq, v, list
            if indexOf(list, preferred) or not preferred then break end
        end
    end
    state.reason = (not square) and reason or nil

    if not square then
        state.square, state.valid, state.object = nil, false, nil
        cursor.currentObject = nil
        DestroyMode.updateCard()
        return true
    end
    look(cursor, square)   -- leave the cursor on the chosen square

    -- objectIndex as ISDestroyCursor:render keeps it; a new square starts on
    -- the object Viewpoint aims at when it is in the list
    local key = square:getX() .. "," .. square:getY() .. "," .. square:getZ()
    if state.squareKey ~= key then
        state.squareKey = key
        cursor.currentSquare = square
        cursor.objectIndex = indexOf(objects, preferred) or 1
    end

    -- the wheel: the next / previous object on the square (the cursor's own)
    local notches = tonumber(Bridge.takeWheel()) or 0
    if notches ~= 0 then
        cursor.currentObject = objects[cursor.objectIndex or 1]
        for _ = 1, math.min(math.abs(notches), 4) do
            local fn = notches > 0 and cursor.cycleToNextObject or cursor.cycleToPreviousObject
            if fn then pcall(fn, cursor) end
        end
    end

    if (cursor.objectIndex or 0) < 1 and #objects > 0 then cursor.objectIndex = 1 end
    if (cursor.objectIndex or 0) > #objects then cursor.objectIndex = #objects end
    local object = objects[cursor.objectIndex]
    if object and object.hasProperty and cursor.checkNorthWestCorner then
        local okP, corner = pcall(object.hasProperty, object, "CornerNorthWall")
        if okP and corner then pcall(cursor.checkNorthWestCorner, cursor, object) end
    end
    cursor.currentObject = object
    state.square, state.valid, state.object = square, valid and object ~= nil, object

    if Input.pressed("interact") then
        if state.valid then
            local ok, err = pcall(cursor.tryBuild, cursor, square:getX(), square:getY(), square:getZ())
            if not ok then Log.error("destroy failed: " .. tostring(err)) end
        else
            VPUI.Controller.toast(T.destroyCannot, 1.5, true)
        end
    end
    DestroyMode.updateCard()
    return true
end

---------------------------------------------------------------------------
-- What gets destroyed: the shapes to outline
---------------------------------------------------------------------------

local function flag(object, name)
    local ok, v = pcall(function()
        local props = object:getProperties()
        return props ~= nil and IsoFlagType[name] ~= nil and props:has(IsoFlagType[name])
    end)
    return ok and v == true
end

local function northOf(object)
    local ok, v = pcall(function() return object.getNorth and object:getNorth() end)
    if ok and v ~= nil then return v == true end
    return nil
end

-- "N" or "W" for an object standing on a square's edge, nil otherwise.
local function edgeOf(cursor, object)
    if flag(object, "cutW") and flag(object, "cutN") then
        -- a corner wall: the half the cursor picked (cornerCounter 1 = north)
        return cursor.cornerCounter == 1 and "N" or "W"
    end
    if flag(object, "cutN") or flag(object, "WallN") then return "N" end
    if flag(object, "cutW") or flag(object, "WallW") then return "W" end
    local isEdgeThing = false
    pcall(function()
        isEdgeThing = instanceof(object, "IsoDoor") or instanceof(object, "IsoWindow") or instanceof(object, "IsoBarricade")
            or (instanceof(object, "IsoThumpable") and (object:isDoor() or object:isWindow()))
    end)
    if isEdgeThing then
        local n = northOf(object)
        if n ~= nil then return n and "N" or "W" end
    end
    local okT, t = pcall(function() return object:getType() end)
    if okT and IsoObjectType then
        if t == IsoObjectType.doorFrN then return "N" end
        if t == IsoObjectType.doorFrW then return "W" end
    end
    return nil
end

-- The objects ISDestroyCursor:render highlights for the current one.
local function highlighted(object)
    local function fromUtil(name)
        if not buildUtil or not buildUtil[name] then return nil end
        local ok, list = pcall(buildUtil[name], object)
        if ok and type(list) == "table" and #list > 0 then return list end
        return nil
    end
    local list = fromUtil("getStairObjects") or fromUtil("getDoubleDoorObjects")
        or fromUtil("getGarageDoorObjects") or fromUtil("getGraveObjects")
    if list then return list end
    local ok, grid = pcall(function() return object:getSpriteGridObjectsIncludingSelf(ArrayList.new()) end)
    if ok and grid and grid.size and grid:size() > 0 then
        local out = {}
        for i = 0, grid:size() - 1 do table.insert(out, grid:get(i)) end
        return out
    end
    return { object }
end

-- { x, y, z, shape = "N"|"W"|"floor"|"box" } for every outlined tile.
function DestroyMode.shapes()
    if not state or not state.object then return {} end
    local cursor = state.cursor
    local out = {}
    for _, o in ipairs(highlighted(state.object)) do
        local ok, x, y, z = pcall(function() return o:getX(), o:getY(), o:getZ() end)
        if ok and x then
            local shape = edgeOf(cursor, o)
            if not shape then shape = flag(o, "solidfloor") and "floor" or "box" end
            table.insert(out, { x = math.floor(x), y = math.floor(y), z = math.floor(z), shape = shape })
        end
    end
    return out
end

local function objectName(object)
    if not object then return nil end
    local MoveMode = VPUI.Building.MoveMode
    local props = MoveMode and MoveMode.propsOf and MoveMode.propsOf(object)
    if props then return MoveMode.displayName(props) end
    local ok, name = pcall(function() return object:getObjectName() end)
    if ok and name and name ~= "" then return tostring(name) end
    return nil
end

---------------------------------------------------------------------------
-- Outline and card
---------------------------------------------------------------------------

local VPElement = VPUI.UI.VPElement
local Card = VPElement:derive("VPDestroyCard")

function Card:new()
    return VPElement.new(self, getCore():getScreenWidth(), getCore():getScreenHeight())
end

local function point(x, y, z, lift)
    local native = VPUI.Native
    if not native or not native.project then return nil end
    local ok, visible = pcall(native.project, x, y, z, lift)
    if not ok or not visible then return nil end
    return { native.projectedX(), native.projectedY() }
end

local function line(ui, a, b, c)
    if not a or not b then return end
    ui:drawLine2(a[1], a[2], b[1], b[2], 0.9, c.r, c.g, c.b)
    ui:drawLine2(a[1] + 1, a[2], b[1] + 1, b[2], 0.6, c.r, c.g, c.b)
end

local WALL_H = 0.95   -- a wall's outline height, as build mode's
local BOX_H = 0.6     -- other objects: a box this high (the real height is not known)

local function outline(ui, t, c)
    local x0, y0, x1, y1, z = t.x, t.y, t.x + 1, t.y + 1, t.z
    if t.shape == "N" or t.shape == "W" then
        local a, b
        if t.shape == "N" then a, b = { x0, y0 }, { x1, y0 } else a, b = { x0, y0 }, { x0, y1 } end
        local p1, p2 = point(a[1], a[2], z, 0), point(b[1], b[2], z, 0)
        local p3, p4 = point(a[1], a[2], z, WALL_H), point(b[1], b[2], z, WALL_H)
        line(ui, p1, p2, c); line(ui, p3, p4, c); line(ui, p1, p3, c); line(ui, p2, p4, c)
        return
    end
    local lift = 0.01
    local b1, b2, b3, b4 = point(x0, y0, z, lift), point(x1, y0, z, lift), point(x1, y1, z, lift), point(x0, y1, z, lift)
    line(ui, b1, b2, c); line(ui, b2, b3, c); line(ui, b3, b4, c); line(ui, b4, b1, c)
    if t.shape == "box" then
        local u1, u2, u3, u4 = point(x0, y0, z, BOX_H), point(x1, y0, z, BOX_H), point(x1, y1, z, BOX_H), point(x0, y1, z, BOX_H)
        line(ui, u1, u2, c); line(ui, u2, u3, c); line(ui, u3, u4, c); line(ui, u4, u1, c)
        line(ui, b1, u1, c); line(ui, b2, u2, c); line(ui, b3, u3, c); line(ui, b4, u4, c)
    end
end

function Card:render()
    local s = state
    if not s or not s.cursor then return end
    local cursor = s.cursor
    local c = s.valid and C.good or C.danger
    for _, t in ipairs(DestroyMode.shapes()) do outline(self, t, c) end

    local font, small = Theme.font(), Theme.smallFont()
    local verb
    if cursor.dismantle then
        verb = T.destroyDismantle
    else
        local ok, p = pcall(cursor.getAPrompt, cursor)
        verb = (ok and p) or T.destroyTitle
    end
    local name = objectName(s.object)
    local title = name and (verb .. ": " .. name) or verb
    local stateText
    if s.reason == "far" then stateText = T.place_far
    elseif not s.object then stateText = T.destroyNothing
    elseif s.valid then stateText = T.destroyReady
    else stateText = T.destroyCannot end
    local hint = string.format(T.destroyHint, VPUI.Input.label("interact"), VPUI.Input.label("cancel"))
    local w = math.max(Theme.textWidth(font, title), Theme.textWidth(small, hint), Theme.textWidth(small, stateText)) + Theme.px(20)
    local fh = Theme.fontHeight(small)
    local hgt = Theme.fontHeight(font) + fh * 2 + Theme.px(18)
    local cx, cy = Theme.screenCenter()
    local x, y = cx - w / 2, cy + Theme.px(40)
    self:panel(x, y, w, hgt)
    self:fill(x, y, Theme.px(2), hgt, c)
    self:text(title, x + Theme.px(10), y + Theme.px(5), C.text, font)
    local ty = y + Theme.px(6) + Theme.fontHeight(font)
    self:text(stateText, x + Theme.px(10), ty, c, small)
    self:text(hint, x + Theme.px(10), ty + fh + Theme.px(4), C.dim, small)
end

function Card:layout()
    self:place(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    self.dirty = false
end

function DestroyMode.updateCard()
    if not DestroyMode.card then DestroyMode.card = Card:new() end
    if DestroyMode.card.dirty then DestroyMode.card:layout() end
    DestroyMode.card:display(state ~= nil)
end

return DestroyMode
