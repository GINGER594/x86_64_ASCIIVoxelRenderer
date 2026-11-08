section .bss
    fix64srr: resq 1 ;fix64 synthetic return register

section .text

;64-bit fixed-point number struct (sf=2^16) (method args follow syscall convention)

;type fix64 struct
;    value int: [*fix64-8]

;constructs fix64 obj returns pointer to obj
global fix64_construct ;*fix64 (int64)
fix64_construct:
    pop qword [fix64srr]

    mov rax, rsp ;storing pointer in rax for return
    ;init value field
    sub rsp, 8
    mov [rsp], rdi

    push qword [fix64srr]
    ret

;constructs fix64 obj, performs 16-bit left-shift on n, returns pointer to obj
global fix64_constructSal ;*fix64 (int64)
fix64_constructSal:
    pop qword [fix64srr]

    mov rax, rsp ;storing pointer in rax for return
    sal rdi, 16
    ;init value field
    sub rsp, 8
    mov [rsp], rdi

    push qword [fix64srr]
    ret

;constructs fix64 obj from fix64 obj, returns pointer to obj
global fix64_clone ;*fix64 (*fix64)
fix64_clone:
    pop qword [fix64srr]

    mov rax, rsp ;storing pointer in rax for return
    ;init value field
    sub rsp, 8
    mov rdi, [rdi-8] ;getting value field from *fix64 arg
    mov [rsp], rdi

    push qword [fix64srr]
    ret

;returns value / sf
global fix64_getInt ;int64 (*fix64)
fix64_getInt:
    mov rax, [rdi-8]
    sar rax, 16
    ret

;a *= -1
global fix64_neg ;void (*fix64)
fix64_neg:
    neg qword [rdi-8]
    ret

;a += b
global fix64_add ;void (*fix64, *fix64)
fix64_add:
    mov rsi, [rsi-8]
    add [rdi-8], rsi
    ret

;a = (a*b) / sf
global fix64_mul ;void (*fix64, *fix64)
fix64_mul:
    mov rax, [rdi-8]
    imul qword [rsi-8]
    sar rax, 16
    mov [rdi-8], rax
    ret
    