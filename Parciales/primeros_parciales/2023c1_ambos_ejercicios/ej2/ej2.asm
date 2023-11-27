global maximosYMinimos_asm

section .rodata
mask_quitar_transp: times 4 dd 0xFFFFFF00
mask_orden_BRGA: db 0x01+12, 0x03+12, 0x02+12, 0x80+12, 0x01+8, 0x03+8, 0x02+8, 0x80+8, 0x01+4, 0x03+4, 0x02+4, 0x80+4, 0x01, 0x03, 0x02, 0x80
mask_orden_GBRA: db 0x01+12, 0x03+12, 0x02+12, 0x80+12, 0x01+8, 0x03+8, 0x02+8, 0x80+8, 0x01+4, 0x03+4, 0x02+4, 0x80+4, 0x01, 0x03, 0x02, 0x80
mask_pares: times 2 dd 0xFFFFFFFF00000000
mask_impares: times 2 dd 0x00000000FFFFFFFF

;########### SECCION DE TEXTO (PROGRAMA)
section .text
;void maximosYMinimos_asm(uint8_t *src, uint8_t *dst, uint32_t width, uint32_t height)
;los registros quedan con los siguientes valores: 
;rdi = src
;rsi = dst
;rdx = width
;rcx = height

maximosYMinimos_asm:
    push rbp 
    mov rbp, rsp

    ; lo uso para el offset al recorrer la imagen
    xor r8, r8

    ; el ancho en pixeles de cada linea
    mov r9, rdx
    imul r9, 4

    ; traigo mascaras de memoria
    movdqu xmm0, [mask_quitar_transp]
    movdqu xmm6, [mask_orden_BRGA]
    movdqu xmm7, [mask_orden_GBRA]
    movdqu xmm8, [mask_pares]
    movdqu xmm9, [mask_impares]

    ciclo:
        ; si ya vi toda la foto
        cmp rcx, 0
        jl fin

        ; si ya vi todos los pixeles de ancho
        cmp r8, r9
        jne sigo

        dec rcx ; disminuyo height en 1
        xor r8, r8 ; reseteo el offset al principio nuevamente
        add rdi, r9 ; voy a la sgte linea fuente
        add rsi, r9 ; voy a la sgte linea destino
        
        jmp ciclo

        sigo:
            ; traigo 4 pixeles que son        R-G-B-A
            movdqu xmm1, [rdi+r8]

            ; quito la transparencia de cada uno
            pand xmm1, xmm0

            ; copio pixeles y aplico shuffle  B-R-G-A
            movdqu xmm2, xmm1
            pshufb xmm2, xmm6

            ; copio pixeles y aplico shuffle  G-B-R-A
            movdqu xmm3, xmm1
            pshufb xmm3, xmm7

            ; ahora comparo verticalmente max(R,B,G) o min(R,B,G)
            ; ejemplo si RGBA era 6-5-3-0, entonces los shuffles van a ser 3-6-5-0 y 5-3-6-0
            ; y guarda verticalmente    max(6,3,3)-max(5,6,3)-max(3,5,6)-max(0,0,0) = 6,6,6,0

            ; guardo una copia de xmm1 para hacer el minimo despues de mascara
            movdqu xmm4, xmm1

            ; primero aplico maximo a todo
            pmaxub xmm1, xmm2
            pmaxub xmm1, xmm3

            ; aplico minimo a todo
            pminub xmm4, xmm2
            pminub xmm4, xmm3

            ; ahora pongo par-impar-par-impar usando mascara
            ; osea tengo
            ; xmm1: Max1 Max2 Max3 Max4 y lo convierto en   Max1   0      Max3   0
            ; xmm4: Min1 Min2 Min3 Min4 y lo convierto en   0      Min2   0      Min3
            ; entonces sumo empaquetado y ya me queda       Max1   Min2   Max3   Min4
            pand xmm1, xmm8
            pand xmm4, xmm9

            paddd xmm1, xmm4

            ; muevo los 4 pixeles modificados a destino
            movdqu [rsi+r8], xmm1
            

            ; aumento offset a los sgtes 4 pixeles
            add r8, 16

            jmp ciclo


    fin:
    pop rbp 
    ret