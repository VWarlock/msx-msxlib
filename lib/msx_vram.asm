
; =============================================================================
;	VRAM routines (BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Volcado con repetici�n de un mismo bloque a VRAM
; (rutina original: COPY_BLOCK de Eduardo A. Robsy Petrus)
; param hl: direcci�n RAM del bloque (normalmente CLRTBL)
; param de: direcci�n VRAM destino
; param b: n�mero de bloques a copiar
LDIRVM_BLOCKS:
	push	bc ; preserva el contador
	push	hl ; preserva el origen
	push	de ; preserva el destino
; Vuelca un bloque
	ld	bc, 8
	call	LDIRVM
	pop	hl ; restaura el destino (en hl)
	ld	bc, 8 ; hl += 8
	add	hl, bc
	ex	de, hl ; destino actualizado en de
	pop	hl ; restaura el origen
	pop	bc ; restaura el contador
	djnz	LDIRVM_BLOCKS
	ret
; -----------------------------------------------------------------------------

; =============================================================================
;	VRAM buffers routines (NAMTBL and SPRATR, BIOS-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Vaciado del buffer de pantalla con el car�cter espacio
CLS_NAMTBL:
	ld      hl, namtbl_buffer
	ld      de, namtbl_buffer + 1
	ld      bc, NAMTBL_SIZE - 1
	ld      [hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vaciado del buffer de SPRATR
CLS_SPRATR:
	ld      hl, spratr_buffer
	ld      de, spratr_buffer + 1
	ld      bc, SPRATR_SIZE - 1
	ld      [hl], SPAT_END
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de NAMTBL utilizando la BIOS
LDIRVM_NAMTBL:
	ld	hl, namtbl_buffer
	ld	de, NAMTBL
	ld	bc, NAMTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuleca el buffer de SPRATR utilizando la BIOS
LDIRVM_SPRATR:
	ld	hl, spratr_buffer
	ld	de, SPRATR
	ld	bc, SPRATR_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vac�a NAMTBL, deshabilita sprites y desactiva la pantalla
DISSCR_NO_FADE:
	halt	; (sincronizaci�n antes de desactivar la pantalla)
	call	DISSCR
; Vac�a NAMTBL
	call	CLS
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	jp	WRTVRM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de salida (cortinilla horizontal)
; Vac�a NAMTBL, deshabilita sprites y desactiva la pantalla
DISSCR_FADE_OUT:
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fundido
	ld	hl, NAMTBL
	ld	b, SCR_WIDTH
@@COL:
	push	bc ; preserva contador de columnas
	push	hl ; preserva puntero
	ld	de, SCR_WIDTH
	ld	b, SCR_HEIGHT
	ld	a, $20 ; " " ASCII
@@H_CHAR:
	call	WRTVRM
	add	hl, de
	djnz	@@H_CHAR
	halt
	pop	hl ; restaura puntero
	inc	hl
	pop	bc ; restaura contador de columnas
	djnz	@@COL

; Desactiva la pantalla
	jp	DISSCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca los buffer de NAMTBL y SPRATR y activa la pantalla
ENASCR_NO_FADE:
	halt	; (sincronizaci�n antes del volcado por si la pantalla estaba activada)
	call	LDIRVM_NAMTBL
	call	LDIRVM_SPRATR
	halt	; (sincronizaci�n antes de activar la pantalla)
	jp	ENASCR
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de entrada (cortinilla horizontal)
; Vuelca los buffer de NAMTBL y SPRATR y activa la pantalla
ENASCR_FADE_IN:
; Inicialmente vac�a, tanto NAMTBL como sprites
	ld	hl, NAMTBL
	ld	bc, NAMTBL_SIZE
	ld	a, $20 ; " " ASCII
	call	FILVRM
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Activa la pantalla
	halt	; (sincronizaci�n antes de activar la pantalla)
	call	ENASCR
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Fundido de entrada/salida (cortinilla horizontal),
; de la imagen actual al contenido de NAMTBL
LDIRVM_NAMTBL_FADE_INOUT:
; Deshabilita sprites
	ld	hl, SPRATR
	ld	a, SPAT_END
	call	WRTVRM

; Fundido
	ld	hl, NAMTBL
	ld	de, namtbl_buffer
	ld	c, SCR_WIDTH
@@COL:
	push	hl ; preserva puntero hl
	push	de ; preserva puntero de
	ld	b, SCR_HEIGHT
@@CHAR:
	push	bc ; preserva contadores
; escribe un caracter
	ld	a, [de]
	call	WRTVRM
; baja una posici�n
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl
	add	hl, bc
	ex	de, hl
	pop	bc ; restaura contadores
	djnz	@@CHAR
	push	bc ; preserva contadores
	halt
; se mueve a la derecha una posici�n
	pop	bc ; restaura contadores
	pop	de ; restaura puntero de
	inc	de
	pop	hl ; restaura puntero hl
	inc	hl
	dec	c
	jr	nz, @@COL
	ret
; -----------------------------------------------------------------------------

; =============================================================================
;	NAMTBL buffer text routines
; =============================================================================

; -----------------------------------------------------------------------------
; Escribe un literal centrado horizontalmente
; param hl: origen
; param de: primer caracter de la l�nea destino
; touches a, bc, de, hl
PRINT_TXT:
	call	LOCATE_CENTER
PRINT_TXT_DE_OK:
	xor	a
@@LOOP:
	cp	[hl]
	ret	z
	ldi
	jr	@@LOOP
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Escribe m�ltiples literales centrados horizontalmente
; param hl: origen
; param de: primer caracter de la l�nea destino
; touches a, bc, de, hl
PRINT_FULL_TXT:
	push	de ; preserva el destino
	call	PRINT_TXT
	pop	de ; restaura el destino
; �hay m�s texto pendiente?
	inc	hl ; salta el \0
	ld	a, [hl]
	or	a
	ret	z ; no
; s�: salto de l�nea
	ex	de, hl ; destino en hl
	ld	bc, SCR_WIDTH
	add	hl, bc
	ex	de, hl ; destino en de
	jr	PRINT_FULL_TXT
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Centra horizontalmente un literal
; param hl: origen
; param de: primer caracter de la l�nea destino
; ret de: destino
; touches: a, bc
LOCATE_CENTER:
	push	hl ; preserva origen
; busca el siguiente \0
	xor	a
	ld	bc, SCR_WIDTH +1 ; (+1 para contar el �ltimo dec bc)
	cpir
; centra el puntero de escritura
	sra	b ; bc /= 2
	rr	c
	ex	de, hl ; de += bc (=(32 - longitud) / 2)
	add	hl, bc
	ex	de, hl
	pop	hl ; restaura origen
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Limpia una l�nea
; param hl: primer caracter de la l�nea destino
; touches: bc, de, hl
CLEAR_LINE:
	ld	d, h ; de = hl + 1
	ld	e, l
	inc	de
	ld	bc, SCR_WIDTH -1
	ld	[hl], $20 ; " " ASCII
	ldir
	ret
; -----------------------------------------------------------------------------

; =============================================================================
;	Unpacking to VRAM routines
; =============================================================================

; -----------------------------------------------------------------------------
; Descomprime
; param hl: origen de datos (comprimidos)
; param de: destino en RAM
UNPACK:
	; Pletter (v0.5c1, XL2S Entertainment, asMSX syntax by Jos� Vila Cuadrillero)
	.include	"libext/pletter05c-unpackRam-asmsx.asm"
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime y vuelca a VRAM utilizando el buffer de descompresi�n y la BIOS
; param hl: origen de datos (comprimidos)
; param de: destino en VRAM
; param bc: tama�o a volcar en VRAM
UNPACK_LDIRVM:
	push	de ; preserva la direcci�n VRAM
	push	bc ; preserva el tama�o
; Descomprime
	ld	de, unpack_buffer
	push	de ; preserva la direcci�n del buffer de descompresi�n
	call	UNPACK
; Vuelca a VRAM
	pop	hl ; restaura la direcci�n del buffer de descompresi�n
	pop	bc ; restaura el tama�o
	pop	de ; restaura la direcci�n VRAM
	jp	LDIRVM
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime y vuelca a los tres bancos de patrones utilizando la BIOS
; param hl: origen de datos (comprimidos)
UNPACK_LDIRVM_CHRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CHRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresi�n a los tres bancos de patrones
; utiliznado la BIOS
LDIRVM_CHRTBL:
	ld	de, CHRTBL
	call	LDIRVM_CXRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE
	call	LDIRVM_CXRTBL_BANK
	ld	de, CHRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	jr	LDIRVM_CXRTBL_BANK
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Descomprime y vuelca a los tres bancos de colores utilizando la BIOS
; param hl: origen de datos (comprimidos)
UNPACK_LDIRVM_CLRTBL:
	ld	de, unpack_buffer
	call	UNPACK
	; jr	LDIRVM_CLRTBL ; falls through
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresi�n a los tres bancos de colores
; utiliznado la BIOS
LDIRVM_CLRTBL:
	ld	de, CLRTBL
	call	LDIRVM_CXRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE
	call	LDIRVM_CXRTBL_BANK
	ld	de, CLRTBL + CHRTBL_SIZE + CHRTBL_SIZE
	; jr	LDIRVM_CXRTBL_BANK
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Vuelca el buffer de descompresi�n a un banco completo de patrones o colores
; utilizando la BIOS
; param de: direcci�n VRAM destino
LDIRVM_CXRTBL_BANK:
	ld	hl, unpack_buffer
	ld	bc, CHRTBL_SIZE
	jp	LDIRVM
; -----------------------------------------------------------------------------

; EOF