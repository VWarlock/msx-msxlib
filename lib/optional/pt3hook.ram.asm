
;
; =============================================================================
;	Rutinas para el uso del replayer PT3 instalado en la interrupci�n
; =============================================================================
;

; Variables de las bibliotecas incluidas
	.include	"libext/pt3-ram.asm"

; Rutina de interrupci�n previamente existente en el hook H.TIMI
old_htimi_hook:
	.ds	HOOK_SIZE
	
; Sincronizaci�n de la m�sica en equipos a 60Hz
replayer_frameskip:
	.byte

; EOF
