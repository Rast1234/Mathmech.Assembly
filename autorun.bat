c:\dos\ng\ng
REM c:\dos\util\reschar /i

path=c:\dos\nu;c:\dos\me;c:\dos\util;c:\dos\bc\bin;c:\dos\bp\bin;c:\dos\sr;c:\dos\fp25;c:\dos\frac;c:\winnt\system32
set dircmd=

del c:\dos\work\t.com
c:\dos\nasm\nasm.exe v_test.asm -o t.com -f bin

del c:\dos\work\e.com
c:\dos\nasm\nasm.exe ega.asm -o e.com -f bin

del c:\dos\work\v.com
c:\dos\nasm\nasm.exe v_ega.asm -o v.com -f bin
