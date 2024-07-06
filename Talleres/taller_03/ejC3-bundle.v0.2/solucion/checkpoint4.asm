extern malloc
extern free
extern fprintf

section .data
	msg: db 'NULL',0xa

section .text

global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **

; int32_t strCmp(char* a, char* b) a -> RDI, b -> RSI
strCmp:
	push RBP
	mov RBP, RSP

	xor RAX, RAX

	loop_strCmp:
		mov DL, [RDI] ;a
		mov CL, [RSI] ;b

		cmp DL, 0
		jz A_termina
		cmp CL, 0
		jz A_es_mayor ; si B termina y A no, entonces A es mayor

		cmp DL, CL
		jg A_es_mayor
		jl A_es_menor

		jmp igual_char

	A_termina:
		cmp CL, 0
		jz end_strCmp ; B es cero entonces son iguales
		; aca llega si A termina antes, o sea, es menor
		jmp A_es_menor

	A_es_mayor:
		dec RAX
		jmp end_strCmp
		
	A_es_menor:
		inc RAX
		jmp end_strCmp

	igual_char:
		inc RDI
		inc RSI
		jmp loop_strCmp

	end_strCmp:
	pop RBP
	ret


; char* strClone(char* a) rdi:a
strClone:
	push RBP
	mov RBP, RSP

	push RDI
	sub RSP, 0x8
	
	call strLen

	mov RDI, RAX
	inc RDI
	call malloc
	; ahora en RAX tenemos el puntero al nuevo espacio reservado

	add RSP, 0x08
	pop RDI
	
	mov RSI, RAX

	loop_strClone:
		mov DL, BYTE[RDI] ; DL son los 8 bits menos significativos del registro RDX
		mov BYTE[RSI], DL
		cmp DL, 0
		je end_strClone
		inc RDI
		inc RSI
		jmp loop_strClone

	end_strClone:
	
	pop RBP
	ret

; void strDelete(char* a)
strDelete:
	push RBP
	mov RBP, RSP

	call free

	pop RBP
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	push RBP
	mov RBP, RSP

	cmp BYTE[rdi], 0
	jne continue
	mov rdi, msg

	continue:
	xchg rdi, rsi
	call fprintf

	pop RBP
	ret

; uint32_t strLen(char* a)
strLen:
	push RBP
	mov RBP, RSP
	
	xor RAX, RAX

	loop_strLen:
		mov SIL, BYTE[RDI] ; SIL son los 8 bits bajos de RSI
		cmp SIL, 0
		jz end_strLen
		inc RAX
		inc RDI
		jmp loop_strLen
	
	end_strLen:
	pop RBP
	ret