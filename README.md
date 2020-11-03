azan-nasm
=========

azan-nasm is nasm azan implementation

Installation
------------
**current**
```sh
git clone https://github.com/afify/azan-nasm.git
cd azan-nasm/
make
make install
```
**latest release**
```sh
wget --content-disposition $(curl -s https://api.github.com/repos/afify/azan-nasm/releases/latest | tr -d '",' | awk '/tag_name/ {print "https://github.com/afify/azan-nasm/archive/"$2".tar.gz"}')
tar -xzf azan-nasm-*.tar.gz && cd azan-nasm-*/
make
make install
```
Run
---
```sh
$ azan-nasm
```
Options
-------
```sh
$ azan-nasm
$ man azan-nasm
```
