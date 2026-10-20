-- PROJECT ECHO - spoiler-safe field journal UI
require "ProjectEcho_Core"
require "ProjectEcho_Missions"
require "ProjectEcho_JournalData"
require "ProjectEcho_StoryEnhancements"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

if ProjectEcho.Disabled then return end
local PE=ProjectEcho
local TM=getTextManager()
local FH=TM:getFontHeight(UIFont.Small)
local FHM=TM:getFontHeight(UIFont.Medium)

local C={
    bg={r=0.025,g=0.03,b=0.035,a=0.98}, panel={r=0.05,g=0.058,b=0.064,a=0.98},
    border={r=0.28,g=0.38,b=0.42,a=1}, text={r=0.90,g=0.93,b=0.92,a=1},
    muted={r=0.62,g=0.68,b=0.68,a=1}, accent={r=0.30,g=0.76,b=0.82,a=1},
    vanilla={r=0.82,g=0.72,b=0.40,a=1}, human={r=0.84,g=0.48,b=0.34,a=1}
}

local function initChild(parent,child)
    child:initialise(); child:instantiate(); parent:addChild(child); return child
end
local function tw(font,s) return TM:MeasureStringX(font,tostring(s or "")) end
local function wrap(font,text,maxW)
    local out={}
    for raw in (tostring(text or "").."\n"):gmatch("(.-)\n") do
        if raw=="" then out[#out+1]="" else
            local line=""
            for word in raw:gmatch("%S+") do
                local c=line=="" and word or (line.." "..word)
                if tw(font,c)<=maxW then line=c else
                    if line~="" then out[#out+1]=line end
                    line=word
                    if tw(font,line)>maxW then
                        local chunk=""
                        for i=1,#line do
                            local cc=chunk..line:sub(i,i)
                            if tw(font,cc)>maxW and chunk~="" then out[#out+1]=chunk; chunk=line:sub(i,i) else chunk=cc end
                        end
                        line=chunk
                    end
                end
            end
            if line~="" then out[#out+1]=line end
        end
    end
    return out
end

PE_JournalTextPanel=ISPanel:derive("PE_JournalTextPanel")
function PE_JournalTextPanel:new(x,y,w,h)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.backgroundColor=C.panel; o.borderColor=C.border; o.title=""; o.tag=""; o.body=""; o.scrollLine=0; return o
end
function PE_JournalTextPanel:setContent(title,tag,body)
    self.title=PE.resolveText(title or ""); self.tag=tostring(tag or ""); self.body=PE.resolveText(body or ""); self.scrollLine=0
end
function PE_JournalTextPanel:onMouseWheel(del)
    local lines=wrap(UIFont.Small,self.body,math.max(80,self.width-28)); local visible=math.max(1,math.floor((self.height-72)/FH))
    local maxScroll=math.max(0,#lines-visible)
    self.scrollLine=math.max(0,math.min(maxScroll,(self.scrollLine or 0)+del*3)); return true
end
function PE_JournalTextPanel:prerender()
    ISPanel.prerender(self)
    self:drawText(self.title,14,12,C.text.r,C.text.g,C.text.b,1,UIFont.Medium)
    if self.tag~="" then self:drawText("["..self.tag.."]",14,14+FHM,C.accent.r,C.accent.g,C.accent.b,1,UIFont.Small) end
    self:drawRect(12,48,self.width-24,1,0.8,C.border.r,C.border.g,C.border.b)
    local lines=wrap(UIFont.Small,self.body,math.max(80,self.width-28)); local y=58; local start=(self.scrollLine or 0)+1
    local visible=math.max(1,math.floor((self.height-68)/FH))
    for i=start,math.min(#lines,start+visible-1) do self:drawText(lines[i],14,y,C.text.r,C.text.g,C.text.b,1,UIFont.Small); y=y+FH end
    if #lines>visible then self:drawText(getText("UI_ProjectEcho_Text_0014"),14,self.height-FH-6,C.muted.r,C.muted.g,C.muted.b,1,UIFont.Small) end
end

PE_JournalList=ISScrollingListBox:derive("PE_JournalList")
function PE_JournalList:new(x,y,w,h)
    local o=ISScrollingListBox:new(x,y,w,h); setmetatable(o,self); self.__index=self; o.itemheight=44; o.backgroundColor=C.panel; o.borderColor=C.border; return o
end
function PE_JournalList:doDrawItem(y,item,alt)
    local row=item and item.item or {}; local fill=alt and 0.07 or 0.09
    self:drawRect(1,y,self.width-2,self.itemheight-2,0.98,fill,fill+0.005,fill+0.008)
    if self.selected==item.index then self:drawRect(2,y+1,4,self.itemheight-4,1,C.accent.r,C.accent.g,C.accent.b) end
    self:drawText(tostring(row.label or ""),10,y+7,C.text.r,C.text.g,C.text.b,1,UIFont.Small)
    if row.sub and row.sub~="" then self:drawText(tostring(row.sub),10,y+24,C.muted.r,C.muted.g,C.muted.b,1,UIFont.Small) end
    return y+self.itemheight
end

PE_JournalWindow=ISCollapsableWindow:derive("PE_JournalWindow")
PE_JournalWindow.instance=nil
function PE_JournalWindow:new(x,y,w,h)
    local o=ISCollapsableWindow:new(x,y,w,h); setmetatable(o,self); self.__index=self; o.title=getText("UI_ProjectEcho_Text_0002"); o.resizable=true; o.category="objective"; o.lastSelected=-1; return o
end
function PE_JournalWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    if self.collapseButton then self.collapseButton:setVisible(false) end
    if self.pinButton then self.pinButton:setVisible(false) end
    local labels={{getText("UI_ProjectEcho_Text_0015"),"objective"},{getText("UI_ProjectEcho_Text_0016"),"operations"},{getText("UI_ProjectEcho_Text_0017"),"echo"},{getText("UI_ProjectEcho_Text_0018"),"vanilla"},{getText("UI_ProjectEcho_Text_0019"),"alife"},{getText("UI_ProjectEcho_Text_0020"),"system"}}
    local x=10; local bw=96
    self.catButtons={}
    for _,row in ipairs(labels) do
        local b=ISButton:new(x,30,bw,26,row[1],self,function(target,button) target:setCategory(button.internal) end)
        b.internal=row[2]; b.backgroundColor={r=0.08,g=0.09,b=0.10,a=1}; b.borderColor=C.border; initChild(self,b); self.catButtons[#self.catButtons+1]=b; x=x+bw+5
    end
    self.list=PE_JournalList:new(10,64,300,self.height-76); initChild(self,self.list)
    self.detail=PE_JournalTextPanel:new(320,64,self.width-330,self.height-76); initChild(self,self.detail)
    self:refresh()
end
function PE_JournalWindow:onResize()
    ISCollapsableWindow.onResize(self)
    if self.list then self.list:setHeight(self.height-76) end
    if self.detail then self.detail:setX(320); self.detail:setWidth(self.width-330); self.detail:setHeight(self.height-76) end
end
local function currentMissionPseudo()
    local st=PE.ClientState or {}; local id=st.currentMain; local m=id and PE.getMission(id) or nil
    if not m then return {label=getText("UI_ProjectEcho_Text_0021"),sub="",title="PROJECT ECHO",tag="OBJECTIVE",body=getText("UI_ProjectEcho_Text_0022")} end
    local progress=tonumber(st.progress and st.progress[id]) or 0
    local progressText=st.progressText and st.progressText[id] or ""
    if PE.renderProgressDetails then
        progressText=PE.renderProgressDetails(st.progressDetails and st.progressDetails[id]) or progressText
    end
    return {label=PE.resolveText(m.title),sub=string.format("%.0f%%",progress),title=PE.resolveText(m.title),tag="OBJECTIVE",body=PE.resolveText(m.description or "").."\n\n"..PE.resolveText(progressText or "")}
end
local function journalEntryTitle(id)
    local e=PE.JournalEntries and PE.JournalEntries[id] or nil
    return e and PE.resolveText(e.title or id) or tostring(id or getText("UI_ProjectEcho_Text_0023"))
end

local function missionTitle(id)
    local m=id and PE.getMission(id) or nil
    return m and PE.resolveText(m.title or id) or tostring(id or "PROJECT ECHO")
end

local function formatOperationEvent(e)
    if type(e)~="table" then return nil end
    local event=tostring(e.event or "")
    if event=="journal_unlock" then
        local jid=tostring(e.journalID or "")
        local title=getText("UI_ProjectEcho_Text_0054")..journalEntryTitle(jid)
        local rt=tostring(e.reasonType or "system")
        local body
        if rt=="mission" then body=getText("UI_ProjectEcho_Text_0055")..tostring(e.reasonValue or "")
        elseif rt=="broadcast" then body=getText("UI_ProjectEcho_Text_0057")
        elseif rt=="first_contact" then body=getText("UI_ProjectEcho_Text_0058")
        elseif rt=="field" then body=getText("UI_ProjectEcho_Text_0064")
        elseif rt=="admin" then body=tostring(e.reasonValue or "ADMIN")
        else body=getText("UI_ProjectEcho_Text_0056") end
        return {label=title,sub="journal",title=title,tag="LOG",body=body}
    elseif event=="mission_started" then
        local id=tostring(e.missionID or "")
        local m=PE.getMission(id)
        local title=missionTitle(id)
        local body=m and PE.resolveText(m.description or "") or id
        if m and m.echoTarget then body=body.."\n\n"..PE.resolveText(m.echoTarget) end
        return {label=title,sub="ACTIVE",title=title,tag="LOG",body=body}
    elseif event=="mission_complete" then
        local id=tostring(e.missionID or "")
        local m=PE.getMission(id)
        local title=getText("UI_ProjectEcho_Text_0061")..missionTitle(id)
        local body=m and PE.resolveText(m.description or "") or id
        return {label=title,sub="mission",title=title,tag="LOG",body=body}
    elseif event=="human_seen" then
        local title=getText("UI_ProjectEcho_Text_0059")
        local body=PE.resolveText(e.label or getText("UI_ProjectEcho_Text_0060"))
        if e.faction and tostring(e.faction)~="" then body=body..getText("UI_ProjectEcho_Text_0043")..tostring(e.faction) end
        return {label=title,sub="human",title=title,tag="LOG",body=body}
    elseif event=="human_killed" then
        local title=getText("UI_ProjectEcho_Text_0051")
        local body=getText("UI_ProjectEcho_Text_0052")
        if e.faction and tostring(e.faction)~="" then body=body..getText("UI_ProjectEcho_Text_0053")..tostring(e.faction) end
        return {label=title,sub="human",title=title,tag="LOG",body=body}
    elseif event=="debug" then
        return {label=tostring(e.titleText or "ADMIN"),sub="debug",title=tostring(e.titleText or "ADMIN"),tag="LOG",body=tostring(e.bodyText or "")}
    end
    -- Compatibility fallback for any future ASCII-safe event type.
    return {label=PE.resolveText(e.title or e.text or getText("UI_ProjectEcho_Text_0023")),sub=tostring(e.kind or ""),title=PE.resolveText(e.title or getText("UI_ProjectEcho_Text_0023")),tag="LOG",body=PE.resolveText(e.body or e.text or "")}
end

function PE_JournalWindow:buildRows()
    local rows={}; local st=PE.ClientState or {}
    if self.category=="objective" then rows[1]=currentMissionPseudo(); return rows end
    if self.category=="operations" then
        local ev=st.journalEvents or {}
        for i=#ev,math.max(1,#ev-119),-1 do
            local row=formatOperationEvent(ev[i])
            if row then rows[#rows+1]=row end
        end
        return rows
    end
    local unlocked=st.journalUnlocked or {}
    for id,e in pairs(PE.JournalEntries or {}) do
        if unlocked[id]==true and e.category==self.category then rows[#rows+1]={id=id,label=PE.resolveText(e.title),sub="["..tostring(e.tag or "").."]",title=PE.resolveText(e.title),tag=tostring(e.tag or ""),body=PE.resolveText(e.body or "")} end
    end
    table.sort(rows,function(a,b) return tostring(a.label)<tostring(b.label) end); return rows
end
function PE_JournalWindow:setCategory(cat)
    self.category=cat or "objective"; self.lastSelected=-1; self:refresh()
end
function PE_JournalWindow:refresh()
    if not self.list then return end
    local rows=self:buildRows(); self.rows=rows; self.list:clear()
    for _,r in ipairs(rows) do self.list:addItem(r.label,r) end
    self.list.selected=(#rows>0) and 1 or 0; self.lastSelected=-1; self:updateDetail()
end
function PE_JournalWindow:updateDetail()
    local idx=self.list and self.list.selected or 0; local row=self.rows and self.rows[idx] or nil
    if row then self.detail:setContent(row.title,row.tag,row.body) else self.detail:setContent(getText("UI_ProjectEcho_Text_0024"),"",getText("UI_ProjectEcho_Text_0025")) end
    self.lastSelected=idx
end
function PE_JournalWindow:prerender()
    ISCollapsableWindow.prerender(self)
    if self.list and self.list.selected~=self.lastSelected then self:updateDetail() end
    for _,b in ipairs(self.catButtons or {}) do
        local on=b.internal==self.category; b.backgroundColor=on and {r=0.10,g=0.24,b=0.27,a=1} or {r=0.08,g=0.09,b=0.10,a=1}
    end
end

function PE.openJournal()
    local w=PE_JournalWindow.instance
    if not w then
        local sw,sh=getCore():getScreenWidth(),getCore():getScreenHeight(); local ww=math.min(940,sw-80); local wh=math.min(640,sh-100)
        w=PE_JournalWindow:new(math.floor((sw-ww)/2),math.floor((sh-wh)/2),ww,wh); w:initialise(); w:addToUIManager(); PE_JournalWindow.instance=w
    else w:setVisible(true); w:addToUIManager(); w:refresh() end
    return w
end
