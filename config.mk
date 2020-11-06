# azan-nasm version
VERSION = 0.1

# Customize below to fit your system

# paths
PREFIX    = /usr/local
MANPREFIX = ${PREFIX}/share/man

# flags
AFLAGS  = -f elf64 -w+all -D$$(uname)
LFLAGS  = -m elf_x86_64 -s -no-pie

# compiler and linker
ASM  = nasm
LNK  = ld
