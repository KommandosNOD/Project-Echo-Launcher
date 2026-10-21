package com.projectecho.zombiewindowfix;

import me.zed_0xff.zombie_buddy.Patch;

/**
 * PZ 42.21 / ZombieBuddy 2.3.x.
 * IsoGameCharacter.dropHeavyItems() is incorrectly reached by IsoZombie
 * during window climbing. The network packet expects IsoPlayer.
 * Skip the original only for IsoZombie, keep players unchanged.
 */
@Patch(className = "zombie.characters.IsoGameCharacter", methodName = "dropHeavyItems")
public class Patch_ZombieWindowDrop {
    @Patch.OnEnter(skipOn = true)
    public static boolean onEnter(@Patch.This Object character) {
        if (character == null) return false;
        Class<?> type = character.getClass();
        while (type != null) {
            if ("zombie.characters.IsoZombie".equals(type.getName())) {
                return true;
            }
            type = type.getSuperclass();
        }
        return false;
    }
}
