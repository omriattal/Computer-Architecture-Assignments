all: br

br: main.o
	gcc -m32 -Wall -g main.o -o br

main.o: main.s
	nasm -f elf main.s -o main.o

.PHONY: main

clean: 
	rm -f *.o main
