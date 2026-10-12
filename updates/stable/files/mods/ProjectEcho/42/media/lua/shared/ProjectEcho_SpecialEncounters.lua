-- PROJECT ECHO - spoiler-contained special encounter definitions.
-- This file is intentionally data-only. The journal/UI never enumerates future entries.
require "ProjectEcho_Core"
require "ProjectEcho_Missions"
ProjectEcho = ProjectEcho or {}
local PE = ProjectEcho

PE.SpecialEncounterDefs = {
    -- The first controlled anomalies appear only after the campaign is established.
    { id="PEX_A", provider="mutants", anchor="sz_march_research", missions={"PE_M038","PE_M039"},
      wave={"PZTheMutants_Puker"}, boundaryScale=1.18 },
    { id="PEX_B", provider="mutants", anchor="sz_bunker3", missions={"PE_M041"},
      wave={"PZTheMutants_Husk","PZTheMutants_Weeper"}, boundaryScale=1.15 },
    { id="PEX_C", provider="mutants", anchor="raven_center", missions={"PE_M047","PE_M048"},
      wave={"PZTheMutants_Skitter","PZTheMutants_Leaper"}, boundaryScale=1.12 },
    { id="PEX_D", provider="mutants", anchor="raccoon_city", missions={"PE_M053","PE_M054"},
      wave={"PZTheMutants_Wrecker","PZTheMutants_Puker","PZTheMutants_Husk"}, boundaryScale=1.10 },

    -- Cry-of-Fear encounters are armed here, but the exact spawn adapter is generated
    -- only after PREPARE_SPECIAL_ZONES reads the installed Workshop build. Never guess
    -- a third-party private API: unavailable adapter => encounter is skipped, never a softlock.
    { id="PEX_E", provider="cof", anchor="sz_march_research", missions={"PE_M039"}, preset="controlled_light" },
    { id="PEX_F", provider="cof", anchor="sz_bunker3", missions={"PE_M041"}, preset="controlled_medium" },
    { id="PEX_G", provider="cof", anchor="sz_louisville_complex", missions={"PE_M073"}, preset="controlled_heavy" },
}

PE.SpecialEncounterById = {}
for _,def in ipairs(PE.SpecialEncounterDefs) do PE.SpecialEncounterById[def.id]=def end

PE.JournalEntries = PE.JournalEntries or {}
PE.JournalEntries.FIELD_ANOMALY = {
    category="echo", title=ProjectEcho.dataText("UI_ProjectEcho_Text_0452"), tag="FIELD",
    body=ProjectEcho.dataText("UI_ProjectEcho_Text_0453")
}
