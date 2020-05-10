section	.rodata			; we define (global) read-only variables in .rodata section
	format: db "%s", 10, 0
	format_integer: db "%d",10,0
section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	finished_string: resb 12

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
		mov edx,0
		div dword [ebp-4]
		cmp edx, 9
		jle convert_to_char_0_9
		convert_to_char_A_F:
			add dl,55
			mov byte [an + ebx],dl
			inc ebx
			jmp condition

		convert_to_char_0_9:
			add dl,48
			mov byte [an + ebx], dl
			inc ebx
			jmp condition
		condition: ;added these lines
			cmp eax,0
			je reverse_string_begin_init_edx
			jmp convert_to_hexa_char
			
	reverse_string_begin_init_edx:
		mov edx, 0
	reverse_string_begin:
		mov ecx, 0
		cmp ebx, 0
		je continue
		reverse_string:
			dec ebx
			mov  cl, byte [an+ebx]
			mov byte [finished_string+edx],cl
			inc edx
			jmp reverse_string_begin

	continue:
		mov byte [finished_string + edx], 0 ; added
		push finished_string
		push format
		call printf
		add esp, 8		; clean up stack after call
		popad			
		mov esp, ebp	
		pop ebp
		ret
