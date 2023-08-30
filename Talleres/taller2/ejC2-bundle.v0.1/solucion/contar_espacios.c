#include "contar_espacios.h"
#include <stdio.h>

uint32_t longitud_de_string(char* string) {
	uint32_t cont = 0;
	while (string != NULL && *string != '\0'){  // Recorro el string hasta que llegue al final
		cont++; // cuento los caracteres
		string++; //avanzo
	}
	return cont;
}

uint32_t contar_espacios(char* string) {
	uint32_t cont = 0;

	while (string != NULL && *string != '\0'){
		if(*string== ' ') cont++; // me fijo si es un espacio
		string++;
	}
	return cont;
}

// Pueden probar acá su código (recuerden comentarlo antes de ejecutar los tests!)
/*
int main() {

    printf("1. %d\n", contar_espacios("hola como andas?"));

    printf("2. %d\n", contar_espacios("holaaaa orga2"));
    
    printf("3. %d\n", longitud_de_string("holaaaa orga2"));
}

*/