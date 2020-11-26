# azan
# See LICENSE file for copyright and license details.

include config.mk

BIN = azan
SRC = ${BIN}.s
OBJ = ${SRC:.s=.o}

all: options ${BIN}

options:
	@echo ${BIN} build options:
	@echo "AFLAGS  = ${AFLAGS}"
	@echo "LFLAGS  = ${LFLAGS}"
	@echo "ASM     = ${ASM}"
	@echo "LNK     = ${LNK}"

.s.o:
	${ASM} ${AFLAGS} $<

${OBJ}: config.s config.mk

config.s:
	cp config.def.s $@

${BIN}: ${OBJ}
	${LNK} ${LFLAGS} -o $@ ${OBJ}

clean:
	rm -rf ${OBJ} ${BIN} ${BIN}-${VERSION}.tar.gz

dist: clean
	mkdir -p ${BIN}-${VERSION}
	cp -R LICENSE Makefile README.md config.mk\
		${BIN}.1 ${SRC} ${BIN}-${VERSION}
	tar -cf ${BIN}-${VERSION}.tar ${BIN}-${VERSION}
	gzip ${BIN}-${VERSION}.tar
	rm -rf ${BIN}-${VERSION}

install: ${BIN}
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f ${BIN} ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/${BIN}
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < ${BIN}.1 > \
		${DESTDIR}${MANPREFIX}/man1/${BIN}.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/${BIN}.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/${BIN}\
		${DESTDIR}${MANPREFIX}/man1/${BIN}.1

.PHONY: all options clean dist install uninstall
