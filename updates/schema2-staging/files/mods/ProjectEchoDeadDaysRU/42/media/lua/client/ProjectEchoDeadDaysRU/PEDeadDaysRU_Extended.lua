-- PROJECT ECHO - dynamic story journal translations 0.1.3
-- Native UTF-8 strings live in Translate/RU/UI.json; this source stays ASCII.
local R = PEDeadDaysRU
local previousTranslate = R.translate
local ex = {
    ["Neutral"] = "UI_ProjectEchoDDS_EXT_0001",
    ["Wary"] = "UI_ProjectEchoDDS_EXT_0002",
    ["Hostile"] = "UI_ProjectEchoDDS_EXT_0003",
    ["Trusted"] = "UI_ProjectEchoDDS_EXT_0004",
    ["Allied"] = "UI_ProjectEchoDDS_EXT_0005",
    ["Kill on sight"] = "UI_ProjectEchoDDS_EXT_0006",
    ["Neighbours"] = "UI_ProjectEchoDDS_EXT_0007",
    ["Neighbors"] = "UI_ProjectEchoDDS_EXT_0008",
    ["Church Volunteers"] = "UI_ProjectEchoDDS_EXT_0009",
    ["Slackwater Rats"] = "UI_ProjectEchoDDS_EXT_0010",
    ["County Sheriff"] = "UI_ProjectEchoDDS_EXT_0011",
    ["5th SFG (Airborne) - Isolated Detachment"] = "UI_ProjectEchoDDS_EXT_0012",
    ["5th SFG (Airborne)"] = "UI_ProjectEchoDDS_EXT_0013",
    ["False Checkpoint Crew"] = "UI_ProjectEchoDDS_EXT_0014",
    ["COMMUNITY"] = "UI_ProjectEchoDDS_EXT_0015",
    ["MILITARY"] = "UI_ProjectEchoDDS_EXT_0016",
    ["ANTAGONIST"] = "UI_ProjectEchoDDS_EXT_0017",
    ["WILDCARD"] = "UI_ProjectEchoDDS_EXT_0018",
    ["Community"] = "UI_ProjectEchoDDS_EXT_0019",
    ["Military"] = "UI_ProjectEchoDDS_EXT_0020",
    ["Antagonist"] = "UI_ProjectEchoDDS_EXT_0021",
    ["Wildcard"] = "UI_ProjectEchoDDS_EXT_0022",
    ["Visitors"] = "UI_ProjectEchoDDS_EXT_0023",
    ["Law Enforcement"] = "UI_ProjectEchoDDS_EXT_0024",
    ["MILITARY | 1993 / Late Factions"] = "UI_ProjectEchoDDS_EXT_0025",
    ["1993 / Late Factions"] = "UI_ProjectEchoDDS_EXT_0026",
    ["Fall 1993"] = "UI_ProjectEchoDDS_EXT_0027",
    ["Wolfe"] = "UI_ProjectEchoDDS_EXT_0028",
    ["Wolfes"] = "UI_ProjectEchoDDS_EXT_0029",
    ["Jasper"] = "UI_ProjectEchoDDS_EXT_0030",
    ["Bub"] = "UI_ProjectEchoDDS_EXT_0031",
    ["Marisol"] = "UI_ProjectEchoDDS_EXT_0032",
    ["Jolene"] = "UI_ProjectEchoDDS_EXT_0033",
    ["Otis"] = "UI_ProjectEchoDDS_EXT_0034",
    ["March Ridge"] = "UI_ProjectEchoDDS_EXT_0035",
    ["Valley Station"] = "UI_ProjectEchoDDS_EXT_0036",
    ["Muldraugh"] = "UI_ProjectEchoDDS_EXT_0037",
    ["Rosewood"] = "UI_ProjectEchoDDS_EXT_0038",
    ["Riverside"] = "UI_ProjectEchoDDS_EXT_0039",
    ["West Point"] = "UI_ProjectEchoDDS_EXT_0040",
    ["Louisville"] = "UI_ProjectEchoDDS_EXT_0041",
    ["Spurlock"] = "UI_ProjectEchoDDS_EXT_0042",
    ["Church Volunteers want to know"] = "UI_ProjectEchoDDS_EXT_0043",
    ["Bounty: Bub"] = "UI_ProjectEchoDDS_EXT_0044",
    ["Recon: Slackwater Rats"] = "UI_ProjectEchoDDS_EXT_0045",
    ["Taken: Jasper"] = "UI_ProjectEchoDDS_EXT_0046",
    ["The Vault at clearing"] = "UI_ProjectEchoDDS_EXT_0047",
    ["Lightfoot"] = "UI_ProjectEchoDDS_EXT_0048",
    ["Aiming"] = "UI_ProjectEchoDDS_EXT_0049",
    ["Maintenance"] = "UI_ProjectEchoDDS_EXT_0050",
    ["Lightfoot XP"] = "UI_ProjectEchoDDS_EXT_0051",
    ["Aiming XP"] = "UI_ProjectEchoDDS_EXT_0052",
    ["Maintenance XP"] = "UI_ProjectEchoDDS_EXT_0053",
    ["EXP"] = "UI_ProjectEchoDDS_EXT_0054",
    ["XP"] = "UI_ProjectEchoDDS_EXT_0055",
    ["EXPIRED"] = "UI_ProjectEchoDDS_EXT_0056",
    ["Expired"] = "UI_ProjectEchoDDS_EXT_0057",
    ["RECENT"] = "UI_ProjectEchoDDS_EXT_0058",
    ["New lead"] = "UI_ProjectEchoDDS_EXT_0059",
    ["Incoming radio"] = "UI_ProjectEchoDDS_EXT_0060",
    ["The Long Winter"] = "UI_ProjectEchoDDS_EXT_0061",
    ["The Fence"] = "UI_ProjectEchoDDS_EXT_0062",
    ["Smoke from a chimney. Washing on a line."] = "UI_ProjectEchoDDS_EXT_0063",
    ["No one rides with you yet."] = "UI_ProjectEchoDDS_EXT_0064",
    ["The Church Volunteers want to know how many guns the Slackwater Rats have at a tree line near the backroads outside March Ridge. Look, count, don't touch."] = "UI_ProjectEchoDDS_EXT_0065",
    ["Nobody's heard from the Wolfe place at the the backroads outside March Ridge warehouse in days. Go look."] = "UI_ProjectEchoDDS_EXT_0066",
    ["look, count, don't touch."] = "UI_ProjectEchoDDS_EXT_0067",
    ["Look, count, don't touch."] = "UI_ProjectEchoDDS_EXT_0068",
    ["No one rides with you yet. Help the Spurlock place and they'll send someone. People you rescue may offer to come along too."] = "UI_ProjectEchoDDS_EXT_0069",
    ["Daily: Check on the Wolfes"] = "UI_ProjectEchoDDS_EXT_0070",
    ["The backroads outside March Ridge warehouse"] = "UI_ProjectEchoDDS_EXT_0071",
    ["A tree line near the backroads outside March Ridge"] = "UI_ProjectEchoDDS_EXT_0072",
    ["COMMUNITY | Visitors"] = "UI_ProjectEchoDDS_EXT_0073",
    ["Neutral (5)"] = "UI_ProjectEchoDDS_EXT_0074",
    ["Wary (-10)"] = "UI_ProjectEchoDDS_EXT_0075",
    ["Hostile (-42)"] = "UI_ProjectEchoDDS_EXT_0076",
    ["Trusted (25)"] = "UI_ProjectEchoDDS_EXT_0077",
    ["Fall, 1993"] = "UI_ProjectEchoDDS_EXT_0078",
    ["WORLD"] = "UI_ProjectEchoDDS_EXT_0079",
    ["Visitor"] = "UI_ProjectEchoDDS_EXT_0080",
    ["visitors"] = "UI_ProjectEchoDDS_EXT_0081",
    ["New lead: The Fence"] = "UI_ProjectEchoDDS_EXT_0082",
    ["New lead: The Vault at clearing"] = "UI_ProjectEchoDDS_EXT_0083",
    ["Incoming radio: Tessa Spurlock (the Spurlock place)"] = "UI_ProjectEchoDDS_EXT_0084",
    ["Storyline"] = "UI_ProjectEchoDDS_EXT_0085",
}
local rules = {
    { p = "^New lead: (.+)$", k = "UI_ProjectEchoDDS_EXT_0086" },
    { p = "^New mission: (.+)$", k = "UI_ProjectEchoDDS_EXT_0087" },
    { p = "^Incoming radio: (.+)$", k = "UI_ProjectEchoDDS_EXT_0088" },
    { p = "^Day (%d+) %- The Long Winter, Act (%d+)%. A new story begins: The Long Winter%. Daily ops are posted%.$", k = "UI_ProjectEchoDDS_EXT_0089" },
    { p = "^Day (%d+) %- (.-), Act (%d+)%. A new story begins: (.-)%. Daily ops are posted%.$", k = "UI_ProjectEchoDDS_EXT_0090" },
    { p = "^Day (%d+) (%d%d:%d%d)$", k = "UI_ProjectEchoDDS_EXT_0091" },
    { p = "^Day (%d+)$", k = "UI_ProjectEchoDDS_EXT_0092" },
    { p = "^Act (%d+): (.+)$", k = "UI_ProjectEchoDDS_EXT_0093" },
    { p = "^Bounty: (.+)$", k = "UI_ProjectEchoDDS_EXT_0094" },
    { p = "^Recon: (.+)$", k = "UI_ProjectEchoDDS_EXT_0095" },
    { p = "^Taken: (.+)$", k = "UI_ProjectEchoDDS_EXT_0096" },
    { p = "^Ransom: (.+)$", k = "UI_ProjectEchoDDS_EXT_0097" },
    { p = "^Gone Missing: (.+)$", k = "UI_ProjectEchoDDS_EXT_0098" },
    { p = "^No One Left Behind: (.+)$", k = "UI_ProjectEchoDDS_EXT_0099" },
    { p = "^Distress: (.+)$", k = "UI_ProjectEchoDDS_EXT_0100" },
    { p = "^The Vault at (.+)$", k = "UI_ProjectEchoDDS_EXT_0101" },
    { p = "^Daily: Check on the (.+)s$", k = "UI_ProjectEchoDDS_EXT_0102" },
    { p = "^Daily: (.+)$", k = "UI_ProjectEchoDDS_EXT_0103" },
    { p = "^The Long Road: (.+)$", k = "UI_ProjectEchoDDS_EXT_0104" },
    { p = "^Nest: (.+)$", k = "UI_ProjectEchoDDS_EXT_0105" },
    { p = "^Trade: (.+)$", k = "UI_ProjectEchoDDS_EXT_0106" },
    { p = "^Project: (.+)$", k = "UI_ProjectEchoDDS_EXT_0107" },
    { p = "^Supply Run: (.+)$", k = "UI_ProjectEchoDDS_EXT_0108" },
    { p = "^Shopping List: (.+)$", k = "UI_ProjectEchoDDS_EXT_0109" },
    { p = "^Empty Shelves: (.+)$", k = "UI_ProjectEchoDDS_EXT_0110" },
    { p = "^Dispute: (.+) and (.+)$", k = "UI_ProjectEchoDDS_EXT_0111" },
    { p = "^From: (.+)$", k = "UI_ProjectEchoDDS_EXT_0112" },
    { p = "^([%a ]+) ([%+%-]?%d+)$", k = "UI_ProjectEchoDDS_EXT_0113" },
    { p = "^([A-Z]+)%s+|%s+(.+)$", k = "UI_ProjectEchoDDS_EXT_0114" },
    { p = "^The (.+) want to know how many guns the (.+) have at (.+)%. Look, count, don't touch%.$", k = "UI_ProjectEchoDDS_EXT_0115" },
    { p = "^Nobody's heard from the (.+) place at (.+) in days%. Go look%.$", k = "UI_ProjectEchoDDS_EXT_0116" },
    { p = "^No one rides with you yet%. Help (.+) and they'll send someone%. People you rescue may offer to come along too%.$", k = "UI_ProjectEchoDDS_EXT_0117" },
    { p = "^[Aa] tree line near (.+)$", k = "UI_ProjectEchoDDS_EXT_0118" },
    { p = "^[Aa] clearing near (.+)$", k = "UI_ProjectEchoDDS_EXT_0119" },
    { p = "^[Aa] field near (.+)$", k = "UI_ProjectEchoDDS_EXT_0120" },
    { p = "^A ([%a ]+) near (.+)$", k = "UI_ProjectEchoDDS_EXT_0121" },
    { p = "^[Tt]he backroads outside (.+)$", k = "UI_ProjectEchoDDS_EXT_0122" },
    { p = "^the (.+) warehouse$", k = "UI_ProjectEchoDDS_EXT_0123" },
    { p = "^the (.+) hospital$", k = "UI_ProjectEchoDDS_EXT_0124" },
    { p = "^the (.+) school$", k = "UI_ProjectEchoDDS_EXT_0125" },
    { p = "^the (.+) gas station$", k = "UI_ProjectEchoDDS_EXT_0126" },
    { p = "^the (.+) house$", k = "UI_ProjectEchoDDS_EXT_0127" },
    { p = "^the (.+) church$", k = "UI_ProjectEchoDDS_EXT_0128" },
    { p = "^the (.+) motel$", k = "UI_ProjectEchoDDS_EXT_0129" },
    { p = "^the (.+) police station$", k = "UI_ProjectEchoDDS_EXT_0130" },
    { p = "^the (.+) supermarket$", k = "UI_ProjectEchoDDS_EXT_0131" },
    { p = "^the (.+) pharmacy$", k = "UI_ProjectEchoDDS_EXT_0132" },
    { p = "^the (.+) store$", k = "UI_ProjectEchoDDS_EXT_0133" },
    { p = "^the (.+) outpost$", k = "UI_ProjectEchoDDS_EXT_0134" },
    { p = "^the (.+) place$", k = "UI_ProjectEchoDDS_EXT_0135" },
    { p = "^the (.+) settlement$", k = "UI_ProjectEchoDDS_EXT_0136" },
    { p = "^the (.+) farm$", k = "UI_ProjectEchoDDS_EXT_0137" },
    { p = "^the (.+) warehouse$", k = "UI_ProjectEchoDDS_EXT_0138" },
    { p = "^((%a+)) place$", k = "UI_ProjectEchoDDS_EXT_0139" },
    { p = "^([%a ]+) %(the (.+) place%)$", k = "UI_ProjectEchoDDS_EXT_0140" },
    { p = "^([%a ]+) %(the (.+)%)$", k = "UI_ProjectEchoDDS_EXT_0141" },
    { p = "^(.+) of the (.+) says (.+) was taken by the (.+) and is being held at (.+)%.$", k = "UI_ProjectEchoDDS_EXT_0142" },
    { p = "^(.+) of the (.+) needs (.+) %- (.+)%. Try (.+)%.$", k = "UI_ProjectEchoDDS_EXT_0143" },
    { p = "^(.+), called (.+), (.+)%. The (.+) want him gone%. Last seen near (.+)%.$", k = "UI_ProjectEchoDDS_EXT_0144" },
    { p = "^A voice on the emergency band %- (.+) %- says they're trapped at (.+) with family%. It sounds real%. It always sounds real%.$", k = "UI_ProjectEchoDDS_EXT_0145" },
    { p = "^(.+) of the (.+) needs a sealed letter carried to (.+) of the (.+) at (.+)%. Don't open it%.$", k = "UI_ProjectEchoDDS_EXT_0146" },
    { p = "^A (.+) patrol went silent near (.+) two days ago%. Find out why%.$", k = "UI_ProjectEchoDDS_EXT_0147" },
    { p = "^The dead have packed into (.+) and every noise draws more%. The (.+) can't farm the fields around it until it's cleared%.$", k = "UI_ProjectEchoDDS_EXT_0148" },
    { p = "^(.+) of the (.+) will trade for (.+)%. Leave it at the drop and they'll pay up%.$", k = "UI_ProjectEchoDDS_EXT_0149" },
    { p = "^The (.+) and the (.+) both claim (.+)%. Somebody's going to get shot%. Both sides agreed to let an outsider decide%. That's you%.$", k = "UI_ProjectEchoDDS_EXT_0150" },
    { p = "^(.+) swears there's an untouched evidence locker in (.+)%. Two doors, one key somewhere inside, and a whole lot of noise if you do it wrong%.$", k = "UI_ProjectEchoDDS_EXT_0151" },
    { p = "^(.+) has been following letters left by (.+) since July%. Four drop points%. Days apart%. (.+) can't walk anymore%. You can%.$", k = "UI_ProjectEchoDDS_EXT_0152" },
    { p = "^(.+) wants to build something that'll outlast this winter: (.+)%. It'll take days and a lot of hauling%.$", k = "UI_ProjectEchoDDS_EXT_0153" },
    { p = "^Every dead one you drop today is one fewer at somebody's fence%.$", k = "UI_ProjectEchoDDS_EXT_0154" },
    { p = "^(.+) is short on (.+)%. Leave (.+) at the drop%.$", k = "UI_ProjectEchoDDS_EXT_0155" },
    { p = "^Walk the perimeter%. Two points%. Eyes open%.$", k = "UI_ProjectEchoDDS_EXT_0156" },
    { p = "^Keep the (.+) honest%. Put (%d+) of them down today%.$", k = "UI_ProjectEchoDDS_EXT_0157" },
    { p = "^(.+) has been on the emergency channel for a week%. The group is holding out at (.+)%. Go and see them%.$", k = "UI_ProjectEchoDDS_EXT_0158" },
    { p = "^([%a ]+) now see you as: (.+)$", k = "UI_ProjectEchoDDS_EXT_0159" },
    { p = "^(.+) %(optional%) %(optional%)$", k = "UI_ProjectEchoDDS_EXT_0160" },
}
local memo = {}
local function ru(key)
    local v = memo[key]
    if v then return v end
    if not getText then return nil end
    local ok, r = pcall(getText, key)
    if not ok or type(r) ~= "string" or r == key then return nil end
    memo[key] = r
    return r
end
local inTranslation = 0
local translatedCache = {}
local cacheSize = 0
local function remember(key, value)
    if inTranslation == 0 then
        if cacheSize >= 1200 then translatedCache = {}; cacheSize = 0 end
        if translatedCache[key] == nil then cacheSize = cacheSize + 1 end
        translatedCache[key] = value
    end
    return value
end
R.translate = function(input)
    if type(input) ~= "string" then return previousTranslate(input) end
    if inTranslation > 6 then return previousTranslate(input) end
    local memo = translatedCache[input]
    if memo ~= nil then return memo end
    local key = ex[input]
    if key then local v=ru(key); if v then return remember(input, v) end end
    local old = previousTranslate(input)
    if old ~= input then return remember(input, old) end
    for _, item in ipairs(rules) do
        local parts = { string.match(input, item.p) }
        if parts[1] ~= nil then
            local fmt = ru(item.k)
            if fmt then
                for n=1,#parts do
                    local value = parts[n] or ""
                    inTranslation = inTranslation + 1
                    local t = R.translate(value)
                    inTranslation = inTranslation - 1
                    fmt = string.gsub(fmt, "@@"..n.."@@", function() return tostring(t) end)
                end
                return remember(input, fmt)
            end
        end
    end
    return remember(input, input)
end
return R
