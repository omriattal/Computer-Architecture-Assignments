section .data:
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    ZERO: dd 0.0
section .text:
    global init_drone
    extern seed
    extern random_word
    extern position_gen
    extern angle_gen   
    extern printf
    extern position_res
    extern angle_res
    extern angle_gen

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

init_drone: ; receives a pointer to where to plant the drone. ebp+8 holds the ptr
    init_func 0
    mov ebx, dword [ebp+8]
    call position_gen ; result is in position res
    fld dword [position_res]
    fstp dword [ebx+X] ; x position
    call position_gen ; result is in position res
    fld dword [position_res] 
    fstp dword [ebx+Y] ; y position 
    call angle_gen ; result is in angle res
    fld dword [angle_res]
    fstp dword [ebx+ANGLE] 
    fld dword [ZERO]
    fstp dword [ebx+SPEED]
    mov dword [ebx+SCORE],0
    end_func 0
    


     


