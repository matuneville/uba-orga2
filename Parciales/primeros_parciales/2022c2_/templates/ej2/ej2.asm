extern malloc
global filtro

;########### SECCION DE DATOS
section .data
mask_shuff: db 0,1,4,5,8,9,12,13,2,3,6,7,10,11,14,15

;########### SECCION DE TEXTO (PROGRAMA)
section .text


; el arreglo es de tipo | R0 | L0 | R1 | L1 | R2 | L2 | ... | Rn | Ln |
; Ri y Li ocupan 16b cada uno. O sea Ri + Li = 32b = 4B
; en un xmmi me entran 16B -> 4 datos | Ri | Li |

;int16_t* filtro (const int16_t* entrada [RDI], unsigned size [RSI])
filtro:
push RBP
mov RBP, RSP

push R12
push R13

mov R12, RDI
mov R13, RSI 

; cargo mascara para el shuffle
movdqu XMM0, [mask_shuff]

pxor XMM2, XMM2 ; registro con 0s

; reservo espacio para el arreglo de salida: n * 4B
mov RCX, RSI ; cargo el largo
sub RCX, 3 ; resto 3 del final
shl RCX, 2 ; multiplico x4

; cargo en RDI el 4n y llamo a malloc
mov RDI, RCX
call malloc
; ahora RAX apunta al arreglo reservado

; restablezco RDI y RSI
mov RDI, R12
mov RSI, R13

; aca me guardo la guarda del ciclo
mov RCX, RSI 
sub RCX, 3
shl RCX, 2

ciclo:
    ; veo si terminé de ver el arreglo
    cmp RCX, 0
    je fin 

    ; si no, proceso datos

    ; traigo 4 datos Ri,Li
    movdqu XMM1, [RDI]

    ; tengo que sumar horizontalmente Ri+Ri+1+Ri+2+Ri+3, lo mismo con Li
    ; aplico shuffle
    pshufb XMM1, XMM0

    ; divido primero por 4 cada word para mantenerme en el rango de representacion
    psrlw XMM1, 2

    ; sumo horizontal. me quedan los resultados en los 64b bajos
    phaddsw XMM1, XMM2 ; en los 64b altos hay 0s
    ; sumo horizontal de vuelta y me quedan sumados en los 32b bajos
    phaddsw XMM1, XMM2

    ; traigo a registro comun RDX de 32b los datos
    movd EDX, XMM1

    ; muevo ambos en mi arreglo
    ; movd [RAX], EDX
    mov [RAX], EDX

    add RAX, 4
    add RDI, 4
    dec RCX

    jmp ciclo



fin:
pop R13 
pop R12
pop RBP
ret


