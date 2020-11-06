; See LICENSE file for copyright and license details.
; azan-nasm is simple muslim prayers calculator.
; print next prayer left duration or today's all prayers.

BITS 64
%include "syscalls.s"
%include "macros.s"
CHECK_OPENBSD

section .bss
	timestamp: resb 12
	julian: resb 12
	equation_of_time: resb 12
	res_char: resb 1
	res_hour: resb 2
	res_min: resb 2
section .rodata
	julian_1970: dq 0x41429ec5c0000000 ; double 2440587.5
	sec_in_day: dq 0x40f5180000000000 ; double 86400

section .text
	global _start
	extern _printRAX

_start:
; get_timestamp:
	mov rax, SYS_gettimeofday ;sys_gettimeofday(
	mov rdi, timestamp        ;struct timeval *tv,
	mov rsi, rsi              ;struct timezone* tz
	syscall                   ;)

; calc_julian:
	mov rax, [timestamp]   ; mov value of timestamp in rax
	mov rbx, sec_in_day    ; rbx = SEC_IN_DAY
	div rbx                ; timestamp / SEC_IN_DAY
	add rax, 2440587
	mov [julian], rax      ; save result of division in julian

	call _printRAX ;util.s
	EEXIT EXIT_SUCCESS
