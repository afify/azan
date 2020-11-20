; See LICENSE file for copyright and license details.
; azan-nasm is simple muslim prayers calculator.
; print next prayer left duration or today's all prayers.

BITS 64
%include "syscalls.s"
%include "macros.s"
%include "config.s"
CHECK_OPENBSD

section .rodata
	sec_inday:	dq 0x40f5180000000000	;double 86400.0
	jul1970:	dq 0x41429ec5c0000000	;double 2440587.5
	offset:		dq 0xc142b42c80000000	;double -2451545
	to_rad:		dq 0x3f91df46a2529d39	;double pi / 180
	to_deg:		dq 0x404ca5dc1a63c1f8	;double 180 / pi
	g_1:		dq 0x3fef8a099930e901	;double 0.98560027999999999
	g_2:		dq 0x40765876c8b43958	;double 357.529
	e_3:		dq 0xbe9828c0be769dc1	;double -3.5999999999999999E-7
	e_4:		dq 0x403770624dd2f1aa	;double 23.439
	q_5:		dq 0x3fef8a6c5512d6f2	;double 0.98564735999999997
	q_6:		dq 0x4071875810624dd3	;double 280.459
	sing_1:		dq 0x3FFEA3D70A3D70A4	;double 1.915
	sing_2:		dq 0x3F947AE147AE147B	;double 0.020
	RA_1:		dq 0x402E000000000000	;double 15.0
	eqt_1:		dq 0x4076800000000000	;double 360.0
	duhr_1:		dq 0x4028000000000000	;double 12.0
	pray_1:		dq 0x4038000000000000	;double 24.0
	neg1:		dq 0xBFF0000000000000	;double -1.0
	p1:		dq 0X3fb1111111111111	;double 0.066666666666666666
	hours_to_sec:	dq 0x40ac200000000000	;double 3600

section .bss
	tmp0:	resq 1
	tmp1:	resq 1

section .text
	global _start

_start:
	pop	rcx
	cmp	rcx, MAX_ARGC
	jl	get_timestamp
	je	die_version

die_usage:
	DIE	usage_msg, usage_len

die_version:
	mov	rcx, [rsp+8]		; argv
	cmp	[rcx], byte '-'
	jne	die_usage
	cmp	[rcx+1], byte 'v'
	jne	die_usage
	cmp	[rcx+2], byte 0
	jne	die_usage
	DIE	version_msg, version_len

get_timestamp:
	mov	rax, SYS_gettimeofday	;sys_gettimeofday(
	mov	rdi, tmp0		;struct timeval *tv,
	mov	rsi, rsi		;struct timezone* tz
	syscall

	; start_of_day = tstamp - (tstamp % 86400);
	mov	edi, [tmp0]
	movsx	rax, edi
	mov	edx, edi
	imul	rax, rax, -1037155065
	sar	edx, 31
	shr	rax, 32
	add	eax, edi
	sar	eax, 16
	sub	eax, edx
	imul	edx, eax, 86400
	mov	eax, edi
	sub	eax, edx
	cvtsi2sd xmm15, rdx
	movsd	xmm14, [time_zone]
	mulsd	xmm14, [hours_to_sec]
	subsd	xmm15, xmm14

	;tstamp = xmm6 convert tstamp to double
	cvtsi2sd xmm6, [tmp0]

	;julian = tstamp / sec_inday) + jul1970 = xmm0
	movsd	xmm0, xmm6		;copy tstamp to xmm0
	divsd	xmm0, [sec_inday]	;tstamp / sec_inday
	addsd	xmm0, [jul1970]		;div result + jul1970

calc_equation_of_time:
	;d = julian - offset = xmm0
	addsd	xmm0, [offset]

	;g = to_rad * ((d *  0.98560028) + 357.529) = xmm1
	movsd	xmm1, [g_1]
	mulsd	xmm1, xmm0
	addsd	xmm1, [g_2]
	mulsd	xmm1, [to_rad]

	;e = to_rad * (23.439 - (d * 0.00000036)) = xmm3
	movsd	xmm3, [e_3]
	mulsd	xmm3, xmm0
	addsd	xmm3, [e_4]
	mulsd	xmm3, [to_rad]

	;q = (d *  0.98564736) + 280.459 = xmm4
	movsd	xmm4, [q_5]
	mulsd	xmm4, xmm0
	addsd	xmm4, [q_6]

	;sing = 1.915 * sin(g) = xmm5
	movsd	xmm5, xmm1
	SIN	xmm5
	mulsd	xmm5, [sing_1]

	;sin2g = 0.020 * sin(2.0*g) = xmm1
	addsd	xmm1, xmm1
	SIN	xmm1
	mulsd	xmm1, [sing_2]

	;sin(e) = xmm8
	movsd	xmm8 , xmm3
	SIN	xmm8

	;cos(e) = xmm7
	movsd	xmm7, xmm3
	COS	xmm7

	;L = to_rad(q + sing + sin2g) = xmm5
	addsd	xmm5, xmm1
	addsd	xmm5, xmm4
	mulsd	xmm5, [to_rad]

	;sin(L) = xmm2
	movsd	xmm2, xmm5
	SIN	xmm2

	;cos(L) = xmm5
	COS	xmm5

	;RA = to_deg(atan2(cose * sinL, cosL) / 15.0) = xmm7
	mulsd	xmm7, xmm2	;cose * sinL
	ATAN2	xmm7, xmm5	;result in xmm7
	divsd	xmm7, [RA_1]	;atan2 result /15.0
	mulsd	xmm7, [to_deg]	;* to_deg

	;D = to_deg(asin(sine * sinL)) = xmm8
	mulsd	xmm8, xmm2
	ASIN	xmm8
	mulsd	xmm8, [to_deg]

	;EqT = q / 15.0 - RA = xmm9
	movsd	xmm9, xmm4	;move q to xmm9
	divsd	xmm9, [RA_1]	;q / 15.0
	subsd	xmm9, xmm7	;- RA
	subsd	xmm9, [eqt_1]	;EqT = EqT - 360.0

get_duhr:			;duhr = 12.0+time_zone-EqT-(longitude/15.0);
	movsd	xmm1, [longitude]
	divsd	xmm1, [RA_1]
	movsd	xmm0, [duhr_1]
	addsd	xmm0, [time_zone]
	subsd	xmm0, xmm9
	subsd	xmm0, xmm1

	;normalize duhr
	;xmm0 - (pray_1 * floor(xmm1 / pray_1));
	movsd	xmm1, xmm0
	divsd	xmm1, [pray_1]
	roundsd	xmm1, xmm1, ROUND_DOWN	;floor(xmm1)
	mulsd	xmm1, [pray_1]
	subsd	xmm0, xmm1
	;xmm0 = duhr

get_fajr:			;fajr = duhr - T(fajr_angle, D);
	;calculate T = p1 * p5
	;p2 =	cos(convert_degrees_to_radians(latitude)) *
	;	cos(convert_degrees_to_radians(D)) = xmm1
	movsd	xmm1, [latitude]
	mulsd	xmm1, [to_rad]
	COS	xmm1
	movsd	xmm2, xmm8,
	mulsd	xmm2, [to_rad]
	COS	xmm2
	mulsd	xmm1, xmm2

	;p3 =	sin(convert_degrees_to_radians(latitude)) *
	;	sin(convert_degrees_to_radians(D)) = xmm2
	movsd	xmm2, [latitude]
	mulsd	xmm2, [to_rad]
	SIN	xmm2
	movsd	xmm3, xmm8, ; xmm8 = D
	mulsd	xmm3, [to_rad]
	SIN	xmm3
	mulsd	xmm2, xmm3

	;p4 = -1.0 * sin(convert_degrees_to_radians(alpha)) = xmm3
	movsd	xmm3, [fajr_angle]
	mulsd	xmm3, [to_rad]
	SIN	xmm3
	mulsd	xmm3, [neg1]

	;p5 = convert_radians_to_degrees(acos((p4 - p3) / p2)) = xmm3
	subsd	xmm3, xmm2	; p4 - p3
	divsd	xmm3, xmm1	; / p2
	ACOS	xmm3
	mulsd	xmm3, [to_deg]	; xmm3 = p5

	;T = p1 * p5 = xmm3
	mulsd	xmm3, [p1]

	;fajr = duhr - T = xmm3
	movsd	xmm4, xmm3
	movsd	xmm3, xmm0
	subsd	xmm3, xmm4

convert_fajr_to_time:
	mulsd	xmm3, [hours_to_sec]	;convert to seconds
	roundsd	xmm3, xmm3, ROUND_DOWN
	addsd	xmm3, xmm15		;fajr seconds + start_of_day
	ucomisd	xmm3, xmm6		;if fajr > tstamp
	jae	calculate_left_fajr
	jmp	convert_duhr_to_time

convert_duhr_to_time:
	mulsd	xmm0, [hours_to_sec]	;convert to seconds
	roundsd	xmm0, xmm0, ROUND_DOWN
	addsd	xmm0, xmm15		;duhr seconds + start_of_day
	ucomisd	xmm0, xmm6		;if duhr > tstamp
	jae	calculate_left_duhr
	jmp	calculate_asr

calculate_left_fajr:
	DIE	fajr_msg, fajr_len
;
calculate_left_duhr:
	DIE	duhr_msg, duhr_len
;
calculate_asr:
	DIE	asr_msg, asr_len

; 	duhr:		; xmm0
; 	p2:		; xmm1
; 	p3:		; xmm2
; 	fajr:		; xmm3
; 	tstamp:		; xmm6
; 	EqT:		; xmm9
; 	D:		; xmm8
; 	start_of_day:	; xmm15

	EEXIT EXIT_SUCCESS
