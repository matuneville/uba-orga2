/* ** por compatibilidad se omiten tildes **
================================================================================
 TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Rutinas del controlador de interrupciones.
*/

#include "pic.h"

#define PIC1_PORT 0x20
#define PIC2_PORT 0xA0

// esto que es ????
static __inline __attribute__((always_inline)) void outb(uint32_t port,
                                                         uint8_t data) {
  __asm __volatile("outb %0,%w1" : : "a"(data), "d"(port));
}

void pic_finish1(void) { outb(PIC1_PORT, 0x20); }
void pic_finish2(void) {
  outb(PIC1_PORT, 0x20);
  outb(PIC2_PORT, 0x20);
}

// COMPLETAR: implementar pic_reset()
void pic_reset() {
  // inicializacion PIC 1
  outb(PIC1_PORT, 0x11); // IRQs activas, modo cascada
  outb(PIC1_PORT + 1, 0x20); // int base para pic1 tipo 32
  outb(PIC1_PORT + 1, 0x4); // pic1 master, slave conectado a irq2
  outb(PIC1_PORT + 1, 0x1); // modo no buffered
  outb(PIC1_PORT + 1, 0xFF); // deshabilitamos interrupciones pic1

  // inicializacion PIC 2
  outb(PIC2_PORT, 0x11);  // modo ca
  outb(PIC2_PORT + 1, 0x70); // inicializo a partir de la 0x70
  outb(PIC2_PORT + 1, 0x02); // inicializo
  outb(PIC2_PORT + 1, 0x01); // Modo no Buffered, Fin de interrupcion Normal
  outb(PIC2_PORT + 1, 0xFF);
}

void pic_enable() {
  outb(PIC1_PORT + 1, 0x00);
  outb(PIC2_PORT + 1, 0x00);
}

void pic_disable() {
  outb(PIC1_PORT + 1, 0xFF);
  outb(PIC2_PORT + 1, 0xFF);
}
