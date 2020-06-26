#format is target-name: target dependencies
#{-tab-}actions

# All Targets
all: ass3

# Tool invocations
# Executable "hello" depends on the files hello.o and run.o.
ass3:  start.o target.o scheduler.o drone.o printer.o
	gcc -m32 -g -Wall -o ass3 start.o target.o scheduler.o drone.o printer.o -lm

# Depends on the source and header files

start.o: ass3.s
	nasm -f elf ass3.s -o start.o

drone.o: drone.s
	nasm -f elf drone.s -o drone.o

target.o: target.s
	nasm -f elf target.s -o target.o

scheduler.o: scheduler.s
	nasm -f elf scheduler.s -o scheduler.o

printer.o: printer.s
	nasm -f elf printer.s -o printer.o


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o ass3
