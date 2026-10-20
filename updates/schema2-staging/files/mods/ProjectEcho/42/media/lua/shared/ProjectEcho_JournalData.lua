-- PROJECT ECHO - shared journal/lore data
require "ProjectEcho_Core"
ProjectEcho = ProjectEcho or {}
local PE = ProjectEcho

PE.JournalCategories = {
    objective = { order = 1, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0066") },
    operations = { order = 2, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0067") },
    echo = { order = 3, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0068") },
    vanilla = { order = 4, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0069") },
    alife = { order = 5, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0019") },
    system = { order = 6, title = ProjectEcho.dataText("UI_ProjectEcho_Text_0020") },
}

PE.JournalEntries = {
    SYS_FIELD_MANUAL = {
        category = "system",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0070"),
        tag = "SYSTEM",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0071"),
    },
    VAN_0706 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0072"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0073"),
    },
    VAN_0709 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0074"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0075"),
    },
    VAN_TV_NORMALCY = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0076"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0077"),
    },
    VAN_0710 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0078"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0079"),
    },
    VAN_0711_12 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0080"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0081"),
    },
    VAN_0713_14 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0082"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0083"),
    },
    VAN_0715_17 = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0084"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0085"),
    },
    VAN_0718PLUS = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0086"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0087"),
    },

    VAN_MEDIA_METHOD = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0088"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0089"),
    },
    VAN_AEBS = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0090"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0091"),
    },
    VAN_NEWSROOMS = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0092"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0093"),
    },
    VAN_KNOXTALK_ARCHIVE = {
        category = "vanilla",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0094"),
        tag = "VANILLA",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0095"),
    },
    ECHO_E01 = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0096"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0097"),
    },
    ECHO_ORDER6B = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0098"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0099"),
    },
    ECHO_CONTINUITY = {
        category = "echo",
        title = "Continuity Program",
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0100"),
    },
    ECHO_OBS17 = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0101"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0102"),
    },
    ECHO_RC7 = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0103"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0104"),
    },
    ECHO_INDEX = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0105"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0106"),
    },
    ECHO_OMEGA = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0107"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0108"),
    },
    ECHO_OUTBOUND = {
        category = "echo",
        title = "OUTBOUND CORRIDOR",
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0109"),
    },
    ECHO_FINAL = {
        category = "echo",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0110"),
        tag = "ECHO",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0111"),
    },
    ALIFE_FIRST_CONTACT = {
        category = "alife",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0112"),
        tag = "A-LIFE",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0113"),
    },
    ALIFE_FIRST_BLOOD = {
        category = "alife",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0051"),
        tag = "A-LIFE",
        body = ProjectEcho.dataText("UI_ProjectEcho_Text_0114"),
    },
}

PE.JournalUnlocks = {
    PE_M001 = { "SYS_FIELD_MANUAL" },
    PE_M007 = { "VAN_MEDIA_METHOD", "VAN_AEBS", "VAN_0706", "VAN_0709", "VAN_TV_NORMALCY" },
    PE_M012 = { "ECHO_E01" },
    PE_M021 = { "ECHO_ORDER6B" },
    PE_M035 = { "ECHO_CONTINUITY" },
    PE_M039 = { "ECHO_OBS17" },
    PE_M049 = { "ECHO_RC7" },
    PE_M056 = { "ECHO_INDEX" },
    PE_M070 = { "ECHO_OMEGA" },
    PE_M077 = { "ECHO_OUTBOUND" },
    PE_M084 = { "ECHO_FINAL" },
}

-- Relative to the server's default July 9 start. These only unlock after the radio
-- introduction mission has been completed, so the journal does not spoil the broadcast
-- arc before the group has begun listening to the airwaves.
PE.BroadcastJournalTimeline = {
    { hours = 24, id = "VAN_0710" },
    { hours = 30, id = "VAN_NEWSROOMS" },
    { hours = 48, id = "VAN_0711_12" },
    { hours = 60, id = "VAN_KNOXTALK_ARCHIVE" },
    { hours = 96, id = "VAN_0713_14" },
    { hours = 144, id = "VAN_0715_17" },
    { hours = 216, id = "VAN_0718PLUS" },
}

PE.HumanEncounterMissions = {
    PE_M020 = { anchor = "sz_muldraugh_crossroads", kills = 2, fallbackKills = 45, fallbackHours = 0.50, label = ProjectEcho.dataText("UI_ProjectEcho_Text_0115") },
    PE_M026 = { anchor = "westpoint_police", kills = 2, fallbackKills = 55, fallbackHours = 0.50, label = "West Point" },
    PE_M032 = { anchor = "louisville_qz", kills = 3, fallbackKills = 75, fallbackHours = 0.75, label = ProjectEcho.dataText("UI_ProjectEcho_Text_0116") },
    PE_M045 = { anchor = "raven_north", kills = 3, fallbackKills = 90, fallbackHours = 0.75, label = "Raven Creek" },
    PE_M051 = { anchor = "raccoon_city", kills = 4, fallbackKills = 120, fallbackHours = 1.00, label = "Raccoon City" },
    PE_M073 = { anchor = "sz_louisville_complex", kills = 5, fallbackKills = 160, fallbackHours = 1.00, label = ProjectEcho.dataText("UI_ProjectEcho_Text_0117") },
}

PE.DebugHelp = {
    "help",
    "status",
    "state log",
    "doctor",
    "repair",
    "recover",
    "current",
    "complete current",
    "reset current",
    "objective current 1",
    "snapshot manual",
    "restore auto_prev",
    "backup",
    "restorebackup latest",
    "restorebackup previous",
    "journal repair",
    "resync",
    "restart campaign",
    "dump",
    "special status",
    "special quarantine",
    "ProjectEcho.Debug.doctor()",
    "ProjectEcho.Debug.repair()",
    "ProjectEcho.Debug.completeCurrent()",
    "ProjectEcho.Debug.forceObjective(1)",
    "ProjectEcho.Debug.snapshot(\"manual\")",
    "ProjectEcho.Debug.restore(\"auto_prev\")",
    "ProjectEcho.Debug.restoreBackup(\"latest\")",
    "ProjectEcho.Debug.restartCampaign()",
}

-- Intentionally not shown in normal help: commands that jump to arbitrary future mission IDs.
-- They remain supported for emergency administration but the UI defaults to spoiler-safe recovery.
PE.DebugAdvancedHelp = {
    "mission <ID>", "complete <ID>", "setmain <ID>", "rewind <ID>", "reset <ID>",
    "objective <ID> <N>", "anchor <ID>", "journal unlock <ID>", "journal unlockall"
}
