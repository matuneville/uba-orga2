; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"
;%include "colors.h"
;%include "defines.h"

global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern print_text_rm
extern print_text_pm
extern COLOR_FACHERITO
extern A20_enable
extern GDT_DESC
extern screen_draw_layout

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0x08 ; 1 0 00
%define DS_RING_0_SEL 0x18 ; 3 0 00


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Real Mode (no fake)'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; COMPLETAR - Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, COLOR_FACHERITO, 0, 0

    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_enable

    ; COMPLETAR - Cargar la GDT
    ;lgdt [GDT_DESC + 2] 
    lgdt [GDT_DESC] ; %%% PREGUNTAR POR QUE ES ASI %%%

    gdt_loaded: 
    
    ; COMPLETAR - Setear el bit PE del registro CR0
    mov edi, cr0 
    inc edi
    mov cr0, edi

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido


BITS 32
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov edi, DS_RING_0_SEL
    mov ds, edi
    mov es, edi
    mov gs, edi
    mov fs, edi
    mov ss, edi

    ; COMPLETAR - Establecer el tope y la base de la pila
    mov ebp, 0x25000
    mov esp, 0x25000

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, COLOR_FACHERITO, 3, 0

    modo_protegido_activado:
    ; COMPLETAR - Inicializar pantalla
    
    call screen_draw_layout
   
    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
