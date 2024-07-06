#include "lista_enlazada.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


lista_t* nueva_lista(void) {

    lista_t* lista = malloc(sizeof(lista_t));
    lista->head = NULL;

    return lista;
}

uint32_t longitud(lista_t* lista) {

    nodo_t* actual = lista->head;

    if (actual == NULL) return 0;
    
    uint16_t count = 1;
    while(actual->next != NULL){
        count++;
        actual = actual->next;
    }

    return count;
}

void agregar_al_final(lista_t* lista, uint32_t* arreglo, uint64_t longitud) {

    nodo_t* nuevo = malloc(sizeof(nodo_t));
    nuevo->next = NULL;
    nuevo->longitud = longitud;

    uint32_t* nuevoArreglo = malloc(sizeof(uint32_t) * longitud);

    /*for(uint16_t i = 0; i < longitud; i++){
        *nuevoArreglo = *arreglo;
        arreglo++;
        nuevoArreglo++;
    }*/

    for(uint16_t i = 0; i < longitud; i++){
        nuevoArreglo[i] = arreglo[i];
    }

    nuevo->arreglo = nuevoArreglo;

    nodo_t* actual = lista->head;

    if (actual == NULL){
        lista->head = nuevo;
        return;
    }

    while(actual->next != NULL){
        actual = actual->next;
    }
    actual->next = nuevo;
}

nodo_t* iesimo(lista_t* lista, uint32_t i) {
    nodo_t* actual = lista->head;

    while(i > 0){
        actual = actual->next;
        i--;
    }
    
    return actual;
}

uint64_t cantidad_total_de_elementos(lista_t* lista) {
    uint16_t sumaTotal = 0;
    nodo_t* actual = lista->head;
    
    if (actual == NULL){
        return 0;
    }
    
    while(actual->next != NULL){
        sumaTotal = sumaTotal + actual->longitud;
        actual = actual->next;
    }
    sumaTotal = sumaTotal + actual->longitud;
    
    return sumaTotal;
}

void imprimir_lista(lista_t* lista) {
    nodo_t* actual = lista->head;

    if (actual == NULL){
        printf("null");
        return 0;
    }

    while(actual->next != NULL){
        printf("| ", actual->longitud, " | -> ");
        actual = actual->next;
    }
    printf("| ", actual->longitud, " | -> ");
    printf("null");
}

// Función auxiliar para lista_contiene_elemento
int array_contiene_elemento(uint32_t* array, uint64_t size_of_array, uint32_t elemento_a_buscar) {
    while(size_of_array > 0){
        if (*array == elemento_a_buscar)
            return 1;
        array++;

        size_of_array--;
    }
    return 0;
}

int lista_contiene_elemento(lista_t* lista, uint32_t elemento_a_buscar) {
    
    nodo_t* actual = lista->head;
    if (actual == NULL)
        return 0;
    
    while(actual->next != NULL){
        if (array_contiene_elemento(actual->arreglo, actual->longitud, elemento_a_buscar))
            return 1;
        actual = actual->next;
    }
    if (array_contiene_elemento(actual->arreglo, actual->longitud, elemento_a_buscar))
        return 1;

    return 0;
}


// Devuelve la memoria otorgada para construir la lista indicada por el primer argumento.
// Tener en cuenta que ademas, se debe liberar la memoria correspondiente a cada array de cada elemento de la lista.
void destruir_lista(lista_t* lista) {
    nodo_t* actual = lista->head;
    while(actual->next != NULL){
        nodo_t* prox = actual->next;
        free(actual->arreglo);
        free(actual);
        actual = prox;
    }
    free(actual->arreglo);
    free(actual);
    free(lista);
}