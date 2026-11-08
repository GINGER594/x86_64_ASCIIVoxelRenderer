section .data
    ;back-left vert
    cubeX: equ 34
    cubeY: equ 34
    cubeZ: equ 34
    ;size
    faceSize: equ 32 ;n: n x n face
    faceSizeSub1: equ faceSize-1 ;used for hollow cube gen

    ;rotate about
    abtX: equ 50
    abtY: equ 50
    abtZ: equ 50
    ;rotate angle (radians)
    rotVal: equ 131 ;2^16*0.002

    maxVoxels: equ 10000
    dqMaxVoxels: equ maxVoxels*8 ;quad-word vec3d count (voxelArr size in bytes)

section .bss
    vsrr: resq 1;voxelCube synthetic return register

    voxelArr: resq maxVoxels ;*vec3d arr
    dqVoxelCount: resq 1

    abt: resq 1 ;*vec3d point to rotate cube about
    rot: resq 1 ;*fix64 radian rotation

section .text
extern fix64_construct
extern fix64_constructSal
extern vec3d_construct
extern vec3d_rotXY
extern vec3d_rotXZ
extern vec3d_rotYZ
extern loadVoxelIntoWin

;func args follow syscall convention

;inits about vec3d from abtX, abtY, abtZ, stores in abt
global initAbt
initAbt:
    pop qword [vsrr]

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

    push qword [vsrr]
    ret

;inits fix64 rotation (in radians) from rotVal, stores in rot
global initRot
initRot:
    pop qword [vsrr]

    mov rdi, rotVal
    call fix64_construct
    mov [rot], rax

    push qword [vsrr]
    ret

;generates vec3ds forming hollow cube, loads into voxelArr
global genCube
genCube:
    pop qword [vsrr]

    xor rcx, rcx ;voxelArr i
    xor r11, r11 ;x
    iterGenCubeX:
        xor r12, r12 ;y
        iterGenCubeY:
            xor r13, r13 ;z
            iterGenCubeZ:
                ;if (x == 0 || x == faceSizeSub1 || y == 0 || y == faceSizeSub1 || z == 0 || z == faceSizeSub1): genVoxel
                cmp r11, 0 ;x == 0
                je genVoxel
                cmp r11, faceSizeSub1 ;x == faceSizeSub1
                je genVoxel
                cmp r12, 0 ;y == 0
                je genVoxel
                cmp r12, faceSizeSub1 ;y == faceSizeSub1
                je genVoxel
                cmp r13, 0 ;z == 0
                je genVoxel
                cmp r13, faceSizeSub1 ;z == faceSizeSub1
                je genVoxel
                jmp cont_iterGenCubeZ
                genVoxel:
                    ;*fix64 z+cubeZ
                    mov rdi, r13
                    add rdi, cubeZ
                    call fix64_constructSal
                    mov rdx, rax
                    ;*fix64 y+cubeY
                    mov rdi, r12
                    add rdi, cubeY
                    call fix64_constructSal
                    mov rsi, rax
                    ;*fix64 x+cubeX
                    mov rdi, r11
                    add rdi, cubeX
                    call fix64_constructSal
                    mov rdi, rax
                    ;construct vec3d
                    call vec3d_construct
                    mov [voxelArr+rcx], rax ;loading *vec3d into voxelArr
                    ;inc voxelCount
                    add qword [dqVoxelCount], qword 8
                    ;inc voxelArr i
                    add rcx, 8
                    cmp rcx, dqMaxVoxels ;checking if at voxelArr end
                    jge end_genCube
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
end_genCube:
    push qword [vsrr]
    ret

;rotates vec3ds in voxelArr by rot about abt
global rotVoxels
rotVoxels:
    xor rcx, rcx ;voxelArr i
    iterRotVoxels:
        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call vec3d_rotXY

        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call vec3d_rotXZ

        mov rdi, [voxelArr+rcx]
        mov rsi, [abt]
        mov rdx, [rot]
        call vec3d_rotYZ

        ;inc voxelArr i
        add rcx, 8
        cmp rcx, [dqVoxelCount]
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
        cmp rcx, [dqVoxelCount]
        jl iterRenderVoxels
        ret
