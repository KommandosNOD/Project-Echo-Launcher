-- PROJECT ECHO - admin recovery/debug console, spoiler-safe by default
require "ProjectEcho_Core"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
if ProjectEcho.Disabled then return end
local PE=ProjectEcho
local TM=getTextManager(); local FH=TM:getFontHeight(UIFont.Small)
local C={bg={r=0.025,g=0.025,b=0.03,a=0.98},panel={r=0.045,g=0.05,b=0.055,a=0.98},border={r=0.36,g=0.40,b=0.42,a=1},text={r=0.90,g=0.92,b=0.90,a=1},muted={r=0.62,g=0.65,b=0.64,a=1},ok={r=0.44,g=0.74,b=0.48,a=1},warn={r=0.80,g=0.60,b=0.24,a=1}}
local function initChild(parent,child) child:initialise(); child:instantiate(); parent:addChild(child); return child end
local function isAdminLocal()
    local p=getPlayer(); if not p then return false end
    if isAdmin and isAdmin() then return true end
    if p.isAccessLevel then local ok,v=pcall(function() return p:isAccessLevel("admin") end); if ok and v then return true end end
    if p.getAccessLevel then local ok,v=pcall(function() return p:getAccessLevel() end); return ok and string.lower(tostring(v or ""))=="admin" end
    return false
end

PE_DebugOutput=ISPanel:derive("PE_DebugOutput")
function PE_DebugOutput:new(x,y,w,h) local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self; o.lines={"PROJECT ECHO recovery console","Type help or use the buttons below."}; o.scroll=0; o.backgroundColor=C.panel; o.borderColor=C.border; return o end
function PE_DebugOutput:setLines(lines)
    self.lines={}; for _,v in ipairs(lines or {}) do self.lines[#self.lines+1]=PE.resolveText(v) end; if #self.lines==0 then self.lines[1]="(empty result)" end; self.scroll=math.max(0,#self.lines-math.floor((self.height-14)/FH))
end
function PE_DebugOutput:append(line) self.lines[#self.lines+1]=PE.resolveText(line); self.scroll=math.max(0,#self.lines-math.floor((self.height-14)/FH)) end
function PE_DebugOutput:onMouseWheel(del) local vis=math.max(1,math.floor((self.height-14)/FH)); self.scroll=math.max(0,math.min(math.max(0,#self.lines-vis),(self.scroll or 0)+del*3)); return true end
function PE_DebugOutput:prerender()
    ISPanel.prerender(self); local y=7; local vis=math.max(1,math.floor((self.height-14)/FH)); local st=(self.scroll or 0)+1
    for i=st,math.min(#self.lines,st+vis-1) do local line=self.lines[i]; local col=C.text; if line:find("%[PASS%]") or line:find("%[OK%]") then col=C.ok elseif line:find("%[FAIL%]") or line:find("%[WARN%]") then col=C.warn end; self:drawText(line,8,y,col.r,col.g,col.b,1,UIFont.Small); y=y+FH end
end

PE_DebugWindow=ISCollapsableWindow:derive("PE_DebugWindow")
PE_DebugWindow.instance=nil
function PE_DebugWindow:new(x,y,w,h) local o=ISCollapsableWindow:new(x,y,w,h); setmetatable(o,self); self.__index=self; o.title=getText("UI_ProjectEcho_Text_0009"); o.resizable=true; return o end
function PE_DebugWindow:createChildren()
    ISCollapsableWindow.createChildren(self); if self.collapseButton then self.collapseButton:setVisible(false) end; if self.pinButton then self.pinButton:setVisible(false) end
    local buttons={{"STATUS","status"},{"DOCTOR","doctor"},{"REPAIR","repair"},{"RECOVER","recover"},{"SNAPSHOT","snapshot manual"},{"ROLLBACK","restore auto_prev"},{"BACKUP","backup"},{"RESTORE BAK","restorebackup latest"},{"RESYNC","resync"}}
    local x=10; local y=32
    for i,row in ipairs(buttons) do
        local b=ISButton:new(x,y,100,25,row[1],self,function(target,button) target:execute(button.command) end); b.command=row[2]; b.backgroundColor={r=0.09,g=0.10,b=0.11,a=1}; b.borderColor=C.border; initChild(self,b); x=x+105; if x+100>self.width-10 then x=10; y=y+30 end
    end
    self.output=PE_DebugOutput:new(10,y+6,self.width-20,self.height-y-82); initChild(self,self.output)
    self.entry=ISTextEntryBox:new("status",10,self.height-66,self.width-125,26); initChild(self,self.entry); self.entry:setMaxTextLength(260)
    self.run=ISButton:new(self.width-108,self.height-66,98,26,getText("UI_ProjectEcho_Text_0010"),self,function(target) target:execute(target.entry:getText()) end); self.run.backgroundColor={r=0.12,g=0.22,b=0.24,a=1}; self.run.borderColor=C.border; initChild(self,self.run)
    self.hint=ISButton:new(10,self.height-35,160,24,getText("UI_ProjectEcho_Text_0011"),self,function(target) target:execute("objective current 1") end); self.hint.backgroundColor={r=0.10,g=0.11,b=0.12,a=1}; self.hint.borderColor=C.border; initChild(self,self.hint)
    self.finish=ISButton:new(175,self.height-35,190,24,getText("UI_ProjectEcho_Text_0012"),self,function(target) target:execute("complete current") end); self.finish.backgroundColor={r=0.13,g=0.10,b=0.08,a=1}; self.finish.borderColor=C.border; initChild(self,self.finish)
    self.reset=ISButton:new(370,self.height-35,170,24,getText("UI_ProjectEcho_Text_0013"),self,function(target) target:execute("reset current") end); self.reset.backgroundColor={r=0.10,g=0.11,b=0.12,a=1}; self.reset.borderColor=C.border; initChild(self,self.reset)
    self.restart=ISButton:new(545,self.height-35,190,24,"RESTART CAMPAIGN",self,function(target) target:onRestartCampaign() end); self.restart.backgroundColor={r=0.30,g=0.07,b=0.07,a=1}; self.restart.borderColor={r=0.75,g=0.18,b=0.18,a=1}; initChild(self,self.restart)
    self.restartArmed=false
end
function PE_DebugWindow:onResize()
    ISCollapsableWindow.onResize(self)
    if self.output then self.output:setWidth(self.width-20); self.output:setHeight(self.height-self.output.y-82) end
    if self.entry then self.entry:setY(self.height-66); self.entry:setWidth(self.width-125) end
    if self.run then self.run:setX(self.width-108); self.run:setY(self.height-66) end
    if self.hint then self.hint:setY(self.height-35) end; if self.finish then self.finish:setY(self.height-35) end; if self.reset then self.reset:setY(self.height-35) end; if self.restart then self.restart:setY(self.height-35) end
end
function PE_DebugWindow:onRestartCampaign()
    if not self.restartArmed then
        self.restartArmed=true; self.restart:setTitle("CONFIRM RESTART")
        self.output:setLines({"[WARN] This resets PROJECT ECHO story progress for the whole server.","World and characters are NOT deleted.","Click CONFIRM RESTART again to proceed."})
        return
    end
    self.restartArmed=false; self.restart:setTitle("RESTART CAMPAIGN"); self:execute("restart campaign")
end
function PE_DebugWindow:execute(cmd)
    if not isAdminLocal() then self.output:setLines({"[DENIED] admin access required"}); return end
    cmd=tostring(cmd or ""):gsub("^%s+",""):gsub("%s+$",""); if cmd=="" then return end
    self.output:append("> "..cmd); sendClientCommand(getPlayer(),PE.Module,"DebugExec",{command=cmd})
end
function PE_DebugWindow:onResult(lines) self.output:setLines(lines or {}) end
function PE.openDebugConsole()
    if not isAdminLocal() then return nil end
    local w=PE_DebugWindow.instance
    if not w then local sw,sh=getCore():getScreenWidth(),getCore():getScreenHeight(); local ww=math.min(820,sw-80); local wh=math.min(500,sh-100); w=PE_DebugWindow:new(math.floor((sw-ww)/2),math.floor((sh-wh)/2),ww,wh); w:initialise(); w:addToUIManager(); PE_DebugWindow.instance=w else w:setVisible(true); w:addToUIManager() end
    return w
end

PE.Debug=PE.Debug or {}
local function exec(cmd) if not isAdminLocal() then print("[PROJECT ECHO] admin required"); return end; sendClientCommand(getPlayer(),PE.Module,"DebugExec",{command=cmd}) end
PE.Debug.status=function() exec("status") end
PE.Debug.doctor=function() exec("doctor") end
PE.Debug.repair=function() exec("repair") end
PE.Debug.recover=function() exec("recover") end
PE.Debug.completeCurrent=function() exec("complete current") end
PE.Debug.resetCurrent=function() exec("reset current") end
PE.Debug.forceObjective=function(n) exec("objective current "..tostring(tonumber(n) or 1)) end
PE.Debug.snapshot=function(name) exec("snapshot "..tostring(name or "manual")) end
PE.Debug.restore=function(name) exec("restore "..tostring(name or "auto_prev")) end
PE.Debug.backup=function() exec("backup") end
PE.Debug.restoreBackup=function(which) exec("restorebackup "..tostring(which or "latest")) end
PE.Debug.resync=function() exec("resync") end
PE.Debug.restartCampaign=function() exec("restart campaign") end
PE.Debug.forceComplete=function(id) exec("complete "..tostring(id or "current")) end
PE.Debug.setMain=function(id) if id then exec("setmain "..tostring(id)) end end
PE.Debug.rewind=function(id) exec("rewind "..tostring(id or "current")) end
PE.Debug.open=function() PE.openDebugConsole() end
PE.Debug.journal=function() if PE.openJournal then PE.openJournal() end end
