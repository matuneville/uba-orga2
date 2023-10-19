# Ejercicio para coloquio

Se desea evaluar un nuevo sistema de puntajes para torneos. Para evaluar el
sistema se solicita implementar una versión acelerada vía SIMD la cual será
utilizada con varios resultados históricos a fin de ver si los nuevos rankings
son deseables.

El nuevo sistema de puntaje otorga los siguientes puntos:
* +3 por cada partido ganado
* +2 por cada partido empatado
* -1 por cada partido perdido
* +30 si el equipo logró jugar todos los partidos y no perdió ninguno, es decir,
  no tiene ningún partido cancelado ni perdido. 

Por cada equipo se proporcionarán cuatro datos: ganados, empatados, perdidos y
cancelados.
La firma de la función es:

`void calcular_puntajes(int16_t* puntajes, puntajes_equipo_t* resultados, uint64_t cantidad);`

`puntajes` es el arreglo dónde se almacenarán los nuevos puntajes por equipo.
Su memoria ya fue reservada.

Cada estructura del tipo `puntajes_equipo_t` del array `resultados` 
corresponde a un equipo. Ningún equipo ganó, empató, perdió o le cancelaron más
de 192 partidos en los registros que se tienen disponibles.

`cantidad` es la cantidad de puntajes a calcular.

## Makefile

Para correr los tests de la implementación en assembler basta con ejecutar
`make run_tests`. Los tests de la implementación en C se corren con
`make run_c_tests`.

Además, se provee un fichero para realizar pruebas personales (`main.c`) el
genera dos binarios al compilarse `main_asm` (que utiliza su implementación en
assembler) y `main_c` que utiliza su implementación en C.
