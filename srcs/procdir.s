%include "includes/header.s"

SECTION .TEXT EXEC WRITE

global _start

_start:
PUSH
mov rbp, rsp
sub rbp, 5000

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


read_file:
	lea rdi, [rbp]
	add rdi, r13
	movzx edx, word[rdi+dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	call .open_comm
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
	cmp byte[r11], 0
	inc r11
	jnz .dirname

.filename:
	mov al, byte [rdi]
	mov byte[rsi], al
	inc rsi
	inc rdi
	cmp byte[rdi], 0
	jnz .filename

.nextfile:
cmp r13, r12
jl read_file
ret

pdir db "/proc/", 0, 0
pname db "/comm"
commpath	db 0 dup(100)
