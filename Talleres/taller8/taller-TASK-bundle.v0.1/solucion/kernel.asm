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
extern IDT_DESC
extern idt_init
extern screen_draw_layout
extern pic_reset
extern pic_enable
extern KERNEL_PAGE_DIR
extern mmu_init
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern tss_init
extern tasks_screen_draw
extern sched_init
extern tasks_init

GDT_IDX_CODE_0 equ 1
GDT_IDX_DATA_0 equ 3
GDT_CODE_0_SEL equ GDT_IDX_CODE_0 << 3 
GDT_DATA_0_SEL equ GDT_IDX_DATA_0 << 3 

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL      GDT_CODE_0_SEL
%define DS_RING_0_SEL      GDT_DATA_0_SEL  

%define TASK_A_CODE_START (0x00018000)

; 0x58 = 01011 000 = indice 11 en la GDT y le agrego 3 ceros para obtener selector
%define SELECTOR_TSS_INICIAL 0x58
; 0x60 = 01100 000 = indice 12 en la GDT y le agrego 3 ceros para obtener selector
%define SELECTOR_TSS_IDLE 0x60 

BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
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
    print_text_rm      start_rm_msg, start_rm_len, 3, 0, 5
    
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
    ; (recuerden que un far jmp se especifica como jmp CS_selector:add ress)
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
    mov es, bx ; hacemos esto porque es segmentacion FLAT
    mov gs, bx 
    mov fs, bx 
    mov ss, bx 

    ; COMPLETAR - Establecer el tope y la base de la pila
    ; los registros que indican dónde está la base y el tope del stack son EBP y ESP
    ; ejercicio 17)
    mov ebp, 0x25000
    mov esp, ebp

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    ; ejercicio 18)
    ; call print_text_pm me daba error
    ; preguntar, por que no es asi ?
    print_text_pm      start_pm_msg, start_pm_len, 3, 0, 0
    pm_mode_loaded:

    ; COMPLETAR - Inicializar pantalla
    call screen_draw_layout

    ;; -------------------------------------------------------------------------- ;;
    ;                           taller paginacion
    
    call mmu_init
    
    call mmu_init_kernel_dir
    ; en el return ya tenemos el address en eax

    ; shl eax, 12    preguntar bien esto porque me marea
    mov cr3, eax
    
    ; le activo el bit 31 que indica Paginacion
    mov ebx, cr0
    or ebx, 0x80000000
    mov cr0, ebx 
    
    paginacion_activada:

    ;; -------------------------------------------------------------------------- ;;
    ;                           taller interrupciones
    ; Ejercicio 3)
    call idt_init
    lidt [IDT_DESC]
    
    ; Ejercicio 5)  
    call pic_reset ; inicializo pic remapeandolo
    call pic_enable ; habilito pic

    ; Ejercicio 10)
    sti ; habilito interrupciones

    int 88
    int 98

    interrupciones_activada:

    ;; -------------------------------------------------------------------------- ;;
    ;                           taller tareas

    call tss_init
    call tasks_screen_draw

    ; cargo tarea inicial
    mov ax, SELECTOR_TSS_INICIAL
    ltr ax

    call sched_init
    call tasks_init

    ; El PIT (Programmable Interrupt Timer) corre a 1193182Hz.
    ; Cada iteracion del clock decrementa un contador interno, cuando éste llega
    ; a cero se emite la interrupción. El valor inicial es 0x0 que indica 65536,
    ; es decir 18.206 Hz
    mov ax, 1000
    out 0x40, al
    rol ax, 8
    out 0x40, al

    ; far jmp a tarea Idle porque esta en otro segmento
    jmp SELECTOR_TSS_IDLE:0 ; offset 0

    tareas_activadas:

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
