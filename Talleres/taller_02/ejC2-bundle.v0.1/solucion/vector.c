#include "vector.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// make tests_vector
// ./tests_vector
//make run_tests_vector

vector_t* nuevo_vector(void) {
    vector_t* nuevo = malloc(sizeof(vector_t));
    nuevo->array = malloc(2 * sizeof(uint32_t));
    nuevo->capacity = 2; 
    nuevo->size = 0;
    return nuevo;    
}

uint64_t get_size(vector_t* vector) {
    return vector->size;
}

void push_back(vector_t* vector, uint32_t elemento) {
    if (vector->size == vector->capacity){
        vector->array = realloc(vector->array, 2 * vector->capacity * sizeof(uint32_t));
        vector->capacity *= 2;
    }
    vector->array[vector->size++] = elemento;
    
}

int son_iguales(vector_t* v1, vector_t* v2) {

    if (v1->size != v2->size ) return 0;

    for (uint64_t i = 0; i < v1->size; i++) {
        if (v1->array[i] != v2->array[i]) return 0;
    }
    
    return 1;
}


uint32_t iesimo(vector_t* vector, size_t index) {
    return vector->array[index];
}

void copiar_iesimo(vector_t* vector, size_t index, uint32_t* out){
    *out = vector->array[index];
}


// Dado un array de vectores, devuelve un puntero a aquel con mayor longitud.
vector_t* vector_mas_grande(vector_t** array_de_vectores, size_t longitud_del_array){
    uint64_t max = (*array_de_vectores)->size;
    vector_t* max_vector = *array_de_vectores;
    vector_t** actual = array_de_vectores;
    while (longitud_del_array > 0) {
        if (max < (*actual)->size) {
            max_vector = *actual;
            max = (*actual)->size;
        }
        actual++;
        longitud_del_array--;
    }
    return max_vector;
}