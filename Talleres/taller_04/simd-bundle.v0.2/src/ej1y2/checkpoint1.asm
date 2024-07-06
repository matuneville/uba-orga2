
section .text

global dot_product_asm

; uint32_t dot_product_asm(uint16_t *p, uint16_t *q, uint32_t length);
; *p: RDI,   *q: RSI,   length: RDX
dot_product_asm:
	PUSH rbp
	MOV rbp, rsp

	XOR rax, rax
	XOR rcx, rcx

	loop_dot_prod:
		CMP rdx, 0
		JE end_dot_prod
	
		PMOVZXWD xmm0, [rdi] ; traigo 4 numeros de P
		PMOVZXWD xmm1, [rsi] ; traigo 4 numeros de Q

		PMULLD xmm0, xmm1 ; multiplico verticalmente

		PHADDD xmm0, xmm0 ; sumo entre ellos y los 64b altos no me importan
		PHADDD xmm0, xmm0 ; sumo nuevamente y me quedo con los 32b bajos

		MOVD ecx, xmm0 ; agarro los 32b bajos que tienen la suma total

		ADD eax, ecx

		SUB rdx, 4 ; resto 4 numeros de length (como contador)
		ADD rdi, 8 ; avanzo 8 bytes (4*16b) para ver los sgtes 4 numeros
		ADD rsi, 8
		JMP loop_dot_prod

	end_dot_prod:
	POP rbp
	RET
