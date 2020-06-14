section .data
    extern number_of_drones
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20 ; dword
    DRONE_SIZE equ 24
    amount_of_actives: dd 0
section .bss
    active_res: resd 1
    mod_res: resd 1
section .text
    global scheduler_func
    extern cors
    extern resume
    extern sp_main
    extern drones
    extern number_of_scheduler_cycles
    extern number_of_printer_cycles
    extern maximum_distance
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
;receives an index to the drone
%macro is_active 1  
    pushfd
    pushad
    mov edx,0
    mov eax,%1 ; the multiplicand
    mov ecx,DRONE_SIZE ; the multiplier
    mul ecx ; result is in eax
    mov ebx, dword [drones]
    add ebx,eax
    mov eax, dword [ebx+STATUS] ; the status in eax
    mov dword [active_res],eax
    popad
    popfd
%endmacro

%macro mod 2 
    pushad
    pushfd
    mov eax,%1
    mov edx,0
    div %2
    mov dword [mod_res],edx
    popfd
    popad
%endmacro

scheduler_func:
    mov edx,0 ; the index
    mov eax, dword [cors] ; the cors ptrs
    mov ebx, dword [number_of_drones]
    mov dword [amount_of_actives], ebx ; amount of actives == number of drones
    round_robin:
        cmp dword [amount_of_actives],0 ; only one active
        je .finish
        mod edx,dword [number_of_drones] ; result is in modres
        mov ecx, dword [mod_res] ; store the result in ecx. ecx = i%N
        is_active ecx ; result is in active_res
        cmp dword [active_res],1 ; this drone is active
        je .activate_drone
            .activate_drone:
                 mov ebx, dword [eax + 4*ecx] ;getting ready for resuming
                 call resume
                 inc edx ; update the edx
                 dec dword [amount_of_actives]
                 jmp round_robin
    .finish:
        jmp end_co