; See LICENSE file for copyright and license details.

%ifndef SYSCALLS_S
%define SYSCALLS_S

%ifdef Linux
	%define SYS_exit 60
	%define SYS_write 1
	%define SYS_gettimeofday 96
%elifdef OpenBSD
	%define SYS_exit 1
	%define SYS_write 4
	%define SYS_gettimeofday 67
	%define SYS_pledge 108
%elifdef FreeBSD
	%define SYS_exit 1
	%define SYS_write 4
	%define SYS_gettimeofday 116
%elifdef NetBSD
	%define SYS_exit 1
	%define SYS_write 4
	%define SYS_gettimeofday 116
%else
	%fatal "OS not supported"
%endif

%endif ;SYSCALLS_S
