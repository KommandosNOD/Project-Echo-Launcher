-- PROJECT ECHO Admin Commands v0.1.2
-- SERVER ONLY. Never place this file under lua/client or lua/shared.
-- Edit only while the server is stopped.
-- Username is the login name, not the character display name.
-- Set SteamID64 to a quoted 17-digit number for stronger ownership verification.
ProjectEchoAdminCommandsConfig = {
    Owners = {
        ["KommandosNOD"] = "",  -- TODO: paste SteamID64 for stricter verification
    },
    RequireSteamID = false,       -- change to true AFTER populating SteamID64
    AllowRemoteHeal = true,
    AllowTeleport = true,
    AllowInvisible = true,       -- only the owner, self only; old configs default to enabled
    CooldownMilliseconds = 750,
}
