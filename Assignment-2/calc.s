section .data
    format_string: db "%s",0
    format_integer: db "%d",10,0
    format_hexa: db "%02X",0
    format_hexa_no_pad: db "%0X",0 ; no pad
    newline_msg: db 10,0
    calc_msg: db "calc: ",0
    error_msg_overflow: db "Error: Operand Stack Overflow",10,0
    error_msg_insufficient: db "Error: Insufficient Number of Arguments on Stack",10,0
    comma_msg: db ", ",0
    is_allocated: db 0 ; boolean - determines if te operand stack was allocated
    operand_stack_size: db 5
    operand_stack_index: db 0
    number_of_actions: dd 0
    calloc_ptr: dd 0
    max_size: db 80
    byte_string_for_node: db 48,0,0 ; the raw data of two bytes to be ready for the node

section .bss
    operand_stack: resd 5
    str_input: resb 80
    number: resd 1
    

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc
  extern calloc 
  extern free 
  extern stdin
  extern gets 
  extern getchar 
  extern fgets 

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

%macro input_stdin 1
    pushfd
    pushad
    push dword [stdin]
    push dword [max_size]
    push dword %1
    call fgets
    add esp,12
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
%macro allocate_node 0
    pushad
    pushfd
    push dword 1
    push dword 5
    call calloc
    add esp,8
    mov dword [calloc_ptr],eax
    popfd
    popad
%endmacro
%macro allocate_stack 1
    pushad
    pushfd
    push dword 4
    push dword %1
    call calloc
    add esp,8
    mov dword [operand_stack],eax ; assigns the pointer to operand stack
    popfd
    popad
%endmacro
%macro free_node 1
    pushad
    pushfd
    push dword %1
    call free
    add esp,4
    popfd
    popad
%endmacro
%macro create_link 2
    pushad
    pushfd
    allocate_node ; calloc_ptr holds the ptr
    mov edx, dword [calloc_ptr]
    mov byte [edx], %1
    mov dword [edx +1], %2
    mov [calloc_ptr],edx
    popfd
    popad
%endmacro

add_nodes:
    init_func 8
    mov edx,0
    mov dl, byte [operand_stack_index]
    mov eax,0 ; will hold the new node at the end
    mov ebx, dword [operand_stack+4*edx] ; the first one
    dec edx
    dec byte [operand_stack_index]
    mov ecx, dword [operand_stack +4*edx] ; the second node

    .add_first:
        mov eax,0
        mov edx,0
        mov ah, byte [ebx] ; the first node
        mov dh, byte [ecx] ; the second node
        adc ah,dh ; add with carry
        mov dl,ah
        mov eax,0
        mov al , dl ; mov to lower byte
        create_link al,0
        mov eax, dword [calloc_ptr] ; eax = new node
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next 
        mov dword [ebp-4],eax ; backup eax - the first ptr
        
    ; don't touch ebp -4
    ; eax holds the current one, ebx - the first, ecx - the second, edx - free
    .add_rest:
        pushfd ; backup flags
        cmp ebx,0 ;cmprs to null ptr
        je .no_ebx_popfd
        cmp ecx,0
        je .no_ecx_popfd

        popfd
        mov dword [ebp-8],eax ; backup eax
        mov eax,0
        mov edx,0
        mov ah, byte [ebx] ; the first node
        mov dh, byte [ecx] ; the second node
        ADC ah,dh ; add with carry
        mov dl,ah
        mov eax,0
        mov al , dl ; mov to lower byte
        create_link al,0 ; now calloc _ ptr holds the new node
        mov eax, dword [ebp-8] ; restore backup
        mov edx, dword [calloc_ptr]
        mov dword [eax+1],edx ; eax = edx -> next
        mov eax,edx ; eax = eax - > next
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next 
        jmp .add_rest

    .no_ebx_popfd:
        popfd ; this is for the pop
    .no_ebx:
        pushfd
        cmp ecx,0
        je .check_carry
        popfd
        mov dword [ebp-8],eax ; backup eax
        mov eax,0
        mov edx,0
        mov ah, byte [ecx] ; the first node
        mov dh, 0 ; there is nothing in ebx
        ADC ah,dh ; add with carry
        mov dl,ah
        mov eax,0
        mov al , dl ; mov to lower byte
        create_link al,0 ; now calloc _ ptr holds the new node
        mov eax, dword [ebp-8] ; restore backup
        mov edx, dword [calloc_ptr]
        mov dword [eax+1],edx ; eax = edx -> next
        mov eax,edx ; eax = eax - > next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next 
        jmp .no_ebx

    .no_ecx_popfd:
        popfd ; this is for the pop
    .no_ecx: 
        pushfd
        cmp ebx,0
        je .check_carry
        popfd
        mov dword [ebp-8],eax ; backup eax
        mov eax,0
        mov edx,0
        mov ah, byte [ebx] ; the first node
        mov dh, 0 ; there is nothing in ecx
        ADC ah,dh ; add with carry
        mov dl,ah
        mov eax,0
        mov al , dl ; mov to lower byte
        create_link al,0 ; now calloc _ ptr holds the new node
        mov eax, dword [ebp-8] ; restore backup
        mov edx, dword [calloc_ptr]
        mov dword [eax+1],edx ; eax = edx -> next
        mov eax,edx ; eax = eax - > next
        mov edx, dword [ebx + 1]; edx = ebx->next
        mov ebx, edx ; ebx = ebx -> next 
        jmp .no_ecx

    .check_carry:
        popfd
        jnc .finished_adding
        create_link 1,0 ; 1 is the carry
        mov edx, dword [calloc_ptr]
        mov dword [eax+1],edx ; eax = edx -> next
        mov eax,edx ; eax = eax - > next

    .finished_adding:
        mov eax, dword [ebp-4]
        inc byte [operand_stack_index] ; getting ready to pop the top one
        call stack_pop
        dec byte [operand_stack_index] ; getting ready to pop the the bottom one
        call stack_pop
        mov edx,0
        mov dl,byte [operand_stack_index]
        mov dword [operand_stack+4*edx],eax ; the new ptr
        end_func 8

bitwise_and:
    init_func 8
    mov edx,0
    mov dl, byte [operand_stack_index]
    mov eax,0 ; will hold the new node at the end
    mov ebx, dword [operand_stack+4*edx] ; the first one
    dec edx
    dec byte [operand_stack_index]
    mov ecx, dword [operand_stack +4*edx] ; the second node

    .bitwise_first:
        mov eax,0
        mov al, byte [ebx] ; the byte of the first node
        mov ah, byte [ecx] ; the byte of the second node
        AND al,ah
        create_link al,0 ; now calloc ptr holds the new nodes
        mov eax, dword [calloc_ptr] ; eax holds the new ptr
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next

    ; eax holds the new ptr - don't touch , backup by ebp -4
    mov dword [ebp -4],eax

    .bitwise_rest:
        cmp ebx,0 ; ebx is null
        jmp .finished_reading
        cmp ecx,0
        jmp .finished_reading
        mov edx,0
        mov dl, byte [ebx]
        mov dh, byte [ecx]
        AND dl,dh
        print format_hexa, edx
        mov dword [ebp-8],eax ; backup
        mov eax, 0
        mov al,dl
        create_link al , 0 ; now calloc ptr holds the new ptr
        mov eax, dword [ebp-8] ; restore
        mov edx, dword [calloc_ptr]
        mov dword [eax + 1],edx ; next of eax
        mov eax, edx ; eax = eax -> next
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next
        jmp .bitwise_rest

    .finished_reading:
        mov eax, dword [ebp-4]
        inc byte [operand_stack_index] ; getting ready to pop the top one
        call stack_pop
        dec byte [operand_stack_index] ; getting ready to pop the the bottom one
        call stack_pop
        mov edx,0
        mov dl , byte [operand_stack_index]
        mov dword [operand_stack+4*edx],eax ; the new ptr
        end_func 8

bitwise_or: ; receives nothing , assumes correct index locations
    init_func 8
    mov edx,0
    mov dl, byte [operand_stack_index]
    mov eax,0 ; will hold the new node at the end
    mov ebx, dword [operand_stack+4*edx] ; the first one
    dec edx
    dec byte [operand_stack_index]
    mov ecx, dword [operand_stack +4*edx] ; the first node

    .bitwise_first:
        mov eax,0
        mov al, byte [ebx] ; the byte of the first node
        mov ah, byte [ecx] ; the byte of the second node
        OR al,ah
        create_link al,0 ; now calloc ptr holds the new nodes
        mov eax, dword [calloc_ptr] ; eax holds the new ptr
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next

    ; eax holds the new ptr - don't touch , backup by ebp -4
    mov dword [ebp -4],eax

    .bitwise_rest:
        cmp ebx,0 ; ebx is null
        je .no_ebx
        cmp ecx,0
        je .no_ecx
        mov edx,0
        mov dl, byte [ebx]
        mov dh, byte [ecx]
        OR dl,dh
        print format_hexa, edx
        mov dword [ebp-8],eax ; backup
        mov eax, 0
        mov al,dl
        create_link al , 0 ; now calloc ptr holds the new ptr
        mov eax, dword [ebp-8]
        mov edx, dword [calloc_ptr]
        mov dword [eax + 1],edx ; next of eax
        mov eax, edx ; eax = eax -> next
        mov edx, dword [ebx+1] ; edx = ebx->next
        mov ebx, edx ; ebx = ebx ->next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next
        jmp .bitwise_rest

    .no_ebx:
        cmp ecx,0
        je .finished_reading
        mov edx,0
        mov dl, byte [ecx] ; dl holds the data
        mov dword [ebp-8],eax ; backup
        mov eax, 0
        mov al,dl
        create_link al , 0 ; now calloc ptr holds the new ptr
        mov eax, dword [ebp-8]
        mov edx, dword [calloc_ptr]
        mov dword [eax+1], edx ; edx = eax -> next
        mov eax, edx ; eax = eax -> next
        mov edx, dword [ecx + 1]; edx = ecx->next
        mov ecx, edx ; ecx = ecx -> next
        jmp .no_ebx

    .no_ecx:
        cmp ebx,0
        je .finished_reading
        mov edx,0
        mov dl, byte [ebx] ; dl holds the data
        mov dword [ebp-8],eax ; backup
        mov eax, 0
        mov al,dl
        create_link al , 0 ; now calloc ptr holds the new ptr
        mov eax, dword [ebp-8]
        mov edx, dword [calloc_ptr]
        mov dword [eax+1], edx ; edx = eax -> next
        mov eax, edx ; eax = eax -> next
        mov edx, dword [ebx + 1]; edx = ebx->next
        mov ebx, edx ; ecx = ecx -> next
        jmp .no_ecx

    .finished_reading:
        mov eax, dword [ebp-4]
        inc byte [operand_stack_index] ; getting ready to pop the top one
        call stack_pop
        dec byte [operand_stack_index] ; getting ready to pop the the bottom one
        call stack_pop
        mov edx,0
        mov dl , byte [operand_stack_index]
        mov dword [operand_stack+4*edx],eax ; the new ptr
        end_func 8

duplicate_node: ;receives nothing - duplicates the current node in the stack
    init_func 0
    mov edx,0
    mov dl , byte [operand_stack_index]; move index to edx
    mov ebx, dword [operand_stack+4*edx]; move current node to ebx
    inc edx ; getting ready to store it
    inc byte [operand_stack_index] 
    mov ecx, 0 ; will hold the duplicated 
    mov eax,0
    .duplicate_first:
        mov al , byte [ebx] ; get the data
        create_link al,0 ; now [calloc_ptr] holds the ptr
        mov ecx, dword [calloc_ptr] ; holds the copied node in ecx
        mov dword [operand_stack+4*edx], ecx ; holds the location in the operand stack
        mov edx, dword [ebx+1] ; edx = ebx ->next
        mov ebx, edx ; ebx = ebx->next
    
    .duplicate_rest:
        cmp ebx,0 ; compares ebx to nullptr
        je .finish_duplicating
        mov eax,0
        mov al, byte [ebx] ; al = ebx = curr.data
        create_link al,0  ; calloc holds the ptr of the new node
        mov edx, dword [calloc_ptr] ; edx holds the next
    .after_reading1:
        mov dword [ecx+1],edx ; updates the next
        mov edx, dword [ebx+1] ; edx = ebx -> next
        mov ebx, edx ; ebx = ebx->next
        mov edx, dword [ecx+1] ; edx = ecx -> next
        mov ecx, edx ; ecx = ecx->next
        jmp .duplicate_rest

    .finish_duplicating:
        end_func 0

calculate_hex_digits: ; receives nothing - iterates over the current node list and calculates hexadecimal digits
    init_func 4
    mov edx, 0
    mov eax, 0 ; will count the amount of digits
    mov dl, byte [operand_stack_index] ; now dl has the index
    mov ecx, dword [operand_stack+4*edx] ; ecx has the current pointer
    .read_loop:
        cmp ecx , 0 ; if ecx is nullptr
        je .finished_reading
        mov ebx , dword [ecx + 1]; the next node
        cmp ebx , 0 ; ecx is the last node
        je .last_node_case
        .inc_eax_2:
            inc eax 
            inc eax ; two digits
            mov ecx , ebx ; ecx = ecx -> next
            jmp .read_loop
        .last_node_case:
            cmp byte [ecx], 15 ; smaller than 15
            jg .inc_eax_2 ; larger than 15 - two digits
        .inc_eax_1:
            inc eax
            mov ecx , ebx ; ecx = ecx -> next
            jmp .read_loop

    .finished_reading:
        end_func_save 4,eax 

free_stack: ;frees the stack
    init_func 0
    mov edx, 0 ; the index
    .free_loop:
        cmp dl, byte [operand_stack_size] ; means we're done
        je .finished_deleting
        mov byte [operand_stack_index] , dl ; getting ready for stack push
        call stack_pop ; frees the current node
        inc dl
        jmp .free_loop
    .finished_deleting:
    end_func 0

stack_pop: ; receives nothing, pops the node list from the current index in operand stack
    init_func 4
    mov edx,0
    mov dl, byte [operand_stack_index] ; mov stack index to edx (it's a byte!)
    mov ecx, dword [operand_stack+4*edx] ; now ecx holds the ptr to the current node
    .node_loop:
    cmp ecx,0 ; if ecx is null
    je .finished_deleting
        .delete_node:
            mov dword [ebp -4], ecx ; save value
            mov ebx, dword [ecx+1] ; save next value of ecx
            mov ecx, ebx ; ecx = ecx -> next
            free_node [ebp-4] ; free the node
            jmp .node_loop

    .finished_deleting:
     mov dword [operand_stack+4*edx],0 ; nullptr
     end_func 4


is_number: ; receives a ptr to a string and outputs 1 in eax if the first char is a a number
    init_func 4
    mov ebx, dword [ebp +8] ; ebx stores the ptr
    cmp byte [ebx],48 ; compars to '0'
    jb .not_a_number
    cmp byte [ebx],58 ; compars to ':' 
    jge .not_a_number
    mov eax, 1 ; the first char is a number
    jmp .finished_reading

    .not_a_number:
        mov eax,0

    .finished_reading:
        end_func_save 4,eax ; save eax value

init_args: ;receives argc [ebp+8], char* argv [ebp+12] - updates stack size
    init_func 0
    mov ebx, dword [ebp+8] ; save argc
    mov ecx, dword [ebp+12] ; ecx = char*argv[]
    mov edx, 1 ; main loop index,ignoring the first - will end when equals ebx
    mov eax,0 ; will hold the correct size at the end, if specified
    .argloop:
        cmp edx,ebx
        je .finished_reading
        push dword [ecx+4*edx] ; pushes the string ptr to is number
        call is_number ; eax stores 1 if the first  char is a number
        add esp,4
        cmp eax,0 ; not a number
        je .continue_reading
        mov eax,0
        push dword [ecx+4*edx] ; pushes string ptr
        call convert_hex_str_to_number ; now eax  holds the decimal number
        add esp,4 
            mov byte [is_allocated],1 ; says that the stack was allocated
            allocate_stack eax  ; now calloc_ptr holds the pointer to the stack
            mov byte [operand_stack_size], al
            jmp .finished_reading

        .continue_reading:
            inc edx
            jmp .argloop

    .finished_reading:
        end_func 0

convert_hex_str_to_number: ;receives a string represting a hex number and calcualte its decimal value
   init_func 4
    mov dword [ebp-4],16 ;the base
    mov ebx, dword [ebp+8]
    mov edx,0 ;index of string
    mov eax,0 ;the multiplyer
    .convertor:
        cmp byte [ebx+edx],10
        je .finished_reading
        cmp byte [ebx+edx],0
        je .finished_reading
        cmp byte [ebx+edx],57 ; 0,9
        jle .convert_0_9
        .convert_A_F:
            sub byte [ebx+edx],55 ;transform to 10,15
            push edx
            mul dword [ebp-4]
            pop edx
            mov ecx,0
            mov byte cl,[ebx+edx]
            add eax,ecx
            inc edx
            jmp .convertor

        .convert_0_9:
            sub byte [ebx+edx],48 ;transform to 0,9
            push edx
            mul dword [ebp-4]
            pop edx
            mov ecx,0
            mov cl, byte [ebx+edx]
            add eax,ecx
            inc edx
            jmp .convertor

        .finished_reading:
     end_func_save 4,eax


str_length: ; receives a string and calculate it's length
    init_func 4
    mov ebx, dword [ebp+8]
    mov eax,0
    .iterator:
        cmp byte [ebx+eax],10
        je .finished_reading
        inc eax
        jmp .iterator

    .finished_reading:
       end_func_save 4,eax

check_even: ;receives a string and outputs eax = 1 if its length is even, 1 otherwise
    init_func 4
    push dword [ebp+8]
    call str_length ; eax store the eveness of the length of the string
    add esp,4
    bp_after_length:
    mov edx,0
    mov ebx,2
    div ebx ; divide by 2
    cmp edx,0 ;remainder is in edx
    je .set_to_one
    mov eax,0
    jmp .finish
        .set_to_one:
            mov eax,1 
    .finish:
    end_func_save 4,eax ;save eax value

print_node: ;receives a pointer to a node and outputs all of its data
    init_func 4
    mov ebx, dword [ebp+8] ; ebx holds the pointer to the node
    mov edx,0
    mov eax,0
    mov byte [ebp-4],0 ; will count the amount of times pushed data to stack
    .iterator: 
        cmp ebx,0 ; compares ebx (holds pointer) to nullptr
        je .print_special_case
        mov edx,0
        mov dl, byte [ebx] ; move the data to edx
        push edx ; stores the data
        inc eax ; updates the amount of times
        mov ecx, dword [ebx+1] ; hold the next one in ecx
        mov ebx,ecx ; update ebx
        jmp .iterator

    .print_special_case: ; for different formatting
        pop edx
        print format_hexa_no_pad,edx
        dec eax
    .print_stack_loop:
            cmp eax,0 ; no more pushes in the stack, only the last one
            je .finished_reading
            pop edx
            print format_hexa,edx
            dec eax 
            jmp .print_stack_loop

    .finished_reading:
        
        print format_string,newline_msg
        end_func 4

make_node: ;receives a string and makes a a series of nodes. eax holds it
    init_func 12 ; many local variables
    mov dword [ebp-4],0 ; check_even
    mov dword [ebp-8],0
    mov dword [ebp-12],0
    mov ebx, dword [ebp+8] ; ebx stores the pointer to the string

    .ignore_leading_zeroes:
        cmp byte [ebx],'0'
        jne .no_more_zeroes
        inc ebx
        jmp .ignore_leading_zeroes
    
    .no_more_zeroes:
        cmp byte [ebx] , 10 ; the end
        jne .continue
        dec ebx
    .continue:
    push ebx
    call check_even ; eax stores 1 if the length is even and 0 otherwise
    add esp,4 
    mov dword [ebp-4],eax ; [ebp-4] stores the eveness of the string
    mov edx,0 ; index of the string we will use
    mov ecx, 0 
    cmp dword [ebp-4],1 ; the string's length is even
    je .make_node_even
    .make_node_odd: ; only one will be there including the 48 in the beginning
            .parse_first_odd: ; will parse the first byte as zero padding to the left and nullptr
                mov byte cl, [ebx] ; get the first byte
                mov byte [byte_string_for_node+1], cl ; second location - first is zero (48)
                push byte_string_for_node
                call convert_hex_str_to_number ;eax now stores the first two bytes as parsed decimal number - 1 byte
                add esp,4
                allocate_node ; now calloc_ptr holds the location in memmory of the node allocation
                mov ecx, dword [calloc_ptr]
                .bp_after_str_conversion:
                mov byte [ecx], al ; inserts the data to the node
                mov dword [ecx + 1],0 ; nullptr
                inc edx
                jmp .main_node_creator
                
    .make_node_even:
        cmp byte [ebx+edx],10 ; the string might be in length of 1
        je .finished_reading ; 
        cmp byte [ebx+edx],0
        je .finished_reading
            .parse_first_even:
                mov byte cl, [ebx] ; get the first byte
                mov byte ch, [ebx + 1 ] ; second byte
                mov byte [byte_string_for_node], cl ; second location - first is zero (48)
                mov byte [byte_string_for_node+1], ch ; second location - first is zero (48)
                push byte_string_for_node
                call convert_hex_str_to_number ;eax now stores the first two bytes as parsed decimal number - one byte
                add esp,4
                allocate_node ; now calloc_ptr holds the location in memmory of the node allocation
                mov ecx, dword [calloc_ptr] ; ecx stores the ptr
                mov byte [ecx],al ; inserts the data to the node
                mov dword [ecx + 1],0 ; nullptr
                inc edx
                inc edx
                jmp .main_node_creator

        .main_node_creator: ; will convert the rest of the string to nodes, two chars at a time (guaranteed)
                cmp byte [ebx+edx],10
                je .finished_reading
                cmp byte [ebx+edx],0
                je .finished_reading
                mov eax,0 ; zero eax for getting the number
                mov byte al, [ebx+edx] ; first byte of the string
                inc edx
                mov byte ah , [ebx+edx] ; second byte
                inc edx
                mov byte [byte_string_for_node], al ; first byte
                mov byte [byte_string_for_node + 1],ah ; second byte
                push byte_string_for_node
                call convert_hex_str_to_number ; now eax stores the right number as integer data
                add esp,4
                allocate_node ; calloc_ptr holds the pointer - we want to hold it in edx after saving edx value
                mov dword [ebp-8],edx ; saving edx's values
                mov edx, dword [calloc_ptr] ; edx holds the pointer to the next node
                mov byte [edx], al ; changes the data - stores in eax in 1 byte
                mov dword [edx+1], ecx ; next is the pointer of ecx
                mov dword ecx, edx ; saves the new pointer in ecx
                mov edx, dword [ebp - 8] ; restores the index
                jmp .main_node_creator

     .finished_reading: ; now ecx holds the pointer to the nodes
        mov byte [byte_string_for_node],48
        mov byte [byte_string_for_node+1],0
        mov eax, ecx ; change the pointer to eax
        end_func_save 12,eax


main: ; the main function
    init_func 0
    push dword [ebp+12] ; char* argv[]
    push dword [ebp+8] ;argc
    call init_args
    add esp,8

    call my_calc
    print format_integer, [number_of_actions] ;prints number of actions
    end_func 0

my_calc:
    init_func 0
    .main_loop:
    print format_string,calc_msg
    input_stdin str_input

    .after_reading:
    cmp byte [str_input],113 ;cmp to 'q'
    je .finish_program

    cmp byte [str_input],112 ; 'p'
    jne .check_duplicate
    call handle_pop_print
    jmp .main_loop

    .check_duplicate:
    cmp byte [str_input],100 ; 'd'
    jne .check_bitwise_and
    call handle_duplicate
    jmp .main_loop

    .check_bitwise_and:
    cmp byte [str_input],'&'
    jne .check_bitwise_or
    call handle_bitwise_and
    jmp .main_loop
    
    .check_bitwise_or:
    cmp byte [str_input],'|'
    jne .check_number_of_digits
    call handle_bitwise_or
    jmp .main_loop

    .check_number_of_digits:
    cmp byte [str_input],110 ; 'n'
    jne .check_addition
    call handle_number_of_digits
    jmp .main_loop

    .check_addition:
    cmp byte [str_input],'+'
    jne .check_number
    call handle_addition
    jmp .main_loop
 
    .check_number:
    push str_input ; first input is a number
    call handle_number
    add esp,4
    jmp .main_loop
    
    .finish_program:
        cmp byte [is_allocated],1
        jne .continue
        call free_stack
        .continue:
        end_func 0

handle_number: ; handles the enter number option - makes node list in the operand stack if there is space, receives str_input
    init_func 0
    mov eax,0
    mov al, byte [operand_stack_size]
    cmp byte [operand_stack_index],al ; the stack is full
    jne .add_to_operand_stack ; stack is full
    print format_string, error_msg_overflow ; error msg 
    jmp .finished_reading
    .add_to_operand_stack:
        mov ebx,0
        mov bl,byte [operand_stack_index] ; moves the index to ebx
        mov ecx, dword [ebp +8] ; ecx holds the ptr to the string
        push ecx ; pushes the string
        call make_node ; eax stores the ptr to the linked list
        add esp,4  
        mov dword [operand_stack+4*ebx],eax ; now operand_Stack[ebx] = pointer to  a series of nodes
        inc byte [operand_stack_index] ; increments the index

    .finished_reading:
    inc dword [number_of_actions]
    end_func 0 
    

handle_pop_print: ; receives nothing - prints and pop the current node from the list, updates the index
    init_func 0
    mov edx,0
    mov dl , byte [operand_stack_index] ; dl is the index now
    cmp dl,0 ; there is nothing in the stack
    je .error_msg
    .print_pop:
        dec edx ; now edx points to the current index 
        push dword [operand_stack+4*edx]
        call print_node ; prints the node
        add esp,4
        dec byte [operand_stack_index]
        call stack_pop ; pops the node from the stack
        jmp .finish_popping

    .error_msg:
        print format_string,error_msg_insufficient ; prints error msg
    
    .finish_popping:
    inc dword [number_of_actions]
    end_func 0


handle_number_of_digits: ; received nothing - pop the last node and pushes its length
    init_func 0
    mov eax,0
    mov edx,0
    cmp byte [operand_stack_index] , 0 ; stack is empty
    je .error_msg
    .calculate_hex_digits_pop_and_push: ; now eax has the right amount of hex digits
        mov dl, byte [operand_stack_index]
        dec byte [operand_stack_index] ; decrements the index, get ready for calculate hex digits
        call calculate_hex_digits ; eax stores the number of digits
        print format_hexa, eax
        call stack_pop ; pop the node from the stack
        create_link al , 0 ; al is the data, calloc ptr has the ptr
        mov ecx , dword [calloc_ptr] ; move ptr to ecx
        mov dl, byte [operand_stack_index] ; move the index to dl
        mov dword [operand_stack+4*edx], ecx ; push to stack
        inc byte [operand_stack_index] ; increments the index - next location
        jmp .finished_reading
    .error_msg:
        print format_string,error_msg_insufficient ; prints error msg

    .finished_reading:
        inc dword [number_of_actions]
        end_func 0
handle_duplicate: ; receives nothing, pushes a new copy of the current node in the operand stack
    init_func 0
    mov ecx,0
    mov cl, [operand_stack_size] ; save operand stack size
    cmp byte [operand_stack_index],cl ; stack is full
    je .error_msg_overflow
    cmp byte [operand_stack_index],0
    je .error_msg_insufficient
    dec byte [operand_stack_index]
    call duplicate_node
    inc byte [operand_stack_index] ; incrementing the index
    jmp .finish_duplicate
    .error_msg_overflow:
        print format_string,error_msg_overflow
        jmp .finish_duplicate
    
    .error_msg_insufficient:
        print format_string,error_msg_insufficient
    .finish_duplicate:
        inc dword [number_of_actions]
        end_func 0

handle_bitwise_or: ; pops the last two nodes and pushes their result in bitwise or to the stack
    init_func 0
    mov edx,0
    mov dl, byte [operand_stack_index] ; move index to edx
    cmp dl ,1 ; there is only one node in the stack
    jle .error_msg
    .do_bitwise_or:
        dec byte [operand_stack_index] ; decrements index, getting ready for bitwise
        call bitwise_or
        inc byte [operand_stack_index] ; the new free
        jmp .finish_bitwise

    .error_msg:
        print format_string,error_msg_insufficient
    
    .finish_bitwise:
         inc dword [number_of_actions]
        end_func 0

handle_bitwise_and: ; pops the last two nodes and pushes their result in bitwise and to the stack
  init_func 0
    mov edx,0
    mov dl, byte [operand_stack_index] ; move index to edx
    cmp dl ,1 ; there is only one node in the stack
    jle .error_msg
    .do_bitwise_or:
        dec byte [operand_stack_index] ; decrements index, getting ready for bitwise
        call bitwise_and
        inc byte [operand_stack_index] ; the new free
        jmp .finish_bitwise

    .error_msg:
        print format_string,error_msg_insufficient
    
    .finish_bitwise:
        inc dword [number_of_actions]
        end_func 0

handle_addition: ; pops the last two nodes and pushes their result in unsigned addition to the stack
 init_func 0
    mov edx,0
    mov dl, byte [operand_stack_index] ; move index to edx
    cmp dl ,1 ; there is only one node in the stack
    jle .error_msg
    .do_addition:
        dec byte [operand_stack_index] ; decrements index, getting ready for bitwise
        call add_nodes
        inc byte [operand_stack_index] ; the new free
        jmp .finish_adding

    .error_msg:
        print format_string,error_msg_insufficient
    
    .finish_adding:
         inc dword [number_of_actions]
        end_func 0




