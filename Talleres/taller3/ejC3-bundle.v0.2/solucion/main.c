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
	
	//uint32_t res;
	//uint32_t x1 = 2;
	//float f1 = 2.49;
	//product_2_f(&res, x1, f1);
	
	uint32_t x1 = 5;
	uint32_t x2 = 5;
	uint32_t x3 = 5;
	uint32_t x4 = 5;
	uint32_t x5 = 5;
	uint32_t x6 = 5;
	uint32_t x7 = 5;
	uint32_t x8 = 5;
	uint32_t x9 = 5;	

	float f1 = 5.0;
	float f2 = 5.0;
	float f3 = 5.0;
	float f4 = 5.0;
	float f5 = 5.0;
	float f6 = 5.0;
	float f7 = 5.0;
	float f8 = 5.0;
	float f9 = 5.0;

	double r = 13;
	double* res = &r;
	product_9_f(res, x1, f1, x2, f2, x3, f3, x4, f4, x5, f5, x6, f6, x7, f7, x8, f8, x9, f9);

	printf("%f \n", *res);
	return 0;    
} 





