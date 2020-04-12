extern c_checkValidity
extern printf

section .data
    format: db '%d' , 10, 0

section .text
assFunc:
    push ebp
    mov ebp,esp
    pushad
    pushfd
    sub esp,4
    mov ebx, [ebp + 8]
    mov ecx, [ebp +12]
    add ebx,ecx
    mov [ebp-4],ebx
    push dword [ebp-4] 
    push dword [format] 
    call printf
    add esp,12
    popfd
    popad
    mov esp, ebp
    pop ebp 
    


