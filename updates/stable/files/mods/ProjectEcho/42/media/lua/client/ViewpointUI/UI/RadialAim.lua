--
-- Viewpoint UI - radial menus steered by the mouse.
--
-- The game's radial menus (ISRadialMenu: the vehicle menu on V, emotes, the
-- firearm and hotbar wheels, and any mod's) are made for a free cursor. In
-- Viewpoint's view the mouse turns the camera, so a radial could only be used
-- after middle-clicking for the cursor. While one is open here, the mouse keeps
-- its capture and the camera holds still; moving the mouse moves an invisible
-- pointer round the menu, the game highlights the slice it points at, and
-- letting go of the key that opened the menu picks it (a click still works too,
-- the same click the game would get from a real cursor).
--
-- Lua finds the open menu and its geometry; the Java part (VP.radialMouse,
-- Patch_LookRead) moves the pointer and holds the camera. The flag expires on
-- its own within 0.3 s if this stops being refreshed.
--

require "ISUI/ISRadialMenu"
require "ViewpointUI/Core"
require "ViewpointUI/Settings"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.RadialAim then return end

local RadialAim = {}
VPUI.UI.RadialAim = RadialAim

local Log = VPUI.Log
local Bridge = VPUI.Bridge

local menus = {}       -- radial menus that were shown -> times shown (weak: they come and go)
local shown = 0
setmetatable(menus, { __mode = "k" })
local on = false

-- Note every radial menu as it is shown.
if ISRadialMenu then
    local own = rawget(ISRadialMenu, "addToUIManager")
    ISRadialMenu.addToUIManager = function(self, ...)
        shown = shown + 1
        menus[self] = shown   -- the game reuses one menu object; this tells openings apart
        -- the parent's version is looked up now, so later wrappers still apply
        local add = own or ISPanelJoypad.addToUIManager
        return add(self, ...)
    end
end

local function visible(menu)
    local ok, v = pcall(function() return menu:isReallyVisible() end)
    return ok and v == true
end

function RadialAim.openMenu()
    for menu in pairs(menus) do
        if visible(menu) then return menu end
    end
    return nil
end

local function send(active, cx, cy, inner, outer)
    local native = VPUI.Native
    local fn = native and native.setRadial
    if not fn then
        if active then
            Log.once(Log.WARN, "noSetRadial", "radial menus by mouse need the updated Java part (approve ViewpointUI in ZombieBuddy)")
        end
        return
    end
    local ok, err = pcall(fn, active, cx or 0, cy or 0, inner or 0, outer or 0)
    if not ok then Log.once(Log.ERROR, "setRadial", "setRadial failed: " .. tostring(err)) end
end

-- Keys pressed just before a menu opened are the keys that opened it (V for the
-- vehicle menu, a mod's key...). Releasing them picks the highlighted slice.
local downAt = {}
Events.OnKeyStartPressed.Add(function(key) downAt[key] = getTimestampMs() end)
local OPENER_MS = 700

local cur = nil        -- the open menu
local curGen = nil     -- which opening of it
local held = nil       -- keys that opened it, while still held
local lastCmd = nil    -- the highlighted slice's command { fn, args... }

local function openerKeys()
    local now = getTimestampMs()
    local keys = {}
    for key, t in pairs(downAt) do
        if now - t <= OPENER_MS and isKeyDown(key) then table.insert(keys, key) end
    end
    if #keys == 0 then return nil end
    return keys
end

local function allUp(keys)
    for _, key in ipairs(keys) do
        if isKeyDown(key) then return false end
    end
    return true
end

local function run(cmd)
    if not cmd or not cmd[1] then return end
    local ok, err = pcall(cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
    if not ok then Log.error("radial menu action failed: " .. tostring(err)) end
end

-- The command of the slice under the pointer (the game's own hit test,
-- RadialMenu.getSliceIndexFromMouse, with menu-relative coordinates as
-- ISRadialMenu:onMouseDown passes them).
local function highlighted(menu)
    local ok, cmd = pcall(function()
        local x = getMouseX() - menu:getAbsoluteX()
        local y = getMouseY() - menu:getAbsoluteY()
        local index = menu.javaObject:getSliceIndexFromMouse(x, y)
        if index == nil or index < 0 then return nil end
        return menu:getSliceCommand(index + 1)
    end)
    if ok then return cmd end
    return nil
end

-- Per tick. `interfaceActive`: Viewpoint's view is on and the interface runs.
function RadialAim.tick(interfaceActive)
    local menu = nil
    if interfaceActive and VPUI.Settings.get("radialMouse") == true and Bridge.ready()
            and Bridge.call("cursorFree", false) ~= true and not (VPUI.Hub and VPUI.Hub.isOpen()) then
        menu = RadialAim.openMenu()
    end
    if menu then
        if menu ~= cur or menus[menu] ~= curGen then
            cur = menu
            curGen = menus[menu]
            held = openerKeys()
            lastCmd = nil
        end
        local ok, cx, cy = pcall(function()
            return menu:getAbsoluteX() + menu:getWidth() / 2, menu:getAbsoluteY() + menu:getHeight() / 2
        end)
        if ok then
            send(true, cx, cy, menu.innerRadius or 0, menu.outerRadius or (menu:getWidth() / 2))
            on = true
        end
        lastCmd = highlighted(menu)
        -- the opening key let go while the menu is still up (key-toggle option,
        -- or a mod's menu that stays): pick the highlighted slice. With the
        -- pointer in the centre nothing is picked and the menu stays for a click.
        if held and allUp(held) then
            held = nil
            if lastCmd then
                local cmd = lastCmd
                lastCmd = nil
                pcall(function() menu:undisplay() end)
                run(cmd)
            end
        end
        return
    end
    if cur then
        -- the menu closed: when the game closed it because its key was let go
        -- (the hold-to-show menus), the highlighted slice is picked; a click or
        -- Esc closes it without that (the key is still held, or nothing was
        -- highlighted)
        if held and allUp(held) and lastCmd and not isMouseButtonDown(0) then
            run(lastCmd)
        end
        cur, held, lastCmd = nil, nil, nil
    end
    if on then
        send(false)
        on = false
    end
end

function RadialAim.isOn()
    return on
end
