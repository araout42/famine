section     .text
global      _start                              ;must be declared for linker (ld)

_start:                                         ;tell linker entry point
	mov rax, 0x1
	mov rdi, 0x1
	lea rsi, [rel msg]
	mov rdx, len
	syscall
	jmp 0x1050

msg     db  '....WOODY....',0xa                 ;our dear string
len     equ $ - msg                             ;length of our dear string
