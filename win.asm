section .data
    zDiv: dq 7 ;arbitrary value to divide z by in outWin for increased contrast
    zMap: db " .,-~:;*=%$&#", 0
    zMapLen: equ $-zMap

section .bss
    rowLen: equ 100 ;dimensions for n x n display window
    winLen: equ rowLen*rowLen
    dqRowLen: equ rowLen*8 ;quad-word row len
    dqWinLen: equ winLen*8 ;quad-word win len
    win: resq winLen ;2d int arr

    outBuffLen: equ (winLen*2)+rowLen ;*2 for spaces between values, +1 for \n at the end of each row
    outBuff: resb outBuffLen ;byte arr output buffer

section .text
extern fix64_Int
extern vec3d_getX
extern vec3d_getY
extern vec3d_getZ

;func args follow syscall convention

;loads vec3d into win arr
global loadVoxelIntoWin ;void (*vec3d)
loadVoxelIntoWin:
    ;x *fix64
    call vec3d_getX
    mov r8, rax
    ;y *fix64
    call vec3d_getY
    mov r9, rax
    ;z *fix64
    call vec3d_getZ
    mov r10, rax

    ;x*8 int
    mov rdi, r8
    call fix64_Int
    cmp rax, 0 ;leaving if x < 0
    jl leaveLoadVoxelIntoWin
    cmp rax, rowLen ;leaving if x >= rowLen
    jge leaveLoadVoxelIntoWin
    lea r8, [rax*8]
    ;y*dqRowLen int
    mov rdi, r9
    call fix64_Int
    cmp rax, 0 ;leaving if y < 0
    jl leaveLoadVoxelIntoWin
    cmp rax, rowLen ;leaving if y >= rowLen
    jge leaveLoadVoxelIntoWin
    mov rdx, dqRowLen
    imul rdx
    mov r9, rax
    ;z int
    mov rdi, r10
    call fix64_Int
    mov r10, rax

    ;replacing win[y][x] if z > win[y][x]
    cmp r10, [win+r9+r8]
    jle leaveLoadVoxelIntoWin
    mov [win+r9+r8], r10
leaveLoadVoxelIntoWin:
    ret

;zeros win arr
global zeroWin
zeroWin:
    xor rcx, rcx
    iterZeroWin:
        mov qword [win+rcx], qword 0
        add rcx, 8
        cmp rcx, dqWinLen
        jl iterZeroWin
    ret

;loads win arr (mapped to zMap) into output buffer, outputs
global outWin
outWin:
    xor rcx, rcx ;outBuff i
    xor r9, r9 ;win y
    iterOutWinY:
        xor r8, r8 ;win x
        iterOutWinX:
            mov rax, [win+r9+r8] ;win[y][x]
            ;z /= zDiv (increasing contrast)
            cqo
            idiv qword [zDiv]
            ;clamp(z, 0, len(zMap-2))
            xor rdx, rdx
            cmp rax, rdx
            cmovl rax, rdx
            lea rdx, [zMapLen-2]
            cmp rax, rdx
            cmovg rax, rdx
            ;outBuff[i] = zMap[win[y][x]]
            mov rdx, [zMap+rax]
            mov [outBuff+rcx], rdx
            ;outBuff[i+1] = " "
            mov rdx, 32
            mov [outBuff+rcx+1], rdx
            add rcx, 2 ;inc outBuff i, +2 for vec3d + space
            ;inc x
            add r8, 8
            cmp r8, dqRowLen
            jl iterOutWinX
        ;outBuff[i] = "\n", inc outBuff i
        mov rdx, 10
        mov [outBuff+rcx], rdx
        add rcx, 1
        ;inc y
        add r9, dqRowLen
        cmp r9, dqWinLen
        jl iterOutWinY
    ;out output buffer
    mov rax, 1
    mov rdi, 1
    mov rsi, outBuff
    mov rdx, outBuffLen
    syscall
    ret
