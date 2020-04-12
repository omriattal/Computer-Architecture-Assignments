
extern c_checkValidity
extern printf

section .data
    format: db "%d", 10, 0
section .text
    global assFunc

assFunc:
    push ebp                    ;backup EBP
    mov ebp,esp 
    pushad                      ; backup registers
    pushfd
    mov ebx,[ebp + 8]      ; get first argument
    mov ecx, [ebp + 12] 
    push ecx
    push ebx
    call c_checkValidity
    cmp eax,1
    je subtruct
    jne adder
    subtruct:
        sub ebx,ecx
        jmp continue
    adder:
        add ebx,ecx
        jmp continue                        ; assign esp to ebp - new activation frame                    ; backup eFlags                   ;save space for sum     ; get second argument
    continue:
        push ebx
        push format                ; pushes the format char array
        call printf                 ; sum ebx and ecx and store it in ebx            ; assign the value to the space allocated on the stack              ; calls printf
        add esp,16                  ;    add 8 to the esp - to be at the flags and registers backup
        popfd                       ; restore flags value
        popad                       ; restore registers value
        mov esp, ebp                ;set the esp to the ebp
        pop ebp                 ; restore the ebp to original



