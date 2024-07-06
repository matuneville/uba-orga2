

;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar: estos datos pueden ir en section.data?
NODO_LENGTH	EQU	0x20 ; 32
CATEGORIA_OFFSET EQU  0x8 ;8
ARRAY_OFFSET EQU 0x10 ; 16
LONGITUD_OFFSET	EQU	0x18 ; 24

; Struct NODO
; |--- 8B ---| -> puntero next
; |1B|--7B L-| -> categoria y libre
; |--- 8B ---| -> puntero array
; |-4B-|-----| -> longitud

; Struct NODO menor consumo
; |--- 8B ---| -> puntero next
; |1B|--|-4B-| -> categoria y libre
; |--- 8B ---| -> puntero array

PACKED_NODO_LENGTH	EQU	0x15 ; 21
PACKED_CATEGORIA_OFFSET EQU  0x8 ;
PACKED_ARRAY_OFFSET EQU 0x9 ; 
PACKED_LONGITUD_OFFSET	EQU	0x11 ; 17

; Struct NODO PACKED
; |--- 8B ---|1B|--- 8B ---|-4B-|

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS
global cantidad_total_de_elementos
global cantidad_total_de_elementos_packed

;########### DEFINICION DE FUNCIONES
;extern uint32_t cantidad_total_de_elementos(lista_t* lista);
;registros: lista[RDI]
cantidad_total_de_elementos:
	push RBP
	mov RBP, RSP

	; registro para acumular la suma
	xor RAX, RAX

	; accedo al puntero al primer nodo
	mov RSI, [RDI]

	loop_lista:
		; chequeo NULL
		cmp RSI, 0
		jz end_lista

		; sumo elementos largo
		add EAX, DWORD[RSI+LONGITUD_OFFSET]
		
		; voy al siguiente nodo
		mov RSI, [RSI]

		jmp loop_lista

	end_lista:
	pop RBP
	ret

;extern uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista);
;registros: lista[RDI]
cantidad_total_de_elementos_packed:
	push RBP
	mov RBP, RSP

	; registro para acumular la suma
	xor RAX, RAX

	; accedo al puntero al primer nodo
	mov RSI, [RDI]

	loop_lista_packed:
		; chequeo NULL
		cmp RSI, 0
		je end_lista_packed

		; sumo elementos largo
		add EAX, DWORD[RSI+PACKED_LONGITUD_OFFSET]
		
		; voy al siguiente nodo
		mov RSI, [RSI]

		jmp loop_lista_packed

	end_lista_packed:
	pop RBP
	ret

