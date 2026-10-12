-- PROJECT ECHO - client sync and contextual interactions
require "ProjectEcho_Core"
require "ProjectEcho_Missions"
require "ProjectEcho_JournalData"
require "ProjectEcho_StoryEnhancements"
require "ProjectEcho_JournalUI"
require "ProjectEcho_DebugUI"
require "ProjectEcho_UICompat"
pcall(require, "ISUI/ISContextMenu")
if ProjectEcho.Disabled then return end

local PE=ProjectEcho

local function requestSync(player)
    player=player or getPlayer()
    if player then sendClientCommand(player,PE.Module,"RequestSync",{}) end
end

local function countUnlocked(t)
    local n=0; for _,v in pairs(t or {}) do if v==true then n=n+1 end end; return n
end

local function onServerCommand(module,command,args)
    if module==TM42.Module and command=="MissionSuccess" and type(args)=="table" and args.missionID then
        local player=getPlayer(); local mission=PE.getMission(tostring(args.missionID))
        if player and mission and PE.isEchoMission(mission) then sendClientCommand(player,PE.Module,"MissionSuccessAck",{missionID=mission.id}) end
        return
    end
    if module~=PE.Module then return end
    if command=="DebugResult" and type(args)=="table" then
        local lines=args.lines or {}
        for _,line in ipairs(lines) do print("[PROJECT ECHO DEBUG] "..tostring(line)) end
        if PE_DebugWindow and PE_DebugWindow.instance then PE_DebugWindow.instance:onResult(lines) end
        return
    end
    if command~="Sync" or type(args)~="table" then return end
    local old=countUnlocked(PE.ClientState and PE.ClientState.journalUnlocked)
    PE.ClientState=args
    PE.ClientState.progress=type(PE.ClientState.progress)=="table" and PE.ClientState.progress or {}
    PE.ClientState.progressText=type(PE.ClientState.progressText)=="table" and PE.ClientState.progressText or {}
    PE.ClientState.progressDetails=type(PE.ClientState.progressDetails)=="table" and PE.ClientState.progressDetails or {}
    PE.ClientState.activeMissionIDs=type(PE.ClientState.activeMissionIDs)=="table" and PE.ClientState.activeMissionIDs or {}
    PE.ClientState.completed=type(PE.ClientState.completed)=="table" and PE.ClientState.completed or {}
    PE.ClientState.cooldowns=type(PE.ClientState.cooldowns)=="table" and PE.ClientState.cooldowns or {}
    PE.ClientState.journalUnlocked=type(PE.ClientState.journalUnlocked)=="table" and PE.ClientState.journalUnlocked or {}
    PE.ClientState.journalEvents=type(PE.ClientState.journalEvents)=="table" and PE.ClientState.journalEvents or {}
    local registryChanged=false
    if PE.applyRewardSeed and PE.ClientState.rewardSeed then
        registryChanged=PE.applyRewardSeed(PE.ClientState.rewardSeed) or registryChanged
    end
    if PE.applyAssignmentVisibility then
        registryChanged=PE.applyAssignmentVisibility(PE.ClientState) or registryChanged
    end
    if registryChanged and TM42 and TM42.rebuildMissionRegistry then TM42.rebuildMissionRegistry(true) end
    local new=countUnlocked(PE.ClientState.journalUnlocked)
    if new>old and old>0 then
        pcall(function() if HaloTextHelper and getPlayer() then HaloTextHelper.addText(getPlayer(),getText("UI_ProjectEcho_Text_0001")) end end)
    end
    if PE_JournalWindow and PE_JournalWindow.instance and PE_JournalWindow.instance:isVisible() then PE_JournalWindow.instance:refresh() end
end

local function inAnchor(player,anchor)
    if not player or not anchor then return false end
    local dx=player:getX()-anchor.x; local dy=player:getY()-anchor.y; local r=tonumber(anchor.radius) or 150
    return dx*dx+dy*dy<=r*r
end

local function resolveAnchor(id)
    if id=="$START" then id=PE.ClientState and PE.ClientState.startAnchor or nil end
    return id and PE.Anchors[id] or nil
end

local function doInteract(player,missionID,index)
    sendClientCommand(player,PE.Module,"Interact",{missionID=missionID,reqIndex=index})
end
local function doChoice(player,missionID,index,choice)
    sendClientCommand(player,PE.Module,"Choose",{missionID=missionID,reqIndex=index,choice=choice})
end

local function isLocalAdmin(player)
    if not player or not player.getAccessLevel then return false end
    local ok,level=pcall(function() return player:getAccessLevel() end)
    return ok and string.lower(tostring(level or ""))=="admin"
end

local function adminSkip(player)
    sendClientCommand(player,PE.Module,"AdminSkipCurrent",{})
end
local function adminResetCurrent(player)
    sendClientCommand(player,PE.Module,"AdminResetCurrent",{})
end
local function adminSync(player)
    requestSync(player)
end

local function onContextMenu(playerIndex,context,worldobjects,test)
    if test then return end
    local player=getSpecificPlayer(playerIndex)
    if not player or not TM42 then return end
    context:addOption(getText("UI_ProjectEcho_Text_0002"),player,function() PE.openJournal() end)
    if isLocalAdmin(player) then context:addOption(getText("UI_ProjectEcho_Text_0003"),player,function() PE.openDebugConsole() end) end
    local md=TM42.getModData(player)
    if not md then return end
    for _,mission in ipairs(TM42.getActiveMissions(md) or {}) do
        if PE.isEchoMission(mission) then
            for i,req in ipairs(mission.echo.requirements or {}) do
                if req.kind=="interact" or req.kind=="start_interact" then
                    local anchor=resolveAnchor(req.kind=="start_interact" and "$START" or req.anchor)
                    if anchor and inAnchor(player,anchor) then
                        context:addOption("PROJECT ECHO: "..PE.resolveText(req.prompt or getText("UI_ProjectEcho_Text_0004")),player,doInteract,mission.id,i)
                    end
                elseif req.kind=="choice" then
                    local anchor=resolveAnchor(req.anchor)
                    if (not anchor) or inAnchor(player,anchor) then
                        local root=context:addOption(getText("UI_ProjectEcho_Text_0005"))
                        local sub=ISContextMenu:getNew(context)
                        context:addSubMenu(root,sub)
                        for _,c in ipairs(req.choices or {}) do
                            sub:addOption(PE.resolveText(c.label),player,doChoice,mission.id,i,c.id)
                        end
                    end
                end
            end
        end
    end
    if isLocalAdmin(player) then
        local root=context:addOption("PROJECT ECHO [ADMIN]")
        local sub=ISContextMenu:getNew(context)
        context:addSubMenu(root,sub)
        sub:addOption(getText("UI_ProjectEcho_Text_0006"),player,adminSync)
        sub:addOption(getText("UI_ProjectEcho_Text_0007"),player,adminResetCurrent)
        sub:addOption(getText("UI_ProjectEcho_Text_0008"),player,adminSkip)
    end
end

local function onCreatePlayer(index,player)
    requestSync(player)
end

if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
if Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(onContextMenu) end
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
if Events.OnConnected then Events.OnConnected.Add(function() requestSync(getPlayer()) end) end
