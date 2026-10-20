PROJECT ECHO / Viewpoint Null Model Fix - EXPERIMENTAL v0.1.0
============================================================
Target: Project Zomboid B42.21.0 + Viewpoint 0.1.6.1 + ZombieBuddy 2.x+
Crash targeted: NPE in ScriptBucketCollection.getScript(String name) from
ItemModelRenderer.itemHasModel / Viewpoint FloorDecals.items, name == null.

INSTALLATION (CLIENT TEST FIRST)
1. Close the game and BACK UP your local user data. Do not change the server.
2. Extract ProjectEchoViewpointNullModelFix folder to:
   C:\Users\KommandosNOD\Zomboid\mods\
3. Enable mod ID ProjectEchoViewpointNullModelFix on the CLIENT, after Viewpoint,
   with ZombieBuddy installed. On a dedicated server it is not required.
4. Fully restart PZ, test same location with the same dropped items.

SUCCESS LOG LINES
[PE Viewpoint NullModelFix] v0.1.0 initialized...
[PE Viewpoint NullModelFix] skipped null script-name lookup (count=1)

If no first line appears: ZombieBuddy did not load the Java mod.
If you see PATCH ERROR or the same crash: disable the patch, save console.txt,
provide Viewpoint.jar + ProjectZomboid game JAR for precise API review.

WHAT IT DOES
- When the engine looks up a SCRIPT using a NULL script name, skips the
  original String.contains invocation and returns NULL instead of crashing.
- Non-null names still use the unmodified game method.
- Does not delete/mutate world items, Steam Workshop originals or saves.
- This is a targeted workaround; the item or mod with missing model is not
  identified or repaired. Other bugs/crashes can still happen.

RISKS
- Untested inside Project Zomboid (compiled and control logic tested only).
- Some other game code might not handle a null script result gracefully.
- Third-party Java patches may interact with this patch.
- Test off the production server first. Disable/remove at any time.

Source and build notes included for review. Java class file version 61 (Java 17)
works with Java 25 game runtime. ZombieBuddy annotation API per upstream docs.
Compiled against minimal compile-only annotation stubs; NOT bundled.
