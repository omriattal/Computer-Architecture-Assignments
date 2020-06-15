section .data
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20 ; dword
    ZERO: dd 0.0
    DRONE_SIZE: equ 24
    format_string: db "%s",0
    format_integer: db "%d",10,0
    format_destroy: db "drone %d destroying target!",10,0
    hello: db "hello world from drone: ",0
    drone_location: dd 0
    can_destroy: db 0
    delta_x: dd 0
    delta_y: dd 0
    
section .text
    global init_drone
    global drone_func
    extern maximum_distance 
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
    extern target_co
    extern target_func
    extern curr_drone
    extern drones
    extern target_x
    extern target_y
    
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
    print format_integer,[curr_drone]
    call may_destroy ; result is in can drone
    cmp byte [can_destroy],0
    je .resume_scheduer
    call destroy ; inc score and initiate new target
    .resume_scheduer:
    mov ebx, scheduler_co ; the current co-routine
    call resume
    jmp drone_func

may_destroy:
    init_func 0
    mov eax, dword [drones] ; the drones array
    get_drone_loc dword [curr_drone] ; will output the exact location in the array in drone location
    mov ebx, dword [drone_location]
    fld dword [eax+ebx+X] ; load current x
    fld dword [target_x] ;load target x
    fsubp
    fstp dword [delta_x] ; store in delta x

    fld dword [eax+ebx+Y] ; load current y
    fld dword [target_y] 
    fsubp
    fstp dword [delta_y]

    fld dword [delta_x]
    fld dword [delta_x] 
    fmulp ; delta x square
    fld dword [delta_y]
    fld dword [delta_y]
    fmulp ; delta y sqyare
    faddp ; dx^2 + dy^2
    fsqrt ; the distance formula
    fld dword [maximum_distance]
    fcomip ;compares with maximum distance and pop. changed x86 registers
    fstp
    jl not_in_range
    in_range:
        mov byte [can_destroy],1
        jmp cont
    not_in_range:
        mov byte [can_destroy],0
    cont:
        end_func 0

destroy:
    init_func 0
    mov eax, dword [drones] ; the drones array
    get_drone_loc dword [curr_drone] ; will output the exact location in the array in drone location
    mov ebx, dword [drone_location]
    inc dword [eax+ebx+SCORE] ; load current x
    print format_destroy,[curr_drone]
    mov ebx,target_co ; new target
    call resume
    end_func 0



