build:
	as -march=i386 -mtune=i8086 --32 main.S -o main.o
	for f in *.asm; \
	do \
		filename="$${f%.*}"; \
		#echo $$filename; \
		out=$$filename.o; \
		all="$$all $$out"; \
		nasm -g -f elf32 $$f -o $$out; \
	done; \
	all="main.o $$all"; \
	ld -T libdos/ldcom --oformat binary $$all -o snake.com
