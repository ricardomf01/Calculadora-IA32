# Trabalho 2 — Software Básico
## Calculadora em Assembly IA-32

Calculadora de números inteiros com suporte a duas precisões (16 e 32 bits),
implementada inteiramente em Assembly IA-32 (x86 32 bits), usando apenas
chamadas de sistema do Linux (`int 0x80`) — sem uso da biblioteca `IO.MAC`.

Suporta 6 operações: **SOMA, SUBTRAÇÃO, MULTIPLICAÇÃO, DIVISÃO,
EXPONENCIAÇÃO e MOD**, com detecção de overflow (multiplicação e
exponenciação) e tratamento de divisão por zero.

## Sistema operacional utilizado

Linux (testado em **Fedora**), com **NASM** e **LD** (do `binutils`).

## Estrutura do projeto

```
CALCULADORA.asm     # main + funções de I/O (leitura, escrita, conversão)
soma.asm            # operação SOMA (16 e 32 bits)
subtracao.asm       # operação SUBTRACAO (16 e 32 bits)
multiplicacao.asm   # operação MULTIPLICACAO (16 e 32 bits) + overflow
divisao.asm         # operação DIVISAO (16 e 32 bits)
exponenciacao.asm   # operação EXPONENCIACAO (16 e 32 bits) + overflow
mod.asm             # operação MOD (16 e 32 bits)
Makefile            # compila e linka tudo em um único executável
README.md           # este arquivo
```

Cada operação é compilada isoladamente (`nasm`) e depois linkada junto com
`CALCULADORA.asm` (`ld`) em um único executável.

## Como compilar e rodar

**Pré-requisitos:** `nasm` e `ld` instalados (`sudo dnf install nasm binutils` no Fedora).

**Com make (recomendado):**
```bash
make
./calculadora
```

**Manualmente, sem make:**
```bash
nasm -f elf32 -g -F dwarf CALCULADORA.asm  -o CALCULADORA.o
nasm -f elf32 -g -F dwarf soma.asm          -o soma.o
nasm -f elf32 -g -F dwarf subtracao.asm     -o subtracao.o
nasm -f elf32 -g -F dwarf multiplicacao.asm -o multiplicacao.o
nasm -f elf32 -g -F dwarf divisao.asm       -o divisao.o
nasm -f elf32 -g -F dwarf exponenciacao.asm -o exponenciacao.o
nasm -f elf32 -g -F dwarf mod.asm           -o mod.o

ld -m elf_i386 -o calculadora CALCULADORA.o soma.o subtracao.o multiplicacao.o divisao.o exponenciacao.o mod.o

./calculadora
```

**Limpar os arquivos gerados:**
```bash
make clean
```

## Uso

O programa pergunta o nome, a precisão desejada (0 = 16 bits, 1 = 32 bits) e
então mostra um menu em loop com as 6 operações, mais a opção de sair (7).
Cada operação pede dois números inteiros e mostra o resultado.

- Overflow em multiplicação/exponenciação exibe `OCORREU OVERFLOW` e encerra
  o programa.
- Divisão/MOD por zero e expoente negativo mostram um aviso e retornam ao menu.