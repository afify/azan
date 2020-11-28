# azan version
VERSION = 0.1

# paths
PREFIX    = /usr/local
MANPREFIX = ${PREFIX}/share/man

# flags
AFLAGS  = -f elf64 -w+all -D$$(uname) -DVERSION=\"${VERSION}\"
LFLAGS  = -m elf_x86_64 -s -no-pie
# FreeBSD (uncomment)
# LFLAGS  = -m elf_amd64_fbsd -s

# assembler and linker
ASM  = nasm
LNK  = ld
