PROJECT ECHO — ADMIN COMMANDS v0.1.2 TEST (B42.21 MP)
====================================================

CHANGES
- /pe help and all replies appear INSIDE GAME CHAT only, not above character.
- /pe invisible [on|off|status] controls your OWN invisibility to zombies.
- /pe invisible without arguments toggles current invisibility.
- Server checks username / optionally SteamID64 before EVERY command.
- Original vanilla chat handler remains untouched; previous keyboard-focus fix kept.
- No modifications to game binaries, Workshop files, or saved world.

КОМАНДЫ В ЧАТЕ
/pe help                 — список доступных команд прямо в чате
/pe players              — список игроков
/pe where                — координаты
/pe invisible            — включить/выключить невидимость для зомби
/pe invisible on         — включить невидимость
/pe invisible off        — выключить невидимость
/pe invisible status     — проверить состояние
/pe heal [USERNAME]      — восстановить здоровье
/pe tp USERNAME          — телепорт к игроку
/pe bring USERNAME       — переместить игрока к себе

УСТАНОВКА
1. Закрыть игру, остановить сервер.
2. Распаковать ZIP, запустить INSTALL.cmd.
3. Проверить, что в servertest.ini / Mods= указан ProjectEchoAdminCommands (не дублировать).
4. Установить одинаковую клиентскую версию у владельца сервера.
   Если мод распространяется через Builder — синхронизировать локальный мод.
5. Запустить сервер и клиент, сначала проверить /pe help, WASD, ESC и обычный чат.
6. Затем попробовать /pe invisible status -> on -> off.

КОНФИГУРАЦИЯ
42/media/lua/server/ProjectEchoAdminCommands/PEAC_ServerConfig.lua
- AllowInvisible = true (на новых установках).
- Старые конфиги сохраняются при установке; если AllowInvisible не указан,
  команда по умолчанию разрешена указанному владельцу.
- Не публикуйте приватный серверный конфиг. Рекомендуется заполнить SteamID64
  и установить RequireSteamID = true на остановленном сервере.

ОТКАТ / ВАЖНО
- При установке старый мод сохраняется в папке
  %USERPROFILE%\Zomboid\ProjectEchoPatchBackups (вне папки mods).
- Не испытывать телепорты внутри RV Interior или над пустыми этажами.
- Невидимость относится к обнаружению зомби; другие игроки могут видеть персонажа.
- Никакая команда не выдаёт роль Admin, GodMode или NoClip.
- Не забудьте /pe invisible off перед обычной игрой.
- В игре B42.21 реальные игровые проверки не выполнялись: TEST.
- Если управление зависнет, перезапустите клиент и вернитесь к резервной копии.

ЛОГИ: console.txt и server-console.txt, префикс [PE-AdminCmd].
