PROJECT ECHO - UNIFIED RU LOCALIZATION v1.0
===========================================
Project Zomboid Build 42.21 (multiplayer)

This archive merges the original 3 translation mods:
  ProjectEcho_Frockin_RU
  ProjectEcho_6Mods_RU
  ProjectEcho_PSA_RU

INSTALL
1. Stop game/server.
2. Extract the ProjectEcho_RU folder into:
   C:\Users\KommandosNOD\Zomboid\mods\ProjectEcho_RU
3. In the single Mods= line of servertest.ini:
   REMOVE: ;ProjectEcho_Frockin_RU
   REMOVE: ;ProjectEcho_6Mods_RU
   REMOVE: ;ProjectEcho_PSA_RU
   ADD AT THE END: ;ProjectEcho_RU
4. Give the SAME ProjectEcho_RU folder to all players through the launcher.
5. Restart the server and client. Select Russian language in the game.

DO NOT change WorkshopItems=. All original gameplay mods remain enabled.
Other independent translations (e.g. ProjectEcho_UI_RU) are NOT included here.

COVERAGE
 - ContextMenu.json: 255
 - IG_UI.json: 747
 - ItemName.json: 3874
 - Recipes.json: 157
 - Sandbox.json: 799
 - Tooltip.json: 179
 - UI.json: 34
Total: 6045 unique localization entries.
Colliding keys across the three source mods: 0.

Only mod.info and translation JSONs are shipped; no Lua gameplay code,
item scripts, models, textures, or save files are modified.

NOTE: Existing English text that was not translated in the 3 input mods
will remain English. This is a lossless merge, not a new translation pass.

--- v1.1 ---
PhunMart 2: corrected Nickel / Dime / Quarter names and related currency items.
Copy ProjectEcho_RU over the existing folder (replace files). Restart server + all clients.
Mod ID is unchanged: ProjectEcho_RU. Do not add another mod.
