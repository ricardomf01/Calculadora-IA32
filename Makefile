# Makefile - Trabalho 2 (Software Basico)

ASM      = nasm
ASMFLAGS = -f elf32 -g -F dwarf
LD       = ld
LDFLAGS  = -m elf_i386

OBJS = CALCULADORA.o SOMA.o SUBTRACAO.o MULTIPLICACAO.o DIVISAO.o

calculadora: $(OBJS)
	$(LD) $(LDFLAGS) -o calculadora $(OBJS)

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< -o $@

clean:
	rm -f *.o calculadora

.PHONY: clean