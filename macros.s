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

	fajr_msg:	db "fajr is bigger", 10, 0
	fajr_len:	equ $ - fajr_msg

	duhr_msg:	db "duhr is bigger", 10, 0
	duhr_len:	equ $ - duhr_msg

	asr_msg:	db "asr is bigger", 10, 0
	asr_len:	equ $ - asr_msg

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

%endif ;MACROS_S
