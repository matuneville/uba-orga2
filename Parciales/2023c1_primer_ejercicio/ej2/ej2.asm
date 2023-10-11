
section .data

CONSTANTE_ROJO dd 0.299
CONSTANTE_VERDE dd 0.587
CONSTANTE_AZUL dd 0.114

;########### SECCION DE TEXTO (PROGRAMA)
section .text

global miraQueCoincidencia
miraQueCoincidencia:    ; void miraQueCoincidencia_c( uint8_t *A[rdi], uint8_t *B[rsi], uint32_t N[rdx], 
                        ;    uint8_t *laCoincidencia[rcx] ){
    ; Prólogo
    push rbp
    mov rbp, rsp
   
    pop rbp
    ret

