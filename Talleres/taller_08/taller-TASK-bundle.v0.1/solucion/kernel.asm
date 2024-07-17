; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"

global start

; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern print_text_rm
extern print_text_pm
;extern COLOR_FACHERITO
extern A20_enable
extern GDT_DESC
extern screen_draw_layout

extern IDT_DESC
extern idt_init
extern pic_enable
extern pic_reset

extern mmu_init
extern mmu_init_kernel_dir
extern mmu_init_task_dir

extern tss_init
extern tasks_screen_draw
extern sched_nextTask
extern sched_init
extern tasks_init

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0x08 ; 1 0 00
%define DS_RING_0_SEL 0x18 ; 3 0 00

%define KERNEL_PAGE_DIR 0x25000

%define GDT_INITIAL_TASK_SEL    0x58 ; 101 1 0 00

%define GDT_IDLE_TASK_SEL       0x60 ; 110 0 0 00

%define TASK_A_CODE_START (0x00018000)


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
tss_gdt_entry_for_task
    ; Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, 2, 0, 0

    ; Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_enable

    ; Cargar la GDT
    lgdt [GDT_DESC]

    gdt_loaded: 
    
    ; Setear el bit PE del registro CR0
    mov edi, cr0 
    inc edi
    mov cr0, edi

    ; Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido


BITS 32
modo_protegido:
    ; A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov edi, DS_RING_0_SEL
    mov ds, edi
    mov es, edi
    mov gs, edi
    mov fs, edi
    mov ss, edi

    ; Establecer el tope y la base de la pila
    mov ebp, 0x25000
    mov esp, 0x25000

    ; Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 2, 3, 0

    modo_protegido_activado:
    ; Inicializar pantalla
    
    call screen_draw_layout

    ; -------- --------------------------
    ; -------- taller Paginación --------

    call mmu_init

    call mmu_init_kernel_dir
    ; en eax tenemos la paddr del dir
    mov cr3, eax 

    ; activo el bit 31 de cr0 que indica paginacion activa
    mov edi, cr0
    add edi, 0x80000000
    mov cr0, edi

    paginacion_activada:

    ; -------- --------     -------- --------
    ; -------- taller Interrupciones --------

    ; Inicializar IDT y cargarla
    call idt_init
    lidt [IDT_DESC]

    idt_cargada:

    ; Habilito interrupciones externas
    call pic_reset ; remapear PIC
    call pic_enable 

    ; -------- ------------- ------------
    ; -------- taller Tareas --------


    call tss_init

    call tasks_screen_draw
    
    mov ax, GDT_INITIAL_TASK_SEL
    ltr ax 

    call sched_init

    call tasks_init

    ; El PIT (Programmable Interrupt Timer) corre a 1193182Hz.
    ; Cada iteracion del clock decrementa un contador interno, cuando éste llega
    ; a cero se emite la interrupción. El valor inicial es 0x0 que indica 65536,
    ; es decir 18.206 Hz
    mov ax, 1500
    out 0x40, al
    rol ax, 8
    out 0x40, al


    jmp GDT_IDLE_TASK_SEL:0
    ; Esto va a cambiar el valor del registro TR apuntando a la TSS de la tarea Idle y producir el cambio de contexto. Saltar a una tarea es algo que lo va a hacer el Sistema Operativo en nivel 0.

    scheduler_activado:
   
    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
