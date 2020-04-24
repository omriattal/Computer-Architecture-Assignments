section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0
	format_integer: db "%d",10,0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
 

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
		je continue_with_number
		sub byte [ecx+ebx] , 48
		mul dword [ebp-4]
		mov edx,0
		mov byte dl,[ebx+ecx]
		add eax,edx
		inc ebx
		jmp getting_number

	continue_with_number:
	mov [an],eax
	push dword [an]	; call printf with 2 arguments -  
	push format_integer	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
