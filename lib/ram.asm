
; =============================================================================
; 	RAM
; =============================================================================

IFDEF CFG_INIT_16KB_RAM
	org	$c000, $f380
ELSE
	org	$e000, $f380
ENDIF
ram_start:


; -----------------------------------------------------------------------------
; 	MSX cartridge (ROM) header, entry point and initialization

; Refresh rate in Hertzs (50Hz/60Hz) and related convenience vars
frame_rate:
	rb	1
frames_per_tenth:
	rb	1
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
;	Input routines (BIOS-based)

; Stores GET_TRIGGER result
trigger:
	rb	1

; Stores GET_STICK_TRIGGER_BITS result
stick:
	rb	1
stick_edge:
	rb	1
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
;	VRAM routines (BIOS-based)
;	NAMBTL and SPRATR buffer routines (BIOS-based)
;	NAMTBL buffer text routines
;	Logical coordinates sprite routines

; NAMTBL buffer in RAM
namtbl_buffer:
	rb	NAMTBL_SIZE
	
; SPRATR buffer in RAM
spratr_buffer:
	rb	SPRATR_SIZE
spratr_buffer_end:
	rb	1	; to store one SPAT_END when the buffer is full
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
;	"vpoke" routines (deferred WRTVRMs routines)
;	Spriteables routines (2x2 chars that eventually become a sprite)

; "vpoke" routines (deferred WRTVRMs routines)
IFDEF CFG_VPOKES
vpokes:
.count:
	rb	1
.array:
	rb	CFG_VPOKES * VPOKE.SIZE
ENDIF


IFDEF CFG_SPRITEABLES
spriteables:
.count:
	rb	1
.array:
; estado (0 = reposo, [MASK_TILE_SPRITE_DIRECTION | MASK_TILE_SPRITE_PENDING] = movimiento pendiente)
	_SPRITEABLE_STATUS:	equ $ - spriteables.array
	rb	1
; offset del caracter superior izquierdo
	_SPRITEABLE_OFFSET_L:	equ $ - spriteables.array
	rb	1
	_SPRITEABLE_OFFSET_H:	equ $ - spriteables.array
	rb	1
; caracteres que definen el tile convertible
	_SPRITEABLE_FOREGROUND:	equ $ - spriteables.array
	rb	1
; caracteres de fondo cubiertos por el tile convertible
	_SPRITEABLE_BACKGROUND:	equ $ - spriteables.array
	rb	4
; atributos del sprite equivalente (patrón, color)
	_SPRITEABLE_PATTERN:	equ $ - spriteables.array
	rb	1	; patrón
	_SPRITEABLE_COLOR:	equ $ - spriteables.array
	rb	1	; color
	SPRITEABLE_SIZE:	equ $ - spriteables.array

; (resto del array)
	rb	(CFG_SPRITEABLES -1) * ($ - spriteables.array)
	spriteables.SIZE:	equ $ - spriteables.array
	
ENDIF
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Player vars
player:

; Logical coordinates (in pixels)
.xy:
.y:
	rb	1
.x:
	rb	1
; Current animation delay (e.g.: when walking) (in frames)
.animation_delay:
	rb	1
; Current player state
.state:
	rb	1
; Delta-Y (dY) table index (when jumping and falling)
.dy_index:
	rb	1
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Enemies array
IFDEF CFG_ENEMY_COUNT
enemies:

enemy:
; Logical coordinates (in pixels)
	.xy:	equ $ - enemy
	.y:		equ $ - enemy
	rb	1
	.x:		equ $ - enemy
	rb	1
; Initial logical coordinates backup (e.g.: for respawning)
	.xy_backup:	equ $ - enemy
	.y_backup:	equ $ - enemy
	rb	1
	.x_backup:	equ $ - enemy
	rb	1
; Enemy sprite attributes
	.pattern:	equ $ - enemy
	rb	1
	.color:		equ $ - enemy
	rb	1
; State pointer
	.state:		equ $ - enemy
	.state_l:	equ $ - enemy
	rb	1
	.state_h:	equ $ - enemy
	rb	1
; Current animation delay (e.g.: when walking) (in frames)
	.animation_delay:	equ $ - enemy
	rb	1
; Current frame counter
	.frame_counter:	equ $ - enemy
	rb	1
	.SIZE:	equ $ - enemy

; (rest of the array)
	rb	(CFG_ENEMY_COUNT -1) * enemy.SIZE
	enemies.SIZE:	equ $ - enemies
ENDIF
; -----------------------------------------------------------------------------


; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_MSX2_OPTIONS > 0)
	; .include	"lib/optional/msx2options.ram.asm"
; ENDIF ; (CFG_OPTIONAL_MSX2_OPTIONS > 0)
; ; -----------------------------------------------------------------------------

; ; -----------------------------------------------------------------------------
; IF (CFG_OPTIONAL_PT3HOOK > 0)
	; .include	"lib/optional/pt3hook.ram.asm"
; ENDIF ; (CFG_OPTIONAL_PT3HOOK > 0)
; ; -----------------------------------------------------------------------------

; EOF
