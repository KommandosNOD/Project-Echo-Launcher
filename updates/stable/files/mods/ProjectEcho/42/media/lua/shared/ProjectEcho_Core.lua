-- PROJECT ECHO - shared bootstrap / The Mission integration
ProjectEcho = ProjectEcho or {}
ProjectEcho.VERSION = "0.9.13-progressguard"
ProjectEcho.Module = "ProjectEcho"
ProjectEcho.GlobalKey = "ProjectEcho_Campaign_v1"
ProjectEcho.BackupGlobalKey = "ProjectEcho_Campaign_Backup_v1"
ProjectEcho.SharedHistoryKey = "project_echo_shared"
ProjectEcho.ClientState = ProjectEcho.ClientState or {
    progress = {}, progressText = {}, progressDetails = {}, activeMissionIDs = {}, currentMain = nil, completed = {}, cooldowns = {},
    journalUnlocked = {}, journalEvents = {}, compat = {}, startAnchor = nil, choice = nil
}
ProjectEcho.ServerView = ProjectEcho.ServerView or nil

-- Localization transport rule (v0.9.6): dedicated-server state must never persist
-- localized Unicode strings. Server/shared data uses ASCII tokens; clients resolve
-- them with getText() only at display time. This avoids B42 dedicated-server
-- low-byte corruption of Cyrillic in GlobalModData / server commands.
local function peIsServerRuntime()
    if type(isServer) ~= "function" then return false end
    local ok, result = pcall(isServer)
    return ok and result == true
end

function ProjectEcho.textRef(key)
    return "[[PE:" .. tostring(key or "") .. "]]"
end

function ProjectEcho.formatRef(key, ...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    return "[[PEF:" .. tostring(key or "") .. "|" .. table.concat(parts, "|") .. "]]"
end

function ProjectEcho.dataText(key)
    if peIsServerRuntime() then return ProjectEcho.textRef(key) end
    local ok, value = pcall(getText, key)
    if ok and value then return value end
    return tostring(key or "")
end

local function peLiteralReplaceAll(text, needle, replacement)
    local out=tostring(text or "")
    needle=tostring(needle or "")
    if needle=="" then return out end
    replacement=tostring(replacement or "")
    local pos=1
    while true do
        local a,b=out:find(needle,pos,true)
        if not a then break end
        out=out:sub(1,a-1)..replacement..out:sub(b+1)
        pos=a+#replacement
    end
    return out
end

function ProjectEcho.formatLocalText(key,args)
    local ok,fmt=pcall(getText,tostring(key or ""))
    local out=(ok and fmt) and tostring(fmt) or tostring(key or "")
    for i,value in ipairs(args or {}) do
        out=peLiteralReplaceAll(out,"{"..tostring(i).."}",value)
    end
    return out
end

local function peResolveFormatToken(key, blob)
    local fmt = ProjectEcho.dataText(key)
    -- dataText() can only return a token on the dedicated server. resolveText() is
    -- a client/UI helper, but keep this guard for safe console use.
    if fmt:find("%[%[PE:", 1) then return fmt end
    local args = {}
    if blob and blob ~= "" then
        for part in (blob .. "|"):gmatch("(.-)|") do
            local n = tonumber(part)
            args[#args + 1] = n ~= nil and n or part
        end
    end
    -- Literal replacement avoids both Lua-pattern surprises and B42's own
    -- translation formatter. The server transports values separately in v0.9.10.
    local out = tostring(fmt or "")
    for i, value in ipairs(args) do
        out=peLiteralReplaceAll(out,"{"..tostring(i).."}",value)
    end
    return out
end

function ProjectEcho.resolveText(value)
    local s = tostring(value or "")
    -- Resolve a few passes because a translated prefix may be concatenated with a
    -- second token (for example a localized anchor name).
    for _ = 1, 4 do
        local before = s
        s = s:gsub("%[%[PEF:([%w_]+)|([^%]]*)%]%]", peResolveFormatToken)
        s = s:gsub("%[%[PE:([%w_]+)%]%]", function(key)
            local ok, out = pcall(getText, key)
            return (ok and out) and out or key
        end)
        if s == before then break end
    end
    return s
end

local function getEchoView()
    local serverSide = false
    if type(isServer) == "function" then
        local okServer, result = pcall(isServer)
        serverSide = okServer and result == true
    end
    if serverSide and type(ProjectEcho.ServerView) == "table" then
        return ProjectEcho.ServerView
    end
    return ProjectEcho.ClientState or {}
end
ProjectEcho.getEchoView = getEchoView

local ok, err = pcall(require, "TM42_Config")
if not ok or not TM42 then
    print("[PROJECT ECHO] FATAL: TheMission42 is required: " .. tostring(err))
    ProjectEcho.Disabled = true
    return
end

-- PROJECT ECHO owns The Mission's catalog on this server. The base mission UI stays,
-- but the default/sample mission packs are replaced by the campaign below.
TM42.DefaultMissionDefs = {}
TM42.CustomMissionDefs = {}
TM42.RuntimeMissionDefs = {}
TM42.RuntimeDisabledMissionIds = {}
TM42.areDefaultMissionsEnabled = function() return false end
TM42.shouldLoadCustomMissions = function() return true end

-- Ignore The Mission admin/runtime catalog while PROJECT ECHO is active. This prevents
-- an old admin mission catalog from reappearing after GlobalModData is restored.
TM42.applyRuntimeMissionCatalog = function(snapshot, rebuildNow)
    TM42.RuntimeMissionDefs = {}
    TM42.RuntimeDisabledMissionIds = {}
    TM42.RuntimeCatalogRevision = 0
    if rebuildNow ~= false and TM42.rebuildMissionRegistry then
        return TM42.rebuildMissionRegistry(true)
    end
    return true
end

TM42.Categories = {
    {
        id = "echo",
        nameKey = "PROJECT ECHO",
        descKey = ProjectEcho.dataText("UI_ProjectEcho_Text_0065"),
        sandboxOption = nil
    }
}
TM42.MissionTypeData.echo = {
    targetTextKey = "PROJECT ECHO",
    progressTextKey = "PROJECT ECHO",
    badgeColor = { r = 0.34, g = 0.78, b = 0.86, a = 1 },
    fallbackLetter = "E",
    displayDecimals = 0
}

-- One shared The Mission history record for the whole server. This is what makes
-- accept/completion/death/reconnect behavior server-global instead of character-local.
TM42.getHistoryKeyCandidates = function(player)
    return { ProjectEcho.SharedHistoryKey }
end
TM42.resolveHistoryKey = function(globalHistory, player)
    local key = ProjectEcho.SharedHistoryKey
    return key, type(globalHistory) == "table" and globalHistory[key] or nil
end
TM42.getHistoryKey = function(player)
    return ProjectEcho.SharedHistoryKey
end

-- A 100+ hour campaign must never be wiped by The Mission's real-time weekly reset.
TM42.isMissionResetEnabled = function()
    return false
end

function ProjectEcho.getMission(id)
    return ProjectEcho.MissionsById and ProjectEcho.MissionsById[id] or nil
end

function ProjectEcho.getAnchor(id)
    if id == "$START" then
        local s = getEchoView()
        id = s and s.startAnchor or nil
    end
    return id and ProjectEcho.Anchors and ProjectEcho.Anchors[id] or nil
end

function ProjectEcho.isEchoMission(mission)
    return mission and mission.type == "echo" and mission.echo ~= nil
end

local oldProgress = TM42.getMissionProgressValue
local oldReady = TM42.isMissionReady
local oldRatio = TM42.getMissionProgressRatio
local oldTargetText = TM42.getMissionTargetText
local oldProgressText = TM42.getMissionProgressText
local oldAcceptBlock = TM42.getMissionAcceptBlockReason
local oldCooling = TM42.isMissionCoolingDown

TM42.getMissionProgressValue = function(player, mission, modData)
    if ProjectEcho.isEchoMission(mission) then
        local s = getEchoView()
        return tonumber(s.progress and s.progress[mission.id]) or 0
    end
    return oldProgress(player, mission, modData)
end

TM42.isMissionReady = function(player, mission, modData)
    if ProjectEcho.isEchoMission(mission) then
        return TM42.getMissionProgressValue(player, mission, modData) >= 99.999
    end
    return oldReady(player, mission, modData)
end

TM42.getMissionProgressRatio = function(player, mission, modData)
    if ProjectEcho.isEchoMission(mission) then
        return math.max(0, math.min(1, TM42.getMissionProgressValue(player, mission, modData) / 100))
    end
    return oldRatio(player, mission, modData)
end

local function peCoopTargetText(mission)
    if peIsServerRuntime() or not ProjectEcho.isEchoMission(mission) then return nil end
    local reqs=mission.echo and mission.echo.requirements or nil
    if type(reqs)~="table" or #reqs~=1 then return nil end
    local req=reqs[1] or {}
    if req.kind=="kills" then
        return ProjectEcho.formatLocalText("UI_ProjectEcho_Target_Kills",{math.floor((tonumber(req.count) or 0)+0.5)})
    elseif req.kind=="kills_zone" then
        return ProjectEcho.formatLocalText("UI_ProjectEcho_Target_KillsZone",{math.floor((tonumber(req.count) or 0)+0.5)})
    elseif req.kind=="distance" then
        local km=(tonumber(req.meters) or 0)/1000
        local shown=string.format("%.1f",km):gsub("%.0$","")
        return ProjectEcho.formatLocalText(req.onFoot and "UI_ProjectEcho_Target_DistanceFoot" or "UI_ProjectEcho_Target_Distance",{shown})
    elseif req.kind=="items" then
        local total=0
        for _,it in ipairs(req.items or {}) do total=total+(tonumber(it.count) or 1) end
        return ProjectEcho.formatLocalText("UI_ProjectEcho_Target_Items",{total})
    end
    return nil
end

TM42.getMissionTargetText = function(mission)
    if ProjectEcho.isEchoMission(mission) then
        return peCoopTargetText(mission) or ProjectEcho.resolveText(mission.echoTarget or mission.title or "PROJECT ECHO")
    end
    return oldTargetText(mission)
end

local function peRenderProgressDetails(details)
    if type(details)~="table" or #details==0 then return nil end
    local parts={}
    for _,detail in ipairs(details) do
        if type(detail)=="table" and detail.key then
            parts[#parts+1]=ProjectEcho.formatLocalText(detail.key,detail.args or {})
        elseif type(detail)=="table" and detail.raw then
            parts[#parts+1]=ProjectEcho.resolveText(detail.raw)
        end
    end
    if #parts==0 then return nil end
    return table.concat(parts," | ")
end
ProjectEcho.renderProgressDetails=peRenderProgressDetails

TM42.getMissionProgressText = function(player, mission, modData)
    if ProjectEcho.isEchoMission(mission) then
        local s = getEchoView()
        -- v0.9.10: prefer structured progress payloads. This completely bypasses
        -- B42/The Mission placeholder handling, so {1}/{2} can never leak to UI.
        local rendered=peRenderProgressDetails(s.progressDetails and s.progressDetails[mission.id])
        if rendered and rendered~="" then return rendered end
        local text = s.progressText and s.progressText[mission.id] or nil
        if text and text ~= "" then return ProjectEcho.resolveText(text) end
        local value = math.floor((tonumber(s.progress and s.progress[mission.id]) or 0) + 0.5)
        return tostring(value) .. "%"
    end
    return oldProgressText(player, mission, modData)
end

TM42.isMissionCoolingDown = function(modData, mission)
    if ProjectEcho.isEchoMission(mission) and mission.repeatable then
        local s = getEchoView()
        local untilHour = tonumber(s.cooldowns and s.cooldowns[mission.id]) or 0
        local nowHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        return untilHour > nowHour
    end
    return oldCooling(modData, mission)
end

TM42.getMissionAcceptBlockReason = function(modData, mission)
    if ProjectEcho.isEchoMission(mission) then
        local s = getEchoView()
        if mission.track == "main" then
            local current = s and s.currentMain or nil
            if not current or mission.id ~= current then return "locked" end
        end
        local prereq = mission.echoPrerequisite
        if prereq and prereq ~= "" and not (s and s.completed and s.completed[prereq] == true) then
            return "locked"
        end
        if mission.repeatable and TM42.isMissionCoolingDown(modData, mission) then return "cooldown" end
        -- Do not delegate PROJECT ECHO gating back to The Mission. Its per-player
        -- prerequisite/history layer can lag one sync behind the global campaign and
        -- was the source of Available/LOCKED oscillation in older builds.
        return nil
    end
    return oldAcceptBlock(modData, mission)
end

-- Client-only assignment catalog filter (v0.9.10). The Mission category shows
-- only completed PROJECT ECHO assignments plus assignments that are currently active.
-- Future missions remain in ProjectEcho.MissionsById for story logic, but are hidden
-- from The Mission registry until the server exposes them.
local function peClientOnlyRuntime()
    local c=false; local srv=false
    if type(isClient)=="function" then local ok,v=pcall(isClient); c=ok and v==true end
    if type(isServer)=="function" then local ok,v=pcall(isServer); srv=ok and v==true end
    return c and not srv
end

function ProjectEcho.applyAssignmentVisibility(view)
    if not peClientOnlyRuntime() then return false end
    view=type(view)=="table" and view or {}
    local visible={}
    for id,v in pairs(view.completed or {}) do if v==true then visible[tostring(id)]=true end end
    if view.currentMain then visible[tostring(view.currentMain)]=true end
    for _,id in ipairs(view.activeMissionIDs or {}) do visible[tostring(id)]=true end
    local changed=false
    local visibleDefs={}
    for _,mission in ipairs(ProjectEcho.Missions or {}) do
        local want=visible[mission.id]==true
        if mission.enabled~=want then mission.enabled=want; changed=true end
        if want then visibleDefs[#visibleDefs+1]=mission end
    end
    -- Do not rely on The Mission merely honoring mission.enabled. Feed its client
    -- registry only the assignments that should exist in the PROJECT ECHO list.
    TM42.CustomMissionDefs=visibleDefs
    return changed
end

