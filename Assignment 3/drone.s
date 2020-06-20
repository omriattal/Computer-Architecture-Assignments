section .data
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20 ; dword
    DRONE_SIZE: equ 24
    format_string: db "%s",0
    format_integer: db "%d",10,0
    format_float: db "%.2f",10,0
    format_destroy: db "drone %d destroying target!",10,0
    hello: db "hello world from drone: ",0
    drone_location: dd 0
    can_destroy: db 0
    delta_x: dd 0
    delta_y: dd 0
    ONE_HUNDRED: dd 100
    MINUS_ONE_HUNDRED: dd 0
    THREE_SIXTY: dd 360
    ZERO: dd 0
    SIXTY: dd 60
    TWO: dd 2
    MINUS_SIXTY: dd 60
section .bss
    garbage: resd 1
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
    extern delta_alpha_res
    extern delta_speed_res
    extern delta_alpha_gen
    extern delta_speed_gen
        
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
    call move_drone
    .main_loop:
        call may_destroy ; result is in can drone
        cmp byte [can_destroy],0
        jne .destroy
        jmp .resume_scheduer
        .destroy:
            call destroy ; inc score and initiate new target
        .resume_scheduer:
            call move_drone
            mov ebx, scheduler_co ; the current co-routine
            call resume
    jmp .main_loop

may_destroy:
    init_func 0
    mov eax, dword [drones] ; the drones array
    get_drone_loc dword [curr_drone] ; will output the exact location in the array in drone location
    mov ebx, dword [drone_location]
    finit
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
    fcomip  ;compares with maximum distance and pop. changed x86 registers
    fstp dword [garbage]
    jb not_in_range
    in_range:
        mov byte [can_destroy],1
        jmp cont
    not_in_range:
        mov byte [can_destroy],0
    cont:
        ffree
        end_func 0

destroy:
    init_func 0
    mov eax, dword [drones] ; the drones array
    get_drone_loc dword [curr_drone] ; will output the exact location in the array in drone location
    mov ebx, dword [drone_location]
    inc dword [eax+ebx+SCORE] ; load current x
    inc dword [curr_drone]
    print format_destroy,[curr_drone]
    dec dword [curr_drone]
    mov ebx,target_co ; new target
    call resume
    end_func 0

move_drone:
    init_func 0
    call delta_alpha_gen ; result is in delta elpha res
    call delta_speed_gen ; result is in delta speed res
    mov eax, dword [drones]
    get_drone_loc dword [curr_drone]
    mov ebx, dword [drone_location] ; ebx stores the exact drone location
    finit
    compute_deltas:
        fld dword [eax+ebx+ANGLE]
        fsin ; sin(currangle)
        fld dword [eax+ebx+SPEED]
        fmulp
        fstp dword [delta_y]
        fld dword [eax+ebx+ANGLE]
        fcos ; cos(currangle)
        fld dword [eax+ebx+SPEED]
        fmulp
        fstp dword [delta_x]

    move_x:
        fld dword [eax+ebx+X]
        fld dword [delta_x]
        faddp ; adds the current x loc with delta x
        fild dword [ONE_HUNDRED]
        fcomip
        jb .wraparoundtop
        fild dword [ZERO]
        fcomip
        ja .wraparoundbottom
        jmp .regular_x

        .wraparoundtop:
            fisub dword [ONE_HUNDRED]
            fstp dword [eax+ebx+X]
            jmp move_y

        .wraparoundbottom:
            fiadd dword [ONE_HUNDRED]
            fstp dword [eax+ebx+X]
            jmp move_y
        .regular_x:
        fstp dword [eax+ebx+X]

    move_y:
        fld dword [eax+ebx+Y]
        fld dword [delta_y]
        faddp ; adds the current x loc with delta x
        fild dword [ONE_HUNDRED]
        fcomip
        jb .wraparoundtop
        fild dword [ZERO]
        fcomip
        ja .wraparoundbottom
        jmp .regular_y
        .wraparoundtop:
            fisub dword [ONE_HUNDRED]
            fstp dword [eax+ebx+Y]
            jmp change_angle
            
        .wraparoundbottom:
            fiadd dword [ONE_HUNDRED]
            fstp dword [eax+ebx+Y]
            jmp change_angle
            
        .regular_y:
        fstp dword [eax+ebx+Y]

    change_angle:
        fld dword [eax+ebx+ANGLE]
        fld dword [delta_alpha_res]
        faddp
        fldpi
        fimul dword [TWO]
        fcomip ; compares with 2pi = 360
        jb .wraparoundtop
        fild dword [ZERO]
        fcomip
        ja .wraparoundbottom
        jmp .regular_angle
        .wraparoundtop:
            fldpi
            fimul dword [TWO]
            fsubp; subtracts 2pi from st1 - the angle
            fstp dword [eax+ebx+ANGLE]
            jmp change_speed
        .wraparoundbottom:
            fldpi
            fimul dword [TWO]
            faddp  ; subtracts 2pi from st1 - the angle
            fstp dword [eax+ebx+ANGLE]
            jmp change_speed
        .regular_angle:
        fstp dword [eax+ebx+ANGLE]

    change_speed:
        fld dword [eax+ebx+SPEED]
        fld dword [delta_speed_res]
        faddp
        fild dword [ONE_HUNDRED]
        fcomip
        jb .wraparoundtop
        fild dword [ZERO]
        fcomip
        ja .wraparoundbottom
        jmp .regular_speed
        .wraparoundtop:
            fisub dword [ONE_HUNDRED]
            fstp dword [eax+ebx+SPEED]
            jmp finish
        .wraparoundbottom:
            fiadd dword [ONE_HUNDRED]
            fstp dword [eax+ebx+SPEED]
            jmp finish

        .regular_speed:
        fstp dword [eax+ebx+SPEED]

    finish:
        ffree
        end_func 0

