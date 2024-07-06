section .rodata
	align 16
	;mask_quitar_palo: times 16 db 0xF0 ; 1111 0000 
	mask_quitar_palo: 	times 16 db 0x0F ; 0000 1111 
	mask_manos_iguales: times 4  dd 0x00FFFFFF ; 00 ff 00 ff 00 ff
	mask_cuento_manos:	times 4  dd 0x00000001
	

section .text

global four_of_a_kind_asm

; uint32_t four_of_a_kind_asm(card_t *hands, uint32_t n);
;rdi -> card_t
;rsi -> n
four_of_a_kind_asm:
	push rbp
	mov rbp, rsp

	movdqa xmm0, [mask_quitar_palo]
	movdqa xmm1, [mask_manos_iguales]
	movdqa xmm4, [mask_cuento_manos]
	xor rax, rax

	ciclo:
		cmp rsi, 0
		je fin

		; agarramos 4 manos (16 cartas)
		movdqu xmm2, [rdi] ; este lo shifteamos
		; le quitamos los palos
		andpd xmm2, xmm0
		movdqu xmm3, xmm2

		; shifteamos 1B a la derecha en cada elemento
		psrld xmm2, 8
		
		; comparamos la mano con la mano shifteada
		pcmpeqb xmm3, xmm2

		; comparamos el res con la mascara manos iguales
		pcmpeqd xmm3, xmm1

		; le pongo un solo 1 a cada mano valida
		andpd xmm3, xmm4

		; sumo horizontal asi obtengo la suma de manos validas
		phaddd xmm3, xmm3
		phaddd xmm3, xmm3

		; en la dword baja tengo el resultado
		movd edx, xmm3
		add eax, edx
		
		add rdi, 16
		sub rsi, 4
		jmp ciclo

	fin:
	pop rbp
	ret

	; 03 03 03 03   04 05 04 04   06 06 06 06   09 08 09 04
	; AND BYTE
	; 00 03 03 03   00 04 05 04   00 06 06 06   00 09 08 09

	; =
	; 00 FF FF FF   00 00 00 FF   00 FF FF FF   00 00 00 00
	;
	; Posible paso extra:
	; CMP DW
	; 00 FF FF FF   00 FF FF FF   00 FF FF FF   00 FF FF FF (mascara manos iguales)
	; =
	; FF FF FF FF   00 00 00 00   FF FF FF FF   00 00 00 00  =  +2
