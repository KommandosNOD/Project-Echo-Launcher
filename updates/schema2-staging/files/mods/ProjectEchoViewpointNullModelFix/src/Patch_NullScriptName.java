package projectecho.viewpoint.nullmodel;

import java.util.concurrent.atomic.AtomicInteger;
import me.zed_0xff.zombie_buddy.annotations.Patch;

/**
 * Project Zomboid B42.21 + Viewpoint 0.1.6.1:
 * ScriptBucketCollection.getScript(String name) calls name.contains(...)
 * without a null guard. Viewpoint calls it for a ground item that lacks
 * a model script name and disables its 3D scene on NPE.
 *
 * Returning null for null input is the least-invasive null-object
 * behavior: absent model script stays absent; non-null names remain
 * completely untouched. This patch does NOT repair the source item.
 */
@Patch(className = "zombie.scripting.ScriptBucketCollection", methodName = "getScript", warmUp = true)
public final class Patch_NullScriptName {
    private static final AtomicInteger BLOCKED = new AtomicInteger();
    private Patch_NullScriptName() {}

    @Patch.OnEnter(skipOn = true)
    public static boolean preventNullName(@Patch.Argument(0) String name) {
        if (name != null) return false;
        int count = BLOCKED.incrementAndGet();
        if (count == 1 || count == 10 || count == 100) {
            System.out.println("[PE Viewpoint NullModelFix] skipped null script-name lookup (count=" + count + ")");
        }
        return true; // ZB skips original; getScript() default return = null.
    }
}
