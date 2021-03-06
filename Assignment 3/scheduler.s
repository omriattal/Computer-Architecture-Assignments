section .data
    extern number_of_drones
    global curr_drone
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20 ; dword
    DRONE_SIZE equ 24
    MAX_INT equ 0xFFFFFFF
    amount_of_actives: dd 0
    score_res: dd 0
    lowest_score: dd 0
    active_res: dd 0
    modulu_res: dd 0
    drone_location: dd 0
    eliminate_msg: db 10,"ELIMINATED DRONE: ",0
    round_msg: db 10,"ROUND: ",0
    winner_winner_chicken_dinner: db 10,"---- WINNER WINNER CHICKEN DINNER! ----",10,"        THE WINNER IS DRONE - ",0
    first_board: db "FIRST BOARD: ",10,0
    format_string: db "%s",0
    format_integer: db "%d",10,0
    curr_drone: dd 0 ; the current drone
section .text
    global scheduler_func
    extern cors
    extern resume
    extern sp_main
    extern printf
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
%macro modulu 2 
    pushad
    pushfd
    mov eax,%1
    mov edx,0
    div %2
    mov dword [modulu_res],edx
    popfd
    popad
%endmacro
%macro divide 2 
    pushad
    pushfd
    mov eax,%1
    mov edx,0
    div %2
    mov dword [modulu_res],eax
    popfd
    popad
%endmacro

scheduler_func:
    mov edx,0 ; the index
    print format_string,first_board
    mov ebx, printer_co ; print first board
    call resume 
    mov eax, dword [cors] ; the cors ptrs
    mov ebx, dword [number_of_drones]
    mov dword [amount_of_actives], ebx ; amount of actives == number of drones
    
    round_robin:
        cmp dword [amount_of_actives],1 ; only one active
        je finish
        print format_string,round_msg
        print format_integer,edx
        modulu edx,dword [number_of_drones] ; result is in modulures
        mov ecx, dword [modulu_res] ; store the result in ecx. ecx = i%N
        is_active ecx ; result is in active_res
        check_active_drone:
        cmp dword [active_res],1 ; this drone is active
        je activate_drone
        jmp check_printer
            activate_drone:
                mov dword [curr_drone],ecx
                mov ebx, dword [eax + 4*ecx] ;getting ready for resuming
                call resume
        
        check_printer:
        modulu edx,dword [number_of_printer_cycles] ; result in modulu res
        mov ecx, dword [modulu_res]
        cmp ecx,0
        je activate_printer
        jmp check_elimination
            activate_printer:
                mov ebx,printer_co
                call resume

        check_elimination:
            cmp edx,0 ; the index equals to 0 - not eliminating
            je cont
            modulu edx, dword [number_of_drones]
            mov ecx, dword [modulu_res] ; ecx = i%N
            cmp ecx,0
            jne cont ; not equals
            divide edx,dword [number_of_drones] ; result in division in modulu res
            mov ecx, dword [modulu_res] ; ecx = i/N
            modulu ecx, dword [number_of_scheduler_cycles]
            mov ecx, dword [modulu_res] ; ecx = i/N % R
            cmp ecx,0
            jne cont ; i/N % R != 0
            call execute_order_66 ; will eliminate a drone with the lowest score
            dec dword [amount_of_actives] ; one less active drone
     cont:
        inc edx
        jmp round_robin
    
    finish:
        call print_winner
        mov ebx,printer_co ; print the board one last time
        call resume
        jmp end_co

find_lowest_score:
    init_func 0
    mov ebx,MAX_INT
    mov ecx,0 ; the index
    .loop:
        cmp ecx, dword [number_of_drones]
        je .finish
        is_active ecx ; result is in active res
        cmp dword [active_res],1 ; is active
        jne .cont ; inactive
        get_score ecx ; result is in score_res
        mov eax, dword [score_res]
        cmp ebx,dword [score_res]
        jle .cont ; ebx is smaller or equals
        mov ebx,dword [score_res] ; make ebx smaller
    .cont:
        inc ecx
        jmp .loop
    .finish:
        mov dword [lowest_score],ebx ; save lowest score
    end_func 0

execute_order_66:
    init_func 0
    call find_lowest_score ; result is in lowest score
    after:
    mov ebx,0
    mov eax, [drones]
    mov ecx,0
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
        print format_string,eliminate_msg
        print format_integer,ecx
        mov ebx,dword [drone_location]
        mov dword [eax+ebx+STATUS],0 ; deactivate drone
        jmp .finish ; no need to continue    
        .cont:
            inc ecx
            jmp .loop
    .finish:
        end_func 0

print_winner:
    init_func 0
    mov ecx,0 ; he index
    .loop:
        cmp ecx, dword [number_of_drones]
        je .finish
        is_active ecx ; result is in active_res
        cmp dword [active_res],1
        jne .cont
        print format_string,winner_winner_chicken_dinner
        inc ecx
        print format_integer,ecx
        dec ecx
        jmp .finish
        .cont:
            inc ecx
            jmp .loop
    .finish:
        end_func 0


