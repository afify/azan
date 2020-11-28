azan
=========
**prayers time calculator, written in nasm.**

- standalone nasm
- unix portable syscalls
- tested on Linux, OpenBSD, FreeBSD and NetBSD
- binary size ≈ 7 kb
- instructions ≈ 250-400
- branches ≈ 6-20

Installation
------------
**dependency**
- nasm (assembler)
- ld (linker)

**current**
```sh
git clone https://github.com/afify/azan.git
cd azan/
make
make install
```
**latest release**
```sh
wget --content-disposition $(curl -s https://api.github.com/repos/afify/azan/releases/latest | tr -d '",' | awk '/tag_name/ {print "https://github.com/afify/azan/archive/"$2".tar.gz"}')
tar -xzf azan-*.tar.gz && cd azan-*/
make
make install
```
Run
---
```sh
$ azan
```
Options
-------
```sh
$ azan [-AaNnUuv]
$ man azan
```
| option | description                                  |
|:------:|:---------------------------------------------|
| `-A`   | print all prayers time, 12-hour clock format.|
| `-a`   | print all prayers time, 24-hour clock format.|
| `-N`   | print next prayer time, 12-hour clock format.|
| `-n`   | print next prayer time, 24-hour clock format.|
| `-U`   | print all prayers time, unix-time format.    |
| `-u`   | print next prayer time, unix-time format.    |
| `-v`   | print version.                               |


Configuration
-------------
The configuration of azan is done by creating a custom config.s
and (re)compiling the source code.
