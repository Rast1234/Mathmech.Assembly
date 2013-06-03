.code16

.include "libdos/dos-headers.S"

.extern nasm_main

.section .text
    call   nasm_main

    SYS_EXIT
