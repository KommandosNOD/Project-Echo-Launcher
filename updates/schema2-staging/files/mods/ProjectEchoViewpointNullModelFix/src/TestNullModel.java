package projectecho.viewpoint.nullmodel;
public final class TestNullModel {
    public static void main(String[] args) throws Exception {
        if (!Patch_NullScriptName.preventNullName(null)) throw new AssertionError("null must be skipped");
        if (Patch_NullScriptName.preventNullName("Base.Hammer")) throw new AssertionError("valid name must execute");
        var a = Patch_NullScriptName.class.getAnnotation(me.zed_0xff.zombie_buddy.annotations.Patch.class);
        if (!a.className().equals("zombie.scripting.ScriptBucketCollection") || !a.methodName().equals("getScript")) throw new AssertionError("target");
        var m = Patch_NullScriptName.class.getMethod("preventNullName", String.class);
        var on = m.getAnnotation(me.zed_0xff.zombie_buddy.annotations.Patch.OnEnter.class);
        if (!on.skipOn()) throw new AssertionError("skipOn");
        System.out.println("PASS: null skip, non-null passthrough, annotation metadata");
    }
}
