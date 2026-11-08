section .data
    escC: db 27, 99, 0

    sleepSec: dq 0
    sleepNano: dq 800000

section .text
extern initAbt
extern initRot
extern genCube
extern rotVoxels
extern loadVoxelArrIntoWin
extern zeroWin
extern outWin

clearTerminal:
    mov rax, 1
    mov rdi, 1
    mov rsi, escC
    mov rdx, 2
    syscall
    ret

sleep:
    mov rax, 35
    mov rdi, sleepSec
    mov rsi, sleepNano
    syscall
    ret

global _start
_start:
    call initAbt
    call initRot
    call genCube
    call loadVoxelArrIntoWin

    ;main loop
    run:
        call clearTerminal
        call outWin

        call rotVoxels
        call zeroWin
        call loadVoxelArrIntoWin

        call sleep
        jmp run

    mov rax, 60
    xor rdi, rdi
    syscall
