section .bss
    global target_x
    global target_y
    target_x: resd 1
    target_y: resd 1


section .text:
    global init_target
    global target_func
    extern position_gen
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
    init_func 0
    end_func 0