global _start

_start:
int3
push 0
pop r10

and r10, 0


sub r10, r10


xor r10, r10

mov r10d, 0





mov rax, 60
mov rdi, 0x0
syscall

