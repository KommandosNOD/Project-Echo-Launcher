--
-- Viewpoint UI - discs and tapes into TVs and radios.
--
-- The game's device window (ISRadioWindow) takes media and batteries through
-- an ISItemDropBox: the vanilla inventory pane drags an item onto it. In first
-- or third person the inventory is the Viewpoint one, which cannot drag into
-- a game window, so a click on an empty box lists what you carry that fits
-- (the box's own verifyItem: the device's media type, batteries...) and the
-- pick goes through the box's own handler (RWMMedia.addMedia ->
-- addMediaAux: walk, transfer, ISDeviceMediaAction), exactly as a drop would.
--

require "ViewpointUI/Core"
require "ViewpointUI/Bridge"

local VPUI = ViewpointUI
VPUI.UI = VPUI.UI or {}
if VPUI.UI.DeviceMedia then return end

local DeviceMedia = {}
VPUI.UI.DeviceMedia = DeviceMedia

local Log = VPUI.Log

local function fits(box, player)
    local verify = box.onVerifyItem or box.defaultVerifyItem
    if not verify then return {} end
    local found = player:getInventory():getAllEvalRecurse(function(item)
        local ok, yes = pcall(verify, box.functionTarget, item)
        return ok and yes == true
    end)
    local list = {}
    for i = 0, found:size() - 1 do table.insert(list, found:get(i)) end
    return list
end

local function offer(box, x, y)
    local player = (box.functionTarget and box.functionTarget.player) or VPUI.Util.player()
    if not player then return false end
    local list = fits(box, player)
    if #list == 0 then return false end
    local context = ISContextMenu.get(player:getPlayerNum(), box:getAbsoluteX() + x, box:getAbsoluteY() + y)
    for _, item in ipairs(list) do
        context:addOption(item:getDisplayName(), box, function(b, it)
            if b.onItemDropped then b.onItemDropped(b.functionTarget, { it }) else b:itemDropped({ it }) end
        end, item)
    end
    return true
end

local function viewOn()
    return VPUI.Bridge and VPUI.Bridge.viewOn and VPUI.Bridge.viewOn() == true
end

local installed = false
function DeviceMedia.install()
    if installed or not ISItemDropBox then return end
    installed = true
    local original = ISItemDropBox.onMouseUp
    ISItemDropBox.onMouseUp = function(self, x, y)
        local empty = ISMouseDrag == nil or ISMouseDrag.dragging == nil
        if empty and viewOn() and self:getIsVisible() and self.mouseEnabled ~= false and not self.isLocked
                and (self.allowDropAlways or self.boxOccupied ~= true) then
            local ok, shown = pcall(offer, self, x, y)
            if not ok then Log.once(Log.WARN, "deviceMedia", "listing items for the device failed: " .. tostring(shown)) end
            if ok and shown then return end
        end
        return original(self, x, y)
    end
    Log.info("device media: a click on an empty media/battery box lists what fits")
end

Events.OnGameStart.Add(DeviceMedia.install)

return DeviceMedia
