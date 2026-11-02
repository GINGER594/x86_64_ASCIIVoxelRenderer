section .bss
    vsrr: resq 1 ;voxel synthetic return register
    vsspr: resq 1 ;voxel synthetic stack pointer register

    ;voxel aboutA, voxel aboutB, voxel rotation - used in rotAB
    vAbtA: resq 1
    vAbtB: resq 1
    vRot: resq 1

section .text
extern fix64_construct
extern fix64_constructSal
extern fix64_getVal
extern fix64_neg
extern fix64_add
extern fix64_mul

;3d voxel class (method args follow syscall convention)

;class voxel
;
;*fix64 x, accessed via [*voxel-8]
;*fix64 y, accessed via [*voxel-16]
;*fix64 z, accessed via [*voxel-24]
;
;public *voxel voxel_construct(*fix64, *fix64, *fix64)
;
;public *fix64 voxel_getX(*voxel)
;public *fix64 voxel_getY(*voxel)
;public *fix64 voxel_getZ(*voxel)
;
;private void rotAB(*fix64 a, *fix64 b, *fix64 abtA, *fix64 abtB, *fix64 rot)
;public void voxel_rotXY(*voxel, *voxel abt, *fix64 rot)
;public void voxel_rotXZ(*voxel, *voxel abt, *fix64 rot)
;public void voxel_rotYZ(*voxel, *voxel abt, *fix64 rot)

;constructs voxel obj, returns pointer to obj
global voxel_construct
voxel_construct:
    pop qword [vsrr]

    mov rax, rsp ;storing pointer in rax for return
    ;init fields
    sub rsp, 24
    mov [rsp+16], rdi ;x
    mov [rsp+8], rsi ;y
    mov [rsp], rdx ;z

    push qword [vsrr]
    ret

global voxel_getX
voxel_getX:
    mov rax, [rdi-8]
    ret

global voxel_getY
voxel_getY:
    mov rax, [rdi-16]
    ret

global voxel_getZ
voxel_getZ:
    mov rax, [rdi-24]
    ret

;rotates (a, b) rot about (abtA, abtB) using small-angle approximations: (a-abtA)-((b-abtB)*rot)+abtA, (b-abtB)+((a-abtA)*rot)+abtB
rotAB:
    mov [vsspr], rsp ;storing stack pointer

    mov r11, rdi ;a = r11
    mov r12, rsi ;b = r12
    mov [vAbtA], rdx
    mov [vAbtB], r10
    mov [vRot], r8

    ;a -= abtA
    mov rdi, [vAbtA]
    call fix64_neg ;abtA *= -1
    mov rdi, r11
    mov rsi, [vAbtA]
    call fix64_add ;a += abtA
    mov rdi, [vAbtA]
    call fix64_neg ;abtA *= -1
    ;b -= abtB
    mov rdi, [vAbtB]
    call fix64_neg ;abtB *= -1
    mov rdi, r12
    mov rsi, [vAbtB]
    call fix64_add ;b += abtB
    mov rdi, [vAbtB]
    call fix64_neg ;abtB *= -1

    ;r13 = cloneA
    mov rdi, r11
    call fix64_getVal
    mov rdi, rax
    call fix64_construct
    mov r13, rax
    ;r14 = cloneB
    mov rdi, r12
    call fix64_getVal
    mov rdi, rax
    call fix64_construct
    mov r14, rax

    ;a -= cloneB*rot
    mov rdi, r14
    call fix64_neg ;cloneB *= -1
    mov rdi, r14
    mov rsi, [vRot]
    call fix64_mul ;cloneB *= rot
    mov rdi, r11
    mov rsi, r14
    call fix64_add ;a += cloneB
    ;b += cloneA*rot
    mov rdi, r13
    mov rsi, [vRot]
    call fix64_mul ;cloneA *= rot
    mov rdi, r12
    mov rsi, r13
    call fix64_add ;b += cloneA

    ;a += abtA
    mov rdi, r11
    mov rsi, [vAbtA]
    call fix64_add
    ;b += abtB
    mov rdi, r12
    mov rsi, [vAbtB]
    call fix64_add

    mov rsp, [vsspr] ;restoring stack pointer (freeing space used by cloneA, cloneB objects)
    ret

;rotates x, y fields by rot about (abtX, abtZ)
global voxel_rotXY
voxel_rotXY:
    mov r8, rdx ;rot
    mov r10, [rsi-16] ;abtY
    mov rdx, [rsi-8] ;abtX
    mov rsi, [rdi-16] ;y
    mov rdi, [rdi-8] ;x
    call rotAB
    ret

;rotates x, z fields by rot about (abtX, abtZ)
global voxel_rotXZ
voxel_rotXZ:
    mov r8, rdx ;rot
    mov r10, [rsi-24] ;abtZ
    mov rdx, [rsi-8] ;abtX
    mov rsi, [rdi-24] ;z
    mov rdi, [rdi-8] ;x
    call rotAB
    ret

;rotates y, z fields by rot about (abtY, abtZ)
global voxel_rotYZ
voxel_rotYZ:
    mov r8, rdx ;rot
    mov r10, [rsi-16] ;abtY
    mov rdx, [rsi-24] ;abtZ
    mov rsi, [rdi-16] ;y
    mov rdi, [rdi-24] ;x
    call rotAB
    ret
