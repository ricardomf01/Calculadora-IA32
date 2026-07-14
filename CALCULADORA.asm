; =============================================================
; CALCULADORA.asm
; Programa principal: le nome, precisao (16/32 bits) e opcao do
; menu; contem as funcoes de I/O (leitura/escrita/conversao) e
; despacha para as operacoes reais (SOMA, SUBTRACAO,
; MULTIPLICACAO, DIVISAO, EXPONENCIACAO, MOD).
;
; Convencoes do projeto: parametros sempre pela pilha, retorno
; sempre em EAX. Toda saida de texto passa por print_string.
; Globais permitidas: ponteiros de mensagem, nome, precisao,
; opcao -- todo o resto e local.
;
; Monta:   nasm -f elf32 -g -F dwarf CALCULADORA.asm  -o CALCULADORA.o
;          nasm -f elf32 -g -F dwarf soma.asm          -o soma.o
;          nasm -f elf32 -g -F dwarf subtracao.asm     -o subtracao.o
;          nasm -f elf32 -g -F dwarf multiplicacao.asm -o multiplicacao.o
;          nasm -f elf32 -g -F dwarf divisao.asm       -o divisao.o
;          nasm -f elf32 -g -F dwarf exponenciacao.asm -o exponenciacao.o
;          nasm -f elf32 -g -F dwarf mod.asm           -o mod.o
; Linka:   ld -m elf_i386 -o calculadora CALCULADORA.o soma.o subtracao.o multiplicacao.o divisao.o exponenciacao.o mod.o
; Roda:    ./calculadora
; (ou simplesmente: make)
; =============================================================

section .data
    msg_linha_vazia     db 10
    msg_linha_vazia_len equ $ - msg_linha_vazia

    msg_pedir_nome      db "Bem-vindo. Digite seu nome:", 10
    msg_pedir_nome_len  equ $ - msg_pedir_nome

    msg_ola             db "Ola, "
    msg_ola_len         equ $ - msg_ola

    msg_bemvindo        db ", bem-vindo ao programa de CALCULADORA IA-32.", 10
    msg_bemvindo_len    equ $ - msg_bemvindo

    msg_precisao        db "Vai trabalhar com 16 ou 32 bits (digite 0 para 16, e 1 para 32):", 10
    msg_precisao_len    equ $ - msg_precisao

    msg_precisao_invalida     db "Valor invalido. Digite 0 (16 bits) ou 1 (32 bits).", 10
    msg_precisao_invalida_len equ $ - msg_precisao_invalida

    ; impresso por UMA SO chamada a print_string
    msg_menu            db "ESCOLHA UMA OPCAO:", 10, \
                           "- 1: SOMA", 10, \
                           "- 2: SUBTRACAO", 10, \
                           "- 3: MULTIPLICACAO", 10, \
                           "- 4: DIVISAO", 10, \
                           "- 5: EXPONENCIACAO", 10, \
                           "- 6: MOD", 10, \
                           "- 7: SAIR", 10
    msg_menu_len        equ $ - msg_menu

    msg_pede_num1       db "Digite o primeiro numero (inteiro):", 10
    msg_pede_num1_len   equ $ - msg_pede_num1

    msg_pede_num2       db "Digite o segundo numero (inteiro):", 10
    msg_pede_num2_len   equ $ - msg_pede_num2

    msg_valor1          db "Primeiro numero lido: "
    msg_valor1_len      equ $ - msg_valor1

    msg_valor2          db "Segundo numero lido: "
    msg_valor2_len      equ $ - msg_valor2

    msg_numero_overflow     db "Numero muito grande. Digite um valor entre -2147483648 e 2147483647:", 10
    msg_numero_overflow_len equ $ - msg_numero_overflow

    msg_numero_overflow_16     db "Numero fora da faixa de 16 bits. Digite um valor entre -32768 e 32767:", 10
    msg_numero_overflow_16_len equ $ - msg_numero_overflow_16

    msg_resultado       db "Resultado: "
    msg_resultado_len   equ $ - msg_resultado

    msg_overflow       db "OCORREU OVERFLOW", 10
    msg_overflow_len   equ $ - msg_overflow

    msg_expoente_negativo     db "Expoente deve ser nao-negativo. Voltando ao menu.", 10
    msg_expoente_negativo_len equ $ - msg_expoente_negativo

    msg_divisao_zero        db "Nao e possivel dividir por zero. Voltando ao menu.", 10
    msg_divisao_zero_len    equ $ - msg_divisao_zero

    msg_opcao_invalida       db "Opcao invalida. Tente novamente.", 10
    msg_opcao_invalida_len   equ $ - msg_opcao_invalida

section .bss
    ; Unicas globais alem dos ponteiros de mensagem, conforme
    ; permitido pelo enunciado. Declaradas "global" para serem
    ; inspecionaveis no gdb e acessiveis de outros .asm.
    global nome, precisao, opcao
    nome        resb 64
    precisao    resd 1
    opcao       resd 1

section .text
    global _start
    extern calcula_soma
    extern calcula_subtracao
    extern calcula_multiplicacao
    extern calcula_verifica_overflow_multiplicacao
    extern calcula_divisao
    extern calcula_exponenciacao
    extern calcula_verifica_overflow_exponenciacao
    extern calcula_mod

; -------------------------------------------------------------
; print_string(ptr, tamanho) -- unica funcao de saida do projeto.
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
; read_string(buffer, tamanho_max) -> EAX = chars lidos (sem \n).
; Se a linha digitada for maior que o buffer, o restante ainda
; nao lido fica esperando no stdin -- para evitar que isso vaze
; para a PROXIMA leitura, esta funcao drena (descarta) o resto
; da linha aqui mesmo antes de retornar.
; -------------------------------------------------------------
read_string:
    push ebp
    mov ebp, esp
    sub esp, 20               ; [ebp-16..ebp-1] = buffer de descarte
                                ; [ebp-20]        = contagem original salva
    push ebx
    push ecx
    push edx

    mov eax, 3               ; syscall sys_read
    xor ebx, ebx              ; file descriptor 0 = stdin
    mov ecx, [ebp+8]         ; buffer de destino (do chamador)
    mov edx, [ebp+12]        ; tamanho maximo (do chamador)
    int 0x80                  ; EAX = bytes efetivamente lidos
    mov [ebp-20], eax         ; salva a contagem original

    ; verifica se o '\n' esta dentro do que foi lido
    mov ecx, [ebp+8]
    add ecx, eax
    dec ecx
    cmp byte [ecx], 10
    jne drena_resto_linha_read_string
    dec dword [ebp-20]         ; remove o '\n' da contagem salva
    jmp fim_read_string

drena_resto_linha_read_string:
    ; a linha digitada era maior que o buffer do chamador -- ainda
    ; sobram bytes DESSA MESMA linha esperando no stdin. Descarta
    ; ate encontrar o '\n' que fecha a linha.
loop_drena_linha_read_string:
    mov eax, 3
    xor ebx, ebx
    lea ecx, [ebp-16]          ; buffer de descarte local (nunca devolvido)
    mov edx, 16
    int 0x80                    ; EAX = bytes lidos neste pedaco descartado

    cmp eax, 0
    je fim_read_string          ; seguranca: nada mais para ler (ex.: EOF)

    lea ecx, [ebp-16]
    add ecx, eax
    dec ecx
    cmp byte [ecx], 10
    je fim_read_string          ; achou o fim da linha -> pode parar de descartar

    jmp loop_drena_linha_read_string  ; ainda sobrou mais da mesma linha

fim_read_string:
    mov eax, [ebp-20]           ; recupera a contagem original (ja ajustada)

    pop edx
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
; copiar_bytes(destino, origem, tamanho) -> EAX = destino+tamanho
; (permite encadear copias sem recalcular a posicao).
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
; monta_saudacao(destino, nome_ptr, nome_len) -> EAX = tamanho
; total. Monta "Ola, <nome>, bem-vindo ao programa de
; CALCULADORA IA-32.\n" no buffer destino (fornecido pelo
; chamador -- geralmente uma variavel local, nao uma global).
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
; converte_digito(ptr) -> EAX = valor inteiro do 1o caractere.
; -------------------------------------------------------------
converte_digito:
    push ebp
    mov ebp, esp

    mov ecx, [ebp+8]
    movzx eax, byte [ecx]
    sub eax, '0'

    pop ebp
    ret

; -------------------------------------------------------------
; converte_numero32(ptr, tamanho) -> EAX = inteiro convertido
; (aceita sinal opcional '+'/'-').
; -------------------------------------------------------------
converte_numero32:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]         ; ponteiro da string
    mov ecx, [ebp+12]        ; tamanho da string
    xor edi, edi              ; indice atual = 0
    mov ebx, 1                 ; sinal = 1 (positivo)
    xor eax, eax               ; valor acumulado = 0

    cmp ecx, 0
    je fim_converte_numero32   ; string vazia -> retorna 0

    mov dl, [esi]               ; primeiro caractere
    cmp dl, '-'
    jne checa_mais_numero32
    mov ebx, -1                 ; sinal negativo
    inc edi
    jmp loop_digitos_numero32

checa_mais_numero32:
    cmp dl, '+'
    jne loop_digitos_numero32
    inc edi                     ; apenas pula o '+', sinal continua 1

loop_digitos_numero32:
    cmp edi, ecx
    jge aplica_sinal_numero32

    movzx edx, byte [esi+edi]
    sub edx, '0'
    imul eax, eax, 10           ; valor = valor * 10
    add eax, edx                ; valor += digito
    inc edi
    jmp loop_digitos_numero32

aplica_sinal_numero32:
    imul eax, ebx                ; valor = valor * sinal

fim_converte_numero32:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; -------------------------------------------------------------
; verifica_overflow_numero32(ptr, tamanho) -> EAX: 1 se a string
; estoura 32 bits, 0 caso contrario. Checa ANTES de multiplicar/
; somar (nao detecta depois, quando ja teria corrompido o valor).
; Limite assimetrico: positivo ate 2147483647 (ultimo digito 7),
; negativo ate 2147483648 em magnitude (ultimo digito 8, o INT_MIN).
; -------------------------------------------------------------
verifica_overflow_numero32:
    push ebp
    mov ebp, esp
    sub esp, 4                  ; local: ultimo digito permitido (7 ou 8)
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]            ; ponteiro da string
    mov ecx, [ebp+12]           ; tamanho da string
    xor edi, edi                 ; indice atual = 0
    mov ebx, 1                    ; sinal = 1 (positivo)
    xor eax, eax                  ; acumulador simulado = 0

    cmp ecx, 0
    je verifica_sem_overflow      ; string vazia -> sem overflow

    mov dl, [esi]
    cmp dl, '-'
    jne verifica_checa_mais_sinal
    mov ebx, -1
    inc edi
    jmp verifica_define_limite

verifica_checa_mais_sinal:
    cmp dl, '+'
    jne verifica_define_limite
    inc edi

verifica_define_limite:
    mov dword [ebp-4], 7          ; positivo -> ultimo digito permitido = 7
    cmp ebx, -1
    jne verifica_loop_overflow
    mov dword [ebp-4], 8          ; negativo -> ultimo digito permitido = 8

verifica_loop_overflow:
    cmp edi, ecx
    jge verifica_sem_overflow      ; percorreu a string inteira sem estourar

    movzx edx, byte [esi+edi]
    sub edx, '0'

    cmp eax, 214748364              ; quociente do limite (igual p/ ambos os sinais)
    ja verifica_com_overflow
    jne verifica_avanca_overflow
    cmp edx, [ebp-4]                ; empatou no quociente -> so cabe se digito <= limite
    jg verifica_com_overflow

verifica_avanca_overflow:
    imul eax, eax, 10
    add eax, edx
    inc edi
    jmp verifica_loop_overflow

verifica_com_overflow:
    mov eax, 1                       ; retorna 1 (overflow detectado)
    jmp verifica_fim_overflow

verifica_sem_overflow:
    xor eax, eax                      ; retorna 0 (sem overflow)

verifica_fim_overflow:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
; ler_numero32(msg_ptr, msg_len) -> EAX = valor lido (32 bits).
; Imprime o prompt, le, converte; se estourar 32 bits, avisa e
; repete a mesma pergunta ate receber um valor valido.
; -------------------------------------------------------------
ler_numero32:
    push ebp
    mov ebp, esp
    ; layout local: [ebp-16..ebp-1] buffer de digitos (16 bytes)
    ;               [ebp-20]        tamanho realmente lido
    sub esp, 20

tenta_ler_numero32:
    push dword [ebp+12]           ; tamanho da mensagem de prompt
    push dword [ebp+8]            ; ponteiro da mensagem de prompt
    call print_string
    add esp, 8

    lea eax, [ebp-16]
    push dword 16
    push eax
    call read_string
    add esp, 8
    mov [ebp-20], eax             ; tamanho realmente lido

    push dword [ebp-20]
    lea eax, [ebp-16]
    push eax
    call verifica_overflow_numero32
    add esp, 8

    cmp eax, 0
    je numero32_sem_overflow

    push dword msg_numero_overflow_len
    push dword msg_numero_overflow
    call print_string
    add esp, 8
    jmp tenta_ler_numero32          ; repete a MESMA pergunta original

numero32_sem_overflow:
    push dword [ebp-20]
    lea eax, [ebp-16]
    push eax
    call converte_numero32
    add esp, 8
    ; EAX = valor inteiro convertido (ja garantidamente sem overflow)

    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
; verifica_overflow_numero16(ptr, tamanho) -> EAX: igual a
; verifica_overflow_numero32, mas com limites de 16 bits
; (positivo ate 32767, negativo ate 32768 em magnitude).
; -------------------------------------------------------------
verifica_overflow_numero16:
    push ebp
    mov ebp, esp
    sub esp, 4                  ; local: ultimo digito permitido (7 ou 8)
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]
    mov ecx, [ebp+12]
    xor edi, edi
    mov ebx, 1
    xor eax, eax

    cmp ecx, 0
    je verifica16_sem_overflow

    mov dl, [esi]
    cmp dl, '-'
    jne verifica16_checa_mais_sinal
    mov ebx, -1
    inc edi
    jmp verifica16_define_limite

verifica16_checa_mais_sinal:
    cmp dl, '+'
    jne verifica16_define_limite
    inc edi

verifica16_define_limite:
    mov dword [ebp-4], 7          ; positivo -> limite 32767 -> ultimo digito 7
    cmp ebx, -1
    jne verifica16_loop_overflow
    mov dword [ebp-4], 8          ; negativo -> limite 32768 -> ultimo digito 8

verifica16_loop_overflow:
    cmp edi, ecx
    jge verifica16_sem_overflow

    movzx edx, byte [esi+edi]
    sub edx, '0'

    cmp eax, 3276                  ; quociente do limite (32767/10 = 32768/10 = 3276)
    ja verifica16_com_overflow
    jne verifica16_avanca_overflow
    cmp edx, [ebp-4]
    jg verifica16_com_overflow

verifica16_avanca_overflow:
    imul eax, eax, 10
    add eax, edx
    inc edi
    jmp verifica16_loop_overflow

verifica16_com_overflow:
    mov eax, 1
    jmp verifica16_fim_overflow

verifica16_sem_overflow:
    xor eax, eax

verifica16_fim_overflow:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
; ler_numero16(msg_ptr, msg_len) -> EAX = valor lido (16 bits).
; Igual a ler_numero32, validando a faixa de 16 bits. Reaproveita
; converte_numero32 para o parsing (so a faixa aceita difere).
; -------------------------------------------------------------
ler_numero16:
    push ebp
    mov ebp, esp
    sub esp, 20                  ; mesmo layout de ler_numero32

tenta_ler_numero16:
    push dword [ebp+12]
    push dword [ebp+8]
    call print_string
    add esp, 8

    lea eax, [ebp-16]
    push dword 16
    push eax
    call read_string
    add esp, 8
    mov [ebp-20], eax

    push dword [ebp-20]
    lea eax, [ebp-16]
    push eax
    call verifica_overflow_numero16
    add esp, 8

    cmp eax, 0
    je numero16_sem_overflow

    push dword msg_numero_overflow_16_len
    push dword msg_numero_overflow_16
    call print_string
    add esp, 8
    jmp tenta_ler_numero16

numero16_sem_overflow:
    push dword [ebp-20]
    lea eax, [ebp-16]
    push eax
    call converte_numero32
    add esp, 8

    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
; ler_numero(msg_ptr, msg_len, precisao) -> EAX
; Escolhe ler_numero32 ou ler_numero16 conforme precisao (0 =
; 16 bits, 1 = 32 bits). Unico ponto de leitura de numero usado
; em _start.
; -------------------------------------------------------------
ler_numero:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je ler_numero_16bits

    push dword [ebp+12]
    push dword [ebp+8]
    call ler_numero32
    add esp, 8
    jmp fim_ler_numero

ler_numero_16bits:
    push dword [ebp+12]
    push dword [ebp+8]
    call ler_numero16
    add esp, 8

fim_ler_numero:
    pop ebp
    ret

; -------------------------------------------------------------
; imprime_inteiro(valor) -- converte para string decimal (com
; sinal) e imprime, usando DIV real do IA-32.
; -------------------------------------------------------------
imprime_inteiro:
    push ebp
    mov ebp, esp
    sub esp, 17                  ; buffer local: sinal + 10 digitos + '\n'
                                  ; ocupa [ebp-17 .. ebp-1] -- alocado
                                  ; ANTES dos push abaixo, para nao
                                  ; sobrepor os registradores salvos
    push ebx
    push esi
    push edi

    mov byte [ebp-1], 10         ; ultimo byte do buffer = '\n' (fixo)
    lea edi, [ebp-2]             ; posicao de escrita, logo antes do '\n'

    mov eax, [ebp+8]             ; valor a converter
    mov ebx, 1                    ; sinal positivo = 1
    cmp eax, 0
    jge numero_nao_negativo
    mov ebx, 0                    ; sinal negativo = 0
    neg eax                       ; trabalha com o valor absoluto
numero_nao_negativo:

    cmp eax, 0
    jne loop_extrai_digitos
    mov byte [edi], '0'           ; caso especial: valor == 0
    dec edi
    jmp fim_extrai_digitos

loop_extrai_digitos:
    cmp eax, 0
    je fim_extrai_digitos
    xor edx, edx
    mov esi, 10
    div esi                       ; EAX = EAX/10 , EDX = EAX%10 (DIV real)
    add edx, '0'
    mov byte [edi], dl
    dec edi
    jmp loop_extrai_digitos

fim_extrai_digitos:
    cmp ebx, 0
    jne pula_sinal_negativo
    mov byte [edi], '-'
    dec edi
pula_sinal_negativo:

    ; a string valida comeca em (edi+1) e termina em (ebp-1), com \n incluso
    lea eax, [ebp-1]
    sub eax, edi                  ; tamanho = (ebp-1) - edi
    lea ecx, [edi+1]              ; ponteiro para o inicio da string

    push eax                      ; tamanho
    push ecx                      ; ponteiro
    call print_string
    add esp, 8

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; -------------------------------------------------------------
_start:
    push ebp
    mov ebp, esp
    ; locais: [ebp-128..-1] buffer saudacao | [ebp-132] nome_len |
    ; [ebp-140..-133] buffer de digito (reaproveitado) |
    ; [ebp-144] num1 | [ebp-148] num2 | [ebp-152] resultado
    sub esp, 152

    ; nome
    push dword msg_pedir_nome_len
    push dword msg_pedir_nome
    call print_string
    add esp, 8

    push dword 64
    push dword nome
    call read_string
    add esp, 8
    mov [ebp-132], eax          ; nome_len

    ; saudacao (buffer local, nao cria global nova)
    lea eax, [ebp-128]
    push dword [ebp-132]
    push dword nome
    push eax
    call monta_saudacao
    add esp, 12

    push eax
    lea eax, [ebp-128]
    push eax
    call print_string
    add esp, 8

    push dword msg_linha_vazia_len
    push dword msg_linha_vazia
    call print_string
    add esp, 8

    ; precisao (repete ate um digito valido 0/1)
pergunta_precisao:
    push dword msg_precisao_len
    push dword msg_precisao
    call print_string
    add esp, 8

    lea eax, [ebp-140]
    push dword 8
    push eax
    call read_string
    add esp, 8

    cmp eax, 1                   ; precisa ser exatamente 1 caractere
    jne precisao_invalida

    lea eax, [ebp-140]
    push eax
    call converte_digito
    add esp, 4

    cmp eax, 0
    je precisao_valida
    cmp eax, 1
    je precisao_valida
    jmp precisao_invalida

precisao_valida:
    mov [precisao], eax
    jmp fim_precisao

precisao_invalida:
    push dword msg_precisao_invalida_len
    push dword msg_precisao_invalida
    call print_string
    add esp, 8
    jmp pergunta_precisao

fim_precisao:

    ; loop principal do menu
menu_loop:
    push dword msg_linha_vazia_len
    push dword msg_linha_vazia
    call print_string
    add esp, 8

    push dword msg_menu_len
    push dword msg_menu
    call print_string
    add esp, 8

    lea eax, [ebp-140]
    push dword 8
    push eax
    call read_string
    add esp, 8

    cmp eax, 1                   ; precisa ser exatamente 1 caractere
    jne opcao_invalida

    lea eax, [ebp-140]
    push eax
    call converte_digito
    add esp, 4
    mov [opcao], eax

    cmp dword [opcao], 7
    je sair_menu

    cmp dword [opcao], 1
    jl opcao_invalida
    cmp dword [opcao], 6
    jg opcao_invalida

    ; opcao valida (1-6) -- le os dois numeros na precisao escolhida
    push dword [precisao]
    push dword msg_pede_num1_len
    push dword msg_pede_num1
    call ler_numero
    add esp, 12
    mov [ebp-144], eax           ; num1

    push dword [precisao]
    push dword msg_pede_num2_len
    push dword msg_pede_num2
    call ler_numero
    add esp, 12
    mov [ebp-148], eax           ; num2

    push dword msg_valor1_len
    push dword msg_valor1
    call print_string
    add esp, 8

    push dword [ebp-144]
    call imprime_inteiro
    add esp, 4

    push dword msg_valor2_len
    push dword msg_valor2
    call print_string
    add esp, 8

    push dword [ebp-148]
    call imprime_inteiro
    add esp, 4

    ; dispatch: chama a operacao real
    cmp dword [opcao], 1
    je faz_soma
    cmp dword [opcao], 2
    je faz_subtracao
    cmp dword [opcao], 3
    je faz_multiplicacao
    cmp dword [opcao], 4
    je faz_divisao
    cmp dword [opcao], 5
    je faz_exponenciacao
    cmp dword [opcao], 6
    je faz_mod

    ; nunca deveria chegar aqui -- opcao ja validada entre 1 e 6
    ; antes deste ponto (ver cmp/jl/jg logo apos o menu_loop)
    jmp opcao_invalida

faz_soma:
    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_soma
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

faz_subtracao:
    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_subtracao
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

faz_multiplicacao:
    ; overflow em multiplicacao mostra "OCORREU OVERFLOW" e
    ; ENCERRA o programa (unico erro deste projeto que nao volta
    ; ao menu -- exigencia do enunciado).
    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_verifica_overflow_multiplicacao
    add esp, 12
    cmp eax, 0
    jne overflow_fatal

    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_multiplicacao
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

overflow_fatal:
    push dword msg_overflow_len
    push dword msg_overflow
    call print_string
    add esp, 8
    mov esp, ebp
    pop ebp
    mov eax, 1
    xor ebx, ebx
    int 0x80

faz_divisao:
    ; IDIV por zero derruba o programa (SIGFPE) -- checa antes.
    cmp dword [ebp-148], 0
    je divisao_por_zero

    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_divisao
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

divisao_por_zero:
    push dword msg_divisao_zero_len
    push dword msg_divisao_zero
    call print_string
    add esp, 8
    jmp menu_loop

faz_exponenciacao:
    ; segundo numero = expoente; negativo nao produz inteiro.
    cmp dword [ebp-148], 0
    jl expoente_negativo

    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_verifica_overflow_exponenciacao
    add esp, 12
    cmp eax, 0
    jne overflow_fatal

    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_exponenciacao
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

expoente_negativo:
    push dword msg_expoente_negativo_len
    push dword msg_expoente_negativo
    call print_string
    add esp, 8
    jmp menu_loop

faz_mod:
    cmp dword [ebp-148], 0
    je divisao_por_zero

    push dword [precisao]
    push dword [ebp-148]
    push dword [ebp-144]
    call calcula_mod
    add esp, 12
    mov [ebp-152], eax
    jmp mostra_resultado

mostra_resultado:
    push dword msg_resultado_len
    push dword msg_resultado
    call print_string
    add esp, 8

    push dword [ebp-152]
    call imprime_inteiro
    add esp, 4

    jmp menu_loop

opcao_invalida:
    push dword msg_opcao_invalida_len
    push dword msg_opcao_invalida
    call print_string
    add esp, 8
    jmp menu_loop

sair_menu:
    ; 7) encerra o programa
    mov esp, ebp
    pop ebp
    mov eax, 1
    xor ebx, ebx
    int 0x80