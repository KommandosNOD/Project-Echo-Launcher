--
-- Viewpoint UI - vehicle tab: seats, condition and storage of the vehicle being
-- aimed at or sat in.
--
-- Seats are chosen the way the vanilla seat picker does it
-- (ISVehicleSeatUI:useSeat: switch when the seat is reachable from inside,
-- otherwise exit and walk round; items on a seat are moved off first). Values
-- shown are read from the vehicle's parts (VehiclePartOwner, VehiclePart) as the
-- vanilla mechanics window and dashboard read them. Mechanics opens the game's
-- own mechanics window (FALLBACK in the legacy policy).
--

require "ViewpointUI/Core"
require "ViewpointUI/UI/Theme"
require "ViewpointUI/UI/Region"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Legacy"

local VPUI = ViewpointUI
VPUI.Screens = VPUI.Screens or {}
if VPUI.Screens.Vehicle then return end

local Theme = VPUI.UI.Theme
local C = Theme.color
local Region = VPUI.UI.Region
local T = VPUI.Text
local Log = VPUI.Log

local Vehicle = {}
Vehicle.__index = Vehicle
VPUI.Screens.Vehicle = Vehicle

Vehicle.lastVehicle = nil

local NEAR_TILES = 8        -- an aimed-at vehicle counts while you stay this close
local MECHANICS_TILES = 15  -- further than this, Mechanics asks you to get closer

local function distance(player, vehicle)
    local dx = vehicle:getX() - player:getX()
    local dy = vehicle:getY() - player:getY()
    return math.sqrt(dx * dx + dy * dy)
end

local function usable(vehicle)
    if not vehicle then return false end
    local ok, removed = pcall(function() return vehicle:isRemovedFromWorld() end)
    if ok and removed then return false end
    return true
end

-- The vehicle the tab is about: the one you sit in, the one the game itself
-- would interact with (ISVehicleMenu.getVehicleToInteractWith: useable or near,
-- the same as the vanilla V radial), or the one you last aimed at while it is
-- still close. nil when no vehicle is around, so the tab hides.
function Vehicle.current(player)
    if not player then return nil end
    local v = player:getVehicle()
    if v then return v end
    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
        local ok, near = pcall(ISVehicleMenu.getVehicleToInteractWith, player)
        if ok and near and usable(near) then return near end
    end
    local last = Vehicle.lastVehicle
    if usable(last) then
        local ok, d = pcall(distance, player, last)
        if ok and d <= NEAR_TILES then return last end
    end
    return nil
end

function Vehicle.seatName(vehicle, seat)
    local name = "Seat" .. tostring(vehicle:getScript():getPassenger(seat):getId())
    return getTextOrNull("IGUI_" .. name) or name
end

function Vehicle.seats(player, vehicle)
    local rows = {}
    local mySeat = vehicle:getSeat(player)
    for seat = 0, vehicle:getMaxPassengers() - 1 do
        local status, free = nil, false
        if not vehicle:isSeatInstalled(seat) then
            status = getText("IGUI_VehicleSeat_Uninstalled")
        elseif seat == mySeat then
            status = getText("IGUI_VehicleSeat_Self")
        elseif vehicle:getCharacter(seat) then
            status = getText("IGUI_VehicleSeat_Person")
        elseif vehicle:isSeatOccupied(seat) then
            status = getText("IGUI_VehicleSeat_Items")
            free = true
        else
            free = true
            if mySeat ~= -1 and not vehicle:canSwitchSeat(mySeat, seat) then
                status = getText("IGUI_VehicleSeat_ExitToSwitch")
            end
        end
        table.insert(rows, { key = "seat" .. tostring(seat), seat = seat, name = Vehicle.seatName(vehicle, seat),
                             status = status, free = free, mine = seat == mySeat })
    end
    return rows
end

-- ISVehicleSeatUI:useSeat, step for step.
function Vehicle.useSeat(player, vehicle, seat)
    if not vehicle:isSeatInstalled(seat) or vehicle:getCharacter(seat) then return end
    if player:getVehicle() then
        if vehicle:canSwitchSeat(vehicle:getSeat(player), seat) then
            local part = vehicle:getPartForSeatContainer(seat)
            local cont = part and part:getItemContainer()
            if cont and cont:getCapacityWeight() > cont:getCapacity() / 4
                    and not ISVehicleMenu.moveItemsFromSeat(player, vehicle, seat, true, false) then
                return
            end
            ISVehicleMenu.onSwitchSeat(player, seat)
        else
            ISVehicleMenu.onExit(player)
            ISVehicleMenu.onEnter(player, vehicle, seat)
        end
    else
        ISVehicleMenu.onEnter(player, vehicle, seat)
    end
end

local function percent(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

function Vehicle.info(vehicle)
    local lines = {}
    local function add(label, value, state) table.insert(lines, { label = label, value = value, state = state }) end
    local function partCondition(id)
        local part = vehicle:getPartById(id)
        if part then return part:getCondition() end
        return nil
    end
    local engine = partCondition("Engine")
    if engine then add(getText("IGUI_VehiclePartEngine"), tostring(engine) .. "%", engine < 30 and "bad" or nil) end
    add(T.vehEngineQuality, tostring(vehicle:getEngineQuality()))
    local tank = vehicle:getPartById("GasTank")
    if tank and tank:isContainer() and tank:getContainerCapacity() > 0 then
        local f = tank:getContainerContentAmount() / tank:getContainerCapacity()
        add(getText("IGUI_VehiclePartGasTank"), percent(f), f < 0.15 and "bad" or nil)
    end
    local battery = vehicle:getBatteryCharge()
    if battery then add(getText("IGUI_VehiclePartBattery"), percent(battery), battery < 0.15 and "bad" or nil) end
    for _, id in ipairs({ "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }) do
        local tire = vehicle:getPartById(id)
        if tire then
            if tire:getInventoryItem() then
                local text = tostring(tire:getCondition()) .. "%"
                if tire:getContainerCapacity() > 0 then
                    text = text .. "  " .. string.format("%d/%d", math.floor(tire:getContainerContentAmount()), tire:getContainerCapacity())
                end
                add(getText("IGUI_VehiclePart" .. id), text, tire:getCondition() < 30 and "bad" or nil)
            else
                add(getText("IGUI_VehiclePart" .. id), T.vehMissing, "bad")
            end
        end
    end
    return lines
end

function Vehicle.create(screen)
    local self = setmetatable({}, Vehicle)
    self.screen = screen
    self.nextRead = 0
    self.seatList = Region.List.new({
        rowHeight = function() return Theme.fontHeight(Theme.font()) + Theme.fontHeight(Theme.smallFont()) + Theme.px(10) end,
        drawRow = function(ui, row, x, y, w, h)
            local c = row.mine and C.accent or (row.free and C.text or C.off)
            ui:drawText(row.name, x + Theme.px(8), y + Theme.px(4), c.r, c.g, c.b, 1, Theme.font())
            if row.status then
                ui:drawText(row.status, x + Theme.px(8), y + Theme.px(4) + Theme.fontHeight(Theme.font()), C.dim.r, C.dim.g, C.dim.b, 1, Theme.smallFont())
            end
        end,
        onActivate = function(row) self:sit(row) end,
    })
    self.buttons = {
        sit = Region.Button.new({ label = T.vehSit, accent = true, onClick = function()
            local rows = self.seatList:selectedRows()
            if rows[1] then self:sit(rows[1]) end
        end, enabled = function()
            local rows = self.seatList:selectedRows()
            return rows[1] ~= nil and rows[1].free
        end }),
        storage = Region.Button.new({ label = T.vehStorage, onClick = function() self:storage() end }),
        mechanics = Region.Button.new({ label = T.vehMechanics, onClick = function() self:mechanics() end }),
    }
    return self
end

function Vehicle:open(args)
    local player = VPUI.Util.player()
    self.vehicle = (args and args.vehicle) or Vehicle.current(player)
    self.nextRead = 0
end

function Vehicle:update(now)
    if now < self.nextRead then return end
    self.nextRead = now + 500
    local player = VPUI.Util.player()
    if not player then return end
    -- follow the vehicle you are in / next to; drop one that went away
    local cur = Vehicle.current(player)
    if cur ~= self.vehicle then
        self.vehicle = cur
        self.seatList:setRows({})
        self.lines = {}
    end
    if not self.vehicle then return end
    local ok, rows = pcall(Vehicle.seats, player, self.vehicle)
    if ok then self.seatList:setRows(rows) else Log.once(Log.ERROR, "veh-seats", "reading seats failed: " .. tostring(rows)) end
    local okI, info = pcall(Vehicle.info, self.vehicle)
    self.lines = okI and info or {}
    local okN, name = pcall(ISVehicleMenu.getVehicleDisplayName, self.vehicle)
    self.name = okN and name or "?"
end

function Vehicle:sit(row)
    local player = VPUI.Util.player()
    if not player or not row or not row.free then return end
    VPUI.Hub.close()
    local ok, err = pcall(Vehicle.useSeat, player, self.vehicle, row.seat)
    if not ok then Log.error("choosing a seat failed: " .. tostring(err)) end
end

function Vehicle:storage()
    VPUI.Hub.open("inventory", {})
end

-- Watches a mechanics request: the game walks to the hood (opening it, with
-- the key if it is locked) and then opens the window. If the walk is given up
-- without the window appearing, say so instead of silently doing nothing.
local watch = nil

local function mechanicsWindow(player)
    local ok, ui = pcall(getPlayerMechanicsUI, player:getPlayerNum())
    if ok and ui then
        local okV, v = pcall(function() return ui:isReallyVisible() end)
        return okV and v == true
    end
    return false
end

local function watchTick()
    if not watch then return end
    local player = VPUI.Util.player()
    local now = VPUI.Util.now()
    if not player or mechanicsWindow(player) or now > watch.untilMs then
        watch = nil
        return
    end
    local queue = ISTimedActionQueue.queues[player]
    local busy = queue and queue.queue and #queue.queue > 0
    if busy then
        watch.sawQueue = true
    elseif now - watch.startedMs > 1500 then
        watch = nil
        VPUI.Controller.toast(T.vehMechanicsFailed, 4, true)
    end
end
Events.OnTick.Add(function() pcall(watchTick) end)

-- ISOpenMechanicsUIAction:waitToStart (and ISOpenVehicleDoor's, for the hood)
-- turns the character to face the vehicle
-- and waits until it stops turning (shouldBeTurning). In first and third person
-- Viewpoint steers the facing with the mouse, so the turn never finishes and
-- the window never opens. The queued action is told not to wait for the turn
-- (instance fields only; the game's class is untouched).
function Vehicle.unblockMechanics(player)
    local queue = ISTimedActionQueue.queues[player]
    for _, action in ipairs(queue and queue.queue or {}) do
        if action.Type == "ISOpenMechanicsUIAction" then
            action.waitToStart = function() return false end
            action.update = function() end
        elseif action.Type == "ISOpenVehicleDoor" and action.part and action.part:getId() == "EngineDoor" then
            -- opening the hood waits for the same turn (ISOpenVehicleDoor:waitToStart)
            action.waitToStart = function() return false end
        end
    end
end

function Vehicle:mechanics()
    local player = VPUI.Util.player()
    if not player or not self.vehicle then return end
    local vehicle = self.vehicle
    if not player:getVehicle() then
        local ok, d = pcall(distance, player, vehicle)
        if ok and d > MECHANICS_TILES then
            self.screen:notify(T.vehTooFar, 3, true)
            return
        end
    end
    VPUI.Hub.close()
    -- the mechanics window opens after walking to the hood; Legacy.alwaysFree
    -- frees the cursor whenever it is shown and gives mouse-look back when it closes
    VPUI.Legacy.openWindow(function()
        ISVehicleMenu.onMechanic(player, vehicle)
        Vehicle.unblockMechanics(player)
    end, 20000)
    watch = { startedMs = VPUI.Util.now(), untilMs = VPUI.Util.now() + 30000 }
end

function Vehicle:layout(x, y, w, h)
    self.area = { x = x, y = y, w = w, h = h }
    local headH = Theme.fontHeight(UIFont.Large) + Theme.px(16)
    local half = math.floor((w - Theme.px(24)) / 2)
    local btnH = Theme.fontHeight(Theme.font()) + Theme.px(10)
    self.seatList:layout(x, y + headH, half, h - headH - btnH - Theme.px(12))
    local by = y + h - btnH
    self.buttons.sit:layout(x, by, Theme.px(140), btnH)
    self.buttons.storage:layout(x + Theme.px(150), by, Theme.px(140), btnH)
    self.buttons.mechanics:layout(x + Theme.px(300), by, Theme.px(140), btnH)
    self.infoX = x + half + Theme.px(24)
    self.infoY = y + headH
    self.infoW = half
end

function Vehicle:render(ui, mx, my)
    local a = self.area
    if not self.vehicle then
        ui:drawText(T.vehNone, a.x, a.y, C.off.r, C.off.g, C.off.b, 1, Theme.font())
        return
    end
    ui:drawText(self.name or "", a.x, a.y, C.text.r, C.text.g, C.text.b, 1, UIFont.Large)
    self.seatList:draw(ui, mx, my)
    for _, b in pairs(self.buttons) do b:draw(ui, mx, my) end
    local y = self.infoY
    local lineH = Theme.fontHeight(Theme.font()) + Theme.px(6)
    for _, line in ipairs(self.lines or {}) do
        ui:drawText(line.label, self.infoX, y, C.dim.r, C.dim.g, C.dim.b, 1, Theme.font())
        local c = line.state == "bad" and C.danger or C.text
        ui:drawTextRight(line.value, self.infoX + self.infoW, y, c.r, c.g, c.b, 1, Theme.font())
        y = y + lineH
    end
end

function Vehicle:mouseDown(x, y, mods)
    for _, b in pairs(self.buttons) do if b:mouseDown(x, y) then return true end end
    return self.seatList:mouseDown(x, y, mods)
end
function Vehicle:mouseUp() self.seatList:mouseUp() end
function Vehicle:doubleClick(x, y, mods) return self.seatList:doubleClick(x, y, mods) end
function Vehicle:wheel(x, y, del) return self.seatList:wheel(x, y, del) end

VPUI.Hub.register({
    id = "vehicle",
    label = T.tabVehicle,
    order = 70,
    visible = function(player)
        return Vehicle.current(player) ~= nil
    end,
    create = Vehicle.create,
})
