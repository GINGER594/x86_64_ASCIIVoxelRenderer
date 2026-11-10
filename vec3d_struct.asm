section .bss
    v3dsrr: resq 1 ;vec3d synthetic return register
    v3dsspr: resq 1 ;vec3d synthetic stack pointer register

    ;vec3d aboutA, vec3d aboutB, vec3d rotation - used in rotAB
    v3dAbtA: resq 1
    v3dAbtB: resq 1
    v3dRot: resq 1

section .text
extern fix64_construct
extern fix64_constructSal
extern fix64_clone
extern fix64_neg
extern fix64_add
extern fix64_mul

;3d vector struct (method args follow syscall convention)

;type vec3d struct
;    x *fix64 [*vec3d-8]
;    y *fix64 [*vec3d-16]
;    z *fix64 [*vec3d-24]

;constructs vec3d obj, returns pointer to obj
global vec3d_construct ;*vec3d (*fix64, *fix64, *fix64)
vec3d_construct:
    pop qword [v3dsrr]

    mov rax, rsp ;storing pointer in rax for return
    ;init fields
    sub rsp, 24
    mov [rsp+16], rdi ;x
    mov [rsp+8], rsi ;y
    mov [rsp], rdx ;z

    push qword [v3dsrr]
    ret

global vec3d_getX ;*fix64 (*vec3d)
vec3d_getX:
    mov rax, [rdi-8]
    ret

global vec3d_getY ;*fix64 (*vec3d)
vec3d_getY:
    mov rax, [rdi-16]
    ret

global vec3d_getZ ;*fix64 (*vec3d)
vec3d_getZ:
    mov rax, [rdi-24]
    ret

;rotates (a, b) rot about (abtA, abtB) using small-angle approximations: (a-abtA)-((b-abtB)*rot)+abtA, (b-abtB)+((a-abtA)*rot)+abtB
rotAB: ;void (a *fix64, b *fix64, abtA *fix64, abtB *fix64, rot *fix64)
    mov [v3dsspr], rsp ;storing stack pointer

    mov r11, rdi ;a = r11
    mov r12, rsi ;b = r12
    mov [v3dAbtA], rdx
    mov [v3dAbtB], r10
    mov [v3dRot], r8

    ;a -= abtA
    mov rdi, [v3dAbtA]
    call fix64_neg ;abtA *= -1
    mov rdi, r11
    mov rsi, [v3dAbtA]
    call fix64_add ;a += abtA
    mov rdi, [v3dAbtA]
    call fix64_neg ;abtA *= -1
    ;b -= abtB
    mov rdi, [v3dAbtB]
    call fix64_neg ;abtB *= -1
    mov rdi, r12
    mov rsi, [v3dAbtB]
    call fix64_add ;b += abtB
    mov rdi, [v3dAbtB]
    call fix64_neg ;abtB *= -1

    ;r13 = cloneA
    mov rdi, r11
    call fix64_clone
    mov r13, rax
    ;r14 = cloneB
    mov rdi, r12
    call fix64_clone
    mov r14, rax

    ;a -= cloneB*rot
    mov rdi, r14
    call fix64_neg ;cloneB *= -1
    mov rdi, r14
    mov rsi, [v3dRot]
    call fix64_mul ;cloneB *= rot
    mov rdi, r11
    mov rsi, r14
    call fix64_add ;a += cloneB
    ;b += cloneA*rot
    mov rdi, r13
    mov rsi, [v3dRot]
    call fix64_mul ;cloneA *= rot
    mov rdi, r12
    mov rsi, r13
    call fix64_add ;b += cloneA

    ;a += abtA
    mov rdi, r11
    mov rsi, [v3dAbtA]
    call fix64_add
    ;b += abtB
    mov rdi, r12
    mov rsi, [v3dAbtB]
    call fix64_add

    mov rsp, [v3dsspr] ;restoring stack pointer (freeing space used by cloneA, cloneB objects)
    ret

;rotates x, y fields by rot about (abtX, abtY)
global vec3d_rotXY ;void (*vec3d, abt *vec3d, rot *fix64)
vec3d_rotXY:
    mov r8, rdx ;rot
    mov r10, [rsi-16] ;abtY
    mov rdx, [rsi-8] ;abtX
    mov rsi, [rdi-16] ;y
    mov rdi, [rdi-8] ;x
    call rotAB
    ret

;rotates x, z fields by rot about (abtX, abtZ)
global vec3d_rotXZ ;void (*vec3d, abt *vec3d, rot *fix64)
vec3d_rotXZ:
    mov r8, rdx ;rot
    mov r10, [rsi-24] ;abtZ
    mov rdx, [rsi-8] ;abtX
    mov rsi, [rdi-24] ;z
    mov rdi, [rdi-8] ;x
    call rotAB
    ret

;rotates y, z fields by rot about (abtY, abtZ)
global vec3d_rotYZ ;void (*vec3d, abt *vec3d, rot *fix64)
vec3d_rotYZ:
    mov r8, rdx ;rot
    mov r10, [rsi-24] ;abtZ
    mov rdx, [rsi-16] ;abtY
    mov rsi, [rdi-24] ;z
    mov rdi, [rdi-16] ;y
    call rotAB
    ret
