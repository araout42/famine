section .text

global _start

_start:
						add rax, 150
						push rax
						pop rax
		dd 0x90909090
						mov rax, 0xFF
		dd 0x90909090
						sub rax, r11
		dd 0x90909090
						xor rax, rcx
		dd 0x90909090


		dd 0x90909090



		dd 0x90909090

		dd 0x90909090

