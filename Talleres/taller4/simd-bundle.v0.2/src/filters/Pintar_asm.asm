
global Pintar_asm

;void Pintar_asm(unsigned char *src, 	[RDI]     
;              unsigned char *dst,		[RSI]
;              int width,				[RDX]
;              int height,				[RCX]
;              int src_row_size,		[R8] 
;              int dst_row_size);		[R9]

Pintar_asm:
	push rbp
	mov rbp, rsp

	push rbx ; usamos para offset
	xor rbp, rbp

	movdqu xmm1, 0xFF000000 ; pixel negro, hay que ponerlo en .rodata POR 4 VECES PARA LLENAR DE 4 PIXELES NEGROS
	modqu  xmm2, 0xFFFFFFFF ; pixel blanco, hay que ponerlo en .rodata

	fila_superior:
		cmp rbx, rdx
		je fin_fila_sup

		; cargo pixel negro a dst
		movdqu [dst+rbx], xmm1

		
		
		; lo movemos a [rsi]


	pop rbp
	ret
	


