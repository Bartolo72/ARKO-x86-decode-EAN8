decode_ean8: main.c func.asm
	cc -m32 -std=c99 -c main.c
	nasm -f elf32 func.asm
	cc -m32 -o decode_ean8 main.o func.o
	rm main.o func.o
