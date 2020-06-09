section .data
    format_string: db "%s",0
    format_integer: db "%d",0
    format_float: db "%.2f",0
    format_float_regular: db "%f",0
    newline_msg: db 10,0
    BOARD_SIZE: dd 100
    MAX_SHORT: dd 0xFFFF
    THREE_SIXTY: dd 360
    ONE_EIGHTY: dd 180
    seed: dd 0 ; seed is a word
    number_of_drones: dd 0
    number_of_scheduler_cycles: dd 0
    number_of_printer_cycles: dd 0
    maximum_distance: dd 0.0

section .bss
    position_res: resd 1
    angle_res: resd 1
    arg_temp: resd 1

%macro print 2
    pushfd
    pushad
    push dword %2
    push dword %1
    call printf
    add esp,8
    popad
    popfd
%endmacro
%macro init_func 1
    push ebp 
    mov ebp,esp
    sub esp, %1
    pushfd
    pushad
%endmacro
%macro end_func 1
    popad
    popfd
    add esp, %1
    pop ebp
    ret
%endmacro
%macro end_func_save 2
    mov dword [ebp-%1],%2
    popad
    popfd
    mov %2, dword [ebp-%1] ; save the value
    add esp,%1
    pop ebp
    ret
%endmacro
%macro print_float 1
    pushad
    pushfd
    fld %1
    sub esp,8
    fstp qword [esp]
    push format_float
    call printf
    add esp,12
    popfd
    popad
%endmacro
%macro print_newline 0
    pushad
    pushfd
    push dword newline_msg
    push dword format_string
    call printf
    add esp,8
    popfd
    popad
%endmacro
%macro read_arg 3
    pushad
    pushfd
    push dword %3
    push dword %2
    push dword %1
    call sscanf
    add esp,12
    popfd
    popad
%endmacro

section .text
  align 16
  global main
  global random_words
  global position_gen
  extern printf
  extern malloc
  extern calloc 
  extern free  
  extern sscanf

main: ; the main function
    init_func 0
    push dword [ebp+12]
    call init_args
    add esp,4
    end_func 0
init_args:
    init_func 0
    mov ecx, dword [ebp+8] ; char* argv[]
    read_arg [ecx+4],format_integer,number_of_drones
    read_arg [ecx+8],format_integer,number_of_scheduler_cycles 
    read_arg [ecx+12],format_integer,number_of_printer_cycles
    read_arg [ecx+16],format_float_regular,maximum_distance
    read_arg [ecx+20],format_integer,seed
    end_func 0

random_bit:
    init_func 0
    mov ebx,0
    bt word [seed], 0 ; set carry flag to be seed[0]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],2 ; set carry flag to be seed[2]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],3 ; set carry flag to be seed[3]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],5 ; set carry flag to be seed[5]
    adc bl,0 ; bl xor carry flag -> bl
    bt bx,0 ; ; set carry flag to be the lsb of bx. the bit we we're calculating
    rcr word [seed],1 ; rotate with carry one time
    end_func 0

random_word:
    init_func 0
    mov ecx, 16 ; do the rotation 16 bytes
    next_bit:
    call random_bit
    loop next_bit, ecx
    end_func 0

position_gen:
    init_func 0
    call random_word ; now seed has the right number we'll use
    fild dword [seed]
    fdiv dword [MAX_SHORT]
    fmul dword [BOARD_SIZE]
    fstp dword [position_res] ; position_res will hold the result of the operation
    end_func 0
angle_gen:
    init_func 0
    call random_word ; now seed has the right number we'll use
    fild dword [seed]
    fdiv dword [MAX_SHORT]
    fmul dword [THREE_SIXTY] 
    fldpi
    fmulp
    fidiv dword [ONE_EIGHTY]
    fstp dword [angle_res] ; angle_res will hold the result of the operation
    end_func 0




    

