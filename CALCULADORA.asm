; =============================================================
; CALCULADORA.ASM
;
; Monta:   nasm -f elf32 CALCULADORA.ASM -o CALCULADORA.o
; Linka:   ld -m elf_i386 -o calculadora CALCULADORA.o
; Roda:    ./calculadora
; =============================================================

section .data
    msg_hello       db "Teste 1 - funcao unica de saida e convencao de chamada", 10
    msg_hello_len   equ $ - msg_hello

    msg_ok          db "OK: soma_teste(2,3) retornou 5 em EAX, via parametros na pilha", 10
    msg_ok_len      equ $ - msg_ok

    msg_fail        db "FALHA: o valor retornado em EAX nao e o esperado", 10
    msg_fail_len    equ $ - msg_fail

section .text
    global _start

; -------------------------------------------------------------
; print_string
;   Funcao UNICA de saida de dados de string do programa.
;   Recebe pela pilha:
;     [ebp+8]  -> ponteiro para a string (variavel global)
;     [ebp+12] -> quantidade de bytes a escrever
;   Nao tem retorno.
;
;   Convencao de chamada usada no projeto (cdecl simplificado):
;   o chamador empilha os argumentos da DIREITA para a ESQUERDA,
;   ou seja, para chamar print_string(ptr, tamanho):
;       push tamanho   ; empilhado primeiro -> fica mais "longe" do topo
;       push ptr       ; empilhado por ultimo -> fica no topo -> [ebp+8]
;       call print_string
;       add esp, 8     ; quem chamou e quem limpa a pilha (cdecl)
; -------------------------------------------------------------
print_string:
    push ebp
    mov ebp, esp
    pusha                   ; preserva todos os registradores do chamador

    mov eax, 4               ; syscall sys_write
    mov ebx, 1                ; file descriptor 1 = stdout
    mov ecx, [ebp+8]         ; ponteiro da string
    mov edx, [ebp+12]        ; quantidade de bytes
    int 0x80

    popa
    pop ebp
    ret

; -------------------------------------------------------------
; soma_teste
;   Funcao de teste APENAS da convencao de chamada (nao e a
;   funcao SOMA final do trabalho, que vai morar em SOMA.ASM).
;   Recebe pela pilha:
;     [ebp+8]  -> primeiro inteiro
;     [ebp+12] -> segundo inteiro
;   Retorna a soma em EAX.
; -------------------------------------------------------------
soma_teste:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    add eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
_start:
    ; --- Teste 1: chamar a funcao unica de saida -------------
    push dword msg_hello_len
    push dword msg_hello
    call print_string
    add esp, 8

    ; --- Teste 2: chamar soma_teste(2, 3) e validar EAX ------
    push dword 3
    push dword 2
    call soma_teste
    add esp, 8

    cmp eax, 5
    je .ok
    jmp .fail

.ok:
    push dword msg_ok_len
    push dword msg_ok
    call print_string
    add esp, 8
    jmp .sair

.fail:
    push dword msg_fail_len
    push dword msg_fail
    call print_string
    add esp, 8
    jmp .sair

.sair:
    mov eax, 1                ; syscall sys_exit
    xor ebx, ebx              ; codigo de saida 0
    int 0x80