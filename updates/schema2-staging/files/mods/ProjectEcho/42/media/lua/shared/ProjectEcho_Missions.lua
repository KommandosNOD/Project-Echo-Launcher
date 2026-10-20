-- PROJECT ECHO campaign data. Generated for this server build.
require "ProjectEcho_Core"
require "ProjectEcho_RewardTiers"
ProjectEcho = ProjectEcho or {}

ProjectEcho.Anchors = {
    start_echo = {
        name = "Echo Creek, KY",
        x = 4235,
        y = 11069,
        z = 0,
        radius = 1200,
        source = "vanilla B42 town centre"
    },
    start_muldraugh = {
        name = "Muldraugh, KY",
        x = 11181,
        y = 9725,
        z = 0,
        radius = 1200,
        source = "vanilla B42 town centre"
    },
    start_riverside = {
        name = "Riverside, KY",
        x = 6300,
        y = 5668,
        z = 0,
        radius = 1200,
        source = "vanilla B42 town centre"
    },
    start_rosewood = {
        name = "Rosewood, KY",
        x = 8446,
        y = 11556,
        z = 0,
        radius = 1100,
        source = "vanilla B42 town centre"
    },
    start_westpoint = {
        name = "West Point, KY",
        x = 11581,
        y = 6916,
        z = 0,
        radius = 1100,
        source = "vanilla B42 town centre"
    },
    echo_base = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0118"),
        x = 3584,
        y = 10880,
        z = 0,
        radius = 520,
        source = "SHELTER Echo Creek B42 stable fallback"
    },
    muldraugh_police = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0119"),
        x = 10630,
        y = 10400,
        z = 0,
        radius = 180,
        source = "vanilla POI"
    },
    muldraugh_gas = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0120"),
        x = 10610,
        y = 9760,
        z = 0,
        radius = 180,
        source = "vanilla POI"
    },
    mccoy = {
        name = "McCoy Logging",
        x = 10320,
        y = 9320,
        z = 0,
        radius = 260,
        source = "vanilla POI"
    },
    westpoint_police = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0121"),
        x = 11900,
        y = 6890,
        z = 0,
        radius = 180,
        source = "vanilla POI"
    },
    westpoint_gunstore = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0122"),
        x = 12050,
        y = 6950,
        z = 0,
        radius = 180,
        source = "vanilla POI"
    },
    marchridge = {
        name = "March Ridge",
        x = 10088,
        y = 12696,
        z = 0,
        radius = 900,
        source = "vanilla B42 town centre"
    },
    louisville = {
        name = "Louisville",
        x = 12500,
        y = 1800,
        z = 0,
        radius = 1400,
        source = "vanilla B42 city centre"
    },
    louisville_qz = {
        name = "Louisville Quarantine Zone",
        x = 13627,
        y = 4099,
        z = 0,
        radius = 520,
        source = "vanilla B42 Louisville exclusion-border fallback"
    },
    fort_preston = {
        name = "Fort Preston",
        x = 8832,
        y = 11008,
        z = 0,
        radius = 760,
        source = "cells 33-36 x 42-44"
    },
    raccoon_city = {
        name = "Raccoon City",
        x = 8576,
        y = 8576,
        z = 0,
        radius = 720,
        source = "cells 33-34 x 33-34"
    },
    raven_gate = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0123"),
        x = 6400,
        y = 14592,
        z = 0,
        radius = 650,
        source = "Raven Creek occupied east cells"
    },
    raven_north = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0124"),
        x = 6144,
        y = 15104,
        z = 0,
        radius = 720,
        source = "Raven Creek occupied cells"
    },
    raven_center = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0125"),
        x = 5376,
        y = 16128,
        z = 0,
        radius = 800,
        source = "Raven Creek occupied cells"
    },
    raven_south = {
        name = ProjectEcho.dataText("UI_ProjectEcho_Text_0126"),
        x = 4608,
        y = 17408,
        z = 0,
        radius = 800,
        source = "Raven Creek occupied cells"
    },
    constown = {
        name = "Constown",
        x = 5504,
        y = 11008,
        z = 0,
        radius = 760,
        source = "cells 19-24 x 42-44"
    },
    hartburg = {
        name = "Hartburg",
        x = 6528,
        y = 11264,
        z = 0,
        radius = 520,
        source = "cells 25-26 x 43-45"
    },
    sz_march_research = {
        name = "SecretZ March Ridge Research Facility",
        x = 10368,
        y = 12160,
        z = 0,
        radius = 700,
        source = "cells 39-41 x 46-49"
    },
    sz_muldraugh_crossroads = {
        name = "SecretZ Muldraugh Crossroads",
        x = 10624,
        y = 11136,
        z = 0,
        radius = 520,
        source = "cells 41-43 x 43-44 group"
    },
    sz_train_evac = {
        name = "SecretZ Muldraugh Train Depot EVAC",
        x = 11392,
        y = 9984,
        z = 0,
        radius = 720,
        source = "cells 44 x 37-41 group"
    },
    sz_bunker3 = {
        name = "SecretZ Bunker 3",
        x = 6016,
        y = 11648,
        z = 0,
        radius = 650,
        source = "cells 23-24 x 45-46 group"
    },
    sz_north_checkpoint = {
        name = "SecretZ North Checkpoint",
        x = 3968,
        y = 6912,
        z = 0,
        radius = 760,
        source = "cells 14-16 x 26-28 group"
    },
    sz_mall = {
        name = "SecretZ Valley Station Mall",
        x = 13952,
        y = 5760,
        z = 0,
        radius = 820,
        source = "cells 53-55 x 22-23 group"
    },
    sz_louisville_complex = {
        name = "SecretZ Louisville Military Complex",
        x = 14592,
        y = 2304,
        z = 0,
        radius = 1000,
        source = "cells 53-59 x 7-11 group"
    },
    sz_westpoint_checkpoint = {
        name = "SecretZ West Point corridor",
        x = 12032,
        y = 8064,
        z = 0,
        radius = 760,
        source = "active SecretZ east corridor cells"
    }
}

ProjectEcho.CampaignChapters = {
    {
        roman = "I",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0127")
    },
    {
        roman = "II",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0128")
    },
    {
        roman = "III",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0129")
    },
    {
        roman = "IV",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0130")
    },
    {
        roman = "V",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0131")
    },
    {
        roman = "VI",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0132")
    },
    {
        roman = "VII",
        title = "Raven Creek"
    },
    {
        roman = "VIII",
        title = "Raccoon City"
    },
    {
        roman = "IX",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0133")
    },
    {
        roman = "X",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0134")
    },
    {
        roman = "XI",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0135")
    },
    {
        roman = "XII",
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0136")
    }
}

ProjectEcho.RawMissions = {
    {
        id = "PE_M001",
        track = "main",
        chapter = 1,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0137"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0138"),
        requirements = {
            {
                kind = "start_region"
            }
        },
        reward = {
            "item",
            "Base.Battery",
            2
        },
        prerequisite = nil,
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0139")
    },
    {
        id = "PE_M002",
        track = "main",
        chapter = 1,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0140"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0141"),
        requirements = {
            {
                kind = "start_hold",
                hours = 0.35
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M001",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0142")
    },
    {
        id = "PE_M003",
        track = "main",
        chapter = 1,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0143"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0144"),
        requirements = {
            {
                kind = "kills",
                count = 35
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            4
        },
        prerequisite = "PE_M002",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0145")
    },
    {
        id = "PE_M004",
        track = "main",
        chapter = 1,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0146"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0147"),
        requirements = {
            {
                kind = "distance",
                meters = 1800,
                onFoot = true
            }
        },
        reward = {
            "item",
            "Base.Battery",
            2
        },
        prerequisite = "PE_M003",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0148")
    },
    {
        id = "PE_M005",
        track = "main",
        chapter = 1,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0149"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0150"),
        requirements = {
            {
                kind = "items",
                items = {
                    {
                        type = "Base.Bandage",
                        count = 4
                    },
                    {
                        type = "Base.Battery",
                        count = 2
                    },
                    {
                        type = "Base.Hammer",
                        count = 1
                    }
                }
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M004",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0151")
    },
    {
        id = "PE_M006",
        track = "main",
        chapter = 1,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0152"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0153"),
        requirements = {
            {
                kind = "survive",
                hours = 8
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M005",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0154")
    },
    {
        id = "PE_M007",
        track = "main",
        chapter = 1,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0155"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0156"),
        requirements = {
            {
                kind = "start_interact",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0157")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M006",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0158")
    },
    {
        id = "PE_M008",
        track = "main",
        chapter = 2,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0128"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0159"),
        requirements = {
            {
                kind = "zone",
                anchor = "start_echo"
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M007",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0160")
    },
    {
        id = "PE_M009",
        track = "main",
        chapter = 2,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0161"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0162"),
        requirements = {
            {
                kind = "zone",
                anchor = "echo_base"
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M008",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0163")
    },
    {
        id = "PE_M010",
        track = "main",
        chapter = 2,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0164"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0165"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "echo_base",
                count = 90
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M009",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0166")
    },
    {
        id = "PE_M011",
        track = "main",
        chapter = 2,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0167"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0168"),
        requirements = {
            {
                kind = "interact",
                anchor = "echo_base",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0169")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M010",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0169")
    },
    {
        id = "PE_M012",
        track = "main",
        chapter = 2,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0096"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0170"),
        requirements = {
            {
                kind = "interact",
                anchor = "echo_base",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0171")
            }
        },
        reward = {
            "item",
            "Base.Notebook",
            1
        },
        prerequisite = "PE_M011",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0171")
    },
    {
        id = "PE_M013",
        track = "main",
        chapter = 2,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0172"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0173"),
        requirements = {
            {
                kind = "distance",
                meters = 6500,
                onFoot = false
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M012",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0174")
    },
    {
        id = "PE_M014",
        track = "main",
        chapter = 2,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0175"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0176"),
        requirements = {
            {
                kind = "survive",
                hours = 10
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M013",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0177")
    },
    {
        id = "PE_M015",
        track = "main",
        chapter = 3,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0178"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0179"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_train_evac"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M014",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0180")
    },
    {
        id = "PE_M016",
        track = "main",
        chapter = 3,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0181"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0182"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "sz_train_evac",
                count = 120
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M015",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0183")
    },
    {
        id = "PE_M017",
        track = "main",
        chapter = 3,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0184"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0185"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_train_evac",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0186")
            }
        },
        reward = {
            "item",
            "Base.Notebook",
            1
        },
        prerequisite = "PE_M016",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0187")
    },
    {
        id = "PE_M018",
        track = "main",
        chapter = 3,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0188"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0189"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_muldraugh_crossroads"
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            4
        },
        prerequisite = "PE_M017",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0190")
    },
    {
        id = "PE_M019",
        track = "main",
        chapter = 3,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0191"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0192"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_muldraugh_crossroads",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0193")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M018",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0194")
    },
    {
        id = "PE_M020",
        track = "main",
        chapter = 3,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0195"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0196"),
        requirements = {
            {
                kind = "hold",
                anchor = "sz_muldraugh_crossroads",
                hours = 0.75
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M019",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0197")
    },
    {
        id = "PE_M021",
        track = "main",
        chapter = 3,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0098"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0198"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_muldraugh_crossroads",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0199")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M020",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0200")
    },
    {
        id = "PE_M022",
        track = "main",
        chapter = 4,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0201"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0202"),
        requirements = {
            {
                kind = "zone",
                anchor = "fort_preston"
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M021",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0203")
    },
    {
        id = "PE_M023",
        track = "main",
        chapter = 4,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0204"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0205"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "fort_preston",
                count = 160
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M022",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0206")
    },
    {
        id = "PE_M024",
        track = "main",
        chapter = 4,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0207"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0208"),
        requirements = {
            {
                kind = "interact",
                anchor = "fort_preston",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0209")
            }
        },
        reward = {
            "item",
            "Base.Notebook",
            1
        },
        prerequisite = "PE_M023",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0209")
    },
    {
        id = "PE_M025",
        track = "main",
        chapter = 4,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0210"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0211"),
        requirements = {
            {
                kind = "distance",
                meters = 12000,
                onFoot = false
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M024",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0212")
    },
    {
        id = "PE_M026",
        track = "main",
        chapter = 4,
        number = 5,
        title = "West Point",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0213"),
        requirements = {
            {
                kind = "zone",
                anchor = "westpoint_police"
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M025",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0214")
    },
    {
        id = "PE_M027",
        track = "main",
        chapter = 4,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0215"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0216"),
        requirements = {
            {
                kind = "zone",
                anchor = "westpoint_gunstore"
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M026",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0217")
    },
    {
        id = "PE_M028",
        track = "main",
        chapter = 4,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0218"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0219"),
        requirements = {
            {
                kind = "interact",
                anchor = "westpoint_gunstore",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0220")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M027",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0220")
    },
    {
        id = "PE_M029",
        track = "main",
        chapter = 5,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0131"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0221"),
        requirements = {
            {
                kind = "zone",
                anchor = "louisville_qz"
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            4
        },
        prerequisite = "PE_M028",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0222")
    },
    {
        id = "PE_M030",
        track = "main",
        chapter = 5,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0223"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0224"),
        requirements = {
            {
                kind = "interact",
                anchor = "louisville_qz",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0225")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M029",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0225")
    },
    {
        id = "PE_M031",
        track = "main",
        chapter = 5,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0226"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0227"),
        requirements = {
            {
                kind = "hold",
                anchor = "louisville_qz",
                hours = 1.0
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M030",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0228")
    },
    {
        id = "PE_M032",
        track = "main",
        chapter = 5,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0229"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0230"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "louisville_qz",
                count = 180
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M031",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0231")
    },
    {
        id = "PE_M033",
        track = "main",
        chapter = 5,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0232"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0233"),
        requirements = {
            {
                kind = "zone",
                anchor = "louisville"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M032",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0234")
    },
    {
        id = "PE_M034",
        track = "main",
        chapter = 5,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0235"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0236"),
        requirements = {
            {
                kind = "distance",
                meters = 9000,
                onFoot = false
            }
        },
        reward = {
            "item",
            "Base.Battery",
            4
        },
        prerequisite = "PE_M033",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0237")
    },
    {
        id = "PE_M035",
        track = "main",
        chapter = 5,
        number = 7,
        title = "Continuity Program",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0238"),
        requirements = {
            {
                kind = "interact",
                anchor = "louisville_qz",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0239")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M034",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0240")
    },
    {
        id = "PE_M036",
        track = "main",
        chapter = 6,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0241"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0242"),
        requirements = {
            {
                kind = "zone",
                anchor = "marchridge"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M035",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0243")
    },
    {
        id = "PE_M037",
        track = "main",
        chapter = 6,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0244"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0245"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_march_research"
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M036",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0246")
    },
    {
        id = "PE_M038",
        track = "main",
        chapter = 6,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0247"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0248"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_march_research",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0249")
            }
        },
        reward = {
            "item",
            "Base.Screwdriver",
            1
        },
        prerequisite = "PE_M037",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0249")
    },
    {
        id = "PE_M039",
        track = "main",
        chapter = 6,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0101"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0250"),
        requirements = {
            {
                kind = "hold",
                anchor = "sz_march_research",
                hours = 1.25
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M038",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0251")
    },
    {
        id = "PE_M040",
        track = "main",
        chapter = 6,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0252"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0253"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_bunker3"
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M039",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0254")
    },
    {
        id = "PE_M041",
        track = "main",
        chapter = 6,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0255"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0256"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "sz_bunker3",
                count = 150
            },
            {
                kind = "interact",
                anchor = "sz_bunker3",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0257")
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M040",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0258")
    },
    {
        id = "PE_M042",
        track = "main",
        chapter = 6,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0259"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0260"),
        requirements = {
            {
                kind = "survive",
                hours = 12
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M041",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0261")
    },
    {
        id = "PE_M043",
        track = "main",
        chapter = 7,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0262"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0263"),
        requirements = {
            {
                kind = "distance",
                meters = 15000,
                onFoot = false
            }
        },
        reward = {
            "item",
            "Base.Battery",
            4
        },
        prerequisite = "PE_M042",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0264")
    },
    {
        id = "PE_M044",
        track = "main",
        chapter = 7,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0265"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0266"),
        requirements = {
            {
                kind = "zone",
                anchor = "raven_gate"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M043",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0267")
    },
    {
        id = "PE_M045",
        track = "main",
        chapter = 7,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0268"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0269"),
        requirements = {
            {
                kind = "zone",
                anchor = "raven_north"
            },
            {
                kind = "kills_zone",
                anchor = "raven_north",
                count = 120
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M044",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0270")
    },
    {
        id = "PE_M046",
        track = "main",
        chapter = 7,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0271"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0272"),
        requirements = {
            {
                kind = "zone",
                anchor = "raven_center"
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M045",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0273")
    },
    {
        id = "PE_M047",
        track = "main",
        chapter = 7,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0274"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0275"),
        requirements = {
            {
                kind = "interact",
                anchor = "raven_center",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0276")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M046",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0277")
    },
    {
        id = "PE_M048",
        track = "main",
        chapter = 7,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0278"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0279"),
        requirements = {
            {
                kind = "zone",
                anchor = "raven_south"
            },
            {
                kind = "kills_zone",
                anchor = "raven_south",
                count = 140
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M047",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0280")
    },
    {
        id = "PE_M049",
        track = "main",
        chapter = 7,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0103"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0281"),
        requirements = {
            {
                kind = "interact",
                anchor = "raven_center",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0282")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M048",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0282")
    },
    {
        id = "PE_M050",
        track = "main",
        chapter = 8,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0283"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0284"),
        requirements = {
            {
                kind = "zone",
                anchor = "raccoon_city"
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M049",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0285")
    },
    {
        id = "PE_M051",
        track = "main",
        chapter = 8,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0286"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0287"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "raccoon_city",
                count = 220
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M050",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0288")
    },
    {
        id = "PE_M052",
        track = "main",
        chapter = 8,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0289"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0290"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "raccoon_city"
                },
                count = 1
            },
            {
                kind = "distance",
                meters = 7000,
                onFoot = true
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M051",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0291")
    },
    {
        id = "PE_M053",
        track = "main",
        chapter = 8,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0292"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0293"),
        requirements = {
            {
                kind = "interact",
                anchor = "raccoon_city",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0294")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M052",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0294")
    },
    {
        id = "PE_M054",
        track = "main",
        chapter = 8,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0295"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0296"),
        requirements = {
            {
                kind = "hold",
                anchor = "raccoon_city",
                hours = 1.5
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M053",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0297")
    },
    {
        id = "PE_M055",
        track = "main",
        chapter = 8,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0298"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0299"),
        requirements = {
            {
                kind = "vehicle_zone",
                anchor = "raccoon_city",
                invert = true
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            4
        },
        prerequisite = "PE_M054",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0300")
    },
    {
        id = "PE_M056",
        track = "main",
        chapter = 8,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0301"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0302"),
        requirements = {
            {
                kind = "interact",
                anchor = "raccoon_city",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0303")
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M055",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0303")
    },
    {
        id = "PE_M057",
        track = "main",
        chapter = 9,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0304"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0305"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "start_echo",
                    "start_muldraugh",
                    "start_riverside",
                    "start_rosewood",
                    "start_westpoint"
                },
                count = 5
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M056",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0306")
    },
    {
        id = "PE_M058",
        track = "main",
        chapter = 9,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0307"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0308"),
        requirements = {
            {
                kind = "interact",
                anchor = "echo_base",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0309")
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M057",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0310")
    },
    {
        id = "PE_M059",
        track = "main",
        chapter = 9,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0311"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0312"),
        requirements = {
            {
                kind = "interact",
                anchor = "fort_preston",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0313")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M058",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0314")
    },
    {
        id = "PE_M060",
        track = "main",
        chapter = 9,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0315"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0316"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_march_research",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0317")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M059",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0317")
    },
    {
        id = "PE_M061",
        track = "main",
        chapter = 9,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0318"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0319"),
        requirements = {
            {
                kind = "interact",
                anchor = "raven_center",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0320")
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M060",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0320")
    },
    {
        id = "PE_M062",
        track = "main",
        chapter = 9,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0321"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0322"),
        requirements = {
            {
                kind = "interact",
                anchor = "louisville_qz",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0323")
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M061",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0323")
    },
    {
        id = "PE_M063",
        track = "main",
        chapter = 9,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0324"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0325"),
        requirements = {
            {
                kind = "survive",
                hours = 12
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M062",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0326")
    },
    {
        id = "PE_M064",
        track = "main",
        chapter = 10,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0327"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0328"),
        requirements = {
            {
                kind = "items",
                items = {
                    {
                        type = "Base.Bandage",
                        count = 12
                    },
                    {
                        type = "Base.Battery",
                        count = 8
                    },
                    {
                        type = "Base.Hammer",
                        count = 1
                    },
                    {
                        type = "Base.Saw",
                        count = 1
                    },
                    {
                        type = "Base.Screwdriver",
                        count = 1
                    }
                }
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M063",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0329")
    },
    {
        id = "PE_M065",
        track = "main",
        chapter = 10,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0330"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0331"),
        requirements = {
            {
                kind = "distance",
                meters = 18000,
                onFoot = false
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M064",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0332")
    },
    {
        id = "PE_M066",
        track = "main",
        chapter = 10,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0333"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0334"),
        requirements = {
            {
                kind = "hold",
                anchor = "fort_preston",
                hours = 2.0
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M065",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0335")
    },
    {
        id = "PE_M067",
        track = "main",
        chapter = 10,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0336"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0337"),
        requirements = {
            {
                kind = "kills",
                count = 260
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            6
        },
        prerequisite = "PE_M066",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0338")
    },
    {
        id = "PE_M068",
        track = "main",
        chapter = 10,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0339"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0340"),
        requirements = {
            {
                kind = "vehicle_zone",
                anchor = "louisville_qz"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M067",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0341")
    },
    {
        id = "PE_M069",
        track = "main",
        chapter = 10,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0342"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0343"),
        requirements = {
            {
                kind = "survive",
                hours = 16
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M068",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0344")
    },
    {
        id = "PE_M070",
        track = "main",
        chapter = 10,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0107"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0345"),
        requirements = {
            {
                kind = "interact",
                anchor = "louisville_qz",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0346")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M069",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0346")
    },
    {
        id = "PE_M071",
        track = "main",
        chapter = 11,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0135"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0347"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_westpoint_checkpoint"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M070",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0348")
    },
    {
        id = "PE_M072",
        track = "main",
        chapter = 11,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0349"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0350"),
        requirements = {
            {
                kind = "hold",
                anchor = "sz_westpoint_checkpoint",
                hours = 1.0
            },
            {
                kind = "kills_zone",
                anchor = "sz_westpoint_checkpoint",
                count = 160
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M071",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0351")
    },
    {
        id = "PE_M073",
        track = "main",
        chapter = 11,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0117"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0352"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_louisville_complex"
            }
        },
        reward = {
            "item",
            "Base.Battery",
            4
        },
        prerequisite = "PE_M072",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0353")
    },
    {
        id = "PE_M074",
        track = "main",
        chapter = 11,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0354"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0355"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_louisville_complex",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0356")
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M073",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0357")
    },
    {
        id = "PE_M075",
        track = "main",
        chapter = 11,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0358"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0359"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "sz_louisville_complex",
                count = 300
            },
            {
                kind = "hold",
                anchor = "sz_louisville_complex",
                hours = 1.5
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M074",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0360")
    },
    {
        id = "PE_M076",
        track = "main",
        chapter = 11,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0361"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0362"),
        requirements = {
            {
                kind = "zone",
                anchor = "sz_north_checkpoint"
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M075",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0363")
    },
    {
        id = "PE_M077",
        track = "main",
        chapter = 11,
        number = 7,
        title = "OUTBOUND",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0364"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_north_checkpoint",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0365")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M076",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0365")
    },
    {
        id = "PE_M078",
        track = "main",
        chapter = 12,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0366"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0367"),
        requirements = {
            {
                kind = "survive",
                hours = 12
            }
        },
        reward = {
            "item",
            "Base.Battery",
            3
        },
        prerequisite = "PE_M077",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0368")
    },
    {
        id = "PE_M079",
        track = "main",
        chapter = 12,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0369"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0370"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "fort_preston",
                    "louisville_qz",
                    "sz_louisville_complex"
                },
                count = 3
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M078",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0371")
    },
    {
        id = "PE_M080",
        track = "main",
        chapter = 12,
        number = 3,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0372"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0373"),
        requirements = {
            {
                kind = "distance",
                meters = 5000,
                onFoot = true
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M079",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0374")
    },
    {
        id = "PE_M081",
        track = "main",
        chapter = 12,
        number = 4,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0375"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0376"),
        requirements = {
            {
                kind = "kills",
                count = 320
            }
        },
        reward = {
            "item",
            "Base.Bandage",
            6
        },
        prerequisite = "PE_M080",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0377")
    },
    {
        id = "PE_M082",
        track = "main",
        chapter = 12,
        number = 5,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0378"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0379"),
        requirements = {
            {
                kind = "hold",
                anchor = "sz_louisville_complex",
                hours = 2.0
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M081",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0380")
    },
    {
        id = "PE_M083",
        track = "main",
        chapter = 12,
        number = 6,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0381"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0382"),
        requirements = {
            {
                kind = "interact",
                anchor = "sz_louisville_complex",
                prompt = ProjectEcho.dataText("UI_ProjectEcho_Text_0383")
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M082",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0384")
    },
    {
        id = "PE_M084",
        track = "main",
        chapter = 12,
        number = 7,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0385"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0386"),
        requirements = {
            {
                kind = "choice",
                anchor = "sz_louisville_complex",
                choices = {
                    {
                        id = "broadcast",
                        label = ProjectEcho.dataText("UI_ProjectEcho_Text_0387")
                    },
                    {
                        id = "seal",
                        label = ProjectEcho.dataText("UI_ProjectEcho_Text_0388")
                    },
                    {
                        id = "burn",
                        label = ProjectEcho.dataText("UI_ProjectEcho_Text_0389")
                    }
                }
            }
        },
        reward = {
            "pool",
            "accessory",
            1
        },
        prerequisite = "PE_M083",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0390")
    },
    {
        id = "PE_S01_01",
        track = "side",
        chapter = 1,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0391"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0392"),
        requirements = {
            {
                kind = "items",
                items = {
                    {
                        type = "Base.Bandage",
                        count = 8
                    }
                }
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M003",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0391")
    },
    {
        id = "PE_S01_02",
        track = "side",
        chapter = 1,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0393"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0394"),
        requirements = {
            {
                kind = "distance",
                meters = 3500,
                onFoot = true
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M003",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0393")
    },
    {
        id = "PE_S02_01",
        track = "side",
        chapter = 2,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0395"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0396"),
        requirements = {
            {
                kind = "hold",
                anchor = "echo_base",
                hours = 0.75
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M010",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0395")
    },
    {
        id = "PE_S02_02",
        track = "side",
        chapter = 2,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0397"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0398"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "echo_base",
                count = 140
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M010",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0397")
    },
    {
        id = "PE_S03_01",
        track = "side",
        chapter = 3,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0399"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0400"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "muldraugh_police",
                    "sz_train_evac"
                },
                count = 2
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M017",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0399")
    },
    {
        id = "PE_S03_02",
        track = "side",
        chapter = 3,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0401"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0402"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "sz_train_evac",
                count = 180
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M017",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0401")
    },
    {
        id = "PE_S04_01",
        track = "side",
        chapter = 4,
        number = 1,
        title = "McCoy",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0403"),
        requirements = {
            {
                kind = "zone",
                anchor = "mccoy"
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M024",
        repeatable = false,
        target = "McCoy"
    },
    {
        id = "PE_S04_02",
        track = "side",
        chapter = 4,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0404"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0405"),
        requirements = {
            {
                kind = "distance",
                meters = 20000,
                onFoot = false
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M024",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0404")
    },
    {
        id = "PE_S05_01",
        track = "side",
        chapter = 5,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0406"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0407"),
        requirements = {
            {
                kind = "hold",
                anchor = "louisville_qz",
                hours = 1.5
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M031",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0406")
    },
    {
        id = "PE_S05_02",
        track = "side",
        chapter = 5,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0408"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0409"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "louisville_qz",
                count = 250
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M031",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0408")
    },
    {
        id = "PE_S06_01",
        track = "side",
        chapter = 6,
        number = 1,
        title = "March Ridge",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0410"),
        requirements = {
            {
                kind = "zone",
                anchor = "marchridge"
            },
            {
                kind = "kills_zone",
                anchor = "marchridge",
                count = 120
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M038",
        repeatable = false,
        target = "March Ridge"
    },
    {
        id = "PE_S06_02",
        track = "side",
        chapter = 6,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0411"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0412"),
        requirements = {
            {
                kind = "hold",
                anchor = "sz_bunker3",
                hours = 2.0
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M038",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0411")
    },
    {
        id = "PE_S07_01",
        track = "side",
        chapter = 7,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0413"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0414"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "raven_gate",
                    "raven_north",
                    "raven_center",
                    "raven_south"
                },
                count = 4
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M045",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0413")
    },
    {
        id = "PE_S07_02",
        track = "side",
        chapter = 7,
        number = 2,
        title = "Raven Sweep",
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0415"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "raven_center",
                count = 260
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M045",
        repeatable = false,
        target = "Raven Sweep"
    },
    {
        id = "PE_S08_01",
        track = "side",
        chapter = 8,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0416"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0417"),
        requirements = {
            {
                kind = "hold",
                anchor = "raccoon_city",
                hours = 2.0
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M052",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0416")
    },
    {
        id = "PE_S08_02",
        track = "side",
        chapter = 8,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0418"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0419"),
        requirements = {
            {
                kind = "distance",
                meters = 12000,
                onFoot = false
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M052",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0418")
    },
    {
        id = "PE_S09_01",
        track = "side",
        chapter = 9,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0420"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0421"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "start_echo",
                    "start_muldraugh",
                    "start_riverside",
                    "start_rosewood",
                    "start_westpoint"
                },
                count = 5
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M059",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0420")
    },
    {
        id = "PE_S09_02",
        track = "side",
        chapter = 9,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0422"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0423"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "constown",
                    "hartburg"
                },
                count = 2
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M059",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0422")
    },
    {
        id = "PE_S10_01",
        track = "side",
        chapter = 10,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0424"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0425"),
        requirements = {
            {
                kind = "items",
                items = {
                    {
                        type = "Base.Battery",
                        count = 12
                    },
                    {
                        type = "Base.Bandage",
                        count = 12
                    }
                }
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M066",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0424")
    },
    {
        id = "PE_S10_02",
        track = "side",
        chapter = 10,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0426"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0427"),
        requirements = {
            {
                kind = "distance",
                meters = 25000,
                onFoot = false
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M066",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0426")
    },
    {
        id = "PE_S11_01",
        track = "side",
        chapter = 11,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0428"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0429"),
        requirements = {
            {
                kind = "kills",
                count = 400
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M073",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0428")
    },
    {
        id = "PE_S11_02",
        track = "side",
        chapter = 11,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0430"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0431"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "fort_preston",
                    "sz_louisville_complex"
                },
                count = 2
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M073",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0430")
    },
    {
        id = "PE_S12_01",
        track = "side",
        chapter = 12,
        number = 1,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0432"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0433"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "echo_base",
                    "raven_center"
                },
                count = 2
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M080",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0432")
    },
    {
        id = "PE_S12_02",
        track = "side",
        chapter = 12,
        number = 2,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0434"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0435"),
        requirements = {
            {
                kind = "survive",
                hours = 24
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M080",
        repeatable = false,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0434")
    },
    {
        id = "PE_EG01",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0436"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0437"),
        requirements = {
            {
                kind = "kills",
                count = 350
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0436")
    },
    {
        id = "PE_EG02",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0438"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0439"),
        requirements = {
            {
                kind = "distance",
                meters = 30000,
                onFoot = false
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0438")
    },
    {
        id = "PE_EG03",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0440"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0441"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "raven_north",
                    "raven_center",
                    "raven_south"
                },
                count = 3
            }
        },
        reward = {
            "pool",
            "bag",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0440")
    },
    {
        id = "PE_EG04",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0442"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0443"),
        requirements = {
            {
                kind = "kills_zone",
                anchor = "raccoon_city",
                count = 220
            }
        },
        reward = {
            "pool",
            "clothing",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0442")
    },
    {
        id = "PE_EG05",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0444"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0445"),
        requirements = {
            {
                kind = "hold",
                anchor = "louisville_qz",
                hours = 2.0
            }
        },
        reward = {
            "pool",
            "tool",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0444")
    },
    {
        id = "PE_EG06",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0446"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0447"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "sz_bunker3",
                    "sz_march_research"
                },
                count = 2
            }
        },
        reward = {
            "pool",
            "book",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0446")
    },
    {
        id = "PE_EG07",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0448"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0449"),
        requirements = {
            {
                kind = "visit_zones",
                anchors = {
                    "start_echo",
                    "start_muldraugh",
                    "start_riverside",
                    "start_rosewood",
                    "start_westpoint"
                },
                count = 5
            }
        },
        reward = {
            "pool",
            "magazine",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0448")
    },
    {
        id = "PE_EG08",
        track = "endgame",
        chapter = 13,
        number = 0,
        title = ProjectEcho.dataText("UI_ProjectEcho_Text_0450"),
        description = ProjectEcho.dataText("UI_ProjectEcho_Text_0451"),
        requirements = {
            {
                kind = "survive",
                hours = 24
            }
        },
        reward = {
            "pool",
            "accessory",
            1
        },
        prerequisite = "PE_M084",
        repeatable = true,
        target = ProjectEcho.dataText("UI_ProjectEcho_Text_0450")
    }
}

-- Cooperative server balance profile (v0.9.11). PROJECT ECHO progression is
-- shared, so requirements are intentionally fixed around a 6-8 player server
-- instead of changing when somebody joins/leaves. Dynamic scaling would make a
-- live objective move under the players' feet.
ProjectEcho.CoopBalance = {
    targetPlayers = 7,
    profile = "shared_6_8",
}

local function peRoundTo(value,step)
    step=tonumber(step) or 1
    return math.max(step,math.floor((tonumber(value) or 0)/step+0.5)*step)
end

function ProjectEcho.scaleSharedRequirement(req)
    if type(req)~="table" or req.projectEchoCoopScaled then return req end
    req.projectEchoCoopScaled=true
    local kind=req.kind
    if kind=="kills" or kind=="kills_zone" then
        local base=math.max(1,tonumber(req.count) or 1)
        req.projectEchoBaseCount=base
        local scaled
        if base<=50 then
            scaled=math.max(100,base*2.75)
        elseif base<=150 then
            scaled=base*2.25
        elseif base<=300 then
            scaled=base*1.80
        else
            scaled=base*1.60
        end
        req.count=peRoundTo(scaled,5)
    elseif kind=="distance" then
        local base=math.max(1,tonumber(req.meters) or 1)
        req.projectEchoBaseMeters=base
        req.meters=math.max(6000,peRoundTo(base*2.0,100))
    elseif kind=="items" then
        for _,it in ipairs(req.items or {}) do
            local base=math.max(1,tonumber(it.count) or 1)
            it.projectEchoBaseCount=base
            it.count=math.max(2,math.ceil(base*2.0))
        end
    end
    return req
end

for _,raw in ipairs(ProjectEcho.RawMissions or {}) do
    for _,req in ipairs(raw.requirements or {}) do ProjectEcho.scaleSharedRequirement(req) end
end

ProjectEcho.Missions = {}
ProjectEcho.MissionsById = {}

-- Reward economy v2 (v0.9.11): every mission keeps an explicit T1-T5 tier,
-- but CLAIM now pays the PhunMart change wallet through a server adapter.
local function makeReward(raw,index)
    local id=raw and raw.id or nil
    return ProjectEcho.rollMissionReward(id,"bootstrap")
end

local clientOnly=false
if type(isClient)=="function" then
    local okC,c=pcall(isClient)
    local okS,srv=true,false
    if type(isServer)=="function" then okS,srv=pcall(isServer) end
    clientOnly=okC and c==true and (not okS or srv~=true)
end

for index, raw in ipairs(ProjectEcho.RawMissions) do
    local mission = {
        id = raw.id,
        -- Dedicated clients start with an empty ECHO catalog and receive the
        -- completed/current visibility set from the authoritative server sync.
        enabled = not clientOnly,
        type = "echo",
        letter = "E",
        title = raw.title,
        description = raw.description,
        targetCount = 100,
        sortOrder = 10000 + index,
        prerequisiteMissionID = nil,
        echoPrerequisite = raw.prerequisite,
        repeatable = raw.repeatable == true,
        rewards = makeReward(raw,index),
        rewardTier = ProjectEcho.getRewardTier(raw.id),
        track = raw.track,
        chapter = raw.chapter,
        echoTarget = raw.target,
        echo = {
            requirements = raw.requirements or {}
        }
    }
    ProjectEcho.Missions[#ProjectEcho.Missions + 1] = mission
    ProjectEcho.MissionsById[mission.id] = mission
end

ProjectEcho.applyRewardSeed("bootstrap")
if clientOnly and ProjectEcho.applyAssignmentVisibility then
    ProjectEcho.applyAssignmentVisibility(ProjectEcho.ClientState or {})
else
    TM42.CustomMissionDefs = ProjectEcho.Missions
end
TM42.rebuildMissionRegistry(true)
print("[PROJECT ECHO] registered " .. tostring(#ProjectEcho.Missions) .. " missions (catalog visibility is server-driven on clients)")
