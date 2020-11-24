; See LICENSE file for copyright and license details.

%ifndef MATH_S
%define MATH_S

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

%macro ATAN2 2
	movsd	[tmp0], %1
	movsd	[tmp1], %2
	fld	qword [tmp0]	;x
	fld	qword [tmp1]	;y
	fpatan
	fstp	qword [tmp0]
	movsd	%1, [tmp0]
%endmacro

%endif ;MATH_S
