PROJECT ECHO - INVENTORY ZOOM LOCK v0.1.0 TEST
================================================

Naznachenie:
  Blokirovka zooma kamery pri prokrutke inventarya ViewpointUI.
  Podderzhka ViewpointUI 0.13.1, ProjectViewpointQOL i (esli ustanovlen) CameraPlus.
  Quick Loot Responsive mozhet byt' vklyuchen: ego fayly ne zamenyayutsya.

INSTALL:
1. Zakroyte igru i server.
2. Skopiruyte papku ProjectEchoInventoryZoomLock v:
   C:\Users\KommandosNOD\Zomboid\mods\
   (ostal'nye klienty: %USERPROFILE%\Zomboid\mods\)
3. V Mods= dobav'te ;ProjectEchoInventoryZoomLock POSLE ViewpointUI i ProjectViewpointQOL.
4. Dobav'te etu papku klientam cherez PROJECT ECHO Builder.
5. WorkshopItems= i Map= NE menyayte.

TEST:
- Otkroyte polnyy inventar' ViewpointUI, prokrutite spisok: kamera ne dolzhna zoomit'sya.
- Zakroyte inventar': kamera snova zoomit'sya kolesom.
- Quick Loot: prokrutka predmetov dolzhna rabotat' kak ran'she.
- Kamera pri otkrytom vanilla inventare (kursornyy hover): ne dolzhna zoomit'sya.
- Prover'te pervoye/tretye litso i CTRL+koleso esli ispol'zuete.
- console.txt: [PE-InventoryZoomLock] active / LOCKED / UNLOCKED

ROLLBACK:
Udalite ;ProjectEchoInventoryZoomLock iz Mods=, zakroyte igru i udal'te papku.
Originialy ViewpointUI, ProjectViewpointQOL i CameraPlus ne menyayutsya.

POZHAlUYSTA, PROCHTITE:
Etot mod tol'ko dlya KLIENTOV (Lua). Bez Java, bez perenosa predmetov,
bez servernykh ogranicheniy, bez sokhraneniya nastroek.
Fakticheskaya rabota v igre eshche ne proverena. TEST na svoey sborke.
