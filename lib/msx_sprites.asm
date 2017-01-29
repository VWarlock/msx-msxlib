
; =============================================================================
;	Generic sprite routines
; =============================================================================

; -----------------------------------------------------------------------------
; N�mero de sprites gestionados din�micamente (por ejemplo: enemigos, balas)
	CFG_SPRITES_DYNAMIC	equ 32 -CFG_SPRITES_RESERVED_BEFORE -CFG_PLAYER_SPRITES -CFG_SPRITES_RESERVED_AFTER
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Modifica las coordenadas de un sprite en el buffer de spratr
; param hl: puntero al sprite a modificar en el buffer de la spratr
; param d: coordenada x
; param e: coordenada y
; param b: n�mero de sprites
MOVE_SPRITE_XY:
	djnz	@@MULTI

@@DO_PUT_SPRITE_XY:
; spratr y = coordenada y -16 -1
	ld	a, e
	add	CFG_SPRITES_Y_OFFSET
	ld	[hl], a
	inc	hl
; spratr x = coordenada x -8
	ld	a, d
	add	CFG_SPRITES_X_OFFSET
	ld	[hl], a
	ret
	
@@MULTI:
; primer sprite
	push	de ; preserva las coordenadas del objeto
	call	@@DO_PUT_SPRITE_XY
	pop	de ; restaura las coordenadas del objeto
; lee el patr�n del sprite
	inc	hl
	ld	a, [hl]
@@LOOP:
; guarda el patr�n del sprite en c
	ld	c, a
; siguiente sprite
	push	de ; preserva las coordenadas del objeto
	inc	hl ; avanza hasta el buffer de la spratr del siguiente sprite
	inc	hl
	call	@@DO_PUT_SPRITE_XY
	pop	de ; restaura las coordenadas del objeto
; escribe el siguiente patr�n (c + 4)
	inc	hl
	ld	a, 4
	add	c
	ld	[hl], a
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Resetea toda la informaci�n de los sprites din�micos
RESET_DYNAMIC_SPRITES:
; Rellena todas las coordenadas Y con SPAT_END
	ld	hl, dynamic_sprites
	ld	b, (spratr_buffer_end - dynamic_sprites) / 4
	ld	a, SPAT_END
@@LOOP:
	ld	[hl], a
; Avanza al siguiente sprite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	@@LOOP
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; A�ade un sprite din�mico
; param de: coordenadas (y, x) l�gicas o f�sicas
; param cb: atributos (patr�n, color)
PUT_DYNAMIC_SPRITE_LOGICAL:
; Convierte las coordenadas l�gicas en f�sicas (-8, -16)
	ld	a, d ; y -= 16, y--
	add	CFG_SPRITES_Y_OFFSET
	ld	d, a
	ld	a, e ; x -= 8
	add	CFG_SPRITES_X_OFFSET
	ld	e, a
	
PUT_DYNAMIC_SPRITE:
; Localiza el SPAT_END
	ld	hl, dynamic_sprites
	ld	a, SPAT_END
@@LOOP:
	cp	[hl]
	jr	z, @@HL_OK
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	jr	@@LOOP
@@HL_OK:

; Vuelca los valores en el buffer de SPRATR
	ld	[hl], d
	inc	hl
	ld	[hl], e
	inc	hl
	ld	[hl], c
	inc	hl
	ld	[hl], b
	ret
; -----------------------------------------------------------------------------

; EOF