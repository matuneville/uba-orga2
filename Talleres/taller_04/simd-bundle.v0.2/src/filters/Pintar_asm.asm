global Pintar_asm

section .rodata
	align 16					;    AARRGGBB
	pixeles_blanco:		times 4 dd 0xFFFFFFFF
	pixeles_negro:		times 4 dd 0xFF000000
	pixeles_col_der:	dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000, 0xFF000000
	pixeles_col_izq:	dd 0xFF000000, 0xFF000000, 0xFFFFFFFF, 0xFFFFFFFF

section .text

; typedef struct bgra_t {
;    unsigned char b, g, r, a;
; }

;void Pintar_asm(unsigned char *src,	[RDI]
;              unsigned char *dst,		[RSI]
;              int width,				[RDX]
;              int height,				[RCX]
;              int src_row_size,		[R8]
;              int dst_row_size);		[R9]


Pintar_asm:
	push rbp
	mov rbp, rsp

	push r12
	push r13

	movdqa xmm0, [pixeles_negro]
	movdqa xmm1, [pixeles_blanco]
	movdqa xmm2, [pixeles_col_izq]
	movdqa xmm3, [pixeles_col_der]

	xor r8, r8 ; cuento pixeles de ancho
	xor r9, r9 ; cuento pixeles de alto

	mov r12, rcx ; ultimas dos lineas
	sub r12, 3

	mov r13, rdx ; ultima columna
	sub r13, 4

	ciclo:
		; termine de recorrer imagen
		cmp r9, rcx 
		je end

		; termine de recorrer linea actual
		cmp r8, rdx 
		jne misma_linea
		inc r9 ; salto a linea sgte
		xor r8, r8	; reseteo columna
		jmp ciclo

		misma_linea:
		cmp r9, 2
		jl linea_negra

		cmp r9, r12
		jg linea_negra

		cmp r8, 0
		je col_izq

		cmp r8, r13
		je col_der

		jmp linea_blanca

		continue:
		add rsi, 16 ; avanzo en dst
		add r8, 4 ; avanzo 4 pixeles de ancho
		jmp ciclo


		linea_negra:
			movdqu [rsi], xmm0
			jmp continue

		linea_blanca:
			movdqu [rsi], xmm1
			jmp continue

		col_izq:
			movdqu [rsi], xmm2
			jmp continue

		col_der:
			movdqu [rsi], xmm3
			jmp continue
	
	end:

	pop r13
	pop r12

	pop rbp
	ret