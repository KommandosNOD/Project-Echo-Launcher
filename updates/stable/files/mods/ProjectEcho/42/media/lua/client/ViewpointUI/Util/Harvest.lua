--
-- Viewpoint UI - context-menu harvesting.
--
-- Many game features exist only as entries of a right-click menu (item actions,
-- medical treatments, mods' additions). Rather than re-implementing each one,
-- the game's own builder is run, its options are read, and the menu is hidden
-- before it is ever drawn. Choosing an entry later calls exactly the function
-- the game would have called on click (ISContextMenu:onMouseUp does
-- onSelect(target, param1..param10)). Viewpoint uses the same technique for
-- world objects.
--
-- Option fields read (client/ISUI/ISContextMenu.lua allocOption/addOption):
--   name, onSelect, target, param1..param10, subOption, notAvailable, isDisabled
--

require "ViewpointUI/Core"

local VPUI = ViewpointUI
VPUI.Util = VPUI.Util or {}
if VPUI.Util.Harvest then return end

local Harvest = {}
VPUI.Util.Harvest = Harvest

local Log = VPUI.Log

local function collect(menu, prefix, out, depth, skip)
    if depth > 4 then return end
    for i = 1, (menu.numOptions or 1) - 1 do
        local o = menu.options[i]
        if o and not o.isDefaultOption then
            local name = tostring(o.name or "?")
            local label = prefix and (prefix .. ": " .. name) or name
            if o.subOption then
                local sub = menu:getSubMenu(o.subOption)
                if sub and not sub:isEmpty() then collect(sub, label, out, depth + 1, skip) end
            elseif o.onSelect and not (skip and skip(o)) then
                local option = o
                table.insert(out, {
                    label = label,
                    enabled = not option.notAvailable and not option.isDisabled,
                    fn = option.onSelect,
                    args = { option.target, option.param1, option.param2, option.param3, option.param4, option.param5,
                             option.param6, option.param7, option.param8, option.param9, option.param10 },
                })
            end
        end
    end
end

-- Reads an ISContextMenu the game just built. Returns a list of
-- { label, enabled, run = fn() }. skip(option) may drop entries.
function Harvest.read(context, playerNum, skip)
    local out = {}
    if not context then return out end
    local ok, err = pcall(collect, context, nil, out, 0, skip)
    if not ok then Log.error("reading a context menu failed: " .. tostring(err)) end
    for _, a in ipairs(out) do
        local fn, args = a.fn, a.args
        a.run = function()
            ISContextMenu.globalPlayerContext = playerNum
            fn(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11])
        end
    end
    return out
end

-- Hides the player's shared context menu (and its submenus) right after a
-- builder showed it.
function Harvest.hide(playerNum)
    local menu = getPlayerContextMenu(playerNum)
    if menu then
        local ok = pcall(function() menu:hideAndChildren() end)
        if not ok then pcall(function() menu:setVisible(false) end) end
    end
end

-- Runs builder() (which must return the ISContextMenu it filled), harvests it and
-- hides it. Returns the action list (possibly empty).
function Harvest.run(playerNum, builder, skip)
    if VPUI.Perf then VPUI.Perf.count("menuHarvests") end
    local menu = getPlayerContextMenu(playerNum)
    if menu and menu:getIsVisible() then pcall(function() menu:hideAndChildren() end) end
    local ok, context = pcall(builder)
    local actions = {}
    if ok then
        actions = Harvest.read(context, playerNum, skip)
    else
        Log.error("building a context menu failed: " .. tostring(context))
    end
    Harvest.hide(playerNum)
    return actions
end
