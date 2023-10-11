global acumuladoPorCliente_asm
global en_blacklist_asm
global blacklistComercios_asm
extern malloc 
extern calloc
extern strcmp
extern cant_blacklist




section .data 
%define OFFSET_MONTO 0
%define OFFSET_COMERCIO 8
%define OFFSET_CLIENTE 16
%define OFFSET_APROBADO 17
%define SIZE_STRUCT 24


;########### SECCION DE TEXTO (PROGRAMA)
section .text

; uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, 	[RDI]
;								pago_t* arr_pagos 			[RSI])
acumuladoPorCliente_asm:
	push rbp
	mov rbp, rsp

	push r12
	push r13

	mov r12, rdi 
	mov r13, rsi

	mov rdi, 10
	mov rsi, 4 ; reservo espacio para 10 uint 32b
	call calloc				; reservo el espacio para la salida, en rax tengo el puntero

	xor rdx, rdx ; lo uso como contador para recorrer el arreglo

	mov rdi, r12 
	mov rsi, r13

	ciclo_a:
		cmp rdx, rdi
		je fin_a

		mov r8b, byte [rsi + OFFSET_CLIENTE] ; guardo numero de cliente
		mov r9b, byte [rsi + OFFSET_APROBADO]; guardo si es cliente aprobado

		cmp r9d, 1
		jne fin_iteracion_a

		mov r12, [rax + r8]
		inc r12
		mov [rax + r8], r12

		fin_iteracion_a:
			add rsi, SIZE_STRUCT
			inc rdx
			jmp ciclo_a

	fin_a:
		pop r13
		pop r12 
		pop rbp 
		ret


;uint8_t en_blacklist(char* comercio 			[RDI], 
;					  char** lista_comercios 	[RSI],
;					  uint8_t n 				[RDX])
en_blacklist_asm:
	push rbp
	mov rbp, rsp

	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	mov r13, rsi
	mov r14, rdx

	ciclo_b:
		cmp rdx, 0
		je fin_b

		mov r15, [r13]

		mov rdi, r12
		mov rsi, r15 ; el string de la lista

		call strcmp

		dec rdx 
		add r13, 8 ; voy al sgte string

		cmp rax, 0
		je fin_igual

		jmp ciclo_b

	fin_igual:
		mov rax, 1

	fin_b:
		pop r15
		pop r14
		pop r13 
		pop r12
		pop rbp
		ret



; pago_t** blacklistComercios(uint8_t cantidad_pagos, 	[RDI]
;							  pago_t* arr_pagos,	 	[RSI]
;							  char** arr_comercios,		[RDX]
;							  uint8_t size_comercios	[RCX])
blacklistComercios_asm:  
	push rbp
	mov rbp, rsp

	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rsp, 8

	mov r12, rdi
	mov r13, rsi
	mov r14, rdx
	mov r15, rcx

	call cant_blacklist ; me dice cuantos hay que blacklistear para armar el arreglo

	mov rdi, rax
	imul rdi, 8 ; como son punteros tienen que ser de 64b

	call malloc

	; ahora guardo en rbx el rax que tiene el puntero a arreglo nuevo
	mov rbx, rax

	mov r9, r13

	ciclo_c:
		cmp r12, 0
		je fin_c

		mov rdi, [r9 + OFFSET_COMERCIO]
		mov rsi, r14
		mov rdx, r15

		call en_blacklist_asm
		cmp rax, 1
		jne sigo
		
		; si es true, añado el puntero a pago al arreglo
		mov r8, r13
		mov [rbx], r8
		add rbx, 8

		sigo:
			lea r13, [r13 + 8]
			mov r9, r13
			dec r12
			jmp ciclo_c


	fin_c:
		add rsp, 8
		pop rbx
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
		ret