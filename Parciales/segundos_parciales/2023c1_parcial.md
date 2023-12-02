# Segundo Parcial: Primer Cuatrimestre 2023

## Ejercicio 1 - (70 puntos)
En un sistema similar al que implementamos en los talleres del curso (modo protegido con paginación activada), se tienen 5 tareas en ejecución y una sexta que procesa los resultados enviados por las otras. Cualquiera de estas 5 tareas puede en algún momento realizar una cuenta y enviar el resultado de la misma a la sexta tarea para que lo utilice de manera inmediata. Para ello la tarea que realizó la cuenta guardará el resultado de la misma en EAX. A continuación, la tarea que hizo la cuenta le cederá el tiempo de ejecución que le queda a la tarea que va procesar el resultado (lo recibirá en EAX). Tener en cuenta que la tarea que hizo la cuenta no volverá a ser ejecutada hasta que la otra tarea no haya terminado de utilizar el resultado de la operación realizada.  

Se desea agregar al sistema una syscall para que la tareas después de realizar la cuenta en cuestión puedan cederle el tiempo de ejecución a la tarea que procesará el resultado.  

Se pide:


_Se recomienda organizar la resolución del ejercicio realizando paso a paso los items mencionados anteriormente y explicar las decisiones que toman._   
Detalles de implementación:
  - Las 5 tareas originales corren en nivel 3.
  - La sexta tarea tendrá nivel de privilegio 0.

## Resolución

La idea es: 
1. Agregar la entrada correspondiente en la IDT.
2. Escribo el codigo que atiende la syscall
    - Deshabilito tarea llamadora (con la nueva función)
    - Habilito la tarea 6
    - Cambio la TSS de la tarea 6 para que en eax y ebx esten los valores que necesito (resultado, id de la tarea llamadora)
    - Hago el cambio de tarea, que dispara el cambio de contexto
3. Escribo el codigo de la tarea 6
    - Proceso el resultado
    - Habilito la tarea que la había llamado
    - Deshabilito la tarea 6 y la reinicia (como?)

### Inciso A

- a. Definir o modificar las estructuras de sistema necesarias para que dicho servicio pueda ser invocado.

Debemos agregar una syscall que resuelva el problema planteado, implementandola con interrupciones de software, creando su rutina de atención.  

Le asigno el número de interrupción 90 porque es uno de los disponibles.  

Agregamos a la IDT la entrada correspondiente a esta instrucción con DPL = 3, para que todas las 5 tareas de nivel 3 puedan llamar a este servicio.  

Esto lo hacemos en idt_init, asi se vincula la entrada 90 con el símbolo `_isr90`

### Inciso B

- b. Implementar la syscall que llamarán las tareas.


```asm
global _isr90


_isr90:
    pushad

    ; guardo eax (resultado de la cuenta) en la pila
    push eax
    ; cargo id de la tarea 6 en eax
    mov eax, task_6_id
    ; habilito la tarea 6
    call sched_enable_task ; se habilita tarea 6
    ; deshabilito tarea actual, la que hizo la cuenta, y guardo su id
    call sched_disable_current_task
    mov ebx, eax ; guardo id de la tarea actual por el return previo

    pop eax ; recupero el resultado de la cuenta
    mov [task_6_sel+40], eax ; guardo el resultado en la tss de tarea 6 en donde corresponde eax
    mov [task_6_sel+52], ebx ; guardo el id de la llamadora en la tss de tarea 6 en donde corresponde ebx. Esto se hace para que la tarea 6 sepa cuál es la tarea que realizó la cuenta y pueda reactivarla cuando termine de procesar el resultado.

    str cx; cargo selector de segmento actual en cx
    ; quiero que la actual y la 6 no sean iguales
    cmp task_6_sel, cx
    je .fin

    ; cambio al selector de la tss en la gdt de la tarea 6 y se dispara el cambio de contexto
    mov [selector], task_6_sel
    jmp far [offset]

    .fin
    popad
    iret

```

En cuanto comienza la rutina deshabilitamos el estado de la tarea que realizó la cuenta con sched_disable_task_current, y recién la activamos luego de procesar el resultado en la tarea 6.  

Para sched_disable_task_current podemos modificar sched_disable_task para que devuelva current_task. 

### Inciso C

- c. Dar el pseudo-código de la tarea que procesa resultados (no importa como lo procese).  


```c
void task_6 () {

    /* hago algo */

	sched_enable_task(task_id); // task_id es el id de la tarea llamadora, la del ebx
	sched_disable_task(task_6_id); 
	task_reset(task_6_id); 
}

```

### Inciso D

- d. Mostrar un pseudo-código de la función sched_next_task para que funcione de acuerdo a las necesidades de este sistema.  

Sería igual al del taller hecho en `sched.c` pero con MAX_TASKS siendo 6.  

Podrían surgir problemas si las tareas compartes datos que se esten modificando en paralelo.


## Ejercicio 2

Se desea implementar una modificación sobre un kernel como el de los talleres: en el momento de desalojar una página de memoria que fue modificada ésta se suele escribir a disco, sin embargo se desea modificar el sistema para que no sea escrita a disco si la página fue modificada por una tarea específica.  
Se les pide que hagan una función que, dado el CR3 de la tarea mencionada y la dirección física de la página a desalojar, diga si dicha página debe ser escrita a disco o no.  
La función a implementar es:
`uint8_t Escribir_a_Disco (int32_t cr3, paddr_t phy);`  
Detalles de implementación:
- Si necesitan, pueden asumir que el sistema tiene segmentación flat.
- NO DEBEN modificar las estructuras del kernel para llamar a la función que están creando. Solamente deben programar la función que se pide

### Resolución

Idea: obtener la dirección virtual, y ver en los atributos si está dirty.  

```c
uint8_t Escribir_a_Disco (int32_t cr3, paddr_t phy) {
	pt_entry_t actual;
	for (int i=0; i<1024; i++) { // Para cada entrada de la PD 
		for (int j=0; j<1024; j++) { // Para cada entrada de la PT 
			if (estaMapeada(i,j,cr3) && virtualAFisica(i,j,cr3)==phy) {
				actual = pageTableEntry(i,j,cr3); 
				break; 
            } // o sea vemos si está mapeada la pagina, y si esa direccion es igual a la que estamos buscando. Si lo es, nos quedamos con 
		}
	}
	if (actual.attrs && mmu_d == 1) // chequeo bit dirty, si fue modificado
		return 0; (no hay que copiarla en disco)
	else 
		return 1; 
}


bool estaMapeada(uint32_t i, uint32_t j, uint32_t cr3) {
	pd_entry_t pd = (pd_entry_t) cr3; //apunta al principio del page directory 
	// Verifica si la entrada en la pd con indice i está presente 
	if (pd[i] && mmu_= 1) { // chequeo presente
		pt_entry_t pt = (pd_entry_t) pd[i].page_table_base << 12; // agarro los 20 bits altos con el .page y shifteo 12 asi lo convierto en la direccion fisica de la tabla
		if (pt[j] && mmu_= 1) { // si la pagina en indice j esta presente, esta mapeada
			return true; 
		} else {
			return false; 
		}
	} else {
		return false; 
	}
}

paddr_t virtualAFisica(uint32_t i, uint32_t j, uint32_t cr3) {
	pd_entry_t pd = (pd_entry_t) cr3; 
	pt_entry_t pt = (pt_entry_t) pd[i].page_table_base<<12; 
	return pt[j]; 
}
```