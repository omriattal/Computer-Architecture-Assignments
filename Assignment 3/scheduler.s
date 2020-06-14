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
    score_res: dd 0
    lowest_score: dd 0
    active_res: dd 0
    mod_res: dd 0
    drone_location: dd 0
section .text
    global scheduler_func
    extern cors
    extern resume
    extern sp_main
    extern drones
    extern number_of_scheduler_cycles
    extern number_of_printer_cycles
    extern maximum_distance
    extern printer_co
    extern target_co
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
%macro get_score 1  
    pushfd
    pushad
    mov edx,0
    mov eax,%1 ; the multiplicand
    mov ecx,DRONE_SIZE ; the multiplier
    mul ecx ; result is in eax
    mov ebx, dword [drones]
    add ebx,eax
    mov eax, dword [ebx+SCORE] ; the status in eax
    mov dword [score_res],eax
    popad
    popfd
%endmacro
%macro get_drone_loc 1 
    pushfd
    pushad
    mov edx,0
    mov eax,%1 ; the multiplicand
    mov ecx,DRONE_SIZE ; the multiplier
    mul ecx ; result is in eax
    mov dword [drone_location],eax
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

%macro divide 2 
    pushad
    pushfd
    mov eax,%1
    mov edx,0
    div %2
    mov dword [mod_res],eax
    popfd
    popad
%endmacro

scheduler_func:
    mov edx,0 ; the index
    mov eax, dword [cors] ; the cors ptrs
    mov ebx, dword [number_of_drones]
    mov dword [amount_of_actives], ebx ; amount of actives == number of drones
    round_robin:
        cmp dword [amount_of_actives],1 ; only one active
        je finish
        mod edx,dword [number_of_drones] ; result is in modres
        mov ecx, dword [mod_res] ; store the result in ecx. ecx = i%N
        is_active ecx ; result is in active_res
        check_active_drone:
        cmp dword [active_res],1 ; this drone is active
        je activate_drone
        jmp check_printer
            activate_drone:
                 mov ebx, dword [eax + 4*ecx] ;getting ready for resuming
                 call resume
        
        check_printer:
        mod edx,dword [number_of_printer_cycles] ; result in mod res
        mov ecx, dword [mod_res]
        cmp ecx,0
        je activate_printer
        jmp check_elimination
            activate_printer:
                mov ebx,printer_co
                call resume

        check_elimination:
            mod edx, dword [number_of_drones]
            mov ecx, dword [mod_res] ; ecx = i%N
            cmp ecx,0
            jne cont ; not equals
            divide edx,dword [number_of_drones] ; result in division in mod res
            mov ecx, dword [mod_res] ; ecx = i/N
            mod ecx, dword [number_of_scheduler_cycles]
            mov ecx, dword [mod_res] ; ecx = i/N % R
            cmp ecx,0
            jne cont ; i/N % R != 0
            call eliminate ; will eliminate a drone with the lowest score
            dec dword [amount_of_actives]
     cont:
        inc edx
        jmp round_robin
    
    finish:
        jmp end_co

find_lowest_score:
    init_func 0
    mov ebx,0
    mov ecx,0 ; the index
    .loop:
        cmp ecx, dword [number_of_drones]
        je .finish
        is_active ecx ; result is in active res
        cmp dword [active_res],1 ; is active
        jne .cont
        get_score ecx ; result is in score_res
        cmp ebx,dword [score_res]
        jle .cont ; ebx is smaller or equals
        mov ebx,dword [score_res] ; make ebx smaller
    .cont:
        inc ecx
        jmp .loop
    .finish:
        mov dword [lowest_score],ebx ; save lowest score
    end_func 0

eliminate:
    init_func 0
    call find_lowest_score ; result is in lowest score
    mov ecx, dword [lowest_score]
    mov ebx,0
    mov eax, [drones]
    .loop:
        cmp ecx, dword[number_of_drones]
        je .finish
        is_active ecx ; result is in active res
        cmp dword [active_res],1
        jne .cont ; drone is not active
        get_score ecx ; result is in score res
        mov ebx, dword [score_res]
        cmp ebx,dword [lowest_score]
        jg .cont ; ebx has a greater score
        get_drone_loc ecx ; result is in drone location
        mov ebx,dword [drone_location]
        mov dword [eax+ebx+STATUS],0 ; deactivate drone
        jmp .finish ; no need to continue    
        .cont:
            inc ecx
            jmp .loop
    .finish:
        end_func 0

