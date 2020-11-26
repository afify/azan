# azan version
VERSION = 0.1

# paths
PREFIX    = /usr/local
MANPREFIX = ${PREFIX}/share/man

# flags
AFLAGS  = -f elf64 -w+all -D$$(uname) -DVERSION=\"${VERSION}\"
LFLAGS  = -m elf_x86_64 -s -no-pie

# assembler and linker
ASM  = nasm
LNK  = ld
