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
	xor rbx, rbx

	push r12 ; los usamos para tener height y width y no perderlos
	push r13
	push r14 ; guardo rsi para no perder
	push r15 ; contador de linea
	
	xor r15, r15

	mov r12, rdx ; width
	mov r13, rcx ; height
	mov r14, rsi ; destino

	movdqu  xmm1, 0x000000FF000000FF000000FF000000FF ; pixel negro
	movdqu  xmm2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ; pixel blanco
	movdqu	xmm3, 0x000000FF000000FFFFFFFFFFFFFFFFFF ; pixel negro-blanco
	movdqu  xmm4, 0xFFFFFFFFFFFFFFFF000000FF000000FF ; pixel blanco-negro

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
		cmp r13, 0 
		je end

		; if linea 0 o 1
		cmp r15, 1
		jle pinto_fila_negro

		; pinto izquierda o derecha de negro-blanco o blanco-negro
		cmp rbx, 0
		je pinto_prim_col_negro ; aca el rbx no hay que retornarlo a 0, asi sigue en la misma, ok?

		cmp rbx, r12 - 16 ;
		je pinto_ult_col_negro

		cmp r15, rcx - 2
		jge pinto_fila_negro
		
		movdqu [rsi+rbx], xmm2
		add		rbx, 16
		jmp 	ciclo
		

	
	pinto_fila_negro:
		cmp rbx, width*4  ; evaluar usar un contador de columna en vez de usar el offset, es un bolonqui sino
		jne sigo                 

		xor rbp, rbp
		dec r13
		inc r15
        add rsi, r9
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
        xor     rbx, rbx
        dec     r13
        inc     r15
        add     rsi, r9
        jmp ciclo
		
	end:

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
	


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
