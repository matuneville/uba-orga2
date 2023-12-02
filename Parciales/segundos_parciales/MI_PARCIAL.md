Ejercicio 1

Ahora las tareas en vez de utilizar la syscall draw (int 88) ahora deben tener acceso directo a memoria de video:
- La memoria fisica de video (0xB8000 - 0xB9FFF) es la que refleja la pantalla real, y solo puede haber una unica tarea en un determinado momento con a memoria fisica de video mapeada
- el resto de las tareas tendran asignadas una pantalla dummy (falsa) en la region fisica 0x1E000 - 0x1FFFF
- la memoria de video de una tarea mapeara siempre en el rango virtual 0x08004000 - 0x08005FFF independientemente si tiene acceso a la pantalla real o no

con el diseño propuesto ha yna unica tarea "actualmente en pantalla" (con acceso a la memoria fisica de video real), las tareas que no se encuentren en pantalla podran escribir a las direcciones virtuales de video pero solo se veran reflejadas en la memoria dummy.  

Soltar la tecla TAB (scancode 0x0F al presionar, 0x9F al soltar) cambiara la tarea actualmente en pantalla a la siguiente de manera ciclica (t1 - t2 - t3 - t1 ...). Se solicita describir los cambios requeridos para implementar esta nueva caracteristica, con una syscall implementada con interrupcion.
Que puedo hacer en el mapeo para que se cambie al detectarse que TAB se suelta?




d) Debo implementar ahora una interrupción de teclado, especificamente que, cuando detecte que se suelta la letra tab, la syscall cambie la tarea que está actualmente en pantalla. Para hacer esto, primero debemos desmapear la memoria de video física (0xB8000 - 0xB9FFF) de la tarea actual y mapearla a la memoria dummy (0x1E000 - 0x1FFFF). Luego, a la siguiente tarea, se le desmapea su memoria dummy y mapear la memoria de video física.  

Puedo asumir que todas las tareas tienen acceso a la pantalla. Entonces cuando se suelte TAB y se salte a la sgte tarea, me fijo en el scheduler cual es la next task que este ACTIVA (y tendra acceso a la pantalla por lo ya dicho). 

El registro CR3 en la arquitectura x86 juega un papel crucial en la traducción de direcciones virtuales a lineales. CR3 apunta al directorio de páginas. La parte PDX de la dirección se indexa en el directorio de páginas para darte una tabla de páginas. La parte PTX se indexa en la tabla de páginas para darte una página, y luego añades los bits bajos1. En resumen, CR3 es esencial para localizar el directorio de páginas, que es el primer paso en la traducción de una dirección virtual a una dirección lineal.



mmu_init_task_dir(paddr_t phy_start): En esta función, agregar un mapeo para la memoria de video. Dependiendo de si la tarea está actualmente en pantalla o no, mapear la memoria de video real o la memoria dummy. Podría agregar un parámetro a esta función para indicar si la tarea está en pantalla o no.
// mapeo de la memoria de video
if (en_pantalla) {
  mmu_map_page(cr3, VIDEO_VIRTUAL, VIDEO_FISICA, MMU_U | MMU_W | MMU_P);
} else {
  mmu_map_page(cr3, VIDEO_VIRTUAL, VIDEO_DUMMY, MMU_U | MMU_W | MMU_P);
}

create_task(tipo_e tipo): Cuando creas una tarea, necesitas decidir si estará en pantalla o no. Podrías mantener un contador de tareas y dar acceso a la pantalla solo a la primera tarea. Luego, pasarías este valor a mmu_init_task_dir.

sched_add_task(uint16_t selector): Esta función parece estar bien para el propósito actual. Sin embargo, si necesitas realizar alguna acción especial cuando cambias la tarea en pantalla, podrías necesitar modificarla.



```c

void cambioDePantalla(uint16_t task_sel, uint32_t cr3){
    uint16_t new_task_sel = sched_next_video_task();

    mmu_unmap_task_page(task_sel, cr3, 0x08004000);
    mmu_map_task_page(task_cel, cr3, 0x08004000, 0x1E000);

    mmu_unmap_task_page(new_task_sel, cr3, 0x08004000);
    mmu_map_task_page(new_task_cel, cr3, 0x08004000, 0xB8000);
}
```




Ejercicio 2

Sistema similar al de los talleres de la materia, que ejecuta concurrentemente 4 tareas independientes. El mapa de memoria virtual es el mimso para las 4, u cada una tiene asignado 1MB para datos. La tarea con ID 1 puede usar el servicio CopiarPagina que recibe un ID de otra tarea en EDI y una virtual address en ESI. Este servicio copia la pagina de la tarea EDI en la vitual address ESI, a la misma virtual address ESI pero de la tarea 1.

Básicamente la tarea de ID 1 podrá utilizar un servicio, que lo definiré con una interrupción para que sea una syscall, que, dado los parámetros que estén en EDI (id de la tarea a hackear) y ESI (direccion virtual de la tarea de EDI a copiar), debe copiar la pagina de la tarea del parámetro ubicada en la dirección virtual indicada, en la misma dirección virtual indicada pero de la tarea llamadora (la de ID 1).  

La implementaré con una interrupción (99) 

En `idt.c`, función `idt_init`:
```c
//...
IDT_ENTRY3(99)
//...
```

```asm
global _isr99

_isr99:
    pushad

    ; aca ya tengo en EDI y ESI de la pila de nivel 0, de la tarea 1, los parámetros
    ; agarro el esp de la funcion llamadora
    mov eax, [esp + 16] 
    ; ahora con el esp, voy y agarro los dos registros de su pila para tenerlos como parametros para llamar a la funcion

    mov eax, [esp + 0] ; agarro EDI
    mov ebx, [esp + 4] ; agarro ESI

    mov ecx, cr3

    push eax
    push ebx
    push ecx

    call CopiarPagina



    .fin
        popad
        iret
```

Usaré la función `void copy_page(paddr_t dst_addr, paddr_t src_addr)` del taller, en mmu.c

```c
void CopiarPagina(uint32_t id, vaddr_t v_dir, uint32_t cr3){
    // tengo que pasar la dirección virtual de tarea parametro y la mia, ambas en v_dir, a direccion logica
    paddr_t phy_task1 = VirtualToPhy(1, v_dir, cr3);
    paddr_t phy_taskSrc = VirtualToPhy(id, v_dir, cr3);

    copy_page(phy_task1, phy_taskSrc);
}


paddr_t VirtualToPhy(uint32_t id_task, vaddr_t v_dir, uint32_t cr3){
    uint16_t task_sel = sched_tasks[id_task].selector;
    uint32_t task_gdt_id = task_sel >> 3;

    gdt_entry_t gdt_entry = get_gdt_entry(id_task);
    uint32_t base = gdt_entry.base_low | (gdt_entry.base_middle << 16) | (gdt_entry.base_high << 24);
    uint32_t linear_address = base + v_dir;


    pd_entry_t pd = (pd_entry_t) cr3; //apunta al principio del page directory 
	pt_entry_t pt = (pd_entry_t) pd[linear_address.dir]; // agarro el entry a la tabla con linear_address.dir, que me da los 10 bits altos
    paddr_t phy_page = pt[linear_address.table] << 12 + linear_address.offset;

    return phy_page;
}
```    




