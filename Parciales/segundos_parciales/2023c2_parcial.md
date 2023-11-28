# Segundo Parcial: Segundo Cuatrimestre 2023

## Ejercicio 1

Se desea construir un sistema similar al del taller que debe ejecutar concurrentemente 5 tareas independientes. Las tareas de este sistema utilizarán el registro _ecx_ como reservado, el cual al ser un registro de la tarea, este puede ser modificado y seteado en cualquier momento. El registro _ecx_ contendrá en todo momento un número de ticks del reloj denominado UTC (Unreal Time Clock) el cual será actualizado por el sistema incrementándolo cada vez que la tarea vuelva a ser ejecutada luego de una interrupción de reloj. Tener en cuenta que este valor solo esta guardado en un único lugar que se corresponde siempre con el espacio dedicado a los _ecx_ de cada tarea.  

Por otro lado, el sistema cuenta además con el servicio _fuiLlamadaMasVeces_ que permite que una tarea pregunte si el UTC de otra tarea es menor que el suyo. Este servicio espera en _edi_ el ID de la tarea por la que se esta preguntando (los IDs van del 0 al 4) y devuelve el resultado en _eax_. El resultado será 0 si la tarea llamadora tiene un UTC menor o igual que la tarea por la que preguntó y 1 en caso contrario.

### Inciso A

**Describir qué entradas están presentes en la GDT indicando los campos que consideren relevantes.**  

En la GDT tenemos:

- un descriptor nulo en 1ra posición
- un descriptor de segmento de código de nivel 0 de ejecucion/lectura
- un descriptor de segmento de código de nivel 3 de ejecucion/lectura
- un descriptor de segmento de datos de nivel 0 de lectura/escritura
- un descriptor de segmento de datos de nivel 3 de lectura/escritura
- un descriptor de segmento de video de nivel 3 de lectura/escritura

Estos tienen en sus atrubutos el bit DPL en 0 o 3 según su nivel, el bit P de presente en 1 (excepto el nulo), el bit S que indica que son de code/data y no de sistema (excepto el nulo), entre otros.  

Por otro lado, tenemos los descriptores de TSS por cada una de las 5 tareas, que tienen el bit S en 0 (pues son del sistema), con DPL en 0 (porque solo se puede acceder a las TSS con privilegio 0).  

También están las 2 TSS de la tarea inicial y la idle.

### Inciso B

**Describir qué deben modificar respecto del sistema del taller para que el valor UTC se actualice correctamente en los _ecx_ de cada tarea.**  
 
Para que el valor UTC se actualice en los _ecx_ de cada tarea, debemos modificar la rutina de atención a interrupción del reloj para que cada vez que se vaya a cambiar de tarea, se aumente el _ecx_ de la tarea a la que se va a saltar en 1 unidad.  

Esto hay que hacerlo accediendo al _ecx_ guardado en la pila de nivel 0, ya que sino al saltar a esta tarea, la intrucción `popad` (de a rutina del reloj) restauraría los registros a como estaban en la tarea antes de que fuera pausada la ultima vez.  

Para acceder al _ecx_, necesitamos buscar la TSS de la tarea a la que saltaremos, ya que ahí estará el _esp_. El _ecx_ se encuentra en _esp_+24.  

Entonces los pasos a seguir serían:
1. Buscar el id de la próxima tarea a ejecutar (llamémosla A)
2. Obtener el selector de A para poder saltar
3. Obtener la TSS de A, y buscar el ESP
4. Movernos en la pila de nivel 0 hasta ESP+28, y en ese lugar está el ECX de A
5. Incrementamos en 1
6. realizamos el salto a como normalmente lo hariamos

Obs: Asumo que la tarea A fue desalojado por el reloj al menos 1 vez


### Inciso C

**Describir qué y cómo deben modificar el sistema del taller para poder implementar el servicio _fuiLlamadaMasVeces_**  

Para implementar este servicio debemos crear una nueva syscall. Esta debe obtener el _ecx_ de ambas tareas, compararlos, y devolver 1 o 0 segun corresponda.  

Además, habrá que agregar una entrada a la IDT para que la nueva syscall funcione como interrupción.  

Por último, debemos crear una función auxiliar de C para obtener el UTC de cada tarea.

### Inciso D

**Implementar el servicio _fuiLlamadaMasVeces_ en assembly**  

En `idt.c`, función `idt_init`:
```c
//...
IDT_ENTRY3(90)
//...
```

En `isr.asm`:
```asm
extern current_task

global _isr90

_isr90:
    ; reservo un lugar en la pila para poder guardar el rtdo de la funcion y luego popear sin perderlo
    sub esp, 4 

    pushad

    ; pusheo el id de la tarea llamadora
    push dword, [current_task]
    call obtener_UTC
    ; ahora en eax tengo el UTC de la llamadora
    mov ecx, eax
    push edi ; pusheo el id de la otra
    call obtener_UTC ; en eax ahora esta el UTC de la otra
    add esp, 8

    cmp ecx, eax ; comparamos los UTC
    jg .return_uno

    mov [esp+32], 0 ; pongo 0 en [esp+32] ya que por el pushad ocupa 32 bytes (pushea 8 registros de 4B cada uno)

    jmp .fin

    .return_uno
        mov [esp+32], 1

    .fin
        popad
        pop eax ; recupero el resultado en eax
        iret
```

en C:

```c
uint32_t obtener_UTC(uint32_t task_id){
    tss_t tss_tarea = tss_tasks[task_id];
    uint32_t UTC_tarea = tss_tarea.ecx;
    return UTC_tarea;
}
```

## Ejercicio 2

Por un lado tienen un sistema similar al utilizado en el taller de la materia y por el otro una colección de software originalmente diseñado para correr en nivel cero. Los programas de dicha colección de software utilizaban la instrucción HLT para apagar la computadora una vez habian terminado su trabajo. Por razones obvias, no podemos permitir esto en un sistema multitarea.  

Se solicita adaptar el sistema implementado en los talleres para que se puedan utilizar estos programas en nivel de usuario y sin modificaciones. Cuando éstos intenten ejecutar HLT, el sistema operativo debe interpretar esa acción como una solicitud de "fin de la tarea".  

### Inciso A

- a. ¿Qué excepción ocurrirá cuando un proceso no privilegiado intente ejecutar HLT?  

Si un proceso no privilegiado intenta ejecutar HLT se produce una excepción n° 13: General Protection Exception

### Inciso B

- b. ¿Cómo puede determinar que la instrucción que se quiso ejecutar es HLT?  

La excepcion se genero desde un nivel de privilegio distinto a 0. Entonces, al ir a la RAI de la General Protection Fault, se produce un cambio en el nivel de privilegio, a un nivel 0.  

Además, al ir al código de la RAI, en la pila de nivel 0 se pushean varias cosas, y queda de la siguiente manera:  

| **stack +++** |
|:---------:|  
| |
| SS |
| ESP|
| EFLAGS |
| CS |  
| EIP |
| Error Code|
| |
| **stack ---** | 

La int 13 pushea Error Code, y el ESP apunta ahí.  

Con los datos de la pila podemos obtener el EIP de la intrucción que generó la interrupción.  

Luego, comparamos el primer byte al que apunta el EIP con el opcode de HLT y determinamos si esta fue la instrucción ejecutada (y luego se salta a idle)

### Inciso C

- c. ¿Qué pasos debe seguir para "finalizar" un proceso?  

Para finalizar un proceso debemos:
1. Eliminar la tarea actual: es decir, liberar su slot en el scheduler
2. Buscar la siguiente tarea a ejecutar
3. Activar la tarea encontrada
4. Saltar a la tarea encontrada

### Inciso D

- d. ¿Cómo determinará el próximo proceso a ejecutar?

Lo determinamos a partir de la funcion *sched_next_task*, que recorre el scheduler desde la posición de la tarea actual en adelante, yendo al primer slot y arrancando desde ahi otra vez, hasta llegar a la current_task, en busca de tareas en estado runneable.  

Luego, al encontrar una, devuelve su selector y la pone como current_task.  

### Inciso E

- e. Describa los cambios que debe realizar a las estructuras del sistema para poder agregar el mecanismo solicitado.  

Debemos modificar la RAI de la excepción de GPF.  

Ademas, agregamos una función al scheduler llamada sched_delete_task, que elimina la tarea que se está corriendo del scheduler (asi nos aseguramos que el scheduler no va a ejecutar procesos finalizados).  



### Inciso F

- f. Escriba el pseudocódigo necesario para implementar el mecanismo. Su pseudocódigo debe describir el detalle de las siguientes acciones:

    - Atender la excepción y determinar si es necesario usar el nuevo mecanismo

    - Finalizar el proceso que generó la excepción

    - Abandonar el proceso finalizado saltando a uno todavía vivo

    - Modificar el scheduler (de ser necesario) para que nunca ejecute procesos finalizados  

En isr.asm
```asm
global _isr13
selector: dw 0
offset: dd 0

_isr13:
    pushad

    ; cargamos el EIP de la tarea que generó la excepción
    mov eax, [esp + 4] ; agarro el eip de la pila
    mov al, [eax] ; agarro el primer byte de la instruccion

    ; veo si genero H:T, comparo con el opcode de HLT que es 0xF4
    cmp al, 0xF4
    je .finalizar_tarea

    ; aca llegamos si la GPF no se genero por fault, entonces salto al idle luego de deshabilitar la tarea
    push dword [current_task]
    call sched_disable_task
    ; ahora salto a idle

    add esp, 4 ; ajusto la pila
    jmp (12<<3):0 ; idle es id 12 en gdt, lo transformo en selector poniendole 0 en sus atributos

    ; aca llegamos si la GPF fue generada por HLT
    ; eliminamos la tarea actual del scheduler
    .finalizar_tarea
        push current_task
        call sched_delete_task
        add esp, 4 ; ajusto la pila

        ; saltamos a la siguiente tarea ejecutable
        call sched_next_task ; me deja el selector de la prox task en eax, y la fija como current_task
        mov [selector], ax ; el offset no nos importa
        jmp far [selector] ; uso esto porque el jmp far tiene que usar memoria y no registro (creo)

    .fin
    add esp, 4 ; porque la excepcion GP pushea error_code
    popad
    iret
```


En sched.c
```c
void sched_delete_task(uint8_t task_id){
    sched_tasks[task_id].state = TASK_SLOT_FREE;
}
```