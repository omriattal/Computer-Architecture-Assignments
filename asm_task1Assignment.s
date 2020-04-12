extern c_checkValidity
extern printf

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