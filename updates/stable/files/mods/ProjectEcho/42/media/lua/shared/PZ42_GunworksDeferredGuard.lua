-- B42.21 Gunworks / Guns of Marz: postpone inventory item replacement
-- while a connecting player's IsoGridSquare has not been assigned yet.
-- Original ItemSpawnCore.lua:31-45 sends ReplaceInventoryItemInContainer
-- even when player.square == nil, causing Java NullPointerException.
-- Use Gunworks' OWN deferred queue: no replacements are discarded.

local LOG = '[PZ42RuntimeFix02][Gunworks] '
local installed = false
local loggedFirstWait = false

local function install()
    if installed or not isServer or not isServer() then return end

    local ok, core = pcall(require, 'SpawnerSystems/ItemSpawnCore')
    if not ok or type(core) ~= 'table' or type(core.resolve) ~= 'function' then
        return
    end
    if core._pz42_runtime_guard02 then
        installed = true
        return
    end

    local previous = core.resolve
    core.resolve = function(item, entry, computeFn, queue, resolveFn)
        if item and item.getContainer then
            local container = item:getContainer()
            local parent = container and container:getParent()
            if parent and instanceof(parent, 'IsoPlayer')
                and parent:getSquare() == nil then
                if queue and queue.mark and resolveFn then
                    queue.mark(item, resolveFn)
                    if not loggedFirstWait then
                        loggedFirstWait = true
                        print(LOG .. 'Deferred replacement until player square exists')
                    end
                    return
                end
            end
        end
        return previous(item, entry, computeFn, queue, resolveFn)
    end

    core._pz42_runtime_guard02 = true
    installed = true
    print(LOG .. 'Deferred inventory replacement guard installed (server)')
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(install) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(install) end
install()
