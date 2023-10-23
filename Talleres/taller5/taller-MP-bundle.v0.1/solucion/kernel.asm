; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"

global start

; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern print_text_rm
extern print_text_pm
extern C_FG_CYAN ; no funca usar el color asi
extern A20_enable
extern GDT_DESC
extern screen_draw_layout

;extern GDT_CODE_0_SEL
;extern GDT_DATA_0_SEL

; preguntar por que no podemos usar lo de arriba !!!
; tuvimos que redefinir todo lo del defines.h de nuevo   :(

GDT_IDX_CODE_0 equ 1
GDT_IDX_DATA_0 equ 3
GDT_CODE_0_SEL equ GDT_IDX_CODE_0 << 3 
GDT_DATA_0_SEL equ GDT_IDX_DATA_0 << 3 

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL      GDT_CODE_0_SEL
%define DS_RING_0_SEL      GDT_DATA_0_SEL  


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real hola FURFI GOD'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; ejercicio 9)
    ; COMPLETAR - Deshabilitar interrupciones LISTO
    cli ; clear interrupt flag

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    ; call print_text_rm me daba error
    ; preguntar, por que no es asi ?
    call print_text_rm      start_rm_msg, start_rm_len, 3, 0, 0 ; fila y columna ??
    
    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_enable

    ; COMPLETAR - Cargar la GDT
    ; ejercicio 11)
    lgdt [GDT_DESC]

    ; CHECKPOINT 1
    gdt_loaded:

    ; COMPLETAR - Setear el bit PE del registro CR0
    ; los registros de control son de 32b e indican que modo de operacion tiene
    ; SOLO permiten modificarlos mediante mov
    ; ejercicio 14)
    mov ebx, cr0
    or ebx, 1
    mov cr0, ebx
    ; no se permite "or cr0, 1" ya que los registros de control estan "protegidos"

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    ; ejercicio 15)
    jmp CS_RING_0_SEL:modo_protegido
    ; consultar bien esto


BITS 32
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    ; ejercicio 16)
    mov bx, DS_RING_0_SEL 
    mov ds, bx  ; cargo todos los registros selectores para que inicien en segmento de datos de nivel 0
    mov es, bx
    mov gs, bx 
    mov fs, bx 
    mov ss, bx 

    ; COMPLETAR - Establecer el tope y la base de la pila
    ; los registros que indican dónde está la base y el tope del stack son EBP y ESP
    ; ejercicio 17)
    mov ebp, 0x25000
    mov esp, 0x25000

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    ; ejercicio 18)
    ; call print_text_pm me daba error
    ; preguntar, por que no es asi ?
    print_text_pm      start_pm_msg, start_pm_len, 3, 0, 0 ; fila y columna ??

    pm_mode_loaded:

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
