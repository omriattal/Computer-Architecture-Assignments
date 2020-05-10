section .data
    calc_msg: db "calc: ",0
    format: db "%s",0
    number_of_actions: dd 0
    node:  db 0
           dd 4
    format_integer: db "%d",0
    operand_stack_length: db 5
    operand_stack_esp:  db 4

section .bss
    operand_stack: resd 5
    str_input: resb 80

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern gets 
  extern getchar 
  extern fgets
  extern stdin
%macro print 2
    push dword %2
    push dword %1
    call printf
    add esp,8
%endmacro

%macro input 1
    push dword [stdin]
    mov ebx,80 ;maximum input
    push ebx
    push dword %1
    call fgets
    add esp,12
%endmacro
%macro insert_to_operand_stack
    mov dword ebx, %1
    cmp byte [ebx],'A'
    jle convert_to_0_9
    convert_to_A_F:
        sub byte [ebx], 55	;'A'->10, 'B'->11 and so on.
        jmp make_node

    convert_to_0_9:
        sub byte [ebx], 48
        jmp make_node
    make_node:
        

%endmacro
main:
    push ebp
	mov ebp, esp
    pushfd
    pushad
    ; mov eax,4 ; allocate dynamically memory of size 4*length
    ; cmp dword [ebp+8],0 //TODO: IMPLEMENT MALLOC ON OPERNAD STACK
    ; jne defined_operand_stack
    ; mul dword [ebp+8] ;stack size is at most 256
    ; push eax
    ; call malloc
    ; mov dword [operand_stack], eax ; TODO - RELEASE MEMORY 
    ; add esp,4
    print format,calc_msg
    input str_input


    popad
    popfd
    mov esp, ebp	
	pop ebp
    mov dword eax, [number_of_actions]
    ret

    

