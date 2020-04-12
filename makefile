all: main_task1Assignment1

main_task1Assignment1: main_task1Assignment1.o
	gcc -g -m32 -Wall -o  main_task1Assignment1 main_task1Assignment1.o 

main_task1Assignment1.o: main_task1Assignment1.c
	gcc -g -m32 -Wall -c -o main_task1Assignment1.o main_task1Assignment1.c 

.PHONY: clean

clean: 
	rm -f *.o main_task1Assignment1
