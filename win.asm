section .data
    rowLen: equ 100 ;dimensions for n x n display window
    winLen: equ rowLen*rowLen
    dqRowLen: equ rowLen*8 ;quad-word row len
    dqWinLen: equ winLen*8 ;quad-word win len
    outBuffLen: equ (winLen*2)+rowLen ;*2 for spaces between values, +1 for \n at the end of each row

    zDiv: dq 6 ;arbitrary value to divide z by in outWin for increased contrast
    zMap: db " .,-~:;*=%$&#", 0
    zMapEnd: equ $-zMap-2

section .bss
    win: resq winLen ;2d int arr
    outBuff: resb outBuffLen ;byte arr output buffer

section .text
extern fix64_getInt
extern vec3d_getX
extern vec3d_getY
extern vec3d_getZ

;func args follow syscall convention

;loads vec3d (from voxelArr) into win arr
global loadVoxelIntoWin ;void (*vec3d)
loadVoxelIntoWin:
    ;x *fix64 (r11)
    call vec3d_getX
    mov r11, rax
    ;y *fix64 (r12)
    call vec3d_getY
    mov r12, rax
    ;z *fix64 (r13)
    call vec3d_getZ
    mov r13, rax

    ;x (r11)
    mov rdi, r11
    call fix64_getInt
    cmp rax, 0 ;exiting func if x < 0
    jl end_winLoadVoxel
    cmp rax, rowLen ;exiting func if x >= rowLen
    jge end_winLoadVoxel
    mov rbx, 8
    imul rbx ;x *= 8 (quad-word size)
    mov r11, rax

    ;y (r12)
    mov rdi, r12
    call fix64_getInt
    cmp rax, 0 ;exiting func if y < 0
    jl end_winLoadVoxel
    cmp rax, rowLen ;exiting func if y >= rowLen
    jge end_winLoadVoxel
    mov rbx, dqRowLen
    imul rbx ;y *= dqRowLen
    mov r12, rax

    ;z (r12)
    mov rdi, r13
    call fix64_getInt
    mov r13, rax

    ;only replacing win[y][x] if z > win[y][x]
    cmp r13, [win+r12+r11]
    jle end_winLoadVoxel
    mov [win+r12+r11], r13
end_winLoadVoxel:
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
end_zeroWin:
    ret

;loads win arr (mapped to zMap) into output buffer (with spaces and \n's), outputs
global outWin
outWin:
    xor r12, r12 ;win y
    xor rcx, rcx ;outBuff i
    iterOutWinY:
        xor r11, r11 ;win x
        iterOutWinX:
            mov rax, [win+r12+r11] ;win[y][x]
            ;div z by arbitrary value for contrast
            cqo
            idiv qword [zDiv]
            ;clamp z >= 0
            xor rbx, rbx
            cmp rax, rbx
            cmovl rax, rbx
            ;clamp z <= len(zMap)-2
            mov rbx, zMapEnd
            cmp rax, zMapEnd
            cmovg rax, rbx
            ;mapping z to zMap, inserting into output buffer
            mov rbx, [zMap+rax] ;zMap[win[y][x]]
            mov [outBuff+rcx], rbx
            ;adding space for padding
            mov rbx, 32
            mov [outBuff+rcx+1], rbx ;adding space for padding
            ;inc outBuff i, win x
            add rcx, 2 ;+2 for vec3d + space
            add r11, 8
            cmp r11, dqRowLen
            jl iterOutWinX
    cont_iterOutWinY: ;adding \n to row end, inc outBuff i, win y
        mov rbx, 10
        mov [outBuff+rcx], rbx
        add rcx, 1
        ;inc y
        add r12, dqRowLen
        cmp r12, dqWinLen
        jl iterOutWinY
    ;print output buffer
    mov rax, 1
    mov rdi, 1
    mov rsi, outBuff
    mov rdx, outBuffLen
    syscall
    ret
