PROJECT ECHO - Cursor HUD Compat v0.1.0 TEST
==========================================
ПРИЧИНА:
ViewpointUI Legacy.lua классифицирует TM42_MiniTracker как окно другого мода.
При открытой панели TM42 он удерживает свободный курсор, даже если инвентарь закрыт.
Из-за этого Viewpoint не вращает камеру мышью.

ИСПРАВЛЕНИЕ:
Добавляем TM42_MiniTracker в перечень пассивных элементов HUD ViewpointUI.
Остальные окна, карта, чат, инвентарь, мини-лут сохраняют исходное управление.
Никаких Java-патчей, изменений сохранений, серверной логики и модов Workshop.
Файл Legacy.lua взят из установленного ViewpointUI версии 0.13.2.

УСТАНОВКА:
1) Закрыть клиент и сервер Project Zomboid.
2) Папку ProjectEchoCursorHUDCompat положить в
   C:\Users\KommandosNOD\Zomboid\mods\
   Другие клиенты: %USERPROFILE%\Zomboid\mods\
3) Добавить ;ProjectEchoCursorHUDCompat в строку Mods= ПОСЛЕ ViewpointUI.
   WorkshopItems= и Map= не изменять. При использовании нашего лаунчера
   разместить мод через PROJECT ECHO Builder как локальный клиентский мод.
4) При следующем запуске в console.txt ожидается:
   [PROJECT ECHO][CursorHUDCompat v0.1.0] ViewpointUI 0.13.2 Legacy override active

ТЕСТ:
A) 3D Viewpoint -> открыть и закрыть инвентарь -> мышь вращает камеру.
B) TM42 mini tracker остается видимым, но сам по себе не освобождает курсор.
C) Quick Loot прокручивается, а камера не зумится при наведении на инвентарь.
D) Карта, диалоги, чат, административные окна по-прежнему получают курсор.
E) Повторить несколько раз: инвентарь -> миссия -> мини-лут -> инвентарь.

ВАЖНО:
Если для ручного перемещения TM42 mini tracker нужен указатель,
освободить курсор штатной клавишей Viewpoint (средняя кнопка мыши)
и потом вернуть режим mouse-look.
ДАННЫЙ FIX ДЛЯ ViewpointUI v0.13.2; при обновлении ViewpointUI нужна ревизия патча,
так как он переопределяет один его клиентский Lua-файл.

ОТКАТ:
1) Удалить ;ProjectEchoCursorHUDCompat из Mods=.
2) Удалить папку ProjectEchoCursorHUDCompat из Zomboid\mods.
Другие моды, Workshop и сохранения не изменялись.

Диагноз основан на console.txt:
[ViewpointUI] WARN another mod's window is open ... TM42_MiniTracker
Пока изменение не проверено в игре, поэтому версия TEST.
