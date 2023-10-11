global templosClasicos
global cuantosTemplosClasicos

extern malloc

offset_colum_largo  equ 0
offset_nombre       equ 8
offset_colum_corto  equ 16
size_templo         equ 24

; 0  |# 1B #|---- 7B ---| -> colum_largo y padding
; 8  |####### 8B #######| -> nombre
; 16 |# 1B #|---- 7B ---| -> colum_corto y padding
; 24


;########### SECCION DE TEXTO (PROGRAMA)
section .text

cuantosTemplosClasicos: ; cuantosTemplosClasicos_c(templo *temploArr[rdi], size_t temploArr_len[rsi]){
    push RBP
    mov RBP, RSP

    ; el contador de resultado de 32b
    xor EAX, EAX 

    ciclo1:
        ; si ya vi todo el arreglo
        cmp RSI, 0 
        je fin1

        ; agarro N y M del templo actual
        mov R8B, BYTE [RDI + offset_colum_corto] ; N
        mov R9B, BYTE [RDI + offset_colum_largo] ; M

        ; en RDX guardo el resultado 2N+1 para comparar con M
        mov DL, R8B
        shl RDX, 1 ; multiplico por 2
        inc RDX

        cmp DL, R9B
        jne distinto1

        ; si es igual, incremento contador
        inc EAX 

        distinto1:
            add RDI, size_templo ; voy al sgte templo
            dec RSI
            jmp ciclo1

    fin1:
        pop RBP 
        ret



templosClasicos: ; templosClasicos(templo *temploArr[rdi], size_t temploArr_len[rsi]);
    push RBP
    mov RBP, RSP

    push R12
    push R13
    push R14
    push R15
    ; pila alineada a 16B

    mov R14, size_templo

    ; guardo RDI y RSI para no perderlos en el call
    mov R12, RDI
    mov R13, RSI

    ; en RDI y RSI tengo los mismos inputs para la funcion previa
    call cuantosTemplosClasicos

    ;ahora en rax ya tengo el largo de mi arreglo. Reservo #templos * size_struct
    imul RAX, R14

    ; llamo al malloc
    mov RDI, RAX
    call malloc
    ; ahora en RAX ya tengo mi puntero al arreglo reservado
    
    ciclo2:
        ; si ya vi todo el arreglo
        cmp R13, 0 
        je fin2

        ; agarro N y M del templo actual
        mov R8B, BYTE [R12 + offset_colum_corto] ; N
        mov R9B, BYTE [R12 + offset_colum_largo] ; M

        ; en RDX guardo el resultado 2N+1 para comparar con M
        mov DL, R8B
        shl RDX, 1 ; multiplico por 2
        inc RDX

        cmp DL, R9B
        jne distinto2

        mov R10, QWORD [R12 + offset_nombre] ; puntero char nombre
        ; si es igual, guardo el templo en mi arreglo

        mov BYTE [RAX + offset_colum_largo], R9B
        mov [RAX + offset_nombre], R10
        mov BYTE [RAX + offset_colum_corto], R8B
        add RAX, R14

        distinto2:
            ; voy al sgte templo
            add R12, R14
            dec R13
            jmp ciclo2

    fin2:
        pop R15
        pop R14
        pop R13
        pop R12

        pop RBP
        ret