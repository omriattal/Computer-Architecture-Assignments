section .data
    X: equ 0
    Y: equ 4
    ANGLE: equ 8
    SPEED: equ 12
    SCORE: equ 16
    STATUS: equ 20
    DRONE_SIZE equ 24
    format_float: db "%.2f",0
    format_string: db "%s",0
    format_integer: db "%d",0
    active_msg: db "ACTIVE",0
    inactive_msg: db "INACTIVE",0
    comma_msg: db ", ",0
    newline_msg: db 10,0
    angle_maalot: dd 0
    coordinates_msg: db "COORDINATES: ",0
    angle_msg: db "ANGLE: ",0
    speed_msg: db "SPEED: ",0
    score_msg: db "SCORE: ",0
    ONE_EIGHTY: dd 180
section .text
    global print_drones
    global printer_func
    extern target_x
    extern target_y
    extern printf
    extern drones
    extern scheduler_co
    extern resume
    extern number_of_drones

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
%macro print_newline 0
    pushad
    pushfd
    push dword newline_msg
    push dword format_string
    call printf
    add esp,8
    popfd
    popad
%endmacro

printer_func:
    print_float dword [target_x] ; prints target x location
    print format_string,comma_msg
    print_float dword [target_y] ; prints target y location
    print_newline
    call print_drones
    mov ebx, scheduler_co ; the current co-routine
    call resume
    jmp printer_func

print_drones:
    init_func 0
    mov ebx, dword [drones]
    mov ecx,0
    .main_loop:
        cmp ecx,dword [number_of_drones]
        je .finish_looping
        inc ecx
        print format_integer,ecx
        dec ecx
        print format_string,comma_msg
        print format_string,coordinates_msg
        print_float dword [ebx+X]
        print format_string,comma_msg
        print_float dword [ebx+Y]
        print format_string,comma_msg
        print format_string,angle_msg
        fld dword [ebx+ANGLE]
        fldpi
        fdivp
        fimul dword [ONE_EIGHTY]
        fstp dword [angle_maalot]
        print_float dword [angle_maalot]
        print format_string,comma_msg
        print format_string,speed_msg
        print_float dword [ebx+SPEED]
        print format_string,comma_msg
        print format_string,score_msg
        print format_integer,[ebx+SCORE]
        print format_string,comma_msg
        cmp dword [ebx+STATUS],1
        je .print_active
        print format_string,inactive_msg
        jmp .cont
        .print_active:
            print format_string,active_msg

        .cont:
        inc ecx
        add ebx,DRONE_SIZE
        print_newline
        jmp .main_loop
    .finish_looping:
        end_func 0