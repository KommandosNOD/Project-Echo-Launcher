-- PROJECT ECHO - authoritative dedicated-server campaign engine
if type(isServer) ~= "function" or not isServer() then return end

require "ProjectEcho_Core"
require "ProjectEcho_Missions"
require "ProjectEcho_JournalData"
require "ProjectEcho_StoryEnhancements"
require "ProjectEcho_SpecialEncounters"
require "ProjectEcho_PhunMart_Server"

if ProjectEcho.Disabled then return end

local PE = ProjectEcho
local ProgressGuard = require "ProjectEcho_ProgressGuard"

-- PROJECT ECHO owns a persistent shared campaign. The Mission's periodic history
-- reset must never reset this campaign. This is a runtime safety net; the server
-- SandboxVars should also keep TM42.EnableMissionReset=false.
local function enforceServerPolicy()
    if type(SandboxVars)~="table" then return end
    if type(SandboxVars.TM42)=="table" then
        if SandboxVars.TM42.EnableMissionReset ~= false then
            print("[PROJECT ECHO][STATE] TM42 mission reset was enabled; forcing EnableMissionReset=false for this runtime")
        end
        SandboxVars.TM42.EnableMissionReset=false
    end
    -- Requested server policy: mixed zombie speed with a very small vanilla
    -- sprinter population. Keeping Speed=4 is required for SprinterPercentage.
    if type(SandboxVars.ZombieLore)=="table" then
        SandboxVars.ZombieLore.Speed=4
        SandboxVars.ZombieLore.SprinterPercentage=1
    end
end
enforceServerPolicy()

local history, missionProgress
local stateLog, stateLine, logTM42API
local function nowHours()
    return (getGameTime and getGameTime():getWorldAgeHours()) or 0
end

local function getStore()
    local s = ModData.getOrCreate(PE.GlobalKey)
    s.version = 5
    s.completed = type(s.completed) == "table" and s.completed or {}
    s.runtime = type(s.runtime) == "table" and s.runtime or {}
    s.cooldowns = type(s.cooldowns) == "table" and s.cooldowns or {}
    s.knownPlayers = type(s.knownPlayers) == "table" and s.knownPlayers or {}
    s.journalUnlocked = type(s.journalUnlocked) == "table" and s.journalUnlocked or {}
    s.journalEvents = type(s.journalEvents) == "table" and s.journalEvents or {}
    s.journalSchema = tonumber(s.journalSchema) or 1
    s.debugSnapshots = type(s.debugSnapshots) == "table" and s.debugSnapshots or {}
    s.debugSnapshotOrder = type(s.debugSnapshotOrder) == "table" and s.debugSnapshotOrder or {}
    s.humanContacts = type(s.humanContacts) == "table" and s.humanContacts or {}
    s.humanContacts.seenUIDs = type(s.humanContacts.seenUIDs) == "table" and s.humanContacts.seenUIDs or {}
    s.humanContacts.totalSeen = tonumber(s.humanContacts.totalSeen) or 0
    s.humanContacts.totalKills = tonumber(s.humanContacts.totalKills) or 0
    s.eventFlags = type(s.eventFlags) == "table" and s.eventFlags or {}
    s.specialEncounters = type(s.specialEncounters) == "table" and s.specialEncounters or {}
    s.specialStats = type(s.specialStats) == "table" and s.specialStats or {}
    s.choice = s.choice or nil
    s.startAnchor = s.startAnchor or nil
    s.mainIndex = tonumber(s.mainIndex) or nil
    s.stateMachineVersion = tonumber(s.stateMachineVersion) or 1
    s.campaignEpoch = math.max(1,tonumber(s.campaignEpoch) or 1)
    s.rewardSeed = s.rewardSeed and tostring(s.rewardSeed) or nil
    s.finished = s.finished == true
    -- Never resurrect PE_M001 just because currentMain is nil. A finished campaign
    -- legitimately has currentMain=nil. Initialize only a genuinely new store.
    if s.currentMain == nil and s.mainIndex == nil and not s.finished then s.currentMain = "PE_M001" end
    s.revision = math.max(1, tonumber(s.revision) or 1)
    s.transitionSerial = math.max(0,tonumber(s.transitionSerial) or 0)
    s.logSchema = 1
    return s
end

local function persist(s)
    ProgressGuard.beforePersist(s)
    s.revision = (tonumber(s.revision) or 0) + 1
    ModData.add(PE.GlobalKey, s)
    ProgressGuard.afterPersist(s)
end

local STATE_LOG_FILE = "ProjectEcho_StateMachine.log"
local sessionTag = tostring(os and os.time and os.time() or "pz")..":"..tostring(math.floor(nowHours()*1000))
local lastLoggedProgress = {}

local function safePlayerName(player)
    if not player then return "server" end
    local ok,u=pcall(function() return player:getUsername() end)
    if ok and u and u~="" then return tostring(u) end
    return "player"
end

local function tmStateList(rec)
    local out={}
    for _,snap in ipairs((rec and rec.state) or {}) do out[#out+1]=tostring(snap and snap.missionID or "?") end
    table.sort(out)
    return table.concat(out,",")
end

stateLine = function(event,reason,player,s,rec,extra)
    s=s or getStore()
    if not rec then local _,r=history(); rec=r end
    local id=tostring(s.currentMain or "nil")
    local m=s.currentMain and PE.getMission(s.currentMain) or nil
    local pct,_,ready=0,"",false
    if m then pct,_,ready=missionProgress(s,m) end
    local tmDone=(rec and rec.completed and s.currentMain and rec.completed[s.currentMain]==true) and "1" or "0"
    local peDone=(s.completed and s.currentMain and s.completed[s.currentMain]==true) and "1" or "0"
    local claim="0"
    if rec and rec.claims and s.currentMain then
        local c=rec.claims[s.currentMain]
        if c~=nil then claim=tostring(c) end
    end
    return table.concat({
        "session="..sessionTag,
        "event="..tostring(event or "?"),
        "reason="..tostring(reason or "-"),
        "player="..safePlayerName(player),
        "rev="..tostring(s.revision),
        "tx="..tostring(s.transitionSerial),
        "idx="..tostring(s.mainIndex),
        "current="..id,
        "finished="..tostring(s.finished==true),
        "progress="..tostring(math.floor((tonumber(pct) or 0)+0.5)),
        "ready="..tostring(ready==true),
        "peDoneCurrent="..peDone,
        "tmDoneCurrent="..tmDone,
        "tmClaimCurrent="..claim,
        "tmActive=["..tmStateList(rec).."]",
        "extra="..tostring(extra or "-")
    }," | ")
end

stateLog = function(event,reason,player,s,rec,extra)
    local line=stateLine(event,reason,player,s,rec,extra)
    print("[PROJECT ECHO][STATE] "..line)
    pcall(function()
        local w=getFileWriter(STATE_LOG_FILE,true,true)
        w:write(line.."\n")
        w:close()
    end)
end

logTM42API = function()
    local keys={}
    for k,v in pairs(TM42 or {}) do
        local lk=string.lower(tostring(k))
        if type(v)=="function" and (lk:find("state",1,true) or lk:find("status",1,true) or lk:find("active",1,true) or lk:find("complete",1,true) or lk:find("claim",1,true) or lk:find("history",1,true)) then
            keys[#keys+1]=tostring(k)
        end
    end
    table.sort(keys)
    stateLog("TM42_API","startup",nil,getStore(),nil,table.concat(keys,","))
end

local function distance2(x1,y1,x2,y2)
    local dx=x1-x2; local dy=y1-y2
    return dx*dx+dy*dy
end

local function resolveAnchor(s, id)
    if id == "$START" then id = s.startAnchor end
    return id and PE.Anchors[id] or nil
end

local function inAnchor(player, anchor)
    if not player or not anchor then return false end
    local z = math.floor(player:getZ() or 0)
    if anchor.z ~= nil and math.abs(z - (tonumber(anchor.z) or 0)) > 2 then return false end
    local r = tonumber(anchor.radius) or 150
    return distance2(player:getX(),player:getY(),anchor.x,anchor.y) <= r*r
end

-- PROJECT_ECHO_SERVER_UDP_GUARD_FIX: network API is unavailable during GlobalModData init.
-- Wait for first server game tick before enumerating players.
local peServerTickObserved = false

local function onlinePlayers()
    local result = {}
    if not peServerTickObserved then return result end
    if not getOnlinePlayers then return result end

    -- During dedicated-server startup OnInitGlobalModData can fire before
    -- Project Zomboid has finished creating the online-player collection.
    -- In that short window getOnlinePlayers() itself may throw. Treat that
    -- as an empty server; clients will request a fresh sync after joining.
    local okList, list = pcall(getOnlinePlayers)
    if not okList or not list then return result end

    local okSize, count = pcall(function() return list:size() end)
    if not okSize or not count then return result end

    for i = 0, count - 1 do
        local okPlayer, player = pcall(function() return list:get(i) end)
        if okPlayer and player then result[#result + 1] = player end
    end
    return result
end

history = function()
    local gh = ModData.getOrCreate(TM42.GlobalHistoryKey)
    local rec = gh[PE.SharedHistoryKey]
    local created=false
    if type(rec) ~= "table" then
        rec = { completed = {}, resetAt = TM42.getRealWorldTimestamp(), cooldowns = {}, state = {}, claims = {} }
        gh[PE.SharedHistoryKey] = rec
        created=true
    end
    rec.completed = type(rec.completed)=="table" and rec.completed or {}
    rec.state = type(rec.state)=="table" and rec.state or {}
    rec.cooldowns = type(rec.cooldowns)=="table" and rec.cooldowns or {}
    rec.claims = type(rec.claims)=="table" and rec.claims or {}
    if created then ModData.add(TM42.GlobalHistoryKey, gh) end
    return gh, rec
end

local function findState(rec,id)
    for _,snap in ipairs(rec.state or {}) do if snap.missionID==id then return snap end end
    return nil
end

local function removeState(rec,id)
    local out={}
    for _,snap in ipairs(rec.state or {}) do if snap.missionID~=id then out[#out+1]=snap end end
    rec.state=out
end

local function ensureActive(rec,id)
    if not id or findState(rec,id) then return false end
    rec.state[#rec.state+1]={missionID=id,progress=0,acceptedAt=TM42.getRealWorldTimestamp()}
    return true
end

local function mirrorToPlayer(player,s,rec)
    if not player then return end
    local md = TM42.getModData(player)
    if not md then stateLog("MIRROR_SKIP","no_moddata",player,s,rec); return end
    TM42.replaceCompletedHistory(md, rec.completed, rec.resetAt)
    TM42.replaceRefillCooldowns(md, rec.cooldowns)
    TM42.applyMissionState(player, md, rec.state)
    if player.transmitModData then player:transmitModData() end
    stateLog("MIRROR_PLAYER","authoritative",player,s,rec)
end

local function knownPlayerKey(player)
    if not player then return nil end
    local steam = player.getSteamID and player:getSteamID() or nil
    if steam and tostring(steam) ~= "0" then return "steam:"..tostring(steam) end
    local u=player.getUsername and player:getUsername() or nil
    return u and "user:"..tostring(u) or nil
end

local function runtimeFor(s,id)
    local r=s.runtime[id]
    if type(r)~="table" then
        r={ startedAt=nowHours(), kills=0, distance=0, visited={}, interacted={}, hold={}, choices={}, humanKills={}, humanSeen={}, humanHold={} }
        s.runtime[id]=r
    end
    r.visited=type(r.visited)=="table" and r.visited or {}
    r.interacted=type(r.interacted)=="table" and r.interacted or {}
    r.hold=type(r.hold)=="table" and r.hold or {}
    r.choices=type(r.choices)=="table" and r.choices or {}
    r.humanKills=type(r.humanKills)=="table" and r.humanKills or {}
    r.humanSeen=type(r.humanSeen)=="table" and r.humanSeen or {}
    r.humanHold=type(r.humanHold)=="table" and r.humanHold or {}
    return r
end

local function isModActive(modID)
    local mods = getActivatedMods and getActivatedMods() or nil
    if not mods or not mods.contains then return false end
    local ok, result = pcall(function() return mods:contains(modID) end)
    return ok and result == true
end

local function isALifeOwned(zombie)
    if not zombie or not zombie.getModData then return false end
    local ok, md = pcall(function() return zombie:getModData() end)
    return ok and type(md)=="table" and md.ProjectALifeOwned == true
end

local function getALifeInfo(zombie)
    local out={uid=nil,faction=nil}
    if not zombie or not zombie.getModData then return out end
    local ok,md=pcall(function() return zombie:getModData() end)
    if ok and type(md)=="table" then
        out.uid=md.ProjectALifeUID or md.ALifeUID
        out.faction=md.ProjectALifeFactionId or md.ALifeFactionId
    end
    return out
end

local function getALifeStance(zombie,player)
    if not zombie or not player or not ProjectALife then return nil end
    local info=getALifeInfo(zombie)
    if not info.uid then return nil end
    local actor=nil
    if ProjectALife.ActorRegistry and type(ProjectALife.ActorRegistry.read)=="function" then
        local ok,result=pcall(ProjectALife.ActorRegistry.read,info.uid)
        if ok then actor=result end
    end
    if actor and ProjectALife.Relations and type(ProjectALife.Relations.playerStance)=="function" then
        local ok,result=pcall(ProjectALife.Relations.playerStance,actor,player)
        if ok then return result end
    end
    return nil
end

local function inventoryCountAcrossPlayers(itemType)
    local total=0
    for _,p in ipairs(onlinePlayers()) do
        local inv=p:getInventory()
        if inv and inv.getItemCount then total=total+(inv:getItemCount(itemType,false) or 0) end
    end
    return total
end

local function oneDecimal(value)
    return string.format("%.1f", tonumber(value) or 0)
end

local function reqProgress(s,mission,req,index)
    local rt=runtimeFor(s,mission.id)
    local kind=req.kind
    local T=PE.textRef
    local F=PE.formatRef
    if kind=="start_region" then
        return s.startAnchor and 1 or 0, 1, s.startAnchor and (PE.Anchors[s.startAnchor].name) or T("UI_ProjectEcho_Text_0026")
    elseif kind=="start_hold" then
        local target=tonumber(req.hours) or 0.25
        local cur=tonumber(rt.hold["$START"]) or 0
        return cur,target,F("UI_ProjectEcho_Text_0027",oneDecimal(cur),oneDecimal(target))
    elseif kind=="start_interact" then
        local done=rt.interacted["$START"]==true
        return done and 1 or 0,1,done and T("UI_ProjectEcho_Text_0028") or T("UI_ProjectEcho_Text_0029")
    elseif kind=="zone" then
        local done=rt.visited[req.anchor]==true
        local a=resolveAnchor(s,req.anchor)
        local place=(a and a.name or req.anchor)
        return done and 1 or 0,1,(done and T("UI_ProjectEcho_Text_0030") or T("UI_ProjectEcho_Text_0031"))..tostring(place)
    elseif kind=="visit_zones" then
        local need=tonumber(req.count) or #(req.anchors or {})
        local cur=0
        for _,id in ipairs(req.anchors or {}) do if rt.visited[id] then cur=cur+1 end end
        return cur,need,F("UI_ProjectEcho_Text_0032",cur,need)
    elseif kind=="kills" then
        local target=tonumber(req.count) or 1
        local cur=tonumber(rt.kills) or 0
        return cur,target,F("UI_ProjectEcho_Text_0033",cur,target)
    elseif kind=="kills_zone" then
        local target=tonumber(req.count) or 1
        local key="zoneKills:"..tostring(req.anchor)
        local cur=tonumber(rt[key]) or 0
        return cur,target,F("UI_ProjectEcho_Text_0034",cur,target)
    elseif kind=="human_encounter" then
        local key=tostring(req.anchor or "any")
        local need=tonumber(req.kills) or 1
        local humanKills=tonumber(rt.humanKills[key]) or 0
        if humanKills>=need then
            return 1,1,F("UI_ProjectEcho_Text_0035",humanKills,need)
        end
        local fallbackKills=tonumber(req.fallbackKills) or 0
        local fallbackHours=tonumber(req.fallbackHours) or 0
        local zedKills=tonumber(rt.kills) or 0
        local held=tonumber(rt.humanHold[key]) or 0
        local fallbackReady=(fallbackKills<=0 or zedKills>=fallbackKills) and (fallbackHours<=0 or held>=fallbackHours)
        if fallbackReady then return 1,1,T("UI_ProjectEcho_Text_0036") end
        if not isModActive("ProjectALifeNPCs") then
            return 0,1,F("UI_ProjectEcho_Text_0037",zedKills,fallbackKills,oneDecimal(held),oneDecimal(fallbackHours))
        end
        local seen=tonumber(rt.humanSeen[key]) or 0
        return 0,1,F("UI_ProjectEcho_Text_0038",seen,humanKills,need,zedKills,fallbackKills,oneDecimal(held),oneDecimal(fallbackHours))
    elseif kind=="distance" then
        local target=tonumber(req.meters) or 1
        local key=req.onFoot and "distanceFoot" or "distance"
        local cur=tonumber(rt[key]) or 0
        return cur,target,F("UI_ProjectEcho_Text_0039",oneDecimal(cur/1000),oneDecimal(target/1000))
    elseif kind=="survive" then
        local target=tonumber(req.hours) or 1
        local cur=math.max(0,nowHours()-(tonumber(rt.startedAt) or nowHours()))
        return cur,target,F("UI_ProjectEcho_Text_0040",oneDecimal(cur),oneDecimal(target))
    elseif kind=="hold" then
        local target=tonumber(req.hours) or 1
        local cur=tonumber(rt.hold[req.anchor]) or 0
        return cur,target,F("UI_ProjectEcho_Text_0041",oneDecimal(cur),oneDecimal(target))
    elseif kind=="items" then
        local needed=0; local got=0; local labels={}
        for _,it in ipairs(req.items or {}) do
            local n=tonumber(it.count) or 1; local c=inventoryCountAcrossPlayers(it.type)
            needed=needed+n; got=got+math.min(c,n)
            labels[#labels+1]=tostring(math.min(c,n)).."/"..tostring(n)
        end
        return got,needed,T("UI_ProjectEcho_Text_0042")..table.concat(labels,T("UI_ProjectEcho_Text_0043"))
    elseif kind=="interact" then
        local done=rt.interacted[req.anchor]==true
        return done and 1 or 0,1,done and T("UI_ProjectEcho_Text_0044") or (req.prompt or T("UI_ProjectEcho_Text_0045"))
    elseif kind=="vehicle_zone" then
        local key="vehicle:"..tostring(req.anchor)..":"..tostring(req.invert==true)
        local done=rt.visited[key]==true
        return done and 1 or 0,1,done and T("UI_ProjectEcho_Text_0046") or T("UI_ProjectEcho_Text_0047")
    elseif kind=="choice" then
        local done=s.choice~=nil and rt.choices[index]~=nil
        return done and 1 or 0,1,done and T("UI_ProjectEcho_Text_0048") or T("UI_ProjectEcho_Text_0049")
    end
    return 0,1,T("UI_ProjectEcho_Text_0050")
end

local function progressDetailFromLabel(label)
    local raw=tostring(label or "")
    if raw:sub(1,6)=="[[PEF:" and raw:sub(-2)=="]]" then
        local body=raw:sub(7,-3)
        local sep=body:find("|",1,true)
        if sep then
            local key=body:sub(1,sep-1)
            local blob=body:sub(sep+1)
            local args={}
            for part in (blob.."|"):gmatch("(.-)|") do args[#args+1]=part end
            return {key=key,args=args}
        end
    end
    return {raw=raw}
end

missionProgress = function(s,mission)
    local parts={}; local details={}; local total=0; local count=0; local ready=true
    for i,req in ipairs(mission.echo.requirements or {}) do
        local cur,target,label=reqProgress(s,mission,req,i)
        target=math.max(0.0001,tonumber(target) or 1)
        total=total+math.max(0,math.min(1,(tonumber(cur) or 0)/target)); count=count+1
        if (tonumber(cur) or 0)+0.0001 < target then ready=false end
        parts[#parts+1]=label
        details[#details+1]=progressDetailFromLabel(label)
    end
    local pct=count>0 and (total/count*100) or 0
    return pct,table.concat(parts," | "),ready,details
end

local function clientSnapshot(s)
    local snap={
        revision=s.revision,currentMain=s.currentMain,mainIndex=s.mainIndex,campaignEpoch=s.campaignEpoch,rewardSeed=s.rewardSeed,finished=s.finished,startAnchor=s.startAnchor,choice=s.choice,
        completed={},progress={},progressText={},progressDetails={},activeMissionIDs={},cooldowns={},journalUnlocked={},journalEvents={},compat={}
    }
    for id,v in pairs(s.completed) do if v==true then snap.completed[id]=true end end
    for id,v in pairs(s.cooldowns) do snap.cooldowns[id]=v end
    for id,v in pairs(s.journalUnlocked or {}) do if v==true then snap.journalUnlocked[id]=true end end
    local first=math.max(1,#(s.journalEvents or {})-119)
    for i=first,#(s.journalEvents or {}) do snap.journalEvents[#snap.journalEvents+1]=s.journalEvents[i] end
    snap.compat.alife=isModActive("ProjectALifeNPCs")
    snap.compat.bossZombie=isModActive("bossZombie")
    snap.compat.bossSpawner=isModActive("ZombieBossSpawner") or isModActive("BossZombieSpawner")
    snap.compat.mutants=isModActive("PZTheMutants")
    snap.compat.cryOfFear=isModActive("CryOfFearMonsters")
    if PE.SpecialEncounterSnapshot then snap.compat.special=PE.SpecialEncounterSnapshot(s) end
    snap.compat.humanSeen=tonumber(s.humanContacts and s.humanContacts.totalSeen) or 0
    snap.compat.humanKills=tonumber(s.humanContacts and s.humanContacts.totalKills) or 0
    local _,rec=history()
    for _,st in ipairs(rec.state or {}) do
        local m=PE.getMission(st.missionID)
        if m and PE.isEchoMission(m) then
            snap.activeMissionIDs[#snap.activeMissionIDs+1]=m.id
            local pct,text,_,details=missionProgress(s,m)
            snap.progress[m.id]=pct; snap.progressText[m.id]=text; snap.progressDetails[m.id]=details or {}
        end
    end
    PE.ServerView = snap
    return snap
end

local function broadcast(s)
    local snap=clientSnapshot(s)
    for _,p in ipairs(onlinePlayers()) do
        sendServerCommand(p,PE.Module,"Sync",snap)
    end
end

local function echoHistoryDigest(rec)
    local done={}
    for id,v in pairs((rec and rec.completed) or {}) do
        local m=PE.getMission(id)
        if v==true and m and PE.isEchoMission(m) then done[#done+1]=id end
    end
    table.sort(done)
    return table.concat(done,",").."|"..tmStateList(rec)
end

local function canonicalizeHistory(s,reason)
    local gh,rec=history()
    local before=echoHistoryDigest(rec)

    -- Completion flags are output-only mirrors. Never import them back into ECHO.
    for id,m in pairs(PE.MissionsById or {}) do
        if PE.isEchoMission(m) then rec.completed[id]=nil end
    end
    for id,v in pairs(s.completed or {}) do if v==true then rec.completed[id]=true end end

    local cleaned={}
    local seen={}
    for _,snap in ipairs(rec.state or {}) do
        local id=snap and snap.missionID
        local m=id and PE.getMission(id) or nil
        local keep=true
        if m and PE.isEchoMission(m) then
            if m.track=="main" then
                keep=false -- main state is reconstructed below from currentMain only
            elseif s.completed[id]==true then
                keep=false
            elseif m.echoPrerequisite and s.completed[m.echoPrerequisite]~=true then
                keep=false
            end
        end
        if keep and id and not seen[id] then cleaned[#cleaned+1]=snap; seen[id]=true end
    end
    rec.state=cleaned
    if s.currentMain and not s.finished then ensureActive(rec,s.currentMain) end

    local after=echoHistoryDigest(rec)
    local changed=(before~=after)
    if changed then
        gh[PE.SharedHistoryKey]=rec
        ModData.add(TM42.GlobalHistoryKey,gh)
        stateLog("HISTORY_CANONICALIZED",reason,nil,s,rec,"before="..before.." => after="..after)
    end
    return rec,changed
end

local function syncHistory(s,reason,mirrorAllPlayers)
    local rec=canonicalizeHistory(s,reason or "sync")
    if mirrorAllPlayers~=false then
        for _,p in ipairs(onlinePlayers()) do mirrorToPlayer(p,s,rec) end
    end
    return rec
end

local function markVisitedAndHolds(s,deltaHours)
    local _,rec=history()
    for _,snap in ipairs(rec.state or {}) do
        local m=PE.getMission(snap.missionID)
        if m and PE.isEchoMission(m) then
            local rt=runtimeFor(s,m.id)
            for _,req in ipairs(m.echo.requirements or {}) do
                if req.kind=="start_region" and not s.startAnchor then
                    for id,a in pairs(PE.Anchors) do
                        if string.sub(id,1,6)=="start_" then
                            for _,p in ipairs(onlinePlayers()) do
                                if inAnchor(p,a) then
                                    s.startAnchor=id
                                    print("[PROJECT ECHO] start anchor selected: "..tostring(id).." / "..tostring(a.name))
                                    break
                                end
                            end
                            if s.startAnchor then break end
                        end
                    end
                elseif req.kind=="zone" then
                    local a=resolveAnchor(s,req.anchor)
                    for _,p in ipairs(onlinePlayers()) do if inAnchor(p,a) then rt.visited[req.anchor]=true; break end end
                elseif req.kind=="visit_zones" then
                    for _,id in ipairs(req.anchors or {}) do
                        local a=resolveAnchor(s,id)
                        for _,p in ipairs(onlinePlayers()) do if inAnchor(p,a) then rt.visited[id]=true; break end end
                    end
                elseif req.kind=="hold" or req.kind=="start_hold" then
                    local id=req.kind=="start_hold" and "$START" or req.anchor
                    local a=resolveAnchor(s,id)
                    local inside=false
                    for _,p in ipairs(onlinePlayers()) do if inAnchor(p,a) then inside=true; break end end
                    if inside then rt.hold[id]=(tonumber(rt.hold[id]) or 0)+deltaHours end
                elseif req.kind=="human_encounter" then
                    local key=tostring(req.anchor or "any")
                    local a=resolveAnchor(s,req.anchor)
                    local inside=false
                    for _,p in ipairs(onlinePlayers()) do if (not a) or inAnchor(p,a) then inside=true; break end end
                    if inside then rt.humanHold[key]=(tonumber(rt.humanHold[key]) or 0)+deltaHours end
                elseif req.kind=="vehicle_zone" then
                    local a=resolveAnchor(s,req.anchor)
                    for _,p in ipairs(onlinePlayers()) do
                        local inside=inAnchor(p,a)
                        local inVeh=p:getVehicle()~=nil
                        local success=(req.invert==true) and ((not inside) and inVeh) or (inside and inVeh)
                        if success then rt.visited["vehicle:"..tostring(req.anchor)..":"..tostring(req.invert==true)]=true; break end
                    end
                end
            end
        end
    end
end

local lastPositions={}
local function trackDistance(s)
    local _,rec=history()
    local active={}
    for _,snap in ipairs(rec.state or {}) do active[snap.missionID]=true end
    for _,p in ipairs(onlinePlayers()) do
        local key=knownPlayerKey(p) or tostring(p)
        local x,y=p:getX(),p:getY(); local old=lastPositions[key]
        if old then
            local dx=x-old.x; local dy=y-old.y; local d=math.sqrt(dx*dx+dy*dy)
            if d>0 and d<350 then
                for id in pairs(active) do
                    local m=PE.getMission(id)
                    if m and PE.isEchoMission(m) then
                        local rt=runtimeFor(s,id)
                        rt.distance=(tonumber(rt.distance) or 0)+d
                        if not p:getVehicle() then rt.distanceFoot=(tonumber(rt.distanceFoot) or 0)+d end
                    end
                end
            end
        end
        lastPositions[key]={x=x,y=y}
    end
end

local counted=setmetatable({}, {__mode="k"})
local function onZombieDead(zombie)
    if not zombie or counted[zombie] then return end
    local attacker=zombie.getAttackedBy and zombie:getAttackedBy() or nil
    if not attacker or not attacker.getUsername then return end
    counted[zombie]=true
    local s=getStore(); local _,rec=history()

    if isALifeOwned(zombie) then
        local info=getALifeInfo(zombie)
        s.humanContacts.totalKills=(tonumber(s.humanContacts.totalKills) or 0)+1
        for _,snap in ipairs(rec.state or {}) do
            local m=PE.getMission(snap.missionID)
            if m and PE.isEchoMission(m) then
                local rt=runtimeFor(s,m.id)
                for _,req in ipairs(m.echo.requirements or {}) do
                    if req.kind=="human_encounter" then
                        local a=resolveAnchor(s,req.anchor)
                        if (not a) or inAnchor(attacker,a) then
                            local key=tostring(req.anchor or "any")
                            rt.humanKills[key]=(tonumber(rt.humanKills[key]) or 0)+1
                        end
                    end
                end
            end
        end
        if s.journalUnlocked.ALIFE_FIRST_BLOOD~=true then s.journalUnlocked.ALIFE_FIRST_BLOOD=true end
        s.journalEvents[#s.journalEvents+1]={schema=2,hour=nowHours(),kind="human",event="human_killed",faction=info.faction and tostring(info.faction) or nil}
        while #s.journalEvents>200 do table.remove(s.journalEvents,1) end
        persist(s); broadcast(s)
        return
    end

    for _,snap in ipairs(rec.state or {}) do
        local m=PE.getMission(snap.missionID)
        if m and PE.isEchoMission(m) then
            local rt=runtimeFor(s,m.id); rt.kills=(tonumber(rt.kills) or 0)+1
            for _,req in ipairs(m.echo.requirements or {}) do
                if req.kind=="kills_zone" then
                    local a=resolveAnchor(s,req.anchor)
                    if inAnchor(attacker,a) then
                        local k="zoneKills:"..tostring(req.anchor)
                        rt[k]=(tonumber(rt[k]) or 0)+1
                    end
                end
            end
        end
    end
end


local function pushJournalEvent(s,event)
    s.journalEvents=s.journalEvents or {}
    event=type(event)=="table" and event or {kind="field",event="unknown"}
    event.schema=2
    event.hour=tonumber(event.hour) or nowHours()
    event.kind=tostring(event.kind or "field")
    s.journalEvents[#s.journalEvents+1]=event
    while #s.journalEvents>200 do table.remove(s.journalEvents,1) end
end

local function unlockJournal(s,id,reasonType,reasonValue)
    if not id or not PE.JournalEntries or not PE.JournalEntries[id] then return false end
    if s.journalUnlocked[id]==true then return false end
    s.journalUnlocked[id]=true
    pushJournalEvent(s,{kind="journal",event="journal_unlock",journalID=tostring(id),reasonType=tostring(reasonType or "system"),reasonValue=reasonValue and tostring(reasonValue) or nil})
    return true
end

local function unlockMissionJournal(s,missionID)
    for _,id in ipairs((PE.JournalUnlocks and PE.JournalUnlocks[missionID]) or {}) do
        unlockJournal(s,id,"mission",missionID)
    end
end

local function backfillJournal(s)
    unlockJournal(s,"SYS_FIELD_MANUAL","system")
    for id,v in pairs(s.completed or {}) do if v==true then unlockMissionJournal(s,id) end end
end

local function rebuildStructuredJournal(s)
    local rebuilt={}
    local function add(e)
        e.schema=2; e.hour=tonumber(e.hour) or nowHours(); e.kind=tostring(e.kind or "field")
        rebuilt[#rebuilt+1]=e
    end
    local reverse={}
    for missionID,ids in pairs(PE.JournalUnlocks or {}) do
        for _,jid in ipairs(ids or {}) do if not reverse[jid] then reverse[jid]=missionID end end
    end
    local broadcast={}
    for _,row in ipairs(PE.BroadcastJournalTimeline or {}) do broadcast[row.id]=true end
    local ids={}
    for jid,v in pairs(s.journalUnlocked or {}) do if v==true then ids[#ids+1]=jid end end
    table.sort(ids)
    for _,jid in ipairs(ids) do
        local reasonType="system"; local reasonValue=nil
        if jid=="ALIFE_FIRST_CONTACT" then reasonType="first_contact"
        elseif jid=="FIELD_ANOMALY" then reasonType="field"
        elseif broadcast[jid] then reasonType="broadcast"
        elseif reverse[jid] then reasonType="mission"; reasonValue=reverse[jid] end
        add({kind="journal",event="journal_unlock",journalID=jid,reasonType=reasonType,reasonValue=reasonValue})
    end
    local completed={}
    for id,v in pairs(s.completed or {}) do if v==true and PE.getMission(id) then completed[#completed+1]=id end end
    table.sort(completed)
    for _,id in ipairs(completed) do add({kind="mission",event="mission_complete",missionID=id}) end
    if s.currentMain and not s.finished then add({kind="mission",event="mission_started",missionID=tostring(s.currentMain)}) end
    if tonumber(s.humanContacts and s.humanContacts.totalSeen) and tonumber(s.humanContacts.totalSeen)>0 then
        add({kind="human",event="human_seen"})
    end
    if tonumber(s.humanContacts and s.humanContacts.totalKills) and tonumber(s.humanContacts.totalKills)>0 then
        add({kind="human",event="human_killed"})
    end
    if #rebuilt>200 then
        local trimmed={}; for i=#rebuilt-199,#rebuilt do trimmed[#trimmed+1]=rebuilt[i] end; rebuilt=trimmed
    end
    s.journalEvents=rebuilt
    s.journalSchema=2
    return true
end

local function ensureJournalSchema(s)
    local needs=(tonumber(s.journalSchema)~=2)
    if not needs then
        for _,e in ipairs(s.journalEvents or {}) do
            if type(e)~="table" or tonumber(e.schema)~=2 or not e.event then needs=true; break end
        end
    end
    if needs then
        rebuildStructuredJournal(s)
        print("[PROJECT ECHO] journal migrated to structured schema v2")
        return true
    end
    return false
end

local function unlockBroadcastLore(s)
    if not (s.completed and s.completed.PE_M007==true) then return end
    local age=nowHours()
    for _,row in ipairs(PE.BroadcastJournalTimeline or {}) do
        if age>=(tonumber(row.hours) or 0) then unlockJournal(s,row.id,"broadcast") end
    end
end

local function scanHumanContacts(s)
    if not isModActive("ProjectALifeNPCs") then return end
    local _,rec=history()
    local relevant={}
    for _,snap in ipairs(rec.state or {}) do
        local m=PE.getMission(snap.missionID)
        if m and PE.isEchoMission(m) then
            for _,req in ipairs(m.echo.requirements or {}) do
                if req.kind=="human_encounter" then relevant[#relevant+1]={mission=m,req=req} end
            end
        end
    end
    if #relevant==0 then return end
    local cell=getCell and getCell() or nil
    local list=cell and cell.getZombieList and cell:getZombieList() or nil
    if not list then return end
    for _,entry in ipairs(relevant) do
        local rt=runtimeFor(s,entry.mission.id)
        local key=tostring(entry.req.anchor or "any")
        local a=resolveAnchor(s,entry.req.anchor)
        local anyPlayer=false
        for _,p in ipairs(onlinePlayers()) do if (not a) or inAnchor(p,a) then anyPlayer=true; break end end
        if anyPlayer then
            local seen=0
            for i=0,list:size()-1 do
                local z=list:get(i)
                if isALifeOwned(z) then
                    local zx,zy=z:getX(),z:getY()
                    local inZone=(not a) or distance2(zx,zy,a.x,a.y)<=((tonumber(a.radius) or 150)^2)
                    if inZone then
                        seen=seen+1
                        local info=getALifeInfo(z)
                        local uid=tostring(info.uid or (math.floor(zx)..":"..math.floor(zy)))
                        if not s.humanContacts.seenUIDs[uid] then
                            s.humanContacts.seenUIDs[uid]=true
                            s.humanContacts.totalSeen=(tonumber(s.humanContacts.totalSeen) or 0)+1
                            if s.journalUnlocked.ALIFE_FIRST_CONTACT~=true then unlockJournal(s,"ALIFE_FIRST_CONTACT","first_contact") end
                            pushJournalEvent(s,{kind="human",event="human_seen",label=tostring(entry.req.label or entry.req.anchor or PE.textRef("UI_ProjectEcho_Text_0060")),faction=info.faction and tostring(info.faction) or nil})
                        end
                    end
                end
            end
            rt.humanSeen[key]=math.max(tonumber(rt.humanSeen[key]) or 0,seen)
        end
    end
end

local function deepCopy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}
    if seen[value] then return seen[value] end
    local out={}; seen[value]=out
    for k,v in pairs(value) do
        if k~="debugSnapshots" and k~="debugSnapshotOrder" then out[deepCopy(k,seen)]=deepCopy(v,seen) end
    end
    return out
end

local function makeStateSnapshot(s)
    return {
        version=s.version,currentMain=s.currentMain,mainIndex=s.mainIndex,stateMachineVersion=s.stateMachineVersion,campaignEpoch=s.campaignEpoch,rewardSeed=s.rewardSeed,finished=s.finished,startAnchor=s.startAnchor,choice=s.choice,
        completed=deepCopy(s.completed),runtime=deepCopy(s.runtime),cooldowns=deepCopy(s.cooldowns),
        journalUnlocked=deepCopy(s.journalUnlocked),journalEvents=deepCopy(s.journalEvents),journalSchema=tonumber(s.journalSchema) or 2,
        humanContacts=deepCopy(s.humanContacts),eventFlags=deepCopy(s.eventFlags)
    }
end

local function takeDebugSnapshot(s,name)
    name=tostring(name or "manual")
    s.debugSnapshots[name]=makeStateSnapshot(s)
    local out={}; for _,n in ipairs(s.debugSnapshotOrder) do if n~=name then out[#out+1]=n end end
    out[#out+1]=name
    while #out>12 do local old=table.remove(out,1); s.debugSnapshots[old]=nil end
    s.debugSnapshotOrder=out
end

local function restoreDebugSnapshot(s,name)
    local snap=s.debugSnapshots[tostring(name or "")]
    if type(snap)~="table" then return false end
    s.currentMain=snap.currentMain; s.mainIndex=snap.mainIndex; s.stateMachineVersion=snap.stateMachineVersion; s.campaignEpoch=snap.campaignEpoch; s.rewardSeed=snap.rewardSeed; s.finished=snap.finished==true; s.startAnchor=snap.startAnchor; s.choice=snap.choice
    s.completed=deepCopy(snap.completed or {}); s.runtime=deepCopy(snap.runtime or {}); s.cooldowns=deepCopy(snap.cooldowns or {})
    s.journalUnlocked=deepCopy(snap.journalUnlocked or {}); s.journalEvents=deepCopy(snap.journalEvents or {}); s.journalSchema=tonumber(snap.journalSchema) or 1
    s.humanContacts=deepCopy(snap.humanContacts or {seenUIDs={}}); s.eventFlags=deepCopy(snap.eventFlags or {})
    s.humanContacts.seenUIDs=type(s.humanContacts.seenUIDs)=="table" and s.humanContacts.seenUIDs or {}
    return true
end


local function copyStateIntoStore(target,snap)
    if type(target)~="table" or type(snap)~="table" then return false end
    target.version=snap.version or 3
    target.currentMain=snap.currentMain
    target.mainIndex=snap.mainIndex
    target.stateMachineVersion=snap.stateMachineVersion
    target.campaignEpoch=snap.campaignEpoch
    target.rewardSeed=snap.rewardSeed
    target.finished=snap.finished==true
    target.startAnchor=snap.startAnchor
    target.choice=snap.choice
    target.completed=deepCopy(snap.completed or {})
    target.runtime=deepCopy(snap.runtime or {})
    target.cooldowns=deepCopy(snap.cooldowns or {})
    target.journalUnlocked=deepCopy(snap.journalUnlocked or {})
    target.journalEvents=deepCopy(snap.journalEvents or {})
    target.journalSchema=tonumber(snap.journalSchema) or 1
    target.humanContacts=deepCopy(snap.humanContacts or {seenUIDs={}})
    target.eventFlags=deepCopy(snap.eventFlags or {})
    target.humanContacts.seenUIDs=type(target.humanContacts.seenUIDs)=="table" and target.humanContacts.seenUIDs or {}
    return true
end

local function writeRecoveryBackup(s,label)
    local b=ModData.getOrCreate(PE.BackupGlobalKey)
    b.version=1
    b.previous=type(b.latest)=="table" and deepCopy(b.latest) or b.previous
    b.latest=makeStateSnapshot(s)
    b.latestLabel=tostring(label or "checkpoint")
    b.latestHour=nowHours()
    ModData.add(PE.BackupGlobalKey,b)
    return true
end

local function restoreRecoveryBackup(s,which)
    local b=ModData.getOrCreate(PE.BackupGlobalKey)
    local key=(string.lower(tostring(which or "latest"))=="previous") and "previous" or "latest"
    local snap=b[key]
    if type(snap)~="table" then return false,"backup not found: "..key end
    copyStateIntoStore(s,snap)
    return true,"restored recovery backup: "..key
end

local function mainID(index)
    index=tonumber(index)
    if not index or index<1 or index>84 then return nil end
    return string.format("PE_M%03d",index)
end

local function mainNumber(id)
    return tonumber(string.match(tostring(id or ""),"^PE_M(%d+)$"))
end

local function combinedCompleted(s,rec,id)
    return (s.completed and s.completed[id]==true) or (rec and rec.completed and rec.completed[id]==true)
end

local function deriveMainIndexForLegacyMigration(s,rec)
    for i=1,84 do
        local id=mainID(i)
        if not combinedCompleted(s,rec,id) then return i end
    end
    return 85
end

local function normalizeMainState(s,rec,changes)
    changes=changes or {}
    local ver=tonumber(s.stateMachineVersion or 1)
    if ver<2 then
        s.mainIndex=deriveMainIndexForLegacyMigration(s,rec)
        changes[#changes+1]="legacy state machine migrated to v2 baseline"
    elseif not s.mainIndex then
        local n=mainNumber(s.currentMain)
        s.mainIndex=n or (s.finished and 85 or 1)
        changes[#changes+1]="mainIndex reconstructed from authoritative ECHO state"
    end
    if ver<3 then
        s.stateMachineVersion=3
        changes[#changes+1]="state machine migrated to v3 transactional mode"
    end
    local idx=math.floor(tonumber(s.mainIndex) or 1)
    if idx<1 then idx=1; changes[#changes+1]="mainIndex clamped" end
    if idx>85 then idx=85; changes[#changes+1]="mainIndex clamped" end
    s.mainIndex=idx
    for i=1,84 do
        local id=mainID(i)
        if i<idx then s.completed[id]=true else s.completed[id]=nil end
    end
    if idx<=84 then s.currentMain=mainID(idx); s.finished=false else s.currentMain=nil; s.finished=true end
    return true
end

local function newRewardSeed(s)
    return tostring(TM42.getRealWorldTimestamp())..":"..tostring(nowHours())..":"..tostring((tonumber(s.campaignEpoch) or 1)+1)..":"..tostring((tonumber(s.revision) or 0)+1)
end

local function applyCampaignRewards(s,rebuild)
    if not s.rewardSeed or s.rewardSeed=="" then s.rewardSeed=newRewardSeed(s) end
    local changed=PE.applyRewardSeed and PE.applyRewardSeed(s.rewardSeed) or false
    if rebuild and changed and TM42.rebuildMissionRegistry then TM42.rebuildMissionRegistry(true) end
    return changed
end

local function repairState(s)
    local changes={}
    local _,rec=history()
    normalizeMainState(s,rec,changes)
    if not s.rewardSeed or s.rewardSeed=="" then s.rewardSeed=newRewardSeed(s); changes[#changes+1]="reward seed created" end
    applyCampaignRewards(s,false)
    backfillJournal(s)
    if ensureJournalSchema(s) then changes[#changes+1]="journal schema migrated" end
    return changes
end

local function forceObjectiveDone(s,missionID,index)
    local m=PE.getMission(missionID); local req=m and m.echo and m.echo.requirements and m.echo.requirements[tonumber(index)] or nil
    if not req then return false,"objective not found" end
    local rt=runtimeFor(s,missionID); local k=req.kind
    if k=="start_region" then s.startAnchor=s.startAnchor or "start_muldraugh"
    elseif k=="start_hold" then rt.hold["$START"]=tonumber(req.hours) or 1
    elseif k=="start_interact" then rt.interacted["$START"]=true
    elseif k=="zone" then rt.visited[req.anchor]=true
    elseif k=="visit_zones" then for _,id in ipairs(req.anchors or {}) do rt.visited[id]=true end
    elseif k=="kills" then rt.kills=math.max(tonumber(rt.kills) or 0,tonumber(req.count) or 1)
    elseif k=="kills_zone" then rt["zoneKills:"..tostring(req.anchor)]=tonumber(req.count) or 1
    elseif k=="human_encounter" then rt.humanKills[tostring(req.anchor or "any")]=tonumber(req.kills) or 1
    elseif k=="distance" then rt[req.onFoot and "distanceFoot" or "distance"]=tonumber(req.meters) or 1
    elseif k=="survive" then rt.startedAt=nowHours()-(tonumber(req.hours) or 1)-0.1
    elseif k=="hold" then rt.hold[req.anchor]=tonumber(req.hours) or 1
    elseif k=="items" then return false,"items objective cannot be safely forged; use complete mission if needed"
    elseif k=="interact" then rt.interacted[req.anchor]=true
    elseif k=="vehicle_zone" then rt.visited["vehicle:"..tostring(req.anchor)..":"..tostring(req.invert==true)]=true
    elseif k=="choice" then rt.choices[tonumber(index) or 1]="debug"; s.choice=s.choice or "debug"
    else return false,"unknown objective kind: "..tostring(k) end
    return true,"forced "..tostring(k)
end

local function advanceMain(s,completedID)
    local idx=mainNumber(completedID)
    if not idx or s.currentMain~=completedID or tonumber(s.mainIndex)~=idx then return false end
    s.transitionSerial=(tonumber(s.transitionSerial) or 0)+1
    s.mainIndex=idx+1
    if s.mainIndex<=84 then s.currentMain=mainID(s.mainIndex); s.finished=false else s.currentMain=nil; s.finished=true end
    return true
end

local transitionBusy=false
local function completeEchoFromTM(player,missionID)
    local m=PE.getMission(missionID)
    if not m or not PE.isEchoMission(m) then return end
    local s=getStore(); ProgressGuard.beforePersist(s); local _,recBefore=history()
    stateLog("CLAIM_ACK","MissionSuccess",player,s,recBefore,"mission="..tostring(missionID))
    if transitionBusy then stateLog("CLAIM_ACK_IGNORED","transition_busy",player,s,recBefore,"mission="..tostring(missionID)); return end
    if m.track=="main" and missionID~=s.currentMain then
        stateLog("CLAIM_ACK_IGNORED","stale_main",player,s,recBefore,"mission="..tostring(missionID))
        local rec=syncHistory(s,"stale_claim_ack",false); if player then mirrorToPlayer(player,s,rec) end; broadcast(s); return
    end
    if s.completed[m.id]==true and not m.repeatable then
        stateLog("CLAIM_ACK_IGNORED","already_completed",player,s,recBefore,"mission="..tostring(missionID))
        local rec=syncHistory(s,"duplicate_claim_ack",false); if player then mirrorToPlayer(player,s,rec) end; broadcast(s); return
    end
    local pct,_,ready=missionProgress(s,m)
    if not ready then
        stateLog("CLAIM_ACK_IGNORED","not_ready",player,s,recBefore,"mission="..tostring(m.id).." pct="..tostring(math.floor((pct or 0)+0.5)))
        return
    end

    transitionBusy=true
    stateLog("TRANSITION_BEGIN","claim",player,s,recBefore,"mission="..tostring(m.id))
    local ok,err=pcall(function()
        local gh,rec=history()
        -- MissionSuccess means The Mission accepted CLAIM. Pay the claimant in
        -- PhunMart CHANGE exactly once on this authoritative transition. Economy
        -- failure is non-blocking: the payout receipt remains as recovery proof.
        local economyOK,economyInfo=false,"adapter missing"
        if PE.grantPhunMartMissionReward then
            local callOK,a,b=pcall(PE.grantPhunMartMissionReward,player,m.id)
            if callOK then economyOK,economyInfo=a,b else economyInfo=tostring(a) end
        end
        stateLog(economyOK and "ECONOMY_REWARD" or "ECONOMY_FALLBACK","claim",player,s,rec,tostring(economyInfo))
        if m.repeatable then
            s.cooldowns[m.id]=nowHours()+24; s.runtime[m.id]=nil; removeState(rec,m.id)
        else
            takeDebugSnapshot(s,"auto_prev"); writeRecoveryBackup(s,"before_"..tostring(m.id))
            s.completed[m.id]=true; s.runtime[m.id]=nil; removeState(rec,m.id)
            unlockMissionJournal(s,m.id)
            pushJournalEvent(s,{kind="mission",event="mission_complete",missionID=tostring(m.id)})
            if m.track=="main" then
                local moved=advanceMain(s,m.id)
                if moved and s.currentMain and not s.finished then
                    pushJournalEvent(s,{kind="mission",event="mission_started",missionID=tostring(s.currentMain)})
                end
                takeDebugSnapshot(s,"auto_current"); takeDebugSnapshot(s,"after_"..tostring(m.id))
            end
        end
        persist(s)
        local canonical=syncHistory(s,"transition_commit",true)
        stateLog("TRANSITION_COMMIT","claim",player,s,canonical,"completed="..tostring(m.id).." next="..tostring(s.currentMain))
        broadcast(s)
    end)
    transitionBusy=false
    if not ok then
        stateLog("TRANSITION_ERROR","claim",player,s,nil,tostring(err))
        print("[PROJECT ECHO] transition error: "..tostring(err))
        return
    end
    print("[PROJECT ECHO] completed "..tostring(m.id).." track="..tostring(m.track).." next="..tostring(s.currentMain).." mainIndex="..tostring(s.mainIndex))
end

local function validateInteract(player,s,mission,req,index)
    if not player or not mission or not req then return false end
    local anchorID=req.kind=="start_interact" and "$START" or req.anchor
    local a=resolveAnchor(s,anchorID)
    if not a or not inAnchor(player,a) then return false end
    local rt=runtimeFor(s,mission.id)
    if req.kind=="interact" then rt.interacted[req.anchor]=true; return true end
    if req.kind=="start_interact" then rt.interacted["$START"]=true; return true end
    if req.kind=="choice" then return true end
    return false
end

local function isAdmin(player)
    if not player then return false end
    if player.isAccessLevel then
        local ok,allowed=pcall(function() return player:isAccessLevel("admin") end)
        if ok and allowed==true then return true end
    end
    if player.getAccessLevel then
        local ok,level=pcall(function() return player:getAccessLevel() end)
        if ok and string.lower(tostring(level or ""))=="admin" then return true end
    end
    return false
end

local function adminSkipCurrent(player)
    if not isAdmin(player) then return end
    local s=getStore(); local id=s.currentMain
    local m=id and PE.getMission(id) or nil
    if not m then return end
    takeDebugSnapshot(s,"auto_prev")
    writeRecoveryBackup(s,"before_admin_skip_"..tostring(id))
    local gh,rec=history()
    s.completed[id]=true
    s.runtime[id]=nil
    unlockMissionJournal(s,id)
    pushJournalEvent(s,{kind="debug",event="debug",titleText="ADMIN skip",bodyText=tostring(id)})
    rec.completed[id]=true
    removeState(rec,id)
    gh[PE.SharedHistoryKey]=rec
    ModData.add(TM42.GlobalHistoryKey,gh)
    advanceMain(s,id)
    pushJournalEvent(s,{kind="mission",event="mission_complete",missionID=tostring(id)})
    if s.currentMain then pushJournalEvent(s,{kind="mission",event="mission_started",missionID=tostring(s.currentMain)}) end
    takeDebugSnapshot(s,"auto_current")
    print("[PROJECT ECHO] ADMIN skipped "..tostring(id).." next="..tostring(s.currentMain))
    persist(s); syncHistory(s,"state_change",true); broadcast(s)
end

local function adminResetCurrent(player)
    if not isAdmin(player) then return end
    local s=getStore(); local id=s.currentMain
    if not id then return end
    s.runtime[id]=nil
    print("[PROJECT ECHO] ADMIN reset runtime for "..tostring(id))
    persist(s); syncHistory(s,"state_change",true); broadcast(s)
end


local function debugReply(player,lines)
    if type(lines)~="table" then lines={tostring(lines)} end
    sendServerCommand(player,PE.Module,"DebugResult",{lines=lines})
end

local function completedMainCount(s)
    local n=0; for i=1,84 do if s.completed[string.format("PE_M%03d",i)]==true then n=n+1 end end; return n
end

local function debugStatus(s)
    local _,rec=history(); local current=s.currentMain and PE.getMission(s.currentMain) or nil
    local lines={
        "PROJECT ECHO "..tostring(PE.VERSION),
        "current="..tostring(s.currentMain).." / "..tostring(current and current.title or "nil"),
        "finished="..tostring(s.finished).." completedMain="..tostring(completedMainCount(s)).."/84",
        "start="..tostring(s.startAnchor).." revision="..tostring(s.revision).." mainIndex="..tostring(s.mainIndex),
        "rewardSeed="..tostring(s.rewardSeed).." tier="..tostring(current and current.rewardTier or "nil"),
        "co-op balance=shared 6-8 players; current payout="..tostring(current and PE.getMissionCreditAmount and PE.getMissionCreditAmount(current.id) or 0).." cents",
        "PhunMart="..tostring((function() if not PE.getPhunMartAdapterStatus then return "false (adapter missing)" end; local ok,info=PE.getPhunMartAdapterStatus(); return tostring(ok).." ("..tostring(info)..")" end)()),
        "TM active states="..tostring(#(rec.state or {})),
        "journal="..tostring((function() local n=0 for _,v in pairs(s.journalUnlocked or {}) do if v then n=n+1 end end return n end)()),
        "A-Life="..tostring(isModActive("ProjectALifeNPCs")).." seen="..tostring(s.humanContacts.totalSeen).." humanKills="..tostring(s.humanContacts.totalKills),
        "Special zones: TheMutants="..tostring(isModActive("PZTheMutants")).." CryOfFear="..tostring(isModActive("CryOfFearMonsters")),
    }
    if current then local pct,text=missionProgress(s,current); lines[#lines+1]=string.format("progress=%.1f%%",pct); lines[#lines+1]=text end
    return lines
end

local function debugDoctor(s)
    local lines={"PROJECT ECHO DOCTOR"}
    local bad=0
    if s.currentMain and not PE.getMission(s.currentMain) then bad=bad+1; lines[#lines+1]="[FAIL] currentMain missing in registry: "..tostring(s.currentMain) else lines[#lines+1]="[PASS] currentMain registry" end
    if s.currentMain and s.completed[s.currentMain] then bad=bad+1; lines[#lines+1]="[FAIL] currentMain is already completed" else lines[#lines+1]="[PASS] currentMain completion state" end
    local expected=mainID(tonumber(s.mainIndex) or 1)
    if (s.finished and s.currentMain==nil) or (not s.finished and expected==s.currentMain) then lines[#lines+1]="[PASS] mainIndex/currentMain state machine" else bad=bad+1; lines[#lines+1]="[FAIL] mainIndex/currentMain mismatch" end
    local missingAnchors=0
    for _,m in ipairs(PE.Missions or {}) do for _,req in ipairs((m.echo and m.echo.requirements) or {}) do
        if req.anchor and req.anchor~="$START" and not PE.Anchors[req.anchor] then missingAnchors=missingAnchors+1 end
        for _,a in ipairs(req.anchors or {}) do if a~="$START" and not PE.Anchors[a] then missingAnchors=missingAnchors+1 end end
    end end
    if missingAnchors>0 then bad=bad+1; lines[#lines+1]="[FAIL] missing anchor refs="..tostring(missingAnchors) else lines[#lines+1]="[PASS] anchor refs" end
    local _,rec=history(); lines[#lines+1]="[INFO] TM states="..tostring(#(rec.state or {}))
    lines[#lines+1]="[INFO] A-Life="..tostring(isModActive("ProjectALifeNPCs")).." (human bodies excluded from zombie counters)"
    lines[#lines+1]="[INFO] The Mutants="..tostring(isModActive("PZTheMutants")).." CryOfFear="..tostring(isModActive("CryOfFearMonsters"))
    if not isModActive("PZTheMutants") then bad=bad+1; lines[#lines+1]="[FAIL] PZTheMutants missing" else lines[#lines+1]="[PASS] PZTheMutants active" end
    if not isModActive("CryOfFearMonsters") then bad=bad+1; lines[#lines+1]="[FAIL] CryOfFearMonsters missing" else lines[#lines+1]="[PASS] CryOfFearMonsters active" end
    lines[#lines+1]=bad==0 and "DOCTOR: PASS" or ("DOCTOR: "..tostring(bad).." issue(s); run repair if state-related")
    return lines
end

local function forceCompleteMission(s,id)
    local m=PE.getMission(id); if not m then return false,"mission not found" end
    s.completed[id]=true; s.runtime[id]=nil; unlockMissionJournal(s,id); pushJournalEvent(s,{kind="debug",event="debug",titleText="ADMIN complete",bodyText=tostring(id)}); pushJournalEvent(s,{kind="mission",event="mission_complete",missionID=tostring(id)})
    local gh,rec=history(); rec.completed[id]=true; removeState(rec,id); gh[PE.SharedHistoryKey]=rec; ModData.add(TM42.GlobalHistoryKey,gh)
    if m.track=="main" and s.currentMain==id then advanceMain(s,id); if s.currentMain then pushJournalEvent(s,{kind="mission",event="mission_started",missionID=tostring(s.currentMain)}) end end
    return true,"completed "..id.." next="..tostring(s.currentMain)
end

local function setMainMission(s,id)
    local m=PE.getMission(id); local n=mainNumber(id); if not m or m.track~="main" or not n then return false,"main mission not found" end
    s.mainIndex=n; s.currentMain=id; s.finished=false; s.stateMachineVersion=3
    for i=n,84 do local mid=mainID(i); s.completed[mid]=nil; s.runtime[mid]=nil end
    local gh,rec=history(); for i=n,84 do local mid=mainID(i); rec.completed[mid]=nil; removeState(rec,mid) end
    ensureActive(rec,id); gh[PE.SharedHistoryKey]=rec; ModData.add(TM42.GlobalHistoryKey,gh)
    rebuildStructuredJournal(s)
    return true,"currentMain="..id
end

local function rewindTo(s,id)
    local n=mainNumber(id); if not n or not PE.getMission(id) then return false,"invalid main mission" end
    local gh,rec=history()
    for i=n,84 do local mid=mainID(i); s.completed[mid]=nil; s.runtime[mid]=nil; rec.completed[mid]=nil; removeState(rec,mid) end
    s.mainIndex=n; s.currentMain=id; s.finished=false; s.stateMachineVersion=3; ensureActive(rec,id)
    gh[PE.SharedHistoryKey]=rec; ModData.add(TM42.GlobalHistoryKey,gh)
    rebuildStructuredJournal(s); pushJournalEvent(s,{kind="debug",event="debug",titleText="ADMIN rewind",bodyText=tostring(id)})
    return true,"rewound to "..id
end

local function restartCampaign(s)
    writeRecoveryBackup(s,"before_restart_campaign")
    local keepAnchor=s.startAnchor
    s.completed={}; s.runtime={}; s.cooldowns={}; s.journalUnlocked={}; s.journalEvents={}; s.journalSchema=2
    s.humanContacts={seenUIDs={},totalSeen=0,totalKills=0}; s.eventFlags={}; s.specialEncounters={}; s.specialStats={}
    s.choice=nil; s.currentMain="PE_M001"; s.mainIndex=1; s.finished=false; s.stateMachineVersion=3
    s.campaignEpoch=(tonumber(s.campaignEpoch) or 1)+1; s.rewardSeed=newRewardSeed(s); s.startAnchor=keepAnchor
    local gh=ModData.getOrCreate(TM42.GlobalHistoryKey)
    local rec={completed={},resetAt=TM42.getRealWorldTimestamp(),cooldowns={},state={},claims={}}
    ensureActive(rec,"PE_M001"); gh[PE.SharedHistoryKey]=rec; ModData.add(TM42.GlobalHistoryKey,gh)
    unlockJournal(s,"SYS_FIELD_MANUAL","system")
    pushJournalEvent(s,{kind="mission",event="mission_started",missionID="PE_M001"})
    applyCampaignRewards(s,true)
    takeDebugSnapshot(s,"auto_current")
    return true,"campaign restarted at PE_M001; PhunMart payout state reset; world/characters untouched"
end

local function normalizeDebugCommand(raw)
    raw=tostring(raw or ""):gsub("^%s+",""):gsub("%s+$","")
    local arg=raw:match('^ProjectEcho%.Debug%.forceComplete%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "complete "..arg end
    if raw:match('^ProjectEcho%.Debug%.completeCurrent%(%s*%)$') then return "complete current" end
    arg=raw:match('^ProjectEcho%.Debug%.setMain%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "setmain "..arg end
    arg=raw:match('^ProjectEcho%.Debug%.resetMission%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "reset "..arg end
    if raw:match('^ProjectEcho%.Debug%.resetCurrent%(%s*%)$') then return "reset current" end
    local oi=raw:match('^ProjectEcho%.Debug%.forceObjective%(%s*(%d+)%s*%)$')
    if oi then return "objective current "..oi end
    arg=raw:match('^ProjectEcho%.Debug%.snapshot%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "snapshot "..arg end
    arg=raw:match('^ProjectEcho%.Debug%.restore%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "restore "..arg end
    arg=raw:match('^ProjectEcho%.Debug%.restoreBackup%(%s*["\\\']([^"\\\']+)["\\\']%s*%)$')
    if arg then return "restorebackup "..arg end
    if raw:match('^ProjectEcho%.Debug%.status%(%s*%)$') then return "status" end
    if raw:match('^ProjectEcho%.Debug%.doctor%(%s*%)$') then return "doctor" end
    if raw:match('^ProjectEcho%.Debug%.repair%(%s*%)$') then return "repair" end
    if raw:match('^ProjectEcho%.Debug%.recover%(%s*%)$') then return "recover" end
    if raw:match('^ProjectEcho%.Debug%.resync%(%s*%)$') then return "resync" end
    if raw:match('^ProjectEcho%.Debug%.restartCampaign%(%s*%)$') then return "restart campaign" end
    return raw
end

local function runDebugCommand(player,raw)
    if not isAdmin(player) then return {"[DENIED] admin access required"} end
    local s=getStore(); local cmd=normalizeDebugCommand(raw); local low=string.lower(cmd)
    local function currentID(value)
        value=tostring(value or "")
        if string.lower(value)=="current" then return s.currentMain end
        return value
    end
    if low=="help" or low=="?" then
        local out={PE.textRef("UI_ProjectEcho_Text_0062")}
        for _,x in ipairs(PE.DebugHelp or {}) do out[#out+1]=x end
        out[#out+1]="Advanced ID-jump commands are intentionally hidden to avoid spoilers."
        return out
    end
    if low=="help advanced" then
        local out={PE.textRef("UI_ProjectEcho_Text_0063")}
        for _,x in ipairs(PE.DebugAdvancedHelp or {}) do out[#out+1]=x end
        return out
    end
    if string.sub(low,1,7)=="special" and PE.SpecialDebugCommand then local r=PE.SpecialDebugCommand(player,cmd,s); if r then return r end end
    if low=="status" or low=="current" then return debugStatus(s) end
    if low=="doctor" then return debugDoctor(s) end
    if low=="repair" then
        local changes=repairState(s); persist(s); syncHistory(s,"state_change",true); broadcast(s)
        local out={"REPAIR complete"}; if #changes==0 then out[#out+1]="No state repair was necessary" else for _,x in ipairs(changes) do out[#out+1]="- "..x end end
        return out
    end
    if low=="recover" or low=="softlock" then
        writeRecoveryBackup(s,"before_recover")
        local changes=repairState(s)
        syncHistory(s,"state_change",true); persist(s); broadcast(s)
        local out={"SOFTLOCK RECOVERY complete","Recovery backup created before changes."}
        if #changes==0 then out[#out+1]="State looked consistent; history was re-synced." else for _,x in ipairs(changes) do out[#out+1]="- "..x end end
        return out
    end
    if low=="restart campaign" then
        local ok,msg=restartCampaign(s); if ok then ProgressGuard.authorizeRewind("restart_campaign") end; persist(s); local rec=syncHistory(s,"state_change",true); broadcast(s)
        stateLog("CAMPAIGN_RESTART","admin",player,s,rec,"epoch="..tostring(s.campaignEpoch))
        return {ok and "[OK]" or "[FAIL]",msg,"Recovery backup: before_restart_campaign"}
    end
    if low=="backup" then writeRecoveryBackup(s,"manual"); return {"[OK] recovery backup saved","Use: restorebackup latest"} end
    local which=cmd:match("^restorebackup%s+(%S+)$")
    if which then
        local ok,msg=restoreRecoveryBackup(s,which)
        if ok then repairState(s); ProgressGuard.authorizeRewind("restorebackup"); persist(s); syncHistory(s,"state_change",true); broadcast(s) end
        return {ok and "[OK]" or "[FAIL]",msg}
    end
    if low=="journal repair" then backfillJournal(s); unlockBroadcastLore(s); rebuildStructuredJournal(s); persist(s); broadcast(s); return {"[OK] journal rebuilt from completed campaign history"} end

    local id=cmd:match("^mission%s+(%S+)$")
    if id then
        id=currentID(id); local m=id and PE.getMission(id) or nil
        if not m then return {"mission not found"} end
        local pct,text=missionProgress(s,m)
        return {id.." | "..tostring(m.title),tostring(m.description),string.format("progress %.1f%%",pct),text}
    end
    id=cmd:match("^complete%s+(%S+)$")
    if id then
        id=currentID(id); if not id then return {"[FAIL] no current mission"} end
        takeDebugSnapshot(s,"auto_prev"); writeRecoveryBackup(s,"before_admin_complete_"..id)
        local ok,msg=forceCompleteMission(s,id); persist(s); syncHistory(s,"state_command",true); broadcast(s); return {ok and "[OK]" or "[FAIL]",msg}
    end
    id=cmd:match("^setmain%s+(%S+)$")
    if id then local ok,msg=setMainMission(s,id); if ok then ProgressGuard.authorizeRewind("setmain") end; persist(s); syncHistory(s,"state_command",true); broadcast(s); return {ok and "[OK]" or "[FAIL]",msg} end
    id=cmd:match("^rewind%s+(%S+)$")
    if id then
        id=currentID(id); if not id then return {"[FAIL] no current mission"} end
        writeRecoveryBackup(s,"before_rewind_"..id)
        local ok,msg=rewindTo(s,id); if ok then ProgressGuard.authorizeRewind("rewind") end; persist(s); syncHistory(s,"state_command",true); broadcast(s); return {ok and "[OK]" or "[FAIL]",msg}
    end
    id=cmd:match("^reset%s+(%S+)$")
    if id then
        id=currentID(id); if not id then return {"[FAIL] no current mission"} end
        s.runtime[id]=nil; local gh,rec=history(); removeState(rec,id); if s.currentMain==id then ensureActive(rec,id) end; gh[PE.SharedHistoryKey]=rec; ModData.add(TM42.GlobalHistoryKey,gh); persist(s); syncHistory(s,"state_command",true); broadcast(s); return {"[OK] reset runtime/state for "..id}
    end
    local oid,oi=cmd:match("^objective%s+(%S+)%s+(%d+)$")
    if oid then
        oid=currentID(oid); if not oid then return {"[FAIL] no current mission"} end
        local ok,msg=forceObjectiveDone(s,oid,tonumber(oi)); persist(s); broadcast(s); return {ok and "[OK]" or "[FAIL]",msg}
    end
    local name=cmd:match("^snapshot%s+(.+)$")
    if name then takeDebugSnapshot(s,name); persist(s); return {"[OK] snapshot saved: "..name} end
    name=cmd:match("^restore%s+(.+)$")
    if name then
        writeRecoveryBackup(s,"before_restore_"..name)
        local ok=restoreDebugSnapshot(s,name)
        if ok then repairState(s); ProgressGuard.authorizeRewind("restore_snapshot"); persist(s); syncHistory(s,"state_command",true); broadcast(s); return {"[OK] restored: "..name} end
        return {"[FAIL] snapshot not found: "..name}
    end
    local jid=cmd:match("^journal%s+unlock%s+(%S+)$")
    if jid then local ok=unlockJournal(s,jid,"admin","ADMIN unlock"); persist(s); broadcast(s); return {ok and "[OK] unlocked "..jid or "[INFO] already unlocked / unknown id"} end
    if low=="journal unlockall" then local n=0; for jid in pairs(PE.JournalEntries or {}) do if unlockJournal(s,jid,"admin","ADMIN unlockall") then n=n+1 end end; persist(s); broadcast(s); return {"[OK] unlocked entries: "..tostring(n)} end
    local aid=cmd:match("^anchor%s+(%S+)$")
    if aid then local a=PE.Anchors[aid]; if not a then return {"[FAIL] anchor not found"} end; return {aid.." | "..tostring(a.name),"x="..tostring(a.x).." y="..tostring(a.y).." z="..tostring(a.z).." r="..tostring(a.radius)} end
    if low=="resync" then repairState(s); persist(s); syncHistory(s,"state_command",true); broadcast(s); return {"[OK] server/client history resynced"} end
    if low=="state log" then
        local _,rec=history(); stateLog("ADMIN_MARK","state_log",player,s,rec,"manual marker")
        return {"[OK] state marker written","Zomboid/Lua/"..STATE_LOG_FILE,stateLine("SNAPSHOT","debug",player,s,rec)}
    end
    if low=="dump" then
        local lines=debugStatus(s)
        local ok,err=pcall(function() local w=getFileWriter("ProjectEcho_DebugDump.txt",true,false); for _,line in ipairs(lines) do w:write(tostring(line).."\\n") end; w:close() end)
        lines[#lines+1]=ok and "[OK] wrote Zomboid/Lua/ProjectEcho_DebugDump.txt" or ("[WARN] dump file failed: "..tostring(err)); return lines
    end
    return {"[ERROR] unknown command: "..cmd,"Type: help"}
end

local function detectHistoryDrift(s,reason,player)
    local _,rec=history()
    local expectedCurrent=s.currentMain
    local activeMain={}
    for _,snap in ipairs(rec.state or {}) do
        local m=snap and PE.getMission(snap.missionID) or nil
        if m and PE.isEchoMission(m) and m.track=="main" then activeMain[#activeMain+1]=snap.missionID end
    end
    local drift=false
    if #activeMain~=((expectedCurrent and not s.finished) and 1 or 0) then drift=true end
    if expectedCurrent and #activeMain==1 and activeMain[1]~=expectedCurrent then drift=true end
    if expectedCurrent and rec.completed and rec.completed[expectedCurrent]==true and not (s.completed and s.completed[expectedCurrent]==true) then drift=true end
    if drift then stateLog("HISTORY_DRIFT",reason,player,s,rec,"activeMain="..table.concat(activeMain,",")) end
    return drift
end

local function onClientCommand(module,command,player,args)
    if module~=PE.Module or not player then return end
    if command=="AdminSkipCurrent" then adminSkipCurrent(player); return end
    if command=="AdminResetCurrent" then adminResetCurrent(player); return end
    if command=="DebugExec" then debugReply(player,runDebugCommand(player,args and args.command or "")); return end
    if command=="MissionSuccessAck" and args and args.missionID then
        local missionID=tostring(args.missionID)
        local m=PE.getMission(missionID)
        if not m or not PE.isEchoMission(m) then return end
        -- MissionSuccess itself is the proof that The Mission accepted CLAIM. Do not
        -- read its mutable completed table back into ECHO; that table is only a mirror.
        completeEchoFromTM(player,missionID)
        return
    end
    local s=getStore(); ProgressGuard.beforePersist(s); local key=knownPlayerKey(player); if key then s.knownPlayers[key]=true end
    if command=="RequestSync" then
        detectHistoryDrift(s,"request_sync",player)
        local rec=syncHistory(s,"request_sync",false)
        mirrorToPlayer(player,s,rec)
        sendServerCommand(player,PE.Module,"Sync",clientSnapshot(s))
        stateLog("SYNC_REQUEST","client",player,s,rec)
        return
    end
    if command=="Interact" and args and args.missionID and args.reqIndex then
        local m=PE.getMission(tostring(args.missionID)); local idx=tonumber(args.reqIndex)
        local req=m and m.echo and m.echo.requirements and m.echo.requirements[idx] or nil
        if m and req and validateInteract(player,s,m,req,idx) then persist(s); broadcast(s) end
        return
    end
    if command=="Choose" and args and args.missionID and args.reqIndex and args.choice then
        local m=PE.getMission(tostring(args.missionID)); local idx=tonumber(args.reqIndex)
        local req=m and m.echo and m.echo.requirements and m.echo.requirements[idx] or nil
        if not m or not req or req.kind~="choice" then return end
        local a=resolveAnchor(s,req.anchor); if a and not inAnchor(player,a) then return end
        local valid=false
        for _,c in ipairs(req.choices or {}) do if c.id==args.choice then valid=true break end end
        if valid then
            local rt=runtimeFor(s,m.id); rt.choices[idx]=args.choice; s.choice=args.choice
            print("[PROJECT ECHO] final/server choice: "..tostring(args.choice))
            persist(s); broadcast(s)
        end
    end
end


local lastTickHours=nil; local tickCounter=0
local function onTick()
    peServerTickObserved = true
    tickCounter=tickCounter+1
    if tickCounter%180~=0 then return end
    local s=getStore(); ProgressGuard.beforePersist(s); local now=nowHours(); local delta=0
    if lastTickHours then delta=math.max(0,math.min(0.25,now-lastTickHours)) end
    lastTickHours=now
    markVisitedAndHolds(s,delta); trackDistance(s); scanHumanContacts(s); unlockBroadcastLore(s)
    local _,rec=history()
    local current=s.currentMain and PE.getMission(s.currentMain) or nil
    if current then
        runtimeFor(s,current.id)
        local pct=missionProgress(s,current)
        local ip=math.floor((tonumber(pct) or 0)+0.5)
        if lastLoggedProgress[current.id]~=ip then
            lastLoggedProgress[current.id]=ip
            stateLog("PROGRESS","tick",nil,s,rec,"mission="..tostring(current.id).." pct="..tostring(ip))
        end
    end
    -- IMPORTANT v0.9.9: progress ticks never rewrite The Mission ACTIVE/DONE state.
    persist(s); broadcast(s)
end

local function onInitGlobalModData()
    -- The Mission restores its persistent admin/runtime catalog in the same event.
    -- PROJECT ECHO is registered after TheMission42, so clear that runtime layer here
    -- and rebuild our static campaign once GlobalModData is fully available.
    TM42.RuntimeMissionDefs = {}
    TM42.RuntimeDisabledMissionIds = {}
    TM42.RuntimeCatalogRevision = 0
    TM42.rebuildMissionRegistry(true)
    enforceServerPolicy()
    print("[PROJECT ECHO][STATE] server policy active: TM42 reset=OFF; vanilla sprinters=1%")
    local s=getStore()
    stateLog("INIT_BEGIN","server_start",nil,s,nil,"version="..tostring(PE.VERSION))
    backfillJournal(s); unlockBroadcastLore(s)
    -- Recovery runs BEFORE reward-seed initialization, so a missing/corrupted
    -- GlobalModData campaign can be recovered from the external ledger.
    local recovered=ProgressGuard.startup(s)
    local changes=repairState(s)
    if recovered then
        -- Reconstruct journal metadata without duplicating payouts or CLAIM events.
        backfillJournal(s)
        rebuildStructuredJournal(s)
        changes[#changes+1]="independent checkpoint restored campaign progression"
    end
    applyCampaignRewards(s,true)
    logTM42API()
    detectHistoryDrift(s,"init_before_canonical",nil)
    local hasCurrentStart=false
    for _,e in ipairs(s.journalEvents or {}) do
        if type(e)=="table" and e.event=="mission_started" and tostring(e.missionID or "")==tostring(s.currentMain or "") then hasCurrentStart=true; break end
    end
    if not hasCurrentStart and s.currentMain then pushJournalEvent(s,{kind="mission",event="mission_started",missionID=tostring(s.currentMain)}) end
    local rb=ModData.getOrCreate(PE.BackupGlobalKey)
    if type(rb.latest)~="table" then writeRecoveryBackup(s,"initial") end
    -- WORLD_READY startup guard:
    -- OnInitGlobalModData fires before GameServer.udpEngine exists on dedicated B42.
    -- Do not enumerate/mirror online players here. Joining clients request a fresh
    -- authoritative sync after networking is ready.
    local rec=syncHistory(s,"init",false); persist(s); clientSnapshot(s)
    stateLog("INIT_READY","server_start",nil,s,rec,"repairChanges="..tostring(#changes))
    print("[PROJECT ECHO] campaign state ready, current="..tostring(s.currentMain).." mainIndex="..tostring(s.mainIndex).." repairChanges="..tostring(#changes).." rewardSeed="..tostring(s.rewardSeed))
    print("[PROJECT ECHO][STATE] detailed log: Zomboid/Lua/"..STATE_LOG_FILE)
end

if Events.OnClientCommand then Events.OnClientCommand.Add(onClientCommand) end
if Events.OnZombieDead then Events.OnZombieDead.Add(onZombieDead) end
if Events.OnInitGlobalModData then Events.OnInitGlobalModData.Add(onInitGlobalModData) end
if Events.OnTick then Events.OnTick.Add(onTick) end
