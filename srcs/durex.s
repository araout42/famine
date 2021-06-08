%include "includes/header.s"



SECTION .TEXT EXEC WRITE

global _start

_start:

mov rdi, cmd
mov rsi, argv
mov rdx, env
mov rax, 59
syscall

mov rax, 60
syscall

cmd db "/bin/bash", 0
arg1 db "-c", 0
arg2 db "ls", 0
argv times 25 db 0
env db 0
