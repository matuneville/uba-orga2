# Segundo Parcial: Segundo Cuatrimestre 2022

## Ejercicio 1

En un sistema similar al que implementamos en los talleres del curso (modo protegido con paginación activada), se quiere implementar un servicio tal que cualquier tarea del sistema lo pueda invocar mediante la siguiente instrucción:  

`int 100`  

Recibirá los siguientes parámetros (en ese orden):

- `uint32_t virt`, una dirección de página virtual
- `uint32_t phy`, una dirección de página física
- `uint16_t task_sel`, un selector de segmento que apunta a un descriptor de TSS en la GDT


Para pasar los parâmetros a este servicio, se puede escoger una convención arbitraria.  

El servicio en cuestión forzará la ejecución de código comenzando en la dirección física _phy_, mapeado en virt. Tanto la tarea actual como la tarea que sera pasada como parámetro (indicada por su *task_sel*) deben realizar la ejecucion de la pagina fisica en cuestión.  

Para eso, dicho servicio deberá:  

- Realizar los mapeos necesarios
- Modificar los campos necesarios para que la tarea determinada por task sel, retome su ejecu ción en la posición establecida la próxima vez que se conmute a ella.
- Modificar los campos necesarios para que la tarea actual, retome su ejecución en la posición establecida una vez completada la llamada
  

Se recomienda organizar la resolución del ejercicio realizando paso a paso los items mencionados anteriormente.  

- a. Definir o modificar las estructuras de sistema necesarias para que dicho servicio pueda ser invocado  

- b. Implementar dicho servicio (pseudocódigo)

- c. Dar un ejemplo de invocación de dicho servicio  

Detalles de implementación:

- El código en cuestión a donde se salta es de nivel 3

- Los punteros a las pilas de nivel 3 de ambas tareas y el puntero a la pila de nivel O de la tarea pasada por parámetro, deberán ser reinicializados a la base de la pila, teniendo en cuenta que las mismas comienzan al final de la página y no se extienden más que 4096 bytes.

- Asumir que todas las tareas ya fueron alojadas al menos una vez y que el cambio de tareas se hace en la rutina de interrupción de reloj, como en el taller

## Resolución


Para que el servicio pueda ser invocado debemos configurar la entrada n° 100 en la IDT para la nueva syscall, con DPL = 3 ya que queremos disparar la interrupción desde nivel usuario.  

En `idt_init()` agregamos `IDT_ENTRY3(100)`, esta macro configurará la idt entry con base = dirección del símbolo _isr100.   

Una vez llamada la interrupcion 100, continua el codigo del handler en nivel 0, utilizando un funcion C con los tres parametros.  

```asm
extern force_execute

_isr100:
    push edx
    push ecx
    push eax
    push esp
    call force_execute
    add esp, 16
    iret
```

La función debe modificar la pila de nivel 0 para que al hacer iret vayamos a la dirección deseada con la pila nivel 3 resetada. Le pasamos el esp (nivel 0) a la función C para poder calcular los offsets desde un estado conocido  

```c
void force_execute(uint32_t virt, uint32_t phy, uint16_t task_sel, uint32_t esp){
    tss_task_t* curr_task_tss = &tss_tasks[current_task]; // indexo con el id de mi tarea actual

    tss_task_t* other_task_tss = 

}
```

**Ejemplo para segmentacion**  


Lógica:             0x0060:0x00123001

Selector de segmento:
Hex         0x0060
Binario     0000000001100 0 00 (Indice, TI, RPL)
Índice      0xC
TI          0
RPL         00

Offset:             0x00123001
