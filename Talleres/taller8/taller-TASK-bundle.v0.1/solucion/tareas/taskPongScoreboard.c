#include "task_lib.h"

#define WIDTH TASK_VIEWPORT_WIDTH
#define HEIGHT TASK_VIEWPORT_HEIGHT

#define SHARED_SCORE_BASE_VADDR (PAGE_ON_DEMAND_BASE_VADDR + 0xF00)
#define CANT_PONGS 2 //lo habiamos bajado


void task(void) {
	screen pantalla;
	// ¿Una tarea debe terminar en nuestro sistema?
	while (true)
	{
	// Completar:
	uint32_t y = (HEIGHT/2)-1;
	
	for(uint8_t task_id = 0; task_id < CANT_PONGS; task_id++){
		// - Pueden definir funciones auxiliares para imprimir en pantalla
		struct puntajes {
			uint32_t score_player1;
			uint32_t score_player2;
		};
		struct puntajes* current_task_record = (struct puntajes*) SHARED_SCORE_BASE_VADDR;
		
		task_print_dec(pantalla, current_task_record[task_id].score_player1, 6, (WIDTH/2)-3, y, C_FG_LIGHT_GREEN |C_BG_CYAN);
		task_print_dec(pantalla, current_task_record[task_id].score_player2, 6, (WIDTH/2)-3, y+2, C_FG_LIGHT_GREEN |C_BG_CYAN);
	
		y += 6;
	}
	
	// - Pueden usar `task_print`, `task_print_dec`, etc. 
		syscall_draw(pantalla);

	}
}

