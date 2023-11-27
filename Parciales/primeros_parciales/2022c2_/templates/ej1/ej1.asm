global agrupar

; Struct MSG
; | #### 8B #### | -> pointer text
; | #### 8B #### | -> largo text
; | # 4B # |--4B-| -> tag y padding

%define offset_text 0
%define offset_len  8
%define offset_tag  16
%define struct_size 24


;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text

agrupar:


