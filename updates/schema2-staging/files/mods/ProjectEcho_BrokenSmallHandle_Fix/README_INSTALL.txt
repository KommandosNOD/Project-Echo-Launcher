PROJECT ECHO - Hand Models 3D Fix v0.2 TEST (Build 42.21)

FIXES:
- Broken Base.SmallHandle oversized wooden object in hands (v0.1 fallback).
- Vanilla Base.SleepingBag_* item versions, packed and unpacked, showing too large
  while held. Keeps the proper rolled sleeping-bag model color and original mesh.

HOW TO INSTALL:
1) Extract the ZIP completely to a separate folder.
2) Close Project Zomboid, run INSTALL.bat (it runs GENERATE_AND_INSTALL.ps1).
3) If Steam library is not detected, enter the full ProjectZomboid game folder.
4) Keep Mod ID: PEBrokenSmallHandle3DFix, version 0.2 replaces 0.1.
5) Restart PZ and test locally with Viewpoint.

INSTALL.bat reads vanilla model files from the game, makes 35%-scale COPIES
inside C:\Users\<username>\Zomboid\mods\ProjectEcho_BrokenSmallHandle_Fix\42\media\scripts.
Original game files are NOT edited.

Only local held item appearance changes. On unequip, the original model is
restored. World models, pack/unpack recipe, attachments, physics and item stats
are not directly edited. If there is a conflict with Viewpoint, the workaround
may not visually apply; this v0.2 is NOT tested in the user's game.

LOGS: C:\Users\<username>\Zomboid\console.txt -- search [PE-3DFix].
MISSING aliases: rerun INSTALL.bat and inspect any WARN messages.

SERVER / MP:
Test in single-player first. After successful test, synchronize the generated
mod directory to clients through PROJECT ECHO launcher, then add the same Mod
ID to server Mods= when server requires it. Do not silently change production.

REMOVAL:
Disable PEBrokenSmallHandle3DFix and delete the entire
Zomboid\mods\ProjectEcho_BrokenSmallHandle_Fix directory.
