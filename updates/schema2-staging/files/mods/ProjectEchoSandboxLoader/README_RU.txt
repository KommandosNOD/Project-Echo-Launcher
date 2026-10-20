PROJECT ECHO - SANDBOX LOADER 1.0.0 (Build 42.21 MP)

1. Останови сервер и сохрани резервную копию Zomboid/Server и мира.
2. Распакуй папку ProjectEchoSandboxLoader в C:\Users\KommandosNOD\Zomboid\mods\.
3. В Zomboid/Server/servertest.ini, в конец Mods= добавь ;ProjectEchoSandboxLoader.
4. Убери из Mods= старый PEForceMultiHit, чтобы два мода не боролись.
5. Запусти сервер как обычно (старый start.bat не изменяется).
6. Ищи в логе [ProjectEchoSandboxLoader] и MultiHitZombies=true.

ЭТАЛОН: ProjectEchoSandboxLoader/42/SandboxPreset.lua
В ZIP уже лежит твой полный конфиг от 17.10.2026.
Чтобы заменить эталон, останови сервер, подмени файл и запусти заново.

Мод не переписывает servertest_SandboxVars.lua на диске. Он применяет
эталон к игровым SandboxVars и зарегистрированным SandboxOptions при старте,
проверяет изменения каждые 10 игровых минут и перед сохранением сервера.

Ограничения: не действует задним числом на генерацию уже созданного мира;
не меняет servertest.ini. Работу на твоём сервере необходимо проверить.
