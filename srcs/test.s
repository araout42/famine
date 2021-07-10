section .text

global _start

_start:
		dd 0x90909090

		dd 0x90909090

		dd 0x90909090

		push 0
		pop rdi
		dd 0x90909090

		and rdi, 0

		dd 0x90909090


		sub rdi, rdi

		dd 0x90909090
		xor rdi, rdi

		dd 0x90909090

		mov rdi, 0
