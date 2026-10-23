-- PROJECT ECHO / Project A-Life RU v0.1.0 TEST
-- Polishes translation only, using the existing RU Easy display dictionary.
-- English original / gameplay modules and NPC behavior are never modified.
local POLISH = {
    ["Please.. I just want to get out of here alive"] = "Пожалуйста… Я просто хочу выбраться отсюда живым.",
    ["Don't shoot. The noise could bring more of those things"] = "Не стреляй! На шум сбегутся остальные твари.",
    ["Please, lower it. I don't know what else to say"] = "Убери пушку, прошу. Я даже не знаю, что ещё сказать.",
    ["Point it down. I have enough to worry about"] = "Опусти ствол. Мне и без тебя проблем хватает.",
    ["You're aimed in. Are you sure you want to do this?"] = "Ты уже целишься… Уверен, что хочешь этого?",
    ["Think about what you're doing before you make it worse"] = "Подумай, что делаешь, пока не стало хуже.",
    ["Easy. You're getting into more trouble than you need"] = "Спокойно. Ты сейчас наживёшь себе лишних проблем.",
    ["You want a fight? Is that it?"] = "Драки захотел? Так, что ли?",
    ["Don't point that at me. I'm listening"] = "Не тычь в меня стволом. Я слушаю.",
    ["Look, we can talk without this"] = "Слушай, давай просто поговорим. Без оружия.",
    ["Easy. You don't have to do that"] = "Тише, тише. Не надо этого.",
    ["I've got enough to be afraid of"] = "Мне и так есть чего бояться.",
    ["Please, put it down a little"] = "Ну опусти ты оружие, прошу.",
    ["What do you need? Just say it"] = "Что тебе надо? Скажи прямо.",
    ["I can't think with that pointed at me"] = "Не могу собраться с мыслями, когда на меня направлен ствол.",
    ["You're making this worse for both of us"] = "Ты только усугубляешь ситуацию. Для нас обоих.",
    ["Careful. A mistake here can't be taken back"] = "Осторожнее. Здесь ошибку уже не исправишь.",
    ["I'm here. I heard you. Lower it"] = "Я здесь, я тебя слышу. Опусти оружие.",
    ["Let's not find out how this ends"] = "Давай не будем проверять, чем всё это закончится.",
    ["You can ask me without doing that"] = "Ты можешь просто спросить. Без угроз.",
    ["I'm trying to stay calm. Help me out"] = "Я пытаюсь не паниковать. Не усложняй.",
    ["Someone's down! Don't forget them!"] = "У нас раненый! Не бросайте его!",
    ["We can't just leave somebody there!"] = "Мы не можем просто оставить его там!",
    ["Help if you can, but be careful!"] = "Кто может — помогите! Только осторожно!",
    ["Don't get yourselves hurt trying to help!"] = "Не подставляйтесь, пока вытаскиваете его!",
    ["We need to do something for them!"] = "Надо что-то сделать, ему нужна помощь!",
    ["Can anybody get to them safely?"] = "Кто-нибудь сможет безопасно до него добраться?",
    ["Keep watching! Someone needs help!"] = "Смотрите по сторонам! Человеку нужна помощь!",
    ["This can't be happening again"] = "Только не снова… Этого не может быть.",
    ["Be careful going near! Please!"] = "Не подходите вслепую! Осторожнее!",
    ["We have to think. Don't rush it"] = "Надо подумать. Не лезьте напролом.",
    ["One of us is down. Don't lose your head"] = "Один из наших выбыл. Не теряйте голову!",
    ["They need us paying attention now!"] = "Сейчас надо быть начеку, ему нужна помощь!",
    ["Oh, God. Tell me we can help"] = "Господи… Скажите, что мы можем помочь.",
    ["He's down! Somebody help him!"] = "Он упал! Кто-нибудь, помогите ему!",
    ["Somebody ought to remember what happened here"] = "Кто-то должен запомнить, что здесь произошло.",
    ["Thank Christ, someone else. Stay with us"] = "Слава богу, ты здесь! Не уходи!",
    ["Hey! You hurt? Talk to me!"] = "Эй! Ты ранен? Ответь мне!",
    ["Hold on! Don't give up on me!"] = "Держись! Только не сдавайся!",
    ["I saw that! Are you all right?"] = "Я всё видел! Ты цел?",
    ["Stay with us! We need you!"] = "Не отключайся! Ты нам нужен!",
    ["Can you hear me? Say something!"] = "Ты меня слышишь? Скажи хоть слово!",
    ["Easy! Don't make it worse!"] = "Спокойно! Не делай себе хуже!",
    ["Don't try to be tough about it!"] = "Не геройствуй сейчас!",
    ["You took a hit! Be careful!"] = "Тебя задело! Осторожнее!",
    ["Are you hurt? Don't hide it!"] = "Ты ранен? Не скрывай!",
    ["Keep talking so I know you're with us!"] = "Говори со мной! Я должен знать, что ты в сознании!",
    ["Ah, shit! We need you alive!"] = "Чёрт! Нам надо, чтобы ты выжил!",
    ["You're hit! Be careful, don't make it worse!"] = "Тебя ранили! Осторожно, не усугубляй!",
    ["Oh God, someone's hurt! Help if you can!"] = "Господи, здесь раненый! Кто может — помогите!",
    ["Get some help if you need it!"] = "Нужна помощь — зови!",
    ["Shit, someone's hurt, they're HURT!"] = "Чёрт! Тут раненый! Серьёзно раненый!",
    ["Aw, hell, someone's hurt! Can we help?"] = "Чёрт побери, тут раненый! Чем помочь?",
    ["Goddamn it, someone's hurt! Can anybody help?"] = "Да чтоб тебя! Человек ранен! Кто-нибудь может помочь?",
    ["Trouble. Keep your eyes open"] = "Похоже, будут неприятности. Смотрите в оба.",
    ["That doesn't look friendly"] = "Что-то они не похожи на дружелюбных.",
    ["Be ready. This could get ugly"] = "Будьте готовы. Сейчас может начаться мясо.",
    ["Don't give them an easy chance"] = "Не давайте им лёгкой мишени.",
    ["We need to be careful here"] = "Здесь надо действовать осторожно.",
    ["Watch yourself. This isn't a welcome"] = "Берегись. Нас здесь явно не ждали.",
    ["I was hoping not to do this today"] = "Надеялся, сегодня до такого не дойдёт.",
    ["Don't turn your back on trouble"] = "Не поворачивайтесь к ним спиной.",
    ["Stay awake. Something's wrong"] = "Не зевайте. Здесь что-то не так.",
    ["Keep calm. Don't make this easier for them"] = "Спокойно. Не облегчайте им задачу.",
    ["Looks like trouble found us"] = "Кажется, неприятности сами нас нашли.",
    ["Trouble! Stay ready, all of you!"] = "Опасность! Всем быть наготове!",
    ["Watch yourself. This doesn't look good"] = "Берегись. Дело пахнет плохо.",
    ["Watch it! Something's wrong!"] = "Осторожно! Что-то здесь нечисто!",
    ["Somebody hostile! Don't get caught out!"] = "Враждебный! Не подставляйтесь!",
    ["Somebody out there. Could be trouble"] = "Там кто-то есть. Возможно, недруги.",
    ["Anybody able to help? We've got trouble here"] = "Кто-нибудь может помочь? У нас неприятности!",
    ["Somebody out there. Steady now, don't start anything"] = "Там кто-то есть. Спокойно, не начинайте первыми.",
    ["I don't like this. Stay ready for trouble"] = "Мне это не нравится. Держите оружие наготове.",
    ["Trouble. Stay careful and let me think"] = "Неприятности… Осторожнее. Дайте сообразить.",
    ["Keep your eyes open. Something's wrong here"] = "Смотрите по сторонам. Здесь что-то не так.",
    ["Don't assume they're friendly. Stay careful"] = "Не считайте их друзьями раньше времени. Осторожнее.",
    ["People we don't know. Be careful"] = "Незнакомцы. Будьте осторожны.",
    ["Somebody hostile. Stay careful!"] = "Враждебный человек! Держитесь настороже!",
    ["Keep your eyes open! Don't get caught out!"] = "Смотрите в оба! Не попадитесь!",
    ["Trouble! Don't let yourself get hurt!"] = "Опасность! Берегите себя!",
    ["Someone hostile. Keep watching"] = "Там кто-то враждебный. Не спускайте глаз.",
    ["Keep watching! Don't relax!"] = "Не теряйте бдительности!",
    ["Hostiles. Don't get caught off guard"] = "Враги! Не дайте застать себя врасплох!",
    ["This looks bad. What do we do?"] = "Дело плохо. Что будем делать?",
    ["Trouble. Hold, hold. Let me think"] = "Чёрт… Стойте, дайте подумать.",
}
local applied = false
local function apply()
    local R = ProjectALifeRU
    if not R or type(R.Map) ~= "table" then return end
    if applied then return end
    applied = true
    local n = 0
    for en, ru in pairs(POLISH) do
        R.Map[en] = ru
        n = n + 1
    end
    R.cache, R.cacheCount = {}, 0
    if type(R.buildFragments) == "function" then
        local ok, err = pcall(R.buildFragments)
        if not ok then print("[ProjectEchoALifeRU] fragment refresh warning: " .. tostring(err)) end
    end
    print("[ProjectEchoALifeRU] dialogue polish active: " .. tostring(n) .. " phrases")
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(apply) end
if Events and Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function() apply() end) end
