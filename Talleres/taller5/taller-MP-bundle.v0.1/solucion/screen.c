/* ** por compatibilidad se omiten tildes **
================================================================================
 TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones de impresion por pantalla.
*/

#include "screen.h"

void print(const char* text, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  int32_t i;
  for (i = 0; text[i] != 0; i++) {
    p[y][x].c = (uint8_t)text[i];
    p[y][x].a = (uint8_t)attr;
    x++;
    if (x == VIDEO_COLS) {
      x = 0;
      y++;
    }
  }
}

void print_dec(uint32_t numero, uint32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  uint32_t i;
  uint8_t letras[16] = "0123456789";

  for (i = 0; i < size; i++) {
    uint32_t resto = numero % 10;
    numero = numero / 10;
    p[y][x + size - i - 1].c = letras[resto];
    p[y][x + size - i - 1].a = attr;
  }
}

void print_hex(uint32_t numero, int32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; 
  int32_t i;
  uint8_t hexa[8];
  uint8_t letras[16] = "0123456789ABCDEF";
  hexa[0] = letras[(numero & 0x0000000F) >> 0];
  hexa[1] = letras[(numero & 0x000000F0) >> 4];
  hexa[2] = letras[(numero & 0x00000F00) >> 8];
  hexa[3] = letras[(numero & 0x0000F000) >> 12];
  hexa[4] = letras[(numero & 0x000F0000) >> 16];
  hexa[5] = letras[(numero & 0x00F00000) >> 20];
  hexa[6] = letras[(numero & 0x0F000000) >> 24];
  hexa[7] = letras[(numero & 0xF0000000) >> 28];
  for (i = 0; i < size; i++) {
    p[y][x + size - i - 1].c = hexa[i];
    p[y][x + size - i - 1].a = attr;
  }
}

/*
Entiendo que esta función lo que hace es dibujar un recuadro que simula una pantalla
utilizando un arreglo (que simula matriz) de "ca", de dimensiones (fSize - fInit) x (cSize - cInit),
poniendo en cada "ca" el mismo char y attribute recibido como argumento.

Ocupará en memoria el tamaño de p, que está definido por VIDEO y VIDEO_COLS
*/ 
void screen_draw_box(uint32_t fInit, uint32_t cInit, uint32_t fSize,
                     uint32_t cSize, uint8_t character, uint8_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; // por que no hace un malloc ?
  uint32_t f;
  uint32_t c;
  for (f = fInit; f < fInit + fSize; f++) {
    for (c = cInit; c < cInit + cSize; c++) {
      p[f][c].c = character;
      p[f][c].a = attr;
    }
  }
} 

/*
Usaremos la funcion anterior como template
Preguntar por qué funciona bien esto?
No tendriamos que recibir el puntero a la memoria de video como argumento?
Por que hay que generar una nueva pantalla?
*/
void screen_draw_layout(void) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO;
  for (uint32_t f = 0; f < VIDEO_FILS; f++) {
    for (uint32_t c = 0; c < VIDEO_COLS; c++) {
      p[f][c].c = 0;
      p[f][c].a = C_BG_BLACK;
    }
  }
  print("Jesse, we need to cook Jesse", 20, 0, C_FG_LIGHT_CYAN + C_BG_BLACK);
  print("Jesse, we'd better call Saul Goodman", 20, 1, C_FG_LIGHT_CYAN + C_BG_BLACK);
  print("Where is the meth, Jesse", 20, 2, C_FG_LIGHT_CYAN + C_BG_BLACK);
  print("FURFI 2023", 20, 5, C_FG_GREEN + C_BG_BLACK);
}
