-- PROJECT ECHO / Radio Sync v0.1.0
-- MP station sync only. No changes to music files or FMOD.
PERS_Config = PERS_Config or {
    minTrackSeconds = 12,        -- reject duplicate/too-early next requests
    leaderTimeoutSeconds = 25,   -- elect another listener when current DJ goes away
    heartbeatSeconds = 7,       -- sent by clients only while listening
}
return PERS_Config
