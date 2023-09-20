global temperature_asm

section .rodata
    mascara: times 2 dq 0x0000FFFFFFFFFFFF
    
    div_3: times 4 dd 3.0 ; si no anda esto metemos un cvt

    ; o sino directamente 0x0000FFFFFFFFFFFF0000FFFFFFFFFFFF

section .text
;void Pintar_asm(unsigned char *src, 	[RDI]     
;              unsigned char *dst,		[RSI]
;              int width,				[RDX]
;              int height,				[RCX]
;              int src_row_size,		[R8] 
;              int dst_row_size);		[R9]

temperature_asm:

    push rbp
	mov rbp, rsp

	push rbx ; usamos RBX para offset de columna
	xor rbx, rbx

	push r12 ; R12 va a guardar width*4
	push r13 ; contador de linea
    push r14 ; contador de 4 pixeles
    push r15 ; formar nuevo pixel

    ; mov r12, rdx
	; mul r12, 4 
	xor r13, r13

    pxor xmm2, xmm2 ; inicializo ceros
    movdqu xmm6, [mascara] ; inicializo mascara para quitar Transparencia
    movdqu xmm7, [div_3] ; inicializo los 3 para division
    
    ciclo:
        cmp r13, rcx
        je end

        cmp rbx, r8
        jne sigo3
        add rsi, r8
        add rdi, r8
        xor rbx, rbx
        inc r13
        jmp ciclo


        sigo3:
        pmovzxbw xmm0, [rdi + rbx] ;extendemos cada byte con 0

        pand xmm0, xmm6 ; hago un and bitwise con mascara
                                                                                                             
        phaddw xmm0, xmm0 ; sumamos r+g y b+0
        phaddw xmm0, xmm0 ; sumamos (r+g)+b

        ; punpcklwd xmm0, xmm2 ;extendemos cada byte con 0
        pmovzxwd xmm0, xmm0

        cvtdq2ps xmm0, xmm0

        divps xmm0, xmm7 ; dividimos las t por 3

        cvttps2dq xmm0, xmm0

        mov r14, 2 ; contador para 2 iteraciones de ciclo



    ciclo_fun:
        movd eax, xmm1 ; traigo 32 bits de la t
        psrld xmm1, 4 ; shifteo la sgte t

        cmp r14, 0
        je ciclo

        dec r14

        jmp apply_fun


    end:
    pop r15
    pop r14
    pop r13
    pop r12 
    pop rbx
    pop rbp

    ret


apply_fun:
    cmp eax, 32
    jl apply_fun_l_32
    cmp eax, 96
    jl  apply_fun_l_96
    cmp eax, 160
    jl apply_fun_l_160
    cmp eax, 224
    jl apply_fun_l_224 

    jmp apply_fun_h_224


apply_fun_l_32:
    xor r15, r15

    add r15d, 0xFF ; transparencia
    shl r15d, 1

    imul eax, 4

    add ax, 128 
    add r15d, eax; blue
    shl r15d, 1 

    shl r15d, 1 ;green

    shl r15d, 1 ; red
    
    mov [rsi+rbx],r15d ; paso al destino el color final
    inc rbx
    jmp ciclo_fun
    
apply_fun_l_96:
    xor r15, r15

    add r15d, 0xFF ; transparencia
    shl r15d, 1
    
    add r15d, 255 ; blue
    shl r15d, 1

    sub eax, 32
    imul eax, 4 ; green
    shl r15d, 1

    shl r15d, 1 ; red

    mov [rsi+rbx],r15d
    inc rbx
    jmp ciclo_fun


apply_fun_l_160:
    xor r15, r15

    add r15d, 0xFF ; transparencia
    shl r15d, 1

    add r15d, 255
    sub eax, 96
    imul eax, 4
    sub r15d, eax
    shl r15d, 1 ; blue

    add r15d, 255 ; green
    shl r15d, 1

    add r15d, eax

    mov [rsi+rbx],r15d
    inc rbx
    jmp ciclo_fun

apply_fun_l_224: 
    xor r15, r15

    add r15d, 0xFF ; transparencia
    shl r15d, 1

    shl r15d, 1 ; blue

    sub eax, 160
    imul eax, 4
    add r15d, 255
    sub r15d, eax ; green
    shl r15d, 1

    add r15d, 255 ; red

    mov [rsi+rbx],r15d
    inc rbx
    jmp ciclo_fun

apply_fun_h_224:
    xor r15, r15

    add r15d, 0xFF ; transparencia
    shl r15d, 1

    shl r15d, 1 ; blue
                 
    shl r15d, 1 ; green

    add r15d, 255 
    sub eax, 224
    imul eax, 4 
    sub r15d, eax ; red

    mov [rsi+rbx],r15d
    inc rbx
    jmp ciclo_fun⠀⠀⠀ 
