global temperature_asm

section .data



; t(i,j) = ⌊(src.r(i,j) + src.g(i,j) + src.b(i,j))/3⌋
; unsigned char b, g, r, a; !!! 
mask_alpha:             dd 0x00FFFFFF, 0x00FFFFFF, 0x0, 0x0
mask_3s:                times 4 dd 3 ; 0x00000003
mask_4s:                times 8 dd 4 ; 0x0004
mask_1s:                times 4 dd 0xFFFFFFFF
mask_128s:              times 8 dw 128

;dst(i,j) < r, g, b >=

; < 0, 0, 128 + t · 4 > si t < 32
; < 0,(t − 32) · 4, 255 > si 32 ≤ t < 96
; < (t − 96) · 4, 255, 255 − (t − 96) · 4 > si 96 ≤ t < 160
; < 255, 255 − (t − 160) · 4, 0 > si 160 ≤ t < 224
; < 255 − (t − 224) · 4, 0, 0 > si no

; unsigned char b, g, r, a; !!! 
mask_32:                times 8 dw 32
mask_96:                times 8 dw 96
mask_160:               times 8 dw 160
mask_224:               times 8 dw 224
mask_255:               times 8 dw 255

; unsigned char b, g, r, a; !!! 
shuff_c1:               times 2 db 0x02, 0x80, 0x80, 0x00, 0x01, 0x80, 0x80, 0x00  
shuff_c2:               times 2 db 0x00, 0x02, 0x80, 0x00, 0x00, 0x01, 0x80, 0x00
shuff_c3:               times 2 db 0x04, 0x00, 0x02, 0x00, 0x03, 0x00, 0x01, 0x00
shuff_c4:               times 2 db 0x80, 0x02, 0x00, 0x00, 0x80, 0x01, 0x00, 0x00
shuff_c5:               times 2 db 0x80, 0x80, 0x02, 0x00, 0x80, 0x80, 0x01, 0x00

; blend_3:               dq 0x0000000FFFF000000
blend_c3:               times 2 db 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00 ; esto es asi? creo q si


section .text
;void temperature_asm(unsigned char *src, RDI
;              unsigned char *dst, RSI
;              int width, RDX
;              int height, RCX
;              int src_row_size, R8
;              int dst_row_size); R9
temperature_asm:
    push rbp
    mov rbp, rsp

    movdqu xmm12, [mask_alpha]
    movdqu xmm13, [mask_3s]
    cvtdq2ps xmm13, xmm13
    ; vcvtudq2ps zmm13, [mask_3s] probar esto
    movdqu xmm14, [mask_4s]

    imul RDX, RCX

    ciclo_pintar:
        cmp RDX, 0
        je end ; si recorri todo, termino

        movq xmm0, [RDI]
        pand xmm0, xmm12 ; quito alpha en 2 pixeles
        ; no puedo trabajar de a 4 pixeles porque hay que hacer divisiones con single floats, similar al problema del primer parcial

        ; extiendo a 16b, luego sumo entre si
        pmovzxbw xmm0, xmm0
        phaddsw xmm0, xmm0
        phaddsw xmm0, xmm0

        ;extiendo a 32b, luego en packed single floats y divido entre 3
        pmovzxwd xmm0, xmm0
        cvtdq2ps xmm0, xmm0
        divps xmm0, xmm13
        cvttps2dq xmm0, xmm0
        packusdw xmm0, xmm0

        ; ---- ---- c1: t < 32 ? ---- ----
        ; < 0, 0, 128 + t · 4 > si t < 32 
        ; ---- ---- ---- ---- ---- ---- ----
        movdqu xmm1, [mask_32] ; aplico mascara correspondiente
        pcmpgtw xmm1, xmm0 ; comparo t
        movdqu xmm11, xmm1
        pand xmm1, xmm0 ; keep t segun caso

        paddusw xmm1, xmm1
        paddusw xmm1, xmm1

        movdqu xmm10, [mask_128s] ;cargo 128
        paddusw xmm1, xmm10

        pand xmm1, xmm11
        movdqu xmm7, xmm11

        ; transformo en pixel
        pshuflw xmm11, xmm11, 0x50
        pshufhw xmm11, xmm11, 0x50
        packuswb xmm1, xmm1

        mov R10D, 255
        pinsrb xmm1, R10D, 0

        movdqu xmm8, [shuff_c1]
        pshufb xmm1, xmm8
        
        pand xmm1, xmm11 ; limpio y esto lo voy a hacer siempre
        movdqu xmm11, xmm7

        ; ---- ---- c2: 32 < t < 96 ? ---- ----
        ; < 0,(t − 32) · 4, 255 > si 32 ≤ t < 96
        ; ---- ---- ---- ---- ---- ---- ----
        movdqu xmm2, [mask_96]
        movdqu xmm8, [mask_1s]
        pandn xmm11, xmm8
        ; basicamente hago lo mismo en cada caso, es medio repetitivo

        pcmpgtw xmm2, xmm0

        pand xmm2, xmm11
        movdqu xmm11, xmm2
        pand xmm2, xmm0

        movdqu xmm10, [mask_32]
        psubusw xmm2, xmm10 ; todos menos 32

        paddusw xmm2, xmm2
        paddusw xmm2, xmm2

        pand xmm2, xmm11

        pshuflw xmm11, xmm11, 0x50
        pshufhw xmm11, xmm11, 0x50 ; shuffleo para pixeles nuevos
        packuswb xmm2, xmm2

        mov R10D, 255
        pinsrb xmm2, R10D, 0

        movdqu xmm8, [shuff_c2]
        pshufb xmm2, xmm8

        pand xmm2, xmm11

        ; ---- ---- c3: 96 < t < 160 ? ---- ----
        ; < (t − 96) · 4, 255, 255 − (t − 96) · 4 > si 96 ≤ t < 160
        ; ---- ---- ---- ---- ---- ---- ----
        movdqu xmm11, [mask_96]
        pcmpgtw xmm11, xmm0
        movdqu xmm8, [mask_1s]
        ;96 < t
        pandn xmm11, xmm8 

        movdqu xmm3, [mask_160]
        ; t < 160
        pcmpgtw xmm3, xmm0 

        pand xmm3, xmm11
        movdqu xmm11, xmm3

        pand xmm3, xmm0

        movdqu xmm10, [mask_96]
        psubusw xmm3, xmm10 ; resto 96 a c/u

        paddusw xmm3, xmm3
        paddusw xmm3, xmm3
        pand xmm3, xmm11

        pshuflw xmm11, xmm11, 0x50
        pshufhw xmm11, xmm11, 0x50 ; shuffleo para pixeles nuevos
        packuswb xmm3, xmm3

        movdqu xmm10, [mask_1s]
        psubusb xmm10, xmm3 ;resto 255s

        mov R10D, 255
        pinsrb xmm3, R10D, 0 

        movdqu xmm15, xmm0
        movdqu xmm0, [blend_c3] ; blend choto creo que funciona bien
        pblendvb xmm3, xmm10

        movdqu xmm8, [shuff_c3]
        pshufb xmm3, xmm8 ; shuffleo como corresponde en caso 3
        pand xmm3, xmm11

        ; ---- ---- c4: 160 < t < 224 ? ---- ----
        ; < 255, 255 − (t − 160) · 4, 0 > si 160 ≤ t < 224
        ; ---- ---- ---- ---- ---- ---- ----
        movdqu xmm11, [mask_160]
        pcmpgtw xmm11, xmm15
        movdqu xmm8, [mask_1s]
        ; 160 <= t
        pandn xmm11, xmm8 

        movdqu xmm4, [mask_224]
        ; t < 224
        pcmpgtw xmm4, xmm15 
        pand xmm4, xmm11
        movdqu xmm11, xmm4

        pand xmm4, xmm15

        movdqu xmm10, [mask_160]
        psubusw xmm4, xmm10 ; restar 160s, es siempre lo mismo esto
        ; .
        ; '¿9

        paddusw xmm4, xmm4
        paddusw xmm4, xmm4

        movdqu xmm10, [mask_255]
        psubusw xmm10, xmm4
        movdqu xmm4, xmm10

        pand xmm4, xmm11
        pshuflw xmm11, xmm11, 0x50
        pshufhw xmm11, xmm11, 0x50
        packuswb xmm4, xmm4

        mov R10D, 255
        pinsrb xmm4, R10D, 0

        movdqu xmm8, [shuff_c4]
         ; shuffleo caso 4
        pshufb xmm4, xmm8

        pand xmm4, xmm11

        ; ---- ---- c5: 224 < t ? ---- ----
        ; < 255 − (t − 224) · 4, 0, 0 > si no
        ; ---- ---- ---- ---- ---- ---- ----
        movdqu xmm5, [mask_224]
        pcmpgtw xmm5, xmm15
        movdqu xmm8, [mask_1s]
        pandn xmm5, xmm8
        ; t < 224

        movdqu xmm11, xmm5
        pand xmm5, xmm15

        ;movdqu xmm10, [mask_160]
        ;psubusw xmm4, xmm10 ; restar 160s, es siempre lo mismo esto
        movdqu xmm10, [mask_224]
        ; restar 224s aca ...
        ;
        psubusw xmm5, xmm10
        ;

        paddusw xmm5, xmm5 ; sumo como corresponde aca
        paddusw xmm5, xmm5

        movdqu xmm10, [mask_255]
        ; resto 255s aca ...
        ;
        psubusw xmm10, xmm5
        movdqu xmm5, xmm10

        pand xmm5, xmm11
        pshuflw xmm11, xmm11, 0x50
        pshufhw xmm11, xmm11, 0x50
        packuswb xmm5, xmm5

        mov R10D, 255
        pinsrb xmm5, R10D, 0 

        movdqu xmm8, [shuff_c5]
        ;; shuffleo cas 5
        pshufb xmm5, xmm8 

        pand xmm5, xmm11

        ; ---- #### ---- #### ----
        ; LISTOOOO junto todo ahora y escribo en destino 
        por xmm5, xmm4
        ; tambien puedo sumar pero es mas lindo con ORs je
        por xmm5, xmm3
        por xmm5, xmm2
        por xmm5, xmm1

        movq [RSI], xmm5 ; escribo destino

        add RDI, 8 ; avanzo 2 pixeles
        add RSI, 8 ; avanzo 2 pixeles
        sub RDX, 2 ; descuento 2 pixeles

        jmp ciclo_pintar

    end:

    pop rbp
    ret