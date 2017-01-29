
	CFG_OPTIONAL_PT3HOOK equ 1

; -----------------------------------------------------------------------------
; PT3 Player (Dioniso, versi�n ROM por MSX-KUN, adaptaci�n asMSX por SapphiRe)
	.include	"libext/pt3-rom.asm"
; -----------------------------------------------------------------------------

;
; =============================================================================
;	Rutinas para el uso del replayer PT3 instalado en la interrupci�n
; =============================================================================
;

; -----------------------------------------------------------------------------
; Descomprime una canci�n, inicializa el reproductor
; y lo instala en la interrupci�n.
; param hl: puntero a la canci�n comprimida
INIT_REPLAYER:
; Descomprime la m�sica
	ld	de, unpack_buffer
	call	UNPACK
; Prepara los valores iniciales del las variables el replayer
	ld	a, 6
	ld	[replayer_frameskip], a
; Con las interrupciones deshabilitadas...
	halt	; sincronizaci�n
	di
; ...instala el reproductor de PT3 en la interrupci�n
	ld	hl, @@HOOK
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
; ...inicializa la reproducci�n
	ld	hl, unpack_buffer -100
	call	PT3_INIT
	ld	hl, PT3_SETUP
	set	0, [hl] ; desactiva loop
; Habilita las interrupciones y finaliza
	ei
	halt	; asegura que se limpie el bit de interrupci�n del VDP
	halt	; TODO duda: �innecesarios? �innecesario uno?
	ret

; Hook a instalar en H.TIMI
@@HOOK:
	jp	@@INTERRUPT
	ret	; padding a 5 bytes (tama�o de un hook)
	ret

; Subrutina que se invocar� en cada interrupci�n
@@INTERRUPT:
; Ejecuta un frame del reproductor musical
	call	REPLAYER_INTERRUPT
; Se ejecuta el hook previo
	jp	old_htimi_hook
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Detiene manualmente el reproductor y lo desinstala de la interrupci�n.
REPLAYER_DONE:
; Silencia el reproductor
	halt	; sincronizaci�n
	call	PT3_MUTE
; Con las interrupciones deshabilitadas, recupera el hook previo
	di
	call	RESTORE_OLD_HTIMI_HOOK
	ei
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Subrutina del reproductor musical.
REPLAYER_INTERRUPT:
; En funci�n de los 50Hz/60Hz...
	ld	a, [frame_rate]
	cp	60
	jr	nz, @@NO_FRAMESKIP ; 50Hz
; 60Hz: comprueba si toca frameskip
	ld	hl, replayer_frameskip
	dec	[hl]
	jr	nz, @@NO_FRAMESKIP ; no
; s�: no reproduce m�sica y restaura el valor de frameskip
	ld	a, 6
	ld	[hl], a
	ret

@@NO_FRAMESKIP:
; frame normal: reproduce m�sica
	; di	; innecesario (estamos en la interrupci�n)
	call	PT3_ROUT
	call	PT3_PLAY
	; ei	; innecesario (estamos en la interrupci�n)
; comprueba si se ha llegado al final de la canci�n
	ld	hl, PT3_SETUP
	bit	0, [hl]
	ret	z ; no (est� en modo bucle)
	bit	7, [hl]
	ret	z ; no (no ha terminado)
; s�: detiene autom�ticamente el reproductor
; ------VVVV----falls through--------------------------------------------------

; -----------------------------------------------------------------------------
; Desinstala el reproductor recuperando el hook previo.
; Invocar siempre con las interrupciones deshabilitadas
RESTORE_OLD_HTIMI_HOOK:
	ld	hl, old_htimi_hook
	ld	de, HTIMI
	ld	bc, HOOK_SIZE
	ldir
	ret
; -----------------------------------------------------------------------------

; EOF
