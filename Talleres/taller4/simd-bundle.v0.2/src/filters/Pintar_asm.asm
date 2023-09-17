global Pintar_asm

section .rodata
	.align 16  # Alinea la sección a 16 bytes (tamaño de un registro XMM)

	color_negro: .quad 0x000000FF000000FF000000FF000000FF

	color_blanco: .quad 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

	color_negro_blanco: .quad 0x000000FF000000FFFFFFFFFFFFFFFFFF

	color_blanco_negro: .quad 0xFFFFFFFFFFFFFFFF000000FF000000FF

;void Pintar_asm(unsigned char *src, 	[RDI]     
;              unsigned char *dst,		[RSI]
;              int width,				[RDX]
;              int height,				[RCX]
;              int src_row_size,		[R8] 
;              int dst_row_size);		[R9]

Pintar_asm:
	push rbp
	mov rbp, rsp

	push rbx ; usamos RBX para offset de columna
	xor rbx, rbx

	push r12 ; R12 va a guardar width*4
	push r13 ; guardo RSI para no perder el primer PIXEL del destino REVISAR SI SE PUEDE SACAR
	push r14 ; contador de linea
	

	; inicializo las variables
	mov r12, rdx
	mul r12, 4
	mov r13, rsi
	xor r14, r14

	movdqa  xmm1, [color_negro] ; pixel negro
	movdqa  xmm2, [color_blanco] ; pixel blanco
	movdqa	xmm3, [color_negro_blanco]; pixel negro-blanco
	movdqa  xmm4, [color_blanco_negro] ; pixel blanco-negro

	; PSEUDOCODIGO
	; while height > 0{

	;    if (linea 1 o 0 or linea height or height-1)
	;		pintamos todo negro
	;	 
	;	 else 
	;		if (columna 0 o 1)
	;			pinto negro-blanco
	;		else if(columna width o width-1)
	;			pinto blanco-negro
	;		else
	;			pinto todo blanco
	;}	
	
	ciclo:
		; si ya pasamos la ultima linea, termina
		cmp r14, rcx
		je end

		; if linea 0 o 1
		cmp r14, 1
		jle pinto_fila_negro

		; if linea h-2 o h-1, o sea ultimas dos
		cmp r14, rcx - 2
		jge pinto_fila_negro

		; pinto izquierda de negro-blanco
		cmp rbx, 0
		je pinto_prim_col_negro ; aca el rbx no hay que retornarlo a 0, asi sigue en la misma, ok?

		; pinto derecha de blanco-negro
		cmp rbx, r12 - 16 ;
		je pinto_ult_col_negro

		
	end:
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret
		

	
	pinto_fila_negro:
		cmp rbx, r12
		jne sigo ; si no termine linea, pinto de negro

		xor rbx, rbx
		inc r14 ; voy a sgte linea con contador
        add rsi, r9 ; apunto a sgte fila destino
		jmp ciclo
			
		sigo:
		movdqu [rsi+rbx], xmm1
		add rbx, 16
		jmp pinto_fila_negro


	pinto_prim_col_negro:
        movdqu [rsi+rbx], xmm3
        add		rbx, 16
        jmp ciclo

    pinto_ult_col_negro:
        movdqu [rsi+rbx], xmm4
        xor     rbx, rbx ; lo llevo a 0 de vuelta
        inc     r14
        add     rsi, r9
        jmp ciclo
		


;⢀⡴⠑⡄⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
;⠸⡇⠀⠿⡀⠀⠀⠀⣀⡴⢿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠑⢄⣠⠾⠁⣀⣄⡈⠙⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⢀⡀⠁⠀⠀⠈⠙⠛⠂⠈⣿⣿⣿⣿⣿⠿⡿⢿⣆⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⢀⡾⣁⣀⠀⠴⠂⠙⣗⡀⠀⢻⣿⣿⠭⢤⣴⣦⣤⣹⠀⠀⠀⢀⢴⣶⣆ 
;⠀⠀⢀⣾⣿⣿⣿⣷⣮⣽⣾⣿⣥⣴⣿⣿⡿⢂⠔⢚⡿⢿⣿⣦⣴⣾⠁⠸⣼⡿ 
;⠀⢀⡞⠁⠙⠻⠿⠟⠉⠀⠛⢹⣿⣿⣿⣿⣿⣌⢤⣼⣿⣾⣿⡟⠉⠀⠀⠀⠀⠀ 
;⠀⣾⣷⣶⠇⠀⠀⣤⣄⣀⡀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀ 
;⠀⠉⠈⠉⠀⠀⢦⡈⢻⣿⣿⣿⣶⣶⣶⣶⣤⣽⡹⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⠉⠲⣽⡻⢿⣿⣿⣿⣿⣿⣿⣷⣜⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⣶⣮⣭⣽⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⣀⣀⣈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
;⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⠿⠿⠿⠛⠉