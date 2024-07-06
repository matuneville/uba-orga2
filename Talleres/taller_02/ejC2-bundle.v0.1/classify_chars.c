#include "classify_chars.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// los simbolos son consonantes
int esVocal(char letra){
    return (letra == 'a' || letra == 'e' || letra == 'i' || letra == 'o' || letra == 'u');
}

void classify_chars_in_string(String string, String* vowels_and_cons) {
    // aca modificamos el parametro vowels_and_cons
    int i = 0;
    int vow_i = 0;
    int cons_i = 0; 
    while(string[i] != '\0'){
        if (esVocal(string[i]))
            vowels_and_cons[0][vow_i++] = string[i++];
        else
            vowels_and_cons[1][cons_i++] = string[i++];
    }
    vowels_and_cons[0][vow_i] = '\0';
    vowels_and_cons[1][cons_i] = '\0';
}

// array es arreglo de classifiers
void classify_chars(classifier_t* array, uint64_t size_of_array) {
    for (int i = 0; i < size_of_array; i++){
        // reservo espacio para un arreglo de 2 strings
        String* vowels_and_consonant = malloc(2 * sizeof(String));

        // reservo el espacio para dos arreglos de caracteres (strings) paraclasificar
        vowels_and_consonant[0] = calloc(65, sizeof(char));
        vowels_and_consonant[1] = calloc(65, sizeof(char));

        classify_chars_in_string(array[i].string, vowels_and_consonant);

        array[i].vowels_and_consonants = vowels_and_consonant;
    }
}