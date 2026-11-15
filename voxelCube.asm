section .bss
    ;back-left vert
    cubeX: equ 34
    cubeY: equ 34
    cubeZ: equ 34
    ;size
    faceSize: equ 32

    ;about
    abtX: equ 50
    abtY: equ 50
    abtZ: equ 50
    abt: resq 1 ;*vec3d

    ;rotation angles (radians)
    XYRotValue: equ 131
    YZRotValue: equ 131
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
global initCubeAbt
initCubeAbt:
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
global initCubeRot
initCubeRot:
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

;generates vec3ds forming hollow cube, loads into voxelArr
global genCube
genCube:
    pop r15

    xor rcx, rcx ;voxelArr i
    xor r8, r8 ;x
    iterGenCubeX:
        xor r9, r9 ;y
        iterGenCubeY:
            xor r10, r10 ;z
            iterGenCubeZ:
                ;if (x == 0 || x == faceSize-1 || y == 0 || y == faceSize-1 || z == 0 || z == faceSize-1): genVoxel
                cmp r8, 0 ;x == 0
                je genVoxel
                cmp r8, faceSize-1 ;x == faceSize-1
                je genVoxel
                cmp r9, 0 ;y == 0
                je genVoxel
                cmp r9, faceSize-1 ;y == faceSize-1
                je genVoxel
                cmp r10, 0 ;z == 0
                je genVoxel
                cmp r10, faceSize-1 ;z == faceSize-1
                je genVoxel
                jmp contIterGenCubeZ
                genVoxel:
                    ;*fix64 z+cubeZ
                    lea rdi, [r10+cubeZ]
                    call fix64_constructSal
                    mov rdx, rax
                    ;*fix64 y+cubeY
                    lea rdi, [r9+cubeY]
                    call fix64_constructSal
                    mov rsi, rax
                    ;*fix64 x+cubeX
                    lea rdi, [r8+cubeX]
                    call fix64_constructSal
                    mov rdi, rax
                    ;construct vec3d
                    call vec3d_construct
                    mov [voxelArr+rcx], rax ;voxelArr[i] = *vec3d
                    add qword [dqVoxelArrLen], qword 8 ;inc dqVoxelArrLen
                    ;inc voxelArr i
                    add rcx, 8
                    cmp rcx, dqMaxVoxels ;checking if at voxelArr end
                    jge leaveGenCube
            contIterGenCubeZ: ;inc z
                add r10, 1
                cmp r10, faceSize
                jl iterGenCubeZ
        contIterGenCubeY: ;inc y
            add r9, 1
            cmp r9, faceSize
            jl iterGenCubeY
    contIterGenCubeX: ;inc x
        add r8, 1
        cmp r8, faceSize
        jl iterGenCubeX
leaveGenCube:
    push r15
    ret

;rotates vec3ds in voxelArr by rot about abt
global rotVoxels
rotVoxels:
    xor rcx, rcx ;voxelArr i
    iterRotVoxels:
        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [XYrot]
        call vec3d_rotXY

        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [YZrot]
        call vec3d_rotYZ

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
