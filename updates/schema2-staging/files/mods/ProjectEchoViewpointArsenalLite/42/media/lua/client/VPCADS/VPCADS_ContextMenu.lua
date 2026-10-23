-- Consume only world clicks owned by firearm click-ADS. Inventory menus are separate.
require "Context/ISContextManager"
local function install()
    local manager = ISContextManager.getInstance()
    if manager.VPCADS_worldMenuGuard then return end
    local original = manager.createWorldMenu
    manager.createWorldMenu = function(player, object, objects, x, y, test)
        if player == 0 and VPCADSJ and VPCADSJ.suppressWorldMenu then
            local ok, suppress = pcall(VPCADSJ.suppressWorldMenu)
            if ok and suppress then return end
        end
        return original(player, object, objects, x, y, test)
    end
    manager.VPCADS_worldMenuGuard = true
end
Events.OnGameStart.Add(install)
