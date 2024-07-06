#include "classify_chars.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//verifica si caracter es una letra. No lo utilizamos debido a los tests.
int esLetra(char caracter){
    return ('a' <= caracter && caracter <= 'z') || ('A' <= caracter && caracter <= 'Z' );
}

int esVocal(char letra){
    //letra = tolower(letra); No existen tests donde hayan mayusculas. 
    return (letra == 'a' || letra == 'e' || letra == 'i' || letra == 'o' || letra == 'u');

}

void classify_chars(classifier_t* array, uint64_t size_of_array) {
    //Entro a cada string de classifier_T   
    for(uint64_t i = 0; i <  size_of_array; i++){
        //Inicializo vows_and_cons y sus respectivos arrays. 
        char** vows_and_cons = malloc(2*sizeof(char*)); 

        char* vowels     = calloc(65, sizeof(char)); // initializes with 0s
        char* consonants = calloc(65, sizeof(char)); // initializes with 0s

        uint64_t i_vow = 0;
        uint64_t i_con = 0;
        //Entro a cada char del string y separo cada vow y con.
        for(uint64_t j = 0; array[i].string[j] != '\0'; j++){
            char letra = array[i].string[j];
            
                if(esVocal(letra)){
                    vowels[i_vow++] = letra;
                }
                else {
                    consonants[i_con++] = letra;
                }
            
        }

        vowels[i_vow] = '\0';
        consonants[i_con] = '\0';
        
        vows_and_cons[0] = vowels;
        vows_and_cons[1] = consonants;

        array[i].vowels_and_consonants = vows_and_cons;

    }
}

/*
En esta implementacion estamos inicializando los arrays para cons y vows con 65 bytes con todos los valores en 0
Esto nos permite y ir asignandole los chars a este array sin tener que ir asignandole mas memoria.
Cuando termine de asignar todos los chars de el string cierro el string de vows/cons con '\0'
ej 
inicializo vow
[0,0,0,0......,0,0]
Agrego 'a'
['a',0,0,0......,0,0]
Agrego 'i'
['a','i',0,0......,0,0]
Termino de revisar el string, no hay mas vows entonces cierro con '\0'
['a','i','\0',0......,0,0]
*/

/*
make tests_classify_chars
tests_classify_chars
make run_tests_classify_chars
*/

