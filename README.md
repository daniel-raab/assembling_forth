# Assembling Forth
The goal of this project is to create a forth implementation in Arm Thumb2 assembly for Arm Cortex Microcontrollers.
Probably the STM32F103C8 on the "blue pill" board.

## Running
All things can be done with make.

 - `make build` (or just `make`): build the main.elf from the assembly source
 - `make emulate`: start qemu and load the main.elf. Does not start execution but waits for gdb to connect.
 - `make debug`: start gdb in tui mode and connect to emulation.

Notes:
 - to stop the emulation, use ctrl-x and a

## Done
 - create basic assembly code and compile to binary
 - run with qemu and debug with gdb
 - script for building and running in qemu

## To Do
 - parse numbers: negative, >10
 - execute forth words: DOT creates hardfault: how to get address?

## Resources

 - "8. Semihosting" in *ARM® Compiler toolchain, Version 5.03, Developing Software for ARM Processors*
