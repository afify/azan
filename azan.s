; See LICENSE file for copyright and license details.
; azan is simple muslim prayers calculator.
; print next prayer left duration or today's all prayers.

BITS 64
%include "syscalls.s"
%include "macros.s"
%include "math.s"
%include "config.s"
CHECK_BSD

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
	sec_inhour:	dq 0x40ac200000000000	;double 3600
	sec_inmin:	dq 0x404e000000000000	;double 60
	maghrib_1:	dq 0x3fa1c432ca57a787	;double 0.0347
	maghrib_2:	dq 0x3feaaaaaaaaaaaab	;double 0.833333333333333333
	isha_nor:	dq 0x40b5180000000000	;double 5400.0 90 min
	isha_ram:	dq 0x40bc200000000000	;double 7200.0 120 min
	usage_msg:	db "usage: azan [-AaNnUuv]", 10, 0
	usage_len:	equ $ - usage_msg
	version_msg:	db "azan-", VERSION, 10, 0
	version_len:	equ $ - version_msg
	pledge_msg:	db "pledge", 10, 0
	promises:	db "stdio", 0

section .data
	res_msg:	db "X XX:XX", 10, 0
	res_len:	equ $ - res_msg

section .bss
	tmp0:	resq 1
	tmp1:	resq 1

section .text
	global _start

_start:
	pop	rcx
	cmp	rcx, MAX_ARGC
	jl	get_timestamp
	je	check_argv

die_usage:
	DIE	usage_msg, usage_len

check_argv:
	mov	r11, [rsp+8]	;argv
	cmp	[r11], byte 0x2d	;-
	jne	die_usage
	cmp	[r11+2], byte 0x00
	jne	die_usage
	mov	r12b, [r11+1]
	cmp	r12b, 0x41	;A
	je	get_timestamp
	cmp	r12b, 0x61	;a
	je	get_timestamp
	cmp	r12b, 0x55	;U
	je	get_timestamp
	cmp	r12b, 0x75	;u
	je	get_timestamp
	cmp	r12b, 0x6e	;n
	je	get_timestamp
	cmp	r12b, 0x4e	;N
	je	get_timestamp
	cmp	r12b, 0x76	;v
	jne	die_usage
	DIE	version_msg, version_len

get_timestamp:
	OPENBSD_PLEDGE
	mov	rax, SYS_gettimeofday	;sys_gettimeofday(
	mov	rdi, tmp0		;struct timeval *tv,
	mov	rsi, rsi		;struct timezone* tz
	syscall

	;start_of_day = tstamp - (tstamp % 86400);
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
	mulsd	xmm14, [sec_inhour]
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

get_duhr:	;duhr = 12.0+time_zone-EqT-(longitude/15.0)=xmm0
	movsd	xmm1, [longitude]
	divsd	xmm1, [RA_1]
	movsd	xmm0, [duhr_1]
	addsd	xmm0, [time_zone]
	subsd	xmm0, xmm9
	subsd	xmm0, xmm1
	NORM	xmm0, [pray_1]

calc_p2p3:
	CALC_P2	;xmm1
	CALC_P3	;xmm2

get_fajr:	;fajr = duhr - T(fajr_angle, D) = xmm3

	movsd	xmm3, [fajr_angle]
	CALC_T	xmm3

	;fajr = duhr - T = xmm3
	movsd	xmm4, xmm3
	movsd	xmm3, xmm0
	subsd	xmm3, xmm4

test_fajr:
	mulsd	xmm3, [sec_inhour]	;convert to seconds
	roundsd	xmm3, xmm3, ROUND_DOWN
	addsd	xmm3, xmm15		;fajr seconds + start_of_day
	cmp	r12b, byte 'U'
	je	test_duhr
	cmp	r12b, byte 'a'
	je	test_duhr
	cmp	r12b, byte 'A'
	je	test_duhr
	ucomisd	xmm3, xmm6		;if fajr > tstamp
	jae	print_fajr

test_duhr:
	movsd	xmm13, xmm0		;save duhr to xmm13
	mulsd	xmm0, [sec_inhour]	;convert to seconds
	roundsd	xmm0, xmm0, ROUND_DOWN
	addsd	xmm0, xmm15		;duhr seconds + start_of_day
	cmp	r12b, byte 'U'
	je	get_asr
	cmp	r12b, byte 'a'
	je	get_asr
	cmp	r12b, byte 'A'
	je	get_asr
	ucomisd	xmm0, xmm6		;if duhr > tstamp
	jae	print_duhr

get_asr:	;asr = duhr + A(1.0, D);
	;A = p1 * p7 = xmm4
	;p4 = tan(convert_degrees_to_radians((latitude - D)))
	;p5 = atan2(1.0, (t + p4));
	;p6 = sin(p5) = xmm4
	movsd	xmm4, [latitude]
	subsd	xmm4, xmm8
	mulsd	xmm4, [to_rad]
	movsd	[tmp0], xmm4
	fld1
	fld	qword [tmp0]
	fptan
	fadd
	fpatan
	fsin
	fstp	qword [tmp0]
	movsd	xmm4, [tmp0]

	;p7 = convert_radians_to_degrees(acos((p6 - p3) / p2));
	subsd	xmm4, xmm2
	divsd	xmm4, xmm1
	ACOS	xmm4
	mulsd	xmm4, [to_deg]

	;A = p1 * p7 = xmm4
	mulsd	xmm4, [p1]
	addsd	xmm4, xmm13
	NORM	xmm4, [pray_1]

test_asr:
	mulsd	xmm4, [sec_inhour]	;convert to seconds
	roundsd	xmm4, xmm4, ROUND_DOWN
	addsd	xmm4, xmm15		;asr seconds + start_of_day
	cmp	r12b, byte 'U'
	je	get_maghrib
	cmp	r12b, byte 'a'
	je	get_maghrib
	cmp	r12b, byte 'A'
	je	get_maghrib
	ucomisd	xmm4, xmm6		;if asr > tstamp
	jae	print_asr

get_maghrib:	;duhr + T(0.8333 + 0.0347 * sqrt(altitude), D) = xmm5
	sqrtsd	xmm5, [altitude]
	mulsd	xmm5, [maghrib_1]
	addsd	xmm5, [maghrib_2]
	CALC_T	xmm5
	addsd	xmm5, xmm13

test_maghrib:
	mulsd	xmm5, [sec_inhour]	;convert to seconds
	roundsd	xmm5, xmm5, ROUND_DOWN
	addsd	xmm5, xmm15		;maghrib seconds + start_of_day
	cmp	r12b, byte 'U'
	je	get_isha
	cmp	r12b, byte 'a'
	je	get_isha
	cmp	r12b, byte 'A'
	je	get_isha
	ucomisd	xmm5, xmm6		;if maghrib > tstamp
	jae	print_maghrib

get_isha:
	mov	rcx, 1
	cmp	rcx, use_umm_al_qura
	jne	um_nor
	cmp	rcx, ramadan
	je	um_ram

um_nor:		;maghrib + 90.0 min;
	movsd	xmm7, [isha_nor]
	addsd	xmm7, xmm5
	jmp	test_isha

um_ram:		;maghrib + 120.0 min;
	movsd	xmm7, [isha_ram]
	addsd	xmm7, xmm5
	jmp	test_isha

calc_isha_nor:	;duhr + T(isha_angle, D);
	movsd	xmm7, [isha_angle]
	CALC_T	xmm7
	addsd	xmm7, xmm13
	NORM	xmm7, [pray_1]

test_isha:
	cmp	r12b, byte 'U'
	je	print_all_u
	cmp	r12b, byte 'a'
	je	print_all_24
	cmp	r12b, byte 'A'
	je	print_all_12
	ucomisd	xmm7, xmm6	;if isha > tstamp
	jae	print_isha

get_nfajr:	;fajr + sec_inday
	movsd	xmm12, [sec_inday]
	addsd	xmm12, xmm3

print_nfajr:
	mov	[res_msg], byte 'F'
	movsd	xmm14, xmm12
	cmp	r12b, byte 'u'
	je	print_unix
	cmp	r12b, byte 'n'
	je	print_fajr
	cmp	r12b, byte 'N'
	je	print_fajr
	subsd	xmm12, xmm6	;diff = prayer time - tstamp = xmm12
	SEC_TO_HM xmm12
	PRINT_HM
	EEXIT	EXIT_SUCCESS

print_fajr:
	mov		[res_msg], byte 'F'
	PRINT_FLAG	xmm3

print_duhr:
	mov		[res_msg], byte 'D'
	PRINT_FLAG	xmm0

print_asr:
	mov		[res_msg], byte 'A'
	PRINT_FLAG	xmm4

print_maghrib:
	mov		[res_msg], byte 'M'
	PRINT_FLAG	xmm5

print_isha:
	mov		[res_msg], byte 'I'
	PRINT_FLAG	 xmm7

print_unix:
	PRINT_INT	xmm14
	EEXIT		EXIT_SUCCESS

print_24:
	subsd		xmm14, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm14
	PRINT_HM
	EEXIT		EXIT_SUCCESS

print_12:
	subsd		xmm14, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm14
	cmp		r8, 0xc
	jle		print_exit
	sub	r8, 0xc

print_exit:
	PRINT_HM
	EEXIT		EXIT_SUCCESS

print_all_u:
	PRINT_INT	xmm3	;fajr
	PRINT_INT	xmm0	;duhr
	PRINT_INT	xmm4	;asr
	PRINT_INT	xmm5	;maghrib
	PRINT_INT	xmm7	;isha
	EEXIT		EXIT_SUCCESS

print_all_24:
	mov		[res_msg], byte 'F'
	subsd		xmm3, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm3
	PRINT_HM

	mov		[res_msg], byte 'D'
	subsd		xmm0, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm0
	PRINT_HM

	mov		[res_msg], byte 'A'
	subsd		xmm4, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm4
	PRINT_HM

	mov		[res_msg], byte 'M'
	subsd		xmm5, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm5
	PRINT_HM

	mov		[res_msg], byte 'I'
	subsd		xmm7, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm7
	PRINT_HM
	EEXIT		EXIT_SUCCESS

print_all_12:
	mov		[res_msg], byte 'F'
	subsd		xmm3, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm3
	PRINT_HM

	mov		[res_msg], byte 'D'
	subsd		xmm0, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm0
	PRINT_HM

	mov		[res_msg], byte 'A'
	subsd		xmm4, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm4
	sub		r8, 0xc
	PRINT_HM

	mov		[res_msg], byte 'M'
	subsd		xmm5, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm5
	sub		r8, 0xc
	PRINT_HM

	mov		[res_msg], byte 'I'
	subsd		xmm7, xmm15	;prayer timestamp - start_of_day
	SEC_TO_HM	xmm7
	sub		r8, 0xc
	PRINT_HM
	EEXIT	EXIT_SUCCESS

die_pledge:
	DIE	pledge_msg, 8
;	result_hour	;r8
;	result_min	;r9
;	duhr_ts:	;xmm0
;	p2:		;xmm1
;	p3:		;xmm2
;	fajr_ts:	;xmm3
;	asr_ts		;xmm4
;	maghrib_ts:	;xmm5
;	tstamp:		;xmm6
;	isha_ts:	;xmm7
;	D:		;xmm8
;	EqT:		;xmm9
;	macros:		;xmm10
;	next_fajr	;xmm12
;	duhr:		;xmm13
;	macros:		;xmm14
;	start_of_day:	;xmm15
