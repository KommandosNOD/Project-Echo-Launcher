-- VFE appends model suffixes that cosmetic replacement packs may not provide.
local function install()
    if type(VFEApplySprite) ~= "function" then return end
    if VPCADS_VFEModelGuardInstalled then return end
    local original = VFEApplySprite
    VFEApplySprite = function(weapon, sprite)
        if weapon and type(sprite) == "string" and ScriptManager and ScriptManager.instance then
            local sm = ScriptManager.instance
            if not sm:getModelScript(sprite) then
                local base = weapon:getOriginalWeaponSprite()
                if base and sm:getModelScript(base) then sprite = base end
            end
        end
        return original(weapon, sprite)
    end
    VPCADS_VFEModelGuardInstalled = true
end
Events.OnGameStart.Add(install)
