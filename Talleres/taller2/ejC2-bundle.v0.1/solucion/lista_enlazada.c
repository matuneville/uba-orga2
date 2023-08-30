#include "lista_enlazada.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


// make tests_lista_enlazada 
// ./tests_lista_enlazada
// make run_tests_lista_enlazada 
//

lista_t* nueva_lista(void) 
{
    lista_t* nuevo = malloc(sizeof(nodo_t));
    nuevo->head = NULL;
    return nuevo;
}

uint32_t longitud(lista_t* lista) {
    uint32_t largo = 0;
    nodo_t* actual = lista->head;
    while(actual != NULL){
        largo++;
        actual = actual->next;
    }   
    return largo;
}

void agregar_al_final(lista_t* lista, uint32_t* arreglo, uint64_t longitud) {
    nodo_t* actual = lista->head;
    if(actual == NULL){
        nodo_t* nuevo = malloc(sizeof(nodo_t));
        nuevo->arreglo = malloc(longitud * sizeof(uint32_t));
        
        for (uint64_t i = 0; i < longitud; i++) {
            nuevo->arreglo[i] = arreglo[i];
        }

        nuevo->longitud = longitud;
        nuevo->next = NULL;

        lista->head = nuevo; // lo agrego
    }
    else{
        while(actual->next != NULL){
            actual = actual->next; 
        }   
        nodo_t* nuevo = malloc(sizeof(nodo_t));
        nuevo->arreglo = malloc(longitud * sizeof(uint32_t));
        
        for (uint64_t i = 0; i < longitud; i++) {
            nuevo->arreglo[i] = arreglo[i];
        }

        nuevo->longitud = longitud;
        nuevo->next = NULL;

        actual->next = nuevo; // lo agrego
    }
}

nodo_t* iesimo(lista_t* lista, uint32_t i) {
    nodo_t* actual = lista->head;
    while(i != 0){
        actual = actual->next;
        i--;
    }
    return actual;
}

uint64_t cantidad_total_de_elementos(lista_t* lista) {
    uint64_t total = 0;
    nodo_t* actual = lista->head;
    while (actual != NULL) {
        total = total + actual->longitud;
        actual = actual->next;
    }
    return total;
}

void imprimir_lista(lista_t* lista) {
    nodo_t* actual = lista->head;
    while(actual != NULL){
        printf("| %ld | ",actual->longitud);
        actual = actual->next;
    }
    printf("/n");
}

// Función auxiliar para lista_contiene_elemento
int array_contiene_elemento(uint32_t* array, uint64_t size_of_array, uint32_t elemento_a_buscar) {
    int64_t  i = size_of_array;
    while (i != 0) {
        if (*array == elemento_a_buscar) return 1;
        array++;
        i--;
    }
    return 0;
}

int lista_contiene_elemento(lista_t* lista, uint32_t elemento_a_buscar) {
    nodo_t* actual = lista->head;
    while (actual != NULL) {
        if (array_contiene_elemento(actual->arreglo, actual->longitud,elemento_a_buscar)) return 1;
        actual = actual->next;
    }
    return 0;
}


// Devuelve la memoria otorgada para construir la lista indicada por el primer argumento.
// Tener en cuenta que ademas, se debe liberar la memoria correspondiente a cada array de cada elemento de la lista.
void destruir_lista(lista_t* lista) {
    nodo_t* actual = lista->head;
    nodo_t* temp = actual;
    while(actual->next != NULL){  
        temp = actual->next; 
        free(actual->arreglo);
        free(actual);
        actual = temp;
    }
    free(actual->arreglo);
    free(actual); 
    free(lista); 
}
