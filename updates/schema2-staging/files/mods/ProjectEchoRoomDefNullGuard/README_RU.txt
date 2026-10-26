PROJECT ECHO — RoomDef Null Guard v0.3.0 TEST
Для Project Zomboid B42.21 и ZombieBuddy 2.3.4

ОБНАРУЖЕННАЯ ПРИЧИНА НЕРАБОТАЮЩЕГО ПАТЧА v0.2.0
Crash Capture 2026-10-26 зафиксировал:
  [ZB] Scanned 5 classes in package com.projectecho.roomdefguard
  [ZB] no patches in package com.projectecho.roomdefguard

Версия v0.2.0 использовала API новой ветки ZombieBuddy
  me.zed_0xff.zombie_buddy.annotations.Patch
но установленный у игрока ZombieBuddy 2.3.4 использует
  me.zed_0xff.zombie_buddy.Patch

В v0.1.0 использовался @Patch.Field, которого также нет в API v2.3.4.

ЧТО ИЗМЕНЕНО
1. Правильная аннотация Java-патча под установленный ZombieBuddy 2.3.4.
2. Перед IsoRoom.hasLightSwitches() read-only проверка поля def через Java reflection.
   Если def отсутствует, метод пропускается, результат false; падения нет.
3. Встроены ещё две узкие защиты: выход из IsoRoom.hasLightSwitches()
   и IsoLightSwitch.chunkLoaded(). Они обрабатывают ТОЛЬКО известный NPE
   из IsoRoom.hasLightSwitches, а не все исключения подряд.
4. Логирование срабатывания защиты, чтобы можно было проверить результат в игре.
5. Оригинальный JAR игры, Minidoracat, Workshop, карты и сохранение не изменяются.

УСТАНОВКА
1. Полностью закрой Project Zomboid.
2. Удали старую папку ProjectEchoRoomDefNullGuard.
3. Из архива извлеки ТОЛЬКО папку ProjectEchoRoomDefNullGuard в:
   C:\Users\KommandosNOD\Zomboid\mods\
4. Mod ID прежний: ProjectEchoRoomDefNullGuard.
5. Minidoracat оставь установленным.
6. Протестируй сначала на одном клиенте и резервной копии мира.

ЧТО ОБЯЗАТЕЛЬНО ПРОВЕРИТЬ В console.txt
   [ZB] Found patch class: com.projectecho.roomdefguard.Patch_RoomHasLightSwitches
   [ZB] Found patch class: com.projectecho.roomdefguard.Patch_LightSwitchChunkLoaded

И после загрузки класса:
   [ZB] patching zombie.iso.areas.IsoRoom.hasLightSwitches
   [ZB] patching zombie.iso.objects.IsoLightSwitch.chunkLoaded

Если видишь [ZB] no patches in package, защита НЕ активирована.
Строка Java module loaded сама по себе ничего не гарантирует.

Когда возникает проблема с RoomDef, ищи:
   [PE-RoomDefNullGuard v0.3.0] PREVENTED: ...

Это тестовая версия, пока не проверенная в самой игре. Даже при успешном
предотвращении NPE сообщения duplicate RoomDef.metaID могут остаться.

ОТКАТ: удалить папку и убрать Mod ID из Mods=.

SOURCE_NOT_FOR_BUILDER — исходники и локальный SmokeTest. В игру не копировать.
