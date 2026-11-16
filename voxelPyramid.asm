section .bss
    ;pyramid tip
    pyrX: equ 50
    pyrY: equ 37
    pyrZ: equ 50
    ;size
    layers: equ 26

    ;about
    abtX: equ 50
    abtY: equ 50
    abtZ: equ 50
    abt: resq 1 ;*vec3d

    ;rotation angles (radians)
    XYRotValue: equ -65
    YZRotValue: equ 65
    ZXRotValue: equ 196
    XYrot: resq 1 ;*fix64
    YZrot: resq 1 ;*fix64
    ZXrot: resq 1 ;*fix64

    ;voxel array
    maxVoxels: equ 10000
    dqMaxVoxels: equ maxVoxels*8 ;quad-word max voxel count (voxelArr size in bytes)
    voxelArr: resq maxVoxels ;*vec3d arr
    dqVoxelArrLen: resq 1

section .text
extern fix64_construct
extern fix64_constructSal
extern vec3d_construct
extern vec3d_rotXY
extern vec3d_rotYZ
extern vec3d_rotZX
extern loadVoxelIntoWin

;func args follow syscall convention

;inits about vec3d from abtX, abtY, abtZ
global initPyramidAbt
initPyramidAbt:
    pop r15

    ;z *fix64
    mov rdi, abtZ
    call fix64_constructSal
    mov rdx, rax
    ;y *fix64
    mov rdi, abtY
    call fix64_constructSal
    mov rsi, rax
    ;x *fix64
    mov rdi, abtX
    call fix64_constructSal
    mov rdi, rax
    ;abt *vec3d
    call vec3d_construct
    mov [abt], rax

    push r15
    ret

;inits fix64 rotations from XYRotValue, YZRotValue, ZXRotValue
global initPyramidRot
initPyramidRot:
    pop r15

    ;xy
    mov rdi, XYRotValue
    call fix64_construct
    mov [XYrot], rax
    ;yz
    mov rdi, YZRotValue
    call fix64_construct
    mov [YZrot], rax
    ;zx
    mov rdi, ZXRotValue
    call fix64_construct
    mov [ZXrot], rax

    push r15
    ret

;generates vec3ds forming hollow pyramid, loads into voxelArr
global genPyramid
genPyramid:
    pop r15

    xor rcx, rcx ;voxelArr i
    mov r8, 1 ;layerSize (n: n x n layer)
    xor r9, r9 ;y
    iterGenPyramidY:
        xor r10, r10 ;x
        iterGenPyramidX:
            xor r11, r11 ;z
            iterGenPyramidZ:
                ;if (y == 0 || y == layers-1 || x == 0 || x == layerSize-1 || z == 0 || z == layerSize-1): genVoxel
                cmp r9, 0 ;y == 0
                je genVoxel
                cmp r9, layers-1 ;y == layers-1
                je genVoxel
                cmp r10, 0 ;x == 0
                je genVoxel
                mov rdx, r8
                sub rdx, 1 ;layerSize-1
                cmp r10, rdx ;x == layerSize-1
                je genVoxel
                cmp r11, 0 ;z == 0
                je genVoxel
                cmp r11, rdx ;z == layerSize-1
                je genVoxel
                jmp contIterGenPyramidZ
                genVoxel:
                    ;*fix64 z+pyrZ-y
                    lea rdi, [r11+pyrZ]
                    sub rdi, r9
                    call fix64_constructSal
                    mov rdx, rax
                    ;*fix64 y+pyrY
                    lea rdi, [r9+pyrY]
                    call fix64_constructSal
                    mov rsi, rax
                    ;*fix64 x+pyrX-y
                    lea rdi, [r10+pyrX]
                    sub rdi, r9
                    call fix64_constructSal
                    mov rdi, rax
                    ;construct vec3d
                    call vec3d_construct
                    mov [voxelArr+rcx], rax ;voxelArr[i] = *vec3d
                    add qword [dqVoxelArrLen], qword 8 ;inc dqVoxelArrLen
                    ;inc voxelArr i
                    add rcx, 8
                    cmp rcx, dqMaxVoxels ;checking if at voxelArr end
                    jge leaveGenPyramid
            contIterGenPyramidZ: ;inc z
                add r11, 1
                cmp r11, r8
                jl iterGenPyramidZ
        contIterGenPyramidX: ;inc x
            add r10, 1
            cmp r10, r8
            jl iterGenPyramidX
    contIterGenPyramidY: ;inc layerSize, y
        add r8, 2
        add r9, 1
        cmp r9, layers
        jl iterGenPyramidY
leaveGenPyramid:
    push r15
    ret

;rotates vec3ds in voxelArr by rot about abt
global rotVoxels
rotVoxels:
    xor rcx, rcx ;voxelArr i
    iterRotVoxels:
        ;rot xy
        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [XYrot]
        call vec3d_rotXY
        ;rot yz
        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [YZrot]
        call vec3d_rotYZ
        ;rot zx
        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [ZXrot]
        call vec3d_rotZX
        ;inc voxelArr i
        add rcx, 8
        cmp rcx, [dqVoxelArrLen]
        jl iterRotVoxels
        ret

;loads vec3ds in voxelArr into window
global loadVoxelArrIntoWin
loadVoxelArrIntoWin:
    xor rcx, rcx ;voxelArr i
    iterRenderVoxels:
        mov rdi, [voxelArr+rcx]
        call loadVoxelIntoWin
        ;inc voxelArr i
        add rcx, 8
        cmp rcx, [dqVoxelArrLen]
        jl iterRenderVoxels
        ret
