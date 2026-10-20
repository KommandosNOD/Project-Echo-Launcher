PROJECT ECHO — Money Exchange for PhunMart 2, v1.0.0
=========================================================
PZ Build 42.21 | Mod ID: ProjectEchoMoneyExchange | Requires: phunmart2

INSTALLATION
1. Unpack ProjectEchoMoneyExchange into:
   C:\Users\KommandosNOD\Zomboid\mods\ProjectEchoMoneyExchange
2. Also distribute THE SAME FOLDER to every player, e.g. through PROJECT ECHO launcher.
3. Back up servertest.ini and append exactly one ID at the END of Mods=:
   ;ProjectEchoMoneyExchange
4. WorkshopItems= does NOT need an extra Workshop ID for this local mod.
5. Keep phunmart2 in Mods= and its Workshop ID 3689006725 in WorkshopItems=.
6. Fully restart the dedicated server and game clients.

IN GAME
- Put vanilla banknotes (Base.Money) into the PLAYER INVENTORY (main bag or nested backpack).
- Right-click banknotes in the inventory: choose 1 / 10 / 50 / all.
- If your inventory UI hides the context menu, press F8 to exchange all carried notes.
- 1 banknote = 5 PhunMart change cents ($0.05). 142 banknotes = $7.10.
- Wallet change balance cap applies. Default PhunMart change cap is $99.99.
- All will exchange as many as fit the wallet, maximum 250 bills per action.

MULTIPLAYER SAFETY
- The client sends only one of four values: 1, 10, 50, "all".
- The server validates the command, reads actual server-side Base.Money inventory,
  respects PhunMart's wallet cap and spends the physical notes first.
- Server credits exactly five cents per note actually removed.
- The PhunMart native wallet-sync command refreshes the player's shop balance.
- Requests cannot specify a username, item ID, target player or credit value.
- A per-player lock and one-second cooldown mitigate rapid repeat messages.
- The server does not mutate original PhunMart files, world objects, or item scripts.
- The item must be CARRIED: nearby ground loot is not exchanged automatically.

NOTES / LIMITS
- Needs a manual multiplayer test on your exact B42.21 setup. Static checks only.
- No automatic conversion on pickup. Does not convert Nickel/Dime/Quarter items.
- PhunMart's original wallet cap applies: full wallets refuse fixed exchanges;
  an "all" request exchanges only what fits.
- Maximum 250 bills per transaction limits packet bursts. Press F8 again for more.
- When another mod changes PhunMart API or inventory mechanics, server log shows
  a [PE Money Exchange] diagnostic. Money should not be auto-granted.
- First test with 1 or 10 notes on a test character, confirm inventory and balance.

SOURCE REFERENCE
- PhunMart 2: https://github.com/PhunZoider/PhunMart
- wallet API: shared/PhunMart/wallet.lua -> adjustByPool, getBalance, getCap.
