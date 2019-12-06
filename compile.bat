compilerbinaries\rgbgfx tiles.inc tiles.png

compilerbinaries\rgbasm -obuildfiles\main.obj main.asm
compilerbinaries\rgblink -mbuilt\GameboyThing.map -nbuilt\GameboyThing.sym -obuilt\GameboyThing.gb buildfiles\main.obj
compilerbinaries\rgbfix -p0 -v built\GameboyThing.gb
pause