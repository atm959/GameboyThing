;****************************************************************************************************************************************************
;*	Includes
;****************************************************************************************************************************************************
	
;****************************************************************************************************************************************************
;*	user data [constants]
;****************************************************************************************************************************************************


;****************************************************************************************************************************************************
;*	equates
;****************************************************************************************************************************************************

downButton equ $80
upButton equ $40
leftButton equ $20
rightButton equ $10
startButton equ $08
selectButton equ $04
bButton equ $02
aButton equ $01

didInit equ $C000
playerX equ $C001
playerY equ $C002
key1 equ $C003
key2 equ $C004
t equ $C005
upHeld equ $C006
downHeld equ $C007
leftHeld equ $C008
rightHeld equ $C009
temp equ $C00A

;****************************************************************************************************************************************************
;*	macros
;****************************************************************************************************************************************************

;****************************************************************************************************************************************************
;*	cartridge header
;****************************************************************************************************************************************************

	SECTION	"Org $00",ROM0[$00]
RST_00:
	jp	$100

	SECTION	"Org $08",ROM0[$08]
RST_08:	
	jp	$100

	SECTION	"Org $10",ROM0[$10]
RST_10:
	jp	$100

	SECTION	"Org $18",ROM0[$18]
RST_18:
	jp	$100

	SECTION	"Org $20",ROM0[$20]
RST_20:
	jp	$100

	SECTION	"Org $28",ROM0[$28]
RST_28:
	jp	$100

	SECTION	"Org $30",ROM0[$30]
RST_30:
	jp	$100

	SECTION	"Org $38",ROM0[$38]
RST_38:
	jp	$100

	SECTION	"V-Blank IRQ Vector",ROM0[$40]
VBL_VECT:
	jp VBlank
	
	SECTION	"LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

	SECTION	"Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti
	
	SECTION	"Start",ROM0[$100]
	nop
	jp	Start

	; $0104-$0133 [Nintendo logo - do _not_ modify the logo data here or the GB will not run the program]
	DB	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
	DB	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	DB	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

	; $0134-$013E [Game title - up to 11 upper case ASCII characters, pad with $00]
	DB	"TILEPLACING"
		;0123456789A

	; $013F-$0142 [Product code - 4 ASCII characters, assigned by Nintendo, just leave blank]
	DB	"    "
		;0123

	; $0143 [Color GameBoy compatibility code]
	DB	$00	; $00 - DMG 
			; $80 - DMG/GBC
			; $C0 - GBC Only cartridge

	; $0144 [High-nibble of license code - normally $00 if $014B != $33]
	DB	$00

	; $0145 [Low-nibble of license code - normally $00 if $014B != $33]
	DB	$00

	; $0146 [GameBoy/Super GameBoy indicator]
	DB	$00	; $00 - GameBoy

	; $0147 [Cartridge type - all Color GameBoy cartridges are at least $19]
	DB	$00	; $00 - ROM Only

	; $0148 [ROM size]
	DB	$00	; $00 - 256Kbit = 32Kbyte = 2 banks

	; $0149 [RAM size]
	DB	$00	; $00 - None

	; $014A [Destination code]
	DB	$01	; $01 - All others
			; $00 - Japan

	; $014B [Licensee code - this _must_ be $33]
	DB	$33	; $33 - Check $0144/$0145 for Licensee code.

	; $014C [Mask ROM version - handled by RGBFIX]
	DB	$00

	; $014D [Complement check - handled by RGBFIX]
	DB	$00

	; $014E-$014F [Cartridge checksum - handled by RGBFIX]
	DW	$00


;****************************************************************************************************************************************************
;*	Program Start
;****************************************************************************************************************************************************

	SECTION "Program Start",ROM0[$0150]
Start:
	ld	sp,$FFFE			;set the stack pointer to $FFFE

	call clearWRAM			;Clear the Work RAM

	ei
	ld a, $01
	ld [$FFFF], a

Loop:
	halt
	jp Loop

;***************************************************************
;* Subroutines
;***************************************************************

	SECTION "Support Routines",ROM0

clearWRAM:
	ld hl, $C000
	ld bc, $1FFF
.clearWRAMLoop:
	ld a, $00
	ld [hl], a
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .clearWRAMLoop
	ret

clearOAM:
	ld hl, $FE00
	ld bc, 40*4
.clearOAMLoop:
	ld a, $00
	ld [hl], a
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .clearOAMLoop
	ret

clearMap:
	ld hl, $9800
	ld de, $9C00
	ld bc, 32*32
.clearMapLoop:
	ld a, $00
	ld [hl], a
	ld [de], a
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .clearMapLoop
	ret

loadTiles:
.loadTilesLoop:
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loadTilesLoop
	ret
	
loadMap:
	ld h, $00		;Tile-placing "modulo"
	ld l, $01		;"Write tiles" flag
	ld bc, level1	;Pointer to tile data
	ld de, 0
.loadMapLoop:
	ld a, h			;Load H into A
	cp 20			;Compare with 21
	call z, .setPlaceTilesZero
	cp 32			;Compare with 32
	call z, .setPlaceTilesOne
	ld a, l
	cp $01
	jr nz, .dontPlaceTile
	ld a, h			;Store HL into WRAM
	ld [temp], a	;Store HL into WRAM
	ld a, l			;Store HL into WRAM
	ld [temp+1], a	;Store HL into WRAM
	ld hl, $9840	;Load the tilemap base address into HL
	ld a, [bc]
	add hl, de
	ld [hl], a
	ld a, [temp]
	ld h, a
	ld a, [temp+1]
	ld l, a
	inc bc
.dontPlaceTile:
	inc de
	inc h
	ld a, d
	cp $02
	jr nz, .loadMapLoop
	ld a, e
	cp $00
	jr nz, .loadMapLoop
	ret
.setPlaceTilesZero:
	ld l, $00
	ret
.setPlaceTilesOne:
	ld h, $00
	ld l, $01
	ret
	
keyInput:
	ld a, $20
	ld [$FF00], a
	ld a, [$FF00]
	ld a, [$FF00]
	;A is DULR
	ld [key1], a
	
	ld a, $10
	ld [$FF00], a
	ld a, [$FF00]
	ld a, [$FF00]
	ld a, [$FF00]
	ld a, [$FF00]
	ld a, [$FF00]
	ld a, [$FF00]
	;A is TEBA
	ld [key2], a
	
	ld a, $30
	ld [$FF00], a
	ret

VBlank:
	ld a, [didInit]
	cp a, $01
	jr z, .skipInit

.waitRealVBlank:
	ld	a,[$FF44]			;get current scanline
	cp	$91					;Are we in v-blank yet?
	jr	nz,	.waitRealVBlank	;if A != 0x91 then loop

	ld	a, $00				;Load 0x00 to A
	ld	[$FF40],a			;turn off LCD

	call clearOAM			;Clear OAM
	call clearMap			;Clear BG

	ld hl, tile		;Load a pointer to the tiles into HL
	ld de, $8000				;Load the destination in VRAM to DE
	ld bc, tileEnd-tile;Load the number of bytes to load into BC
	call loadTiles				;Load the tiles

	ld a, %11100100			;Load 0xE4 to A
	ld [$FF47], a			;Load A into 0xFF47 (DMG BG Shades)
	ld [$FF48], a			;Load A into 0xFF48 (DMG Sprite Shades)
	
	call loadMap

	ld	a, $93
	ld	[$FF40],a			;Turn on the LCD, BG, etc

	ld a, $01
	ld [didInit], a

.skipInit:

	call keyInput
	
	ld a, [key1]
	and a, $01
	jr nz, .rightNotPressed
	ld a, [rightHeld]
	cp $01
	jr z, .rightIsHeld
	
	ld a, $01
	ld [rightHeld], a
	
	ld a, [playerX]
	cp a, $13
	jr z, .playerXIs13
	inc a
	ld [playerX], a
.playerXIs13:
	jr .rightIsHeld
.rightNotPressed:
	ld a, $00
	ld [rightHeld], a

.rightIsHeld:

	ld a, [key1]
	and a, $02
	jr nz, .leftNotPressed
	ld a, [leftHeld]
	cp $01
	jr z, .leftIsHeld
	
	ld a, $01
	ld [leftHeld], a
	
	ld a, [playerX]
	cp a, $00
	jr z, .playerXIsZero
	dec a
	ld [playerX], a
.playerXIsZero:
	jr .leftIsHeld
.leftNotPressed:
	ld a, $00
	ld [leftHeld], a

.leftIsHeld:

	ld a, [key1]
	and a, $04
	jr nz, .upNotPressed
	ld a, [upHeld]
	cp $01
	jr z, .upIsHeld
	
	ld a, $01
	ld [upHeld], a
	
	ld a, [playerY]
	cp a, $02
	jr z, .playerYIsTwo
	dec a
	ld [playerY], a
.playerYIsTwo:
	jr .upIsHeld
.upNotPressed:
	ld a, $00
	ld [upHeld], a

.upIsHeld

	ld a, [key1]
	and a, $08
	jr nz, .downNotPressed
	ld a, [downHeld]
	cp $01
	jr z, .downIsHeld
	
	ld a, $01
	ld [downHeld], a
	
	ld a, [playerY]
	cp a, $11
	jr z, .playerYIs11
	inc a
	ld [playerY], a
.playerYIs11:
	jr .downIsHeld
.downNotPressed:
	ld a, $00
	ld [downHeld], a
	
.downIsHeld:

	ld a, [t]
	inc a
	ld [t], a

	ld a, [playerX]
	sla a
	sla a
	sla a
	add a, $08
	ld [$FE01], a
	
	ld a, [playerY]
	sla a
	sla a
	sla a
	add a, $10
	ld [$FE00], a

	ld a, $04
	ld [$FE02], a

	reti
	
levelList:
	dw level1

level1:
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $00, $01, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $01, $01, $00, $01
	db $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01
	db $01, $01, $01, $00, $01, $01, $00, $01, $00, $00, $00, $00, $01, $00, $01, $01, $00, $01, $01, $01
	db $01, $00, $01, $00, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $00, $01, $00, $01
	db $01, $00, $01, $01, $00, $01, $00, $01, $00, $00, $00, $00, $01, $00, $01, $00, $01, $01, $00, $01
	db $01, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	db $01, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $01
	db $01, $00, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $01
	db $01, $00, $00, $00, $00, $01, $01, $00, $00, $01, $01, $00, $00, $01, $01, $00, $00, $00, $00, $01
	db $01, $00, $00, $00, $01, $01, $00, $00, $01, $01, $01, $01, $00, $00, $01, $01, $00, $00, $00, $01
	db $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01
	db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    
tile:
incbin "tiles.inc"
tileEnd: