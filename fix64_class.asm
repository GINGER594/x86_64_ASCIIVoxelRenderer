section .data
    sf: dq 65536 ;sf=2^16

section .bss
    fix64srr: resq 1 ;fix64 synthetic return register

section .text

;64-bit fixed-point number class (sf=2^16) (method args follow syscall convention)

;class fix64
;
;int value, accessed via [*fix64-8]
;
;public *fix64 fix64_construct(int64)
;public *fix64 fix64_constructSal(int64)
;
;public int64 fix64_getVal(*fix64)
;
;public int64 fix64_getInt(*fix64)
;public void fix64_neg(*fix64)
;public void fix64_add(*fix64, *fix64)
;public void fix64_mul(*fix64, *fix64)

;constructs fix64 obj returns pointer to obj
global fix64_construct
fix64_construct:
    pop qword [fix64srr]

    mov rax, rsp ;storing pointer in rax for return
    ;init value field
    sub rsp, 8
    mov [rsp], rdi

    push qword [fix64srr]
    ret

;constructs fix64 obj, performs 16-bit left-shift on n, returns pointer to obj
global fix64_constructSal
fix64_constructSal:
    pop qword [fix64srr]

    mov rax, rsp ;storing pointer in rax for return
    sal rdi, 16 ;arg0 *= sf
    ;init value field
    sub rsp, 8
    mov [rsp], rdi

    push qword [fix64srr]
    ret

;returns value field
global fix64_getVal
fix64_getVal:
    mov rax, [rdi-8]
    ret

;returns value / sf
global fix64_getInt
fix64_getInt:
    mov rax, [rdi-8]
    sar rax, 16 ;value / sf
    ret

;a *= -1
global fix64_neg
fix64_neg:
    neg qword [rdi-8]
    ret

;a += b
global fix64_add
fix64_add:
    mov rsi, [rsi-8]
    add [rdi-8], rsi
    ret

;a = (a*b) / sf
global fix64_mul
fix64_mul:
    mov rax, [rdi-8]
    imul qword [rsi-8]
    sar rax, 16 ;result /= sf
    mov [rdi-8], rax
    ret
    