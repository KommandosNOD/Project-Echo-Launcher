-- PROJECT ECHO - mission overlays that remain softlock-safe.
require "ProjectEcho_JournalData"
ProjectEcho = ProjectEcho or {}
local PE = ProjectEcho

if PE._storyEnhancementsApplied then return end
PE._storyEnhancementsApplied = true

local function appendRequirement(missionID, req)
    local m = PE.getMission and PE.getMission(missionID) or nil
    if not m or not m.echo then return false end
    m.echo.requirements = m.echo.requirements or {}
    for _, existing in ipairs(m.echo.requirements) do
        if existing.kind == req.kind and existing.anchor == req.anchor and existing.projectEchoOverlay == true then
            return true
        end
    end
    req.projectEchoOverlay = true
    m.echo.requirements[#m.echo.requirements + 1] = req
    return true
end

-- These are A-Life-aware encounters, not hard dependencies. If A-Life does not produce
-- hostile humans at the location, the objective falls back to holding/clearing the area.
-- This guarantees the campaign can never be blocked by an NPC mod update or bad spawn roll.
for missionID, cfg in pairs(PE.HumanEncounterMissions or {}) do
    local req={
        kind = "human_encounter",
        anchor = cfg.anchor,
        kills = cfg.kills,
        fallbackKills = cfg.fallbackKills,
        fallbackHours = cfg.fallbackHours,
        label = cfg.label,
    }
    -- Human encounters stay provider-safe; the common co-op scaler deliberately
    -- does not multiply them because A-Life may only produce a few humans.
    if PE.scaleSharedRequirement then PE.scaleSharedRequirement(req) end
    appendRequirement(missionID,req)
end
