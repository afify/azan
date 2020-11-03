; See LICENSE file for copyright and license details.

%ifndef MACROS_S
%define MACROS_S

%define EXIT_SUCCESS 0
%define EXIT_FAILURE 1
%define STDOUT 1
%define STDERR 2

section .rodata
	failure_msg: db  0x5b, 0x1b, 0x5b, 0x33, 0x31, 0x6d, 0x46\
			 0x41, 0x49, 0x4c, 0x45, 0x44, 0x1b, 0x5b\
			 0x30, 0x6d, 0x5d, 0x20, 0x00
	failure_msglen: equ $ - failure_msg
	julian_msg: db "Julian must be greader than offset.", 10, 0
	julian_msglen: equ $ - julian_msg

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

%macro FAIL_MSG 0
	mov rax, SYS_write
	mov rdi, STDERR
	mov rsi, failure_msg
	mov rdx, failure_msglen
	syscall
%endmacro

%macro FAILJULIAN 0
	FAIL_MSG
	mov rax, SYS_write
	mov rdi, STDERR
	mov rsi, julian_msg
	mov rdx, julian_msglen
	syscall
	EEXIT EXIT_FAILURE
%endmacro

%endif ;MACROS_S
