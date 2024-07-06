#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

int main (void){
	/* Acá pueden realizar sus propias pruebas */
	FILE *file  = fopen("test_print.txt", "r+");		
	// write to file vs write to screen
	fprintf(file, "this is a test\n"); // write to file

	fprintf(stdout, "this is a test\n"); // write to screen 

	char* string = "";
	strPrint(string, file);

	return 0;    
}


