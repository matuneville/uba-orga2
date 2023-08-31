#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

int main (void){
	/* Acá pueden realizar sus propias pruebas */
	// assert(alternate_sum_8(8,2,5,1,8,2,5,1) == 30);
	uint32_t res = alternate_sum_8(10, 10, 20, 5, 10, 10, 20, 5);
	printf("%d \n", res);
	return 0;    
}