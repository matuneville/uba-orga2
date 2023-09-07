
section .text

global checksum_asm

; uint8_t checksum_asm(void* array, uint32_t n)
; RDI: array, RSI: n
checksum_asm:
	push rbp
	mov rbp, rsp

	loop1:
		cmp rsi, 0
		je end

		; si rsi == 0 termina, sino decremento y sigo con el ciclo
		dec rsi
		


	end:
		pop rbp
		ret

