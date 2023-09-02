#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

int main (void){
	/* Acá pueden realizar sus propias pruebas */
	// assert(alternate_sum_8(8,2,5,1,8,2,5,1) == 30);
	//uint32_t debug = 5;
	uint32_t res;
	uint32_t x1 = 5;
	float f1 = 7.0;
	product_2_f(&res, x1, f1);
	
	printf("%d \n", res);
	return 0;    
} 