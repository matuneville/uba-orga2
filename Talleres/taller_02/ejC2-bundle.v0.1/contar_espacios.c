#include "contar_espacios.h"
#include <stdio.h>

uint32_t longitud_de_string(char* string) {
    int count = 0;

    if(string == NULL) return 0;

    while(*string != '\0'){
        count++;
        string++;
    }

    return count;
}

uint32_t contar_espacios(char* string) {
    int count = 0;

    if(string == NULL) return 0;

    while(*string != '\0'){
        if (*string == ' ') count++;
        string++;
    }

    return count;
}

/*
int main() {

    printf("1. %d\n", contar_espacios("hola como andas?"));

    printf("2. %d\n", contar_espacios("holaaaa orga2"));
}*/
