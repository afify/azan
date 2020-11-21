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
	usage_msg:	db "usage: azan-nasm [-v]", 10, 0
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

%macro ACOS 1	;acos(x) = atan(sqrt((1-x*x)/(x*x)))
	movsd	[tmp0], %1
	fld    qword [tmp0]
	fld    st0
	fmul   st0, st1
	fld1
	fsubrp st1, st0
	fsqrt
	fxch
	fpatan
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%macro ASIN 1	;asin(x) = atan(sqrt(x*x/(1-x*x)))
	movsd	[tmp0], %1
	fld    qword [tmp0]
	fld    st0
	fmul   st0, st1
	fld1
	fsubrp st1, st0
	fsqrt
	fpatan
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%macro COS 1
	movsd	[tmp0], %1
	fld	qword [tmp0]
	fcos
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%macro SIN 1
	movsd	[tmp0], %1
	fld	qword [tmp0]
	fsin
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%macro ATAN2 2
	movsd	[tmp0], %1
	movsd	[tmp1], %2
	fld	qword [tmp0]	;x
	fld	qword [tmp1]	;y
	fpatan
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%macro CALC_DIFF 1
	; diff = prayer time - tstamp
	subsd	%1, xmm6

	;hours = floor(diff / sec_inhour) = xmm13
	movsd	xmm13, %1
	divsd	xmm13, [sec_inhour]
	roundsd xmm13, xmm13, ROUND_DOWN
	cvtsd2si r8, xmm13

	;remaining_seconds = diff - (hours * sec_inhour) = xmm14
	movsd	xmm14, %1
	mulsd	xmm13, [sec_inhour]
	subsd	xmm14, xmm13

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

%endif ;MACROS_S
