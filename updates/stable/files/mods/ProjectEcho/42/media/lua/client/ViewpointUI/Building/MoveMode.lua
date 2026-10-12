--
-- Viewpoint UI - moving furniture in first and third person.
--
-- The game moves furniture (fridges, chairs, sofas, lamps...) with its
-- moveables cursor (ISMoveableCursor): pick up, place, rotate, scrap and
-- repair, each checked by ISMoveableSpriteProps and carried out by
-- ISMoveablesAction. The cursor is driven from the isometric mouse tile and
-- drawn as isometric ghost sprites, and it is opened from the left sidebar,
-- which is hidden in Viewpoint's view - so furniture could not be moved.
--
-- Here:
--   * "Pick up <name>" on the furniture you aim at (and "Rotate") in the
--     action list. Pick up runs exactly what the cursor's create() does for
--     "pickup": the same checks, walk and equip, and ISMoveablesAction.
--   * Move mode: whenever the game's moveables cursor is up (Place from a
--     carried piece of furniture, Rotate from the list, or any mod), it is
--     driven from the crosshair. The game still decides everything (isValid,
--     tryBuild, the action, multiplayer); the piece stands where it will go as
--     a local preview (Building/Preview), the wheel turns it (the game's own
--     turn: rotateWhilePlacing / the rotate step), Interact does it, the
--     cancel key stops. The game's requirement lines (weight, tool, skill)
--     are shown on a card under the crosshair instead of its isometric panel.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/Building/Preview"

local VPUI = ViewpointUI
VPUI.Building = VPUI.Building or {}
if VPUI.Building.MoveMode then return end

local MoveMode = {}
VPUI.Building.MoveMode = MoveMode

local Log = VPUI.Log
local Bridge = VPUI.Bridge
local Theme = VPUI.UI.Theme
local C = Theme.color
local T = VPUI.Text
local Preview = VPUI.Building.Preview

local REACH = 5.5   -- tiles from the player to the aimed square

local state = nil   -- { cursor, player, square, valid, mode, info, infoKey, hidden }

---------------------------------------------------------------------------
-- Furniture under the crosshair
---------------------------------------------------------------------------

-- The moveable properties of an object, or nil when it cannot be moved.
function MoveMode.propsOf(object)
    if not object or not ISMoveableSpriteProps then return nil end
    local ok, props = pcall(function()
        local sprite = object:getSprite()
        if not sprite then return nil end
        local p = ISMoveableSpriteProps.new(sprite)
        if p and p.isMoveable and p.sprite then return p end
        return nil
    end)
    return ok and props or nil
end

function MoveMode.displayName(props)
    local ok, name = pcall(function() return Translator.getMoveableDisplayName(props.name) end)
    if ok and name and name ~= "" then return name end
    return tostring(props.name or "?")
end

-- Why a pick up is refused, in a few words (the full list is the card's).
function MoveMode.pickupReason(player, square, object, props)
    local ok, r = pcall(function()
        if object and not object:isObjectNoContainerOrEmpty() then return T.moveNotEmpty end
        if not player:getInventory():hasRoomFor(player, props.weight) then return T.moveTooHeavy end
        return T.moveNeedsTool
    end)
    return ok and r or nil
end

-- Picks it up: the "pickup" branch of ISMoveableCursor:create, without the
-- cursor (ISMoveablesAction takes a nil cursor).
function MoveMode.pickUp(player, square, object)
    local props = MoveMode.propsOf(object)
    if not props or not square then return false end
    if not (ISMoveableDefinitions.cheat or player:isMovablesCheat()) and not props:canPickUpMoveable(player, square, object) then
        VPUI.Controller.toast(MoveMode.pickupReason(player, square, object, props) or T.moveCannot, 2.5, true)
        return false
    end
    if not (ISMoveableDefinitions.cheat or props:walkToAndEquip(player, square, "pickup", props.spriteName)) then
        return false
    end
    local direction = props:getFaceDirectionFromSpriteName(props.sprite:getName())
    local obj = props:findOnSquare(square, props.spriteName)
    ISTimedActionQueue.add(ISMoveablesAction:new(player, square, "pickup", props.spriteName, obj, direction, nil, nil))
    return true
end

-- Opens the game's moveables cursor in a mode ("rotate", "place"...); move
-- mode drives it from the crosshair from the next tick.
function MoveMode.open(player, mode, item)
    local cursor = ISMoveableCursor:new(player)
    getCell():setDrag(cursor, cursor.player)
    cursor:setMoveableMode(mode)
    if item then cursor:tryInitialItem(item) end
    return cursor
end

---------------------------------------------------------------------------
-- Move mode
---------------------------------------------------------------------------

-- The game's moveables cursor for this player, if one is up.
function MoveMode.cursor(player)
    if not player then return nil end
    local ok, drag = pcall(function() return getCell():getDrag(player:getPlayerNum()) end)
    if not ok or type(drag) ~= "table" or not drag.isMoveableCursor then return nil end
    return drag
end

function MoveMode.isActive()
    return state ~= nil
end

local function mode(player)
    return ISMoveableCursor.mode[player:getPlayerNum()] or "pickup"
end

local function unhide()
    if state and state.cursor then pcall(state.cursor.resetObjectHiddenDuringRotate, state.cursor) end
end

function MoveMode.stop(clearCursor)
    if not state then return end
    unhide()
    local player = state.player
    if clearCursor and player then
        local pn = player:getPlayerNum()
        if getCell():getDrag(pn) == state.cursor then getCell():setDrag(nil, pn) end
    end
    state = nil
    Preview.clearTiles()
    if MoveMode.card then MoveMode.card:display(false) end
end

-- Pick up, rotate, scrap and repair work on what you aim at; place on the
-- point you look at (the preview is looked through).
local function aimSquare(player, m)
    if m ~= "place" then
        local t = VPUI.Interaction and VPUI.Interaction.Target and VPUI.Interaction.Target.get()
        if t and t.square and t.object then return t.square end
    end
    local hx, hy, hz, dx, dy, du = Preview.Aim.buildPoint()
    if not hx then return nil end
    local ddx, ddy = hx - player:getX(), hy - player:getY()
    if ddx * ddx + ddy * ddy > REACH * REACH then return nil, "far" end
    local back = 0.05
    local x = math.floor(hx - dx * back)
    local y = math.floor(hy - dy * back)
    local z = math.floor(hz - du * back + 0.001)
    if z < 0 then z = 0 end
    return getCell():getGridSquare(x, y, z)
end

-- The tiles the piece will stand on: one, or its sprite grid laid out as the
-- cursor's renderSpriteGrid lays it.
local function footprint(cursor, square)
    local props, orig = cursor.currentMoveProps, cursor.origMoveProps
    if not props or not props.sprite or not square then return {} end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    if orig and orig.isMultiSprite and props.isMultiSprite then
        local origGrid = orig.sprite:getSpriteGrid()
        local grid = props.sprite:getSpriteGrid()
        if not origGrid or not grid then return {} end
        local wx = x - origGrid:getSpriteGridPosX(orig.sprite)
        local wy = y - origGrid:getSpriteGridPosY(orig.sprite)
        local tiles = {}
        for gx = 0, grid:getWidth() - 1 do
            for gy = 0, grid:getHeight() - 1 do
                local s = grid:getSprite(gx, gy)
                if s then table.insert(tiles, { x = wx + gx, y = wy + gy, z = z, sprite = s:getName() }) end
            end
        end
        return tiles
    end
    return { { x = x, y = y, z = z, sprite = props.sprite:getName() } }
end

local function busy(player)
    local b = false
    pcall(function() b = not player:getCharacterActions():isEmpty() end)
    return b
end

-- The game's isometric info panel would sit at the projected tile, which means
-- nothing in Viewpoint's view; its lines go on the card instead.
local function hideInfoPanel(player)
    pcall(function()
        local p = ISMoveableInfoWindow.infoPanels[player:getPlayerNum()]
        if p and p:getIsVisible() then p:setVisible(false) end
    end)
end

local function readInfo(cursor, square, player, m)
    local key = tostring(square) .. "|" .. tostring(cursor.origSpriteName) .. "|" .. tostring(cursor.canCreate) .. "|" .. m
        .. "|" .. tostring(cursor.cursorFacing or cursor.joypadFacing) .. "|" .. tostring(cursor.objectIndex)
    if state.infoKey == key then return end
    state.infoKey = key
    state.info = nil
    if not cursor.currentMoveProps or not square then return end
    local ok, info = pcall(cursor.currentMoveProps.getInfoPanelDescription, cursor.currentMoveProps, square, cursor.cacheObject, player, m)
    if ok and type(info) == "table" then state.info = info end
end

-- Per tick from the controller. Returns true while move mode runs.
function MoveMode.tick(player, now, Input)
    local cursor = MoveMode.cursor(player)
    if not cursor then
        if state then MoveMode.stop(false) end
        return false
    end
    if not state or state.cursor ~= cursor then
        Preview.clearTiles()
        state = { cursor = cursor, player = player }
    end
    if Input.pressed("cancel") then
        MoveMode.stop(true)
        return false
    end
    local m = mode(player)
    state.mode = m

    -- turning: the game's own turn for the mode (the joypad's), a wheel notch a step
    local notches = tonumber(Bridge.takeWheel()) or 0
    if notches ~= 0 then
        for _ = 1, math.min(math.abs(notches), 4) do
            if m == "place" then
                pcall(cursor.rotateWhilePlacing, cursor)
            elseif m == "rotate" then
                pcall(cursor.rotateKey, cursor, 0, true)
            else
                -- pick up / scrap / repair: the next object on the square (the game's Rotate key does the same)
                cursor.objectIndex = (cursor.objectIndex or 1) + (notches > 0 and 1 or -1)
                cursor.objectListCache = nil
            end
        end
    end

    local square, reason = aimSquare(player, m)
    state.square = square
    state.reason = reason
    if not square then
        state.valid = false
        unhide()
        Preview.clearTiles()
        hideInfoPanel(player)
        MoveMode.updateCard()
        return true
    end

    local okV, valid = pcall(Preview.withoutTiles, cursor.isValid, cursor, square)
    if not okV then
        Log.once(Log.ERROR, "moveValid", "furniture check failed: " .. tostring(valid))
        valid = false
    end
    state.valid = valid == true and cursor.canCreate == true
    hideInfoPanel(player)
    readInfo(cursor, square, player, m)

    -- the piece where it will stand; on a raised surface (a lamp on a table)
    -- only the ring, as the preview tile would stand on the floor
    local raised = (tonumber(cursor.yOffset) or 0) ~= 0
    if (m == "place" or m == "rotate") and cursor.objectSprite and not raised and not busy(player) and Preview.available() then
        if m == "rotate" and type(cursor.objectListCache) == "table" and cursor.objectListCache.object then
            pcall(cursor.setObjectHiddenDuringRotate, cursor, cursor.objectListCache.object)
        end
        Preview.showTiles(footprint(cursor, square))
    else
        unhide()
        Preview.clearTiles()
    end

    if Input.pressed("interact") then
        if state.valid then
            Preview.clearTiles()
            unhide()
            local ok, err = pcall(cursor.tryBuild, cursor, square:getX(), square:getY(), square:getZ())
            if not ok then Log.error("moving furniture failed: " .. tostring(err)) end
            state.infoKey = nil
        else
            VPUI.Controller.toast(T.moveCannot, 1.5, true)
        end
    end
    MoveMode.updateCard()
    return true
end

---------------------------------------------------------------------------
-- Card under the crosshair, outline on the floor
---------------------------------------------------------------------------

local VPElement = VPUI.UI.VPElement
local Card = VPElement:derive("VPMoveCard")

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

local MODE_TEXT = { pickup = "movePickup", place = "movePlace", rotate = "moveRotate", scrap = "moveScrap", repair = "moveRepair" }

function Card:render()
    local s = state
    if not s or not s.cursor then return end
    local cursor = s.cursor
    local c = s.valid and C.good or C.danger
    -- outline of the tiles on the floor
    if s.square then
        for _, t in ipairs(footprint(cursor, s.square)) do
            local z = t.z + 0.01
            local a, b2, c2, d = proj(t.x, t.y, z, 0), proj(t.x + 1, t.y, z, 0), proj(t.x + 1, t.y + 1, z, 0), proj(t.x, t.y + 1, z, 0)
            line(self, a, b2, c); line(self, b2, c2, c); line(self, c2, d, c); line(self, d, a, c)
        end
    end
    local font, small = Theme.font(), Theme.smallFont()
    local name = cursor.currentMoveProps and MoveMode.displayName(cursor.currentMoveProps) or (T[MODE_TEXT[s.mode] or "movePickup"])
    local title = (T[MODE_TEXT[s.mode] or "movePickup"] or "") .. (cursor.currentMoveProps and (": " .. name) or "")
    local stateText
    if s.reason == "far" then stateText = T.place_far
    elseif not s.square or not cursor.currentMoveProps then stateText = T.moveNothing
    elseif s.valid then stateText = T.moveReady
    else stateText = T.moveCannot end
    local hint = string.format(T.moveHint, VPUI.Input.label("interact"), VPUI.Input.label("cancel"))
    -- the game's own requirement lines (weight, tools, skill), first few
    local lines = {}
    for i, l in ipairs(s.info or {}) do
        if i > 6 then break end
        local txt = ""
        for _, part in ipairs(l) do txt = txt .. tostring(part.txt or "") .. " " end
        local last = l[#l]
        table.insert(lines, { text = txt, r = (last and last.r or 255) / 255, g = (last and last.g or 255) / 255, b = (last and last.b or 255) / 255 })
    end
    local w = math.max(Theme.textWidth(font, title), Theme.textWidth(small, hint), Theme.textWidth(small, stateText)) + Theme.px(20)
    for _, l in ipairs(lines) do w = math.max(w, Theme.textWidth(small, l.text) + Theme.px(20)) end
    local fh = Theme.fontHeight(small)
    local hgt = Theme.fontHeight(font) + fh * (2 + #lines) + Theme.px(18)
    local cx, cy = Theme.screenCenter()
    local x, y = cx - w / 2, cy + Theme.px(40)
    self:panel(x, y, w, hgt)
    self:fill(x, y, Theme.px(2), hgt, c)
    self:text(title, x + Theme.px(10), y + Theme.px(5), C.text, font)
    local ty = y + Theme.px(6) + Theme.fontHeight(font)
    self:text(stateText, x + Theme.px(10), ty, c, small)
    ty = ty + fh + Theme.px(2)
    for _, l in ipairs(lines) do
        self:drawText(l.text, x + Theme.px(10), ty, l.r, l.g, l.b, 0.9, small)
        ty = ty + fh
    end
    self:text(hint, x + Theme.px(10), ty + Theme.px(2), C.dim, small)
end

function Card:layout()
    self:place(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    self.dirty = false
end

function MoveMode.updateCard()
    if not MoveMode.card then MoveMode.card = Card:new() end
    if MoveMode.card.dirty then MoveMode.card:layout() end
    MoveMode.card:display(state ~= nil)
end

return MoveMode
