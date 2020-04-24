section	.rodata			; we define (global) read-only variables in .rodata section
	format: db "%s", 10, 0
	format_integer: db "%d",10,0	; format string
section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	tmp: resb 12
	

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp
	sub esp , 4
	mov dword [ebp - 4], 10
	pushad			
	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	mov ebx,0 
	mov eax,0
	getting_number:
		cmp byte [ecx+ebx],10 ;checks if the char is a newline
		je cotinue_to_convert_to_hexa_char
		sub byte [ecx+ebx] , 48
		mul dword [ebp-4]
		mov edx,0
		mov byte dl,[ebx+ecx]
		add eax,edx
		inc ebx
		jmp getting_number

	cotinue_to_convert_to_hexa_char:
		mov ebx,0
		mov dword [ebp-4],16

	convert_to_hexa_char: ; now eax stores the decimal number
		cmp eax,0
		je continue
		mov edx,0
		div dword [ebp-4]
		cmp edx, 9
		jle convert_to_char_0_9
		convert_to_char_A_F:
			add dl,55
			mov byte [an + ebx],dl
			inc ebx
			jmp convert_to_hexa_char

		convert_to_char_0_9:
			add dl,48
			mov byte [an + ebx], dl
			inc ebx
			jmp convert_to_hexa_char



	continue:
		mov byte [an + 12], 0 
		push dword format
		call printf
		add esp, 8		; clean up stack after call
		popad			
		mov esp, ebp	
		pop ebp
		ret
