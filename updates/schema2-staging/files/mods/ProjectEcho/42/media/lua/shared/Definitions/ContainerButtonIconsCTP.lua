-- RM_ServerCompatPatch: dedicated-server UI guard.
-- This file only registers UI textures and should not run on a dedicated server.
if isServer and isServer() then
    return
end
require "Definitions/ContainerButtonsIcons"

ContainerButtonIcons = ContainerButtonIcons or {}

local t = {}
t.StandingToolbox = getTexture("media/ui/Container_StandingToolbox.png") -- can use any location, container_ not required
t.ToolTray = getTexture("media/ui/Container_ToolTray.png")
t.Safe = getTexture("media/ui/Container_Safe.png")
t.SpoonRack = getTexture("media/ui/Container_SpoonRack.png")
t.WireShelves = getTexture("media/ui/Container_WireShelves.png")
t.extinguisher_box  = getTexture("media/ui/Container_extinguisher_box.png")
t.Rusty = getTexture("media/ui/Container_Rusty.png")


ContainerButtonIcons.StandingToolbox = t.StandingToolbox -- "Toolbox" refers to unique container name in tile properties
ContainerButtonIcons.ToolTray = t.ToolTray
ContainerButtonIcons.Safe = t.Safe
ContainerButtonIcons.SpoonRack = t.SpoonRack
ContainerButtonIcons.WireShelves = t.WireShelves
ContainerButtonIcons.extinguisher_box  = t.extinguisher_box 
ContainerButtonIcons.Rusty = t.Rusty


ContainerButtonIcons.ExoticPot = getTexture("media/ui/Container_ExoticPot.png") -- new method. no need to define local. will leave previous method in place, if performance impact is detected in either method then adjust
ContainerButtonIcons.StackedAmmoPallet = getTexture("media/ui/Container_StackedAmmoPallet.png")
ContainerButtonIcons.WeaponPallet = getTexture("media/ui/Container_WeaponPallet.png")
ContainerButtonIcons.ToolPallet = getTexture("media/ui/Container_ToolPallet.png")
ContainerButtonIcons.SuppliesPallet = getTexture("media/ui/Container_SuppliesPallet.png")
ContainerButtonIcons.FoodPallet = getTexture("media/ui/Container_FoodPallet.png")
ContainerButtonIcons.BulletinBoard = getTexture("media/ui/Container_Bulletinboard.png")