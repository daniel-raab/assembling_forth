AS      := arm-none-eabi-gcc
ASFLAGS := -x assembler-with-cpp -g
LD      := arm-none-eabi-ld
LDFLAGS := -nostartfiles -nostdlib -g

# Rule for assembling .s -> .o files
build: main.s
	$(AS) $(ASFLAGS) -c main.s -o main.o
	$(LD) $(LDFLAGS) -T linkerscript.ld main.o -o main.elf 

.PHONY: clean
clean:
	rm main.o

.PHONY: emulate
emulate :
	qemu-system-arm -cpu cortex-m3 -M netduino2 -semihosting -s -S -nographic -kernel main.elf

.PHONY: debug
debug:
	arm-none-eabi-gdb -q main.elf -tui -ex "target remote localhost:1234" -ex "layout regs"

