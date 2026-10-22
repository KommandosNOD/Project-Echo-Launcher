-- PROJECT ECHO - Inventory Zoom Lock v0.1.0 TEST
-- Compatible with ViewpointUI 0.13.1, ProjectViewpointQOL and optional CameraPlus.
-- No wheel-event interception: preserve ViewpointUI's existing scrolling/input.
-- Client only. No Java binaries and no gameplay/network modifications.

if ProjectEchoInventoryZoomLock and ProjectEchoInventoryZoomLock.installed then return end

ProjectEchoInventoryZoomLock = ProjectEchoInventoryZoomLock or {}
local PE = ProjectEchoInventoryZoomLock
PE.installed = true
PE.version = "0.1.0"

local previousAPI = nil
local ourProxy = nil
local originalAvailable = nil
local originalFov = nil
local lastBlocked = false
local cameraPlusControlled = false
local lastCameraPlusApply = 0
local loggedReady = false
local loggedMissing = false

local function hubOpen()
    local ui = ViewpointUI
    local hub = ui and ui.Hub
    if not (hub and type(hub.isOpen) == "function") then return false end
    local ok, value = pcall(hub.isOpen)
    return ok and value == true
end

local function quickLootOpen()
    local ui = ViewpointUI
    local ql = ui and ui.Interaction and ui.Interaction.QuickLoot
    if not (ql and type(ql.shown) == "function") then return false end
    local ok, value = pcall(ql.shown)
    return ok and value == true
end

-- Vanilla inventory windows are UI elements; their own wheel handlers stay intact.
-- Only protect when the pointer is actually above the window.
local function mouseOverInventoryWindow(getPage)
    if type(getPage) ~= "function" then return false end
    local ok, page = pcall(getPage, 0)
    if not ok or not page then return false end
    if type(page.getIsVisible) ~= "function" then return false end
    local visOk, visible = pcall(page.getIsVisible, page)
    if not visOk or not visible or page.isCollapsed == true then return false end
    if type(page.isMouseOver) ~= "function" then return false end
    local mouseOk, hovered = pcall(page.isMouseOver, page)
    return mouseOk and hovered == true
end

function PE.shouldBlockZoom()
    if hubOpen() or quickLootOpen() then return true end
    if mouseOverInventoryWindow(getPlayerInventory) then return true end
    if mouseOverInventoryWindow(getPlayerLoot) then return true end
    return false
end

-- QOL's wheel listener calls ViewpointQOLZoom.isAvailable() before 3rd-person zoom,
-- and ViewpointQOLZoom.zoomFov() for Ctrl+wheel. Protect ONLY these entry points.
-- Java-exposed ViewpointQOLZoom may be a class rather than a writable Lua table;
-- a transparent Lua proxy avoids modifying that class or any third-party file.
local function installQOLGuard()
    local api = ViewpointQOLZoom
    if not api or api == ourProxy then return end
    local ok, available = pcall(function() return api.isAvailable end)
    if not ok or type(available) ~= "function" then return end

    local fovOk, fov = pcall(function() return api.zoomFov end)
    if not fovOk then fov = nil end

    local proxy = {}
    setmetatable(proxy, {
        __index = function(_, key) return api[key] end,
    })
    proxy.isAvailable = function(...)
        if PE.shouldBlockZoom() then return false end
        return available(...)
    end
    if type(fov) == "function" then
        proxy.zoomFov = function(...)
            if PE.shouldBlockZoom() then return end
            return fov(...)
        end
    end

    previousAPI = api
    originalAvailable = available
    originalFov = fov
    ourProxy = proxy
    ViewpointQOLZoom = proxy
    PE.qolGuardInstalled = true
    print("[PE-InventoryZoomLock] ViewpointQOLZoom guard installed")
end

local function getCameraPlusWheelSetting()
    if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions) then return nil end
    local ok, options = pcall(PZAPI.ModOptions.getOptions, PZAPI.ModOptions, "CameraPlus")
    if not ok or not options or type(options.getOption) ~= "function" then return nil end
    local optOk, option = pcall(options.getOption, options, "wheel")
    if not optOk or not option or type(option.getValue) ~= "function" then return nil end
    local valOk, value = pcall(option.getValue, option)
    if not valOk then return nil end
    return value == true or value == 1
end

-- CameraPlus handles the wheel in Java and does not use OnMouseWheel's Lua
-- event. Temporarily disable ONLY its runtime wheel flag while inventory/loot
-- is shown. Read the saved ModOptions choice on restore, without changing or
-- saving the option. (Do not override the player's F7 wheel-lock preference.)
local function setCameraPlusWheel(value)
    local api = CameraPlus
    if not api or type(api.set) ~= "function" then return false end
    local ok, err = pcall(api.set, "wheel", value and 1 or 0)
    if not ok then
        if not PE.cameraPlusErrorLogged then
            PE.cameraPlusErrorLogged = true
            print("[PE-InventoryZoomLock] CameraPlus set failed: " .. tostring(err))
        end
        return false
    end
    return true
end

local function updateCameraPlus(now, blocked)
    local desired = getCameraPlusWheelSetting()
    if desired == nil then return end

    if blocked then
        if not cameraPlusControlled or now - lastCameraPlusApply >= 100 then
            if setCameraPlusWheel(false) then
                cameraPlusControlled = true
                lastCameraPlusApply = now
            end
        end
    elseif cameraPlusControlled then
        if setCameraPlusWheel(desired) then cameraPlusControlled = false end
    end
end

local function restoreCameraPlus()
    if not cameraPlusControlled then return end
    local desired = getCameraPlusWheelSetting()
    if desired ~= nil and setCameraPlusWheel(desired) then
        cameraPlusControlled = false
    end
end

local function tick()
    if not loggedReady then
        loggedReady = true
        print("[PE-InventoryZoomLock] active v" .. PE.version .. " (client; zoom guard only)")
    end
    if ViewpointQOLZoom ~= ourProxy then
        local ok, err = pcall(installQOLGuard)
        if not ok and not loggedMissing then
            loggedMissing = true
            print("[PE-InventoryZoomLock] QOL guard setup failed: " .. tostring(err))
        end
    end

    local blocked = PE.shouldBlockZoom()
    local now = (getTimestampMs and getTimestampMs()) or 0
    updateCameraPlus(now, blocked)
    if blocked ~= lastBlocked then
        lastBlocked = blocked
        PE.isZoomLocked = blocked
        -- No per-frame logs; report only transitions for testing.
        print("[PE-InventoryZoomLock] zoom " .. (blocked and "LOCKED (inventory)" or "UNLOCKED (world)"))
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(tick)
end
if Events and Events.OnGameExit then
    Events.OnGameExit.Add(restoreCameraPlus)
end
