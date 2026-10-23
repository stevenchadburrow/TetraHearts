
; ./rgbds/rgbasm -o MyTetris.o MyTetris.asm
; ./rgbds/rgblink -o MyTetris.gb MyTetris.o
; ./rgbds/rgbfix -v -p $FF MyTetris.gb
; ./PICboy.o MyTetris.gb 000

DEF oam_trans_byte		EQU $D0
DEF oam_trans_addr		EQU $D000 ; 160 bytes, 40 sprites, start of page 

DEF shadow_trans_byte	EQU $D1
DEF shadow_trans_addr	EQU $D100 ; shadow of oam_trans, start of next page

DEF field_array_byte	EQU $D2
DEF field_array_addr	EQU $D200 ; 240 bytes, 12x20 grid, start of page

DEF field_line			EQU $D300
DEF field_wait			EQU $D301

DEF rand_value			EQU $D302

DEF joy_current			EQU $D303
DEF joy_previous		EQU $D304
DEF joy_delay			EQU $D305

DEF piece_type_curr 	EQU $D307
DEF piece_type_next		EQU $D306
DEF piece_color_curr	EQU $D308
DEF piece_color_next	EQU $D309
DEF piece_posx 			EQU $D30A
DEF piece_posy 			EQU $D30B
DEF piece_rot 			EQU $D30C
DEF piece_prevx			EQU $D30D
DEF piece_prevy			EQU $D30E
DEF piece_prevr			EQU $D30F
DEF piece_delay 		EQU $D310
DEF piece_frames		EQU $D311
DEF piece_loc0			EQU $D312
DEF piece_loc1			EQU $D313
DEF piece_loc2			EQU $D314
DEF piece_loc3			EQU $D315
DEF piece_drop			EQU $D316
DEF piece_new			EQU $D317
DEF piece_wait			EQU $D318

DEF bag_type			EQU $D319 ; 7 bytes, cannot cross page boundary
DEF bag_color			EQU $D320 ; 7 bytes, cannot cross page boundary
DEF bag_pos				EQU $D327
DEF bag_swap			EQU $D328
DEF bag_counter			EQU $D329

DEF score_lines			EQU $D32A ; 2 bytes
DEF score_trash			EQU $D32C
DEF score_millis		EQU $D32D
DEF score_seconds		EQU $D32E
DEF score_minutes		EQU $D32F
DEF score_digits		EQU $D330 ; 8 bytes
DEF score_time			EQU $D338 ; 8 bytes
DEF score_row			EQU $D340
DEF score_pieces		EQU $D341
DEF score_modten		EQU $D342
DEF score_mode			EQU $D343
DEF score_gameover		EQU $D344

DEF bubble_number		EQU $D345
DEF bubble_active		EQU $D346
DEF bubble_timer		EQU $D347
DEF bubble_counter		EQU $D348
DEF bubble_anim			EQU $D349
DEF bubble_dir			EQU $D34A

DEF menu_status			EQU $D34B
DEF menu_character		EQU $D34C
DEF menu_location		EQU $D34D
DEF menu_challenge		EQU $D34E
DEF menu_pos			EQU $D34F
DEF menu_timer			EQU $D350
DEF menu_palette		EQU $D351

DEF wait_counter		EQU $D352

DEF reset_flag			EQU $D353

DEF char_affection		EQU $D354 ; 4 bytes
DEF char_bonus			EQU $D358 ; 4 bytes

DEF jump_address		EQU $D35C ; 4 bytes

DEF scene_status		EQU $D360
DEF scene_direction		EQU $D361
DEF scene_char_addr		EQU $D362 ; 2 bytes
DEF scene_text_addr		EQU $D364 ; 2 bytes7
DEF scene_ret_addr		EQU $D366 ; 2 bytes
DEF scene_affection		EQU $D368

DEF window_pos			EQU $D369
DEF window_dir			EQU $D36A

DEF inc_vram_start		EQU $D36B
DEF inc_wram_address	EQU $D36C ; 2 bytes
DEF inc_vram_address	EQU $D36E ; 2 bytes

DEF audio_pos			EQU $D370
DEF audio_timer			EQU $D371
DEF audio_addr			EQU $D372 ; 2 bytes
DEF audio_track			EQU $D374
DEF audio_volume		EQU $D375


; WRAM from $C000-$CFFF and $D400-$DFFF
; is shadow VRAM, and is transferred incrementally each frame


SECTION "VBlankInterrupt", ROM0[$40]
	JP VBlankInterrupt

SECTION "Header", ROM0[$0100]
	JP MainEntry

SECTION "Title", ROM0[$0134]
	DB "TETRA HEARTS" ; title
	DB $00,$00,$00,$00 ; manufacturing
	DB $00,$00,$00,$00 ; GBC, licensee, and SGB
	DB $00,$00,$00 ; MBC, ROM, and RAM
	DB $00,$00,$00 ; destination and licensee

SECTION "Main", ROM0[$0150]

; ****************
; ****************
; MAIN CODE
; ****************
; ****************

MainEntry:
	; turn off interrupts
	DI
	LD A, $00
	LD [$FFFF], A

	; turn off audio
	LD A, $00
	LD [$FF26], A

	; wait for v-blank to turn off LCD
MainVBlankLoop:
	LD A, [$FF44]
	CP A, $90 ; line 144
	JR C, MainVBlankLoop

	; turn off LCD
	LD A, $00
	LD [$FF40], A

	; add OAM DMA routine to HRAM
	LD HL, OamDmaHramCode
	LD BC, $FF80
MainTransferLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, C
	CP $8A
	JR NZ, MainTransferLoop

	; add font tile data
	LD BC, FontData
	LD HL, $9000
MainFontLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $94
	JR C, MainFontLoop

	; clear rest of background tiles
	LD HL, $9400
MainTilesLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $98
	JR C, MainTilesLoop

	; clear background tiles
	LD HL, $9800
MainBackLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $9C
	JR C, MainBackLoop

	; set window tiles
	LD HL, $9C00
MainWinLoop:
	LD [HL], $3F ; wall
	INC HL
	LD A, H
	CP A, $A0
	JR C, MainWinLoop

	; clear out character affection
	; (or grab from cart RAM?)
	LD A, $00
	LD [char_affection+0], A
	LD [char_affection+1], A
	LD [char_affection+2], A
	LD [char_affection+3], A

	; set palettes for background/obj0/obj1
	LD A, $E4
	LD [$FF47], A
	LD [$FF48], A
	LD A, $D2
	LD [$FF49], A
	
	; set scroll background values
	LD A, $00
	LD [$FF42], A
	LD A, $00
	LD [$FF43], A

	; set scroll window values
	LD A, $00
	LD [$FF4A], A
	LD A, $00
	LD [$FF4B], A

	; long delay before starting the LCD
	LD BC, $FFFF
MainWaitLoop:
	DEC BC
	LD A, B
	CP A, $00
	JR NZ, MainWaitLoop
	LD A, C
	CP A, $00
	JR NZ, MainWaitLoop

	; turn on LCD
	LD A, $E1 ; $E3 to enable objects (sprites)
	LD [$FF40], A

	; turn on V-Blank interrupt
	LD A, $01
	LD [$FFFF], A
	EI
	NOP
	NOP
	NOP
	NOP

	; ready joy input
	LD A, $FF
	LD [joy_current], A
	LD A, $00
	LD [joy_previous], A
	LD A, $00
	LD [joy_delay], A

	; clear joypad select
	LD A, $30
	LD [$FF00], A

	; set menu values
	LD A, $00
	LD [menu_status], A
	LD [menu_character], A
	LD [menu_location], A
	LD [menu_challenge], A
	LD [menu_pos], A
	LD [menu_timer], A
	LD [menu_palette], A

	; set scene values
	LD A, $00
	LD [scene_direction], A
	LD A, $FF
	LD [scene_status], A

	LD A, $C3 ; jump instruction
	LD [jump_address+0], A
	LD A, $00
	LD [jump_address+1], A
	LD [jump_address+2], A
	LD [jump_address+3], A

	; disable wram-to-vram transfer
	LD A, $E0
	LD [inc_wram_address+0], A
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, $A0
	LD [inc_vram_address+0], A
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, $80
	LD [inc_vram_start], A

	; set window values
	LD A, $00
	LD [window_pos], A
	LD A, $00
	LD [window_dir], A

	; enable audio
	LD A, $80
	LD [$FF26], A
	LD A, $77
	LD [$FF24], A
	LD A, $FF
	LD [$FF25], A

	; start music
	LD A, $00
	LD [audio_track], A
	LD A, $00 ; no volume yet
	LD [audio_volume], A
	CALL AudioMusicLoad

	; starting with reset flag on
	LD A, $01
	LD [reset_flag], A

	; start at menu
	JP MenuEntry


; ****************
; ****************
; V-BLANK CODE
; ****************
; ****************

; same v-blank interrupt for everyone
VBlankInterrupt:
	; check for window direction
	LD A, [window_dir]
	CP A, $01
	JR Z, VBlankWindowUp
	CP A, $02
	JR Z, VBlankWindowDown

	; enable sprites
	LD A, $E3 ; enable objects (sprites)
	LD [$FF40], A
	JR VBlankTransfer

VBlankWindowUp:
	LD A, [window_pos]
	CP A, $00
	JR Z, VBlankWindowStop
	SUB A, $02 ; speed
	LD [window_pos], A
	LD [$FF4A], A
	LD A, $E1 ; disable objects (sprites)
	LD [$FF40], A
	JR VBlankTransfer

VBlankWindowDown:
	LD A, [window_pos]
	CP A, $90
	JR Z, VBlankWindowStop
	ADD A, $02 ; speed
	LD [window_pos], A
	LD [$FF4A], A
	LD A, $E1 ; disable objects (sprites)
	LD [$FF40], A
	JR VBlankTransfer

VBlankWindowStop:
	LD A, $00
	LD [window_dir], A

VBlankTransfer:
	; check for incremental move wram-to-vram
	LD A, [inc_vram_address+0]
	CP A, $80 ; beginning of transfer
	JR C, VBlankTransferAlign
	CP A, $9C ; end of transfer addresses
	JR NC, VBlankScene
	
	; get addresses
	LD A, [inc_wram_address+0]
	LD H, A
	LD A, [inc_wram_address+1]
	LD L, A
	LD A, [inc_vram_address+0]
	LD B, A
	LD A, [inc_vram_address+1]
	LD C, A
	
	; transfer 64 bytes
	LD E, $40
VBlankTransferLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, VBlankTransferLoop
	
	; check for $9000-$93FF non-transfer area
	LD A, B
	CP A, $90
	JR C, VBlankTransferAddress
	CP A, $94
	JR NC, VBlankTransferAddress
	
	; skip non-transfer area
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, $94
	LD [inc_vram_address+0], A
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, $D4
	LD [inc_wram_address+0], A
	JR VBlankAudio

VBlankTransferAddress:
	; set addresses
	LD A, C
	LD [inc_vram_address+1], A
	LD A, B
	LD [inc_vram_address+0], A
	LD A, L
	LD [inc_wram_address+1], A
	LD A, H
	LD [inc_wram_address+0], A
	JR VBlankAudio

VBlankTransferAlign:
	; start at correct address
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, [inc_vram_start]
	LD [inc_vram_address+0], A
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, [inc_vram_start]
	ADD A, $40
	LD [inc_wram_address+0], A
	JR VBlankAudio

VBlankScene:
	; check which mode we are in
	LD A, [scene_status]
	CP A, $FF
	JR Z, VBlankMenu
	
	CALL SceneInterruptFunction
	JR VBlankAudio

VBlankMenu:
	LD A, [menu_status]
	CP A, $FF
	JR Z, VBlankGame

	CALL MenuInterruptFunction
	JR VBlankAudio

VBlankGame:
	CALL GameInterruptFunction
	JR VBlankAudio
	
VBlankAudio:
	; joypad capture function is assumed to already have been called here!

	; check for select button
	LD A, [joy_current]
	BIT $02, A ; select
	CALL Z, VBlankAudioCheckSelect

	; check for start button
	LD A, [joy_current]
	BIT $03, A ; start
	CALL Z, VBlankAudioCheckStart

	; make sure to play the music each time
	CALL AudioMusicPlay

	RETI

VBlankAudioCheckSelect:
	LD A, [joy_previous]
	BIT $02, A
	JR NZ, VBlankAudioShiftSelect
	RET

VBlankAudioShiftSelect:
	; select new track and reload from beginning
	CALL AudioMusicTrack
	CALL AudioMusicLoad
	RET

VBlankAudioCheckStart:
	LD A, [joy_previous]
	BIT $03, A
	JR NZ, VBlankAudioShiftStart
	RET

VBlankAudioShiftStart:
	; shift volume but do not reload
	CALL AudioMusicVolume
	RET
	

; ****************
; ****************
; JOYPAD CODE
; ****************
; ****************

; capture joypad input
JoypadCaptureFunction:
	; set previous values
	LD A, [joy_current]
	LD [joy_previous], A

	; set joy select and settle
	LD A, $10
	LD [$FF00], A
	NOP
	NOP

	; capture buttons
	LD A, [$FF00]
	AND A, $0F
	LD C, A
	
	; set joy select and settle
	LD A, $20
	LD [$FF00], A
	NOP
	NOP

	; capture dpad and combine
	LD A, [$FF00]
	SLA A
	SLA A
	SLA A
	SLA A
	OR A, C
	LD [joy_current], A

JoypadCaptureExit:
	; return
	RET


; ****************
; ****************
; GAME CODE
; ****************
; ****************

GameEntry:
	; set mode to game
	LD A, $FF
	LD [menu_status], A
	LD [scene_status], A

	; turn off interrupts
	DI
	LD A, $00
	LD [$FFFF], A

	; turn off sprites
	LD A, $E1
	LD [$FF40], A

	; set window to move up
	LD A, $01
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $90
	CALL Z, AudioEffectSlideUp

	; clear background tiles
	LD HL, $D800
GameBackLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $DC
	JR C, GameBackLoop

	; clear oam transfer data
	LD HL, oam_trans_addr
GameSpriteLoop1:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, oam_trans_byte+1
	JR C, GameSpriteLoop1

	; clear shadow transfer data
	LD HL, shadow_trans_addr
GameSpriteLoop2:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, shadow_trans_byte+1
	JR C, GameSpriteLoop2

	; wait for v-blank to turn off LCD
GameVBlankLoop:
	LD A, [$FF44]
	CP A, $90 ; line 144
	JR C, GameVBlankLoop

	; oam dma transfer
	CALL $FF80

	; set palettes for background/obj0/obj1
	LD A, $E4
	LD [$FF47], A
	LD [$FF48], A
	LD A, $D2
	LD [$FF49], A
	
	; set scroll background values
	LD A, $00
	LD [$FF42], A
	LD A, $00
	LD [$FF43], A

; ********
; GAME SETUP

	; set field array
	LD HL, FieldArrayData
	LD BC, field_array_addr
GameFieldLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, B
	CP A, field_array_byte+1
	JR C, GameFieldLoop
	LD A, C
	CP A, $00
	JR C, GameFieldLoop

	; preset scores
	LD A, $00
	LD [score_lines+0], A
	LD [score_lines+1], A
	LD [score_trash], A
	LD [score_row], A
	LD [score_pieces], A

	; find correct challenge
	LD A, [menu_challenge]
	LD [score_mode], A
	CP A, $FF ; classic mode
	JP Z, GameFieldClassic
	AND A, $03
	CP A, $00 ; pieces
	JP Z, GameFieldPieces
	CP A, $01 ; lines
	JP Z, GameFieldLines
	CP A, $02 ; trash
	JP Z, GameFieldTrash
	CP A, $03 ; rows
	JP Z, GameFieldRows

	; never ending lines
GameFieldClassic:
	LD A, $00
	LD [score_lines+0], A
	LD [score_lines+1], A
	LD [score_pieces], A
	JP GameFieldFinish

	; decrementing pieces
GameFieldPieces:
	; find affection score
	LD HL, char_affection
	LD A, [menu_character]
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HL]
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	
	; find settings
	LD HL, ChallengeSettingsPiecesData
	LD C, A
	ADD HL, BC
	LD A, [HL]

	; set pieces
	LD [score_pieces], A
	JP GameFieldFinish

	; decrementing lines
GameFieldLines:
	; find affection score
	LD HL, char_affection
	LD A, [menu_character]
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HL]
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	
	; find settings
	LD HL, ChallengeSettingsLinesData
	LD C, A
	ADD HL, BC
	LD A, [HL]
	
	; set lines
	LD [score_lines+0], A
	LD A, $00
	LD [score_lines+1], A
	JP GameFieldFinish

	; trash, fill field with some garbage
GameFieldTrash:
	; find affection score
	LD HL, char_affection
	LD A, [menu_character]
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HL]
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	
	; find settings
	LD HL, ChallengeSettingsTrashData
	LD C, A
	ADD HL, BC
	LD A, [HL]

	; start of loop
	LD E, A
	LD [score_trash], A
GameFieldTrashLoop:
	CALL RandomFunction
	LD A, [rand_value]
	CP A, $90 ; 12 * 12 / 16, highest location of trash
	JR C, GameFieldTrashLoop
	CP A, $C0 ; second-to-bottom-row in field
	JR NC, GameFieldTrashLoop
	LD B, $00
	LD C, A
	LD HL, field_array_addr
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR NZ, GameFieldTrashLoop
	LD A, $80
	LD [HL], A
	DEC E
	JR NZ, GameFieldTrashLoop
	JP GameFieldFinish
	
	; rows, fill field with all garbage	
GameFieldRows:
	; find affection score
	LD HL, char_affection
	LD A, [menu_character]
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HL]
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	
	; find settings
	LD HL, ChallengeSettingsRowsData
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HL]
	LD [score_row], A

	; calculate starting location, (17-A) * 12 / 16
	LD C, A
	LD A, $11
	SUB A, C
	LD C, A
	ADD A, C
	ADD A, C
	SLA A
	SLA A
	LD D, A

	; start of loops
	LD HL, field_array_addr
	LD B, $00
	LD C, D
	ADD HL, BC
GameFieldRowsLoop:
	LD E, $3F ; wall
	LD A, [HL]
	CP A, $00
	JR NZ, GameFieldRowsInsert
	LD E, $80 ; trash
GameFieldRowsInsert:
	LD A, E
	LD [HLI], A
	LD A, L
	CP A, $CC
	JR C, GameFieldRowsLoop

	; then go back and put small holes into it
	LD HL, field_array_addr
	LD B, $00
	LD C, D
	INC C
	ADD HL, BC
	LD B, $00
GameFieldHolesLoop1:
	CALL RandomFunction
	LD A, [rand_value]
	CP A, $09
	JR NC, GameFieldHolesLoop1
	PUSH HL
	LD C, A
	ADD HL, BC
	LD A, $00
	LD [HL], A
	POP HL
GameFieldHolesLoop2:
	CALL RandomFunction
	LD A, [rand_value]
	CP A, $09
	JR NC, GameFieldHolesLoop2
	PUSH HL
	LD C, A
	ADD HL, BC
	LD A, $00
	LD [HL], A
	POP HL
	LD C, $0C
	ADD HL, BC
	LD A, L
	CP A, $CC
	JR C, GameFieldHolesLoop1
	CALL FieldLinesFunction ; change values
	JP GameFieldFinish

GameFieldFinish:

	; choose person tile data
	LD A, [menu_character]
	AND A, $03
	CP A, $00
	JR NZ, GameCharacterChoice1
	LD HL, CharacterData1
	LD A, [char_affection+0]
	JR GameCharacterLoad
GameCharacterChoice1:
	CP A, $01
	JR NZ, GameCharacterChoice2
	LD HL, CharacterData2
	LD A, [char_affection+1]
	JR GameCharacterLoad
GameCharacterChoice2:
	CP A, $02
	JR NZ, GameCharacterChoice3
	LD HL, CharacterData3
	LD A, [char_affection+2]
	JR GameCharacterLoad
GameCharacterChoice3:
	LD HL, CharacterData4
	LD A, [char_affection+3]
	JR GameCharacterLoad

GameCharacterLoad:
	; find specific expression
	AND A, $C0
	CP A, $C0
	JR NZ, GameCharacterExpression
	LD A, $80 ; only 3 expressions per character
GameCharacterExpression:
	SRL A
	SRL A
	SRL A
	SRL A
	LD B, A
	LD C, $00
	ADD HL, BC
	LD B, H
	LD C, L

	; add person tile data
	LD HL, $D400
GameCharacterLoop1:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $D8
	JR C, GameCharacterLoop1

	; draw person on side
	LD HL, $D94C
	LD BC, $0018
	LD A, $40
GameCharacterLoop2:
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	ADD HL, BC
	CP A, $80
	JR C, GameCharacterLoop2

	; add block tile data
	LD HL, PieceBlockData
	LD A, [menu_location]
	AND A, $03
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD A, $00
	RLA
	LD B, A
	ADD HL, BC
	LD B, H
	LD C, L
	LD HL, $C800
GameBlockLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, L
	CP A, $80
	JR C, GameBlockLoop

	; add bubble tile data
	LD BC, BubbleSpriteData
	LD HL, $C000
GameBubbleLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $C1
	JR C, GameBubbleLoop

	; find challenge text
	LD BC, ChallengeClassicData
	LD A, [menu_challenge]
	CP A, $FF
	JR Z, GameChallengePrint
	AND A, $03
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD B, $00
	LD C, A
	LD HL, ChallengeTextData
	ADD HL, BC
	LD B, H
	LD C, L
	
GameChallengePrint:
	; draw challenge text
	LD HL, $D82C
	LD D, $04 ; 4 lines
GameChallengeOuterLoop:
	LD E, $08 ; 8 characters per line
GameChallengeInnerLoop:
	LD A, [BC]
	INC BC
	SUB A, $20
	LD [HLI], A
	DEC E
	JR NZ, GameChallengeInnerLoop
	PUSH BC
	LD BC, $0018
	ADD HL, BC
	POP BC
	DEC D
	JR NZ, GameChallengeOuterLoop

	; set redraw location
	LD A, $14
	LD [field_line], A
	LD A, $00
	LD [field_wait], A

	; shuffles pieces
	LD A, $08
	LD [bag_pos], A
	CALL BagGrabFunction
	
	; grab current piece
	CALL BagGrabFunction

	; shift into place
	LD A, [piece_type_next]
	LD [piece_type_curr], A
	LD A, [piece_color_next]
	LD [piece_color_curr], A

	; grab next piece
	CALL BagGrabFunction

	; piece position initialization
	LD A, $28
	LD [piece_posx], A
	LD HL, PieceStartHeight
	LD A, [piece_type_curr]
	LD C, A
	LD B, $00
	ADD HL, BC
	LD A, [HL]
	LD [piece_posy], A
	LD A, $00
	LD [piece_rot], A
	LD A, $1E
	LD [piece_delay], A
	LD [piece_frames], A
	LD A, $00
	LD [piece_drop], A
	LD [piece_new], A
	LD A, $3C
	LD [piece_wait], A

	; change sprites for piece
	CALL PieceDrawFunction

	; start at zero
	LD A, $00
	LD [score_millis], A
	LD [score_seconds], A
	LD [score_minutes], A
	LD [score_modten], A
	LD [score_digits+0], A
	LD [score_digits+1], A
	LD [score_digits+2], A
	LD [score_digits+3], A
	LD [score_digits+4], A
	LD [score_digits+5], A
	LD [score_digits+6], A
	LD [score_digits+7], A
	LD [score_time+0], A
	LD [score_time+1], A
	LD [score_time+2], A
	LD [score_time+3], A
	LD [score_time+4], A
	LD [score_time+5], A
	LD [score_time+6], A
	LD [score_time+7], A
	LD [score_gameover], A
	
	; clear bubble info
	LD A, $00
	LD [bubble_number], A
	LD [bubble_active], A
	LD [bubble_timer], A
	LD [bubble_anim], A
	LD A, $01
	LD [bubble_dir], A

; ********

	; clear transfer addresses to initialize
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, $00
	LD [inc_wram_address+0], A
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, $00
	LD [inc_vram_address+0], A
	LD A, $80
	LD [inc_vram_start], A

	; turn on V-Blank interrupt
	LD A, $01
	LD [$FFFF], A
	EI
	NOP
	NOP
	NOP
	NOP

GameWaitLoop:
	; wait for wram-to-vram transfer to complete
	HALT
	NOP
	LD A, [inc_vram_address+0]
	CP A, $9C
	JR C, GameWaitLoop
	
	; set window to move down
	LD A, $02
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $00
	CALL Z, AudioEffectSlideDown

GameHaltLoop:
	; check for jump address
	LD A, [jump_address+3]
	CP A, $00
	JR Z, GameHaltContinue
	LD A, $00 ; clear jump flag
	LD [jump_address+3], A
	JP jump_address
	
GameHaltContinue:
	; wait for v-blank interrupt then loop
	HALT
	NOP
	JR GameHaltLoop

; called from v-blank interrupt
GameInterruptFunction:
	; redraw field one line at a time (inside of v-blank)
	CALL FieldRedrawFunction

	; compute current time
	CALL ScoreTimeFunction

	; animate sprites
	CALL BubbleTimeFunction

	; dma transfer oam data
	CALL $FF80

	; check wait counter
	LD A, [piece_wait]
	CP A, $00
	JR NZ, GameInterruptSkip

	; copy shadow oam data
	LD HL, shadow_trans_addr
	LD BC, oam_trans_addr
GameInterruptShadow:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, C
	CP A, $00
	JR NZ, GameInterruptShadow

	; capture joypad input
	LD A, [piece_drop]
	CP A, $00
	CALL Z, JoypadCaptureFunction

	; make lines disappear
	CALL FieldLinesFunction

	; check wait counter
	LD A, [field_wait]
	CP A, $00
	JR NZ, GameInterruptCheck

	; descend piece by one block
	CALL PieceDescendFunction

	; move piece according to joypad
	Call PieceMoveFunction

	; place piece on field
	CALL PiecePlaceFunction

	; calculate score numbers
	CALL ScoreCalculateFunction

	; check for overflow in field
	LD A, [score_row]
	CP A, $11 ; top row
	JR C, GameInterruptCheck
	LD A, $02 ; bad ending
	LD [score_gameover], A

GameInterruptCheck:
	; check for gameover
	LD A, [score_gameover]
	CP A, $00
	JR Z, GameInterruptExit

	; set window to move up
	LD A, $01
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $90
	CALL Z, AudioEffectSlideUp

	; go to scene just after game
	LD A, $01 ; after game scene
	LD [scene_direction], A
	LD A, $00
	LD [scene_status], A
	LD A, $00
	LD [menu_pos], A
	LD A, $FF
	LD [menu_status], A
	
	; load jump address
	LD BC, SceneEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET


GameInterruptExit:
	; return
	RET

GameInterruptSkip:
	; decrement wait counter then return
	DEC A
	LD [piece_wait], A
	RET


; redraws a line of the field (inside of v-blank)
FieldRedrawFunction:
	; increment field line
	LD A, [field_line]
	INC A
	LD [field_line], A
	CP A, $14
	JR C, FieldRedrawContinue
	LD A, $00
	LD [field_line], A

	; zero out wait counter
	LD A, $00 
	LD [field_wait], A

FieldRedrawContinue:
	; set up HL for field array
	SLA A
	SLA A
	LD L, A
	ADD A, L
	ADD A, L
	LD L, A
	LD H, field_array_byte

	; set up BC for tile map
	LD A, [field_line]
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD A, $00
	RLA	
	LD B, A
	LD A, C
	SLA A
	LD C, A
	LD A, B
	RLA
	ADD A, $98
	LD B, A
	
	; draw tile maps
	LD E, $0C
FieldRedrawLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, FieldRedrawLoop

	; draw score time
	LD HL, score_time
	LD BC, $980C
FieldRedrawTime:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, C
	CP A, $14
	JR C, FieldRedrawTime

	; draw score digits
	LD HL, score_digits
	LD BC, $98AC
FieldRedrawScore:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, C
	CP A, $B4
	JR C, FieldRedrawScore

	; return
	RET


; calculate the time taken so far
ScoreTimeFunction:
	; increment time
	LD A, [score_millis]
	INC A
	LD [score_millis], A
	CP A, $3C ; 60 millis
	JR C, ScoreTimeExit
	LD A, $00
	LD [score_millis], A
	LD A, [score_seconds]
	INC A
	LD [score_seconds], A
	CP A, $3C ; 60 seconds
	JR C, ScoreTimeExit
	LD A, $00
	LD [score_seconds], A
	LD A, [score_minutes]
	INC A
	LD [score_minutes], A

	; if not in classic mode, speed up every minute
	LD A, [menu_challenge]
	CP A, $FF
	JR Z, ScoreTimeExit
	LD A, [piece_delay]
	SUB A, $02
	CP A, $04 ; max speed
	JR NC, ScoreTimeExit
	LD [piece_delay], A

ScoreTimeExit:
	RET


; animate sprites
BubbleTimeFunction:
	; speech bubbles
	LD A, [bubble_active]
	CP A, $00
	JP Z, BubbleTimeInactive

	; decrement timer
	LD A, [bubble_timer]
	DEC A
	LD [bubble_timer], A
	JP Z, BubbleTimeInactive

	; animate bubble
	LD A, [bubble_dir]
	LD C, A
	LD A, [bubble_anim]
	ADD A, C
	LD [bubble_anim], A
	CP A, $10
	JR C, BubbleTimeBubbles1
	LD A, $FF
	LD [bubble_dir], A
	LD A, $0F
	LD [bubble_anim], A
BubbleTimeBubbles1:
	CP A, $00
	JR NZ, BubbleTimeBubbles2
	LD A, $01
	LD [bubble_dir], A	
BubbleTimeBubbles2:

	; sprite 8, 9, 10, and 11
	LD A, [bubble_anim]
	SRL A
	SRL A
	ADD A, $5C ; posy
	LD [oam_trans_addr+$20], A
	LD [shadow_trans_addr+$20], A
	LD [oam_trans_addr+$28], A
	LD [shadow_trans_addr+$28], A
	ADD A, $08
	LD [oam_trans_addr+$24], A
	LD [shadow_trans_addr+$24], A
	LD [oam_trans_addr+$2C], A
	LD [shadow_trans_addr+$2C], A
	LD A, $94 ; posx
	LD [oam_trans_addr+$21], A
	LD [shadow_trans_addr+$21], A
	LD [oam_trans_addr+$25], A
	LD [shadow_trans_addr+$25], A
	ADD A, $08
	LD [oam_trans_addr+$29], A
	LD [shadow_trans_addr+$29], A
	LD [oam_trans_addr+$2D], A
	LD [shadow_trans_addr+$2D], A
	LD A, [bubble_number]
	SLA A
	SLA A
	LD [oam_trans_addr+$22], A
	LD [shadow_trans_addr+$22], A
	INC A
	LD [oam_trans_addr+$26], A
	LD [shadow_trans_addr+$26], A
	INC A
	LD [oam_trans_addr+$2A], A
	LD [shadow_trans_addr+$2A], A
	INC A
	LD [oam_trans_addr+$2E], A
	LD [shadow_trans_addr+$2E], A
	LD A, $10
	LD [oam_trans_addr+$23], A
	LD [shadow_trans_addr+$23], A
	LD [oam_trans_addr+$27], A
	LD [shadow_trans_addr+$27], A
	LD [oam_trans_addr+$2B], A
	LD [shadow_trans_addr+$2B], A
	LD [oam_trans_addr+$2F], A
	LD [shadow_trans_addr+$2F], A
	
	; return
	RET	

BubbleTimeInactive:
	; make bubble inactive
	LD A, $00
	LD [bubble_active], A

	; make bubble sprites disappear
	LD A, $00
	LD [oam_trans_addr+$20], A
	LD [shadow_trans_addr+$20], A
	LD [oam_trans_addr+$24], A
	LD [shadow_trans_addr+$24], A
	LD [oam_trans_addr+$28], A
	LD [shadow_trans_addr+$28], A
	LD [oam_trans_addr+$2C], A
	LD [shadow_trans_addr+$2C], A

	; return
	RET


; check for lines to disappear
FieldLinesFunction:
	; only if piece was dropped
	LD A, [piece_drop]
	CP A, $00
	JP Z, FieldLinesExit
	
	; zero out bubble counter
	LD A, $00
	LD [bubble_counter], A
	
	; start from bottom
	LD H, field_array_byte
	LD L, $C1
	PUSH HL

	; check bottom line
FieldLinesLoop:
	LD B, $00
	LD C, $0A
FieldLinesCheck:
	LD A, [HLI]
	CP A, $00
	JR Z, FieldLinesBlank
	INC B
FieldLinesBlank:
	DEC C
	JR NZ, FieldLinesCheck
	LD A, B
	CP A, $00
	JP Z, FieldLinesNext

	; calculate current row
	LD A, L
	LD C, $00
FieldLinesSearchLoop:
	INC C	
	SUB A, $0C
	JR NC, FieldLinesSearchLoop
	DEC C
	LD A, $11
	SUB A, C
	LD [score_row], A
	LD A, B

	; check for a full line to continue
	CP A, $0A
	JP NZ, FieldLinesNext
	
	; shift all lines down
	PUSH HL
	LD BC, $FFF4
	ADD HL, BC
	POP BC
FieldLinesClear:
	LD A, [HLD]
	LD [BC], A
	DEC BC
	LD A, H
	CP field_array_byte-1
	JR NZ, FieldLinesClear

	CALL AudioEffectApprove

	; check same line again
	POP HL
	LD BC, $000C
	ADD HL, BC
	PUSH HL

	; zero out trash counter
	LD A, $00
	LD [score_trash], A

	LD H, field_array_byte
	LD L, $EF ; very bottom
FieldLinesTrash:
	LD A, [HLD]
	CP A, $80 ; trash
	JR NZ, FieldLinesShift
	PUSH HL
	LD HL, score_trash
	INC [HL]
	POP HL
FieldLinesShift:
	LD A, H
	CP field_array_byte-1
	JR NZ, FieldLinesTrash

	; start redrawing from top
	LD A, $00
	LD [field_line], A
	LD A, $01
	LD [field_wait], A

	; increment lines only in classic mode
	LD A, [score_mode]
	CP A, $FF
	JR Z, FieldLinesIncrement

	; check if score is already at zero
	LD A, [score_lines+1]
	CP A, $00
	JR NZ, FieldLinesDecrement
	LD A, [score_lines+0]
	CP A, $00
	JR NZ, FieldLinesDecrement
	JR FieldLinesFinish

FieldLinesDecrement:
	; decrement lines score
	PUSH HL
	LD A, [score_lines+1]
	LD H, A
	LD A, [score_lines+0]
	LD L, A
	LD B, $FF
	LD C, $FF
	ADD HL, BC
	LD A, H
	LD [score_lines+1], A
	LD A, L
	LD [score_lines+0], A
	POP HL
	JR FieldLinesFinish

FieldLinesIncrement:
	; increment lines score
	LD A, [score_lines+0]
	ADD A, $01
	LD [score_lines+0], A
	LD A, $00
	RLA
	LD C, A
	LD A, [score_lines+1]
	ADD A, C
	LD [score_lines+1], A
FieldLinesFinish:

	; increment bubble counter
	LD A, [bubble_counter]
	INC A
	LD [bubble_counter], A
	
	; in classic mode, speed up every 10 lines
	LD A, [menu_challenge]
	CP A, $FF
	JR NZ, FieldLinesNext
	LD A, [score_modten]
	INC A
	LD [score_modten], A
	CP A, $0A
	JR C, FieldLinesNext
	LD A, $00
	LD [score_modten], A
	LD A, [piece_delay]
	SUB A, $02
	CP A, $04 ; max speed
	JR NC, FieldLinesNext
	LD [piece_delay], A
	
FieldLinesNext:
	; go one line up
	POP HL
	LD BC, $FFF4
	ADD HL, BC
	PUSH HL
	LD A, H
	CP A, field_array_byte-1
	JP NZ, FieldLinesLoop
	POP HL

	; increment bubble if active
	LD A, [bubble_counter]
	CP A, $00
	JR Z, FieldLinesExit
	LD A, $01
	LD [bubble_active], A
	LD A, $C0
	LD [bubble_timer], A
	LD A, [bubble_counter]
	DEC A
	LD [bubble_number], A

FieldLinesExit:
	; return
	RET


; drop piece at designated speed
PieceDescendFunction:
	; check to see if piece dropped last turn
	LD A, [piece_new]
	CP A, $00
	JR Z, PieceDescendContinue

	; reset flag
	LD A, $00
	LD [piece_new], A

	; shift current type and color
	LD A, [piece_type_next]
	LD [piece_type_curr], A
	LD A, [piece_color_next]
	LD [piece_color_curr], A

	; grab next piece
	CALL BagGrabFunction

	; reset position
	LD A, $28
	LD [piece_posx], A
	LD HL, PieceStartHeight
	LD A, [piece_type_curr]
	LD C, A
	LD B, $00
	ADD HL, BC
	LD A, [HL]
	LD [piece_posy], A
	LD A, $00
	LD [piece_rot], A
	LD A, [piece_delay]
	LD [piece_frames], A
	LD A, $0F
	LD [piece_wait], A

	; change sprites for piece
	CALL PieceDrawFunction

PieceDescendContinue:
	; reset flag
	LD A, $00
	LD [piece_drop], A

	; check if descending
	LD A, [piece_frames]
	DEC A
	LD [piece_frames], A
	CP A, $00
	JR NZ, PieceDescendExit
	LD A, $01
	LD [piece_drop], A
	LD A, [piece_delay]
	LD [piece_frames], A
	LD A, [piece_posy]
	ADD $08
	LD [piece_posy], A

PieceDescendExit:
	; return
	RET


; move piece according to joypad
PieceMoveFunction:
	; store previous location
	LD A, [piece_posx]
	LD [piece_prevx], A
	LD A, [piece_posy]
	LD [piece_prevy], A
	LD A, [piece_rot]
	LD [piece_prevr], A

	; only check on drop
	LD A, [piece_drop]
	CP A, $00
	JR Z, PieceMoveContinue
	RET

PieceMoveContinue:
	; check dpad and buttons
	LD A, [joy_current]
	BIT $00, A ; action
	CALL Z, PieceMoveCheckAction

	LD A, [joy_current]
	BIT $01, A ; back
	CALL Z, PieceMoveCheckBack

	LD A, [joy_current]
	BIT $04, A ; right
	CALL Z, PieceMoveCheckRight

	LD A, [joy_current]
	BIT $05, A ; left
	CALL Z, PieceMoveCheckLeft

	LD A, [joy_current]
	BIT $07, A ; down
	CALL Z, PieceMoveCheckDown

	; if nothing pressed, reset delay
	LD A, [joy_current]
	CP A, $FF
	JP NZ, PieceMoveExit
	LD A, $00
	LD [joy_delay], A

PieceMoveExit:
	RET

PieceMoveCheckAction:
	; rotate clockwise
	LD A, [joy_previous]
	BIT $00, A
	JR NZ, PieceMoveShiftAction
	RET

PieceMoveShiftAction:
	LD A, [piece_rot]
	SUB A, $01
	AND A, $03
	LD [piece_rot], A

	CALL AudioEffectSwish

	CALL RandomFunction ; randomize
	RET

PieceMoveCheckBack:
	; rotate counter-clockwise
	LD A, [joy_previous]
	BIT $01, A
	JR NZ, PieceMoveShiftBack
	RET

PieceMoveShiftBack:
	LD A, [piece_rot]
	ADD A, $01
	AND A, $03
	LD [piece_rot], A

	CALL AudioEffectSwish

	CALL RandomFunction ; randomize
	RET

PieceMoveCheckRight:
	LD A, [joy_previous]
	BIT $04, A
	JR NZ, PieceMoveShiftRight
	LD A, [joy_delay]
	AND A, A
	JR Z, PieceMoveShiftRight
	DEC A
	LD [joy_delay], A
	RET

PieceMoveShiftRight:
	LD A, [piece_posx]
	ADD A, $08
	LD [piece_posx], A
	LD A, $08
	LD [joy_delay], A
	CALL RandomFunction ; randomize
	RET

PieceMoveCheckLeft:
	; move to the left
	LD A, [joy_previous]
	BIT $05, A
	JR NZ, PieceMoveShiftLeft
	LD A, [joy_delay]
	AND A, A
	JR Z, PieceMoveShiftLeft
	DEC A
	LD [joy_delay], A
	RET

PieceMoveShiftLeft:
	LD A, [piece_posx]
	SUB A, $08
	LD [piece_posx], A
	LD A, $08
	LD [joy_delay], A
	CALL RandomFunction ; randomize
	RET

PieceMoveCheckDown:
	; move down
	LD A, [joy_delay]
	AND A, A
	JR Z, PieceMoveShiftDown
	DEC A
	LD [joy_delay], A
	RET

PieceMoveShiftDown:
	; short delay and descend immediately
	LD A, $01
	LD [joy_delay], A
	LD A, $01
	LD [piece_frames], A
	RET


; places current piece
PiecePlaceFunction:
	; ready sprites for piece
	CALL PieceDrawFunction

	; calculate location in field array
	LD A, [shadow_trans_addr+$00] ; sprite 0
	CP A, $10
	JR NC, PiecePlaceCheckY0
	LD A, $10
PiecePlaceCheckY0:
	SUB A, $10
	SRL A
	LD C, A
	ADD A, C
	ADD A, C
	LD C, A
	LD A, [shadow_trans_addr+$01]
	SUB A, $08
	SRL A
	SRL A
	SRL A
	ADD A, C
	LD [piece_loc0], A
	
	LD A, [shadow_trans_addr+$04] ; sprite 1
	CP A, $10
	JR NC, PiecePlaceCheckY1
	LD A, $10
PiecePlaceCheckY1:
	SUB A, $10
	SRL A
	LD C, A
	ADD A, C
	ADD A, C
	LD C, A
	LD A, [shadow_trans_addr+$05]
	SUB A, $08
	SRL A
	SRL A
	SRL A
	ADD A, C
	LD [piece_loc1], A

	LD A, [shadow_trans_addr+$08] ; sprite 2
	CP A, $10
	JR NC, PiecePlaceCheckY2
	LD A, $10
PiecePlaceCheckY2:
	SUB A, $10
	SRL A
	LD C, A
	ADD A, C
	ADD A, C
	LD C, A
	LD A, [shadow_trans_addr+$09]
	SUB A, $08
	SRL A
	SRL A
	SRL A
	ADD A, C
	LD [piece_loc2], A

	LD A, [shadow_trans_addr+$0C] ; sprite 3
	CP A, $10
	JR NC, PiecePlaceCheckY3
	LD A, $10
PiecePlaceCheckY3:
	SUB A, $10
	SRL A
	LD C, A
	ADD A, C
	ADD A, C
	LD C, A
	LD A, [shadow_trans_addr+$0D]
	SUB A, $08
	SRL A
	SRL A
	SRL A
	ADD A, C
	LD [piece_loc3], A

	; ready HL for field array
	LD H, field_array_byte

	; check for collision with field
	LD A, [piece_loc0]
	LD L, A
	LD A, [HL]
	CP A, $00
	JR NZ, PiecePlaceCollision

	LD A, [piece_loc1]
	LD L, A
	LD A, [HL]
	CP A, $00
	JR NZ, PiecePlaceCollision

	LD A, [piece_loc2]
	LD L, A
	LD A, [HL]
	CP A, $00
	JR NZ, PiecePlaceCollision

	LD A, [piece_loc3]
	LD L, A
	LD A, [HL]
	CP A, $00
	JR NZ, PiecePlaceCollision

	; return if no collision
	RET

PiecePlaceCollision:
	; check if dropped
	LD A, [piece_drop]
	CP A, $00
	JR NZ, PiecePlaceSolid
	
	; return to previous position and rotation
	LD A, [piece_prevx]
	LD [piece_posx], A
	LD A, [piece_prevy]
	LD [piece_posy], A
	LD A, [piece_prevr]
	LD [piece_rot], A

	; change sprites for piece
	CALL PieceDrawFunction

	; return
	RET

PiecePlaceSolid:
	CALL AudioEffectCrunch

	; increment pieces in classic mode
	LD A, [score_mode]
	CP A, $FF
	JR Z, PiecePlaceIncrement
	
	; decrement piece count
	LD A, [score_pieces]
	DEC A
	LD [score_pieces], A
	JR PiecePlaceFinish

PiecePlaceIncrement:
	; increment piece count
	LD A, [score_pieces]
	INC A
	LD [score_pieces], A

PiecePlaceFinish:
	; fill in field
	LD A, [piece_loc0]
	SUB A, $0C
	LD L, A
	LD A, [piece_color_curr]
	LD [HL], A

	LD A, [piece_loc1]
	SUB A, $0C
	LD L, A
	LD A, [piece_color_curr]
	LD [HL], A

	LD A, [piece_loc2]
	SUB A, $0C
	LD L, A
	LD A, [piece_color_curr]
	LD [HL], A

	LD A, [piece_loc3]
	SUB A, $0C
	LD L, A
	LD A, [piece_color_curr]
	LD [HL], A

	; start redrawing at piece location
	LD A, [piece_posy]
	SUB A, $20
	SRA A
	SRA A
	SRA A
	LD [field_line], A

	; clear piece
	LD A, $A0 ; off-screen
	LD [piece_posy], A
	LD A, [piece_delay]
	LD [piece_frames], A
	LD A, $0F
	LD [piece_wait], A

	; flag piece
	LD A, $01
	LD [piece_new], A

	; change sprites for piece
	CALL PieceDrawFunction

	; return
	RET


; draws the current piece
PieceDrawFunction:
	; shift according to piece type
	LD A, [piece_type_curr]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A

	; shift according to rotation
	LD A, [piece_rot]
	SLA A
	SLA A
	SLA A
	ADD A, C
	LD C, A
	LD B, $00
	RL B

	; add to data address
	LD HL, PiecePosData
	ADD HL, BC
	
	; sprite 0
	LD A, [piece_posx]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$01], A
	LD A, [piece_posy]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$00], A
	LD A, [piece_color_curr]
	LD [shadow_trans_addr+$02], A
	LD A, $00
	LD [shadow_trans_addr+$03], A

	; sprite 1
	LD A, [piece_posx]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$05], A
	LD A, [piece_posy]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$04], A
	LD A, [piece_color_curr]
	LD [shadow_trans_addr+$06], A
	LD A, $00
	LD [shadow_trans_addr+$07], A
	
	; sprite 2
	LD A, [piece_posx]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$09], A
	LD A, [piece_posy]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$08], A
	LD A, [piece_color_curr]
	LD [shadow_trans_addr+$0A], A
	LD A, $00
	LD [shadow_trans_addr+$0B], A

	; sprite 3
	LD A, [piece_posx]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$0D], A
	LD A, [piece_posy]
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$0C], A
	LD A, [piece_color_curr]
	LD [shadow_trans_addr+$0E], A
	LD A, $00
	LD [shadow_trans_addr+$0F], A

	; calculate next piece height
	LD HL, PieceStartHeight
	LD A, [piece_type_next]
	LD C, A
	LD B, $00
	ADD HL, BC
	LD A, [HL]
	ADD A, $40 ; posy
	LD E, A

	; shift according to piece type
	LD A, [piece_type_next]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A

	; add to data address
	LD HL, PiecePosData
	ADD HL, BC

	; sprite 4
	LD A, $78 ; posx
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$11], A
	LD A, E
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$10], A
	LD A, [piece_color_next]
	LD [shadow_trans_addr+$12], A
	LD A, $00
	LD [shadow_trans_addr+$13], A

	; sprite 5
	LD A, $78 ; posx
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$15], A
	LD A, E
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$14], A
	LD A, [piece_color_next]
	LD [shadow_trans_addr+$16], A
	LD A, $00
	LD [shadow_trans_addr+$17], A

	; sprite 6
	LD A, $78 ; posx
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$19], A
	LD A, E
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$18], A
	LD A, [piece_color_next]
	LD [shadow_trans_addr+$1A], A
	LD A, $00
	LD [shadow_trans_addr+$1B], A

	; sprite 7
	LD A, $78 ; posx
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$1D], A
	LD A, E
	ADD A, [HL]
	INC HL
	LD [shadow_trans_addr+$1C], A
	LD A, [piece_color_next]
	LD [shadow_trans_addr+$1E], A
	LD A, $00
	LD [shadow_trans_addr+$1F], A

	; return
	RET


; calculate line score
ScoreCalculateFunction:
	; always calculate time
	CALL ScoreCalculateTime

	; determine what to display
	LD A, [score_mode]
	CP A, $00
	JP Z, ScoreCalculateMode0
	CP A, $01
	JP Z, ScoreCalculateMode1
	CP A, $02
	JP Z, ScoreCalculateMode2
	CP A, $03
	JP Z, ScoreCalculateMode3

	; classic mode
	LD A, $2C; L
	LD [score_digits+0], A

	; preload total score
	LD A, [score_lines+0]
	LD L, A
	LD A, [score_lines+1]
	LD H, A
	
	; calculate digits
	CALL ScoreCalculateHundreds
	LD [score_digits+1], A
	CALL ScoreCalculateTens
	LD [score_digits+2], A
	CALL ScoreCalculateOnes
	LD [score_digits+3], A

	RET

ScoreCalculateExit:
	; return
	RET

; display pieces
ScoreCalculateMode0:
	; label on left
	LD A, $30 ; P
	LD [score_digits+0], A
	
	; preload pieces
	LD A, [score_pieces]
	LD L, A
	LD A, $00
	LD H, A

	; calculate digits
	CALL ScoreCalculateHundreds
	LD [score_digits+1], A
	CALL ScoreCalculateTens
	LD [score_digits+2], A
	CALL ScoreCalculateOnes
	LD [score_digits+3], A

	; check for gameover
	LD A, [score_pieces]
	CP A, $00
	JP NZ, ScoreCalculateExit
	LD A, $01 ; good ending
	LD [score_gameover], A
	JP ScoreCalculateExit

; display lines
ScoreCalculateMode1:
	; label on left
	LD A, $2C; L
	LD [score_digits+0], A

	; preload total score
	LD A, [score_lines+0]
	LD L, A
	LD A, [score_lines+1]
	LD H, A
	
	; calculate digits
	CALL ScoreCalculateHundreds
	LD [score_digits+1], A
	CALL ScoreCalculateTens
	LD [score_digits+2], A
	CALL ScoreCalculateOnes
	LD [score_digits+3], A

	; check for gameover
	LD A, [score_lines+1]
	CP A, $00
	JP NZ, ScoreCalculateExit
	LD A, [score_lines+0]
	CP A, $00
	JP NZ, ScoreCalculateExit
	LD A, $01 ; good ending
	LD [score_gameover], A
	JP ScoreCalculateExit

; display trash
ScoreCalculateMode2:
	; label on left
	LD A, $34 ; T
	LD [score_digits+0], A
	
	; preload trash
	LD A, [score_trash]
	LD L, A
	LD A, $00
	LD H, A

	; calculate digits
	CALL ScoreCalculateHundreds
	LD [score_digits+1], A
	CALL ScoreCalculateTens
	LD [score_digits+2], A
	CALL ScoreCalculateOnes
	LD [score_digits+3], A

	; check for gameover
	LD A, [score_trash]
	CP A, $00
	JP NZ, ScoreCalculateExit
	LD A, $01 ; good ending
	LD [score_gameover], A
	JP ScoreCalculateExit

; display lowest clear line
ScoreCalculateMode3:
	; leave far left digit blank
	LD A, $32 ; R
	LD [score_digits+0], A
	
	; preload row
	LD A, [score_row]
	LD L, A
	LD A, $00
	LD H, A

	; calculate digits
	CALL ScoreCalculateTens
	LD [score_digits+1], A
	CALL ScoreCalculateOnes
	LD [score_digits+2], A

	; check for gameover
	LD A, [score_row]
	CP A, $04 ; lowest row to reach
	JP NC, ScoreCalculateExit
	LD A, $01 ; good ending
	LD [score_gameover], A
	JP ScoreCalculateExit

; calculates time
ScoreCalculateTime:
	; leave left side blank
	LD A, $0D ; dashes
	LD [score_time+0], A
	LD [score_time+6], A

	; leave far left digit blank
	LD A, $1A ; colon
	LD [score_time+3], A
	
	; preload minutes
	LD A, [score_minutes]
	LD L, A
	LD A, $00
	LD H, A

	; calculate digits
	CALL ScoreCalculateTens
	LD [score_time+1], A
	CALL ScoreCalculateOnes
	LD [score_time+2], A

	; preload seconds
	LD A, [score_seconds]
	LD L, A
	LD A, $00
	LD H, A

	; calculate digits
	CALL ScoreCalculateTens
	LD [score_time+4], A
	CALL ScoreCalculateOnes
	LD [score_time+5], A	

	RET

; assumes HL is loaded with value
; output digit in A
ScoreCalculateHundreds:
	; divide by 100
	LD BC, $FF9C 
	LD DE, $0000
ScoreCalculateHundredsLoop:
	LD A, H
	CP A, $00
	JR NZ, ScoreCalculateHundredsInc
	LD A, L
	CP A, $64 ; 100 in hex
	JR NC, ScoreCalculateHundredsInc
	LD A, E
	ADD A, $10
	RET
ScoreCalculateHundredsInc:
	ADD HL, BC
	INC DE
	JR ScoreCalculateHundredsLoop

; assumes HL is loaded with value
; output digit in A
ScoreCalculateTens:
	; divide by 10
	LD BC, $FFF6
	LD DE, $0000
ScoreCalculateTensLoop:
	LD A, L
	CP A, $0A ; 10 in hex
	JR NC, ScoreCalculateTensInc
	LD A, E
	ADD A, $10
	RET
ScoreCalculateTensInc:
	ADD HL, BC
	INC DE
	JR ScoreCalculateTensLoop

; assumes HL is loaded with value
; output digit in A
ScoreCalculateOnes:
	; ones digit
	LD A, L
	ADD A, $10
	RET


; puts in next pieces
BagGrabFunction:
	; grab type
	LD A, [bag_pos]
	LD BC, bag_type
	ADD A, C
	LD C, A
	LD A, [BC]
	LD [piece_type_next], A

	; grab color
	LD A, [bag_pos]
	LD BC, bag_color
	ADD A, C
	LD C, A
	LD A, [BC]
	LD [piece_color_next], A

	; increment position
	LD A, [bag_pos]
	INC A
	LD [bag_pos], A
	CP A, $07
	JP C, BagGrabExit

	; start at beginning
	LD A, $00
	LD [bag_pos], A

	; refill with types
	LD A, $00
	LD [bag_type+0], A
	INC A
	LD [bag_type+1], A
	INC A
	LD [bag_type+2], A
	INC A
	LD [bag_type+3], A
	INC A
	LD [bag_type+4], A
	INC A
	LD [bag_type+5], A
	INC A
	LD [bag_type+6], A

	; refill with colors
	LD A, $81
	LD [bag_color+0], A
	INC A
	LD [bag_color+1], A
	INC A
	LD [bag_color+2], A
	INC A
	LD [bag_color+3], A
	INC A
	LD [bag_color+4], A
	INC A
	LD [bag_color+5], A
	INC A
	LD [bag_color+6], A

	; how much to shuffle
	LD A, $1F
	LD [bag_counter], A

BagGrabShuffle1:
	; get first location
	CALL RandomFunction
	LD A, [rand_value]
	AND A, $07
	CP A, $07
	JR Z, BagGrabShuffle1
	LD BC, bag_type
	ADD A, C
	LD C, A
	
BagGrabShuffle2:
	; get second location
	CALL RandomFunction
	LD A, [rand_value]
	AND A, $07
	CP A, $07
	JR Z, BagGrabShuffle2
	LD DE, bag_type
	ADD A, E
	LD E, A

	; swap types
	LD A, [BC]
	LD [bag_swap], A
	LD A, [DE]
	LD [BC], A
	LD A, [bag_swap]
	LD [DE], A

	; shift over to colors
	LD A, $07
	ADD A, C
	LD C, A
	LD A, $07
	ADD A, E
	LD E, A

	; swap colors
	LD A, [BC]
	LD [bag_swap], A
	LD A, [DE]
	LD [BC], A
	LD A, [bag_swap]
	LD [DE], A

	; repeat
	LD A, [bag_counter]
	DEC A
	LD [bag_counter], A
	JR NZ, BagGrabShuffle1

BagGrabExit:
	; return
	RET


; semi-random, val = 5*prev+17
RandomFunction:
	PUSH AF
	PUSH BC
	LD A, [rand_value]
	LD C, A
	SLA A
	SLA A
	ADD A, C
	ADD A, $11
	LD [rand_value], A
	POP BC
	POP AF
	RET



; ****************
; ****************
; MENU CODE
; ****************
; ****************

MenuEntry:
	; check that window is stopped
	HALT
	NOP
	LD A, [window_dir]
	CP A, $00
	JR NZ, MenuEntry

	; turn off interrupts
	DI
	LD A, $00
	LD [$FFFF], A

	; turn off sprites
	LD A, $E1
	LD [$FF40], A

	; clear background tiles
	LD HL, $D800
MenuBackLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $DC
	JR C, MenuBackLoop

	; clear oam transfer data
	LD HL, oam_trans_addr
MenuSpriteLoop1:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, oam_trans_byte+1
	JR C, MenuSpriteLoop1

	; clear shadow transfer data
	LD HL, shadow_trans_addr
MenuSpriteLoop2:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, shadow_trans_byte+1
	JR C, MenuSpriteLoop2

	; wait for v-blank to turn off LCD
MenuVBlankLoop:
	LD A, [$FF44]
	CP A, $90 ; line 144
	JR C, MenuVBlankLoop

	; oam dma transfer
	CALL $FF80

	; set palettes for background/obj0/obj1
	LD A, $E4
	LD [$FF47], A
	LD [$FF48], A
	LD [$FF49], A
	
	; set scroll background values
	LD A, $00
	LD [$FF42], A
	LD A, $00
	LD [$FF43], A

; ********
; MENU SETUP

	; add title tile data
	LD BC, TitleData
	LD HL, $D400
MenuTitleLoop1:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $D8
	JR C, MenuTitleLoop1
	LD HL, $C800
MenuTitleLoop2:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $D0
	JR C, MenuTitleLoop2

	; print title tiles
	LD HL, $D802
	LD A, $40 ; start at 64
	LD D, $0C ; 12 lines
MenuTitleOuterLoop:
	LD E, $10 ; 10 characters per line
MenuTitleInnerLoop:
	LD [HLI], A
	INC A
	DEC E
	JR NZ, MenuTitleInnerLoop
	LD BC, $0010
	ADD HL, BC
	DEC D
	JR NZ, MenuTitleOuterLoop

	; check reset flag
	LD A, [reset_flag]
	CP A, $00
	JP Z, MenuOptionsStart
	
	; change cursor location
	LD A, $10
	LD [menu_pos], A

	; print initial text
	LD BC, AuthorData
	LD HL, $D980
	LD D, $05 ; 5 lines
MenuInitialOuterLoop:
	LD E, $14 ; 20 characters per line
MenuInitialInnerLoop:
	LD A, [BC]
	INC BC
	SUB A, $20
	LD [HLI], A
	DEC E
	JR NZ, MenuInitialInnerLoop
	PUSH BC
	LD BC, $000C
	ADD HL, BC
	POP BC
	DEC D
	JR NZ, MenuInitialOuterLoop
	JP MenuOptionsExit

MenuOptionsStart:
	; find menu text
	LD A, [menu_status]
	CP A, $00
	JR Z, MenuOptionsCharacter
	CP A, $01
	JR Z, MenuOptionsLocation
	CP A, $02
	JR Z, MenuOptionsChallenge
	LD BC, $0000 ; error
	JR MenuOptionsPrint
MenuOptionsCharacter:
	LD BC, MenuCharacterText
	JR MenuOptionsPrint
MenuOptionsLocation:
	LD BC, MenuLocationText
	JR MenuOptionsPrint
MenuOptionsChallenge:
	LD BC, MenuChallengeText
	JR MenuOptionsPrint

	; print menu text
MenuOptionsPrint:
	LD HL, $D980
	LD D, $05 ; 5 lines
MenuOptionsOuterLoop:
	LD E, $14 ; 20 characters per line
MenuOptionsInnerLoop:
	LD A, [BC]
	INC BC
	SUB A, $20
	LD [HLI], A
	DEC E
	JR NZ, MenuOptionsInnerLoop
	PUSH BC
	LD BC, $000C
	ADD HL, BC
	POP BC
	DEC D
	JR NZ, MenuOptionsOuterLoop
MenuOptionsExit:

	; add cursor tile data
	LD BC, MenuCursorData
	LD HL, $C000
MenuCursorLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, L
	CP A, $20
	JR C, MenuCursorLoop

	; add star tile data
	LD BC, MenuStarData
	LD HL, $C020
MenuStarLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, L
	CP A, $60
	JR C, MenuStarLoop

; ********	

	; short delay forced
	LD A, $0F
	LD [wait_counter], A

	; clear transfer addresses to initialize
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, $00
	LD [inc_wram_address+0], A
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, $00
	LD [inc_vram_address+0], A
	LD A, $80
	LD [inc_vram_start], A

	; alter transfer address
	LD A, [menu_status]
	CP A, $00
	JR Z, MenuFullTransfer
	LD A, $98
	LD [inc_vram_start], A
MenuFullTransfer:

	; turn on V-Blank interrupt
	LD A, $01
	LD [$FFFF], A
	EI
	NOP
	NOP
	NOP
	NOP

MenuWaitLoop:
	; wait for wram-to-vram transfer to complete
	HALT
	NOP
	LD A, [inc_vram_address+0]
	CP A, $9C
	JR C, MenuWaitLoop
	
	; set window to move down
	LD A, $02
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $00
	CALL Z, AudioEffectSlideDown

MenuHaltLoop:
	; check for jump address
	LD A, [jump_address+3]
	CP A, $00
	JR Z, MenuHaltContinue
	LD A, $00 ; clear jump flag
	LD [jump_address+3], A
	JP jump_address

MenuHaltContinue:
	; wait for v-blank interrupt then loop
	HALT
	NOP
	JR MenuHaltLoop

; called from v-blank interrupt
MenuInterruptFunction:
	; dma transfer oam data
	CALL $FF80

	; capture joypad input
	CALL JoypadCaptureFunction

	; wait for forced delay
	LD A, [wait_counter]
	CP A, $00
	JR Z, MenuInterruptChoice
	DEC A
	LD [wait_counter], A
	JR MenuInterruptSkip

MenuInterruptChoice:
	; make choices
	CALL MenuChoiceFunction

MenuInterruptSkip:
	; display changes
	CALL MenuDisplayFunction

	; help randomize initial seed
	LD A, [reset_flag]
	CP A, $00
	JR Z, MenuInterruptExit
	CALL RandomFunction
MenuInterruptExit:
	; return
	RET

; make choices
MenuChoiceFunction:
	; check joypad 
	LD A, [joy_current]
	BIT $00, A ; action
	CALL Z, MenuChoiceCheckAction

	LD A, [joy_current]
	BIT $01, A ; back
	CALL Z, MenuChoiceCheckBack
	
	LD A, [joy_current]
	BIT $06, A ; up
	CALL Z, MenuChoiceCheckUp

	LD A, [joy_current]
	BIT $07, A ; down
	CALL Z, MenuChoiceCheckDown	

	RET

MenuChoiceCheckAction:	
	; start game type
	LD A, [joy_previous]
	BIT $00, A
	JP NZ, MenuChoiceSelection
	RET

MenuChoiceCheckBack:	
	; start game type
	LD A, [joy_previous]
	BIT $01, A
	JR NZ, MenuChoiceSelection
	RET

MenuChoiceCheckUp:
	; start game type
	LD A, [joy_previous]
	BIT $06, A
	JP NZ, MenuChoiceMoveUp
	RET

MenuChoiceCheckDown:
	; start game type
	LD A, [joy_previous]
	BIT $07, A
	JP NZ, MenuChoiceMoveDown
	RET

MenuChoiceSelection:
	; check reset flag
	LD A, [reset_flag]
	CP A, $00
	JR Z, MenuChoiceStore	

	; clear reset flag
	LD A, $00
	LD [reset_flag], A

	; start music now
	LD A, $00
	LD [audio_track], A
	LD A, $70 ; turn volume on now
	LD [audio_volume], A
	CALL AudioMusicLoad

	; move cursor position to zero
	LD A, $00
	LD [menu_pos], A

	JP MenuChoiceJump

MenuChoiceStore:
	CALL AudioEffectSelect

	; check menu number
	LD A, [menu_status]
	CP A, $00
	JR Z, MenuChoiceCharacter
	CP A, $01
	JR Z, MenuChoiceLocation
	CP A, $02
	JR Z, MenuChoiceChallenge
	JR MenuChoiceRestart ; error

	; store selection
MenuChoiceCharacter:
	LD A, [menu_pos]
	LD [menu_character], A
	JR MenuChoiceRestart
MenuChoiceLocation:
	LD A, [menu_pos]
	LD [menu_location], A
	CP A, $03 ; classic mode
	JR NZ, MenuChoiceRestart
	LD A, $FF
	LD [menu_challenge], A
	JR MenuChoiceGameStart
MenuChoiceChallenge:
	LD A, [menu_pos]
	LD [menu_challenge], A
	
MenuChoiceGameStart:
	; start scene just before game
	LD A, $00 ; before game scene
	LD [scene_direction], A
	LD A, $00
	LD [scene_status], A
	LD A, $00
	LD [menu_pos], A
	LD A, $FF
	LD [menu_status], A

	; set window to move up
	LD A, $01
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $90
	CALL Z, AudioEffectSlideUp
	
	; load jump address
	LD BC, SceneEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET

MenuChoiceRestart:
	; go to next menu
	LD A, $00
	LD [menu_pos], A
	LD A, [menu_status]
	INC A
	LD [menu_status], A
	
MenuChoiceJump:
	; load jump address
	LD BC, MenuEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET	

MenuChoiceMoveUp:
	; move up
	LD A, [menu_pos]
	CP A, $00
	JR Z, MenuChoiceReturn
	DEC A
	LD [menu_pos], A

	CALL AudioEffectBong

	RET

MenuChoiceMoveDown:
	; move down
	LD A, [menu_pos]
	CP A, $03
	JR NC, MenuChoiceReturn
	INC A
	LD [menu_pos], A

	CALL AudioEffectBong

	RET

MenuChoiceReturn:
	RET


; display menu changes
MenuDisplayFunction:
	; increment timer
	LD A, [menu_timer]
	INC A
	LD [menu_timer], A
	CP A, $20
	JR C, MenuDisplayNext
	LD A, $00
	LD [menu_timer], A

	; increment palette
	LD A, [menu_palette]
	INC A
	LD [menu_palette], A
	CP A, $10 ; change accordingly
	JR C, MenuDisplayPalette
	LD A, $00
	LD [menu_palette], A

MenuDisplayPalette:
	; change palette
	LD HL, MenuCursorPalette
	LD B, $00
	AND A, $03
	LD C, A
	ADD HL, BC
	LD A, [HL]
	LD [$FF48], A

MenuDisplayNext:
	; move cursor according to position
	LD A, [menu_pos]
	SLA A
	SLA A
	SLA A
	ADD A, $78
	LD [oam_trans_addr+$00], A
	LD [oam_trans_addr+$04], A
	LD A, $0C
	LD [oam_trans_addr+$01], A
	ADD A, $08
	LD [oam_trans_addr+$05], A
	LD A, $00
	LD [oam_trans_addr+$02], A
	LD A, $01
	LD [oam_trans_addr+$06], A
	LD A, $00
	LD [oam_trans_addr+$03], A
	LD [oam_trans_addr+$07], A

	; star sprites
	LD A, [menu_palette]
	SRL A
	SRL A
	SLA A
	LD HL, MenuStarCoordData
	LD B, $00
	LD C, A
	ADD HL, BC
	LD A, [HLI]
	ADD A, $18
	LD [oam_trans_addr+$09], A
	LD A, [HL]
	ADD A, $10
	LD [oam_trans_addr+$08], A
	LD A, [menu_palette]
	AND A, $03
	ADD A, $02
	LD [oam_trans_addr+$0A], A
	LD A, $10
	LD [oam_trans_addr+$0B], A

	RET






; ****************
; ****************
; SCENE CODE
; ****************
; ****************

SceneEntry:
	; check that window is stopped
	HALT
	NOP
	LD A, [window_dir]
	CP A, $00
	JR NZ, SceneEntry

	; turn off interrupts
	DI
	LD A, $00
	LD [$FFFF], A

	; turn off sprites
	LD A, $E1
	LD [$FF40], A

	; clear background tiles
	LD HL, $D800
SceneBackLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $DC
	JR C, SceneBackLoop

	; clear oam transfer data
	LD HL, oam_trans_addr
SceneSpriteLoop1:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, oam_trans_byte+1
	JR C, SceneSpriteLoop1

	; clear shadow transfer data
	LD HL, shadow_trans_addr
SceneSpriteLoop2:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, shadow_trans_byte+1
	JR C, SceneSpriteLoop2

; wait for v-blank to turn off LCD
SceneVBlankLoop:
	LD A, [$FF44]
	CP A, $90 ; line 144
	JR C, SceneVBlankLoop

	; oam dma transfer
	CALL $FF80

	; set palettes for background/obj0/obj1
	LD A, $E4
	LD [$FF47], A
	LD [$FF48], A
	LD [$FF49], A
	
	; set scroll background values
	LD A, $00
	LD [$FF42], A
	LD A, $00
	LD [$FF43], A

; ********
; SCENE SETUP

	JP SceneSelect

SceneSelectCharacterData:
	; find character portrait address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectCharacterList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectCharacterList:
	DW CharacterData1
	DW CharacterData2
	DW CharacterData3
	DW CharacterData4

SceneSelectAffectionData:
	; find affection text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectAffectionList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectAffectionList:
	DW SceneDialogBoy1Affection
	DW SceneDialogGirl1Affection
	DW SceneDialogBoy2Affection
	DW SceneDialogGirl2Affection

SceneSelectLocationData:
	; find location text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectLocationList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectLocationList:
	DW SceneDialogBoy1Location
	DW SceneDialogGirl1Location
	DW SceneDialogBoy2Location
	DW SceneDialogGirl2Location

SceneSelectChallengeData:
	; find challenge text address
	PUSH HL
	PUSH BC
	LD A, [menu_challenge]
	CP A, $FF
	JR Z, SceneSelectChallengeClassic
	LD HL, SceneSelectChallengeList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectChallengeList:
	DW SceneDialogBoy1Challenge
	DW SceneDialogGirl1Challenge
	DW SceneDialogBoy2Challenge
	DW SceneDialogGirl2Challenge
SceneSelectChallengeClassic:
	LD HL, SceneSelectClassicList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectClassicList:
	DW SceneDialogBoy1Classic
	DW SceneDialogGirl1Classic
	DW SceneDialogBoy2Classic
	DW SceneDialogGirl2Classic

SceneSelectEndClassicData:
	; find end classic text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectEndClassicList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectEndClassicList:
	DW SceneDialogBoy1EndClassic
	DW SceneDialogGirl1EndClassic
	DW SceneDialogBoy2EndClassic
	DW SceneDialogGirl2EndClassic

SceneSelectEndBadData:
	; find end bad text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectEndBadList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectEndBadList:
	DW SceneDialogBoy1EndBad
	DW SceneDialogGirl1EndBad
	DW SceneDialogBoy2EndBad
	DW SceneDialogGirl2EndBad

SceneSelectEndGoodData:
	; find end good text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectEndGoodList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectEndGoodList:
	DW SceneDialogBoy1EndGood
	DW SceneDialogGirl1EndGood
	DW SceneDialogBoy2EndGood
	DW SceneDialogGirl2EndGood

SceneSelectEndSecondData:
	; find end good text address
	PUSH HL
	PUSH BC
	LD HL, SceneSelectEndSecondList
	LD A, [menu_character]
	AND A, $03
	JP SceneSelectIncrement
SceneSelectEndSecondList:
	DW SceneDialogBoy1EndSecond
	DW SceneDialogGirl1EndSecond
	DW SceneDialogBoy2EndSecond
	DW SceneDialogGirl2EndSecond

SceneSelectIncrement:
	; increment address through list
	SLA A
	LD C, A
	LD B, $00
	ADD HL, BC
	LD A, [HLI]
	LD [scene_ret_addr+0], A
	LD A, [HL]
	LD [scene_ret_addr+1], A
	POP BC
	POP HL
	RET
	

SceneSelect:
	; store portrait address
	CALL SceneSelectCharacterData
	LD A, [scene_ret_addr+0]
	LD [scene_char_addr+0], A
	LD A, [scene_ret_addr+1]
	LD [scene_char_addr+1], A

	; store default affection
	LD A, [menu_character]
	LD C, A
	LD B, $00
	LD HL, char_affection
	ADD HL, BC
	LD A, [HL]
	LD [scene_affection], A

	; decide on text location
	LD A, [scene_direction]
	CP A, $00 ; before game scene
	JP Z, SceneSelectBefore
	LD A, [menu_challenge]
	CP A, $FF ; classic mode
	JP Z, SceneSelectEndClassic
	LD A, [score_gameover]
	CP A, $02 ; bad ending
	JP Z, SceneSelectEndBad
	CP A, $01 ; good ending
	JP Z, SceneSelectEndGood

SceneSelectBefore:
	LD A, [scene_status]
	CP A, $00 ; affection
	JP Z, SceneSelectAffection
	CP A, $01 ; location
	JP Z, SceneSelectLocation
	CP A, $02 ; challenge
	JP Z, SceneSelectChallenge

SceneSelectAffection:
	CALL SceneSelectAffectionData
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	LD BC, $FFB0 ; minus 80 from address
	ADD HL, BC
	LD BC, $0050 ; 80 characters per screen
	LD A, [scene_affection]
	AND A, $C0
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	INC A
	JP SceneSelectPage

SceneSelectLocation:
	CALL SceneSelectLocationData
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	LD BC, $FFB0 ; minus 80 from address
	ADD HL, BC
	LD BC, $0050 ; 80 characters per screen
	LD A, [menu_location]
	AND A, $03
	INC A
	JP SceneSelectPage

SceneSelectChallenge:
	LD A, $F0 ; stop scene here
	LD [scene_status], A
	CALL SceneSelectChallengeData
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	LD A, [menu_challenge]
	CP A, $FF
	JP Z, SceneSelectPageExit
	LD BC, $FFB0 ; minus 80 from address
	ADD HL, BC
	LD BC, $0050 ; 80 characters per screen
	AND A, $03
	INC A
	JP SceneSelectPage
	
SceneSelectEndClassic:
	LD A, $F0 ; stop scene here
	LD [scene_status], A
	CALL SceneSelectEndClassicData
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	JP SceneSelectPageExit

SceneSelectEndBad:
	LD A, $F0 ; stop scene here
	LD [scene_status], A
	CALL SceneSelectEndBadData
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	JP SceneSelectPageExit

SceneSelectEndGood:
	
	; calculate affection bonuses
	LD A, $00
	LD [char_bonus+0], A
	LD [char_bonus+1], A
	LD [char_bonus+2], A
	LD [char_bonus+3], A

	; only add at end of second scene
	LD A, [scene_status]
	CP A, $00
	JR Z, SceneSelectEndGoodMax

	; find location bonus
	LD A, [menu_character]
	LD C, A
	LD B, $00
	LD HL, AffectionLocationData
	ADD HL, BC
	LD A, [HL]
	LD E, A

	; find challenge bonus
	LD A, [menu_challenge]
	LD C, A
	LD B, $00
	LD HL, AffectionChallengeData
	ADD HL, BC
	LD A, [HL]
	LD D, A

	; add to current affection
	LD A, [menu_character]
	LD C, A
	LD B, $00
	LD HL, char_affection
	ADD HL, BC
	LD A, [HL]
	ADD A, E
	ADD A, D
	LD [HL], A
	CP A, $BF ; max out at $BF
	JR C, SceneSelectEndGoodMax
	LD A, $BF ; max out at $BF
	LD [HL], A
SceneSelectEndGoodMax:

	; proceed onward
	LD A, [scene_status]
	CP A, $00
	JR Z, SceneSelectEndGoodFirst
	LD A, $F0 ; stop scene here
	LD [scene_status], A
	CALL SceneSelectEndSecondData
	JR SceneSelectEndGoodBoth
SceneSelectEndGoodFirst:
	CALL SceneSelectEndGoodData
SceneSelectEndGoodBoth:
	LD A, [scene_ret_addr+0]
	LD L, A
	LD A, [scene_ret_addr+1]
	LD H, A
	LD BC, $FFB0 ; minus 80 from address
	ADD HL, BC
	LD BC, $0050 ; 80 characters per screen
	LD A, [scene_affection]
	AND A, $C0
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	SRL A
	INC A
	JP SceneSelectPage
	

SceneSelectPage:
	; increment pages of dialog
	ADD HL, BC
	DEC A
	JR NZ, SceneSelectPage
SceneSelectPageExit:
	LD A, L
	LD [scene_text_addr+0], A
	LD A, H
	LD [scene_text_addr+1], A

	; print menu text
SceneDialogPrint:
	LD A, [scene_text_addr+0]
	LD C, A
	LD A, [scene_text_addr+1]
	LD B, A
	LD HL, $D960
	LD D, $04 ; 4 lines
SceneDialogOuterLoop:
	LD E, $14 ; 20 characters per line
SceneDialogInnerLoop:
	LD A, [BC]
	INC BC
	SUB A, $20
	LD [HLI], A
	DEC E
	JR NZ, SceneDialogInnerLoop
	PUSH BC
	LD BC, $000C
	ADD HL, BC
	POP BC
	DEC D
	JR NZ, SceneDialogOuterLoop

	; clear last text character
	; and set affection for portrait
	PUSH BC
	LD BC, $FFF3
	ADD HL, BC
	POP BC
	LD A, $00
	LD [HL], A
	DEC BC
	LD A, [BC]
	LD [scene_affection], A

SceneCharacterLoad:
	; find specific expression
	LD A, [scene_char_addr+0]
	LD L, A
	LD A, [scene_char_addr+1]
	LD H, A
	LD A, [scene_affection]
	AND A, $C0
	CP A, $C0
	JR NZ, SceneCharacterExpression
	LD A, $80 ; only 3 expressions per character
SceneCharacterExpression:
	SRL A
	SRL A
	SRL A
	SRL A
	LD B, A
	LD C, $00
	ADD HL, BC
	LD B, H
	LD C, L

	; add person tile data
	LD HL, $D400
SceneCharacterLoop1:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $D8
	JR C, SceneCharacterLoop1

	; draw person on top
	LD HL, $D826
	LD BC, $0018
	LD A, $40
SceneCharacterLoop2:
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	LD [HLI], A
	INC A
	ADD HL, BC
	CP A, $80
	JR C, SceneCharacterLoop2

	; print character name
	LD A, [menu_character]
	AND A, $03
	SLA A
	SLA A
	LD C, A
	ADD A, C
	ADD A, C
	ADD A, C
	ADD A, C
	LD HL, CharacterNameText
	LD B, $00
	LD C, A
	ADD HL, BC
	LD B, H
	LD C, L
	LD HL, $D920
	LD E, $14 ; 20 characters per line
SceneNameLoop:
	LD A, [BC]
	INC BC
	SUB A, $20
	LD [HLI], A
	DEC E
	JR NZ, SceneNameLoop
	

; ********

	; short delay forced
	LD A, $0F
	LD [wait_counter], A

	; clear transfer addresses to initialize
	LD A, $00
	LD [inc_wram_address+1], A
	LD A, $00
	LD [inc_wram_address+0], A
	LD A, $00
	LD [inc_vram_address+1], A
	LD A, $00
	LD [inc_vram_address+0], A
	LD A, $94
	LD [inc_vram_start], A

	; turn on V-Blank interrupt
	LD A, $01
	LD [$FFFF], A
	EI
	NOP
	NOP
	NOP
	NOP

SceneWaitLoop:
	; wait for wram-to-vram transfer to complete
	HALT
	NOP
	LD A, [inc_vram_address+0]
	CP A, $9C
	JR C, SceneWaitLoop
	
	; set window to move down
	LD A, $02
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $00
	CALL Z, AudioEffectSlideDown

SceneHaltLoop:
	; check for jump address
	LD A, [jump_address+3]
	CP A, $00
	JR Z, SceneHaltContinue
	LD A, $00 ; clear jump flag
	LD [jump_address+3], A
	JP jump_address

SceneHaltContinue:
	; wait for v-blank interrupt then loop
	HALT
	NOP
	JR SceneHaltLoop

; called from v-blank interrupt
SceneInterruptFunction:
	; dma transfer oam data
	CALL $FF80

	; capture joypad input
	CALL JoypadCaptureFunction

	; wait for forced delay
	LD A, [wait_counter]
	CP A, $00
	JR Z, SceneInterruptChoice
	DEC A
	LD [wait_counter], A
	JR SceneInterruptExit

SceneInterruptChoice:
	; make choices
	CALL SceneChoiceFunction

SceneInterruptExit:
	; return
	RET

; make choices
SceneChoiceFunction:
	; check joypad 
	LD A, [joy_current]
	BIT $00, A ; action
	CALL Z, SceneChoiceCheckAction

	LD A, [joy_current]
	BIT $01, A ; back
	CALL Z, SceneChoiceCheckBack
	RET

SceneChoiceCheckAction:
	; start game type
	LD A, [joy_previous]
	BIT $00, A
	JR NZ, SceneChoiceSelection
	RET

SceneChoiceCheckBack:	
	; start game type
	LD A, [joy_previous]
	BIT $01, A
	JR NZ, SceneChoiceSelection
	RET

SceneChoiceSelection:
	; increment scene number
	LD A, [scene_status]
	INC A
	LD [scene_status], A

	CALL AudioEffectCollect

	LD A, [scene_status]
	CP A, $F0 ; exit scene
	JR C, SceneChoiceExit

	LD A, [scene_direction]
	CP A, $00
	JR NZ, SceneChoiceMenu
	
	; go to game
	LD A, $00
	LD [scene_direction], A
	LD A, $FF
	LD [scene_status], A
	LD A, $00
	LD [menu_pos], A
	LD A, $FF
	LD [menu_status], A

	; load jump address
	LD BC, GameEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET

SceneChoiceMenu:
	; go to menu
	LD A, $00
	LD [scene_direction], A
	LD A, $FF
	LD [scene_status], A
	LD A, $00
	LD [menu_pos], A
	LD A, $00
	LD [menu_status], A

	; set window to move up
	LD A, $01
	LD [window_dir], A
	LD A, [window_pos]
	CP A, $90
	CALL Z, AudioEffectSlideUp
	
	; load jump address
	LD BC, MenuEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET

SceneChoiceExit:
	; redraw scene
	; load jump address
	LD BC, SceneEntry
	LD A, C
	LD [jump_address+1], A
	LD A, B
	LD [jump_address+2], A
	LD A, $01 ; ready to jump
	LD [jump_address+3], A
	RET

	
; ****************
; ****************
; AUDIO SECTION
; ****************
; ****************

; play effects through Channel 1
AudioEffectBong:
	LD A, $00
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F1
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $85
	LD [$FF14], A
	RET

AudioEffectSelect:
	LD A, $24
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F0
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $85
	LD [$FF14], A
	RET

AudioEffectSlideUp:
	LD A, $77
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F2
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $86
	LD [$FF14], A
	RET

AudioEffectSlideDown:
	LD A, $7F
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F2
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $86
	LD [$FF14], A
	RET
	
AudioEffectCrunch:
	LD A, $1B
	LD [$FF10], A
	LD A, $28
	LD [$FF11], A
	LD A, $F5
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $C5
	LD [$FF14], A
	RET

AudioEffectApprove:
	LD A, $36
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F2
	LD [$FF12], A
	LD A, $80
	LD [$FF13], A
	LD A, $86
	LD [$FF14], A
	RET

AudioEffectSwish:
	LD A, $24
	LD [$FF10], A
	LD A, $00
	LD [$FF11], A
	LD A, $F1
	LD [$FF12], A
	LD A, $00
	LD [$FF13], A
	LD A, $86
	LD [$FF14], A
	RET

AudioEffectCollect:
	LD A, $00
	LD [$FF10], A
	LD A, $80
	LD [$FF11], A
	LD A, $F2
	LD [$FF12], A
	LD A, $9D
	LD [$FF13], A
	LD A, $87
	LD [$FF14], A
	RET

AudioMusicTrack:
	; change music track
	PUSH AF
	LD A, [audio_track]
	INC A
	LD [audio_track], A
	CP A, $03 ; max tracks
	JR C, AudioMusicTrackExit
	LD A, $00
	LD [audio_track], A
AudioMusicTrackExit:
	POP AF
	RET

AudioMusicVolume:
	; lower volume then cycle back
	PUSH AF
	LD A, [audio_volume]
	CP A, $00
	JR NZ, AudioMusicVolumeNext
	LD A, $F0
	LD [audio_volume], A
	POP AF
	RET
AudioMusicVolumeNext:
	SRL A
	AND A, $F0
	LD [audio_volume], A
	POP AF
	RET

AudioMusicLoad:
	; set initial music values
	LD A, $00
	LD [audio_pos], A
	LD [audio_timer], A

	; load square channel address
	LD BC, AudioMusicLoadAutumn ; default
	LD A, [audio_track]
	CP A, $00
	CALL Z, AudioMusicLoadAutumn
	CP A, $01
	CALL Z, AudioMusicLoadAdventure
	CP A, $02
	CALL Z, AudioMusicLoadClassic
	
	; put into address variables
	LD A, B
	LD [audio_addr+0], A
	LD A, C
	LD [audio_addr+1], A

	RET

AudioMusicLoadAutumn:
	LD BC, AudioMusicDataAutumn
	RET
AudioMusicLoadAdventure:
	LD BC, AudioMusicDataAdventure
	RET
AudioMusicLoadClassic:
	LD BC, AudioMusicDataClassic
	RET

; play music using Channel 2, 3, and 4
; call during v-blank
AudioMusicPlay:
	; increment timer, only once every 4 frames
	LD A, [audio_timer]
	INC A
	LD [audio_timer], A
	AND A, $03
	CP A, $00
	JR NZ, AudioMusicPlayExit

	; increment position
	LD A, [audio_pos]
	INC A
	LD [audio_pos], A

	; find the exact location of the next note
	LD B, $00
	LD C, A
	LD A, [audio_addr+0]
	LD H, A
	LD A, [audio_addr+1]
	LD L, A
	ADD HL, BC

	; if $FF, then silence
	LD A, [HL]
	CP A, $FF
	JR Z, AudioMusicPlayNoise

	; fill channel 2 registers
	LD A, $AC
	LD [$FF16], A
	LD A, [audio_volume]
	LD [$FF17], A
	LD A, [HL]
	SLA A
	SLA A
	SLA A
	SLA A
	LD [$FF18], A
	LD A, [HL]
	SRL A
	SRL A
	SRL A
	SRL A
	OR A, $C0
	LD [$FF19], A
	
AudioMusicPlayNoise:
	; next page
	INC H

	; if $FF, then silence
	LD A, [HL]
	CP A, $FF
	JR Z, AudioMusicPlayExit

	; fill channel 4 registers
	LD A, $2C
	LD [$FF20], A
	LD A, [audio_volume]
	LD [$FF21], A
	LD A, [HL]
	LD [$FF22], A
	LD A, $C0
	LD [$FF23], A

AudioMusicPlayExit:
	; exit
	RET

AudioMusicDataAutumn:
	; "Autumn Synth"
	; Phrase 1: rolling arpeggios, D - Bm - G - Asus
	DB $48,$48,$54,$54,$5B,$5B,$64,$64,$5B,$5B,$54,$54,$5B,$5B,$FF,$FF
	DB $3E,$3E,$48,$48,$54,$54,$5F,$5F,$54,$54,$48,$48,$54,$54,$FF,$FF
	DB $2C,$2C,$56,$56,$5F,$5F,$64,$64,$5F,$5F,$56,$56,$5F,$5F,$FF,$FF
	DB $36,$36,$4E,$4E,$5B,$5B,$64,$64,$67,$67,$64,$64,$5B,$5B,$FF,$FF
	; Phrase 2: the melody sings over a low bass note
	DB $10,$10,$FF,$64,$64,$64,$64,$6A,$6A,$6A,$6A,$67,$67,$67,$67,$67
	DB $3E,$3E,$FF,$6A,$6A,$6A,$6A,$64,$64,$64,$64,$5F,$5F,$5F,$5F,$5F
	DB $2C,$2C,$FF,$64,$64,$64,$64,$6B,$6B,$6B,$6B,$64,$64,$64,$64,$64
	DB $36,$36,$FF,$67,$67,$67,$67,$64,$64,$64,$64,$5B,$5B,$5B,$5B,$5B
	; Phrase 3: the bridge, slow, long climbing arpeggios (G - D - Em - Asus)
	DB $2C,$2C,$2C,$2C,$56,$56,$56,$56,$5F,$5F,$5F,$5F,$64,$64,$64,$64
	DB $48,$48,$48,$48,$54,$54,$54,$54,$5B,$5B,$5B,$5B,$64,$64,$64,$64
	DB $4E,$4E,$4E,$4E,$56,$56,$56,$56,$5F,$5F,$5F,$5F,$67,$67,$67,$67
	DB $36,$36,$36,$36,$4E,$4E,$4E,$4E,$5B,$5B,$5B,$5B,$67,$67,$FF,$FF
	; Phrase 4: the homecoming, falling melodies that settle back on D
	DB $2C,$2C,$FF,$6B,$6B,$6B,$6B,$64,$64,$64,$64,$5F,$5F,$5F,$5F,$5F
	DB $10,$10,$FF,$6A,$6A,$6A,$6A,$64,$64,$64,$64,$5B,$5B,$5B,$5B,$5B
	DB $1D,$1D,$FF,$67,$67,$67,$67,$5F,$5F,$5F,$5F,$56,$56,$56,$56,$56
	DB $10,$10,$10,$10,$48,$48,$48,$48,$5B,$5B,$5B,$5B,$64,$64,$FF,$FF

	; Phrase 1 (bars 1-4), gentle pulse under the rolling arpeggios, tom fill at the end
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$FF,$FF,$63,$73,$83,$FF
	; Phrase 2 (bars 5-8), half-time, kick locks with the bass note, snare pickup at the end
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$73,$85,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$62,$74,$62,$74
	; Phrase 3 (bars 9-12), the bridge, sparse and building, snare roll into the homecoming
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$94,$FF,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$94,$FF,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$62,$74,$62,$74,$62,$FF
	; Phrase 4 (bars 13-16), the homecoming, then a soft fade-out
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$73,$85,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$73,$85,$FF,$FF,$83,$94,$FF,$FF

AudioMusicDataAdventure:
	; "Deep Hollow" 
	; Section A (bars 1-4), the lamp is lit in an empty hall
	DB $48,$48,$48,$48,$48,$48,$48,$FF,$51,$51,$51,$51,$51,$51,$51,$51
	DB $51,$51,$51,$51,$51,$51,$51,$FF,$48,$48,$48,$48,$48,$48,$48,$48
	DB $3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF,$41,$41,$41,$41,$48,$48,$48,$48
	DB $4E,$4E,$4E,$4E,$4E,$4E,$4E,$FF,$36,$36,$36,$36,$36,$36,$FF,$FF
	; Section A' (bars 5-8), the answer, settling down
	DB $48,$48,$48,$48,$48,$48,$48,$FF,$51,$51,$51,$51,$5B,$5B,$5B,$5B
	DB $5D,$5D,$5D,$5D,$5D,$5D,$5D,$FF,$51,$51,$51,$51,$51,$51,$51,$FF
	DB $56,$56,$56,$56,$51,$51,$51,$51,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$FF
	DB $48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$FF,$FF
	; Bridge (bars 9-12), something stirs below, the lowest notes
	DB $2C,$2C,$2C,$2C,$2C,$2C,$2C,$FF,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A
	DB $48,$48,$48,$48,$48,$48,$48,$FF,$36,$36,$36,$36,$36,$36,$36,$36
	DB $3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF,$41,$41,$41,$41,$3A,$3A,$3A,$3A
	DB $36,$36,$36,$36,$36,$36,$36,$FF,$1D,$1D,$1D,$1D,$1D,$1D,$FF,$FF
	; Reprise (bars 13-16), a little higher, then sinks to a long low D
	DB $51,$51,$51,$51,$51,$51,$51,$FF,$5B,$5B,$5B,$5B,$64,$64,$64,$64
	DB $64,$64,$64,$64,$64,$64,$64,$FF,$5D,$5D,$5D,$5D,$5D,$5D,$5D,$5D
	DB $5D,$5D,$5D,$5D,$56,$56,$56,$56,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$FF
	DB $48,$48,$48,$48,$48,$48,$48,$FF,$10,$10,$10,$10,$10,$10,$10,$10

	; Section A (bars 1-4), a single soft thump to start, then a pulse at mid-bar
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$A5,$FF,$FF,$FF,$FF,$FF,$FF
	; Section A' (bars 5-8), the same pulse, settling home
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$A5,$FF,$FF,$FF,$FF,$FF,$FF
	; Bridge (bars 9-12), slow falling swells, the lowest rumble
	DB $83,$94,$A5,$FF,$FF,$FF,$FF,$FF,$94,$A5,$FF,$FF,$FF,$FF,$FF,$FF
	DB $83,$94,$A5,$FF,$FF,$FF,$FF,$FF,$94,$A5,$FF,$FF,$FF,$FF,$FF,$FF
	DB $83,$94,$A5,$FF,$FF,$FF,$FF,$FF,$94,$A5,$FF,$FF,$FF,$FF,$FF,$FF
	DB $83,$94,$A5,$FF,$FF,$FF,$FF,$FF,$83,$94,$A5,$FF,$FF,$FF,$FF,$FF
	; Reprise (bars 13-16), the thump returns, then a long fade under the final low D
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$94,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$FF,$FF,$FF,$FF,$83,$94,$A5,$FF,$FF,$FF,$FF,$FF

AudioMusicDataClassic:
	; "Tetra Classic"
	; Section A (bars 1-4)
	DB $67,$67,$67,$67,$5F,$5F,$61,$61,$64,$64,$64,$64,$61,$61,$5F,$5F
	DB $5B,$5B,$5B,$FF,$5B,$5B,$61,$61,$67,$67,$67,$67,$64,$64,$61,$61
	DB $5F,$5F,$5F,$5F,$5F,$5F,$61,$61,$64,$64,$64,$64,$67,$67,$67,$67
	DB $61,$61,$61,$61,$5B,$5B,$5B,$FF,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
	; Section B (bars 5-8)
	DB $64,$64,$64,$64,$64,$64,$69,$69,$6D,$6D,$6D,$6D,$6B,$6B,$69,$69
	DB $67,$67,$67,$67,$67,$67,$61,$61,$67,$67,$67,$67,$64,$64,$61,$61
	DB $5F,$5F,$5F,$FF,$5F,$5F,$61,$61,$64,$64,$64,$64,$67,$67,$67,$67
	DB $61,$61,$61,$61,$5B,$5B,$5B,$FF,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
	; Bridge (bars 9-12), slow half notes
	DB $67,$67,$67,$67,$67,$67,$67,$67,$61,$61,$61,$61,$61,$61,$61,$61
	DB $64,$64,$64,$64,$64,$64,$64,$64,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F
	DB $61,$61,$61,$61,$61,$61,$61,$61,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B
	DB $59,$59,$59,$59,$59,$59,$59,$59,$59,$59,$59,$59,$59,$59,$FF,$FF
	; Reprise (bars 13-16), ends on a long A
	DB $67,$67,$67,$67,$5F,$5F,$61,$61,$64,$64,$64,$64,$61,$61,$5F,$5F
	DB $5B,$5B,$5B,$FF,$5B,$5B,$61,$61,$67,$67,$67,$67,$64,$64,$61,$61
	DB $5F,$5F,$5F,$5F,$5F,$5F,$61,$61,$64,$64,$64,$64,$67,$67,$67,$67
	DB $61,$61,$61,$61,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B

	; Section A (bars 1-4), kick on 1&3, snare on 2&4, low ticks on the offbeats
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$62,$74
	; Section B (bars 5-8), double kick on the "and" of 3, tom fill into the bridge
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$73,$85,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$73,$85,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$63,$73,$73,$83
	; Bridge (bars 9-12), half-time: kick on 1, snare on 3, low ticks on 2&4
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$62,$74,$FF,$FF,$94,$FF,$FF,$FF
	DB $73,$85,$FF,$FF,$94,$FF,$94,$FF,$62,$74,$62,$74,$62,$74,$62,$FF
	; Reprise (bars 13-16), full groove returns, then a soft ending
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$73,$85,$62,$74,$94,$FF
	DB $73,$85,$94,$FF,$62,$74,$94,$FF,$73,$85,$94,$FF,$62,$74,$62,$74
	DB $73,$85,$FF,$FF,$94,$FF,$FF,$FF,$73,$85,$FF,$FF,$83,$94,$FF,$FF




; ****************
; ****************
; LOWER DATA SECTION
; ****************
; ****************

; 12x20 grid for field array construction (with added data to fill page)
; to add trash, put $80 value in place of $00 in normal field
FieldArrayData:
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
	DB $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
	DB $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

; transfer this to $FF80 in HRAM then call to transfer oam data
OamDmaHramCode:
	DB $3E, $D0, $E0, $46, $3E, $28, $3D, $20, $FD, $C9

; 16 bytes that are piece graphics
PieceBlockData:
	DB $66,$7E,$24,$3C,$C3,$DB,$81,$81,$FF,$81,$FF,$81,$FF,$81,$FF,$FF,
	DB $FF,$FF,$81,$FF,$BD,$C3,$A5,$C3,$A5,$C3,$BD,$C3,$81,$FF,$FF,$FF,
	DB $3C,$3C,$7E,$42,$F7,$89,$DF,$A1,$FB,$85,$EF,$91,$7E,$42,$3C,$3C,
	DB $3C,$3C,$42,$7E,$91,$EF,$85,$FB,$A1,$DF,$89,$F7,$42,$7E,$3C,$3C,
	DB $FF,$FF,$B1,$C1,$D9,$A1,$ED,$91,$B7,$89,$9B,$85,$8D,$83,$FF,$FF,
	DB $7E,$7E,$F7,$89,$C3,$BD,$D7,$A9,$D7,$A9,$C3,$BD,$F7,$89,$7E,$7E,
	DB $7E,$7E,$89,$F7,$BD,$C3,$A9,$D7,$A9,$D7,$BD,$C3,$89,$F7,$7E,$7E,
	DB $3C,$3C,$7E,$42,$FF,$81,$FF,$81,$00,$FF,$FF,$81,$FF,$81,$7E,$7E,
	DB $3C,$3C,$7E,$42,$FF,$81,$FF,$C3,$BD,$FF,$81,$FF,$81,$FF,$7E,$7E,
	DB $FF,$FF,$81,$FF,$BD,$C3,$A5,$C3,$A5,$C3,$BD,$C3,$81,$FF,$FF,$FF,
	DB $FE,$FE,$FF,$81,$C3,$BD,$FF,$81,$C3,$BD,$FF,$81,$FF,$81,$7F,$7F,
	DB $7F,$7F,$81,$FF,$BD,$C3,$81,$FF,$BD,$C3,$81,$FF,$81,$FF,$FE,$FE,
	DB $FF,$FF,$B1,$C1,$D9,$A1,$ED,$91,$B7,$89,$9B,$85,$8D,$83,$FF,$FF,
	DB $E7,$E7,$FF,$99,$E7,$99,$E7,$99,$E7,$99,$E7,$99,$E7,$FF,$18,$18,
	DB $E7,$E7,$99,$FF,$99,$E7,$99,$E7,$99,$E7,$99,$E7,$FF,$E7,$18,$18,
	DB $7F,$7F,$7F,$41,$FF,$FD,$87,$FD,$87,$FD,$87,$FD,$87,$FF,$FC,$FC,
	DB $18,$18,$24,$3C,$5A,$66,$A5,$C3,$A5,$C3,$5A,$66,$24,$3C,$18,$18,
	DB $FF,$FF,$81,$FF,$BD,$C3,$A5,$C3,$A5,$C3,$BD,$C3,$81,$FF,$FF,$FF,
	DB $3C,$3C,$7E,$42,$DD,$A3,$EB,$95,$EB,$95,$DD,$A3,$7E,$42,$3C,$3C,
	DB $3C,$3C,$42,$7E,$C5,$BB,$A9,$D7,$A9,$D7,$C5,$BB,$42,$7E,$3C,$3C,
	DB $FF,$FF,$B1,$C1,$D9,$A1,$ED,$91,$B7,$89,$9B,$85,$8D,$83,$FF,$FF,
	DB $7E,$7E,$81,$FF,$81,$FF,$81,$FF,$FF,$FF,$7E,$42,$7E,$42,$7E,$7E,
	DB $7E,$7E,$FF,$81,$FF,$81,$FF,$81,$FF,$FF,$42,$7E,$42,$7E,$7E,$7E,
	DB $24,$3C,$81,$FF,$81,$FF,$C3,$BD,$FF,$81,$FF,$81,$7E,$42,$3C,$3C,
	DB $81,$81,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$81,$81,
	DB $FF,$FF,$81,$FF,$BD,$C3,$A5,$C3,$A5,$C3,$BD,$C3,$81,$FF,$FF,$FF,
	DB $3C,$3C,$5A,$62,$B1,$C1,$B1,$C1,$B1,$C1,$B1,$C1,$5A,$62,$3C,$3C,
	DB $66,$66,$9D,$F9,$B9,$C1,$B9,$C1,$B9,$C1,$B1,$C1,$72,$42,$3C,$3C,
	DB $FF,$FF,$B1,$C1,$D9,$A1,$ED,$91,$B7,$89,$9B,$85,$8D,$83,$FF,$FF,
	DB $7E,$7E,$B9,$C1,$BD,$E5,$BD,$E5,$BD,$E5,$B9,$C1,$B9,$C1,$7E,$7E,
	DB $7E,$7E,$B9,$C1,$FB,$C3,$BD,$E5,$BD,$E5,$B9,$C1,$B9,$C1,$7E,$7E,
	DB $FF,$FF,$B9,$C1,$B9,$C1,$FF,$FF,$B9,$D9,$B9,$C1,$B9,$C1,$FF,$FF,

; positions of x and y values of sprites in each rotation
PiecePosData:
	; I pieces
	DB $00,$08
	DB $08,$08
	DB $10,$08
	DB $18,$08
	
	DB $08,$00
	DB $08,$08
	DB $08,$10
	DB $08,$18

	DB $00,$08
	DB $08,$08
	DB $10,$08
	DB $18,$08

	DB $08,$00
	DB $08,$08
	DB $08,$10
	DB $08,$18

	; J pieces
	DB $08,$08
	DB $08,$10
	DB $10,$10
	DB $18,$10

	DB $10,$00
	DB $10,$08
	DB $10,$10
	DB $08,$10

	DB $00,$08
	DB $08,$08
	DB $10,$08
	DB $10,$10

	DB $10,$08
	DB $08,$08
	DB $08,$10
	DB $08,$18

	; L pieces
	DB $00,$10
	DB $08,$10
	DB $10,$10
	DB $10,$08

	DB $08,$08
	DB $10,$08
	DB $10,$10
	DB $10,$18
	
	DB $08,$10
	DB $08,$08
	DB $10,$08
	DB $18,$08

	DB $08,$00
	DB $08,$08
	DB $08,$10
	DB $10,$10

	; O pieces
	DB $08,$00
	DB $10,$00
	DB $08,$08
	DB $10,$08

	DB $08,$00
	DB $10,$00
	DB $08,$08
	DB $10,$08
	
	DB $08,$00
	DB $10,$00
	DB $08,$08
	DB $10,$08

	DB $08,$00
	DB $10,$00
	DB $08,$08
	DB $10,$08

	; S pieces
	DB $00,$08
	DB $08,$08
	DB $08,$00
	DB $10,$00

	DB $08,$00
	DB $08,$08
	DB $10,$08
	DB $10,$10

	DB $00,$08
	DB $08,$08
	DB $08,$00
	DB $10,$00

	DB $08,$00
	DB $08,$08
	DB $10,$08
	DB $10,$10

	; Z pieces
	DB $00,$00
	DB $08,$00
	DB $08,$08
	DB $10,$08

	DB $10,$00
	DB $10,$08
	DB $08,$08
	DB $08,$10
	
	DB $00,$00
	DB $08,$00
	DB $08,$08
	DB $10,$08

	DB $10,$00
	DB $10,$08
	DB $08,$08
	DB $08,$10

	; T pieces
	DB $08,$00
	DB $00,$08
	DB $08,$08
	DB $10,$08

	DB $00,$08
	DB $08,$00
	DB $08,$08
	DB $08,$10

	DB $08,$10
	DB $00,$08
	DB $08,$08
	DB $10,$08

	DB $10,$08
	DB $08,$10
	DB $08,$08
	DB $08,$00

; posy at start of new piece
PieceStartHeight:
	DB $08, $00, $00, $08, $08, $08, $08, $00

; emoji bubbles for person
BubbleSpriteData:
	DB $07,$07,$0F,$08,$1F,$10,$1F,$11,$1F,$11,$1F,$11,$1F,$11,$1F,$11,
	DB $1F,$10,$1F,$10,$1F,$10,$3F,$20,$7F,$40,$FF,$C0,$3F,$30,$0F,$0F,
	DB $FC,$FC,$FE,$02,$FF,$F1,$CF,$39,$8F,$79,$8F,$79,$8F,$79,$8F,$79,
	DB $FF,$F1,$FF,$01,$FF,$F1,$DF,$B1,$FF,$F1,$FF,$01,$FE,$02,$FC,$FC,
	DB $07,$07,$0F,$08,$1F,$10,$1F,$10,$1F,$11,$1F,$12,$1F,$12,$1F,$12,
	DB $1F,$12,$1F,$12,$1F,$12,$3F,$21,$7F,$40,$FF,$C0,$3F,$30,$0F,$0F,
	DB $FC,$FC,$FE,$02,$FF,$01,$FF,$F1,$8F,$79,$07,$FD,$97,$FD,$97,$FD,
	DB $07,$FD,$97,$FD,$67,$FD,$8F,$79,$FF,$F1,$FF,$01,$FE,$02,$FC,$FC,
	DB $07,$07,$07,$08,$1F,$10,$1F,$11,$1F,$12,$1F,$14,$1E,$15,$1E,$15,
	DB $1E,$15,$1F,$12,$1F,$11,$3F,$20,$7F,$40,$FF,$C0,$3F,$30,$0F,$0F,
	DB $FC,$FC,$FE,$02,$FF,$01,$FF,$B1,$CF,$79,$47,$FD,$07,$FD,$07,$FD,
	DB $07,$FD,$0F,$F9,$9F,$71,$FF,$A1,$FF,$41,$FF,$01,$FE,$02,$FC,$FC,
	DB $07,$07,$0F,$08,$1F,$10,$1F,$12,$1F,$11,$1F,$11,$1F,$12,$1F,$14,
	DB $1F,$14,$1E,$15,$1E,$15,$3E,$23,$7F,$41,$FF,$C0,$3F,$30,$0F,$0F,
	DB $FC,$FC,$FC,$02,$FF,$11,$FF,$61,$FF,$A1,$FF,$25,$FF,$19,$9F,$69,
	DB $0F,$F5,$07,$FD,$07,$FD,$0F,$F9,$FF,$F1,$FF,$01,$FE,$02,$FC,$FC,

; classic mode text
ChallengeClassicData:
	DB "CLASSIC "
	DB "MODE    "
	DB "        "
	DB "        "

; text in top corner for challenge
ChallengeTextData:
	DB "PLACE   "
	DB "ALL     "
	DB "PIECES  "
	DB "        "

	DB "FINISH  "
	DB "ALL     "
	DB "LINES   "
	DB "        "

	DB "CLEAR   "
	DB "ALL     "
	DB "TRASH   "
	DB "        "

	DB "LOWER   "
	DB "TO      "
	DB "THIRD   "
	DB "ROW     "

; numbers to pre-set or reach for each game
; each has low, medium, high from affection
ChallengeSettingsPiecesData:
	; pieces - 50, 100, 200, 200
	DB $32, $64, $C8, $C8
ChallengeSettingsLinesData:
	; lines - 25, 50, 100, 100
	DB $19, $32, $64, $64
ChallengeSettingsTrashData:
	; trash - 4, 8, 16, 16
	DB $04, $08, $10, $10
ChallengeSettingsRowsData:
	; rows - 3, 5, 9, 9
	DB $04, $06, $0A, $0A

; added to affection score after success
AffectionLocationData:
	DB $04, $00, $08 ; Michael at Cafe, Library, and Park
	DB $08, $00, $04 ; Stephanie at Cafe, Library, and Park
	DB $00, $08, $04 ; George at Cafe, Library, and Park
	DB $00, $04, $08 ; Jessica at Cafe, Library, and Park

; added to affection score after success
AffectionChallengeData:
	DB $10, $1A, $24, $38 ; Pieces, Lines, Trash, and Rows

; menu cursor sprite data
MenuCursorData:
	DB $00,$00,$7F,$7F,$39,$26,$1C,$13,$1C,$13,$39,$26,$7F,$7F,$00,$00,
	DB $00,$00,$FC,$FC,$9E,$66,$CF,$33,$CF,$33,$9E,$66,$FC,$FC,$00,$00,

; menu palette switching
MenuCursorPalette:
	DB $E4, $D8, $E4, $D8

; menu star sprite data
MenuStarData:
	DB $00,$00,$00,$00,$10,$00,$28,$10,$10,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$10,$00,$28,$10,$54,$38,$28,$10,$10,$00,$00,$00,$00,$00,
	DB $10,$00,$28,$10,$54,$38,$AA,$6C,$54,$38,$28,$10,$10,$00,$00,$00,
	DB $00,$10,$44,$00,$00,$00,$00,$82,$00,$00,$44,$00,$00,$10,$00,$00,

; menu star x and y coordinates
MenuStarCoordData:
	DB $1F, $17
	DB $5B, $2B
	DB $19, $29
	DB $5F, $3D
	
; menu options text
MenuCharacterText:
	DB " HEY THERE...       "
	DB "    MICHAEL!        "
	DB "    STEPHANIE!      "
	DB "    GEORGE!         "
	DB "    JESSICA!        "

MenuLocationText:
	DB " WANNA GO TO THE... "
	DB "    CAFE?           "
	DB "    LIBRARY?        "
	DB "    PARK?           "
	DB "    ARCADE?         " ; classic mode

MenuChallengeText:
	DB " LETS TALK ABOUT... "
	DB "    GOING ALL IN.   "
	DB "    STAYING TRUE.   "
	DB "    LETTING GO.     "
	DB "    OPENING UP.     "

CharacterNameText:
	DB "       MICHAEL      "
	DB "      STEPHANIE     "
	DB "       GEORGE       "
	DB "       JESSICA      "


; ********
; Boy 1 Data
; ********

SceneDialogBoy1Affection:
	DB "OH HEY, YOU CAME!   "
	DB "COOL. SO WHAT'S THE "
	DB "PLAN TODAY? I'M     "
	DB "PRETTY CHILL.      ", $00

	DB "HEY, THERE YOU ARE! "
	DB "I WAS JUST THINKING "
	DB "ABOUT YOU. WEIRD?   "
	DB "NAH. LET'S HANG OUT", $40

	DB "THERE'S MY FAVORITE "
	DB "PERSON.  SORRY, THAT"
	DB "JUST SLIPPED OUT.   "
	DB "... NOT SORRY.     ", $80

SceneDialogBoy1Location:
	DB "OH NICE, THE CAFE!  "
	DB "I COULD GO FOR A    "
	DB "SNACK. OR THREE.    "
	DB "GOOD PICK.         ", $40

	DB "THE LIBRARY? HUH.   "
	DB "IT'S SO QUIET IN    "
	DB "HERE. IS IT OKAY TO "
	DB "EVEN WHISPER?      ", $00

	DB "THE PARK! YES! OKAY,"
	DB "THIS IS MY PLACE.   "
	DB "FRESH AIR, SUN, AND "
	DB "ZERO HOMEWORK.     ", $80

	DB "ARCADE! HECK YEAH!  "
	DB "NO PRESSURE HERE,   "
	DB "JUST US AND SOME    "
	DB "GOOD OLD GAMES.    ", $40

SceneDialogBoy1Challenge:
	DB "ALL IN? SURE, WHY   "
	DB "NOT! OVERTHINKING IS"
	DB "HOW YOU MISS OUT.   "
	DB "LET'S ROLL THE DICE", $40

	DB "STAYING TRUE, HUH?  "
	DB "EASY. I ONLY KNOW   "
	DB "HOW TO BE ME, SO    "
	DB "LET'S KEEP IT REAL.", $00

	DB "LETTING GO? THAT'S  "
	DB "KINDA MY SPECIALTY. "
	DB "STUFF PILES UP, YOU "
	DB "JUST NEED TO BREATH", $80

	DB "OPENING UP? OKAY.   "
	DB "I'LL GO FIRST: I'M  "
	DB "BAD AT THIS PART.   "
	DB "BUT I'LL TRY.      ", $00

SceneDialogBoy1Classic:
	DB "DEEP BREATH. LOOSEN "
	DB "UP. YOU'VE GOT THIS!"
	DB "AND IF IT ALL FALLS "
	DB "APART, IT WAS FUN. ", $40

SceneDialogBoy1EndClassic:
	DB "HA! THAT WAS A RIDE."
	DB "WIN, LOSE, WHATEVER,"
	DB "I HAD A BLAST. LET'S"
	DB "DO IT AGAIN!       ", $40

SceneDialogBoy1EndBad:
	DB "AW, MAN. I REALLY   "
	DB "THOUGHT WE HAD THAT "
	DB "ONE. BUMMER. I KNOW "
	DB "YOU'VE GOT MORE.   ", $00

SceneDialogBoy1EndGood:
	DB "HEY, NICE WORK! YOU "
	DB "TOTALLY PULLED THAT "
	DB "OFF. I'M IMPRESSED. "
	DB "SERIOUSLY!         ", $40

	DB "OKAY, I'M GONNA SAY "
	DB "IT: YOU'RE AWESOME. "
	DB "YOU MAKE EVERYTHING "
	DB "MORE FUN, FOR REAL.", $00

	DB "OK, NO JOKE, THIS   "
	DB "TIME. YOU'RE THE    "
	DB "BEST PART OF MY DAY."
	DB "EVERY. SINGLE. DAY.", $00

SceneDialogBoy1EndSecond:
	DB "TODAY WAS A GOOD DAY"
	DB "HANGING WITH YOU IS "
	DB "EASY. IN A GOOD WAY."
	DB "LET'S DO IT AGAIN. ", $00

	DB "I USUALLY DON'T GET "
	DB "EXCITED ABOUT PLANS."
	DB "BUT WITH YOU, I'M   "
	DB "ALWAYS EXCITED.    ", $80

	DB "I THINK I'M FALLING "
	DB "FOR YOU. OKAY, I'M  "
	DB "IN LOVE WITH YOU.   "
	DB "IS THAT OK? ...    ", $80

; ********
; Girl 1 Data
; ********

SceneDialogGirl1Affection:
	DB "PERFECT, YOU CAME.  "
	DB "I ALWAYS GET WHAT I "
	DB "WANT. LET'S SEE IF  "
	DB "YOU'RE WORTH IT.   ", $00

	DB "RIGHT ON TIME. GOOD."
	DB "MY FRIENDS ASK ABOUT"
	DB "YOU. I'VE MADE QUITE"
	DB "THE CHOICE! :)     ", $40

	DB "I WANT YOUR COMPANY "
	DB "MORE THAN ANYTHING. "
	DB "STAY CLOSE TO ME, I "
	DB "INSIST...          ", $80

SceneDialogGirl1Location:
	DB "MY FAVORITE CAFE!   "
	DB "THEY KNOW MY ORDER. "
	DB "GET WHATEVER YOU    "
	DB "LIKE, I'M BUYING.  ", $80

	DB "THE LIBRARY. REALLY?"
	DB "NOBODY HERE TO SEE  "
	DB "US. FINE. BE BRIEF. "
	DB "I DON'T WHISPER.   ", $00

	DB "THE PARK? NOT BAD.  "
	DB "SUN SUITS ME, AND   "
	DB "A STROLL SUITS YOU! "
	DB "WALK WITH ME.      ", $40

	DB "THE ARCADE! NOW WE  "
	DB "PLAY. I NEVER LOSE, "
	DB "SO DON'T TAKE IT    "
	DB "PERSONALLY. <3     ", $40

SceneDialogGirl1Challenge:
	DB "ALL IN? BOLD MOVE.  "
	DB "I DON'T GAMBLE. I   "
	DB "ONLY BACK WINNERS.  "
	DB "DON'T DISAPPOINT.  ", $40

	DB "STAYING TRUE? YES.  "
	DB "I EXPECT LOYALTY,   "
	DB "AND I REWARD IT.    "
	DB "GENEROUSLY...  ;D  ", $80

	DB "LET GO? OF WHAT? OH,"
	DB "THE CLUTTER. OUT IT "
	DB "GOES. I KEEP ONLY   "
	DB "WHAT I WANT.       ", $00

	DB "OPENING UP? HM. I   "
	DB "DON'T, AS A RULE.   "
	DB "CONSIDER THIS A     "
	DB "PRIVILEGE.         ", $00

SceneDialogGirl1Classic:
	DB "CHIN UP! I PICKED   "
	DB "YOU, SO NO PRESSURE."
	DB "WELL, A LITTLE BIT. "
	DB "SHOW ME SOMETHING! ", $40

SceneDialogGirl1EndClassic:
	DB "WELL PLAYED, REALLY."
	DB "YOU'RE A QUICK STUDY"
	DB "AND I'M AN EXCELLENT"
	DB "COACH. AGAIN SOON. ", $40

SceneDialogGirl1EndBad:
	DB "HM. THAT WASN'T IT. "
	DB "I'M DISAPPOINTED.   "
	DB "I CHOSE YOU TO WIN. "
	DB "DO BETTER. >(      ", $00

SceneDialogGirl1EndGood:
	DB "WELL, WELL. NOT BAD."
	DB "I DID WONDER IF YOU "
	DB "YOU WERE WORTH IT.  "
	DB "... YOU ARE. =)    ", $40

	DB "EVERYONE SAW THAT.  "
	DB "THEY'RE ALL JEALOUS."
	DB "OF ME, NATURALLY.   "
	DB "AND YOU. A LITTLE. ", $00

	DB "I'LL SAY THIS ONCE. "
	DB "I DIDN'T EXPECT TO  "
	DB "FALL FOR MY OWN PICK"
	DB "BUT HERE WE ARE.   ", $80

SceneDialogGirl1EndSecond:
	DB "DON'T GET COCKY.    "
	DB "BUT I'LL ALLOW A    "
	DB "LITTLE PRIDE. COME  "
	DB "BACK, I'M NOT DONE.", $00

	DB "I DON'T COMPLIMENT  "
	DB "LIGHTLY, SO LISTEN: "
	DB "I CHOSE WELL. DON'T "
	DB "FORGET THIS. :>    ", $80

	DB "I LOVE YOU. THERE.  "
	DB "DON'T LOOK SO SMUG. "
	DB "I ALWAYS GET WHAT I "
	DB "WANT. STAY WITH ME.", $80

; ********
; Boy 2 Data
; ********

SceneDialogBoy2Affection:
	DB "OH! H-HI. YOU CAME. "
	DB "I, UM... WASN'T SURE"
	DB "YOU'D ACTUALLY SHOW."
	DB "SO... SHALL WE?    ", $00

	DB "HEY! YOU'RE HERE. I "
	DB "SAVED US A SPOT. I  "
	DB "WAS KINDA HOPING YOU"
	DB "WOULD PICK TODAY.  ", $40

	DB "HI, YOU. I WAS JUST "
	DB "THINKING ABOUT YOU. "
	DB "HA, SORRY! TOO MUCH?"
	DB "...I'M GLAD ITS YOU", $80

SceneDialogBoy2Location:
	DB "THE CAFE? OH. OKAY. "
	DB "IT'S KINDA LOUD, AND"
	DB "I ALWAYS MESS UP... "
	DB "BUT, I'LL TRY!     ", $00

	DB "THE LIBRARY! YES!   "
	DB "I LOVE THE QUIET AND"
	DB "THE SMELL OF BOOKS. "
	DB "IS THAT WEIRD?     ", $80

	DB "OOH, THE PARK! NICE."
	DB "FRESH AIR COULD HELP"
	DB "ME RELAX. A LITTLE. "
	DB "LEAD THE WAY!      ", $40

	DB "THE ARCADE! AWESOME!"
	DB "NO PRESSURE, JUST   "
	DB "FUN. I'M ACTUALLY   "
	DB "GOOD AT THIS!      ", $40

SceneDialogBoy2Challenge:
	DB "ALL IN? WHOA. OKAY. "
	DB "I USUALLY OVERTHINK "
	DB "EVERYTHING FIRST... "
	DB "HERE GOES NOTHING! ", $40

	DB "STAYING TRUE, HUH?  "
	DB "I'M NOT GREAT AT BIG"
	DB "SPEECHES, BUT I MEAN"
	DB "WHAT I SAY. ALWAYS.", $80

	DB "LETTING GO... HM. I "
	DB "HOLD ONTO STUFF. OLD"
	DB "WORRIES, MOSTLY.    "
	DB "LET'S CLEAR IT OUT.", $00

	DB "OPENING UP? ME?     "
	DB "*GULP* I'M A BIT... "
	DB "GUARDED. BUT WITH   "
	DB "YOU, I'LL TRY.     ", $00

SceneDialogBoy2Classic:
	DB "OKAY, DEEP BREATH.  "
	DB "FUN FACT: I ALWAYS  "
	DB "SAY SORRY TO THINGS "
	DB "I MISS. LET'S GO!  ", $40

SceneDialogBoy2EndClassic:
	DB "HA! THAT WAS GREAT. "
	DB "YOU MADE IT LOOK    "
	DB "EASY. I'D HAVE LOST "
	DB "MY NERVE. NICE WORK", $40

SceneDialogBoy2EndBad:
	DB "OH... THAT DIDN'T GO"
	DB "HOW I HOPED. I'M A  "
	DB "LITTLE BUMMED, BUT  "
	DB "LET'S TRY AGAIN?   ", $00

SceneDialogBoy2EndGood:
	DB "YOU DID IT! WOW. I  "
	DB "WAS SO NERVOUS...   "
	DB "BUT THIS WAS GREAT. "
	DB "THANK YOU FOR TODAY", $40

	DB "THAT WAS PERFECT.   "
	DB "I'D FORGOTTEN TO BE "
	DB "NERVOUS. YOU DO THAT"
	DB "TO ME, YOU KNOW?   ", $00

	DB "OKAY. NO STAMMERING."
	DB "JUST THE TRUTH. I   "
	DB "THINK OF YOU ALL DAY"
	DB "EVERY DAY.         ", $00

SceneDialogBoy2EndSecond:
	DB "CAN I BE HONEST? I  "
	DB "DIDN'T THINK I'D    "
	DB "HAVE THIS MUCH FUN. "
	DB "LET'S DO THIS AGAIN", $80

	DB "I DON'T WANT TODAY  "
	DB "TO BE OVER YET. YOU "
	DB "MAKE BE BRAVER, AND "
	DB "I LIKE THAT.       ", $80

	DB "I'M IN LOVE WITH YOU"
	DB "THERE. I SAID IT. MY"
	DB "HEART IS RACING. AND"
	DB "I'M NOT SORRY.     ", $80

; ********
; Girl 2 Data
; ********

SceneDialogGirl2Affection:
	DB "HI! I WAS CURIOUS   "
	DB "ABOUT YOU. WHAT DO  "
	DB "YOU LIKE TO DO WHEN "
	DB "YOU HAVE FREE TIME?", $00

	DB "I'VE BEEN WONDERING "
	DB "HOW YOU'VE BEEN     "
	DB "SINCE WE LAST TALKED"
	DB "... LOOKING GOOD!  ", $40

	DB "WHAT'S ON YOUR MIND "
	DB "TODAY? I'D LOVE TO  "
	DB "HEAR ALL OF IT, EVEN"
	DB "THE SMALL THINGS.  ", $80

SceneDialogGirl2Location:
	DB "IT'S A LITTLE LOUD, "
	DB "IN THE CAFE, OH WELL"
	DB "WHAT ARE YOU IN THE "
	DB "MOOD FOR TODAY?    ", $00

	DB "NICE, THE LIBRARY.  "
	DB "WHAT STORIES DO YOU "
	DB "USUALLY GET LOST IN?"
	DB "I'D LOVE TO KNOW.  ", $40

	DB "THE PARK! GOOD PICK."
	DB "GOT A FAVORITE SPOT?"
	DB "SHOW ME. I'D LOVE TO"
	DB "IT WITH YOU.       ", $80

	DB "OOH, THE ARCADE!    "
	DB "WHICH GAME IS YOUR  "
	DB "FAVORITE? BRING ME. "
	DB "I'LL CHEER YOU ON! ", $40

SceneDialogGirl2Challenge:
	DB "ALL IN? THAT TAKES  "
	DB "TRUST. I FEEL THAT I"
	DB "CAN TRUST YOU. TELL "
	DB "ME MORE...         ", $80

	DB "STAYING TRUE? PEOPLE"
	DB "CAN ALWAYS FEEL WHEN"
	DB "IT'S REAL! WHAT DOES"
	DB "IT MEAN TO YOU?    ", $40

	DB "LETTING GO IS HARD. "
	DB "WE CARRY THINGS SO  "
	DB "LONG THEY FEL LIKE  "
	DB "PART OF US. READY? ", $00

	DB "OPENING UP TAKES    "
	DB "COURAGE. WHERE'D YOU"
	DB "WANT TO BEGIN? TAKE "
	DB "YOUR TIME, I'M HERE", $00

SceneDialogGirl2Classic:
	DB "READY WHEN YOU ARE. "
	DB "I'VE GOT A GOOD     "
	DB "FEELING ABOUT YOU.  "
	DB "GO HAVE FUN!       ", $40

SceneDialogGirl2EndClassic:
	DB "WELL, THAT WAS A    "
	DB "GOOD ONE. I'D BUY A "
	DB "TICKET TO SEE THAT  "
	DB "AGAIN. ROUND TWO?  ", $40

SceneDialogGirl2EndBad:
	DB "OH... THAT GOT AWAY "
	DB "FROM YOU. I'D HOPED "
	DB "WE'D GET FURTHER.   "
	DB "TRY AGAIN? YOU CAN.", $00

SceneDialogGirl2EndGood:
	DB "YOU DID IT! I KNEW  "
	DB "YOU COULD. THAT WAS "
	DB "REALLY SOMETHING I  "
	DB "ENJOYED WITH YOU.  ", $40

	DB "THAT WAS WONDERFUL. "
	DB "YOU DON'T GIVE UP,  "
	DB "DO YOU? I REALLY    "
	DB "ADMIRE THAT IN YOU.", $00

	DB "TODAY WENT BY SO    "
	DB "FAST. I DIDN'T WANT "
	DB "TO END. YOU MAKE    "
	DB "EVERY MOMENT BETTER", $80

SceneDialogGirl2EndSecond:
	DB "TODAY WAS LOVELY. I "
	DB "WOULD LIKE TO KNOW  "
	DB "YOU BETTER. COME    "
	DB "AGAIN SOON, MAYBE? ", $80

	DB "EVERY TIME, I FIND  "
	DB "SOMETHING NEW I LIKE"
	DB "ABOUT YOU. WHAT WILL"
	DB "IT BE NEXT TIME?   ", $80

	DB "I THINK I'M IN LOVE "
	DB "WITH YOU. ACTUALLY, "
	DB "I'M SURE OF IT. IS  "
	DB "THAT OKAY WITH YOU?", $80

; ********
; Author Data
; ********

AuthorData:
	DB "  TETRA HEARTS WAS  "
	DB "CREATED BY PROFESSOR"
	DB " STEVEN CHAD BURROW "
	DB "CODE AND ARTWORK ARE"
	DB "   PUBLIC DOMAIN    "


SECTION "HigherData", ROMX[$4000], BANK[1]

; ****************
; ****************
; HIGHER DATA SECTION
; ****************
; ****************

; 64x64 character models, 3 separate images for each character
CharacterData1:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,
	DB $00,$00,$00,$00,$02,$01,$05,$03,$00,$07,$63,$07,$67,$FF,$3F,$7F,
	DB $00,$00,$80,$00,$04,$83,$97,$0F,$5F,$3F,$7F,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$F0,$00,$D0,$E0,$F0,$FF,$FF,$FF,$FF,$FF,$DF,$FF,$C3,$FF,
	DB $00,$00,$00,$00,$60,$00,$00,$C0,$83,$C0,$C3,$FE,$FC,$FE,$F8,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$00,$01,$03,$03,$07,$17,$0F,$0F,$07,$0F,$07,$17,$0F,$5F,$3F,
	DB $7F,$FF,$CF,$FF,$FF,$FF,$EF,$FF,$C7,$FF,$CF,$FF,$D3,$FF,$E1,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$FF,$FF,$FC,
	DB $ED,$F3,$FB,$E7,$CB,$FF,$D7,$EF,$17,$EF,$97,$EF,$2B,$DF,$8F,$7F,
	DB $FE,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$80,$00,$84,$F8,$F0,$F8,$E8,$F0,$D0,$E0,$E0,$C0,$D0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $5F,$3F,$2F,$1F,$0F,$1F,$3F,$1F,$1F,$3F,$0F,$3F,$27,$0F,$07,$0F,
	DB $F1,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FE,$FD,$FE,$FD,$FE,$FC,$FE,
	DB $FC,$FF,$CF,$FF,$4B,$87,$83,$07,$07,$03,$07,$03,$01,$03,$01,$03,
	DB $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E7,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $F4,$F8,$F4,$F8,$F0,$E0,$E0,$F0,$F4,$F8,$FA,$FC,$F8,$F0,$E0,$F0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $07,$0F,$0B,$07,$01,$03,$01,$03,$04,$03,$00,$01,$00,$01,$01,$00,
	DB $FE,$FF,$FF,$FF,$FF,$F8,$75,$FB,$F1,$FF,$3D,$F0,$B9,$70,$38,$F0,
	DB $60,$83,$EB,$F0,$75,$F8,$E5,$F8,$64,$F8,$CC,$E0,$20,$C0,$00,$00,
	DB $FF,$E7,$FF,$FF,$78,$FF,$BF,$7F,$9E,$7F,$7C,$0E,$0B,$04,$07,$00,
	DB $FF,$FF,$FF,$FF,$7F,$FF,$3F,$FF,$FF,$FF,$3A,$FF,$F8,$3F,$7B,$3E,
	DB $C8,$F0,$E8,$C0,$C0,$E0,$E0,$C0,$60,$C0,$00,$40,$40,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $50,$B8,$A0,$58,$44,$28,$0C,$38,$38,$1C,$28,$1C,$3E,$0C,$04,$0E,
	DB $00,$00,$00,$00,$04,$00,$07,$00,$04,$03,$03,$00,$00,$00,$0F,$00,
	DB $00,$00,$00,$00,$80,$00,$80,$00,$80,$00,$00,$00,$01,$00,$E0,$01,
	DB $70,$3E,$60,$3C,$14,$68,$E8,$70,$E0,$70,$68,$F0,$D8,$E0,$E0,$C0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$02,$01,$0B,$07,$2F,$1F,$5F,$3F,$3F,$7F,$FF,$7F,$CF,$7F,
	DB $2E,$1F,$3F,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE,$FF,
	DB $0E,$00,$07,$80,$80,$C0,$50,$E0,$68,$F0,$9B,$7C,$CF,$3F,$E7,$1F,
	DB $61,$03,$03,$07,$07,$0F,$0D,$1F,$59,$3F,$71,$FF,$F5,$FB,$C5,$FB,
	DB $C0,$E0,$E1,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$40,$80,$D0,$E0,$F0,$F8,$FC,$F8,$F8,$FC,$E8,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$02,$01,$01,$03,$07,$03,$03,$07,$0F,$07,$0F,$1F,$1F,$3F,
	DB $67,$FF,$E3,$FF,$F3,$FF,$39,$FF,$0C,$FF,$86,$FF,$C3,$FF,$F1,$FF,
	DB $FE,$FF,$FE,$FF,$B8,$FF,$B1,$FE,$F9,$FE,$7A,$FC,$31,$FE,$9C,$FB,
	DB $53,$0F,$68,$07,$67,$00,$31,$00,$30,$00,$38,$00,$D8,$00,$C4,$38,
	DB $0D,$F3,$19,$E7,$79,$87,$E4,$0B,$16,$09,$1A,$01,$2A,$11,$20,$1F,
	DB $FF,$FF,$FF,$FF,$3F,$FF,$3B,$FF,$3B,$FF,$9E,$7F,$1C,$FF,$58,$BF,
	DB $CC,$FE,$CE,$FF,$9F,$FF,$1F,$FF,$33,$FF,$63,$FF,$47,$FF,$8F,$FF,
	DB $00,$00,$00,$00,$80,$00,$00,$80,$C0,$80,$D0,$E0,$F0,$F8,$F8,$FC,
	DB $79,$3F,$70,$3F,$70,$3F,$78,$3F,$68,$3F,$4C,$3F,$2E,$00,$00,$00,
	DB $F8,$FF,$FE,$FF,$3F,$FF,$3F,$FF,$BF,$FF,$FF,$FF,$FF,$00,$00,$00,
	DB $C9,$FC,$64,$FE,$37,$FE,$FA,$FF,$FD,$FF,$F7,$FF,$F7,$00,$00,$00,
	DB $F0,$0C,$7E,$00,$1F,$00,$80,$00,$00,$80,$40,$80,$C0,$00,$00,$00,
	DB $5D,$22,$FE,$00,$F0,$00,$00,$00,$01,$00,$02,$01,$01,$00,$00,$00,
	DB $79,$3F,$33,$7F,$E6,$7F,$4F,$FF,$9F,$FF,$6F,$FF,$6F,$00,$00,$00,
	DB $1F,$FF,$7F,$FF,$FE,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$00,$00,$00,
	DB $98,$FC,$08,$FC,$08,$FC,$08,$FC,$98,$FC,$90,$FC,$B4,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$0C,$04,$0F,$02,$07,
	DB $00,$00,$14,$08,$50,$38,$21,$70,$85,$73,$67,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$02,$FC,$FE,$FF,$FF,$FF,$FB,$FF,$FC,$FF,
	DB $00,$00,$00,$00,$04,$00,$12,$0C,$18,$FC,$FC,$F8,$FA,$FC,$FE,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$74,$88,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$05,$03,
	DB $17,$0F,$59,$3F,$B8,$7F,$3E,$FD,$38,$7F,$79,$FE,$FE,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$3F,$FF,$3F,$FF,$7F,$FF,
	DB $FE,$FF,$FD,$FE,$FE,$FF,$FA,$FD,$F1,$FE,$86,$F9,$90,$EF,$85,$FF,
	DB $BF,$7F,$1F,$FF,$BF,$7F,$3F,$FF,$7F,$FF,$7F,$FF,$3F,$FF,$BF,$FF,
	DB $F0,$F8,$E0,$F0,$C0,$E0,$E8,$F0,$F4,$F8,$FD,$FE,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$00,$10,$E0,$C0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $05,$03,$00,$01,$03,$01,$01,$03,$04,$03,$05,$00,$00,$01,$00,$01,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,
	DB $E0,$FF,$D1,$E0,$A0,$C0,$C0,$80,$00,$80,$20,$C0,$E8,$F0,$DA,$3C,
	DB $F7,$FF,$7F,$FF,$7F,$FF,$FF,$7F,$FF,$7F,$3F,$7F,$FD,$7F,$9F,$7D,
	DB $DF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $80,$C0,$00,$80,$00,$00,$00,$00,$00,$80,$80,$C0,$A0,$C0,$80,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $7F,$FE,$1D,$7E,$0C,$7F,$FE,$7D,$29,$DC,$78,$9C,$C8,$3C,$B0,$5C,
	DB $7D,$0E,$73,$FE,$19,$FE,$1B,$7C,$50,$38,$70,$00,$00,$00,$02,$00,
	DB $DA,$3D,$1F,$3F,$4F,$3F,$60,$1F,$37,$0F,$0C,$03,$01,$03,$04,$03,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$4F,$FF,$FF,$CF,$EF,$FF,$F7,$BF,$07,$BF,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$FC,$FE,$FC,$FE,$FC,$FE,$FC,$FE,$74,$FE,
	DB $00,$80,$C0,$80,$80,$C0,$00,$C0,$00,$40,$40,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $24,$58,$48,$24,$38,$04,$04,$18,$18,$0C,$18,$0C,$0E,$1C,$0C,$1E,
	DB $02,$00,$06,$00,$01,$06,$04,$03,$63,$00,$1F,$60,$41,$20,$30,$00,
	DB $01,$00,$80,$00,$C0,$00,$40,$80,$80,$00,$00,$00,$E8,$00,$20,$18,
	DB $FF,$0F,$1F,$0F,$2E,$1F,$2A,$1F,$26,$1F,$4C,$3F,$4C,$33,$68,$36,
	DB $A2,$F4,$F4,$E0,$40,$E0,$60,$C0,$00,$C0,$40,$80,$80,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$01,$0B,$07,
	DB $07,$0E,$06,$0F,$17,$0F,$1E,$07,$2C,$1F,$BD,$7E,$FC,$FE,$FC,$FE,
	DB $00,$00,$01,$00,$8F,$00,$0E,$80,$80,$C0,$60,$C0,$6F,$F0,$BF,$7F,
	DB $08,$30,$E1,$00,$02,$01,$05,$03,$17,$0F,$5C,$3F,$78,$FF,$F3,$FD,
	DB $BC,$78,$70,$F8,$F0,$F8,$FE,$F8,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$10,$E0,$F4,$F8,$FA,$FC,$FC,$FE,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $17,$0F,$07,$1F,$37,$1F,$0F,$3F,$0F,$3F,$2E,$7F,$EE,$7F,$6C,$FF,
	DB $FC,$FE,$FC,$FE,$FC,$FE,$BF,$FE,$7F,$FE,$FF,$FE,$FF,$FE,$F9,$FE,
	DB $DF,$3F,$EF,$1F,$50,$0F,$6A,$05,$69,$06,$0E,$00,$01,$00,$01,$00,
	DB $C1,$FF,$01,$FF,$0D,$F3,$18,$E7,$A8,$47,$C9,$07,$96,$0F,$1C,$0F,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$F0,$FF,$E1,$FF,$83,$FF,$0C,$FF,$20,$FF,
	DB $EC,$FE,$9F,$FE,$3E,$FF,$7F,$FF,$FF,$FF,$87,$FF,$03,$FF,$0F,$FF,
	DB $00,$00,$00,$00,$00,$00,$40,$80,$A0,$C0,$C0,$E0,$C0,$E0,$F0,$E0,
	DB $01,$00,$00,$01,$05,$03,$07,$0F,$0D,$1F,$19,$3F,$7B,$3F,$20,$1F,
	DB $A6,$FF,$B6,$FF,$F6,$FF,$F3,$FF,$FB,$FF,$FB,$FF,$FD,$FF,$00,$FF,
	DB $D1,$FE,$D3,$FC,$95,$F8,$AE,$D1,$99,$C0,$EF,$80,$E1,$80,$40,$80,
	DB $03,$00,$86,$00,$8C,$00,$96,$09,$BD,$03,$FA,$07,$CF,$07,$08,$07,
	DB $00,$3F,$23,$7F,$4E,$FF,$98,$FF,$33,$FF,$FF,$FF,$FF,$FF,$40,$BF,
	DB $80,$FF,$03,$FF,$0F,$FF,$7F,$FF,$FE,$FF,$FC,$FF,$FB,$FF,$00,$FF,
	DB $7F,$FF,$FF,$FF,$FF,$FF,$83,$FF,$07,$FF,$1E,$FF,$78,$FF,$00,$FF,
	DB $E0,$F0,$E0,$F0,$E0,$F0,$F0,$F8,$F8,$FC,$7C,$FE,$3C,$FE,$02,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$00,$0C,$06,
	DB $00,$00,$00,$00,$0A,$04,$08,$1C,$10,$38,$31,$78,$DD,$73,$5F,$FF,
	DB $00,$00,$00,$00,$00,$00,$06,$01,$47,$3F,$7F,$FF,$E3,$FF,$FE,$FF,
	DB $00,$00,$00,$00,$08,$00,$00,$F8,$F7,$F8,$FF,$FF,$FF,$FF,$0F,$FF,
	DB $00,$00,$00,$00,$00,$00,$28,$10,$20,$F0,$E0,$F0,$F0,$E0,$F0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $02,$07,$03,$07,$0B,$07,$2F,$1F,$7E,$3F,$9D,$7F,$99,$3F,$3C,$7F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FE,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$F8,$FF,$FD,$FE,$FE,$FF,$F8,$FF,
	DB $9F,$7F,$6F,$9F,$4F,$BF,$0F,$FF,$FF,$FF,$BF,$7F,$BF,$7F,$3F,$FF,
	DB $F4,$F8,$FD,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$28,$10,$20,$F0,$F0,$E0,$C0,$E0,$80,$C0,$00,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$01,$00,$02,$01,$07,$03,$04,$03,$00,$00,$01,$00,$00,$01,
	DB $FD,$7E,$7C,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$9F,$7F,$9F,$7F,$1F,$FF,$FC,$FF,$F5,$F8,$E8,$F0,
	DB $F3,$FC,$CE,$F9,$15,$EF,$47,$BF,$BF,$FF,$FF,$FF,$7F,$FF,$FF,$7F,
	DB $5F,$FF,$6F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $A0,$C0,$D0,$E0,$E8,$F0,$A8,$D0,$80,$C0,$C0,$E0,$F0,$E0,$C0,$B0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$01,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$FF,$7F,$3F,$7F,$3F,$7F,$3F,$7F,$2F,$5F,$5F,$0F,$07,$0F,
	DB $E0,$F0,$F0,$E0,$D0,$E0,$E6,$F8,$FE,$FF,$FB,$E7,$D8,$E7,$C7,$FF,
	DB $FF,$7F,$3F,$7F,$7F,$3F,$6F,$3F,$5F,$AF,$A6,$CF,$24,$CF,$B7,$C8,
	DB $FF,$FF,$7F,$FF,$FF,$FF,$AF,$DF,$1E,$FF,$FA,$FF,$37,$F8,$07,$38,
	DB $FF,$FF,$FB,$FF,$FF,$FF,$F9,$FF,$F4,$FB,$FC,$FB,$69,$FE,$54,$FA,
	DB $10,$80,$00,$80,$00,$80,$00,$80,$40,$80,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$0F,$09,$03,$03,$01,$00,$01,$01,$00,$00,$00,$0E,$01,$4F,$3F,
	DB $CB,$F7,$C8,$F3,$FF,$E0,$7F,$E0,$2F,$F0,$AF,$50,$78,$F0,$F0,$F8,
	DB $F0,$80,$10,$80,$D0,$00,$F0,$00,$F0,$00,$B0,$00,$2F,$10,$12,$0C,
	DB $7F,$00,$7F,$00,$7F,$00,$3F,$00,$00,$00,$00,$00,$00,$00,$01,$00,
	DB $4A,$F4,$A8,$44,$94,$68,$B0,$78,$F0,$78,$F8,$7C,$72,$FC,$FC,$F0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$01,$00,$00,$01,$00,$01,$03,$01,$01,$03,$03,$07,$07,$0F,
	DB $FF,$7F,$FF,$FF,$9F,$FF,$87,$FF,$C1,$FF,$F0,$FF,$FC,$FF,$5E,$FF,
	DB $FC,$F8,$F8,$FC,$FC,$FE,$FE,$FF,$FF,$FF,$7F,$FF,$1F,$FF,$0F,$FF,
	DB $0C,$00,$37,$00,$3F,$00,$87,$00,$47,$80,$C0,$E0,$68,$F0,$3B,$FC,
	DB $70,$01,$E3,$01,$85,$03,$82,$07,$06,$0F,$0D,$1E,$1D,$3E,$B8,$7F,
	DB $FC,$FE,$FE,$FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$80,$00,$80,$C0,$D0,$E0,$F8,$F0,$FC,$F8,$F8,$FC,$E8,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $1E,$0F,$0C,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$1F,$3F,$7E,$3F,$7F,$3F,
	DB $03,$FF,$00,$FF,$00,$FF,$E0,$FF,$F8,$FF,$FF,$FF,$0F,$FF,$03,$FF,
	DB $83,$FF,$E1,$FF,$30,$FF,$0C,$FF,$06,$FF,$01,$FF,$C0,$FF,$F8,$FF,
	DB $5F,$BF,$EF,$9F,$97,$CF,$58,$E7,$24,$F3,$93,$F8,$CB,$FC,$65,$FE,
	DB $F0,$FF,$E2,$FD,$D2,$ED,$26,$D9,$0E,$F1,$98,$63,$08,$03,$98,$03,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$BE,$FF,$1E,$FF,$0E,$FF,$96,$7F,$B7,$7F,
	DB $EC,$FE,$EF,$FE,$EE,$FF,$CF,$FF,$CF,$FF,$DF,$FF,$DF,$FF,$9F,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$80,$A0,$C0,$E0,$F0,$F4,$F8,$F8,$FC,
	DB $79,$3F,$60,$3F,$60,$3F,$60,$3F,$60,$3F,$60,$3F,$60,$3F,$40,$3F,
	DB $81,$FF,$60,$FF,$30,$FF,$18,$FF,$0C,$FF,$0C,$FF,$07,$FF,$00,$FF,
	DB $FC,$FF,$FF,$FF,$3F,$FF,$9F,$FF,$CF,$FF,$E7,$FF,$77,$FF,$00,$FF,
	DB $32,$FF,$19,$FF,$CD,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FD,$FF,$02,$FD,
	DB $DC,$03,$25,$C2,$F6,$80,$AB,$D0,$5F,$E0,$C0,$E0,$F0,$E0,$10,$E0,
	DB $0F,$F7,$13,$27,$6B,$07,$CE,$07,$0E,$07,$0F,$07,$17,$0F,$08,$07,
	DB $BF,$FF,$3F,$FF,$7F,$FF,$7F,$FF,$FF,$FF,$BF,$FF,$DF,$FF,$20,$DF,
	DB $D8,$FC,$88,$FC,$88,$FC,$B8,$FC,$F8,$FC,$F8,$FC,$F8,$FC,$04,$F8,

CharacterData2:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$03,$07,$07,$0E,$0F,
	DB $00,$00,$00,$00,$10,$0F,$3F,$7F,$E0,$FF,$80,$FF,$0F,$FF,$18,$FF,
	DB $00,$00,$00,$00,$80,$00,$DD,$FE,$FF,$FF,$7C,$FF,$FC,$FF,$7F,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$C0,$80,$C0,$E0,$60,$F0,$90,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,
	DB $1C,$1F,$18,$3F,$30,$3F,$75,$7F,$FA,$7F,$76,$FF,$EC,$FF,$F8,$FF,
	DB $00,$FF,$41,$FE,$82,$FD,$57,$AB,$FB,$07,$27,$DF,$17,$FF,$17,$FF,
	DB $FC,$FF,$38,$FF,$9F,$FF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $68,$FC,$16,$FC,$0E,$FE,$06,$FF,$27,$DF,$8B,$EF,$DF,$A7,$BB,$C7,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$C0,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$01,$09,$01,$0D,$0B,$07,$0F,$27,$07,$13,$33,$1E,$1F,$07,$0F,
	DB $F0,$FF,$E0,$FF,$E8,$FF,$98,$FF,$F4,$FF,$C8,$FF,$31,$FF,$E3,$FF,
	DB $1F,$FC,$18,$FC,$18,$FC,$5C,$F8,$D8,$FC,$B4,$EC,$BC,$FC,$F7,$EE,
	DB $26,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$03,$06,$0F,
	DB $C3,$FF,$41,$FF,$E0,$7F,$72,$7F,$31,$7F,$79,$3F,$78,$FF,$BC,$7F,
	DB $80,$C0,$C0,$C0,$C0,$C0,$42,$E0,$64,$FE,$F8,$FC,$F0,$E0,$33,$F1,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $07,$0F,$06,$0F,$03,$07,$07,$03,$07,$07,$07,$07,$0F,$0F,$0F,$1F,
	DB $87,$FF,$1F,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$CD,$FE,$F4,$EE,$EA,$F4,
	DB $DB,$E4,$FA,$FC,$FE,$FC,$7E,$B8,$40,$B8,$30,$00,$00,$00,$00,$00,
	DB $13,$0C,$1B,$07,$16,$0F,$0B,$07,$04,$03,$01,$00,$00,$00,$00,$00,
	DB $EE,$1F,$DF,$EF,$EF,$FF,$7F,$BF,$69,$9F,$99,$1F,$17,$1B,$3F,$17,
	DB $8A,$FF,$EC,$FE,$FC,$F8,$FC,$F8,$FD,$FE,$F6,$FF,$F0,$F0,$F8,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$03,$02,$03,$02,$06,
	DB $3F,$1F,$7F,$3F,$FF,$7F,$FF,$DF,$9F,$BF,$BF,$3F,$3F,$7F,$7F,$7F,
	DB $F5,$FA,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$DF,$FF,
	DB $00,$00,$00,$00,$00,$00,$80,$00,$C3,$80,$E0,$C0,$F0,$E0,$F0,$F8,
	DB $A0,$00,$E0,$00,$00,$00,$20,$00,$F0,$00,$41,$00,$01,$03,$03,$07,
	DB $07,$3F,$3F,$3F,$77,$3F,$3F,$7F,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FC,$F8,$EC,$FC,$EC,$F6,$F3,$F6,$FB,$F3,$F1,$F9,$F9,$F8,$FC,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$80,$80,$C0,$C0,$E0,$C0,
	DB $06,$06,$07,$06,$03,$07,$03,$03,$01,$00,$00,$00,$00,$00,$00,$00,
	DB $7F,$7F,$FF,$5F,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$7F,$7F,$FF,$FF,$FF,
	DB $DF,$FF,$CF,$FF,$E7,$FF,$F3,$FF,$D9,$FF,$C0,$FF,$E0,$FF,$F2,$FD,
	DB $EE,$FC,$F7,$EF,$F9,$E7,$FE,$E1,$DF,$E0,$DB,$E4,$5D,$E2,$2C,$F3,
	DB $1F,$0F,$3F,$FF,$F7,$FF,$D7,$EF,$B7,$4F,$FF,$0F,$FF,$0F,$FF,$0F,
	DB $FE,$FF,$FE,$FF,$FA,$FF,$F9,$FF,$FD,$FF,$FC,$FF,$FE,$FF,$1F,$FF,
	DB $FC,$FC,$FE,$FC,$7C,$FE,$7E,$FE,$FF,$FE,$3F,$FF,$5F,$BF,$2F,$DF,
	DB $60,$E0,$F0,$60,$E0,$70,$F0,$70,$70,$F0,$F0,$F0,$E0,$F0,$E0,$E0,
	DB $00,$01,$03,$01,$07,$03,$2F,$07,$1F,$3F,$0F,$1F,$1F,$1F,$3F,$1F,
	DB $FF,$FF,$FE,$FF,$FC,$F8,$FE,$F0,$E2,$E0,$E0,$C0,$C0,$C0,$C0,$C0,
	DB $FB,$FC,$FC,$FF,$FE,$7F,$07,$3F,$0B,$07,$05,$03,$03,$01,$00,$01,
	DB $56,$F9,$3F,$F8,$3F,$FC,$9D,$FE,$DF,$FE,$CF,$FF,$DE,$FF,$DF,$FF,
	DB $F1,$0F,$67,$98,$6F,$90,$9A,$65,$87,$38,$57,$80,$96,$61,$A1,$1E,
	DB $FF,$CF,$6F,$F7,$B3,$7F,$35,$DB,$C1,$37,$23,$CF,$0A,$9F,$7F,$1F,
	DB $0F,$FF,$A7,$FF,$B7,$FF,$B7,$FF,$37,$FF,$7F,$FF,$FF,$FF,$FB,$FD,
	DB $E0,$C0,$C0,$C0,$C0,$E0,$F9,$F2,$FE,$FE,$FC,$F0,$F8,$F0,$F8,$F8,
	DB $0F,$1F,$1F,$1F,$3F,$1F,$3F,$1F,$3F,$1F,$3F,$17,$1F,$1F,$10,$0F,
	DB $80,$C0,$C0,$80,$E0,$80,$C0,$80,$C0,$80,$C0,$80,$A0,$C0,$40,$80,
	DB $11,$00,$8B,$00,$07,$08,$23,$05,$33,$07,$1B,$07,$0B,$07,$04,$03,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$F8,$FC,$F0,$F8,$F0,$E0,$E0,$C0,$C0,$00,
	DB $E8,$00,$9C,$03,$2D,$C2,$90,$60,$27,$18,$09,$06,$03,$00,$00,$00,
	DB $7F,$8F,$E9,$1F,$ED,$13,$57,$2F,$AE,$47,$40,$80,$00,$00,$00,$00,
	DB $FF,$F9,$EE,$F1,$DE,$E1,$4E,$F1,$AA,$75,$46,$39,$3E,$19,$17,$08,
	DB $FC,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$FC,$FC,$FC,$F8,$FC,$00,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$03,$0E,$07,$0C,$1F,
	DB $00,$00,$00,$00,$00,$00,$2C,$1E,$7F,$FF,$81,$FF,$3F,$FF,$E7,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$F4,$F8,$FF,$FE,$F1,$FF,$FE,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$C0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$03,$03,$03,
	DB $18,$3F,$35,$7B,$E6,$7B,$C5,$FE,$C3,$FC,$AD,$FA,$D0,$FF,$A0,$FF,
	DB $81,$FF,$0C,$F3,$16,$EF,$DF,$2F,$7F,$1F,$9F,$7F,$1F,$FF,$1D,$FE,
	DB $F1,$FF,$F0,$FF,$7E,$FF,$7C,$FF,$BE,$FF,$FE,$FF,$FE,$FF,$0F,$FF,
	DB $F0,$E0,$70,$F0,$38,$F8,$18,$FC,$4E,$BC,$76,$9E,$CF,$1E,$2F,$DF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $07,$03,$03,$07,$07,$07,$07,$07,$8E,$27,$7C,$DF,$77,$7F,$1E,$3F,
	DB $E0,$FF,$C0,$FF,$90,$FF,$A0,$FF,$62,$FF,$D2,$FF,$A2,$FF,$66,$FF,
	DB $58,$F0,$60,$F0,$60,$F0,$60,$F0,$70,$F0,$10,$F0,$FC,$F8,$E0,$9C,
	DB $05,$03,$02,$01,$01,$00,$00,$00,$00,$00,$08,$07,$0C,$1F,$0C,$10,
	DB $87,$FF,$83,$FF,$C3,$FF,$E5,$FF,$66,$FF,$73,$FF,$F3,$FF,$B8,$7F,
	DB $00,$00,$00,$80,$80,$80,$80,$80,$80,$C0,$D4,$EC,$F8,$F8,$C0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $1C,$0F,$C3,$BF,$FE,$FF,$7C,$3F,$33,$3F,$3F,$1F,$0F,$1F,$1F,$1F,
	DB $CF,$FF,$9F,$FF,$3F,$FF,$7F,$FF,$FF,$FE,$FF,$FE,$FB,$FC,$BC,$F8,
	DB $6C,$90,$F4,$F8,$F8,$F8,$AC,$D0,$60,$F0,$90,$60,$C0,$00,$00,$00,
	DB $31,$0F,$37,$0F,$1A,$0D,$07,$0F,$09,$07,$47,$00,$00,$00,$20,$00,
	DB $58,$BF,$DF,$FF,$5F,$FF,$3F,$7F,$3F,$5F,$BB,$1F,$33,$1F,$37,$1B,
	DB $60,$E2,$16,$FE,$DC,$FC,$F0,$F8,$F0,$F0,$F8,$F8,$FE,$FF,$F2,$EC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,$07,$03,
	DB $1F,$1F,$1F,$3F,$3F,$3F,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$7F,
	DB $9C,$F8,$D4,$B8,$A4,$D8,$CA,$E4,$E4,$FE,$FF,$FE,$FF,$FF,$FF,$FF,
	DB $01,$00,$00,$00,$00,$00,$1F,$00,$0E,$0C,$00,$06,$01,$00,$C0,$80,
	DB $A0,$40,$40,$00,$24,$00,$98,$0C,$28,$18,$08,$10,$20,$00,$E0,$01,
	DB $13,$3F,$0F,$37,$1F,$2F,$7F,$3F,$3F,$7F,$FF,$7F,$FF,$FF,$FF,$FF,
	DB $E0,$E0,$E0,$F0,$F0,$F0,$F0,$F8,$F8,$F8,$F8,$FC,$FE,$FC,$FE,$F6,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $06,$06,$0C,$0C,$1C,$09,$19,$19,$1B,$11,$19,$33,$1F,$3B,$1F,$1F,
	DB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$7F,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$BF,$FF,$9F,$FF,$CF,$FF,$67,$FF,$33,$FF,$81,$FF,
	DB $E0,$C0,$F8,$F0,$DE,$FC,$E7,$DF,$F3,$CF,$F2,$CD,$FF,$C0,$BF,$C0,
	DB $03,$03,$0F,$07,$0F,$1F,$3F,$FF,$FF,$FF,$FF,$EF,$3F,$CF,$FF,$0F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FC,$FF,$FE,$FF,$FE,$FF,$FB,$FF,$FD,$FF,
	DB $FF,$F3,$F9,$FB,$F8,$F9,$F8,$FC,$FC,$FC,$FE,$FC,$7C,$FE,$FE,$FE,
	DB $00,$00,$00,$80,$80,$C0,$E0,$C0,$E0,$60,$60,$70,$70,$70,$38,$70,
	DB $1F,$0F,$07,$03,$03,$03,$07,$03,$07,$07,$07,$0F,$1F,$0F,$DF,$3F,
	DB $FF,$FF,$FF,$FF,$F9,$FF,$F9,$F0,$C0,$E0,$C0,$C0,$C0,$80,$80,$80,
	DB $C0,$FF,$E6,$F9,$FB,$FC,$FC,$FF,$7F,$3F,$17,$0F,$03,$07,$01,$03,
	DB $FB,$C4,$7B,$E4,$7D,$F2,$3C,$FB,$3A,$FD,$9F,$FC,$DE,$FF,$CF,$FF,
	DB $FF,$0F,$EF,$1F,$EF,$1F,$EE,$1F,$E3,$1F,$66,$99,$6F,$90,$98,$67,
	DB $FC,$FF,$FE,$FF,$FF,$FF,$5F,$BF,$BF,$CF,$FF,$E7,$B1,$7F,$31,$DB,
	DB $7F,$FE,$5F,$BF,$2F,$DF,$1F,$EF,$A7,$FF,$B7,$FF,$B7,$FF,$B7,$FF,
	DB $70,$78,$70,$78,$F8,$F0,$F0,$F0,$E0,$E0,$E0,$C0,$F0,$E6,$FC,$FC,
	DB $FF,$7F,$3F,$7F,$7F,$7F,$7F,$7F,$3E,$7F,$7E,$3F,$3E,$7F,$3F,$7F,
	DB $00,$80,$80,$00,$80,$00,$C0,$00,$40,$00,$20,$00,$90,$00,$80,$00,
	DB $13,$01,$08,$01,$0D,$00,$00,$04,$20,$06,$13,$02,$09,$03,$05,$03,
	DB $CF,$FF,$EF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$FC,$F8,
	DB $C7,$38,$FF,$80,$1F,$E0,$20,$9F,$EA,$04,$F8,$01,$38,$C7,$1F,$60,
	DB $D5,$33,$8B,$67,$4D,$9F,$2F,$1F,$BF,$4F,$4F,$99,$E5,$1B,$DF,$27,
	DB $3F,$FF,$7F,$FF,$FF,$FF,$FD,$FB,$F3,$F9,$FF,$E1,$DE,$E1,$4E,$F1,
	DB $F8,$E0,$F0,$E0,$F0,$F0,$F8,$F0,$F0,$F8,$F8,$F8,$F8,$F8,$F8,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,
	DB $00,$00,$00,$00,$00,$00,$05,$03,$1F,$0F,$7C,$3F,$F8,$7F,$E4,$FB,
	DB $00,$00,$00,$00,$7C,$00,$FE,$FF,$87,$FF,$01,$FF,$18,$FF,$7F,$FF,
	DB $00,$00,$00,$00,$00,$00,$80,$00,$A0,$C0,$F4,$F8,$FC,$FE,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,
	DB $01,$03,$07,$03,$0F,$07,$0E,$0F,$1F,$0F,$1E,$1F,$3F,$1F,$3F,$3F,
	DB $C6,$F9,$80,$FF,$4F,$FC,$9D,$F8,$25,$FA,$41,$FE,$80,$FF,$00,$FF,
	DB $81,$FF,$03,$FF,$01,$FF,$D8,$27,$2E,$5F,$1F,$FF,$BF,$FF,$3F,$FF,
	DB $FB,$FF,$F9,$FF,$FE,$FF,$F3,$FF,$F0,$FF,$FC,$FF,$F6,$FF,$F8,$FF,
	DB $80,$80,$80,$C0,$E0,$C0,$60,$E0,$E0,$F0,$F0,$F0,$78,$F0,$B8,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$03,$03,$01,$01,$01,$0C,$08,$05,$0E,$03,$07,$03,$03,$07,$03,
	DB $7E,$3F,$78,$FF,$E3,$FF,$FC,$FF,$71,$FF,$8E,$FF,$F8,$FF,$01,$FF,
	DB $41,$FF,$81,$FF,$01,$FF,$8B,$FF,$1B,$FF,$14,$FF,$77,$FF,$EF,$F9,
	DB $7F,$FF,$F2,$C1,$80,$C0,$80,$C0,$C0,$80,$80,$80,$80,$80,$80,$C0,
	DB $F9,$FE,$F9,$FE,$7B,$3C,$0C,$1F,$14,$0F,$04,$0F,$06,$0F,$06,$0F,
	DB $38,$F8,$FC,$78,$F8,$7C,$38,$FC,$3C,$FC,$3C,$FC,$1C,$FC,$5C,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$01,$01,$01,$03,$01,$03,$03,$07,$03,$07,$07,$0F,$0F,$1F,$1F,
	DB $CF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E7,$FF,$FC,$F7,$FD,$F2,$FC,$FB,
	DB $D5,$F8,$FC,$FF,$FE,$FF,$EF,$DF,$E0,$1E,$FC,$00,$78,$00,$7C,$00,
	DB $20,$C0,$C1,$00,$C2,$01,$83,$00,$86,$01,$01,$03,$01,$01,$01,$00,
	DB $06,$0F,$D7,$EF,$1F,$FF,$CF,$0F,$DB,$E7,$FB,$F7,$DB,$FF,$4F,$DF,
	DB $6C,$FC,$3C,$FE,$3E,$FF,$1F,$FF,$AC,$FE,$F2,$FF,$F9,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$40,$C0,$80,$80,$20,$00,$40,$E0,$80,$C0,$80,$00,
	DB $00,$00,$00,$00,$00,$00,$01,$01,$01,$03,$03,$03,$07,$02,$03,$06,
	DB $37,$3F,$77,$6F,$EF,$CF,$CF,$9F,$1F,$9F,$1F,$3F,$3F,$3F,$7F,$3F,
	DB $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$BF,$FF,
	DB $00,$00,$00,$00,$00,$00,$84,$00,$86,$80,$81,$C0,$E0,$C0,$F0,$E0,
	DB $10,$00,$1B,$00,$61,$10,$20,$00,$00,$00,$B8,$00,$70,$00,$01,$00,
	DB $E7,$1F,$FD,$0F,$E9,$1F,$33,$1F,$17,$3F,$7F,$3F,$7F,$7F,$FF,$FF,
	DB $FE,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FE,$FD,
	DB $00,$00,$20,$C0,$80,$C0,$00,$00,$00,$00,$00,$00,$80,$80,$80,$C0,
	DB $06,$07,$03,$07,$07,$03,$03,$01,$00,$00,$00,$00,$00,$00,$01,$00,
	DB $3F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$7F,$FF,$FF,$FF,$FF,
	DB $BF,$FF,$9F,$FF,$9F,$FF,$5F,$FF,$4F,$FF,$8F,$FF,$87,$FF,$F7,$CF,
	DB $D8,$F0,$DC,$F8,$CD,$FE,$D7,$EF,$DF,$E3,$DE,$E1,$DF,$E0,$EF,$F0,
	DB $01,$03,$17,$0F,$BF,$7F,$E7,$FF,$8C,$FF,$DB,$3E,$BD,$7E,$B8,$7F,
	DB $FF,$FF,$F7,$FF,$8F,$FF,$0F,$FF,$9A,$7C,$F8,$70,$F0,$E0,$E0,$C0,
	DB $FC,$FE,$FE,$FE,$FF,$FE,$FF,$FF,$1F,$3F,$1F,$0F,$07,$0F,$07,$07,
	DB $C0,$E0,$60,$70,$78,$30,$38,$38,$1C,$38,$1C,$BC,$9C,$BC,$FC,$FC,
	DB $03,$01,$07,$03,$27,$1F,$1F,$0F,$0F,$0F,$1F,$1F,$1F,$0F,$1F,$0F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$FF,$E1,$F0,$C1,$E0,$C0,$C0,
	DB $C7,$EF,$E7,$FF,$F7,$FE,$F9,$FC,$72,$F8,$B0,$70,$70,$20,$20,$40,
	DB $A7,$D8,$17,$8C,$72,$3F,$E1,$03,$11,$0F,$32,$01,$18,$07,$1C,$01,
	DB $F9,$7F,$73,$FF,$F3,$FF,$F7,$FF,$FE,$FF,$FF,$FE,$FF,$FE,$FF,$FE,
	DB $80,$C0,$80,$80,$80,$00,$10,$00,$20,$00,$60,$00,$80,$40,$00,$C0,
	DB $07,$03,$07,$03,$03,$03,$01,$03,$05,$03,$05,$03,$0D,$03,$0D,$03,
	DB $FC,$FC,$FC,$F8,$F0,$F8,$F0,$F0,$F0,$F8,$FC,$F8,$FE,$FC,$FE,$FE,
	DB $1F,$1F,$1F,$1F,$3F,$1F,$3F,$17,$17,$17,$07,$1B,$0B,$0F,$07,$0F,
	DB $80,$C0,$C0,$80,$81,$80,$22,$81,$85,$02,$93,$02,$92,$02,$90,$0E,
	DB $80,$40,$00,$80,$80,$00,$00,$00,$00,$00,$00,$01,$0A,$07,$04,$0E,
	DB $07,$00,$17,$0F,$35,$1B,$76,$23,$E2,$47,$CE,$87,$9D,$0E,$1A,$1C,
	DB $FE,$FF,$BF,$FF,$0F,$FF,$3F,$CF,$79,$9F,$9F,$03,$0E,$03,$13,$06,
	DB $C0,$80,$90,$80,$20,$80,$80,$40,$01,$80,$82,$00,$18,$00,$60,$00,
	DB $1F,$03,$17,$03,$23,$07,$4B,$07,$0B,$07,$1F,$07,$3F,$07,$77,$0F,
	DB $F6,$FE,$F2,$FF,$FA,$FB,$FB,$FA,$F6,$FA,$FC,$FE,$FC,$FC,$FC,$F8,

CharacterData3:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$06,$03,$01,$03,$03,$01,$27,$7F,$3F,$3F,$1F,$3F,
	DB $00,$00,$07,$00,$9B,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,
	DB $00,$00,$00,$00,$EA,$F4,$FE,$FF,$FF,$FF,$FF,$FF,$8F,$FF,$3F,$FF,
	DB $00,$00,$00,$00,$20,$00,$10,$30,$D0,$98,$FC,$D8,$F9,$FD,$FD,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $02,$04,$07,$07,$03,$03,$01,$01,$03,$01,$03,$07,$17,$0F,$0F,$1F,
	DB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FE,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $7F,$FF,$0F,$FF,$3F,$FF,$8F,$FF,$8F,$FF,$9F,$FF,$BC,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FF,$97,$FF,$DF,$FF,
	DB $80,$00,$C0,$C0,$F0,$E0,$C0,$F0,$C0,$E0,$F0,$E0,$F0,$F0,$F0,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$07,$07,$07,$07,$0F,$0F,$0F,$1F,$0B,$03,$03,$03,$03,$03,$07,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FF,$FC,$FF,$F9,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$DB,$FD,$B9,$D0,$80,$00,$70,$80,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$DB,$FC,$58,$B0,$30,$00,$00,$00,$0E,$01,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$7F,$AF,$5F,$1F,$0F,$C7,$EF,
	DB $F8,$F8,$E8,$F0,$F0,$F0,$F8,$F0,$F8,$F0,$E0,$F0,$E0,$E0,$F0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $05,$00,$01,$00,$00,$00,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$FF,$FF,$FF,$FD,$FF,$BB,$FF,$FA,$FE,$FE,$F8,$39,$FC,$75,$FE,
	DB $F8,$FC,$FE,$FC,$FE,$FF,$FB,$FF,$72,$FF,$F3,$76,$57,$26,$F3,$0C,
	DB $3F,$1F,$1F,$3F,$FF,$3F,$EF,$FF,$73,$EF,$77,$23,$22,$31,$17,$18,
	DB $FF,$F7,$07,$FF,$DF,$FF,$CE,$FF,$EF,$BE,$37,$8F,$0B,$17,$CF,$37,
	DB $E0,$C0,$C0,$C0,$C0,$C0,$00,$60,$80,$E0,$00,$E0,$C0,$20,$20,$A0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $7C,$FB,$BC,$F8,$58,$FC,$18,$6C,$1E,$3C,$16,$0C,$06,$06,$07,$02,
	DB $0B,$F0,$05,$02,$05,$02,$07,$02,$01,$03,$02,$01,$00,$00,$03,$00,
	DB $00,$0F,$00,$00,$00,$00,$E0,$00,$20,$C0,$40,$80,$00,$00,$E0,$00,
	DB $2F,$C5,$0E,$07,$05,$0E,$08,$0D,$1E,$0F,$1A,$0C,$08,$18,$38,$18,
	DB $40,$A0,$E0,$40,$00,$C0,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$03,$03,$03,$03,$01,$01,$01,$01,$01,$03,$07,$07,$0F,$0F,$1F,
	DB $8B,$04,$00,$80,$81,$C0,$C0,$E0,$E0,$F0,$F0,$F8,$BA,$FC,$BF,$FF,
	DB $C8,$30,$00,$00,$20,$C0,$80,$01,$01,$03,$03,$07,$1E,$0F,$FD,$FE,
	DB $18,$30,$30,$70,$60,$F0,$80,$F0,$DC,$B8,$1E,$BC,$9B,$3E,$1B,$3D,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$07,$03,$1F,$0F,$3B,$7F,
	DB $17,$1F,$17,$3F,$27,$3F,$3F,$67,$DB,$E7,$C3,$E7,$F9,$C3,$BB,$D9,
	DB $9F,$FF,$9B,$FF,$80,$FF,$80,$FF,$90,$EF,$99,$E7,$8C,$F3,$0B,$F0,
	DB $F2,$FC,$E4,$F8,$08,$F0,$10,$E0,$20,$C0,$40,$80,$44,$80,$48,$80,
	DB $19,$3D,$1D,$39,$18,$39,$10,$39,$18,$31,$70,$21,$51,$60,$38,$D8,
	DB $80,$00,$00,$80,$80,$80,$E0,$C0,$60,$F0,$5C,$F8,$EF,$46,$63,$D1,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,
	DB $03,$01,$0F,$07,$1C,$1F,$30,$3F,$22,$3C,$28,$3C,$38,$00,$00,$00,
	DB $E7,$FF,$01,$FF,$39,$C7,$85,$03,$05,$03,$0A,$01,$00,$00,$00,$00,
	DB $B8,$FD,$BF,$FC,$7F,$FE,$7F,$FF,$CF,$FF,$07,$FF,$07,$00,$00,$00,
	DB $81,$F8,$B4,$C8,$40,$FC,$22,$7C,$E5,$B2,$D3,$F8,$D8,$00,$00,$00,
	DB $89,$00,$1B,$01,$37,$02,$0C,$37,$61,$0F,$CB,$1F,$17,$00,$00,$00,
	DB $F8,$BC,$FE,$7C,$7C,$FE,$FF,$FE,$CF,$FF,$06,$F9,$00,$00,$00,$00,
	DB $1E,$C0,$1F,$C0,$10,$C0,$00,$C0,$80,$80,$80,$00,$00,$00,$00,$00,
	DB $E0,$70,$3C,$18,$7C,$06,$14,$02,$0A,$04,$1C,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$08,$04,$07,$07,$03,$03,$05,$03,
	DB $00,$00,$00,$00,$01,$06,$03,$03,$5F,$3F,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$F0,$01,$FA,$FD,$FF,$FF,$F7,$FF,$FF,$FF,$1F,$FF,
	DB $00,$00,$00,$00,$00,$00,$C8,$84,$C6,$E4,$F6,$F6,$FF,$FE,$FE,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$00,$60,$40,$C0,$C0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$01,$07,$07,
	DB $0F,$1F,$7F,$3F,$7F,$FF,$BF,$1F,$7F,$3F,$FF,$7F,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $3F,$FF,$3F,$FF,$1F,$FF,$0F,$FF,$43,$FF,$CE,$FF,$DE,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FF,$65,$FF,$EF,$FF,$FF,$FF,
	DB $C0,$E0,$F0,$F8,$FC,$FC,$FE,$F0,$F8,$F8,$FC,$FC,$FC,$FE,$FF,$FE,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$03,$01,$00,$01,$01,$01,$03,$07,$03,$0F,$07,$05,$03,$01,$03,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$FF,$D8,$F6,$80,$F0,
	DB $FF,$FF,$FF,$FF,$ED,$FE,$FA,$CC,$D0,$88,$82,$01,$03,$07,$07,$0F,
	DB $BF,$FF,$5F,$BF,$3F,$1F,$0B,$17,$49,$33,$FB,$FD,$C4,$FF,$C3,$FF,
	DB $FF,$FF,$FD,$FE,$FE,$FE,$FE,$FE,$FF,$FE,$FE,$FF,$FC,$FC,$FC,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $04,$03,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$1F,$6F,
	DB $B8,$C7,$3F,$FF,$FF,$FF,$FE,$FF,$9F,$FF,$2D,$FF,$06,$EF,$E3,$84,
	DB $0F,$07,$15,$8F,$BA,$FD,$EE,$FC,$EE,$C4,$66,$C3,$E2,$41,$B0,$C0,
	DB $FB,$F3,$F9,$FF,$78,$F7,$73,$72,$68,$06,$40,$BC,$30,$C0,$00,$00,
	DB $F4,$FC,$F8,$E6,$59,$EE,$D0,$7F,$FC,$73,$DE,$79,$2C,$5B,$52,$3A,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $0B,$0F,$07,$0F,$07,$0F,$05,$0F,$05,$0F,$05,$07,$06,$03,$03,$01,
	DB $8D,$C3,$CA,$FC,$B0,$C0,$80,$C0,$E0,$C0,$C0,$E0,$F0,$E0,$20,$F0,
	DB $E4,$00,$46,$20,$59,$26,$52,$3C,$24,$18,$03,$00,$1E,$00,$F0,$00,
	DB $00,$00,$00,$00,$00,$00,$08,$00,$68,$18,$F0,$18,$30,$10,$10,$20,
	DB $40,$36,$2C,$44,$1C,$68,$38,$70,$20,$70,$60,$70,$F0,$70,$60,$F0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $F8,$F0,$70,$18,$1C,$08,$06,$0C,$06,$07,$03,$07,$03,$03,$01,$03,
	DB $E0,$C0,$70,$20,$1D,$00,$06,$01,$03,$00,$C0,$80,$C0,$E0,$F9,$F0,
	DB $21,$00,$C1,$01,$81,$03,$87,$03,$0E,$07,$0D,$0E,$3A,$1C,$B0,$7C,
	DB $E0,$E0,$A0,$E0,$20,$E0,$E0,$20,$78,$30,$7E,$3C,$7B,$3E,$7B,$3D,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$03,$01,
	DB $01,$03,$03,$07,$1F,$0F,$1F,$3F,$6F,$7F,$8F,$FF,$DF,$3F,$0F,$BF,
	DB $7F,$FF,$3F,$FF,$3F,$FF,$52,$BF,$90,$FF,$80,$FF,$A2,$DC,$D1,$EE,
	DB $E4,$F8,$C8,$F0,$90,$E0,$20,$C0,$40,$80,$83,$01,$17,$02,$32,$0C,
	DB $5F,$39,$5B,$39,$11,$33,$34,$63,$41,$C6,$09,$86,$0B,$04,$04,$09,
	DB $80,$00,$00,$80,$80,$80,$C0,$80,$40,$C0,$40,$E0,$F0,$F0,$F8,$9C,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$01,$00,$07,$03,$06,$0F,$08,$1F,$3D,$1E,$0E,$30,
	DB $03,$07,$2F,$1F,$7F,$FF,$87,$FF,$07,$FF,$D7,$0F,$17,$0F,$19,$06,
	DB $A7,$DF,$E7,$DF,$D6,$EF,$FE,$E7,$F3,$F7,$F3,$FB,$FB,$FD,$83,$7C,
	DB $D1,$EE,$D8,$E6,$14,$E0,$00,$F0,$00,$F0,$0B,$F1,$6D,$93,$41,$82,
	DB $23,$1E,$57,$3F,$3F,$6F,$EF,$5F,$9F,$FF,$3F,$FF,$79,$FF,$7E,$81,
	DB $0B,$01,$81,$03,$07,$82,$CC,$86,$86,$CC,$E8,$CC,$EC,$F8,$40,$B0,
	DB $47,$8E,$55,$23,$55,$08,$56,$20,$C1,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$C0,$80,$50,$E0,$50,$38,$9C,$0C,$68,$06,$3A,$04,$04,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$08,$0C,$0F,$07,$07,$37,$4F,$7F,$3F,
	DB $00,$00,$00,$00,$13,$1C,$0F,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$E3,$02,$F3,$FD,$FF,$FF,$CF,$FF,$9F,$FF,$BF,$FF,
	DB $00,$00,$00,$00,$18,$00,$18,$88,$EC,$CC,$F6,$EC,$FC,$FE,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$C0,$C0,$C0,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $0D,$06,$07,$07,$07,$03,$01,$01,$03,$01,$03,$07,$07,$0F,$2F,$DF,
	DB $BF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,
	DB $E0,$FF,$F1,$FF,$F0,$FF,$F8,$FF,$E0,$FF,$4E,$FF,$FE,$FF,$FC,$FF,
	DB $0F,$FF,$FF,$FF,$3F,$FF,$7F,$FF,$3F,$FF,$1F,$FF,$3F,$FF,$76,$FF,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$F9,$FF,$F4,$FF,$57,$FF,$5F,$FF,
	DB $A0,$C0,$F8,$F0,$FC,$F8,$E8,$F4,$F8,$F0,$F8,$F8,$FC,$FC,$FE,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$7F,$7F,$3F,$0F,$1F,$0F,$1F,$1F,$3F,$3F,$7F,$7F,$FF,$2F,$1F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $F9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$FF,$FA,$F7,
	DB $F6,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F5,$FB,$AB,$F1,$53,$81,$81,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$BF,$FF,$7F,$9F,$9F,$0F,
	DB $FE,$FE,$FF,$FE,$FC,$FC,$FE,$FC,$FC,$FE,$FC,$FE,$F8,$FC,$F8,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $1F,$1F,$1F,$3F,$3F,$3F,$7B,$37,$43,$27,$07,$07,$06,$07,$00,$04,
	DB $FF,$FF,$FE,$FF,$FE,$FF,$FF,$FE,$F9,$FE,$F3,$FF,$FF,$FF,$FF,$FF,
	DB $F7,$E0,$E0,$C0,$00,$C0,$03,$00,$92,$61,$E9,$F0,$F6,$F9,$FF,$FF,
	DB $05,$03,$2F,$1F,$7C,$FF,$FE,$FF,$7F,$FF,$DF,$FF,$FB,$97,$90,$C3,
	DB $CF,$E7,$1B,$E7,$4F,$FF,$7F,$BF,$95,$FB,$FB,$F1,$B1,$91,$81,$30,
	DB $F8,$FC,$CA,$E4,$CA,$DE,$B9,$D6,$E5,$B2,$F1,$BA,$D1,$BA,$12,$BA,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$7B,$3F,$3F,$3E,$1C,$3F,$3C,$1E,$1E,$1F,$0E,$1F,$0A,$0F,
	DB $FD,$FE,$7E,$FC,$7E,$74,$56,$2C,$E8,$1E,$68,$F6,$78,$86,$F8,$06,
	DB $41,$C0,$FD,$63,$39,$1E,$0F,$00,$0F,$00,$00,$00,$00,$00,$90,$60,
	DB $B0,$60,$B8,$C0,$F0,$00,$F0,$00,$C0,$00,$00,$00,$00,$00,$01,$00,
	DB $60,$36,$6C,$04,$DC,$08,$90,$78,$70,$F0,$70,$F0,$F0,$F0,$A0,$F0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $0F,$07,$07,$03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FB,$07,$E5,$83,$81,$C0,$E0,$40,$32,$61,$18,$30,$0C,$18,$0C,$06,
	DB $20,$C0,$40,$81,$8C,$03,$7C,$00,$60,$80,$34,$08,$28,$10,$00,$00,
	DB $80,$01,$03,$81,$01,$03,$03,$07,$0E,$07,$1D,$0E,$2C,$1E,$1A,$3C,
	DB $F0,$A0,$D0,$A0,$00,$B0,$90,$30,$BA,$1C,$3B,$1E,$3F,$1D,$3E,$1D,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$0F,$1F,$3F,$E0,$7F,
	DB $00,$00,$00,$00,$00,$00,$00,$01,$03,$0F,$FF,$FE,$BD,$FF,$1B,$FF,
	DB $06,$0F,$3F,$1F,$67,$7F,$CF,$FF,$1F,$FF,$9F,$7F,$5F,$BF,$CF,$BF,
	DB $80,$00,$C1,$80,$DD,$E3,$FF,$FF,$BF,$FF,$BC,$FF,$90,$FF,$98,$FF,
	DB $32,$7C,$64,$F8,$C4,$F8,$8C,$F0,$18,$E0,$38,$C0,$38,$C1,$F6,$03,
	DB $2D,$1C,$28,$1D,$08,$19,$3A,$11,$72,$21,$60,$C3,$81,$82,$06,$00,
	DB $80,$80,$80,$80,$80,$C0,$40,$C0,$C0,$60,$F0,$70,$5C,$F8,$94,$CE,
	DB $01,$00,$01,$01,$03,$03,$02,$07,$0E,$07,$0C,$0F,$1C,$0F,$02,$1D,
	DB $8D,$F0,$50,$A0,$E0,$00,$A1,$40,$02,$C1,$28,$C7,$D0,$EF,$3F,$C0,
	DB $DB,$3F,$57,$3F,$97,$7F,$3F,$FF,$11,$FF,$70,$8F,$18,$E7,$E7,$00,
	DB $EE,$9F,$AC,$DF,$EC,$DF,$FC,$EF,$E4,$FF,$FD,$F6,$76,$FF,$A5,$5A,
	DB $C8,$FF,$C0,$FF,$51,$EE,$1F,$E0,$53,$E0,$15,$63,$9B,$27,$9D,$02,
	DB $FD,$06,$DB,$0F,$B7,$1F,$FF,$2F,$6F,$DF,$DF,$BF,$79,$FF,$BF,$40,
	DB $85,$00,$03,$81,$C1,$83,$87,$C2,$E2,$C6,$CE,$E4,$F4,$EC,$54,$A8,
	DB $E0,$86,$38,$80,$2C,$10,$42,$20,$40,$00,$00,$00,$00,$00,$00,$00,

CharacterData4:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,
	DB $00,$00,$03,$00,$0A,$05,$2F,$1F,$1F,$7F,$3F,$FF,$7F,$FF,$FF,$FF,
	DB $00,$00,$80,$40,$22,$F1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$70,$80,$E0,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$A0,$C0,$D0,$E0,$E8,$F0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$03,$07,$03,$07,$07,$0F,$07,$0F,$0F,$1F,$0F,$1F,$1F,$3F,$1F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$FF,$FC,$FF,$FE,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$5F,$FF,$13,$FC,$E8,$F0,
	DB $FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FC,$FF,$F1,$FF,$DF,$3F,$0F,$1F,
	DB $FC,$F8,$FC,$FC,$FE,$FC,$7E,$FE,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $2F,$3F,$3F,$2F,$5F,$2F,$2F,$5F,$1F,$5F,$3F,$5F,$1F,$7F,$3F,$7F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,
	DB $E0,$F0,$F0,$E0,$C0,$E0,$C0,$E0,$E0,$C0,$80,$C0,$80,$80,$C8,$F0,
	DB $1F,$0F,$0F,$0F,$07,$0F,$05,$0B,$0C,$09,$11,$08,$10,$00,$13,$0F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,
	DB $40,$80,$40,$80,$40,$80,$80,$C0,$C0,$80,$80,$80,$80,$C0,$80,$C0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $7F,$3F,$3F,$3F,$3F,$3F,$7F,$3F,$3F,$7F,$7F,$7F,$FF,$7F,$DF,$BF,
	DB $FE,$FF,$F3,$FC,$FF,$FF,$FF,$FF,$F5,$FE,$F6,$F8,$F3,$F8,$F8,$F8,
	DB $7C,$F8,$C4,$38,$FA,$FC,$FD,$FE,$FB,$F7,$F2,$E7,$A4,$46,$8E,$04,
	DB $1E,$3F,$03,$3C,$5F,$3F,$3F,$FF,$CF,$FF,$6E,$C7,$41,$66,$61,$20,
	DB $BF,$7F,$FF,$1F,$FF,$FF,$FF,$FF,$EF,$7F,$2F,$5F,$DF,$1F,$3F,$1F,
	DB $C0,$80,$60,$80,$C0,$00,$00,$C0,$C0,$80,$80,$80,$80,$80,$00,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$00,$01,$01,$01,$01,$02,$01,$03,$00,$03,$00,$03,$01,$01,$01,
	DB $9F,$BF,$BF,$3F,$3F,$3F,$3F,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,
	DB $7A,$FC,$33,$FF,$BF,$F8,$DC,$F8,$F8,$FC,$FE,$FC,$FC,$FE,$FF,$FE,
	DB $18,$0C,$F2,$F8,$E2,$00,$04,$03,$02,$01,$01,$00,$03,$00,$0B,$04,
	DB $18,$30,$4F,$1F,$47,$00,$00,$C0,$40,$80,$80,$00,$00,$00,$90,$60,
	DB $7D,$3F,$DD,$FF,$FD,$1E,$1C,$3D,$3F,$38,$4C,$38,$1C,$48,$0C,$CC,
	DB $00,$80,$00,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$03,$03,$03,$06,$03,$07,$06,$06,$05,$05,$04,$05,$04,$04,$04,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,
	DB $83,$00,$C2,$81,$E0,$C0,$E0,$F0,$9C,$F8,$8E,$FF,$E7,$DF,$60,$FF,
	DB $C1,$00,$43,$81,$07,$02,$06,$0F,$39,$1F,$73,$FF,$E7,$FB,$07,$FF,
	DB $0C,$86,$06,$06,$06,$02,$02,$06,$C4,$86,$CC,$C4,$EC,$C8,$C8,$D0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $06,$04,$06,$02,$02,$03,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$DF,$FF,$7F,$DF,$FF,$EF,$67,$3F,$1F,$3F,$6F,$1F,$60,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FD,$FF,$FE,$FF,$F7,$FF,$03,$FF,$01,$FF,
	DB $9E,$FF,$E1,$FF,$FD,$FF,$FF,$FF,$3F,$FF,$0F,$FF,$C7,$FF,$F0,$FF,
	DB $7F,$FF,$FF,$FF,$BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $90,$C0,$88,$C0,$E0,$C0,$E0,$E0,$F8,$F0,$FC,$FE,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$80,$F4,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$01,$06,$03,$04,$07,$0C,$0F,$18,$0F,$18,$1F,$10,$1F,$00,$00,
	DB $80,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,
	DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,
	DB $7F,$FF,$0F,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$0F,$FF,$F8,$FF,$00,$FF,$00,$FF,$00,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$04,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,
	DB $FF,$FE,$FF,$FF,$FF,$FF,$4B,$FF,$43,$FF,$4F,$FF,$02,$FF,$00,$00,
	DB $00,$00,$00,$80,$80,$C0,$E0,$C0,$E0,$E0,$F0,$E0,$20,$F0,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$03,$03,$07,$0F,$0F,
	DB $00,$00,$00,$00,$00,$00,$AA,$5C,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$07,$00,$1D,$20,$BB,$47,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$80,$00,$10,$E0,$B4,$F8,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$A0,$C0,$E8,$F0,$F4,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $0F,$1F,$3F,$1F,$3F,$3F,$7F,$3F,$7F,$7F,$FF,$7F,$7F,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$7F,$FF,$1F,$FF,$91,$EF,$C0,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$F8,$20,$F0,$F0,$E0,$C0,$E0,
	DB $E2,$FC,$EF,$FE,$DF,$FF,$FF,$FF,$7F,$FF,$3F,$7F,$3F,$3F,$0F,$3F,
	DB $00,$00,$00,$00,$00,$00,$00,$80,$C0,$80,$C0,$C0,$E0,$C0,$E0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$00,$00,$01,$01,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,
	DB $FF,$FF,$7F,$FF,$FF,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$FF,$7F,$7F,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FC,$F9,$FF,$FE,$FF,
	DB $C0,$E0,$E0,$C0,$E0,$C0,$C0,$C0,$C0,$80,$90,$E0,$F8,$F0,$F8,$00,
	DB $1F,$27,$17,$23,$1B,$27,$1D,$3F,$78,$31,$1A,$65,$4F,$3F,$3B,$7F,
	DB $F0,$E0,$F0,$F0,$F0,$F8,$FC,$F8,$FC,$FC,$F6,$FC,$F8,$FE,$FE,$FA,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,
	DB $FF,$FF,$FF,$FF,$7F,$FF,$FF,$7F,$FF,$7F,$7F,$7F,$7F,$FF,$BF,$7F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$E7,$CB,$FF,
	DB $F7,$F8,$E5,$F3,$CF,$FF,$DF,$FF,$FF,$FF,$F9,$FF,$D4,$FB,$DC,$E8,
	DB $90,$78,$ED,$FF,$B3,$E7,$16,$C3,$C3,$C6,$82,$C6,$44,$86,$04,$0C,
	DB $F1,$7D,$FC,$FD,$FB,$FC,$76,$68,$30,$60,$74,$3B,$A4,$1F,$80,$10,
	DB $F8,$FA,$FC,$FA,$FA,$7C,$F2,$7C,$F8,$74,$F4,$F8,$B0,$78,$30,$78,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$03,
	DB $7F,$3F,$3F,$3F,$3F,$3F,$3F,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,
	DB $CB,$F7,$F8,$E7,$F8,$E7,$FD,$F3,$FC,$F8,$FD,$FE,$FD,$FF,$FF,$FC,
	DB $F6,$EC,$E3,$F7,$7B,$F0,$38,$F8,$DC,$38,$F8,$3C,$FC,$FC,$BC,$7C,
	DB $DC,$38,$D0,$E0,$80,$00,$00,$00,$0F,$10,$0C,$18,$0E,$04,$03,$00,
	DB $C0,$30,$10,$E0,$6A,$04,$F0,$0C,$84,$08,$01,$08,$18,$01,$B3,$00,
	DB $30,$78,$18,$78,$9C,$58,$CC,$0C,$06,$86,$02,$86,$07,$02,$06,$02,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $07,$02,$00,$05,$01,$05,$0F,$01,$01,$07,$03,$07,$03,$03,$07,$03,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FD,$FC,$FF,$FC,$FE,$FF,$FF,$FF,$FB,$FF,$FB,$FF,$FF,$FF,$FE,$FF,
	DB $3E,$7C,$DA,$9F,$B9,$1F,$78,$3F,$FB,$7C,$B4,$FF,$B8,$FF,$BF,$FF,
	DB $00,$00,$80,$00,$D0,$E0,$72,$FC,$1F,$FF,$07,$FF,$71,$FF,$0F,$FF,
	DB $F0,$02,$42,$04,$08,$04,$10,$08,$00,$F0,$F0,$E0,$78,$FC,$FC,$FE,
	DB $06,$06,$0C,$04,$1C,$08,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $02,$07,$03,$06,$00,$06,$02,$06,$06,$02,$02,$02,$00,$03,$01,$01,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$6F,$7F,$36,$3F,$9C,$3F,
	DB $FF,$FE,$FE,$FE,$FE,$FE,$FC,$FF,$FF,$FF,$80,$FF,$00,$FF,$00,$FF,
	DB $7F,$FF,$7F,$FF,$FF,$FF,$E0,$FF,$F0,$FF,$3C,$FF,$0F,$FF,$03,$FF,
	DB $C2,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$1F,$FF,$87,$FF,$E7,$FF,
	DB $FC,$FE,$FC,$FC,$FC,$F8,$F8,$F8,$F8,$FC,$FC,$FE,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$80,$F0,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $6C,$BF,$C8,$6F,$08,$1F,$1C,$1F,$38,$1F,$18,$3F,$3E,$3F,$01,$3E,
	DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$01,$FF,$FE,$01,
	DB $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$10,$FF,$98,$FF,$23,$DC,
	DB $7F,$FF,$0F,$FF,$01,$FF,$00,$FF,$03,$FF,$00,$FF,$00,$FF,$FF,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$3F,$FF,$FF,$FF,$79,$FF,$01,$FF,$FF,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$80,$7F,
	DB $80,$00,$80,$C0,$C0,$E0,$F0,$E0,$F0,$F0,$F8,$F0,$F0,$F8,$00,$F8,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$01,$00,$0B,$04,$15,$0B,$37,$0F,$0F,$3F,
	DB $00,$00,$00,$00,$00,$00,$C0,$00,$B8,$40,$E8,$F4,$F3,$FC,$FF,$FF,
	DB $00,$00,$00,$00,$01,$00,$02,$07,$3F,$1F,$3F,$7F,$FF,$FF,$FF,$FF,
	DB $00,$00,$78,$00,$7A,$84,$FB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$80,$00,$D0,$E0,$FC,$F8,$FC,$FE,$FE,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$01,$03,$03,$03,$07,
	DB $7F,$3F,$7B,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$EF,$FF,$DF,$FF,$DF,$FF,$9F,$EF,$DA,$FF,$FD,$FE,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$FF,
	DB $FE,$FF,$FD,$FF,$FF,$FF,$FD,$FF,$FB,$FF,$FF,$FF,$DF,$FF,$17,$8F,
	DB $40,$80,$00,$C0,$C0,$E0,$F0,$E0,$F0,$F0,$F0,$F8,$F8,$F8,$F8,$FC,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $07,$07,$0F,$05,$09,$0D,$0B,$09,$0B,$09,$1B,$09,$01,$09,$09,$09,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $02,$FF,$FF,$FE,$FF,$FE,$FC,$FE,$FC,$FE,$FE,$FC,$F6,$FC,$F4,$EC,
	DB $03,$07,$05,$03,$05,$02,$04,$02,$06,$00,$04,$00,$00,$01,$07,$03,
	DB $FC,$FC,$FC,$FE,$FD,$FE,$7C,$FF,$3E,$7F,$3F,$7F,$DF,$FF,$3F,$9F,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$80,$00,$00,$80,
	DB $01,$0D,$05,$04,$06,$03,$03,$01,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$7F,$7F,$7F,$7F,$FF,$7F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FD,$FE,$FC,$FF,$7F,$FF,
	DB $C4,$E8,$AF,$DF,$FF,$FF,$58,$A7,$4F,$3F,$7E,$FF,$F3,$FC,$F8,$FC,
	DB $02,$07,$80,$07,$8B,$07,$8F,$07,$AF,$DF,$FF,$7F,$65,$3E,$37,$66,
	DB $9F,$7F,$FF,$FF,$BF,$FF,$FF,$9F,$F2,$9F,$43,$BF,$FA,$0F,$FF,$0E,
	DB $80,$80,$C0,$80,$80,$C0,$00,$C0,$00,$40,$00,$40,$C0,$00,$00,$80,
	DB $00,$00,$00,$01,$04,$03,$04,$00,$00,$00,$00,$00,$01,$01,$07,$03,
	DB $3F,$FF,$7F,$BF,$7F,$3F,$7F,$7F,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $F8,$FF,$F8,$FF,$FF,$FC,$FD,$FE,$FF,$FE,$FD,$FB,$F5,$F8,$FD,$F8,
	DB $BF,$7F,$3D,$FF,$7E,$FF,$0F,$FE,$AF,$7F,$3B,$87,$A9,$C7,$F6,$3F,
	DB $9C,$F8,$87,$F8,$FF,$80,$7E,$C1,$EE,$7F,$47,$B8,$FE,$80,$90,$C0,
	DB $27,$63,$24,$63,$EA,$41,$82,$C1,$81,$0E,$0A,$04,$01,$00,$0C,$03,
	DB $3C,$FF,$54,$EF,$77,$0E,$66,$0E,$1E,$0E,$D6,$0E,$07,$93,$B3,$01,
	DB $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,
	DB $07,$07,$07,$0B,$0F,$07,$17,$0F,$1F,$0F,$1F,$0F,$0B,$1F,$13,$1F,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $FD,$F8,$FC,$FD,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FD,$FF,$FD,$FF,$FF,
	DB $8F,$1F,$33,$1F,$32,$27,$6F,$0F,$4F,$0F,$2F,$0F,$6F,$8F,$FF,$FF,
	DB $C0,$C0,$C0,$C0,$D0,$E0,$F4,$F8,$9E,$FF,$C7,$FF,$B9,$FF,$CF,$FF,
	DB $BF,$40,$2D,$02,$06,$00,$00,$00,$81,$00,$CC,$F3,$F8,$FC,$FC,$FE,
	DB $01,$21,$20,$41,$01,$41,$41,$81,$02,$83,$02,$04,$00,$00,$00,$00,
	DB $80,$80,$80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $1B,$17,$1B,$17,$07,$1B,$0B,$0F,$0F,$07,$03,$03,$01,$01,$00,$00,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$7F,$FF,$FF,$FF,$FF,
	DB $F8,$FF,$F0,$FF,$E0,$FF,$C0,$FF,$C0,$FF,$80,$FF,$C0,$FF,$C0,$FF,
	DB $0F,$FF,$03,$FF,$01,$FF,$80,$7F,$00,$FF,$01,$FF,$00,$FF,$00,$FF,
	DB $FB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$DF,$FF,$67,$FF,$F1,$FF,$FD,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$FE,$FE,$FC,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$80,$F4,$F8,$FC,$FE,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$08,$00,$01,$07,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $7F,$7F,$57,$FF,$CB,$9F,$47,$0F,$5B,$27,$17,$07,$07,$07,$08,$07,
	DB $C0,$FF,$80,$FF,$80,$FF,$80,$FF,$80,$FF,$80,$FF,$F0,$FF,$07,$F8,
	DB $02,$FF,$01,$FF,$01,$FF,$00,$FF,$06,$FF,$03,$FF,$03,$FF,$FE,$01,
	DB $7F,$FF,$7F,$FF,$3E,$FF,$FD,$FF,$7C,$FF,$7A,$FF,$BD,$FF,$02,$FD,
	DB $FF,$FF,$FF,$FF,$7F,$FF,$9F,$FF,$7F,$FF,$18,$FF,$00,$FF,$7F,$80,
	DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$80,$7F,
	DB $00,$00,$80,$80,$80,$C0,$C0,$C0,$E0,$C0,$C0,$E0,$E0,$E0,$00,$E0,

; 3072 bytes of title data
TitleData:
	DB $FF,$FF,$FF,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C1,$FF,
	DB $FF,$FF,$FF,$FF,$0F,$F0,$1F,$E0,$3F,$C0,$7F,$80,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$F0,$0F,$F8,$07,$FC,$03,$FE,$01,$FF,$00,$FF,$FF,
	DB $FF,$FF,$FF,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$FF,$83,$FF,
	DB $C3,$FD,$C7,$F9,$CF,$F1,$DF,$E1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $FF,$FF,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $FF,$FF,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $C3,$BF,$E3,$9F,$F3,$8F,$FB,$87,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$87,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $03,$03,$05,$06,$05,$06,$05,$06,$05,$06,$02,$03,$01,$01,$00,$00,
	DB $18,$18,$AC,$B4,$54,$64,$04,$04,$04,$04,$88,$08,$50,$90,$A0,$E0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $0C,$0C,$16,$1A,$15,$19,$14,$18,$14,$18,$0A,$0C,$05,$06,$02,$03,
	DB $60,$60,$B0,$D0,$50,$90,$10,$10,$10,$10,$20,$20,$40,$40,$80,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $31,$31,$5A,$6B,$55,$66,$50,$60,$50,$60,$28,$30,$15,$19,$0A,$0E,
	DB $80,$80,$C0,$40,$40,$40,$40,$40,$40,$40,$80,$80,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1F,$1F,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FC,$FC,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $85,$86,$85,$86,$85,$86,$85,$86,$87,$87,$85,$86,$85,$86,$85,$86,
	DB $20,$20,$20,$20,$20,$20,$20,$20,$E0,$E0,$20,$20,$20,$20,$20,$20,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$1F,$1F,$14,$18,$14,$18,$14,$18,$14,$18,
	DB $40,$40,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$C0,$C0,$40,$40,$40,$40,$40,$40,$7F,$7F,
	DB $01,$01,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$F8,$F8,$48,$88,$48,$88,$4F,$8F,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7F,$7F,
	DB $04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DF,$DF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$F0,
	DB $14,$18,$14,$18,$14,$18,$14,$18,$1F,$1F,$00,$00,$00,$00,$00,$00,
	DB $A4,$C4,$A4,$C4,$A4,$C4,$A4,$C4,$FF,$FF,$A5,$C6,$A5,$C6,$A5,$C6,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$E1,$E1,$21,$21,$21,$21,$21,$21,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $85,$86,$87,$87,$85,$86,$85,$86,$85,$86,$85,$86,$87,$87,$80,$80,
	DB $20,$20,$FF,$FF,$29,$31,$29,$31,$29,$31,$29,$31,$FF,$FF,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $1F,$1F,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $47,$87,$44,$84,$44,$84,$44,$84,$44,$84,$44,$84,$44,$84,$44,$84,
	DB $E8,$F0,$50,$60,$50,$60,$53,$63,$53,$63,$50,$60,$50,$60,$50,$60,
	DB $1A,$1C,$0A,$0C,$0A,$0C,$AF,$CF,$A9,$C9,$09,$09,$09,$09,$09,$09,
	DB $01,$01,$01,$01,$01,$01,$4F,$8F,$49,$89,$49,$89,$49,$89,$49,$89,
	DB $DD,$EE,$A5,$C6,$40,$80,$43,$83,$42,$82,$4E,$8E,$48,$88,$48,$88,
	DB $74,$78,$68,$70,$50,$60,$FF,$FF,$1F,$1F,$74,$78,$50,$60,$53,$63,
	DB $18,$18,$0C,$0C,$04,$04,$A4,$C4,$A4,$C4,$04,$04,$04,$04,$A4,$C4,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $A5,$C6,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $21,$21,$E1,$E1,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$05,$06,$05,$06,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$F7,$F7,$15,$16,$15,$16,
	DB $44,$84,$44,$84,$44,$84,$44,$84,$44,$84,$FC,$FC,$10,$10,$10,$10,
	DB $53,$63,$53,$63,$50,$60,$50,$60,$68,$70,$3F,$3F,$00,$00,$00,$00,
	DB $F9,$F9,$F9,$F9,$09,$09,$09,$09,$18,$18,$F0,$F0,$00,$00,$00,$00,
	DB $4F,$8F,$41,$81,$41,$81,$A1,$C1,$D1,$E1,$7F,$7F,$00,$00,$00,$00,
	DB $48,$88,$48,$88,$48,$88,$48,$88,$48,$88,$F8,$F8,$01,$01,$01,$01,
	DB $53,$63,$50,$60,$50,$60,$68,$70,$34,$38,$1F,$1F,$F8,$F8,$48,$88,
	DB $A4,$C4,$04,$04,$04,$04,$54,$64,$D4,$E4,$FC,$FC,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$0C,$16,$1A,$15,$19,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$61,$61,$B1,$D1,$51,$91,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $80,$80,$80,$80,$86,$86,$8B,$8D,$8A,$8C,$8A,$8C,$8A,$8C,$85,$86,
	DB $00,$00,$00,$00,$30,$30,$58,$68,$A8,$C8,$08,$08,$08,$08,$10,$10,
	DB $05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$06,
	DB $15,$16,$15,$16,$15,$16,$1D,$1E,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $10,$10,$1F,$1F,$1A,$1C,$14,$18,$14,$18,$14,$18,$14,$18,$14,$18,
	DB $00,$00,$FC,$FC,$07,$07,$03,$03,$02,$03,$EB,$F3,$EA,$F2,$03,$03,
	DB $00,$00,$FF,$FF,$A0,$C0,$40,$80,$80,$00,$FD,$FE,$FD,$FE,$A0,$C0,
	DB $00,$00,$8F,$8F,$DB,$DD,$74,$78,$28,$30,$28,$30,$28,$30,$29,$31,
	DB $01,$01,$FF,$FF,$AA,$CC,$AA,$CC,$0A,$0C,$7F,$7F,$41,$41,$C1,$C1,
	DB $48,$88,$4F,$8F,$01,$01,$01,$01,$01,$01,$4F,$8F,$49,$89,$49,$89,
	DB $00,$00,$7F,$7F,$D0,$E0,$A0,$C0,$40,$80,$40,$80,$4F,$8F,$4F,$8F,
	DB $00,$00,$C0,$C0,$60,$60,$20,$20,$20,$20,$20,$20,$E0,$E0,$80,$80,
	DB $14,$18,$14,$18,$0A,$0C,$05,$06,$02,$03,$01,$01,$00,$00,$00,$00,
	DB $11,$11,$11,$11,$21,$21,$41,$41,$81,$81,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $82,$83,$81,$81,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,
	DB $A0,$20,$40,$C0,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$05,$06,$07,$07,
	DB $1D,$1E,$15,$16,$15,$16,$15,$16,$15,$16,$15,$16,$15,$16,$F7,$F7,
	DB $14,$18,$14,$18,$14,$18,$14,$18,$14,$18,$14,$18,$1A,$1C,$FF,$FF,
	DB $02,$03,$02,$03,$FE,$FF,$FE,$FF,$02,$03,$03,$03,$07,$07,$FC,$FC,
	DB $80,$00,$9D,$1E,$9D,$1E,$80,$00,$80,$00,$42,$83,$A6,$C7,$FF,$FF,
	DB $29,$31,$29,$31,$29,$31,$29,$31,$29,$31,$29,$31,$29,$31,$FF,$FF,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,
	DB $49,$89,$49,$89,$4F,$8F,$41,$81,$41,$81,$A1,$C1,$D1,$E1,$7F,$7F,
	DB $40,$80,$D0,$E0,$7D,$7E,$FD,$FE,$40,$80,$40,$80,$A0,$C0,$FF,$FF,
	DB $E0,$E0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$60,$60,$C0,$C0,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$6B,$AD,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$03,$03,$02,$03,$02,$03,$02,$03,$02,$03,
	DB $00,$00,$00,$00,$00,$00,$F0,$F0,$90,$10,$90,$10,$90,$10,$90,$10,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$6B,$AD,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,
	DB $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $55,$99,$41,$81,$41,$81,$A2,$C2,$54,$64,$28,$38,$10,$10,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $7F,$7F,$52,$63,$52,$63,$52,$63,$52,$63,$7F,$7F,$00,$00,$00,$00,
	DB $FF,$FF,$94,$18,$94,$18,$94,$18,$94,$18,$FF,$FF,$00,$00,$00,$00,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
	DB $55,$99,$41,$81,$41,$81,$A2,$C2,$54,$64,$28,$38,$10,$10,$00,$00,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,$FF,$83,
	DB $FF,$C1,$FF,$C1,$FF,$C1,$FF,$C1,$DF,$E1,$CF,$F1,$C7,$F9,$C3,$FD,
	DB $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,
	DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$FF,$FF,
	DB $FF,$83,$FF,$83,$FF,$83,$FF,$83,$FB,$87,$F3,$8F,$E3,$9F,$C3,$BF,
	DB $C1,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$C0,$FF,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$7F,$80,$3F,$C0,$1F,$E0,$0F,$F0,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$FF,$FF,
	DB $FF,$FF,$FF,$00,$FE,$01,$FC,$03,$F8,$07,$F0,$0F,$FF,$FF,$FF,$FF,
	DB $83,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$FF,$03,$FF,$FF,$FF,$FF,$FF,

; 1024 bytes of font data
; ASCII value minus $20
FontData:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$30,$30,$78,$78,$78,$78,$78,$78,$30,$30,$00,$00,$30,$30
	DB $00,$00,$6C,$6C,$6C,$6C,$24,$24,$48,$48,$00,$00,$00,$00,$00,$00
	DB $00,$00,$6C,$6C,$FE,$FE,$6C,$6C,$6C,$6C,$6C,$6C,$FE,$FE,$6C,$6C
	DB $00,$00,$10,$10,$7E,$7E,$D0,$D0,$7C,$7C,$16,$16,$FC,$FC,$10,$10
	DB $00,$00,$42,$42,$A6,$A6,$4C,$4C,$18,$18,$34,$34,$6A,$6A,$C4,$C4
	DB $00,$00,$70,$70,$D8,$D8,$70,$70,$DA,$DA,$CE,$CE,$C6,$C6,$7C,$7C
	DB $00,$00,$30,$30,$30,$30,$10,$10,$20,$20,$00,$00,$00,$00,$00,$00
	DB $00,$00,$1C,$1C,$30,$30,$60,$60,$60,$60,$60,$60,$30,$30,$1C,$1C
	DB $00,$00,$70,$70,$18,$18,$0C,$0C,$0C,$0C,$0C,$0C,$18,$18,$70,$70
	DB $00,$00,$6C,$6C,$38,$38,$6C,$6C,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$7C,$7C,$10,$10,$10,$10
	DB $00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$10,$10,$20,$20
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7C,$7C,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30
	DB $00,$00,$04,$04,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80
	DB $00,$00,$7C,$7C,$C6,$C6,$8E,$8E,$9A,$9A,$B2,$B2,$E6,$E6,$7C,$7C
	DB $00,$00,$78,$78,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$7E,$7E
	DB $00,$00,$7C,$7C,$C6,$C6,$0C,$0C,$38,$38,$60,$60,$C0,$C0,$FE,$FE
	DB $00,$00,$7C,$7C,$C6,$C6,$06,$06,$3C,$3C,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$1E,$1E,$36,$36,$66,$66,$C6,$C6,$FE,$FE,$06,$06,$06,$06
	DB $00,$00,$FE,$FE,$C0,$C0,$FC,$FC,$06,$06,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$FC,$FC,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$FE,$FE,$C6,$C6,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$7C,$7C,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$7E,$7E,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$30,$30,$30,$30
	DB $00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$30,$30,$10,$10
	DB $00,$00,$00,$00,$00,$00,$1C,$1C,$38,$38,$70,$70,$38,$38,$1C,$1C
	DB $00,$00,$00,$00,$00,$00,$00,$00,$7C,$7C,$00,$00,$7C,$7C,$00,$00
	DB $00,$00,$00,$00,$00,$00,$70,$70,$38,$38,$1C,$1C,$38,$38,$70,$70
	DB $00,$00,$7C,$7C,$C6,$C6,$06,$06,$3C,$3C,$30,$30,$00,$00,$30,$30
	DB $00,$00,$7C,$7C,$C6,$C6,$D6,$D6,$D6,$D6,$DC,$DC,$C0,$C0,$7C,$7C
	DB $00,$00,$38,$38,$6C,$6C,$C6,$C6,$C6,$C6,$FE,$FE,$C6,$C6,$C6,$C6
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$C0,$C0,$C0,$C0,$C6,$C6,$7C,$7C
	DB $00,$00,$F8,$F8,$CC,$CC,$C6,$C6,$C6,$C6,$C6,$C6,$CC,$CC,$F8,$F8
	DB $00,$00,$FE,$FE,$C0,$C0,$C0,$C0,$F8,$F8,$C0,$C0,$C0,$C0,$FE,$FE
	DB $00,$00,$FE,$FE,$C0,$C0,$C0,$C0,$F8,$F8,$C0,$C0,$C0,$C0,$C0,$C0
	DB $00,$00,$7E,$7E,$C0,$C0,$C0,$C0,$DE,$DE,$C6,$C6,$C6,$C6,$7E,$7E
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$FE,$FE,$C6,$C6,$C6,$C6,$C6,$C6
	DB $00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$7E,$7E
	DB $00,$00,$1E,$1E,$06,$06,$06,$06,$06,$06,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$C6,$C6,$CC,$CC,$D8,$D8,$F0,$F0,$D8,$D8,$CC,$CC,$C6,$C6
	DB $00,$00,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$FE,$FE
	DB $00,$00,$C6,$C6,$EE,$EE,$FE,$FE,$D6,$D6,$C6,$C6,$C6,$C6,$C6,$C6
	DB $00,$00,$C6,$C6,$E6,$E6,$F6,$F6,$DE,$DE,$CE,$CE,$C6,$C6,$C6,$C6
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$C0,$C0,$C0,$C0,$C0,$C0
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6,$DE,$DE,$CC,$CC,$7A,$7A
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$D8,$D8,$CC,$CC,$C6,$C6
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$7C,$7C,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$6C,$6C,$38,$38,$10,$10
	DB $00,$00,$C6,$C6,$C6,$C6,$D6,$D6,$FE,$FE,$EE,$EE,$C6,$C6,$C6,$C6
	DB $00,$00,$C6,$C6,$EE,$EE,$7C,$7C,$38,$38,$7C,$7C,$EE,$EE,$C6,$C6
	DB $00,$00,$66,$66,$66,$66,$66,$66,$3C,$3C,$18,$18,$18,$18,$18,$18
	DB $00,$00,$FE,$FE,$0E,$0E,$1C,$1C,$38,$38,$70,$70,$E0,$E0,$FE,$FE
	DB $00,$00,$7C,$7C,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$7C,$7C
	DB $00,$00,$40,$40,$60,$60,$30,$30,$18,$18,$0C,$0C,$06,$06,$02,$02
	DB $00,$00,$7C,$7C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$7C,$7C
	DB $00,$00,$10,$10,$38,$38,$6C,$6C,$C6,$C6,$00,$00,$00,$00,$00,$00
	DB $FF,$FF,$40,$FF,$DF,$60,$50,$60,$FF,$FF,$08,$FF,$FB,$0C,$0A,$0C ; wall
	;DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FE,$FE ; underscore

