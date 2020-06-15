all: drone_game

drone_game: ass3.o drone.o printer.o target.o scheduler.o
	gcc -m32 -Wall -g ass3.o drone.o printer.o target.o scheduler.o -o drone_game.bin

ass3.o: ass3.s
	nasm -f elf ass3.s -o ass3.o

drone.o: drone.s
	nasm -f elf drone.s -o drone.o

printer.o: printer.s
	nasm -f elf printer.s -o printer.o

target.o: target.s
	nasm -f elf target.s -o target.o

scheduler.o: scheduler.s
	nasm -f elf scheduler.s -o scheduler.o
.PHONY: clean

clean:
	rm -f *.o drone_game
