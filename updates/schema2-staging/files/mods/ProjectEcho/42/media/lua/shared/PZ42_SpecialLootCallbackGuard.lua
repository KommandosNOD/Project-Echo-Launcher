-- Project Zomboid B42.20+ / local server compatibility shim.
-- Restores ONE B41 callback referenced by some outdated item scripts.
-- DOES NOT change any loot tables, inventories, or other mods.
SpecialLootSpawns = SpecialLootSpawns or {}

if SpecialLootSpawns.OnCreateSodaCan == nil then
    function SpecialLootSpawns.OnCreateSodaCan(item)
        if item == nil or item.getFluidContainer == nil then
            return
        end

        -- B42 ItemCodeOnCreate.onCreateSodaCan assumes a non-nil FluidContainer.
        -- Do not delegate old/incorrect item definitions that lack the component.
        local ok, fluidContainer = pcall(function()
            return item:getFluidContainer()
        end)
        if not ok or fluidContainer == nil then
            return
        end

        if ItemCodeOnCreate ~= nil and ItemCodeOnCreate.onCreateSodaCan ~= nil then
            local success, err = pcall(function()
                ItemCodeOnCreate.onCreateSodaCan(item)
            end)
            if not success then
                print('[PZ42-CallbackGuard] Soda handler rejected item: ' .. tostring(err))
            end
        end
    end
    print('[PZ42-CallbackGuard] Installed SpecialLootSpawns.OnCreateSodaCan')
end
