section .data
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    format_float: db "%.2f ",0
    format_string: db "%s",0
    format_integer: db "%d ",0
    newline_msg: db 10,0

section .text
    global print_drones
    extern printf
    extern drones
    extern number_of_drones

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

print_drones:
    init_func 0
    mov ebx, dword [drones]
    mov ecx,0
    .main_loop:
        cmp ecx,dword [number_of_drones]
        je .finish_looping
        inc ecx 
        print format_integer,ecx
        dec ecx
        print_float dword [ebx+X]
        print_float dword [ebx+Y]
        print_float dword [ebx+ANGLE]
        print_float dword [ebx+SPEED]
        print format_integer,[ebx+SCORE]
        inc ecx
        add ebx,20
        print_newline
        jmp .main_loop
    .finish_looping:
        end_func 0