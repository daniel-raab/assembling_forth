AS      := arm-none-eabi-as
ASFLAGS := -g
LD      := arm-none-eabi-ld
LDFLAGS := -nostartfiles -nostdlib -g

# Rule for assembling .s -> .o files
build: src/main.s
	$(AS) $(ASFLAGS) -c src/main.s -o src/main.o
	$(LD) $(LDFLAGS) -Ttext 0x00000000 -Tdata 0x20000000 src/main.o -o src/main.elf 

.PHONY: clean
clean:
	rm main.o

.PHONY: emulate
emulate: build
	qemu-system-arm -cpu cortex-m3 -M netduino2 -semihosting -s -S -nographic -kernel src/main.elf

.PHONY: debug
debug: build
	arm-none-eabi-gdb -q src/main.elf -tui -ex "target remote localhost:1234" -ex "layout regs"

