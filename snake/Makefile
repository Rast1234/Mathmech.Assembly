build:
	as -march=i386 -mtune=i8086 --32 main.S -o main.o
	nasm -g -f elf32 nasm_main.asm -o nasm_main.o
	nasm -g -f elf32 utils.asm -o utils.o
	nasm -g -f elf32 video.asm -o video.o
	ld -T libdos/ldcom --oformat binary main.o nasm_main.o utils.o video.o -o snake.com

