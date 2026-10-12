-- PROJECT ECHO - exact Cry of Fear Monsters server binding.
-- Bound against CryOfFearMonsters 0.68.6 (B42.20+).
-- Uses the mod's exported COF_ServerMonsters.create(name,x,y,z) directly.
-- No debug command and no Capability.CreateHorde permission are involved.
require "ProjectEcho_Core"

if type(isServer) ~= "function" or not isServer() then return end
ProjectEcho = ProjectEcho or {}
local PE = ProjectEcho
local A = {}

A.Provider = "CryOfFearMonsters"
A.BoundVersion = "0.68.6"
A.Binding = "COF_ServerMonsters.create"

-- Keep encounter composition here, away from the spoiler-safe journal/UI.
-- All names below are present in COF_ServerMonsters.Health in 0.68.6.
local PRESETS = {
    controlled_light  = {"Slower", "Crawler"},
    controlled_medium = {"Faster", "Croucher", "Psycho"},
    controlled_heavy  = {"Sawcrazy", "Slower3", "Crawler2", "Sewmo"},
}

local OFFSETS = {
    {18,0},{-18,0},{0,18},{0,-18},
    {22,10},{-22,10},{22,-10},{-22,-10},
    {12,24},{-12,24},{12,-24},{-12,-24},
    {28,0},{-28,0},{0,28},{0,-28},
}

local cached
local function serverAPI()
    if cached and type(cached.create)=="function" then return cached end
    local s = rawget(_G,"COF_ServerMonsters")
    if type(s)=="table" and type(s.create)=="function" then cached=s; return s end
    local ok,res = pcall(require,"COF_ServerMonsters")
    if ok and type(res)=="table" and type(res.create)=="function" then cached=res; return res end
    s = rawget(_G,"COF_ServerMonsters")
    if type(s)=="table" and type(s.create)=="function" then cached=s; return s end
    return nil
end

local function squareFree(x,y,z)
    local cell=getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return false end
    local ok,sq=pcall(function() return cell:getGridSquare(x,y,z) end)
    if not ok or not sq then return false end
    if not sq.isFree then return true end
    local ok2,v=pcall(function() return sq:isFree(false) end)
    return ok2 and v==true
end

local function tag(z,encounterID)
    if not z or not z.getModData then return end
    local ok,md=pcall(function() return z:getModData() end)
    if ok and md then
        md.ProjectEchoSpecial=true
        md.ProjectEchoEncounter=encounterID
        md.ProjectEchoProvider="cof"
    end
end


function A.available()
    local s=serverAPI()
    return s~=nil and type(s.create)=="function"
end

function A.name(z)
    local s=serverAPI()
    if not s or type(s.name)~="function" then return nil end
    local ok,n=pcall(s.name,z)
    if ok and type(n)=="string" and n~="" then return n end
    return nil
end

function A.spawnPreset(preset,p,anchor,encounterID)
    local s=serverAPI()
    if not s then return false end
    local names=PRESETS[tostring(preset or "")]
    if type(names)~="table" or #names==0 or not p then return false end

    local px=math.floor(tonumber(p:getX()) or 0)
    local py=math.floor(tonumber(p:getY()) or 0)
    local pz=math.floor(tonumber(p:getZ()) or tonumber(anchor and anchor.z) or 0)
    local made=0

    for i,name in ipairs(names) do
        local chosenX,chosenY
        -- Start from a different offset for each monster, then fan out if occupied.
        for step=0,#OFFSETS-1 do
            local o=OFFSETS[((i+step-1)%#OFFSETS)+1]
            local x,y=px+o[1],py+o[2]
            if squareFree(x,y,pz) then chosenX,chosenY=x,y; break end
        end
        if chosenX and chosenY then
            local ok,z=pcall(s.create,name,chosenX,chosenY,pz)
            if ok and z then
                tag(z,encounterID)
                made=made+1
            elseif not ok then
                print("[PROJECT ECHO][SPECIAL][COF] create failed: "..tostring(z))
            end
        end
    end

    if made>0 then
        print("[PROJECT ECHO][SPECIAL][COF] exact adapter 0.68.6 created "..tostring(made).." controlled monster(s)")
        return true
    end
    return false
end

function A.status()
    return {provider=A.Provider,boundVersion=A.BoundVersion,binding=A.Binding,available=A.available()}
end

PE.CryOfFearAdapter=A
return A
