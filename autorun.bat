c:\dos\ng\ng
REM c:\dos\util\reschar /i

path=c:\dos\nu;c:\dos\me;c:\dos\util;c:\dos\bc\bin;c:\dos\bp\bin;c:\dos\sr;c:\dos\fp25;c:\dos\frac;c:\winnt\system32
set dircmd=

del c:\dos\work\ball.com
c:\dos\nasm\nasm.exe ball.asm -o ball.com -f bin
