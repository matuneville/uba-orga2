section .text

global invertirQW_asm

; void invertirQW_asm(uint8_t* p)

invertirQW_asm:
;   prólogo
    push rbp
    mov rbp,rsp

    ;
    movq    xmm0 , [rdi]
    movq    xmm1 , [rdi + 8]

    movq    [rdi], xmm1
    movq    [rdi + 8], xmm0

    ; epílogo
    pop rbp
    ret
