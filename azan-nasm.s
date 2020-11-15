; See LICENSE file for copyright and license details.
; azan-nasm is simple muslim prayers calculator.
; print next prayer left duration or today's all prayers.

BITS 64
%include "syscalls.s"
%include "macros.s"
CHECK_OPENBSD

section .rodata
	sec_inday:	dq 86400.0
	jul1970:	dq 2440587.5
	offset:		dq 0xc142b42c80000000	;double -2451545
	to_rad:		dq 0x3f91df46a2529d39	;double pi / 180 to radian
	to_deg:		dq 0x404ca5dc1a63c1f8	;double 180 / pi to degree
	g_1:		dq 0x3fef8a099930e901	;double 0.98560027999999999
	g_2:		dq 0x40765876c8b43958	;double 357.529
	e_3:		dq 0xbe9828c0be769dc1	;double -3.5999999999999999E-7
	e_4:		dq 0x403770624dd2f1aa	;double 23.439
	q_5:		dq 0x3fef8a6c5512d6f2	;double 0.98564735999999997
	q_6:		dq 0x4071875810624dd3	;double 280.459
	sing_1:		dq 0x3FFEA3D70A3D70A4	;double 1.915
	sing_2:		dq 0x3F947AE147AE147B	;double 0.020
	RA_1:		dq 0x402E000000000000	;double 15.0
	asin_1:		dq 0x3FF0000000000000	;double 1
	eqt_1:		dq 0x4076800000000000	;double 360.0

section .bss
	tstamp:	resb 12
	julian:	resq 1
	EqT:	resq 1
	g:	resq 1
	g2:	resq 1
	sing:	resq 1
	sin2g:	resq 1
	sine:	resq 1
	cose:	resq 1
	sinL:	resq 1
	cosL:	resq 1
	RA_2:	resq 1
	asin_x:	resq 1

section .text
	global _start

_start:
; get_timestamp:
	mov	rax, SYS_gettimeofday	;sys_gettimeofday(
	mov	rdi, tstamp		;struct timeval *tv,
	mov	rsi, rsi		;struct timezone* tz
	syscall

; calc_julian:(timestamp / sec_in_day) + jul1970
	cvtsi2sd xmm0, [tstamp]		;convert timestamp to double
	divsd	xmm0, [sec_inday]	;timestamp / sec_in_day
	addsd	xmm0, [jul1970]		;div result + jul1970
; 	xmm0 = julian

; calc_equation_of_time:
	addsd	xmm0, [offset]	;d = julian - offset
; 	xmm0 = d

	movsd	xmm2, [to_rad]
	movsd	xmm1, [g_1]	;g = to_rad * ((d *  0.98560028) + 357.529)
	mulsd	xmm1, xmm0
	addsd	xmm1, [g_2]
	mulsd	xmm1, xmm2
; 	xmm1 = g
; 	xmm2 = to_rad

	movsd	xmm3, [e_3]	;e = to_rad * (23.439 - (d * 0.00000036))
	mulsd	xmm3, xmm0
	addsd	xmm3, [e_4]
	mulsd	xmm3, xmm2
; 	xmm3 = e

	movsd	xmm4, [q_5]	;q = (d *  0.98564736) + 280.459
	mulsd	xmm4, xmm0
	addsd	xmm4, [q_6]
; 	xmm4 = q

; 	sing:			;sing = 1.915 * sin(g);
	movsd	xmm5, [sing_1]
	finit
	movsd	[g], xmm1
	fld	qword [g]
	fsin
	fstp	qword [sing]
	mulsd xmm5, [sing]
; 	xmm5 = sing

; 	sin2g:			;sin2g = 0.020 * sin(2.0*g)
	movsd	xmm6, [sing_2]
	addsd	xmm1, xmm1
	movsd	[g2], xmm1
	fld	qword [g2]
	fsin
	fstp	qword [sin2g]
	mulsd xmm6, [sin2g]
; 	xmm1 = 2 * g
; 	xmm6 = sin2g

; 	sine:			;sin(e)
	movsd	[sine], xmm3
	fld	qword [sine]
	fsin
	fstp	qword [sine]

; 	cose:			;cos(e)
	movsd	[cose], xmm3
	fld	qword [cose]
	fcos
	fstp	qword [cose]

;	L:			;L = to_rad(q + sing + sin2g);
	addsd	xmm5, xmm6	;sing + sin2g
	addsd	xmm5, xmm4	;+ q
	mulsd	xmm5, xmm2	;* to_rad
; 	xmm5 = L

; 	sinL:			;sin(L)
	movsd	[sinL], xmm5
	fld	qword [sinL]
	fsin
	fstp	qword [sinL]

; 	cosL:			;cos(L)
	movsd	[cosL], xmm5
	fld	qword [cosL]
	fcos
	fstp	qword [cosL]

;	RA:			;RA = to_deg(atan2(cose * sinL, cosL) / 15.0);
	movsd	xmm7, [cose]
	mulsd	xmm7, [sinL]
	movsd	[cose], xmm7
	fld	qword [cose]	;load cose
	fld	qword [cosL]	;load cosL
	fpatan			;calc atan2 (cose / cosL)
	fstp	qword [RA_2]	;save angle
	movsd	xmm7, [RA_2]
	divsd	xmm7, [RA_1]	;atan2 result /15.0
	mulsd	xmm7, [to_deg]	;* to_deg
; 	xmm7 = RA

;	D:			;D = to_deg(asin(sine * sinL));
;				asin =  arctan(x / sqrt(1 - x * x))
	movsd	xmm8, [sine]
	mulsd	xmm8, [sinL]
	movsd	[asin_x], xmm8
	; xmm8 = x

	movsd xmm9, xmm8	; xmm8 = x
	mulsd xmm9, xmm8	; xmm9 = x * x
	movsd xmm10, [asin_1]	; xmm10 = 1
	subsd xmm10, xmm9	; 1 - xmm9
	movsd [asin_1], xmm10	; asin_1 = (1-x*x)
	movsd [asin_x], xmm8	; asin_1 = (1-x*x)
; 	xmm9 = x * x
; 	xmm10 = 1 - xmm9

	fld	qword [asin_x]
	fld	qword [asin_1]
	fsqrt
	fpatan
	fstp	qword [asin_1]
	movsd	xmm8, [asin_1]
	mulsd	xmm8, [to_deg]
; 	xmm8 = D

;	Eqt			;EqT = q / 15.0 - RA;
	movsd	xmm9, xmm4	; move q to xmm9
	divsd	xmm9, [RA_1]	; q / 15.0
	subsd	xmm9, xmm7	; - RA
; 	xmm9 = EqT
; 	EqT = EqT - 360.0
	subsd xmm9, [eqt_1]

	EEXIT EXIT_SUCCESS
