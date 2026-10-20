-- PROJECT ECHO - mission tier economy / PhunMart change (v0.9.11)
ProjectEcho = ProjectEcho or {}
local PE = ProjectEcho

PE.RewardTierByMission = {
    ["PE_M001"] = 1,
    ["PE_M002"] = 1,
    ["PE_M003"] = 1,
    ["PE_M004"] = 1,
    ["PE_M005"] = 1,
    ["PE_M006"] = 1,
    ["PE_M007"] = 1,
    ["PE_M008"] = 1,
    ["PE_M009"] = 1,
    ["PE_M010"] = 1,
    ["PE_M011"] = 1,
    ["PE_M012"] = 1,
    ["PE_M013"] = 2,
    ["PE_M014"] = 2,
    ["PE_M015"] = 2,
    ["PE_M016"] = 2,
    ["PE_M017"] = 2,
    ["PE_M018"] = 2,
    ["PE_M019"] = 2,
    ["PE_M020"] = 2,
    ["PE_M021"] = 2,
    ["PE_M022"] = 2,
    ["PE_M023"] = 2,
    ["PE_M024"] = 2,
    ["PE_M025"] = 3,
    ["PE_M026"] = 3,
    ["PE_M027"] = 3,
    ["PE_M028"] = 3,
    ["PE_M029"] = 3,
    ["PE_M030"] = 3,
    ["PE_M031"] = 3,
    ["PE_M032"] = 3,
    ["PE_M033"] = 3,
    ["PE_M034"] = 3,
    ["PE_M035"] = 3,
    ["PE_M036"] = 3,
    ["PE_M037"] = 3,
    ["PE_M038"] = 3,
    ["PE_M039"] = 3,
    ["PE_M040"] = 3,
    ["PE_M041"] = 3,
    ["PE_M042"] = 3,
    ["PE_M043"] = 4,
    ["PE_M044"] = 4,
    ["PE_M045"] = 4,
    ["PE_M046"] = 4,
    ["PE_M047"] = 4,
    ["PE_M048"] = 4,
    ["PE_M049"] = 4,
    ["PE_M050"] = 4,
    ["PE_M051"] = 4,
    ["PE_M052"] = 4,
    ["PE_M053"] = 4,
    ["PE_M054"] = 4,
    ["PE_M055"] = 4,
    ["PE_M056"] = 4,
    ["PE_M057"] = 4,
    ["PE_M058"] = 4,
    ["PE_M059"] = 4,
    ["PE_M060"] = 4,
    ["PE_M061"] = 5,
    ["PE_M062"] = 5,
    ["PE_M063"] = 5,
    ["PE_M064"] = 5,
    ["PE_M065"] = 5,
    ["PE_M066"] = 5,
    ["PE_M067"] = 5,
    ["PE_M068"] = 5,
    ["PE_M069"] = 5,
    ["PE_M070"] = 5,
    ["PE_M071"] = 5,
    ["PE_M072"] = 5,
    ["PE_M073"] = 5,
    ["PE_M074"] = 5,
    ["PE_M075"] = 5,
    ["PE_M076"] = 5,
    ["PE_M077"] = 5,
    ["PE_M078"] = 5,
    ["PE_M079"] = 5,
    ["PE_M080"] = 5,
    ["PE_M081"] = 5,
    ["PE_M082"] = 5,
    ["PE_M083"] = 5,
    ["PE_M084"] = 5,
    ["PE_S01_01"] = 1,
    ["PE_S01_02"] = 1,
    ["PE_S02_01"] = 1,
    ["PE_S02_02"] = 1,
    ["PE_S03_01"] = 1,
    ["PE_S03_02"] = 1,
    ["PE_S04_01"] = 2,
    ["PE_S04_02"] = 2,
    ["PE_S05_01"] = 2,
    ["PE_S05_02"] = 2,
    ["PE_S06_01"] = 2,
    ["PE_S06_02"] = 2,
    ["PE_S07_01"] = 3,
    ["PE_S07_02"] = 3,
    ["PE_S08_01"] = 3,
    ["PE_S08_02"] = 3,
    ["PE_S09_01"] = 3,
    ["PE_S09_02"] = 3,
    ["PE_S10_01"] = 4,
    ["PE_S10_02"] = 4,
    ["PE_S11_01"] = 4,
    ["PE_S11_02"] = 4,
    ["PE_S12_01"] = 5,
    ["PE_S12_02"] = 5,
    ["PE_EG01"] = 5,
    ["PE_EG02"] = 5,
    ["PE_EG03"] = 5,
    ["PE_EG04"] = 5,
    ["PE_EG05"] = 5,
    ["PE_EG06"] = 5,
    ["PE_EG07"] = 5,
    ["PE_EG08"] = 5,
}

-- PROJECT ECHO economy v2 (v0.9.11): PhunMart wallet payouts.
-- Amounts are in PhunMart CHANGE cents. The Mission displays a harmless payout
-- receipt; after a successful CLAIM the authoritative server credits the wallet
-- and removes the receipt. If PhunMart is unavailable, the receipt is left in
-- the inventory as a visible recovery marker instead of silently losing reward.
PE.CurrencyByTier = {
    [1] = { amount=500,  item="ProjectEcho.PhunMartPayoutT1" }, -- $5.00
    [2] = { amount=800,  item="ProjectEcho.PhunMartPayoutT2" }, -- $8.00
    [3] = { amount=1200, item="ProjectEcho.PhunMartPayoutT3" }, -- $12.00
    [4] = { amount=1800, item="ProjectEcho.PhunMartPayoutT4" }, -- $18.00
    [5] = { amount=2500, item="ProjectEcho.PhunMartPayoutT5" }, -- $25.00
}

function PE.getRewardTier(missionID)
    return tonumber(PE.RewardTierByMission and PE.RewardTierByMission[missionID]) or 1
end

function PE.getMissionCreditAmount(missionID)
    local row=PE.CurrencyByTier[PE.getRewardTier(missionID)] or PE.CurrencyByTier[1]
    return tonumber(row.amount) or 500
end

function PE.getMissionPayoutItem(missionID)
    local row=PE.CurrencyByTier[PE.getRewardTier(missionID)] or PE.CurrencyByTier[1]
    return tostring(row.item)
end

function PE.rollMissionReward(missionID,seed)
    return {{type=PE.getMissionPayoutItem(missionID),count=1}}
end

function PE.applyRewardSeed(seed)
    -- Kept for save/protocol compatibility. PhunMart payouts are deterministic by
    -- tier; campaign seeds no longer affect economy rewards.
    seed=tostring(seed or "phunmart-v2")
    local changed=PE._AppliedRewardSeed~=seed
    PE._AppliedRewardSeed=seed
    PE.ActiveRewardSeed=seed
    for id,m in pairs(PE.MissionsById or {}) do
        if PE.isEchoMission and PE.isEchoMission(m) then
            m.rewardTier=PE.getRewardTier(id)
            m.echoCredits=PE.getMissionCreditAmount(id)
            m.rewards=PE.rollMissionReward(id,seed)
        end
    end
    return changed
end
