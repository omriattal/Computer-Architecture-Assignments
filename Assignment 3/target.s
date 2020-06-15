section .bss
    global target_x
    global target_y
    target_x: resd 1
    target_y: resd 1

section .data
    extern curr_drone
    extern cors
    extern target_co

section .text:
    global init_target
    global target_func
    extern position_gen
    extern resume
    extern curr
    extern position_res

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

init_target:
    init_func 0
    call position_gen ; result is in position res
    fld dword [position_res]
    fstp dword [target_x]
    call position_gen
    fld dword [position_res]
    fstp dword [target_y]
    end_func 0

target_func:
    call init_target
    mov eax, dword [cors]
    mov ecx, dword [curr_drone]
    mov ebx, dword [eax+4*ecx] ; getting ready to resume current drone
    call resume
    jmp target_func


