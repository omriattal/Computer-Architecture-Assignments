section .data:
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20 ; dword
    ZERO: dd 0.0
    format_string: db "%s",0
    hello: db "hello world",10,0
section .text:
    global init_drone
    global drone_func
    extern seed
    extern resume
    extern random_word
    extern position_gen
    extern angle_gen   
    extern printf
    extern position_res
    extern angle_res
    extern angle_gen
    extern scheduler_co

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
    mov dword [ebx+STATUS],1 ; active
    end_func 0
    

drone_func:
    print format_string,hello
    mov ebx, scheduler_co ; the current co-routine
    call resume
    jmp drone_func
     


