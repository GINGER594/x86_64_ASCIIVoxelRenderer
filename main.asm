section .data
    escC: db 27, 99, 0

    sleepSec: dq 0
    sleepNano: dq 1200000

section .text
extern constructAbt
extern constructRot
extern genCube
extern loadCubeWin
extern rotCube
extern outWin
extern zeroWin

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
    call constructAbt
    call constructRot
    call genCube
    call loadCubeWin

    ;main loop
    run:
        call sleep
        call clearTerminal

        call outWin
        call zeroWin

        call rotCube
        call loadCubeWin
        jmp run

    mov rax, 60
    xor rdi, rdi
    syscall
