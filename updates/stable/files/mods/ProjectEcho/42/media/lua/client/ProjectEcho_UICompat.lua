-- PROJECT ECHO v0.9.12 - The Mission UI compatibility policy
-- Keeps The Mission clickable while removing its G hotkey and nudging its HUD icon down.
require "ProjectEcho_Core"
if ProjectEcho.Disabled then return end

local PE = ProjectEcho
local OFFSET_Y = 44
local attempted = false
local moved = false

local function setNoHotkeyRuntime()
    pcall(function()
        if SandboxVars and SandboxVars.TM42 then
            SandboxVars.TM42.Hotkey = 0
            SandboxVars.TM42.ShowHudIcon = true
        end
    end)
end

local function objY(o)
    if type(o) ~= "table" then return nil end
    if type(o.getY) == "function" then
        local ok,v = pcall(function() return o:getY() end)
        if ok and type(v)=="number" then return v end
    end
    return type(o.y)=="number" and o.y or nil
end
local function objW(o)
    if type(o) ~= "table" then return nil end
    if type(o.getWidth) == "function" then
        local ok,v = pcall(function() return o:getWidth() end)
        if ok and type(v)=="number" then return v end
    end
    return tonumber(o.width)
end
local function objH(o)
    if type(o) ~= "table" then return nil end
    if type(o.getHeight) == "function" then
        local ok,v = pcall(function() return o:getHeight() end)
        if ok and type(v)=="number" then return v end
    end
    return tonumber(o.height)
end

local function isHudKey(k)
    k=string.lower(tostring(k or ""))
    local mission=k:find("mission",1,true) or k:find("tm42",1,true)
    local hud=k:find("hud",1,true) or k:find("icon",1,true) or k:find("button",1,true)
    return mission and hud
end

local function tryMove(o,label)
    if moved or type(o)~="table" or o.__ProjectEchoHudMoved then return false end
    if type(o.setY)~="function" then return false end
    local y=objY(o); local w=objW(o); local h=objH(o)
    if type(y)~="number" then return false end
    -- HUD launchers are small; do not touch the actual mission window controls.
    if w and w>120 then return false end
    if h and h>120 then return false end
    local ok=pcall(function() o:setY(y+OFFSET_Y) end)
    if ok then
        o.__ProjectEchoHudMoved=true
        moved=true
        print("[PROJECT ECHO][UI] The Mission HUD icon moved down by "..tostring(OFFSET_Y).." px via "..tostring(label))
        return true
    end
    return false
end

local function scanKnown()
    if moved then return end
    if type(TM42)=="table" then
        local preferred={"missionHudIcon","missionHUDIcon","hudIcon","hudButton","missionButton","buttonHud","iconButton","missionIcon"}
        for _,k in ipairs(preferred) do if tryMove(TM42[k],"TM42."..k) then return end end
        for k,v in pairs(TM42) do
            if isHudKey(k) and tryMove(v,"TM42."..tostring(k)) then return end
        end
    end
    -- Some builds expose the launcher as a global instead of a TM42 field.
    for k,v in pairs(_G or {}) do
        local lk=string.lower(tostring(k or ""))
        if (lk:find("tm42",1,true) or lk:find("themission",1,true)) and
           (lk:find("hud",1,true) or lk:find("icon",1,true) or lk:find("button",1,true)) then
            if tryMove(v,tostring(k)) then return end
        end
    end
end

local function applyUI()
    setNoHotkeyRuntime()
    scanKnown()
end

local ticks=0
local function onTick()
    if moved then
        if Events.OnTick then Events.OnTick.Remove(onTick) end
        return
    end
    ticks=ticks+1
    -- The Mission creates its HUD after player/UI initialization, so retry briefly.
    if ticks%30==0 then applyUI() end
    if ticks>900 then
        if not attempted then print("[PROJECT ECHO][UI] The Mission HUD launcher not found; hotkey policy still applied.") end
        attempted=true
        if Events.OnTick then Events.OnTick.Remove(onTick) end
    end
end

setNoHotkeyRuntime()
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function() ticks=0; attempted=false; applyUI() end) end
if Events.OnConnected then Events.OnConnected.Add(function() ticks=0; attempted=false; applyUI() end) end
if Events.OnTick then Events.OnTick.Add(onTick) end

PE.UICompat = PE.UICompat or {}
PE.UICompat.apply = applyUI
PE.UICompat.offsetY = OFFSET_Y
