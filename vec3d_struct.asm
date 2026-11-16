section .text
extern fix64_construct
extern fix64_constructSal
extern fix64_clone
extern fix64_add
extern fix64_sub
extern fix64_mul

;3d vector struct (method args follow syscall convention)

;type vec3d struct
;    x *fix64 [*vec3d-8]
;    y *fix64 [*vec3d-16]
;    z *fix64 [*vec3d-24]

;constructs vec3d obj, returns pointer to obj
global vec3d_construct ;*vec3d (*fix64, *fix64, *fix64)
vec3d_construct:
    pop rbx

    mov rax, rsp ;storing pointer in rax for return
    ;init x, y, z fields
    push rdi ;x
    push rsi ;y
    push rdx ;z

    push rbx
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

;rotates (a, b) rot about (abtA, abtB) via small-angle approximation: (a-abtA)-((b-abtB)*rot)+abtA, (b-abtB)+((a-abtA)*rot)+abtB
rotAB: ;void (a *fix64, b *fix64, abtA *fix64, abtB *fix64, rot *fix64)
    enter 0, 0

    mov r11, rdi ;a = r11
    mov r12, rsi ;b = r12
    mov r9, rdx ;abtA = r9
    ;abtB = r10
    ;rot = r8

    ;a -= abtA
    mov rdi, r11
    mov rsi, r9
    call fix64_sub
    ;b -= abtB
    mov rdi, r12
    mov rsi, r10
    call fix64_sub

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
    mov rsi, r8
    call fix64_mul
    mov rdi, r11
    mov rsi, r14
    call fix64_sub
    ;b += cloneA*rot
    mov rdi, r13
    mov rsi, r8
    call fix64_mul
    mov rdi, r12
    mov rsi, r13
    call fix64_add

    ;a += abtA
    mov rdi, r11
    mov rsi, r9
    call fix64_add
    ;b += abtB
    mov rdi, r12
    mov rsi, r10
    call fix64_add

    leave
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

;rotates z, x fields by rot about (abtZ, abtX)
global vec3d_rotZX ;void (*vec3d, abt *vec3d, rot *fix64)
vec3d_rotZX:
    mov r8, rdx ;rot
    mov r10, [rsi-8] ;abtX
    mov rdx, [rsi-24] ;abtZ
    mov rsi, [rdi-8] ;x
    mov rdi, [rdi-24] ;z
    call rotAB
    ret
