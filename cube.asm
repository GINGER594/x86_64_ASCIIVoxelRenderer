section .data
    ;back-left vert
    cubeX: equ 24
    cubeY: equ 24
    cubeZ: equ 24

    ;size
    faceSize: equ 32
    fsm1: equ faceSize-1 ;faceSize minus 1: used for hollow cube gen
    voxelCount: equ (faceSize*faceSize*faceSize)-((fsm1-1)*(fsm1-1)*(fsm1-1)) ;voxel count (hollow cube) = (faceSize^3)-((faceSize-2)^3)
    dqVoxelCount: equ voxelCount*8 ;voxel count * quad-word size

    ;rotate about
    abtX: equ 40
    abtY: equ 40
    abtZ: equ 40
    ;rotate angle
    rotRad: equ 196 ;(2^16)*0.003

section .bss
    csrr: resq 1 ;cube synthetic return register

    cubeArr: resq voxelCount

    abt: resq 1 ;*voxel point to rotate cube about
    rot: resq 1 ;*fix64 radian rotation

section .text
extern fix64_construct
extern fix64_constructSal
extern voxel_construct
extern voxel_rotXY
extern voxel_rotXZ
extern voxel_rotYZ
extern loadVoxelWin

;func args follow syscall convention

;constructs about voxel from abtX, abtY, abtZ, stores in abt
global constructAbt ;void ()
constructAbt:
    pop qword [csrr]

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
    ;abt *voxel
    call voxel_construct
    mov [abt], rax

    push qword [csrr]
    ret

;constructs fix64 rotation in radians from rotRad, stores in rot
global constructRot ;void ()
constructRot:
    pop qword [csrr]

    mov rdi, rotRad
    call fix64_construct
    mov [rot], rax

    push qword [csrr]
    ret

;generates voxels forming hollow cube, loads into cubeArr
global genCube ;void ()
genCube:
    pop qword [csrr]

    xor rcx, rcx ;cube i
    xor r11, r11 ;x
    iterGenCubeX:
        xor r12, r12 ;y
        iterGenCubeY:
            xor r13, r13 ;z
            iterGenCubeZ:
                ;if (x == 0 || x == fsm1 || y == 0 || y == fsm1 || z == 0 || z == fsm1): genVoxel
                cmp r11, 0 ;x == 0
                je genVoxel
                cmp r11, fsm1 ;x == fsm1
                je genVoxel
                cmp r12, 0 ;y == 0
                je genVoxel
                cmp r12, fsm1 ;y == fsm1
                je genVoxel
                cmp r13, 0 ;z == 0
                je genVoxel
                cmp r13, fsm1 ;z == fsm1
                je genVoxel
                jmp cont_iterGenCubeZ
                genVoxel:
                    ;z *fix64
                    mov rdi, r13
                    add rdi, cubeZ ;z += cubeZ
                    call fix64_constructSal
                    mov rdx, rax
                    ;y *fix64
                    mov rdi, r12
                    add rdi, cubeY ;y += cubeY
                    call fix64_constructSal
                    mov rsi, rax
                    ;x *fix64
                    mov rdi, r11
                    add rdi, cubeX ;x += cubeX
                    call fix64_constructSal
                    mov rdi, rax
                    ;construct voxel
                    call voxel_construct
                    mov [cubeArr+rcx], rax ;loading *voxel into cubeArr
                    ;inc cube i
                    add rcx, 8
            cont_iterGenCubeZ: ;inc z
                add r13, 1
                cmp r13, faceSize
                jl iterGenCubeZ
        cont_iterGenCubeY: ;inc y
            add r12, 1
            cmp r12, faceSize
            jl iterGenCubeY
    cont_iterGenCubeX: ;inc x
        add r11, 1
        cmp r11, faceSize
        jl iterGenCubeX

        push qword [csrr]
        ret

;loads voxels in cubeArr into window
global loadCubeWin ;void ()
loadCubeWin:
    xor rcx, rcx ;cube i
    iterLoadCube:
        mov rdi, [cubeArr+rcx]
        call loadVoxelWin
        ;inc cube i
        add rcx, 8
        cmp rcx, dqVoxelCount
        jl iterLoadCube
        ret

;rotates voxels in cubeArr by rot about abt
global rotCube ;void ()
rotCube:
    xor rcx, rcx ;cube i
    iterRotCube:
        mov rdi, [cubeArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call voxel_rotXY

        mov rdi, [cubeArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call voxel_rotXZ

        mov rdi, [cubeArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call voxel_rotYZ

        ;inc cube i
        add rcx, 8
        cmp rcx, dqVoxelCount
        jl iterRotCube
        ret
