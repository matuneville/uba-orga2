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
global product_9_f

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
;registros: destination[rdi], x1[rsi], f1[xmm0]
product_2_f:
    ; Prologo
    push    	rbp
    mov     	rbp, rsp
    
    ; convierto x1 a float y lo guardo en xmm1
	cvtsi2ss 	xmm1, rsi
    
    ; multiplicamos xmm0 (f1) por xmm1 (x1 convertido en float)
    mulss   	xmm1, xmm0
    
    ; guardo en rsi el resultado convertido a uint no hay que truncar, probalo asi nomas
	roundss  	xmm1, xmm1, 2
	cvttss2si 	rsi, xmm1 ; la doble t es para truncar decimales
	mov [rdi], rsi

    ; Epilogo
    pop     	rbp
    ret

;extern void product_9_f( uint32_t *destination ; 		¿¿?? suponemos return puntero a double !!
;, uint32_t x1, float f1, uint32_t x2, float f2, uint32_t x3, float f3, uint32_t x4, float f4
;, uint32_t x5, float f5, uint32_t x6, float f6, uint32_t x7, float f7, uint32_t x8, float f8
;, uint32_t x9, float f9);

;registros y pila: destination[rdi], x1[rsi], f1[xmm0], x2[rdx], f2[xmm1], x3[rcx], f3[xmm2], x4[r8], f4[xmm3]
;	, x5[r9], f5[xmm4], x6[rbp+0x10], f6[xmm5], x7[rbp+0x18], f7[xmm6], x8[rbp+0x20], f8[xmm7],
;	, x9[rbp+0x28], f9[rbp+0x30]
product_9_f:
	;prologo
	push 	rbp
	mov 	rbp, rsp
	;convertimos los flotantes de cada registro xmm en doubles
	cvtss2sd 	xmm0, xmm0
	cvtss2sd 	xmm1, xmm1
	cvtss2sd 	xmm2, xmm2
	cvtss2sd 	xmm3, xmm3
	cvtss2sd 	xmm4, xmm4
	cvtss2sd 	xmm5, xmm5
	cvtss2sd 	xmm6, xmm6
	cvtss2sd 	xmm7, xmm7

	
	; COMPLETAR

	;multiplicamos los doubles en xmm0 <- xmm0 * xmm1, xmmo * xmm2 , ...
	; COMPLETAR
	mulsd		xmm0, xmm1
	mulsd		xmm0, xmm2
	mulsd		xmm0, xmm3
	mulsd		xmm0, xmm4
	mulsd		xmm0, xmm5
	mulsd		xmm0, xmm6
	mulsd		xmm0, xmm7

	cvtss2sd	xmm1, [rbp+0x30]
	mulsd		xmm0, xmm1

	; convertimos los enteros en doubles y los multiplicamos por xmm0.
	; COMPLETAR
	cvtsi2sd	xmm1, rsi
	cvtsi2sd	xmm2, rdx
	cvtsi2sd	xmm3, rcx
	cvtsi2sd	xmm4, r8
	cvtsi2sd	xmm5, r9
	cvtsi2sd	xmm6, [rbp+0x10]
	cvtsi2sd	xmm7, [rbp+0x18]

	mulsd		xmm0, xmm1
	mulsd		xmm0, xmm2
	mulsd		xmm0, xmm3
	mulsd		xmm0, xmm4
	mulsd		xmm0, xmm5
	mulsd		xmm0, xmm6
	mulsd		xmm0, xmm7

	cvtsi2sd	xmm1, [rbp+0x20]
	cvtsi2sd	xmm2, [rbp+0x28]	

	mulsd		xmm0, xmm1
	mulsd		xmm0, xmm2

	
	movsd		[rdi], xmm0
	; epilogo
	pop rbp
	ret