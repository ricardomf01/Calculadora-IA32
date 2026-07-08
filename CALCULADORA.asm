; =============================================================
; CALCULADORA.asm
; Fase 2: leitura do nome do usuario + mensagem de saudacao.
;
;
; Monta:   nasm -f elf32 -g -F dwarf CALCULADORA.asm -o CALCULADORA.o
; Linka:   ld -m elf_i386 -o calculadora CALCULADORA.o
; Roda:    ./calculadora
; =============================================================

section .data
    msg_pedir_nome      db "Bem-vindo. Digite seu nome:", 10
    msg_pedir_nome_len  equ $ - msg_pedir_nome
 
    ; pedacos fixos da saudacao final -- sao "ponteiros de
    ; mensagem", categoria explicitamente permitida como global
    msg_ola             db "Ola, "
    msg_ola_len         equ $ - msg_ola
 
    msg_bemvindo        db ", bem-vindo ao programa de CALCULADORA IA-32.", 10
    msg_bemvindo_len    equ $ - msg_bemvindo
 
section .bss
    ; "variavel de nome" -- unica das variaveis de dado (nao
    ; ponteiro de mensagem fixa) explicitamente permitida como
    ; global pelo enunciado.
    nome        resb 64
 
section .text
    global _start
 
; -------------------------------------------------------------
; print_string  (sem alteracoes desde a Fase 1)
;   [ebp+8]  = ponteiro da string
;   [ebp+12] = tamanho em bytes
;   sem retorno
; -------------------------------------------------------------
print_string:
    push ebp
    mov ebp, esp
    pusha
 
    mov eax, 4
    mov ebx, 1
    mov ecx, [ebp+8]
    mov edx, [ebp+12]
    int 0x80
 
    popa
    pop ebp
    ret
 
; -------------------------------------------------------------
; read_string
;   Le uma linha do teclado (stdin) para dentro de um buffer.
;   [ebp+8]  = ponteiro do buffer de destino
;   [ebp+12] = tamanho maximo do buffer
;   Retorna em EAX a quantidade de caracteres lidos, SEM contar
;   o '\n' final (se o usuario apertar ENTER, o que e o caso
;   normal ao digitar o nome).
; -------------------------------------------------------------
read_string:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
 
    mov eax, 3              ; syscall sys_read
    xor ebx, ebx             ; file descriptor 0 = stdin
    mov ecx, [ebp+8]        ; buffer de destino
    mov edx, [ebp+12]       ; tamanho maximo
    int 0x80                 ; EAX = bytes efetivamente lidos
 
    ; remove o '\n' final do total contado, se existir
    mov ecx, [ebp+8]
    add ecx, eax
    dec ecx
    cmp byte [ecx], 10
    jne .fim
    dec eax
 
.fim:
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
 
; -------------------------------------------------------------
; copiar_bytes
;   Copia [tamanho] bytes de [origem] para [destino].
;   [ebp+8]  = ponteiro destino
;   [ebp+12] = ponteiro origem
;   [ebp+16] = quantidade de bytes
;   Retorna em EAX o ponteiro destino JA AVANCADO (destino +
;   tamanho) -- assim quem chamou pode encadear varias copias
;   seguidas sem recalcular a posicao manualmente.
; -------------------------------------------------------------
copiar_bytes:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx
 
    mov edi, [ebp+8]
    mov esi, [ebp+12]
    mov ecx, [ebp+16]
    cld
    rep movsb                ; copia ECX bytes de [ESI] para [EDI]
 
    mov eax, edi              ; EDI ja esta em destino+tamanho
 
    pop ecx
    pop edi
    pop esi
    pop ebp
    ret
 
; -------------------------------------------------------------
; monta_saudacao
;   Monta em [destino] a frase "Ola, <nome>, bem-vindo ao
;   programa de CALCULADORA IA-32.\n".
;   [ebp+8]  = ponteiro do buffer de destino (fornecido por quem
;              chamou -- normalmente uma variavel local na pilha
;              de quem chamou, e nao uma global nova)
;   [ebp+12] = ponteiro do nome do usuario
;   [ebp+16] = tamanho do nome
;   Retorna em EAX o tamanho TOTAL da mensagem montada.
; -------------------------------------------------------------
monta_saudacao:
    push ebp
    mov ebp, esp
    sub esp, 4                ; local: ponteiro de escrita atual
 
    mov eax, [ebp+8]
    mov [ebp-4], eax           ; ptr_atual = destino
 
    push dword msg_ola_len
    push dword msg_ola
    push dword [ebp-4]
    call copiar_bytes
    add esp, 12
    mov [ebp-4], eax
 
    push dword [ebp+16]        ; tamanho do nome
    push dword [ebp+12]        ; ponteiro do nome
    push dword [ebp-4]
    call copiar_bytes
    add esp, 12
    mov [ebp-4], eax
 
    push dword msg_bemvindo_len
    push dword msg_bemvindo
    push dword [ebp-4]
    call copiar_bytes
    add esp, 12
    mov [ebp-4], eax
 
    mov eax, [ebp-4]
    sub eax, [ebp+8]           ; tamanho total = ptr_final - ptr_inicial
 
    mov esp, ebp
    pop ebp
    ret
 
; -------------------------------------------------------------
_start:
    push ebp
    mov ebp, esp
    ; layout das variaveis locais deste "main":
    ;   [ebp-128 .. ebp-1] -> buffer local p/ montar a saudacao
    ;   [ebp-132]          -> tamanho do nome lido
    sub esp, 132
 
    ; 1) pergunta o nome
    push dword msg_pedir_nome_len
    push dword msg_pedir_nome
    call print_string
    add esp, 8
 
    ; 2) le o nome (guardado na global "nome", permitida pelo enunciado)
    push dword 64
    push dword nome
    call read_string
    add esp, 8
    mov [ebp-132], eax          ; nome_len = EAX
 
    ; 3) monta a saudacao em um buffer LOCAL (nao cria global nova)
    lea eax, [ebp-128]
    push dword [ebp-132]        ; nome_len
    push dword nome              ; ponteiro do nome
    push eax                     ; ponteiro do buffer local (destino)
    call monta_saudacao
    add esp, 12                  ; EAX = tamanho total da saudacao
 
    ; 4) imprime a saudacao
    push eax                     ; tamanho
    lea eax, [ebp-128]
    push eax                     ; ponteiro do buffer
    call print_string
    add esp, 8
 
    ; 5) por enquanto, encerra aqui -- a Fase 3 substitui isto
    ;    pela pergunta de precisao + o loop do menu
    mov esp, ebp
    pop ebp
    mov eax, 1
    xor ebx, ebx
    int 0x80