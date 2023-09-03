extern malloc
extern free
extern fprintf

section .data

section .text
; 
global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **
;Asumo que la direccion de a esta en rdi y de b en rsi
; int32_t strCmp(char* a, char* b)
strCmp:
	push rbp
	mov rbp, rsp
	loop1:
		mov CL,[rdi]
		mov DL,[rsi]
		cmp CL, DL
		je  iguales
		jg  mayor
		jl  menor
	
	;caso donde CL Y DL son iguales
	iguales:
		inc rdi
		inc rsi
		mov CL,[rdi] 
		cmp CL, 0
		je final1 ;CL resulto ser nulo
		mov DL,[rsi] 
		cmp DL,0   
		je final2 ;DL resulto ser nulo 
		jmp loop1
	
	;Caso donde CL es Nulo y no sabemos si DL es nulo
	final1:
		mov DL,[rsi]
		cmp Dl, 0
		je finaligual
		jg menor 
	
	;Caso donde DL es Nulo y sabemos que CL no
	final2:
		jmp mayor 
	
	;Final donde A Y B son iguales
	finaligual:
		mov rax, 0
		jmp fin	
	
	;Final donde A es mayor que B
	mayor:
		mov rax, -1
		jmp fin
	
	;Final donde A es menor que B
	menor:
		mov rax, 1
		jmp fin
	
	;Termina la funcion
	fin:
		pop rbp
		ret




; char* strClone(char* a)
strClone:
	push 	rbp
	mov 	rbp, rsp

	push rdi
	
	; tengo que calcular el largo del string
	call strLen
	
	mov rdi, rax
	inc rdi
	; reservo memoria con malloc de C igual al largo del string
	
	call malloc 
	; ahora rax apunta a la memoria reservada
	
	pop rdi ; recupero mi string
	
	loop2:
		mov		cl, [rdi]
		mov     rax, cl
		cmp 	rdi, 0
		jz 		end1
		inc		rax
		inc		rdi
		jmp 	loop2
	
	end1:
		inc rax
		mov [rax], 0
		pop	rbp
		ret



; void strDelete(char* a)
strDelete:
	ret
	

; uint32_t strLen(char* a)
strLen:
    push rbp
    mov rbp, rsp

    xor rax, rax

    loop3:
        mov cl, [rdi]  ; PREGUNTAR POR QUE SOLO FUNCIONA CON ESTO
        cmp cl, 0
        je end2

        inc rax
        inc rdi
        jmp loop3
    end2:
        pop rbp
        ret