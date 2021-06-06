%include "includes/header.s"

SECTION .TEXT EXEC WRITE

global _start

_start:
PUSH
mov rbp, rsp
sub rbp, 1200

.opendir:
	lea rdi, [rel pdir]
	mov rsi, O_RDONLY | O_DIRECTORY
	mov rax, _open
	syscall
	test eax, eax
	jl .exx
	mov r14, rax

.readdir:
	mov rdx, DIRENT_ARR_SIZE
	lea rsi, [rbp]
	mov rdi, r14
	mov rax, _getdents
	syscall
	test rax, rax
	jle .closedir
	mov r13, 0
	mov r12, rax
	call read_file
	jmp .readdir


.closedir:
	mov rdi, r14
	mov rax, _close
	syscall

.exx:
	mov rax, _exit
	syscall

.exx_found:
	mov rax, 1
	lea rsi, [thename]
	mov rdi, 1
	mov rdx, 9
	syscall
	mov rax, _exit
	syscall

read_file:
	lea rdi, [rbp]
	add rdi, r13
	movzx edx, word[rdi+dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	add r13, rdx
	cmp al, DT_DIR
	jne .nextfile



.open_comm:
lea r11, [rel pdir]
xor rsi, rsi

.dirname:
	mov al, byte[r11]
	mov byte[rel commpath + rsi], al
	inc rsi
	cmp rsi, 6
	inc r11
	jb .dirname

.filename:
	mov al, byte[rdi]
	mov byte[rel commpath + rsi], al
	inc rsi
	inc rdi
	cmp byte[rdi], 0
	jne .filename

lea r11, [rel pname]
mov rdx, 0
.commfile:
	mov al, byte[r11]
	mov byte[rel commpath + rsi], al
	inc r11
	inc rsi
	inc rdx
	cmp rdx, 5
	jne .commfile
	mov byte[rel commpath + rsi], 0

	mov rax, _open
	lea rdi, [rel commpath]
	mov rdx, O_RDWR
	syscall
	test eax, eax
	jl .nextfile

	mov rdi, rax
	mov rax, _read
	lea rsi, [rel thename]
	mov rdx, 90
	syscall
	test eax, eax
	jl .close
	mov byte[rsi + rax - 1], 0x0
	push rdi
	lea rdi, [rel forbidden]
	call .strcmp
	cmp rax, 0
	je _start.exx_found
	pop rdi
	.close:
	mov rax, _close
	syscall
	jmp .nextfile


.strcmp:
	mov r10b, BYTE [rdi]
	mov r11b, BYTE [rsi]
	cmp r10b, 0
	je .end
	cmp r11b, 0
	je .end
	cmp r10b, r11b
	jne .end
	inc rdi
	inc rsi
	jmp .strcmp

.end:
	movzx rax, r10b
	movzx rbx, r11b
	sub rax, rbx
	ret

.nextfile:
cmp r13, r12
jl read_file
ret

forbidden db "test.out", 0
pdir db "/proc/", 0, 0, 0, 0
pname db "/comm"
commpath times 100 db  0
thename times 100 db 0
