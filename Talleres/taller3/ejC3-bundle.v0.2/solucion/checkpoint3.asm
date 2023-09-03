

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar:
NODO_LENGTH	EQU	0x20
LONGITUD_OFFSET	EQU	0x18

; / .... Next ..... 8 B /. Categ . 1 B / #### 7 B #### /.... Arreglo .... 8 B /. Long .4 B / ## 4 B ## /

; no empaqueta los 7B libres luego de Categoria para dejar alineado

; tamaño = 8+8+8+8 = 0x20
; offset a distancia = 8+8+8 = 0x18

PACKED_NODO_LENGTH	EQU	0x15
PACKED_LONGITUD_OFFSET	EQU	0x11

; / .... Next ..... 8 B /. Categ . 1 B /.... Arreglo .... 8 B /. Long ..4 B /

; empaqueta los 7B libres

; tamaño = 8+1+8+4 = 0x15
; offset a distancia = 8+1+8 = 0x11

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS
global cantidad_total_de_elementos
global cantidad_total_de_elementos_packed

;########### DEFINICION DE FUNCIONES
;extern uint32_t cantidad_total_de_elementos(lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos:
	push rbp
	mov rbp, rsp

	mov rdi, [rdi] ; carga el puntero a la cabeza de la lista en rdi

	xor rax, rax ; seteo a 0 para contar longitudes

	; avanzo nodo hasta el final en loop
	.loop
		test rdi, rdi ; compara rdi consigo mismo y verifica si es 0 para ver si es NULL
		jz  .end
		
		add rax, [rdi + LONGITUD_OFFSET]

		mov	 rdi, [rdi]
		jmp .loop
	
	.end
	pop rbp
	ret

;extern uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos_packed:
	push rbp
	mov rbp, rsp

	mov rdi, [rdi] ; carga el puntero a la cabeza de la lista en rdi

	xor rax, rax ; seteo a 0 para contar longitudes

	; avanzo nodo hasta el final en loop
	.loop
		test rdi, rdi ; compara rdi consigo mismo y verifica si es 0 para ver si es NULL
		jz  .end
		
		add rax, [rdi + PACKED_LONGITUD_OFFSET]

		mov	 rdi, [rdi]
		jmp .loop
	
	.end
	pop rbp
	ret
