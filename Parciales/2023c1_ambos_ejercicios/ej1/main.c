#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <stddef.h>
#include "ej1.h"

// typedef struct pago {
//   uint8_t monto;
//   char* comercio;
//   uint8_t cliente;
//   uint8_t aprobado;
// } pago_t; 



int main (void){
    //quiero ver los offsets de la estructura  y su tamaño 
    printf("size of pago_t: %lu\n", sizeof(pago_t));
    printf("offset monto: %lu\n", offsetof(pago_t, monto));
    printf("offset comercio: %lu\n", offsetof(pago_t, comercio));
    printf("offset cliente: %lu\n", offsetof(pago_t, cliente));
    printf("offset aprobado: %lu\n", offsetof(pago_t, aprobado));


    //testeo la funcion acumuladoPorCliente_asm 
    // uint8_t cantidadDePagos = 5;
    // pago_t* arr_pagos = malloc(sizeof(pago_t)*cantidadDePagos);
    // arr_pagos[0].monto = 10;
    // arr_pagos[0].cliente = 0;
    // arr_pagos[1].monto = 0;
    // arr_pagos[1].cliente = 1;
    // arr_pagos[2].monto = 1;
    // arr_pagos[2].cliente = 2;
    // arr_pagos[3].monto = 40;
    // arr_pagos[3].cliente = 3;
    // arr_pagos[4].monto = 50;
    // arr_pagos[4].cliente = 4;
    //printeo 
    // printf("arr_pagos:\n");
    // for(uint8_t i = 0; i < cantidadDePagos; i++){
        // printf("monto: %d, cliente: %d\n", arr_pagos[i].monto, arr_pagos[i].cliente); //anduvo vamos!! ;) 
    // }


    //PRUEBO la funcion en_blacklist
    // char* comercio = "comercio1";
    // char** lista_comercios = malloc(sizeof(char*)*3);
    // lista_comercios[0] = "comercio1";
    // lista_comercios[1] = "comercio2";
    // lista_comercios[2] = "comercio3";
    // uint8_t n = 3;
    // uint8_t res = en_blacklist(comercio, lista_comercios, n);
    // printf("res: %d\n", res); //anduvo
    // free(lista_comercios);

    //test para la funcion en_blacklist_asm
    // char* comercio = "comercio2";
    // char** lista_comercios = malloc(sizeof(char*)*3);
    // lista_comercios[0] = "comercio1";
    // lista_comercios[1] = "comercio2";
    // lista_comercios[2] = "comercio3";
    // uint8_t n = 3;
    // uint8_t res = en_blacklist_asm(comercio, lista_comercios, n);
    // printf("res: %d\n", res); //anduvo
    // free(lista_comercios);


    //test para la funcion pago_t** blacklistComercios_asm(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios);
    uint8_t cantidad_pagos = 5;
    pago_t* arr_pagos = malloc(sizeof(pago_t)*cantidad_pagos);
    arr_pagos[0].monto = 10;
    arr_pagos[0].cliente = 0;
    arr_pagos[0].comercio = "comercio1";
    arr_pagos[1].monto = 0;
    arr_pagos[1].cliente = 1;
    arr_pagos[1].comercio = "comercio2";
    arr_pagos[2].monto = 1;
    arr_pagos[2].cliente = 2;
    arr_pagos[2].comercio = "comercio3";
    arr_pagos[3].monto = 40;
    arr_pagos[3].cliente = 3;
    arr_pagos[3].comercio = "comercio4";
    arr_pagos[4].monto = 50;
    arr_pagos[4].cliente = 4;
    arr_pagos[4].comercio = "comercio5";

    uint8_t size_comercios = 3;
    char** arr_comercios = malloc(sizeof(char*)*size_comercios);
    arr_comercios[0] = "comercio1";
    arr_comercios[1] = "comercio2";
    arr_comercios[2] = "comercio3";


    //printeo
    
    pago_t** res = blacklistComercios_asm(cantidad_pagos, arr_pagos, arr_comercios, size_comercios);
    printf("res:\n");
    uint8_t size_res = cant_blacklist(cantidad_pagos, arr_pagos, arr_comercios, size_comercios);
    for(uint8_t i = 0; i < size_res; i++){
        printf("monto: %d, cliente: %d, comercio: %s\n", res[i]->monto, res[i]->cliente, res[i]->comercio); //anduvo vamos!! ;) 
    }
}


