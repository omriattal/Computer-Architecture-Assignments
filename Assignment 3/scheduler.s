

section .text
    global scheduler_func
    extern cors
    extern number_of_drones
    extern resume
    extern sp_main
    extern do_resume
    extern end_co
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


scheduler_func:
    mov edx,0
    mov eax, dword [cors]
    .round_robin:
        cmp edx,dword [number_of_drones]
        je .finish
        mov ebx, dword [eax +edx*4];the current co-routine
        call resume
        inc edx
        jmp .round_robin
    .finish:
        jmp end_co