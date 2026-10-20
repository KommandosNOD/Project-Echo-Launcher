-- PROJECT ECHO Dynamic Wall Clock 1.2.0 | Project Zomboid B42.21 MP
-- Original sprite pack: nPocTo_4eJI (Workshop 3278687498); 3D assets from installed Viewpoint: Living Props.
-- Client-only: no network commands, no world sprite replacements and no save modifications.
-- Previous bug: V1.1 overwrote ViewpointLivingProps minute-hand overlay with a 2D clock overlay.
-- 32/33 (stock walls) now belong to ViewpointLivingProps while its Viewpoint 3D renderer is active.
-- 34/35 get a separate, EXPERIMENTAL model pack and virtual 3D hands.

local TAG = '[PE DynamicClock v1.2] '
local WATCH = {
    location_community_school_01_32 = 32,
    location_community_school_01_33 = 33,
    location_community_school_01_34 = 34,
    location_community_school_01_35 = 35,
}
local PREFIX = 'location_community_school_01_'
local MIN_PREFIX = 'pe_clkm_'
local HOUR_PREFIX = 'pe_clkh_'
local MANIFEST = 'media/modelpacks/peclock_reverse/pack.properties'
local MOD_ID = 'ProjectEchoDynamicWallClockB42'
local frame, lastMode, packRegistered = 0, nil, false
local objects = setmetatable({}, {__mode = 'k'})
local identified = {}
local errors = 0
local SCAN_RADIUS = 12

local function vLog(msg)
    print(TAG .. tostring(msg))
end
local function safeName(s)
    return s and s:getName() or nil
end
local function spriteName(o)
    if not o then return nil end
    return safeName(o:getSprite())
end
local function clockTile(o)
    local name = spriteName(o)
    return name and WATCH[name] or nil
end
local function view3D()
    -- This is the SAME test used by ViewpointLivingPropsClocks.lua. If the companion's
    -- model pack is disabled we deliberately fall back to old 2D overlays.
    if type(ViewpointLivingPropsIsActive) ~= 'function' then return false end
    local ok, yes = pcall(ViewpointLivingPropsIsActive)
    return ok and yes == true
end
local function registerPack()
    if packRegistered then return true end
    if not Viewpoint or not Viewpoint.ModelPacks or not Viewpoint.ModelPacks.register then return false end
    local ok, registered = pcall(Viewpoint.ModelPacks.register, MOD_ID, MANIFEST)
    if ok and registered then
        packRegistered = true
        vLog('reverse 3D model pack registered (tiles 34/35)')
        return true
    end
    if not ok and errors < 3 then errors = errors + 1; vLog('pack register: ' .. tostring(registered)) end
    return false
end
local function slot()
    local t = getGameTime()
    if not t then return nil, nil, nil end
    local hr, minute = tonumber(t:getHour()), tonumber(t:getMinutes())
    if not hr or not minute then return nil,nil,nil end
    local h = math.floor(hr) % 12
    local m = math.floor(minute) % 60
    return h,m, '_' .. h .. 'h_' .. (math.floor(m/10)*10) .. 'm'
end
local function oldOverlay(n)
    return type(n) == 'string' and n:match('^location_community_school_01_3[2345]_%d+h_%d+m$') ~= nil
end
local function oursMin(n)
    return type(n) == 'string' and n:sub(1,#MIN_PREFIX) == MIN_PREFIX
end
local function hourName(o)
    local list = o:getAttachedAnimSprite()
    if list and list:size() == 1 then
        local item = list:get(0)
        if item then return item:getName() end
    end
    return nil
end
local function prepSprite(name,o,restore)
    local spr = getSprite(name)
    if not spr then return nil end
    if not safeName(spr) then pcall(function() spr:setName(name) end) end
    if not safeName(spr) then
        -- PZ B42 sometimes only names a newly minted virtual sprite via setOverlaySprite.
        pcall(function() o:setOverlaySprite(name,false) end)
        if restore then pcall(function() o:setOverlaySprite(restore,false) end) end
    end
    return safeName(spr) and spr or nil
end
local function detachOurs(o,s)
    local n = safeName(o:getOverlaySprite())
    if oursMin(n) then o:setOverlaySprite('',false) end
    if s.attached and type(hourName(o))=='string' then
        local a = hourName(o)
        if a:sub(1,#HOUR_PREFIX) == HOUR_PREFIX then
            pcall(function() o:RemoveAttachedAnims() end)
        end
    end
    s.attached = false
end
local function discover(o)
    local tile = clockTile(o)
    if not tile or not o:getSquare() then return end
    if not objects[o] then
        objects[o] = {tile=tile, attached=false, seen3D=false}
        if not identified[tile] then
            identified[tile] = true
            local sq = o:getSquare()
            vLog('found tile ' .. tile .. ' at ' .. sq:getX() .. ',' .. sq:getY() .. ',' .. sq:getZ())
        end
    end
end
local function scanSquare(sq)
    if not sq then return end
    local list = sq:getObjects()
    if not list then return end
    for i=0,list:size()-1 do
        local o = list:get(i)
        if o then discover(o) end
    end
end
local function scanNear()
    local p = getPlayer and getPlayer()
    if not p or not p:getSquare() or not getCell() then return end
    local ps = p:getSquare()
    local px,py,pz = ps:getX(),ps:getY(),ps:getZ()
    for zz=math.max(-32,pz-1),math.min(31,pz+1) do
        for xx=px-SCAN_RADIUS,px+SCAN_RADIUS do
            for yy=py-SCAN_RADIUS,py+SCAN_RADIUS do
                scanSquare(getCell():getGridSquare(xx,yy,zz))
            end
        end
    end
end
local function update2D(o,s,h,m,legacy)
    -- Clear only this add-on's 3D hand sprites. Never touch ViewpointLivingProps's sprites.
    detachOurs(o,s)
    local expected = PREFIX .. s.tile .. legacy
    if safeName(o:getOverlaySprite()) ~= expected then
        o:setOverlaySprite(expected,false)
    end
    s.seen3D = false
end
local function update3D32(o,s)
    -- On 32/33 the stock LivingProps 3D script owns BOTH hands; we must not
    -- overwrite lp_clkm_* with our old 2D location_community_school overlay.
    local n = safeName(o:getOverlaySprite())
    if oldOverlay(n) then
        o:setOverlaySprite('',false)
        if not s.handedOff then vLog('handed clock ' .. s.tile .. ' over to ViewpointLivingProps') end
    end
    s.handedOff = true
    s.seen3D = true
end
local function update3DReverse(o,s,h,m)
    if not packRegistered then return end
    local mn = MIN_PREFIX .. s.tile .. '_' .. (m < 10 and '0' or '') .. m
    -- 0-59 hour-hand position = 6 degrees each, one increment every 12 minutes.
    local hi = math.floor((h*60 + m + 6)/12)%60
    local hn = HOUR_PREFIX .. s.tile .. '_' .. (hi < 10 and '0' or '') .. hi
    if safeName(o:getOverlaySprite()) ~= mn then o:setOverlaySprite(mn,false) end
    if hourName(o) ~= hn then
        local spr = prepSprite(hn,o,mn)
        if spr then
            if s.attached and hourName(o) and hourName(o):sub(1,#HOUR_PREFIX)==HOUR_PREFIX then
                o:RemoveAttachedAnims()
            end
            o:addAttachedAnimSprite(spr)
            s.attached = true
        elseif not s.noSpriteLogged then
            s.noSpriteLogged = true
            vLog('cannot name virtual hour sprite for tile ' .. s.tile)
        end
    end
    if not s.seen3D then vLog('3D reverse clock ' .. s.tile .. ' attached') end
    s.seen3D = true
end
local function updateAll()
    local h,m,legacy = slot()
    if not legacy then return end
    local in3D = view3D()
    if lastMode ~= in3D then
        vLog('renderer mode=' .. (in3D and 'Viewpoint3D' or 'isometric/fallback'))
        lastMode = in3D
    end
    for o,s in pairs(objects) do
        local sq = o:getSquare()
        if not sq or clockTile(o) ~= s.tile then
            objects[o] = nil
        else
            local ok,err = pcall(function()
                if in3D then
                    if s.tile == 32 or s.tile == 33 then
                        update3D32(o,s)
                    elseif packRegistered then
                        update3DReverse(o,s,h,m)
                    else
                        -- Keep time visible if our extra model pack cannot register.
                        update2D(o,s,h,m,legacy)
                    end
                else
                    update2D(o,s,h,m,legacy)
                end
            end)
            if not ok and errors < 8 then errors=errors+1; vLog('update tile ' .. s.tile .. ': '.. tostring(err)) end
        end
    end
end
local function onStart()
    frame = 0
    lastMode = nil
    objects = setmetatable({}, {__mode='k'})
    identified = {}
    registerPack()
    scanNear()
    updateAll()
    vLog('loaded; 32/33=LivingProps 3D, 34/35=experimental 3D; 2D overlays only in isometric view')
end
local function onTick()
    frame = frame + 1
    if not packRegistered and frame % 300 == 0 then registerPack() end
    if frame % 30 == 0 then updateAll() end
    if frame % 300 == 0 then scanNear() end
end
if Events.OnGameBoot then Events.OnGameBoot.Add(registerPack) end
if Events.OnGameStart then Events.OnGameStart.Add(onStart) end
if Events.LoadGridsquare then Events.LoadGridsquare.Add(scanSquare) end
if Events.OnObjectAdded then Events.OnObjectAdded.Add(discover) end
if Events.OnTick then Events.OnTick.Add(onTick) end
if Events.OnSave then Events.OnSave.Add(function()
    -- Our virtual overlays/attachments are ephemeral and MUST NOT persist to a save.
    -- We do not touch VLP-owned (32/33) virtual sprites; their mod saves/cleans them.
    for o,s in pairs(objects) do
        if s.tile == 34 or s.tile == 35 then
            pcall(function() detachOurs(o,s) end)
        end
    end
end) end
