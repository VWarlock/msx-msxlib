
; =============================================================================
;	Password encoding/decoding routines
; =============================================================================

; -----------------------------------------------------------------------------
; Password length (in bytes)
	PASSWORD_SIZE:	equ 1 + CFG_PASSWORD_DATA_SIZE * 2 + 1
	
; Salt to obfuscate sequences (000000.. becomes 05AF49..)
	PASSWORD_SALT:		equ $05
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
RESET_PASSWORD:
	ld	a, '0'
	ld	hl, password
	ld	[hl], a
	ld	de, password + 1
	ld	bc, PASSWORD_SIZE - 1
	ldir
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Encodes some bytes as a password
; param hl: the source address
; param b: the number of bytes to encode
; ret [password]: the encoded password
ENCODE_PASSWORD:
; Random first digit
	ld	a, r
	; and	$0f ; unnecessary (because .WRITE_DIGIT implementation)
	ld	c, a ; preserves digit in c
	ld	de, password
	call	.WRITE_DIGIT

; For each byte to encode
	ld	b, CFG_PASSWORD_DATA_SIZE
.LOOP:
; Reads and encodes the high nibble
	ld	a, [hl]
	srl	a
	srl	a
	srl	a
	srl	a
	call	.ENCODE_NIBBLE
; Reads and encodes the low nibble
	ld	a, [hl]
	; and	$0f ; unnecessary (because .WRITE_DIGIT implementation)
	call	.ENCODE_NIBBLE
; Until all the bytes are encoded
	inc	hl
	djnz	.LOOP
	
; Checksum as last digit
	ld	a, c
	add	PASSWORD_SALT
	jr	.WRITE_DIGIT

; Encodes a nibble
; param a: the nibble to encode
; param c: previous digit
; param de: target address
; ret: [de++] = encoded nibble as hexadecimal value in ASCII ('0'..'9','A'..'F')
; ret c: encoded digit
.ENCODE_NIBBLE:
; XOR with the previous digit, then adds the salt
	xor	c
	add	PASSWORD_SALT
	ld	c, a ; preserves digit in c
	; jr	.WRITE_DIGIT ; falls through

; Writes a digit of the password
; param a: hexadecimal value to write ($00..$0f, high nibble ignored)
; param de: target address
; ret: [de++] = '0'..'9','A'..'F'
.WRITE_DIGIT:
	or	$f0	; $f<h>
	daa		; $5<d>, or $6<d>
	add	a, $a0	; $f<d>, or $0<d> and carry flag
	adc	a, $40	; $3<d> or $4<d+1> ('0'..'9' or 'A'..'F')
	ld	[de], a
	inc	de
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Decodes the bytes from the password and validates the password
; param [password]: the hexadecimal password
; ret z/nz: if the password is valid (z) or invalid (nz)
; ret [password_value]: the decoded bytes
DECODE_PASSWORD:
; Reads the random digit
	ld	de, password
	call	.READ_DIGIT
	ld	c, a ; preserves digit in c

; For each byte to encode
	ld	hl, password_value
	ld	b, CFG_PASSWORD_DATA_SIZE
.LOOP:
; Decodes the byte
	call	.DECODE_NIBBLE
	call	.DECODE_NIBBLE
	inc	hl
; Until all the bytes are decoded
	djnz	.LOOP
	
; Reads and checks the checksum digit
	call	.READ_DIGIT
	sub	PASSWORD_SALT
	xor	c
; ret z/nz
	ret

; Decodes a nibble
; param de: source address
; param c: previous digit
; ret a, c: read digit
; ret [hl]: decoded nibble (set with rld)
.DECODE_NIBBLE:
; Reads nibble
	call	.READ_DIGIT
; Substracts the salt, and XOR with the previous digit
	push	af ; preserves digit in a
	sub	PASSWORD_SALT
	xor	c
	rld
; (restores the digit to preserve it in c)
	pop	af ; restores digit in a
	ld	c, a ; preserves digit in c
	ret

; Reads a digit of the password
; param de: source address
; ret a: read hexadecimal value ($00..$0f)
; ret de: next source address (de + 1)
.READ_DIGIT:
	ld	a, [de] ; $3<d> or $4<d+1>
	inc	de
	add	a, $d0  ; $0<d>, or $1<d+1> and carry flag
	cp	10
	ret	c
	add	$F9	; -$10 -1 +$0A
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Reads an hexadecimal digit from the current state of the keyboard matrix
; param hl: digit address
; ret hl: digit address
; ret z/nz: z = no digit was read, nz = a digit was read
INPUT_HEXADECIMAL_DIGIT:
; Checks 0..7
	ld	de, NEWKEY ; 7 6 5 4 3 2 1 0
	ld	a, [de]
	cpl
	or	a
	jr	nz, .0_TO_7; yes: computes digit
; Checks 8..9
	inc	de ; de = NEWKEY +1 = ; ] [ \ = - 9 8
	ld	a, [de]
	cpl
	and	$03
	jr	nz, .8_TO_9 ; yes: computes digit
; Checks A..B
	inc	de ; de = NEWKEY +2 = B A pound / . , ` '
	ld	a, [de]
	cpl
	and	$c0
	jr	nz, .A_TO_B ; yes: computes digit
; Checks C..F
	inc	de ; de = NEWKEY +3 = J I H G F E D C
	ld	a, [de]
	cpl
	and	$0f
	jr	nz, .C_TO_F ; yes: computes digit
; no input
	ret
	
.0_TO_7:
	ld	b, '0'
	jr	.INC_LOOP
.8_TO_9:
	ld	b, '8'
	jr	.INC_LOOP
.C_TO_F:
	ld	b, 'C'
	; jr	.INC_LOOP ; falls through
.INC_LOOP:
	rra
	jr	c, .B_OK
	inc	b
	jr	.INC_LOOP

.A_TO_B:
	ld	b, 'B'
	; jr	.DEC_LOOP ; falls through
.DEC_LOOP:
	rla
	jr	c, .B_OK
	dec	b
	jr	.DEC_LOOP
	
.B_OK:
	ld	[hl], b
; ret nz
	or	$ff
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Increases an hexadecimal digit
; param hl: address
INC_HEXADECIMAL_DIGIT:
; Edge values?
	ld	a, [hl]
	cp	'9'
	jr	nz, .NO_9
; yes : 9 -> A
	ld	[hl], 'A'
	ret
.NO_9:
	cp	'F'
	jr	nz, .NO_F
; yes : F -> 0
	ld	[hl], '0'
	ret
.NO_F:

; No: increases the digit
	inc	[hl]
	ret
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Decreases an hexadecimal digit
; param hl: address
DEC_HEXADECIMAL_DIGIT:
; Edge values?
	ld	a, [hl]
	cp	'0'
	jr	nz, .NO_0
; yes : 0 -> F
	ld	[hl], 'F'
	ret
.NO_0:
	cp	'A'
	jr	nz, .NO_A
; yes : A -> 9
	ld	[hl], '9'
	ret
.NO_A:

; No: decreases the digit
	dec	[hl]
	ret
; -----------------------------------------------------------------------------

; EOF