.section .text

# -----------------------------------------------------

# Берет следующее число из строки аргументов
# INPUT:  %al - string length
#         %es:(%si) - string
# OUTPUT: %ah - success status
#         %dl - number
get_number_from_argv:
    movb  $SUCCESS, %ah
1:
    cmpb  $' ', %es:(%si)
    jne   2f
    incw  %si
    decb  %al
    jmp   1b
2:
    cmpb  $'0', %es:(%si)
    jl    3f
    cmpb  $'9', %es:(%si)
    jg    3f
    movb  %es:(%si), %dl
    subb  $'0', %dl
    jmp   4f
3:
    movb  $FAIL, %ah
4:
    incw  %si
    decb  %al
    ret

# -----------------------------------------------------

# функция печатающая hex представление регистра %al
# void __fastcall print_char_hex(char target_char)#
print_char_hex:

    # сохранение состояния системы
    push  %ax
    push  %bx
    push  %cx
    push  %dx
    
    # сохраняем адрес таблицы hex символов для использования с xlat
    movw  $Liofunc_hex_symbol, %bx

    # сохраняем обрабатываемое значение
    movb  %al,   %cl

    # совершаем сдвиг, взятие из hex-таблицы и вывод
    shrb  $0x04, %al
    xlat
    movb  %al,   %dl
    movb  $DOS_PRINT_CHAR, %ah
    int   $DOS_SYSCALL

    # совершаем сопоставление с битовой маской, взятие из hex-таблицы и вывод
    movb  %cl,   %al
    andb  $0x0f, %al
    xlat
    movb  %al,   %dl
    movb  $DOS_PRINT_CHAR, %ah
    int   $DOS_SYSCALL

    # восстанавливаем состояние системы
    pop   %dx
    pop   %cx
    pop   %bx
    pop   %ax

    ret


# -----------------------------------------------------

# функция печатающая hex представление регистра %ax
# void __fastcall print_word_hex(word target_word)#
print_word_hex:
    xchgb %ah, %al
    call  print_char_hex
    xchgb %ah, %al
    call  print_char_hex
    ret


# -----------------------------------------------------


.section .data

    # таблица hex-символов
    Liofunc_hex_symbol:
        .ascii "0123456789abcdef"

