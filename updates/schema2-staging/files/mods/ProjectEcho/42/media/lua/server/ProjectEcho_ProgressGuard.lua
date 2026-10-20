-- PROJECT ECHO v0.9.13 Progress Guard: independent server-only campaign high-water mark.
-- This file lives in Zomboid/Lua, not inside the world's global_mod_data.bin.
-- On its FIRST installation it adopts the existing campaign unchanged.
local Guard = {}
local FILE_VERSION = "PEPG1"
local CHECKPOINT_SECONDS = 60
local lastRecord = nil
local lastWriteTime = 0
local initialized = false
local warnedIO = false
local allowedReason = nil

local function serverID()
    local value = "servertest"
    if type(getServerName)=="function" then
        local ok,v=pcall(getServerName)
        if ok and v and tostring(v)~="" then value=tostring(v) end
    end
    value=value:gsub("[^%w_%-]","_")
    return value:sub(1,60)
end

local function filename()
    return "ProjectEcho_ProgressGuard_"..serverID().."_v1.log"
end

local function enc(s)
    local out=tostring(s or ""):gsub("([^%w%.%-%_:])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return out
end
local function dec(s)
    return tostring(s or ""):gsub("%%(%x%x)",function(x)
        return string.char(tonumber(x,16))
    end)
end

-- Small deterministic corruption check; incomplete/truncated journal lines are ignored.
local function checksum(s)
    local h=2718281
    for i=1,#s do h=(h*131 + s:byte(i))%2147483629 end
    return tostring(h)
end

local function index(s)
    local n=math.floor(tonumber(s and s.mainIndex) or 1)
    return math.max(1,math.min(85,n))
end

local function snapshot(s)
    return {
        epoch=math.max(1,math.floor(tonumber(s.campaignEpoch) or 1)),
        seed=tostring(s.rewardSeed or ""),
        idx=index(s),
        tx=math.max(0,math.floor(tonumber(s.transitionSerial) or 0)),
        rev=math.max(1,math.floor(tonumber(s.revision) or 1)),
        anchor=tostring(s.startAnchor or ""),
        choice=tostring(s.choice or "")
    }
end

local function encode(r)
    local fields={FILE_VERSION,serverID(),tostring(r.epoch),enc(r.seed),tostring(r.idx),
        tostring(r.tx),tostring(r.rev),enc(r.anchor),enc(r.choice)}
    local body=table.concat(fields,"|")
    return body.."|"..checksum(body)
end

local function decode(line)
    if type(line)~="string" then return nil end
    local a={}
    for part in (line.."|"):gmatch("(.-)|") do a[#a+1]=part end
    if #a~=10 or a[1]~=FILE_VERSION or a[2]~=serverID() then return nil end
    local body=table.concat(a,"|",1,9)
    if checksum(body)~=a[10] then return nil end
    local epoch,idx,tx,rev=tonumber(a[3]),tonumber(a[5]),tonumber(a[6]),tonumber(a[7])
    if not epoch or not idx or not tx or not rev or epoch<1 or idx<1 or idx>85 or tx<0 or rev<1 then return nil end
    if math.floor(idx)~=idx or math.floor(epoch)~=epoch then return nil end
    return {epoch=epoch,seed=dec(a[4]),idx=idx,tx=tx,rev=rev,anchor=dec(a[8]),choice=dec(a[9])}
end

local function loadLatest()
    local ok,reader=pcall(function()return getFileReader(filename(),false) end)
    if not ok or not reader then return nil end
    local record=nil
    local completed,err=pcall(function()
        local line=reader:readLine()
        while line do
            local valid=decode(line)
            if valid then record=valid end
            line=reader:readLine()
        end
    end)
    pcall(function()reader:close() end)
    if not completed then
        print("[PROJECT ECHO][GUARD] WARNING: cannot read checkpoint: "..tostring(err))
    end
    return record
end

local function append(record,reason)
    local line=encode(record)
    local ok,err=pcall(function()
        local writer=getFileWriter(filename(),true,true)
        assert(writer,"getFileWriter returned nil")
        writer:write(line.."\n")
        writer:close()
    end)
    if not ok then
        if not warnedIO then print("[PROJECT ECHO][GUARD] WARNING: independent checkpoint WRITE FAILED: "..tostring(err)); warnedIO=true end
        return false
    end
    lastRecord=record
    lastWriteTime=(os and os.time and os.time()) or 0
    if reason~="periodic" then
        print("[PROJECT ECHO][GUARD] checkpoint="..tostring(record.idx).." tx="..tostring(record.tx).." reason="..tostring(reason).." file=Zomboid/Lua/"..filename())
    end
    return true
end

local function sameCampaign(a,b)
    return a and b and a.epoch==b.epoch and a.seed~="" and a.seed==b.seed
end

local function apply(r,s)
    local previous=tostring(s.currentMain or "")
    s.campaignEpoch=r.epoch
    s.rewardSeed=r.seed
    s.mainIndex=r.idx
    s.transitionSerial=math.max(tonumber(s.transitionSerial) or 0,r.tx)
    s.revision=math.max(tonumber(s.revision) or 0,r.rev)
    s.finished=r.idx>84
    s.currentMain=(r.idx<=84) and string.format("PE_M%03d",r.idx) or nil
    s.completed=type(s.completed)=="table" and s.completed or {}
    for i=1,84 do
        local id=string.format("PE_M%03d",i)
        if i<r.idx then s.completed[id]=true else s.completed[id]=nil end
    end
    if r.anchor~="" then s.startAnchor=r.anchor end
    if r.choice~="" then s.choice=r.choice end
    s.runtime=type(s.runtime)=="table" and s.runtime or {}
    if previous~="" and previous~=s.currentMain then s.runtime[previous]=nil end
end

function Guard.startup(s)
    if initialized then return false end
    initialized=true
    lastRecord=loadLatest()
    if not lastRecord then
        print("[PROJECT ECHO][GUARD] first activation: adopt currently loaded campaign, NO OLD HISTORY RESTORE")
        return false
    end
    local current=snapshot(s)
    -- If GlobalModData lost the whole campaign table, rewardSeed is absent.
    -- The dedicated-server profile journal becomes our last recovery point.
    -- A deliberate new world should use a different server profile or remove
    -- the old checkpoint file while the server is stopped.
    if current.seed=="" and current.idx<=1 and lastRecord.idx>1 then
        apply(lastRecord,s)
        print("[PROJECT ECHO][GUARD] RECOVERED missing GlobalModData campaign from separate server journal (no rewards paid)")
        return true
    end
    if not sameCampaign(current,lastRecord) then
        -- A new season / different world / intentional admin reset may change the seed.
        -- Never apply old world data to an unrelated save.
        print("[PROJECT ECHO][GUARD] campaign fingerprint changed; adopt current save as new baseline")
        lastRecord=nil
        return false
    end
    if current.idx<lastRecord.idx then
        local before=current.idx
        apply(lastRecord,s)
        print("[PROJECT ECHO][GUARD] RECOVERED server rollback "..before.." -> "..lastRecord.idx.." (no rewards paid)")
        return true
    end
    if current.idx==lastRecord.idx and current.tx<lastRecord.tx then
        s.transitionSerial=lastRecord.tx
        print("[PROJECT ECHO][GUARD] restored transaction serial="..tostring(lastRecord.tx))
    end
    return false
end

-- Must be called only after a successful, explicit, admin-authorized rewind/restart/restore.
function Guard.authorizeRewind(reason)
    allowedReason=tostring(reason or "admin")
end

function Guard.beforePersist(s)
    if not initialized then return end
    local r=snapshot(s)
    if allowedReason then return end
    if lastRecord and sameCampaign(r,lastRecord) and r.idx<lastRecord.idx then
        print("[PROJECT ECHO][GUARD] BLOCKED runtime regression "..r.idx.." -> "..lastRecord.idx)
        apply(lastRecord,s)
    elseif lastRecord and (r.epoch~=lastRecord.epoch or r.seed~=lastRecord.seed) then
        -- An unapproved in-game mutation must not silently begin a new campaign.
        print("[PROJECT ECHO][GUARD] BLOCKED unexpected campaign identity change")
        apply(lastRecord,s)
    end
    local n=index(s)
    local expected=n<=84 and string.format("PE_M%03d",n) or nil
    local inconsistent=(s.currentMain~=expected) or (s.finished~=(n>84))
    if inconsistent then
        print("[PROJECT ECHO][GUARD] CORRECTED mismatched currentMain for index="..tostring(n))
        s.currentMain=expected
        s.finished=n>84
    end
    if inconsistent then
        s.completed=type(s.completed)=="table" and s.completed or {}
        for i=1,84 do
            local id=string.format("PE_M%03d",i)
            if i<n then s.completed[id]=true else s.completed[id]=nil end
        end
    end
end

function Guard.afterPersist(s)
    if not initialized then return end
    local reason=allowedReason
    allowedReason=nil
    local r=snapshot(s)
    local now=(os and os.time and os.time()) or 0
    local changed=not lastRecord or not sameCampaign(r,lastRecord) or
        r.idx~=lastRecord.idx or r.tx~=lastRecord.tx
    if reason then
        append(r,"authorized_"..reason)
    elseif changed then
        append(r,"state_change")
    elseif now==0 or now-lastWriteTime>=CHECKPOINT_SECONDS then
        append(r,"periodic")
    end
end

return Guard
