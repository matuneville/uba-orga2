OFFSET_A_0 EQU 0
OFFSET_A_1 EQU 8

OFFSET_B_0 EQU 16
OFFSET_B_1 EQU 24

OFFSET_C_0 EQU 32
OFFSET_C_1 EQU 48


section .rodata
  ocho_4_veces: times 4 dd 8
  ; Definir el valor constante 8 como un número de precisión simple (float)

section .text

global checksum_asm

; uint8_t checksum_asm(void* array, uint32_t n)
; RDI: pointer array, RSI: n
checksum_asm:
	push rbp
	mov rbp, rsp
	movdqu	xmm8, [ocho_4_veces]
	ciclo: ; recorremos las ternas
		cmp rsi, 0
		je end_true

		; packeo A
		movq xmm0, [rdi]
		movq xmm1, [rdi+OFFSET_A_1]

		; extiendo ambos
		pmovzxwd xmm0, xmm0 ; word a dword
		pmovzxwd xmm1, xmm1

		; packeo B
		movq xmm2, [rdi+OFFSET_B_0]
		movq xmm3, [rdi+OFFSET_B_1]

		; extiendo ambos
		pmovzxwd xmm2, xmm2
		pmovzxwd xmm3, xmm3

		; sumo termino a termino
		paddd xmm0, xmm2
		paddd xmm1, xmm3

		; A0 + B0 en xmm0
		; A1 + B1 en xmm1

		; multiplico por 8 cada uno de los 4 numeros en A0+B0 y A1+B1
		pmulld xmm0, xmm8
		pmulld xmm1, xmm8

		; packeo C
		movdqu xmm4, [rdi+OFFSET_C_0]
		movdqu xmm5, [rdi+OFFSET_C_1]

		; comparo los resultados previos con C

		pcmpeqd	xmm4, xmm0 ; setea todos 1s o todos 0s, no es por valor packeado
		pcmpeqd	xmm5, xmm1

		movq rax, xmm4
		cmp rax, 0
		je end_false

		psrldq xmm4, 8 ; shifteo la parte alta a la parte baja
		movq rax, xmm4
		cmp rax, 0
		je end_false

		movq rax, xmm5
		cmp rax, 0
		je end_false

		psrldq xmm5, 8 ; shifteo la parte alta a la parte baja
		movq rax, xmm5
		cmp rax, 0
		je end_false

		; si rsi == 0 termina, sino decremento y sigo con el ciclo
		dec rsi
		add rdi, 64
		jmp ciclo

	end_false:
		mov rax, 0
		jmp end
	end_true:
		mov rax, 1
	end:
		pop rbp
		ret



; A = 4 * 16b = 64b = xmm0 primera mitad A0...A3
; A = 4 * 16b = 64b = xmm1 segunda mitad A3...A7



; B = 8 * 16b = 128b = xmm1
; A = 8 * 32b = 256b = 

; A0..A8B0..B8..C0...C8..... cada uno 2B 
;PACKEAS LOS A0 en 

; 8 * 16 + 8 *16 + 8 * 32 = 512b = 64B

; word = 16, quadword = 64, dqw = 128