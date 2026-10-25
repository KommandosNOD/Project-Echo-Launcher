-- PROJECT ECHO | Vehicle Sleep Recursion Fix v1.0.0
-- Targets the ISVehicleMenu.onSleep recursion seen with YouDriveISleep.
-- Do NOT delegate to the previous onSleep handler; it may have captured itself.
-- Reimplements the B42 sleep confirmation entry point, and leaves the
-- vanilla / Viewpoint onConfirmSleep callback untouched.
-- Client only. No world data or multiplayer packets are changed here.

require "Vehicles/ISUI/ISVehicleMenu"
require "ISUI/ISModalDialog"

local TAG = "[PE-VehicleSleepFix]"

local function fixedOnSleep(playerObj, vehicle)
    if not playerObj or not vehicle then return end
    if playerObj:isAsleep() then return end

    -- Vanilla B42 rule: a driver cannot initiate sleep in a moving car.
    -- Passengers may sleep while someone else drives (YouDriveISleep feature).
    if vehicle:isDriver(playerObj) and not vehicle:isStopped() then
        if HaloTextHelper and HaloTextHelper.addBadText then
            HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_CanNotSleepInMovingCar"))
        end
        return
    end

    local playerNum = playerObj:getPlayerNum()
    if playerNum == nil then return end
    local data = getPlayerData(playerNum)
    if not data then return end

    -- Match the author's B42 modal lifetime handling (avoid duplicate dialogs).
    if not data.vehicleSleepModal then
        if not ISVehicleMenu.onConfirmSleep then
            print(TAG .. " WARNING: onConfirmSleep is unavailable")
            return
        end

        local modal = ISModalDialog:new(
            0, 0, 250, 150,
            getText("IGUI_ConfirmSleep"),
            true, nil, ISVehicleMenu.onConfirmSleep,
            playerNum, playerNum, nil
        )
        if not modal then return end
        data.vehicleSleepModal = modal
        modal:initialise()
        modal:addToUIManager()
    end

    if JoypadState and JoypadState.players and JoypadState.players[playerNum + 1] then
        setJoypadFocus(playerNum, data.vehicleSleepModal)
    end
end

local function applyFix()
    if not ISVehicleMenu then return end
    if ISVehicleMenu.onSleep ~= fixedOnSleep then
        ISVehicleMenu.onSleep = fixedOnSleep
        print(TAG .. " installed: replaced recursive onSleep; preserved onConfirmSleep")
    end
end

-- Initial load plus a second pass after remaining mods initialize.
applyFix()
if Events and Events.OnGameStart then Events.OnGameStart.Add(applyFix) end
