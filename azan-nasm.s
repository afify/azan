; See LICENSE file for copyright and license details.
; azan-nasm is simple muslim prayers calculator.
; print next prayer left duration or today's all prayers.

BITS 64
%include "syscalls.s"
%include "macros.s"
CHECK_OPENBSD

section .bss
	digitSpace: resb 100
	digitSpacePos: resb 8
	current_time: resb 12

section .text
	global _start

_start:
	mov rax, SYS_gettimeofday
	mov rdi, current_time
	mov rsi, rsi
	syscall

	mov rax, [current_time]

	call _printRAX
	EEXIT EXIT_SUCCESS

_printRAX:
	mov rcx, digitSpace
	mov rbx, 10
	mov [rcx], rbx
	inc rcx
	mov [digitSpacePos], rcx

_printRAXLoop:
	mov rdx, 0
	mov rbx, 10
	div rbx
	push rax
	add rdx, 48

	mov rcx, [digitSpacePos]
	mov [rcx], dl
	inc rcx
	mov [digitSpacePos], rcx
	
	pop rax
	cmp rax, 0
	jne _printRAXLoop

_printRAXLoop2:
	mov rcx, [digitSpacePos]

	mov rax, 1
	mov rdi, 1
	mov rsi, rcx
	mov rdx, 1
	syscall

	mov rcx, [digitSpacePos]
	dec rcx
	mov [digitSpacePos], rcx

	cmp rcx, digitSpace
	jge _printRAXLoop2

	ret
