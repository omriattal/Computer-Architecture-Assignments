STACKSZ equ 16*1024
FUNC equ 0
STACK equ 4
DRONE_SIZE equ 24
section .data
    global angle_res
    global position_res
    global number_of_drones
    global scheduler_co
    global printer_co
    global target_co
    global number_of_scheduler_cycles
    global number_of_printer_cycles
    global maximum_distance
    format_string: db "%s",0
    format_integer: db "%d",10,0
    format_float: db "%.2f",10,0
    format_float_regular: db "%f",0
    format_hexa: db "%X",10,
    not_enough_args: db "not enough args,exiting",10,0
    newline_msg: db 10,0
    BOARD_SIZE: dd 100
    MAX_SHORT: dd 0xFFFF
    THREE_SIXTY: dd 360
    ONE_EIGHTY: dd 180
    ONE_TWENTY: dd 120
    SIXTY: dd 60
    TWENTY: dd 20
    TEN: dd 10
    seed: dd 0 ; seed is a word
    number_of_drones: dd 0
    number_of_scheduler_cycles: dd 0
    number_of_printer_cycles: dd 0
    maximum_distance: dd 0.0
    scheduler_co: dd scheduler_func
                  dd scheduler_stack+STACKSZ
    target_co:    dd target_func
                  dd target_stack+STACKSZ
    printer_co:   dd printer_func
                  dd printer_stack+STACKSZ
section .bss
    global drones
    global curr
    global cors
    global sp_main
    global delta_alpha_res
    global delta_speed_res
    position_res: resd 1
    angle_res: resd 1
    delta_alpha_res: resd 1
    delta_speed_res: resd 1
    arg_temp: resd 1
    drones: resd 1
    curr: resd 1
    cors: resd 1
    sp_main: resd 1
    sp_tmp: resd 1
    stack_tmp: resd 1
    printer_stack: resd STACKSZ
    scheduler_stack: resd STACKSZ
    target_stack: resd STACKSZ
    cor_tmp: resd 2
section .text
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
%macro read_arg 3
    pushad
    pushfd
    push dword %3
    push dword %2
    push dword %1
    call sscanf
    add esp,12
    popfd
    popad
%endmacro
%macro create_array 2
    pushad
    pushfd
    push dword %1 ; size of each something
    push dword [number_of_drones]
    call calloc
    add esp,8
    mov dword [%2],eax ; assigns the pointer to operand stack
    popfd
    popad
%endmacro
%macro allocate 2
    pushad
    pushfd
    push dword %1
    push dword 1
    call calloc
    add esp,8
    mov dword [%2],eax
    popfd
    popad
%endmacro
  global main
  global random_words
  global position_gen
  global angle_gen
  global resume
  global end_co
  global do_resume
  global delta_alpha_gen
  global delta_speed_gen
  extern printf
  extern init_drone
  extern init_target
  extern malloc
  extern calloc 
  extern free  
  extern sscanf
  extern printer_func
  extern drone_func
  extern scheduler_func
  extern target_func


; TODO: FREE MEMORY
main: ; the main function
    init_func 0
    push dword [ebp+12]
    call init_args
    add esp,4
    call init_drones
    call init_target
    call create_drone_cors
    call init_all_cors
    start_co:
        pushad
        pushfd
        mov [sp_main],esp
        mov ebx,scheduler_co ; ebx holds the ptr to scheduler co
        jmp do_resume
    end_co:
        mov esp, [sp_main]
        popfd
        popad
    end_func 0
    
init_args:
    init_func 0
    mov ecx, dword [ebp+8] ; char* argv[]
    read_arg [ecx+4],format_integer,number_of_drones
    read_arg [ecx+8],format_integer,number_of_scheduler_cycles 
    read_arg [ecx+12],format_integer,number_of_printer_cycles
    read_arg [ecx+16],format_float_regular,maximum_distance
    read_arg [ecx+20],format_integer,seed
    end_func 0

init_drones:
    init_func 0
    create_array DRONE_SIZE,drones
    mov eax, dword [drones]
    mov ebx,0
    .main_loop:
        cmp ebx,dword [number_of_drones] ; the size of drones
        je .finish_initialize
        push eax
        call init_drone
        add esp,4
        add eax,DRONE_SIZE ; next drone!
        inc ebx ; for the counter.
        jmp .main_loop
    .finish_initialize:
        end_func 0

create_drone_cors:
    init_func 0
    create_array 4,cors ; cors is array of ptrs
    mov edx,0
    mov eax, dword [cors] ; eax is cors array
    .loop:
        cmp edx, dword [number_of_drones]
        je .finish_initialize
        allocate 8,cor_tmp
        mov ebx, dword [cor_tmp] ; ebx holds the current co-routine
        mov dword [eax+4*edx],ebx ; plant the co-routine in the array
        mov dword [ebx+FUNC],drone_func ; set the function to drone_func
        allocate STACKSZ,stack_tmp ; stack is in curr stack
        mov ecx, dword [stack_tmp] ; ecx is the stack tmp
        add ecx,STACKSZ ; make ecx the top of the stack
        mov dword [ebx+STACK],ecx ; assign stack ptr
        inc edx
        jmp .loop
    .finish_initialize:
    end_func 0
init_co:
    init_func 0
    mov ebx, dword [ebp+8] ; get co-routine ptr
    mov eax, dword [ebx+FUNC]
    mov [sp_tmp], esp ; save current esp
    mov esp,[ebx+STACK] ; get stack location
    push eax ; push func to co-routine stack
    pushfd
    pushad
    mov [ebx+STACK],esp ; update the ptr after all the pushes
    mov esp, dword [sp_tmp]
    end_func 0

init_all_cors:
    init_func 0
    mov edx,0
    .init_drones_cors:
        cmp edx, dword [number_of_drones]
        je .init_others
        mov eax, dword [cors] ; the co-routines array
        push  dword [eax+4*edx] ; the current co-routine
        call init_co
        add esp,4
        inc edx
        jmp .init_drones_cors
    .init_others:
        push dword scheduler_co
        call init_co
        add esp,4
        push dword printer_co
        call init_co
        add esp,4
        push dword target_co
        call init_co
        add esp,4
        end_func 0

resume: ;ebx points to the struct of the co-routine to be resumed
    pushfd
    pushad
    mov edx,[curr] ; the current co-routine
    mov [edx+STACK],esp
do_resume:
    mov esp, dword [ebx+STACK]
    mov [curr],ebx ; moves ebx -> curr
    popad
    popfd
    ret

random_bit:
    init_func 0
    mov ebx,0
    bt word [seed], 0 ; set carry flag to be seed[0]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],2 ; set carry flag to be seed[2]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],3 ; set carry flag to be seed[3]
    adc bl,0 ; bl xor carry flag -> bl
    bt word [seed],5 ; set carry flag to be seed[5]
    adc bl,0 ; bl xor carry flag -> bl
    bt bx,0 ; ; set carry flag to be the lsb of bx. the bit we we're calculating
    rcr word [seed],1 ; rotate with carry one time
    end_func 0

random_word:
    init_func 0
    mov ecx, 16 ; do the rotation 16 bytes
    next_bit:
    call random_bit
    loop next_bit, ecx
    end_func 0

position_gen:
    init_func 0
    call random_word ; now seed has the right number we'll use
    finit
    fild dword [seed]
    fidiv dword [MAX_SHORT]
    fimul dword [BOARD_SIZE]
    fstp dword [position_res] ; position_res will hold the result of the operation
    ffree
    end_func 0
angle_gen:
    init_func 0
    finit
    call random_word ; now seed has the right number we'll use
    fild dword [seed]
    fidiv dword [MAX_SHORT]
    fimul dword [THREE_SIXTY] 
    fldpi
    fmulp
    fidiv dword [ONE_EIGHTY]
    fstp dword [angle_res] ; angle_res will hold the result of the operation
    ffree
    end_func 0
delta_alpha_gen:
    init_func 0
    call random_word ; now seed has the right number we'll use
    finit
    fild dword [seed]
    fidiv dword [MAX_SHORT]
    fimul dword [ONE_TWENTY]
    fisub dword [SIXTY]
    fldpi
    fmulp
    fidiv dword [ONE_EIGHTY]
    fstp dword [delta_alpha_res] ; dela_alpha_res will hold the result of the operation
    ffree
    end_func 0
delta_speed_gen:
    init_func 0
    finit
    call random_word
    fild dword [seed]
    fidiv dword [MAX_SHORT]
    fimul dword [TWENTY] ; make it [0,20]
    fisub dword [TEN] ; make it [-10,10]
    fstp dword [delta_speed_res] ; position_res will hold the result of the operation
    ffree
    end_func 0




    

