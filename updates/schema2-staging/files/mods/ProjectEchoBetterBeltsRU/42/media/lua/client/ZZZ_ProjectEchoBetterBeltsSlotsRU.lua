-- PROJECT ECHO Better Belts RU: text-only slot-name overrides (B42.21)
-- No original mod file is changed; no physics / gameplay changes.
local function applyBetterBeltsNames()
    if type(ISHotbarAttachDefinition) ~= "table" then return end
    for _, slot in ipairs(ISHotbarAttachDefinition) do
        if type(slot) == "table" then
            if slot.type == "FrontBeltL" then
                slot.name = "Пояс спереди слева"
            elseif slot.type == "FrontBeltR" then
                slot.name = "Пояс спереди справа"
            elseif slot.type == "LowerBack" then
                slot.name = "Пояс сзади"
            end
        end
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(applyBetterBeltsNames)
end
