; See LICENSE file for copyright and license details.

%ifndef MACROS_S
%define MACROS_S

%define EXIT_SUCCESS	0
%define EXIT_FAILURE	1
%define STDOUT		1
%define STDERR		2
%define ROUND_UP	10B ;toward +inf
%define ROUND_DOWN	01B ;toward -inf
%define MAX_ARGC	2

section .rodata
	usage_msg:	db "usage: azan-nasm [-nuv]", 10, 0
	usage_len:	equ $ - usage_msg
	version_msg:	db "azan-nasm-", VERSION, 10, 0
	version_len:	equ $ - version_msg

section .data
	res_msg:	db "X XX:XX", 10, 0
	res_len:	equ $ - res_msg

%macro CHECK_OPENBSD 0
%ifdef OpenBSD
section .note.openbsd.ident note
	dd 8, 4, 1
	db "OpenBSD", 0
	dd 0
%endif
%endmacro

%macro EEXIT 1
	mov rax, SYS_exit
	mov rdi, %1
	syscall
%endmacro

%macro DIE 2
	mov rax, SYS_write
	mov rdi, STDERR
	mov rsi, %1
	mov rdx, %2
	syscall
	EEXIT EXIT_FAILURE
%endmacro

%macro PRINT_EXIT 0
	SET_MSG
	mov rax, SYS_write
	mov rdi, STDOUT
	mov rsi, res_msg
	mov rdx, res_len
	syscall
	EEXIT EXIT_SUCCESS
%endmacro

%macro SEC_TO_HM 1
	;hours = floor(diff / sec_inhour) = xmm15
	movsd	xmm15, %1
	divsd	xmm15, [sec_inhour]
	roundsd xmm15, xmm15, ROUND_DOWN
	cvtsd2si r8, xmm15

	;remaining_seconds = diff - (hours * sec_inhour) = xmm14
	movsd	xmm14, %1
	mulsd	xmm15, [sec_inhour]
	subsd	xmm14, xmm15

	;minutes = remaining_seconds / sec_inmin
	divsd	xmm14, [sec_inmin]
	roundsd	xmm14, xmm14, ROUND_DOWN
	cvtsd2si r9, xmm14
%endmacro

%macro SET_MSG 0
	xor rdx, rdx
	mov rbx, 0xa
	mov rax, r8
	div ebx
	add rax, 0x30
	add rdx, 0x30
	mov [res_msg+2], al
	mov [res_msg+3], dl

	xor rdx, rdx
	mov rbx, 10
	mov rax, r9
	div ebx
	add rax, 0x30
	add rdx, 0x30
	mov [res_msg+5], al
	mov [res_msg+6], dl
%endmacro

%macro CALC_P2 0
	;p2 =	cos(convert_degrees_to_radians(latitude)) *
	;	cos(convert_degrees_to_radians(D)) = xmm1
	movsd	xmm1, [latitude]
	mulsd	xmm1, [to_rad]
	COS	xmm1
	movsd	xmm2, xmm8,
	mulsd	xmm2, [to_rad]
	COS	xmm2
	mulsd	xmm1, xmm2
%endmacro

%macro CALC_P3 0
	;p3 =	sin(convert_degrees_to_radians(latitude)) *
	;	sin(convert_degrees_to_radians(D)) = xmm2
	movsd	xmm2, [latitude]
	mulsd	xmm2, [to_rad]
	SIN	xmm2
	movsd	xmm3, xmm8, ; xmm8 = D
	mulsd	xmm3, [to_rad]
	SIN	xmm3
	mulsd	xmm2, xmm3
%endmacro

%macro NORM 2;	n = x - (y * floor(x / y));
	movsd xmm14, %1
	divsd xmm14, %2
	roundsd xmm14, xmm14, ROUND_DOWN
	mulsd xmm14, %2
	subsd %1, xmm14
%endmacro

%macro CALC_T 1; T = p1 * p5
	;p4 = -1.0 * sin(convert_degrees_to_radians(alpha)) = %1
	mulsd	%1, [to_rad]
	SIN	%1
	mulsd	%1, [neg1]

	;p5 = convert_radians_to_degrees(acos((p4 - p3) / p2)) = %1
	subsd	%1, xmm2	; p4 - p3
	divsd	%1, xmm1	; / p2
	ACOS	%1
	mulsd	%1, [to_deg]	; %1 = p5

	;T = p1 * p5 = %1
	mulsd	%1, [p1]
%endmacro

%macro PRINT_INT 0
	nop
	mov	rsi, tmp0+11	; pointer to the end of decimal number
	mov	byte [rsi], 0xa	; add '\n'
	cvttsd2si rax, 	xmm14	; convert double to int
	mov	rbx, 0xa        ; hex number will divide to 10
	mov	rcx, 1          ; decimal number length + '\n'

next_digit:
	inc	rcx             ; calculate output length
	xor	rdx, rdx        ; remainder storage should be 0 before divide
	div	rbx             ; divide hex number to 10
	add	rdx, 0x30       ; calculate ascii code of remainder
	dec	rsi             ; calculate decimal digit place
	mov	[rsi], dl       ; put decimal digit into string
	cmp	rax, 0          ; is there hex digits any more?
	jnz	next_digit

	;print
	mov	rax, SYS_write	; system call number (sys_write)
	mov	rdi, STDOUT     ; first argument:  file handle (stdout)
	mov	rdx, rcx        ; second argument: pointer to string
	syscall
	EEXIT	EXIT_SUCCESS
%endmacro

%endif ;MACROS_S
