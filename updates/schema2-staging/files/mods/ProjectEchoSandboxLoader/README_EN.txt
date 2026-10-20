PROJECT ECHO - SANDBOX LOADER 1.0.0
===================================
For Project Zomboid Build 42.21 MP (dedicated server).

INSTALLATION (server stopped):
1) Make a backup of your Zomboid/Server/ and saves.
2) Extract the ZIP contents to:
   C:\Users\KommandosNOD\Zomboid\mods\
   The resulting path must be:
   C:\Users\KommandosNOD\Zomboid\mods\ProjectEchoSandboxLoader\42\mod.info
3) Add ;ProjectEchoSandboxLoader to Mods= in:
   C:\Users\KommandosNOD\Zomboid\Server\servertest.ini
   No Workshop ID is needed for this local server-side-only mod.
4) Disable/REMOVE PEForceMultiHit from Mods= (to avoid two independent controllers).
5) Start the server normally through your existing start.bat.
6) Find [ProjectEchoSandboxLoader] lines in the server console/log.

CANONICAL CONFIG:
   ...\Zomboid\mods\ProjectEchoSandboxLoader\42\SandboxPreset.lua
This includes your exact 2026-10-17 08:43:19 source file (VERSION=6).
To replace it, stop the server and paste another complete SandboxVars = { ... }
file at this exact path. Then start the server again.

BEHAVIOR:
- Reads file from own active 42/ directory using getModFileReader.
- Applies SandboxVars to the Lua table and registered Java SandboxOptions.
- Runs at server-script load and OnServerStarted.
- Every 10 in-game minutes compares values and restores drifted options.
- Checks again before server save.
- Does NOT overwrite servertest.ini, servertest_SandboxVars.lua or world saves.
- 'MultiHitZombies = true' is included in the reference file.

LIMITATIONS:
- Mods may override the same setting later; check console to see conflicts.
- Runtime sandbox changes cannot retroactively regenerate existing chunks/world.
- This has NOT been validated in your local 42.21 installation; verify log
  and multiplayer behavior on a backed-up test copy first.
- The original server's SandboxVars file can still be rewritten by the game;
  this mod locks its *runtime values*, not the file contents.
- Does not change servertest.ini (PVP, server ports, mods, etc.).
- If you change the canonical preset, restart the server (not live reload).

ERRORS / LOG CHECK:
  [ProjectEchoSandboxLoader] preset loaded from this mod
  [ProjectEchoSandboxLoader] OnServerStarted: Lua changed=..., Java options changed=..., errors=0, MultiHitZombies=true

If "preset not found" appears, check the layout (no double nested folder).
