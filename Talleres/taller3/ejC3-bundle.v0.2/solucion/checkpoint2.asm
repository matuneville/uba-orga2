extern sumar_c
extern restar_c
;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS

global alternate_sum_4
global alternate_sum_4_simplified
global alternate_sum_8
global product_2_f
global alternate_sum_4_using_c

;########### DEFINICION DE FUNCIONES
; uint32_t alternate_sum_4(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[RDI], x2[RSI], x3[RDX], x4[RCX]
alternate_sum_4:
	;prologo EL CALL PUSHEA 64 BITS = 8B ENTONCES QUEDA DESALINEADO PQ ANTES SIEMPRE DEBE ESTAR ALINEADA DE A 16B
	; COMPLETAR
	push	rbp ; alinea aca a 16
	mov 	rbp, rsp
	

	;recordar que si la pila estaba alineada a 16 al hacer la llamada
	;con el push de RIP como efecto del CALL queda alineada a 8
	
	mov 	rax, rdi
	sub		rax, rsi
	add		rax, rdx
	sub		rax, rcx

	;epilogo
	; COMPLETAR
	pop		rbp
	ret
; uint32_t alternate_sum_4_using_c(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4_using_c:
	;prologo
	push 	rbp ; alineado a 16
	mov 	rbp, rsp

	push 	r12 
	push	r13
	mov		r12, rdx
	mov		r13, rcx
	
	call 	restar_c

	mov		rdi, rax
	mov 	rsi, r12
	call	sumar_c

	mov		rdi, rax
	mov		rsi, r13
	call 	restar_c

	pop		r13	
	pop 	r12				

	;epilogo
	pop rbp
	ret



; uint32_t alternate_sum_4_simplified(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4_simplified:
	mov 	rax, rdi
	sub		rax, rsi
	add		rax, rdx
	sub		rax, rcx

	ret


; uint32_t alternate_sum_8(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4, uint32_t x5, uint32_t x6, uint32_t x7, uint32_t x8);
; registros y pila: x1[rdi], x2[rsi], x3[rdx], x4[rcx], x5[r8d], x6[r9d], x7[rbp + 0x10], x8[rbp + 0x18]
alternate_sum_8:
	;prologo
	push	rbp ;
	mov 	rbp, rsp
	sub		rsp, 0x18
	; COMPLETAR
	mov 	rax, rdi
	sub		rax, rsi 
	add		rax, rdx 
	sub		rax, rcx  
	add		rax, r8
	sub		rax, r9

	mov		r9, [rbp + 0x10] 
	mov		r8, [rbp + 0x18]
	add		rax, r9
	sub		rax, r8
	;epilogo
	add		rsp, 0x18
	pop		rbp
	ret

; SUGERENCIA: investigar uso de instrucciones para convertir enteros a floats y viceversa
;void product_2_f(uint32_t * destination, uint32_t x1, float f1);
;registros: destination[rax], x1[rdi], f1[xmm0]
product_2_f:
	;prologo
	push	rbp ; alinea
	mov 	rsp, rbp

	; funcion
	


	;epilogo
	add     rsp, 0x08
	pop		rbp
	ret


;extern void product_9_f(uint32_t * destination
;, uint32_t x1, float f1, uint32_t x2, float f2, uint32_t x3, float f3, uint32_t x4, float f4
;, uint32_t x5, float f5, uint32_t x6, float f6, uint32_t x7, float f7, uint32_t x8, float f8
;, uint32_t x9, float f9);
;registros y pila: destination[rdi], x1[?], f1[?], x2[?], f2[?], x3[?], f3[?], x4[?], f4[?]
;	, x5[?], f5[?], x6[?], f6[?], x7[?], f7[?], x8[?], f8[?],
;	, x9[?], f9[?]
product_9_f:
	;prologo
	push rbp
	mov rbp, rsp

	;convertimos los flotantes de cada registro xmm en doubles
	; COMPLETAR

	;multiplicamos los doubles en xmm0 <- xmm0 * xmm1, xmmo * xmm2 , ...
	; COMPLETAR

	; convertimos los enteros en doubles y los multiplicamos por xmm0.
	; COMPLETAR

	; epilogo
	pop rbp
	ret


