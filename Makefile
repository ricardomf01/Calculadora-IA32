# Makefile - Trabalho 2 (Software Basico)
# Fase 1: apenas CALCULADORA.ASM existe ainda.
# Nas proximas fases, adicione SOMA.o SUBTRACAO.o etc. a OBJS.

ASM      = nasm
ASMFLAGS = -f elf32 -g -F dwarf
LD       = ld
LDFLAGS  = -m elf_i386

OBJS = CALCULADORA.o

calculadora: $(OBJS)
	$(LD) $(LDFLAGS) -o calculadora $(OBJS)

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< -o $@

clean:
	rm -f *.o calculadora

.PHONY: clean