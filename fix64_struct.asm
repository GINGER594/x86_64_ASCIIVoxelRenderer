section .text

;64-bit fixed-point number struct (sf=2^16) (method args follow syscall convention)

;type fix64 struct
;    value int [*fix64-8]

;constructs fix64 obj, returns pointer to obj
global fix64_construct ;*fix64 (int64)
fix64_construct:
    pop rbx

    mov rax, rsp ;storing pointer in rax for return
    ;init value field
    push rdi

    push rbx
    ret

;constructs fix64 obj, arg0 *= sf, returns pointer to obj
global fix64_constructSal ;*fix64 (int64)
fix64_constructSal:
    pop rbx

    mov rax, rsp ;storing pointer in rax for return
    sal rdi, 16
    ;init value field
    push rdi

    push rbx
    ret

;constructs fix64 obj from fix64 obj, returns pointer to obj
global fix64_clone ;*fix64 (*fix64)
fix64_clone:
    pop rbx

    mov rax, rsp ;storing pointer in rax for return
    ;cloning value field
    push qword [rdi-8]

    push rbx
    ret

;returns value/sf
global fix64_Int ;int64 (*fix64)
fix64_Int:
    mov rax, [rdi-8]
    sar rax, 16
    ret

;a += b
global fix64_add ;void (*fix64, *fix64)
fix64_add:
    mov rsi, [rsi-8]
    add [rdi-8], rsi
    ret

;a -= b
global fix64_sub ;void (*fix64, *fix64)
fix64_sub:
    mov rsi, [rsi-8]
    sub [rdi-8], rsi
    ret

;a = (a*b)/sf
global fix64_mul ;void (*fix64, *fix64)
fix64_mul:
    mov rax, [rdi-8]
    imul qword [rsi-8]
    sar rax, 16
    mov [rdi-8], rax
    ret
    