--
-- Viewpoint UI - first/third person build mode.
--
-- The game places buildings through a "drag" cursor (ISBuildIsoEntity and the
-- other ISBuildingObject cursors) that it drives from IsoCell.render via
-- OnDoTileBuilding2, using the isometric mouse tile. Viewpoint replaces
-- IsoCell.render, so in Viewpoint's view that event never fires: vanilla cursors
-- neither follow the aim nor place anything. Build mode drives the very same
-- cursor object instead, doing what DoTileBuilding (ISBuildingObject.lua) does:
--
--   square from the aim  ->  cursor:isValid(square) (with auto-rotate)  ->
--   on Interact: cursor:tryBuild(x, y, z)
--
-- so every rule, material check, safehouse rule, timed action and server-side
-- validation stays the game's. The ghost is drawn as an outline of the tiles the
-- object will occupy, projected with Viewpoint's camera (the game's sprite ghost
-- is an isometric draw that Viewpoint's renderer does not show).
--
-- Rotate with the game's Rotate Building key; Interact places; the close key
-- (Backspace) or the build key again leaves build mode.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/Building/Preview"

local VPUI = ViewpointUI
VPUI.Building = VPUI.Building or {}
if VPUI.Building.BuildMode then return end

local Log = VPUI.Log
local Bridge = VPUI.Bridge
local Theme = VPUI.UI.Theme
local C = Theme.color
local T = VPUI.Text
local Preview = VPUI.Building.Preview

local BuildMode = {}
VPUI.Building.BuildMode = BuildMode

local state = nil   -- { logic, cursor, recipe, x, y, z, square, nextRefresh }

function BuildMode.isActive()
    return state ~= nil
end

local function tool(input, inventory)
    -- ISBuildPanel's local getTool: first owned item type that satisfies the tool input
    if not input then return nil end
    local list = input:getPossibleInputItems()
    for m = 0, list:size() - 1 do
        local found = inventory:getAllTypeEvalRecurse(list:get(m):getFullName(), ISBuildIsoEntity.predicateMaterial)
        if found:size() > 0 then return found:get(0):getFullType() end
    end
    return nil
end

-- Builds the cursor for the logic's selected recipe exactly as
-- ISBuildPanel:createBuildIsoEntity does.
local function makeCursor(player, logic)
    local info = logic:getSelectedBuildObject()
    local recipe = logic:getRecipe()
    local covering = logic:getWallCoveringParams()
    if info ~= nil and recipe ~= nil then
        local containers = ISInventoryPaneContextMenu.getContainers(player)
        local cursor = ISBuildIsoEntity:new(player, info, 1, containers, logic)
        cursor.dragNilAfterPlace = false
        cursor.blockAfterPlace = true
        local inventory = player:getInventory()
        cursor.equipBothHandItem = tool(recipe:getToolBoth(), inventory)
        cursor.firstItem = tool(recipe:getToolRight(), inventory)
        cursor.secondItem = tool(recipe:getToolLeft(), inventory)
        return cursor
    elseif covering ~= nil and recipe ~= nil then
        if covering.actionType == WallCoveringType.WALLPAPER then
            return ISPaperCursor:new(player, covering.wallpaperType, WallPaper["wall"][covering.wallpaperType])
        end
        return ISPaintCursor:new(player, covering.actionType:toString(), covering)
    end
    return nil
end

local function updateBlock(player)
    local cursor, logic = state.cursor, state.logic
    if cursor.blockBuild == nil and not cursor.objectInfo then return end
    local can = player:isBuildCheat()
    if not can then
        local ok, v = pcall(function() return logic:canPerformCurrentRecipe() end)
        can = ok and v == true
    end
    if logic:isCraftActionInProgress() then can = false end
    cursor.blockBuild = not can
    state.missing = not can
end

function BuildMode.start(player, logic)
    BuildMode.stop()
    local ok, cursor = pcall(makeCursor, player, logic)
    if not ok or not cursor then
        Log.error("could not create the build cursor: " .. tostring(cursor))
        return false
    end
    getCell():setDrag(cursor, player:getPlayerNum())
    state = { logic = logic, cursor = cursor, recipe = logic:getRecipe(), nextRefresh = 0, player = player }
    updateBlock(player)
    VPUI.Events.fire("BuildModeStarted", state.recipe)
    Log.debug("build mode: " .. tostring(state.recipe and state.recipe:getName()))
    return true
end

function BuildMode.stop()
    if not state then return end
    local pn = state.player:getPlayerNum()
    if getCell():getDrag(pn) == state.cursor then getCell():setDrag(nil, pn) end
    state = nil
    Preview.clearTiles()
    if BuildMode.ghost then BuildMode.ghost:display(false) end
    VPUI.Events.fire("BuildModeStopped")
end

-- The tile in front of the surface the crosshair hits: step back a little along
-- the aim ray so a wall face or a floor resolves to the square the player sees.
-- The tile in front of the surface the crosshair hits: step back a little along
-- the aim ray so a wall face or a floor resolves to the square the player sees.
-- A hit on the preview itself is looked through (Preview.Aim.buildPoint).
local function aimSquare()
    local hx, hy, hz, dx, dy, du = Preview.Aim.buildPoint()
    if not hx then return nil end
    local back = 0.05
    local x = math.floor(hx - dx * back)
    local y = math.floor(hy - dy * back)
    local z = math.floor(hz - du * back + 0.001)
    if z < 0 then z = 0 end
    local square = getCell():getGridSquare(x, y, z)
    if square == nil and getWorld():isValidSquare(x, y, z) then
        square = getCell():createNewGridSquare(x, y, z, true)
    end
    return square, x, y, z
end

local function validate(cursor, square)
    local valid = cursor:isValid(square, cursor.north)
    if not valid and cursor.craftRecipe and cursor.craftRecipe:isAutoRotate() then
        local keep = cursor.nSprite
        for i = 1, 4 do
            cursor.nSprite = i
            cursor:getSprite()
            if cursor:isValid(square, cursor.north) then
                return true
            end
        end
        cursor.nSprite = keep
        cursor:getSprite()
    end
    return valid == true
end

-- Per tick from the controller. Returns true while build mode is running.
function BuildMode.tick(player, now, Input)
    if not state then return false end
    local pn = player:getPlayerNum()
    local cursor = state.cursor
    if getCell():getDrag(pn) ~= cursor then
        -- something else replaced or cleared the cursor
        state = nil
        Preview.clearTiles()
        if BuildMode.ghost then BuildMode.ghost:display(false) end
        return false
    end
    if Input.pressed("cancel") or Input.pressed("build") then
        -- the build key's release still reaches OnKeyPressed; don't let it reopen the tab
        if Input.pressed("build") then BuildMode.swallowBuildKey = true end
        BuildMode.stop()
        return false
    end
    if now >= state.nextRefresh then
        state.nextRefresh = now + 500
        pcall(function()
            state.logic:setContainers(ISInventoryPaneContextMenu.getContainers(player))
            if not state.logic:isManualSelectInputs() then state.logic:autoPopulateInputs() end
        end)
        updateBlock(player)
    end
    local square, x, y, z = aimSquare()
    state.square, state.x, state.y, state.z = square, x, y, z
    if square then
        if cursor.ensureSquaresExist then pcall(cursor.ensureSquaresExist, cursor, x, y, z) end
        cursor.square = square
        -- the game's checks look at the square's objects: run them without the preview
        local ok, valid = pcall(Preview.withoutTiles, validate, cursor, square)
        cursor.canBeBuild = ok and valid
        if not ok then Log.once(Log.ERROR, "build-valid", "build validity check failed: " .. tostring(valid)) end
    else
        cursor.canBeBuild = false
    end
    if Input.pressed("interact") and square and cursor.canBeBuild then
        -- the preview leaves before the real thing goes up (the game walks
        -- there and checks the square again)
        Preview.clearTiles()
        local ok, err = pcall(cursor.tryBuild, cursor, x, y, z)
        if not ok then Log.error("placing failed: " .. tostring(err)) end
        state.nextRefresh = 0
    end
    BuildMode.updatePreview()
    BuildMode.updateGhost()
    return true
end

-- The object itself on its tiles (Preview): the game's sprites for the current
-- rotation, which Viewpoint draws in 3D where it has the model.
-- No preview while a build is under way: the game checks the square again
-- when the action ends (ISBuildIsoEntity:create calls isValid) and must not
-- find the preview there.
local function building(player)
    local ok, busy = pcall(function()
        if state.logic and state.logic:isCraftActionInProgress() then return true end
        return not player:getCharacterActions():isEmpty()
    end)
    return ok and busy == true
end

function BuildMode.updatePreview()
    if not state or not state.square or not Preview.available() or building(state.player) then
        Preview.clearTiles()
        return
    end
    local tiles = {}
    for _, t in ipairs(BuildMode.footprint()) do
        if t.sprite then table.insert(tiles, t) end
    end
    if #tiles == 0 and state.cursor and state.cursor.getSprite then
        -- cursors without a face (paint, wallpaper...): nothing to stand there
        Preview.clearTiles()
        return
    end
    Preview.showTiles(tiles)
end

-- Tiles the object will occupy: { x, y, z, wall = "N"|"W"|nil }
function BuildMode.footprint()
    if not state or not state.square then return {} end
    local cursor = state.cursor
    local tiles = {}
    local face = nil
    if cursor.getFace then
        local ok, f = pcall(cursor.getFace, cursor)
        if ok then face = f end
    end
    local wall = nil
    if cursor.isWallLike then wall = cursor.north and "N" or "W" end
    if face then
        for zz = 0, face:getzLayers() - 1 do
            for xx = 0, face:getWidth() - 1 do
                for yy = 0, face:getHeight() - 1 do
                    local info = face:getTileInfo(xx, yy, zz)
                    if info and (info:getSpriteName() or info:isBlocking()) then
                        table.insert(tiles, { x = state.x + xx, y = state.y + yy, z = state.z + zz, wall = wall,
                                              sprite = info:getSpriteName() })
                    end
                end
            end
        end
    end
    if #tiles == 0 then table.insert(tiles, { x = state.x, y = state.y, z = state.z, wall = wall }) end
    return tiles
end

-- Wall-likeness of the selected object, like ISBuildIsoEntity:render works it out.
local function computeWallLike()
    local cursor = state.cursor
    if not cursor.getFace then return end
    local ok = pcall(function()
        local face = cursor:getFace()
        if not face then return end
        local info = face:getTileInfo(0, 0, 0)
        if not info or not info:getSpriteName() then return end
        local props = getSprite(info:getSpriteName()):getProperties()
        cursor.isWallLike = props:has(IsoPropertyType.WALL_N) or props:has(IsoPropertyType.WALL_W)
            or props:has(IsoPropertyType.WALL_N_TRANS) or props:has(IsoPropertyType.WALL_W_TRANS)
            or props:has(IsoPropertyType.WINDOW_N) or props:has(IsoPropertyType.WINDOW_W)
            or props:has(IsoPropertyType.DOOR_WALL_N) or props:has(IsoPropertyType.DOOR_WALL_W)
    end)
    if not ok then cursor.isWallLike = nil end
end

-- Which way the object faces: the cursor's nSprite is 1..4 = W, N, E, S
-- (ISBuildIsoEntity:getFace converts it the same way).
local FACING = { [1] = { -1, 0, "W" }, [2] = { 0, -1, "N" }, [3] = { 1, 0, "E" }, [4] = { 0, 1, "S" } }
function BuildMode.facing()
    if not state or not state.cursor then return nil end
    local n = tonumber(state.cursor.nSprite)
    return n and FACING[n] or nil
end

-- The texture of a tile sprite, cached (getTexture takes sprite names, as
-- ISWorldObjectContextMenu does for the light switch).
local textures = {}
function BuildMode.texture(spriteName)
    if not spriteName then return nil end
    local t = textures[spriteName]
    if t == nil then
        local ok, tex = pcall(getTexture, spriteName)
        t = ok and tex or false
        textures[spriteName] = t
    end
    return t or nil
end

function BuildMode.status()
    if not state then return nil end
    local cursor = state.cursor
    local name = state.recipe and state.recipe:getTranslationName() or "?"
    local s
    if not state.square then
        s = "none"
    elseif state.missing then
        s = "missing"
    elseif cursor.canBeBuild then
        s = "valid"
    else
        s = "blocked"
    end
    return { name = name, state = s, x = state.x, y = state.y, z = state.z }
end

---------------------------------------------------------------------------
-- Ghost: projected outline of the footprint, plus a status card.
---------------------------------------------------------------------------

local VPElement = VPUI.UI.VPElement
local Ghost = VPElement:derive("VPBuildGhost")

function Ghost:new()
    local o = VPElement.new(self, getCore():getScreenWidth(), getCore():getScreenHeight())
    return o
end

-- Bridge.call takes at most two arguments; projection needs four, so call Native directly.
local function proj(x, y, z, lift)
    local native = VPUI.Native
    if not native or not native.project then return nil end
    local ok, visible = pcall(native.project, x, y, z, lift)
    if not ok or not visible then return nil end
    return native.projectedX(), native.projectedY()
end

local function line(ui, a, b, c)
    if not a or not b then return end
    ui:drawLine2(a[1], a[2], b[1], b[2], 0.9, c.r, c.g, c.b)
    ui:drawLine2(a[1] + 1, a[2], b[1] + 1, b[2], 0.6, c.r, c.g, c.b)
end

local function point(x, y, z, lift)
    local px, py = proj(x, y, z, lift)
    if not px then return nil end
    return { px, py }
end

function Ghost:render()
    local status = BuildMode.status()
    if not status then return end
    local c = status.state == "valid" and C.good or (status.state == "missing" and C.accent or C.danger)
    local tiles = BuildMode.footprint()
    -- the object itself is in the world (Preview); here only its outline on
    -- the floor in the state's colour
    for _, t in ipairs(tiles) do
        local x0, y0, x1, y1 = t.x, t.y, t.x + 1, t.y + 1
        local h = 0.95
        if t.wall == "N" then
            local a, b = point(x0, y0, t.z, 0), point(x1, y0, t.z, 0)
            local a2, b2 = point(x0, y0, t.z, h), point(x1, y0, t.z, h)
            line(self, a, b, c); line(self, a2, b2, c); line(self, a, a2, c); line(self, b, b2, c)
        elseif t.wall == "W" then
            local a, b = point(x0, y0, t.z, 0), point(x0, y1, t.z, 0)
            local a2, b2 = point(x0, y0, t.z, h), point(x0, y1, t.z, h)
            line(self, a, b, c); line(self, a2, b2, c); line(self, a, a2, c); line(self, b, b2, c)
        else
            local p1, p2, p3, p4 = point(x0, y0, t.z, 0), point(x1, y0, t.z, 0), point(x1, y1, t.z, 0), point(x0, y1, t.z, 0)
            line(self, p1, p2, c); line(self, p2, p3, c); line(self, p3, p4, c); line(self, p4, p1, c)
        end
    end
    -- status card under the crosshair
    local font = Theme.font()
    local small = Theme.smallFont()
    local cx, cy = Theme.screenCenter()
    local stateText = T["build_" .. status.state] or status.state
    local rotateKey = getCore():getKey(KeybindId.ROTATE_BUILDING)
    local hint = string.format(T.buildHint, VPUI.Input.label("interact"),
        (rotateKey and rotateKey > 0) and getKeyName(rotateKey) or "?", VPUI.Input.label("cancel"))
    local hgt = Theme.fontHeight(font) + Theme.fontHeight(small) * 2 + Theme.px(16)
    local tex = tiles[1] and BuildMode.texture(tiles[1].sprite)
    local pic = tex and hgt or 0
    local w = math.max(Theme.textWidth(font, status.name), Theme.textWidth(small, hint), Theme.textWidth(small, stateText)) + Theme.px(20) + pic
    local x, y = cx - w / 2, cy + Theme.px(40)
    self:panel(x, y, w, hgt)
    self:fill(x, y, Theme.px(2), hgt, c)
    if tex then
        -- the object as it will face
        pcall(self.drawTextureScaledAspect, self, tex, x + Theme.px(6), y + Theme.px(2), pic - Theme.px(8), hgt - Theme.px(4), 1, 1, 1, 1)
    end
    local tx = x + Theme.px(10) + pic
    self:text(status.name, tx, y + Theme.px(5), C.text, font)
    self:text(stateText, tx, y + Theme.px(6) + Theme.fontHeight(font), c, small)
    self:text(hint, tx, y + Theme.px(8) + Theme.fontHeight(font) + Theme.fontHeight(small), C.dim, small)
end

function Ghost:layout()
    self:place(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight())
    self.dirty = false
end

function BuildMode.updateGhost()
    if not BuildMode.ghost then BuildMode.ghost = Ghost:new() end
    if state and state.cursor and state.cursor.isWallLike == nil then computeWallLike() end
    if BuildMode.ghost.dirty then BuildMode.ghost:layout() end
    BuildMode.ghost:display(state ~= nil)
end
