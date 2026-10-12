--
-- Viewpoint UI - interaction controller.
--
-- Per tick:
--   1. read input and Viewpoint's target (cheap)
--   2. rebuild the action list only when the target or Viewpoint's harvested
--      actions changed, or once a second
--   3. while the interface is active, Viewpoint's loot panel is hidden outright
--      (looting goes through the Viewpoint inventory), so it never flashes up
--      before a target's actions are known; the game's Interact key is held back
--      while there is a target with actions (or one whose actions are still
--      being read), so one press never fires twice
--   4. run the tap / hold / menu state machine, build mode, the fallback-window
--      cursor, and update the widgets
--
-- Three interaction styles (Settings.interactStyle):
--   scroll  - every action on the target is listed beside the crosshair as soon
--             as you aim at it; the wheel chooses, Interact does it (DayZ-like).
--             One action: just the prompt, Interact does it.
--   hold    - tap Interact: the primary action. Hold: the action menu (also a
--             tap when there is no obvious primary). In the menu: wheel to
--             choose, Interact to do, the close key or looking away to dismiss.
--   vanilla - this add-on stays out of interaction: no prompt or list, the
--             game's Interact key and Viewpoint's own loot panel work as without
--             it. The HUD and the screens stay.
--

require "ViewpointUI/Core"
require "ViewpointUI/Settings"
require "ViewpointUI/Text"
require "ViewpointUI/Input"
require "ViewpointUI/Bridge"
require "ViewpointUI/Interaction/Target"
require "ViewpointUI/Interaction/Registry"
require "ViewpointUI/Interaction/Providers"
require "ViewpointUI/Interaction/Executor"
require "ViewpointUI/Interaction/QuickLoot"
require "ViewpointUI/UI/Widgets"
require "ViewpointUI/HUD/StatusHUD"
require "ViewpointUI/HUD/VitalsHUD"
require "ViewpointUI/HUD/WeaponHUD"
require "ViewpointUI/HUD/Hotbar"
require "ViewpointUI/HUD/VanillaHUD"
require "ViewpointUI/UI/ChatStyle"
require "ViewpointUI/UI/Screen"
require "ViewpointUI/Legacy"
require "ViewpointUI/Building/BuildMode"
require "ViewpointUI/Building/PlaceMode"
require "ViewpointUI/Building/MoveMode"
require "ViewpointUI/Building/DestroyMode"
require "TimedActions/ISTimedActionQueue"

local VPUI = ViewpointUI
if VPUI.Controller then return end

local Controller = {}
VPUI.Controller = Controller

local Log, Util, Settings, Text = VPUI.Log, VPUI.Util, VPUI.Settings, VPUI.Text
local Input, Bridge = VPUI.Input, VPUI.Bridge
local Target = VPUI.Interaction.Target
local Registry = VPUI.Interaction.Registry
local Executor = VPUI.Interaction.Executor
local QuickLoot = VPUI.Interaction.QuickLoot

local MENU_TIMEOUT_MS = 15000
local RESOLVE_EVERY_MS = 1000
local PROGRESS_GRACE_MS = 1500
local PROGRESS_MAX_MS = 120000
local HARVEST_GRACE_MS = 700    -- keep Interact while Viewpoint reads a new target's actions

local w = nil -- widgets, created on first tick in game

local mode = "idle" -- idle | holding | menu
local resolved = nil
local resolvedKey, resolvedVersion, resolvedAt = nil, nil, 0
local menuArmed, menuOpenedAt, menuKey, menuVersion = false, 0, nil, nil
local promptSig = nil
local progress = { label = nil, since = 0, seen = false }
local active = false
local targetSince = 0
local lastTargetKey = nil
local lastPlaceCursor = nil   -- the game's place cursor seen last tick (a new one closes the hub)
local lastDestroyCursor = nil  -- the same for its sledgehammer / dismantle cursor
local lastMoveCursor = nil    -- the same for its furniture (moveables) cursor
local listShown = false     -- scroll style: the list beside the crosshair is up
local listSig, listTarget = nil, nil
local pendingPressAt = 0    -- scroll style: Interact pressed while the actions were still being read

local function widgets()
    if w then return w end
    w = {
        prompt = VPUI.UI.VPPrompt:new(),
        menu = VPUI.UI.VPActionMenu:new(),
        progress = VPUI.UI.VPProgressBar:new(),
        reticle = VPUI.UI.VPReticle:new(),
        toast = VPUI.UI.VPToast:new(),
        status = VPUI.HUD.Status:new(),
        vitals = VPUI.HUD.Vitals:new(),
        weapon = VPUI.HUD.Weapon:new(),
        hotbar = VPUI.HUD.Hotbar:new(),
    }
    return w
end

function Controller.toast(message, seconds, danger)
    widgets().toast:show(message, seconds, danger)
end

local function hideInteraction()
    listShown = false
    listSig = nil
    QuickLoot.hide()
    if not w then return end
    w.prompt:display(false)
    w.menu:display(false)
    w.reticle:display(false)
    promptSig = nil
end

local function closeMenu()
    if mode == "menu" then
        VPUI.Events.fire("MenuClosed")
        Log.trace("menu closed")
    end
    mode = "idle"
    menuArmed = false
    listShown = false
    listSig = nil
    if w then w.menu:display(false) end
end

-- Everything off and every Java flag released (interface off, paused, dead).
-- paused: the vanilla HUD stays hidden (and the hotbar's drawing skipped) so
-- it does not flash up under the pause menu; it comes back when the view or
-- the interface is really off.
local function standDown(paused)
    local keepVanilla = paused == true and VPUI.HUD.Vanilla.isHiding()
    if active then
        closeMenu()
        hideInteraction()
        if w then
            w.progress:display(false)
            w.status:display(false)
            w.vitals:display(false)
            w.weapon:display(false)
            w.hotbar:display(false)
        end
        VPUI.HUD.Hotbar.setReplacing(keepVanilla)
        VPUI.Building.BuildMode.stop()
        VPUI.Building.PlaceMode.stop(false)   -- the game's cursor stays for the isometric view
        VPUI.Building.MoveMode.stop(false)
        VPUI.Building.DestroyMode.stop(false)
        VPUI.Legacy.reset()
        Target.clear()
        resolved, resolvedKey, resolvedVersion = nil, nil, nil
        active = false
    end
    mode = "idle"
    VPUI.Legacy.active = false
    if not keepVanilla then
        VPUI.HUD.Vanilla.restore()
        VPUI.HUD.Hotbar.setReplacing(false)
    end
    if paused ~= true then VPUI.HUD.Vanilla.minimapEnd() end
    if paused ~= true then VPUI.UI.ChatStyle.set(false) end
    Bridge.releaseAll()
end

local function openMenu(armed, now)
    if not resolved or #resolved.actions == 0 then return end
    local items = {}
    for _, action in ipairs(resolved.actions) do
        table.insert(items, { label = action.label, enabled = action.enabled, action = action })
    end
    local footer = string.format(Text.menuFooter, Input.label("interact"), Input.label("cancel"))
    w.menu:setContent(resolved.title, items, footer)
    w.menu:display(true)
    w.prompt:display(false)
    promptSig = nil
    mode = "menu"
    menuArmed = armed
    menuOpenedAt = now
    menuKey = resolvedKey
    menuVersion = resolvedVersion
    Bridge.takeWheel() -- drop notches from before the menu
    VPUI.Events.fire("MenuOpened", resolved)
    Log.trace("menu opened with " .. tostring(#items) .. " actions")
end

local function resolve(target, player, now)
    local version = Bridge.call("actionsVersion", -1)
    if not target then
        resolved, resolvedKey, resolvedVersion = nil, nil, nil
        return
    end
    -- The open menu keeps its list; a change closes it (handled in the menu step).
    if mode == "menu" then return end
    if resolvedKey == target.key and resolvedVersion == version and now - resolvedAt < RESOLVE_EVERY_MS then
        return
    end
    resolved = Registry.resolve(target, player)
    VPUI.Perf.count("actionLists")
    resolvedKey, resolvedVersion, resolvedAt = target.key, version, now
    promptSig = nil
    VPUI.Events.fire("ActionsResolved", target, resolved)
end

-- The item a target is, when it is one item lying in the world.
local function targetItem()
    local t = Target.get()
    local obj = t and t.object
    if not obj then return nil end
    local ok, item = pcall(function()
        if instanceof(obj, "IsoWorldInventoryObject") then return obj:getItem() end
        return nil
    end)
    if ok then return item end
    return nil
end

local function updatePrompt(fraction, noHold)
    local show = Settings.get("showPrompt") == true
    if not show or not resolved then
        w.prompt:display(false)
        return
    end
    w.prompt:setItem(targetItem())
    local key = Input.label("interact")
    local hold = string.format(Text.holdPrefix, key)
    local lines = {}
    local count = #resolved.actions
    if resolved.primary then
        table.insert(lines, { key = key, text = resolved.primary.label })
        if count > 1 and not noHold then table.insert(lines, { key = hold, text = string.format(Text.moreActions, tostring(count - 1)) }) end
    elseif resolved.blocked then
        table.insert(lines, { key = key, text = resolved.blocked.label, enabled = false })
        if count > 1 and not noHold then table.insert(lines, { key = hold, text = string.format(Text.moreActions, tostring(count - 1)) }) end
    else
        table.insert(lines, { key = key, text = string.format(Text.actions, tostring(count)) })
    end
    local sig = tostring(resolved.title)
    for _, line in ipairs(lines) do sig = sig .. "|" .. line.key .. line.text .. tostring(line.enabled) end
    if sig ~= promptSig then
        promptSig = sig
        w.prompt:setContent(resolved.title, lines)
    end
    w.prompt:setHold(fraction)
    w.prompt:display(true)
end

local function updateReticle(owned)
    if not owned or Settings.get("showReticle") ~= true then
        w.reticle:display(false)
        return
    end
    local state = "interact"
    if mode == "menu" then
        state = "menu"
    elseif listShown or QuickLoot.shown() then
        state = "menu"
    elseif resolved and not resolved.primary and resolved.blocked then
        state = "blocked"
    end
    w.reticle:setState(state)
    w.reticle:display(true)
end

-- An action we started has finished (a trunk is open now, a door shut): have
-- Viewpoint read the target's actions again and rebuild ours, so the list
-- shows "Close trunk" and the storage without looking away. Viewpoint's own
-- re-read can happen before the queued action even starts.
local watch = nil   -- { since, seen }
local function watchAction(now)
    watch = { since = now, seen = false }
end

local function checkActionDone(player, now)
    if not watch then return end
    local queue = ISTimedActionQueue.queues[player]
    local busy = queue and queue.queue and queue.queue[1] ~= nil
    if busy then watch.seen = true return end
    if watch.seen or now - watch.since > PROGRESS_GRACE_MS then
        watch = nil
        Bridge.call("forgetActions", false)
        resolvedKey, resolvedVersion = nil, nil
        -- Viewpoint takes a moment to read them; keep Interact meanwhile
        targetSince = now
    end
end

local function updateProgress(player, now)
    checkActionDone(player, now)
    if Settings.get("progressHud") ~= true or not progress.label then
        w.progress:display(false)
        return
    end
    local queue = ISTimedActionQueue.queues[player]
    local head = queue and queue.queue and queue.queue[1]
    if head then
        progress.seen = true
        local fraction = 0
        if head.action then
            local ok, delta = pcall(head.getJobDelta, head)
            if ok and type(delta) == "number" then fraction = delta end
        end
        w.progress:set(progress.label, fraction)
        w.progress:display(true)
    end
    local age = now - progress.since
    if (not head and (progress.seen or age > PROGRESS_GRACE_MS)) or age > PROGRESS_MAX_MS then
        progress.label = nil
        w.progress:display(false)
    end
end

local function updateHud(player, now, hidden)
    local vanillaHidden = VPUI.HUD.Vanilla.isHiding()
    if hidden then
        w.status:display(false)
        w.vitals:display(false)
        w.weapon:display(false)
        w.hotbar:display(false)
        VPUI.HUD.Hotbar.setReplacing(vanillaHidden)
        return
    end
    if Settings.get("hotbarHud") == true then
        w.hotbar:read(player, now)
        local show = w.hotbar:count() > 0 and not player:getVehicle()
        w.hotbar:display(show)
        VPUI.HUD.Hotbar.setReplacing(show or vanillaHidden)
    else
        w.hotbar:display(false)
        VPUI.HUD.Hotbar.setReplacing(vanillaHidden)
    end
    if Settings.get("statusHud") == true then
        w.status:setFull(vanillaHidden)
        w.status:read(player, now)
        w.status:display(w.status:hasRows())
    else
        w.status:display(false)
    end
    if Settings.get("vitalsHud") == true then
        w.vitals:read(player, now)
        w.vitals:setAbove(w.status:getIsVisible() and w.status.added and w.status.y or nil)
        w.vitals:display(w.vitals:active())
    else
        w.vitals:display(false)
    end
    if Settings.get("weaponHud") == true then
        w.weapon:read(player, now)
        w.weapon:display(w.weapon:active())
    else
        w.weapon:display(false)
    end
end

local function runAction(action, target, player)
    if Executor.run(action, target, player) then
        watchAction(Util.now())
        progress.label = action.label
        progress.since = Util.now()
        progress.seen = false
    end
end

-- The tap / hold / menu state machine, while this interface owns the target.
local function interact(target, player, now)
    if mode == "idle" then
        if Input.pressed("interact") then mode = "holding" end
        updatePrompt(0)
        return
    end

    if mode == "holding" then
        local holdMs = (tonumber(Settings.get("holdTime")) or 0.35) * 1000
        local held = Input.heldMs("interact", now)
        if Input.down("interact") then
            if held >= holdMs then
                openMenu(false, now)
            else
                updatePrompt(held / holdMs)
            end
            return
        end
        -- released before the hold time: a tap
        mode = "idle"
        if resolved.primary then
            runAction(resolved.primary, target, player)
            updatePrompt(0)
        else
            openMenu(true, now)
        end
        return
    end

    -- mode == "menu"
    if menuKey ~= target.key or menuVersion ~= Bridge.call("actionsVersion", -1) then
        closeMenu()
        return
    end
    if now - menuOpenedAt > MENU_TIMEOUT_MS or Input.pressed("cancel") then
        closeMenu()
        return
    end
    local wheel = tonumber(Bridge.takeWheel()) or 0
    if wheel ~= 0 then
        local steps = math.min(math.abs(wheel), 5)
        w.menu:move(wheel > 0 and -steps or steps)
    end
    if not menuArmed then
        if not Input.down("interact") then menuArmed = true end
        return
    end
    if Input.pressed("interact") then
        local item = w.menu:current()
        closeMenu()
        if item and item.action then runAction(item.action, target, player) end
    end
end

-- Scroll style: the list is up while aiming at a target with several actions.
local function scrollInteract(target, player, now)
    local pressed = Input.pressed("interact")
    if pendingPressAt > 0 then
        if now - pendingPressAt <= HARVEST_GRACE_MS then pressed = true end
        pendingPressAt = 0
    end
    local actions = resolved.actions
    if #actions <= 1 then
        if listShown then
            listShown = false
            listSig = nil
            w.menu:display(false)
        end
        updatePrompt(0, true)
        if pressed and resolved.primary then
            runAction(resolved.primary, target, player)
        end
        return
    end
    local sig = tostring(resolved.title)
    for _, a in ipairs(actions) do sig = sig .. "|" .. tostring(a.label) .. tostring(a.enabled) end
    if sig ~= listSig then
        -- a rebuilt list for the same target keeps what was chosen
        local keep = nil
        if listShown and listTarget == target.key then
            local cur = w.menu:current()
            keep = cur and cur.label
        end
        local items, primaryAt, keepAt = {}, nil, nil
        for i, action in ipairs(actions) do
            table.insert(items, { label = action.label, enabled = action.enabled, action = action })
            if action == resolved.primary then primaryAt = i end
            if keep and action.label == keep then keepAt = i end
        end
        w.menu:setContent(resolved.title, items, string.format(Text.listFooter, Input.label("interact")))
        if keepAt or primaryAt then w.menu:select(keepAt or primaryAt) end
        if not listShown then Bridge.takeWheel() end -- drop notches from before the list
        listSig = sig
        listTarget = target.key
    end
    listShown = true
    w.prompt:display(false)
    promptSig = nil
    w.menu:display(true)
    local wheel = tonumber(Bridge.takeWheel()) or 0
    if wheel ~= 0 then
        local steps = math.min(math.abs(wheel), 5)
        w.menu:move(wheel > 0 and -steps or steps)
    end
    if pressed then
        local item = w.menu:current()
        if item and item.action and item.enabled ~= false then runAction(item.action, target, player) end
    end
end

local function owns(target, player, now)
    if not target then return false end
    if player:getVehicle() ~= nil then return false end
    if resolved and #resolved.actions > 0 then return true end
    -- a fresh target whose actions Viewpoint has not read yet: hold the key a moment
    return now - targetSince < HARVEST_GRACE_MS
end

-- Remembers the last target for the admin tab and the last vehicle for the
-- vehicle tab (they act on what was aimed at before the screen opened).
local function rememberNow(target)
    local sq = target.square
    if not sq and target.object then sq = target.object:getSquare() end
    if sq then
        local name = (resolved and resolved.title) or target.kindName
        local vehicle = (target.kind == Bridge.KIND.VEHICLE) and target.object or nil
        if VPUI.Screens and VPUI.Screens.Admin then
            VPUI.Screens.Admin.lastTarget = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), name = name, vehicle = vehicle }
        end
        if vehicle and VPUI.Screens and VPUI.Screens.Vehicle then VPUI.Screens.Vehicle.lastVehicle = vehicle end
    end
end

local function remember(target)
    if not target then return end
    local ok, err = pcall(rememberNow, target)
    if not ok then Log.once(Log.DEBUG, "remember", "could not note the target: " .. tostring(err)) end
end

-- When prompts go missing, say why in console.txt (once per reason): Viewpoint
-- aims at nothing while the cursor is free, interaction is off, etc.
local whyAt, whyReason, whySince = 0, nil, 0
local function explainNoTarget(player, now)
    if now < whyAt then return end
    whyAt = now + 1000
    local native = VPUI.Native
    if not native or not native.whyNoTarget then return end
    local ok, reason = pcall(native.whyNoTarget, player)
    reason = ok and tostring(reason or "") or ""
    if reason ~= whyReason then whyReason, whySince = reason, now return end
    if reason == "" or reason == "the player is aiming" or reason == "in a vehicle" then return end
    if now - whySince >= 3000 then
        Log.once(Log.WARN, "noTarget:" .. reason, "no interaction prompts: Viewpoint aims at nothing because " .. reason)
    end
end

-- Wanting to aim: a weapon in hand and the aim button held (right mouse, or
-- the game's Aim key), or already aiming. While so, the interface steps out of
-- the way completely (no prompt, no list, no claim on any key, no menu
-- reading), so nothing of it stands between the player and the gun. With the
-- action list up on another player, aiming did not work until the interface
-- was turned off.
local function wantsToAim(player)
    local ok, want = pcall(function()
        local item = player:getPrimaryHandItem()
        if not item or not instanceof(item, "HandWeapon") then return false end
        if player:isAiming() then return true end
        if isMouseButtonDown(1) then return true end
        local key = getCore():getKey(KeybindId.AIM)
        return key ~= nil and key > 0 and isKeyDown(key)
    end)
    return ok and want == true
end
Controller.wantsToAim = wantsToAim

function Controller.tick()
    -- the game's Toggle UI: a full-screen screen left open would stay up
    if Util.uiHidden() and VPUI.Hub.isOpen() then VPUI.Hub.close() end
    local player = Util.player()
    if Settings.get("enabled") ~= true or not player or isGamePaused() or not Bridge.ready() or not Bridge.viewOn() then
        local paused = Settings.get("enabled") == true and player ~= nil and isGamePaused()
            and Bridge.ready() and Bridge.viewOn()
        standDown(paused)
        return
    end
    widgets()
    if Util.uiHidden() then w.toast:display(false) end   -- the game's Toggle UI
    active = true
    local now = Util.now()
    VPUI.Perf.count("ticks")
    VPUI.Perf.flush(now)
    Input.update(now)

    -- Diagnostics switch: behave as if the add-on were absent.
    if Settings.get("legacyFallback") == true then
        VPUI.Legacy.active = false
        VPUI.Building.BuildMode.stop()
        VPUI.Building.PlaceMode.stop(false)
        VPUI.Building.MoveMode.stop(false)
        VPUI.Building.DestroyMode.stop(false)
        VPUI.Legacy.reset()
        closeMenu()
        hideInteraction()
        Bridge.releaseAll()
        VPUI.HUD.Vanilla.restore()
        VPUI.HUD.Vanilla.minimapEnd()
        VPUI.UI.ChatStyle.set(false)
        updateHud(player, now, true)
        return
    end
    VPUI.Legacy.active = true
    -- the isometric HUD is replaced by this interface's own
    if Settings.get("hideVanillaHud") == true then
        VPUI.HUD.Vanilla.hide(player:getPlayerNum(), {
            sidebar = Settings.get("keepSidebar") == true,
            inventory = Settings.get("vanillaInventory") == true,
            moodles = Settings.get("keepMoodles") == true,
        })
    else
        VPUI.HUD.Vanilla.restore()
    end
    VPUI.UI.ChatStyle.set(Settings.get("styleChat") == true)
    if Settings.get("showMinimap") == true then VPUI.HUD.Vanilla.minimap(player:getPlayerNum()) end
    VPUI.Legacy.tick(now)
    local style = Settings.interactStyle()
    Bridge.hideLootPanel(style ~= "vanilla")

    -- The game's Place Item cursor is up (from an item's menu): the hub closes
    -- so you can aim where it goes.
    local placing = VPUI.Building.PlaceMode.cursor(player)
    if placing and placing ~= lastPlaceCursor and VPUI.Hub.isOpen() then VPUI.Hub.close() end
    lastPlaceCursor = placing
    -- The same for the game's furniture cursor (Place on a carried fridge,
    -- Rotate from the list): the hub closes so you can aim.
    local moving = VPUI.Building.MoveMode.cursor(player)
    if moving and moving ~= lastMoveCursor and VPUI.Hub.isOpen() then VPUI.Hub.close() end
    lastMoveCursor = moving
    -- And for the game's sledgehammer / dismantle cursor (Destroy from the list).
    local destroying = VPUI.Building.DestroyMode.cursor(player)
    if destroying and destroying ~= lastDestroyCursor and VPUI.Hub.isOpen() then VPUI.Hub.close() end
    lastDestroyCursor = destroying

    -- The full-screen hub frees the cursor, so there is no aim; keep the world
    -- prompt and the HUD out of the way under it.
    if VPUI.Hub.isOpen() then
        -- opening any screen ends build mode, so keys typed there never place
        VPUI.Building.BuildMode.stop()
        VPUI.Building.PlaceMode.stop(false)   -- picks up again when the screen closes
        VPUI.Building.MoveMode.stop(false)
        VPUI.Building.DestroyMode.stop(false)
        Bridge.ownInteract(false)
        closeMenu()
        hideInteraction()
        updateHud(player, now, true)
        return
    end

    -- Build mode owns Interact and the screen centre while it runs.
    if VPUI.Building.BuildMode.isActive() then
        Bridge.ownInteract(true)
        closeMenu()
        hideInteraction()
        VPUI.Building.BuildMode.tick(player, now, Input)
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    end

    -- Place mode owns Interact (place) and the wheel (turn) while the game's
    -- place cursor is up; Viewpoint cannot drive that cursor on its own.
    if placing then
        Bridge.ownInteract(true)
        -- the wheel turns the item, unless the cursor is free: then it belongs
        -- to whatever window the mouse is over
        Bridge.menuOpen(Bridge.call("cursorFree", false) ~= true)
        closeMenu()
        hideInteraction()
        VPUI.Building.PlaceMode.tick(player, now, Input)
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    elseif VPUI.Building.PlaceMode.isActive() then
        VPUI.Building.PlaceMode.stop(false)
    end

    -- Move mode: the game's furniture cursor, driven from the crosshair.
    if moving then
        Bridge.ownInteract(true)
        Bridge.menuOpen(Bridge.call("cursorFree", false) ~= true)
        closeMenu()
        hideInteraction()
        Target.update()   -- pick up / rotate act on what you aim at
        VPUI.Building.MoveMode.tick(player, now, Input)
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    elseif VPUI.Building.MoveMode.isActive() then
        VPUI.Building.MoveMode.stop(false)
    end

    -- Destroy mode: the game's sledgehammer / dismantle cursor, driven from the crosshair.
    if destroying then
        Bridge.ownInteract(true)
        Bridge.menuOpen(Bridge.call("cursorFree", false) ~= true)
        closeMenu()
        hideInteraction()
        Target.update()   -- the object Viewpoint aims at is picked first
        VPUI.Building.DestroyMode.tick(player, now, Input)
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    elseif VPUI.Building.DestroyMode.isActive() then
        VPUI.Building.DestroyMode.stop(false)
    end

    -- Vanilla style: the game's and Viewpoint's own interaction, untouched.
    if style == "vanilla" then
        Bridge.ownInteract(false)
        Bridge.menuOpen(false)
        closeMenu()
        hideInteraction()
        resolved, resolvedKey, resolvedVersion = nil, nil, nil
        remember(Target.update())   -- the vehicle and admin tabs still use what was aimed at
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    end

    if wantsToAim(player) then
        Bridge.ownInteract(false)
        Bridge.menuOpen(false)
        closeMenu()
        hideInteraction()
        mode = "idle"
        lastTargetKey = nil
        Target.clear()
        resolved, resolvedKey, resolvedVersion = nil, nil, nil
        updateReticle(false)
        updateProgress(player, now)
        updateHud(player, now, false)
        return
    end

    local target = Target.update()
    if not target then explainNoTarget(player, now) end
    if target and target.key ~= lastTargetKey then
        lastTargetKey = target.key
        targetSince = now
        -- a hold started on another target must not fire this one's action
        closeMenu()
        pendingPressAt = 0
    elseif not target then
        lastTargetKey = nil
    end
    resolve(target, player, now)
    remember(target)

    local owned = owns(target, player, now)
    Bridge.ownInteract(owned)

    if owned and not (resolved and #resolved.actions > 0) then
        -- Viewpoint is still reading this target's actions: keep a press so it
        -- is not lost; the state machine picks it up once the actions arrive
        if style == "scroll" then
            if Input.pressed("interact") then pendingPressAt = now end
            hideInteraction()
        else
            if Input.pressed("interact") then mode = "holding" end
            if mode ~= "holding" then hideInteraction() end
        end
    elseif owned and mode ~= "menu" and QuickLoot.wants(target, player, resolved, now) then
        -- a container or body in reach: its items beside the crosshair
        if mode ~= "idle" then closeMenu() end
        -- the prompt and the list make way (not hideInteraction: that would
        -- also reset quick loot's own hold)
        listShown, listSig, promptSig = false, nil, nil
        w.prompt:display(false)
        w.menu:display(false)
        QuickLoot.tick(target, player, resolved, QuickLoot.wants(target, player, resolved, now), now, {
            input = Input,
            interactLabel = Input.label("interact"),
            runAction = function(action) runAction(action, target, player) end,
            toast = function(message) Controller.toast(message, 2) end,
        })
    elseif owned and style == "scroll" then
        QuickLoot.hide()
        if mode ~= "idle" then closeMenu() end
        scrollInteract(target, player, now)
    elseif owned then
        QuickLoot.hide()
        if listShown then hideInteraction() end
        interact(target, player, now)
        if mode == "menu" then w.prompt:display(false) end
    else
        if mode == "menu" then closeMenu() end
        mode = "idle"
        hideInteraction()
    end
    -- the wheel scrolls the action list only while Viewpoint holds the mouse;
    -- with the cursor free it belongs to the game's windows
    Bridge.menuOpen(owned and (mode == "menu" or listShown or QuickLoot.shown()) and Bridge.call("cursorFree", false) ~= true)
    updateReticle(owned and resolved ~= nil and #resolved.actions > 0)
    updateProgress(player, now)
    updateHud(player, now, false)
end

-- Rebuild layout after a resolution, font or size change.
VPUI.Events.add("LayoutChanged", function()
    if not w then return end
    for _, widget in pairs(w) do widget:markDirty() end
end)

function Controller.reset()
    standDown()
    progress.label = nil
end

function Controller.isActive()
    return active
end

function Controller.current()
    return Target.get(), resolved
end
