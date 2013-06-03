# interrupts number
.set DOS_MULTIPLEX_IRQ,      0x2f
.set KEYBOARD_IRQ,           0x09
.set DOS_SYSCALL,            0x21
.set BIOS_VIDEO_CALL,        0x10
.set KEYBOARD_CALL,          0x16
.set MOUSE_CALL,             0x33

# DOS int 0x21 functions
.set DOS_PRINT_CHAR,         0x02
.set DOS_PRINT_STRING,       0x09
.set DOS_SET_IRQ_HANDLER,    0x25
.set DOS_MAKE_RESIDENT,      0x31
.set DOS_GET_IRQ_HANDLER,    0x35
.set DOS_OPEN_FILE,          0x3d
.set DOS_READ_FILE,          0x3f
.set DOS_FREE_MEMORY,        0x49
.set DOS_EXIT,               0x4c

# BIOS video function
.set BIOS_SET_MODE,          0x00
.set BIOS_SET_POSITION,      0x02
.set BIOS_SET_PAGE,          0x05
.set BIOS_SCROLL_UP,         0x06
.set BIOS_SCROLL_DOWN,       0x07
.set BIOS_WRITE_CHAR_COLOR,  0x09
.set BIOS_WRITE_CHAR,        0x0a
.set BIOS_WRITE_GRAPH_DOT,   0x0c
.set BIOS_READ_GRAPH_DOT,    0x0d
.set BIOS_GET_MODE,          0x0f
.set BIOS_WRITE_STRING,      0x13

# Video modes
.set VM_GR_06,         0x06  # 640 X 200, 2 colors 
.set VM_GR_13,         0x0d  # 320 X 200, 16 colors 
.set VM_GR_14,         0x0e  # 640 X 200, 16 colors 
.set VM_GR_15,         0x0f  # 640 X 350, 2 colors 
.set VM_GR_16,         0x10  # 640 X 350, 16 colors 
.set VM_GR_17,         0x11  # 640 X 480, 2 colors 
.set VM_GR_18,         0x12  # 640 X 480, 16 colors 
.set VM_GR_19,         0x13  # 320 X 200, 256 colors 
.set VM_GR_6A,         0x6a  # 800 X 600, 16 colors

# Keyboard function
.set KEYBOARD_WAIT_CHAR,         0x00
.set KEYBOARD_FLAG_STATE,        0x02
.set KEYBOARD_WAIT_EXTEND_CHAR,  0x10
.set KEYBOARD_EXTEND_FLAG_STATE, 0x12

# mouse function
.set MOUSE_INSTALL,     0x00
.set MOUSE_SHOW_CURSOR, 0x01
.set MOUSE_HIDE_CURSOR, 0x02
.set MOUSE_SET_HANDLER, 0x0c


# other
.set TRUE,                   0x00
.set FALSE,                  0x01

.set SUCCESS,                0x00
.set FAIL,                   0x01

# macros

.macro START_PROC
    push   %bp
    movw   %sp, %bp
.endm

.macro END_PROC
    movw   %bp, %sp
    pop    %bp
    ret
.endm

.macro SYS_EXIT
    movb   $DOS_EXIT, %ah
    int    $DOS_SYSCALL
.endm

