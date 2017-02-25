;
; =============================================================================
;	Bullet related routines (generic)
;	Bullet-tile helper routines
; =============================================================================
;

; -----------------------------------------------------------------------------
; Bounding box coordinates offset from the logical coordinates
	BULLET_BOX_X_OFFSET:	equ -(CFG_BULLET_WIDTH / 2)
	BULLET_BOX_Y_OFFSET:	equ -CFG_BULLET_HEIGHT

	MASK_BULLET_SPEED:	equ $0f ; speed (in pixels / frame)
	MASK_BULLET_DIRECTION:	equ $70 ; movement direction

	BULLET_DIR_UP:		equ $10
	BULLET_DIR_DOWN:	equ $20
	BULLET_DIR_RIGHT:	equ $30
	BULLET_DIR_LEFT:	equ $40
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Empties the bullets array
RESET_BULLETS:
; Fills the array with zeroes
	ld	hl, bullets
	ld	de, bullets +1
	ld	bc, bullets.SIZE -1
	ld	[hl], 0
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Initializes a new from the enemy coordinates in the first empty bullet slot
; param hl: pointer to the new bullet data (pattern, color, speed and direction)
; touches: a, hl, de, bc
INIT_BULLET_FROM_ENEMY:
	push	hl ; preserves source
; Search for the first empty enemy slot
	ld	hl, bullets
	ld	bc, bullet.SIZE
	xor	a ; (marker value: y = 0)
.LOOP:
	cp	[hl]
	jr	z, .INIT ; empty slot found
; Skips to the next element of the array
	add	hl, bc
	jr	.LOOP
	
.INIT:
; Stores the logical coordinates
	push	ix ; hl = ix, de = empy bullet slot
	pop	de
	ex	de, hl
	ldi	; .y
	ldi	; .x
; Stores the pattern, color and type (speed and direction)
	pop	hl ; restores source in hl
	ldi	; .pattern
	ldi	; .color
	ldi	; .type
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Updates the bullets
UPDATE_BULLETS:
; For each bullet in the array
	ld	ix, bullets
	ld	b, CFG_BULLET_COUNT
.LOOP:
	push	bc ; preserves counter in b
; Is the bullet slot empty?
	xor	a ; (marker value: y = 0)
	cp	[ix + bullet.y]
	jr	z, .SKIP ; yes
	
; no: puts the bullet sprite
	ld	e, [ix + bullet.y]
	ld	d, [ix + bullet.x]
	ld	c, [ix + bullet.pattern]
	ld	b, [ix + bullet.color]
	call	PUT_SPRITE
	
	ld	a, [ix + bullet.type]
	cp	BULLET_DIR_RIGHT
	jr	c, .UP_OR_DOWN ; direction < RIGHT, ergo UP or DOWN
; direction >= RIGHT, ergo RIGHT or LEFT
	cp	BULLET_DIR_LEFT
	jr	c, .RIGHT

; left
	and	MASK_BULLET_SPEED
	neg
	add	d
	ld	[ix + bullet.x], a
	jr	.SKIP
	
.RIGHT:
; right
	and	MASK_BULLET_SPEED
	add	d
	ld	[ix + bullet.x], a
	jr	.SKIP

.UP_OR_DOWN:
	cp	BULLET_DIR_DOWN
	jr	c, .UP

; down
	and	MASK_BULLET_SPEED
	add	e
	ld	[ix + bullet.y], a
	jr	.SKIP

.UP:
; up
	and	MASK_BULLET_SPEED
	neg
	add	e
	ld	[ix + bullet.y], a
	; jr	.SKIP ; falls through

.SKIP:
; Skips to the next bullet
	ld	bc, bullet.SIZE
	add	ix, bc
	pop	bc ; restores counter
	djnz	.LOOP
	ret
; -----------------------------------------------------------------------------

; EOF
