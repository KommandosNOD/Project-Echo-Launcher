-- PROJECT ECHO - server-only zone controller for special infected / monster NPC mods.
if type(isServer) ~= "function" or not isServer() then return end

require "ProjectEcho_Core"
require "ProjectEcho_Missions"
require "ProjectEcho_SpecialEncounters"
local _cofAdapterLoaded,_cofAdapterResult = pcall(require,"ProjectEcho_CryOfFearAdapter")

if ProjectEcho.Disabled then return end
local PE=ProjectEcho
local TICK_DIV=240
local tick=0

local function isModActive(modID)
    local mods=getActivatedMods and getActivatedMods() or nil
    if not mods or not mods.contains then return false end
    local ok,v=pcall(function() return mods:contains(modID) end)
    return ok and v==true
end

local function store()
    local s=ModData.getOrCreate(PE.GlobalKey)
    s.specialEncounters=type(s.specialEncounters)=="table" and s.specialEncounters or {}
    s.specialStats=type(s.specialStats)=="table" and s.specialStats or {wildMutantsRemoved=0,wildCOFRemoved=0,scriptedMutants=0,cofSpawned=0,cofSkipped=0}
    s.journalUnlocked=type(s.journalUnlocked)=="table" and s.journalUnlocked or {}
    s.journalEvents=type(s.journalEvents)=="table" and s.journalEvents or {}
    return s
end

local function persist(s) ModData.add(PE.GlobalKey,s) end

local function players()
    local out={}
    if not getOnlinePlayers then return out end
    local ok,l=pcall(getOnlinePlayers); if not ok or not l then return out end
    local okn,n=pcall(function() return l:size() end); if not okn or not n then return out end
    for i=0,n-1 do local okp,p=pcall(function() return l:get(i) end); if okp and p then out[#out+1]=p end end
    return out
end

local function dist2(x1,y1,x2,y2) local dx=x1-x2; local dy=y1-y2; return dx*dx+dy*dy end
local function inAnchor(p,a,scale)
    if not p or not a then return false end
    local r=(tonumber(a.radius) or 150)*(tonumber(scale) or 1)
    return dist2(p:getX(),p:getY(),a.x,a.y)<=r*r
end

local function missionMatches(def,current)
    for _,id in ipairs(def.missions or {}) do if id==current then return true end end
    return false
end

local function mutantAPI(z)
    if PZTheMutants and PZTheMutants.API and type(PZTheMutants.API.isMutant)=="function" then
        local ok,v=pcall(PZTheMutants.API.isMutant,z); if ok then return v==true end
    end
    if z and z.getOutfitName then
        local ok,n=pcall(function() return z:getOutfitName() end)
        return ok and type(n)=="string" and string.sub(n,1,13)=="PZTheMutants_"
    end
    return false
end

local function getMD(z)
    if not z or not z.getModData then return nil end
    local ok,md=pcall(function() return z:getModData() end)
    return ok and md or nil
end

local function removeZombie(z)
    if not z then return false end
    local ok=pcall(function()
        if z.removeFromWorld then z:removeFromWorld() end
        if z.removeFromSquare then z:removeFromSquare() end
    end)
    return ok
end

local function loadedZombies()
    local cell=getCell and getCell() or nil
    if not cell or not cell.getZombieList then return nil end
    local ok,l=pcall(function() return cell:getZombieList() end)
    return ok and l or nil
end

-- Hard containment: every naturally spawned The Mutants entity is removed unless it was
-- explicitly tagged by PROJECT ECHO. Tagged entities are also removed if they wander too
-- far from their encounter zone, so they cannot seed the normal world.
local function quarantineMutants(s)
    if not isModActive("PZTheMutants") then return end
    local l=loadedZombies(); if not l then return end
    local okn,n=pcall(function() return l:size() end); if not okn or not n then return end
    for i=n-1,0,-1 do
        local okz,z=pcall(function() return l:get(i) end)
        if okz and z and mutantAPI(z) then
            local md=getMD(z)
            if not (md and md.ProjectEchoSpecial==true) then
                if removeZombie(z) then s.specialStats.wildMutantsRemoved=(tonumber(s.specialStats.wildMutantsRemoved) or 0)+1 end
            else
                local def=PE.SpecialEncounterById[md.ProjectEchoEncounter]
                local a=def and PE.Anchors and PE.Anchors[def.anchor] or nil
                if a then
                    local r=(tonumber(a.radius) or 150)*(tonumber(def.boundaryScale) or 1.2)
                    local zx,zy=z:getX(),z:getY()
                    if dist2(zx,zy,a.x,a.y)>r*r then removeZombie(z) end
                end
            end
        end
    end
end

local function spawnMutantWave(def,s,p)
    if not isModActive("PZTheMutants") or type(addZombiesInOutfit)~="function" then return false,"provider unavailable" end
    local a=PE.Anchors and PE.Anchors[def.anchor] or nil; if not a then return false,"anchor missing" end
    local spawned=0
    for i,outfit in ipairs(def.wave or {}) do
        local angle=(i*2.17); local rr=14+(i%3)*8
        local x=math.floor(p:getX()+math.cos(angle)*rr)
        local y=math.floor(p:getY()+math.sin(angle)*rr)
        local z=math.floor(p:getZ() or a.z or 0)
        local ok,list=pcall(addZombiesInOutfit,x,y,z,1,outfit,50)
        if ok and list then
            local okn,n=pcall(function() return list:size() end)
            if okn and n then
                for j=0,n-1 do
                    local okz,zom=pcall(function() return list:get(j) end)
                    if okz and zom then
                        local md=getMD(zom)
                        if md then md.ProjectEchoSpecial=true; md.ProjectEchoEncounter=def.id end
                        spawned=spawned+1
                    end
                end
            end
        end
    end
    if spawned>0 then
        s.specialStats.scriptedMutants=(tonumber(s.specialStats.scriptedMutants) or 0)+spawned
        return true,"spawned="..tostring(spawned)
    end
    return false,"spawn returned no entities"
end

local function cofAdapter()
    -- Exact binding is packaged with PROJECT ECHO, but remains late-bound/fail-safe:
    -- an external COF update that removes the exported API simply makes encounters skip.
    return PE.CryOfFearAdapter
end

local function cofName(z)
    local ad=cofAdapter()
    if not ad or type(ad.name)~="function" then return nil end
    local ok,n=pcall(ad.name,z)
    return ok and n or nil
end

-- Hard containment for Cry of Fear too. PREPARE disables its natural populations and
-- night event, while this sweep removes anything that still appears outside ECHO control.
local function quarantineCOF(s)
    if not isModActive("CryOfFearMonsters") then return end
    local ad=cofAdapter(); if not ad or type(ad.name)~="function" then return end
    local l=loadedZombies(); if not l then return end
    local okn,n=pcall(function() return l:size() end); if not okn or not n then return end
    for i=n-1,0,-1 do
        local okz,z=pcall(function() return l:get(i) end)
        if okz and z and cofName(z) then
            local md=getMD(z)
            if not (md and md.ProjectEchoSpecial==true and md.ProjectEchoProvider=="cof") then
                if removeZombie(z) then s.specialStats.wildCOFRemoved=(tonumber(s.specialStats.wildCOFRemoved) or 0)+1 end
            else
                local def=PE.SpecialEncounterById[md.ProjectEchoEncounter]
                local a=def and PE.Anchors and PE.Anchors[def.anchor] or nil
                if a then
                    local r=(tonumber(a.radius) or 150)*(tonumber(def.boundaryScale) or 1.2)
                    if dist2(z:getX(),z:getY(),a.x,a.y)>r*r then removeZombie(z) end
                end
            end
        end
    end
end

local function spawnCOF(def,s,p)
    if not isModActive("CryOfFearMonsters") then return false,"provider inactive" end
    local ad=cofAdapter()
    if not ad or type(ad.spawnPreset)~="function" then
        s.specialStats.cofSkipped=(tonumber(s.specialStats.cofSkipped) or 0)+1
        return false,"adapter unavailable (softlock-safe skip)"
    end
    local a=PE.Anchors and PE.Anchors[def.anchor] or nil; if not a then return false,"anchor missing" end
    local ok,res=pcall(ad.spawnPreset,def.preset,p,a,def.id)
    if ok and res then s.specialStats.cofSpawned=(tonumber(s.specialStats.cofSpawned) or 0)+1; return true,"spawned" end
    return false,"adapter call failed"
end

local function unlockFieldNote(s)
    if not s.journalUnlocked.FIELD_ANOMALY then
        s.journalUnlocked.FIELD_ANOMALY=true
        s.journalEvents[#s.journalEvents+1]={schema=2,kind="journal",event="journal_unlock",journalID="FIELD_ANOMALY",reasonType="field",hour=(getGameTime and getGameTime():getWorldAgeHours()) or 0}
    end
end

local function tryEncounters(s)
    local current=s.currentMain
    if not current then return end
    local ps=players(); if #ps==0 then return end
    for _,def in ipairs(PE.SpecialEncounterDefs or {}) do
        local st=s.specialEncounters[def.id]
        if type(st)~="table" then st={triggered=false,attempts=0}; s.specialEncounters[def.id]=st end
        if not st.triggered and missionMatches(def,current) then
            local a=PE.Anchors and PE.Anchors[def.anchor] or nil
            if a then
                for _,p in ipairs(ps) do
                    if inAnchor(p,a,0.72) then
                        st.attempts=(tonumber(st.attempts) or 0)+1
                        local ok,msg=false,""
                        if def.provider=="mutants" then ok,msg=spawnMutantWave(def,s,p)
                        elseif def.provider=="cof" then ok,msg=spawnCOF(def,s,p) end
                        if ok then
                            st.triggered=true; st.at=(getGameTime and getGameTime():getWorldAgeHours()) or 0
                            unlockFieldNote(s)
                            print("[PROJECT ECHO][SPECIAL] controlled encounter activated provider="..tostring(def.provider))
                        elseif def.provider=="cof" and st.attempts>=1 then
                            -- External beta adapter failure must NEVER block or spam a campaign.
                            st.triggered=true; st.skipped=true; st.reason=msg
                            print("[PROJECT ECHO][SPECIAL] optional provider skipped safely: "..tostring(msg))
                        elseif st.attempts>=3 then
                            st.triggered=true; st.skipped=true; st.reason=msg
                            print("[PROJECT ECHO][SPECIAL] provider failed after retries; skipped safely")
                        end
                        break
                    end
                end
            end
        end
    end
end

local function suppressRuntimeSandbox()
    -- Best-effort runtime second line of defence. PREPARE_SPECIAL_ZONES edits the server
    -- SandboxVars before world creation; this catches conventional option names as well.
    if type(SandboxVars)~="table" then return end
    local mutantNames={puker=true,husk=true,skitter=true,leaper=true,wrecker=true,weeper=true}
    -- Exact COF 0.68.6 schema, matching PREPARE_SPECIAL_ZONES. Enum value 1 = None.
    if type(SandboxVars.COF_Sawrunner)=="table" then
        SandboxVars.COF_Sawrunner.NightEvent=false
        SandboxVars.COF_Sawrunner.NaturalSpawns=false
    end
    if type(SandboxVars.COF_Spawns)=="table" then
        SandboxVars.COF_Spawns.Regular=1
        SandboxVars.COF_Spawns.Sawcrazy=1
        SandboxVars.COF_Spawns.Sawrunner=1
        SandboxVars.COF_Spawns.HumanFlowers=false
        SandboxVars.COF_Spawns.Stranger=1
        SandboxVars.COF_Spawns.Drowned=1
        SandboxVars.COF_Spawns.RespawnHours=0
    end
    local function walk(t,mode,depth)
        if type(t)~="table" or depth>2 then return end
        for k,v in pairs(t) do
            local lk=string.lower(tostring(k))
            if type(v)=="table" then walk(v,mode,depth+1)
            elseif mode=="mutants" and type(v)=="number" then
                for n in pairs(mutantNames) do if string.find(lk,n,1,true) and (string.find(lk,"spawn",1,true) or string.find(lk,"chance",1,true) or string.find(lk,"rate",1,true)) then t[k]=0 end end
            elseif mode=="cof" then
                if type(v)=="boolean" and (string.find(lk,"spawn",1,true) or string.find(lk,"encounter",1,true) or string.find(lk,"flower",1,true)) then t[k]=false end
                if type(v)=="number" and (string.find(lk,"respawn",1,true) or string.find(lk,"population",1,true)) then t[k]=0 end
            end
        end
    end
    for k,v in pairs(SandboxVars) do
        local lk=string.lower(tostring(k))
        if string.find(lk,"mutant",1,true) then walk(v,"mutants",0) end
        if string.find(lk,"cry",1,true) or string.find(lk,"fear",1,true) or string.find(lk,"cof",1,true) then walk(v,"cof",0) end
    end
end

function PE.SpecialEncounterSnapshot(s)
    s=s or store()
    local trig,skip=0,0
    for _,v in pairs(s.specialEncounters or {}) do if v.triggered then trig=trig+1 end; if v.skipped then skip=skip+1 end end
    local ad=cofAdapter(); local binding=false
    if _cofAdapterLoaded and ad and type(ad.available)=="function" then
        local ok,v=pcall(ad.available); binding=ok and v==true
    end
    return {mutants=isModActive("PZTheMutants"),cof=isModActive("CryOfFearMonsters"),triggered=trig,skipped=skip,wildRemoved=tonumber(s.specialStats.wildMutantsRemoved) or 0,wildCOFRemoved=tonumber(s.specialStats.wildCOFRemoved) or 0,cofAdapter=(ad and true or false),cofBinding=binding}
end

function PE.SpecialDebugCommand(player,cmd,s)
    s=s or store(); local low=string.lower(tostring(cmd or ""))
    local snap=PE.SpecialEncounterSnapshot(s)
    if low=="special status" or low=="special probe" then
        return {"SPECIAL ZONES", "The Mutants="..tostring(snap.mutants), "CryOfFear="..tostring(snap.cof), "CoF adapter="..tostring(snap.cofAdapter).." binding="..tostring(snap.cofBinding), "activated="..tostring(snap.triggered).." skipped="..tostring(snap.skipped), "wild mutants quarantined="..tostring(snap.wildRemoved), "wild COF quarantined="..tostring(snap.wildCOFRemoved)}
    end
    if low=="special quarantine" then quarantineMutants(s); quarantineCOF(s); persist(s); return {"[OK] special-zone quarantine pass complete"} end
    return nil
end

local function onInit()
    suppressRuntimeSandbox()
    if not _cofAdapterLoaded then print("[PROJECT ECHO][SPECIAL][COF] adapter require failed: "..tostring(_cofAdapterResult)) end
    local s=store(); persist(s)
    local snap=PE.SpecialEncounterSnapshot(s)
    print("[PROJECT ECHO][SPECIAL] subsystem ready mutants="..tostring(snap.mutants).." cof="..tostring(snap.cof).." cofAdapter="..tostring(snap.cofAdapter).." cofBinding="..tostring(snap.cofBinding))
    print("[PROJECT ECHO][SPECIAL] wild-mutant quarantine=ON; COF quarantine=ON; special encounters are non-blocking")
end

local function onTick()
    tick=tick+1; if tick%TICK_DIV~=0 then return end
    local s=store(); suppressRuntimeSandbox(); quarantineMutants(s); quarantineCOF(s); tryEncounters(s); persist(s)
end

if Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(onInit) end
if Events.OnTick then Events.OnTick.Add(onTick) end
