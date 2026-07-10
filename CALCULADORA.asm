; =============================================================
; CALCULADORA.asm
; Fase 6: SUBTRACAO, MULTIPLICACAO e DIVISAO ligadas ao menu
; (opcoes 2, 3 e 4), alem da SOMA ja implementada na Fase 5.
;
; MULTIPLICACAO detecta overflow (via flag OF do IMUL, em
; multiplicacao.asm) -- em caso de overflow, mostra "OCORREU
; OVERFLOW" e ENCERRA o programa.
;
; DIVISAO verifica se o divisor e zero ANTES de chamar a funcao
; divisao (que usa IDIV).
;
;
; Monta:   nasm -f elf32 -g -F dwarf CALCULADORA.asm  -o CALCULADORA.o
;          nasm -f elf32 -g -F dwarf soma.asm          -o soma.o
;          nasm -f elf32 -g -F dwarf subtracao.asm     -o subtracao.o
;          nasm -f elf32 -g -F dwarf multiplicacao.asm -o multiplicacao.o
;          nasm -f elf32 -g -F dwarf divisao.asm       -o divisao.o
; Linka:   ld -m elf_i386 -o calculadora CALCULADORA.o soma.o subtracao.o multiplicacao.o divisao.o
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

    msg_precisao        db "Vai trabalhar com 16 ou 32 bits (digite 0 para 16, e 1 para 32):", 10
    msg_precisao_len    equ $ - msg_precisao

    msg_precisao_invalida     db "Valor invalido. Digite 0 (16 bits) ou 1 (32 bits).", 10
    msg_precisao_invalida_len equ $ - msg_precisao_invalida

    ; menu completo em um unico bloco -- continua sendo impresso
    ; por UMA SO chamada a print_string (a funcao unica de saida)
    msg_menu            db "ESCOLHA UMA OPCAO:", 10, \
                           "- 1: SOMA", 10, \
                           "- 2: SUBTRACAO", 10, \
                           "- 3: MULTIPLICACAO", 10, \
                           "- 4: DIVISAO", 10, \
                           "- 5: EXPONENCIACAO", 10, \
                           "- 6: MOD", 10, \
                           "- 7: SAIR", 10
    msg_menu_len        equ $ - msg_menu

    msg_pede_num1       db "Digite o primeiro numero:", 10
    msg_pede_num1_len   equ $ - msg_pede_num1

    msg_pede_num2       db "Digite o segundo numero:", 10
    msg_pede_num2_len   equ $ - msg_pede_num2

    msg_valor1          db "Primeiro numero lido: "
    msg_valor1_len      equ $ - msg_valor1

    msg_valor2          db "Segundo numero lido: "
    msg_valor2_len      equ $ - msg_valor2

    msg_numero_overflow     db "Numero muito grande. Digite um valor entre -2147483648 e 2147483647:", 10
    msg_numero_overflow_len equ $ - msg_numero_overflow

    msg_resultado       db "Resultado: "
    msg_resultado_len   equ $ - msg_resultado

    msg_overflow_mult       db "OCORREU OVERFLOW", 10
    msg_overflow_mult_len   equ $ - msg_overflow_mult

    msg_divisao_zero        db "Nao e possivel dividir por zero. Voltando ao menu.", 10
    msg_divisao_zero_len    equ $ - msg_divisao_zero

    msg_nao_implementado     db "Operacao ainda nao implementada (chega nas proximas fases).", 10
    msg_nao_implementado_len equ $ - msg_nao_implementado

    msg_opcao_invalida       db "Opcao invalida. Tente novamente.", 10
    msg_opcao_invalida_len   equ $ - msg_opcao_invalida

section .bss
    ; "variavel de nome" -- unica das variaveis de dado (nao
    ; ponteiro de mensagem fixa) explicitamente permitida como
    ; global pelo enunciado.
    ; Declaradas "global" para poderem ser inspecionadas pelo
    ; gdb (print/x) e para eventual uso por outros arquivos .asm.
    global nome, precisao, opcao
    nome        resb 64

    ; "variavel de precisao" e "variavel de opcao do menu" --
    ; tambem explicitamente permitidas como globais.
    precisao    resd 1
    opcao       resd 1

section .text
    global _start
    extern soma                              ; funcao definida em soma.asm (Fase 5)
    extern subtracao                         ; funcao definida em subtracao.asm (Fase 6)
    extern multiplicacao                     ; funcao definida em multiplicacao.asm (Fase 6)
    extern verifica_overflow_multiplicacao   ; idem
    extern divisao                           ; funcao definida em divisao.asm (Fase 6)

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
;
;   IMPORTANTE (correcao de bug): se a linha digitada pelo
;   usuario for MAIOR que o buffer pedido, o '\n' final NAO
;   estara dentro do que foi lido aqui -- e os bytes restantes
;   ficariam esperando no stdin, sendo lidos silenciosamente na
;   PROXIMA chamada de read_string (sem o usuario digitar nada
;   naquele momento). Para evitar isso, quando detectamos que o
;   '\n' nao veio dentro do buffer, DRENAMOS (descartamos) o
;   resto da mesma linha aqui dentro, antes de retornar --
;   assim a proxima chamada sempre comeca numa linha nova de
;   verdade, digitada pelo usuario.
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
; converte_digito
;   Converte um caractere ASCII de digito ('0' a '9') no valor
;   inteiro correspondente. Usada tanto para a precisao (0 ou 1)
;   quanto para a opcao do menu (1 a 7).
;   [ebp+8] = ponteiro para o buffer (le apenas o 1o caractere)
;   Retorna em EAX o valor inteiro do digito.
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
; converte_numero32
;   Converte uma string de digitos (com sinal opcional '+'/'-')
;   para o inteiro de 32 bits correspondente.
;   [ebp+8]  = ponteiro da string
;   [ebp+12] = tamanho da string (sem contar o '\n')
;   Retorna em EAX o valor inteiro convertido (com sinal).
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
; verifica_overflow_numero32
;   Percorre a mesma string de digitos que converte_numero32 vai
;   processar, simulando o acumulo (valor = valor*10 + digito) e
;   parando ANTES de multiplicar/somar caso isso fosse estourar a
;   faixa de 32 bits -- sem depender de deteccao de overflow DEPOIS
;   do fato (o que ja teria corrompido o valor por wraparound).
;
;   O limite depende do sinal, pois a faixa de int32 e assimetrica:
;     positivo -> cabe ate 2147483647 (ultimo digito permitido: 7)
;     negativo -> cabe ate 2147483648 em magnitude (ultimo digito
;                 permitido: 8), pois esse e o INT_MIN
;
;   [ebp+8]  = ponteiro da string
;   [ebp+12] = tamanho da string (sem contar o '\n')
;   Retorna em EAX: 1 se houver overflow, 0 caso contrario.
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
; ler_numero32
;   Imprime a mensagem de prompt recebida, le uma linha do teclado
;   e converte para inteiro de 32 bits. Caso o valor digitado
;   estoure a faixa de 32 bits, avisa o usuario e REPETE a mesma
;   pergunta ate receber um valor valido -- mesmo padrao de retry
;   ja usado na pergunta de precisao, em _start.
;   [ebp+8]  = ponteiro da mensagem de prompt (reimpressa a cada
;              tentativa, inclusive apos overflow)
;   [ebp+12] = tamanho da mensagem de prompt
;   Retorna em EAX o valor inteiro lido (ja validado, sem overflow).
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
; imprime_inteiro
;   Converte um inteiro de 32 bits (com sinal) para string
;   decimal e imprime, seguido de uma quebra de linha.
;   Usa a instrucao DIV real do IA-32 para extrair os digitos.
;   [ebp+8] = valor inteiro a imprimir
;   Sem retorno.
; -------------------------------------------------------------
imprime_inteiro:
    push ebp
    mov ebp, esp
    sub esp, 17                 ; buffer local: sinal + 10 digitos + '\n'
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
    ; layout das variaveis locais deste "main":
    ;   [ebp-128 .. ebp-1]   -> buffer local p/ montar a saudacao
    ;   [ebp-132]            -> tamanho do nome lido
    ;   [ebp-140 .. ebp-133] -> buffer local p/ ler um digito
    ;                           (reaproveitado para precisao E
    ;                           para cada opcao do menu no loop)
    ;   [ebp-144]            -> primeiro numero lido (Fase 4)
    ;   [ebp-148]            -> segundo numero lido (Fase 4)
    ;   [ebp-152]            -> resultado da operacao (Fase 5)
    sub esp, 152

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

    ; 5) pergunta a precisao (0 = 16 bits, 1 = 32 bits)
    ;    repete ate receber uma entrada valida de UM SO caractere
pergunta_precisao:
    push dword msg_precisao_len
    push dword msg_precisao
    call print_string
    add esp, 8

    lea eax, [ebp-140]           ; buffer local do digito
    push dword 8
    push eax
    call read_string
    add esp, 8
    ; EAX = quantidade de caracteres realmente lidos (sem o '\n')

    cmp eax, 1                   ; precisa ser EXATAMENTE 1 caractere
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
    mov [precisao], eax          ; guarda na global "precisao"
    jmp fim_precisao

precisao_invalida:
    push dword msg_precisao_invalida_len
    push dword msg_precisao_invalida
    call print_string
    add esp, 8
    jmp pergunta_precisao

fim_precisao:

    ; 6) loop principal do menu
menu_loop:
    push dword msg_menu_len
    push dword msg_menu
    call print_string
    add esp, 8

    lea eax, [ebp-140]           ; reaproveita o buffer local do digito
    push dword 8
    push eax
    call read_string
    add esp, 8
    ; EAX = quantidade de caracteres realmente lidos (sem o '\n')

    cmp eax, 1                   ; precisa ser EXATAMENTE 1 caractere
    jne opcao_invalida          ; ex.: "716" tem 3 chars -> invalida direto,
                                  ; nunca chega a interpretar o '7' isolado

    lea eax, [ebp-140]
    push eax
    call converte_digito
    add esp, 4
    mov [opcao], eax             ; guarda na global "opcao"

    cmp dword [opcao], 7
    je sair_menu

    cmp dword [opcao], 1
    jl opcao_invalida
    cmp dword [opcao], 6
    jg opcao_invalida

    ; opcao valida (1-6) -- por enquanto, testamos ISOLADAMENTE a
    ; leitura/impressao de numeros de 32 bits (Fase 4). As operacoes
    ; reais (SOMA, SUBTRACAO etc.) entram na Fase 5 em diante.
    push dword msg_pede_num1_len
    push dword msg_pede_num1
    call ler_numero32
    add esp, 8
    mov [ebp-144], eax           ; num1

    push dword msg_pede_num2_len
    push dword msg_pede_num2
    call ler_numero32
    add esp, 8
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

    ; dispatch: chama a operacao real quando ja implementada
    cmp dword [opcao], 1
    je faz_soma
    cmp dword [opcao], 2
    je faz_subtracao
    cmp dword [opcao], 3
    je faz_multiplicacao
    cmp dword [opcao], 4
    je faz_divisao

    ; opcoes 5-6 (EXPONENCIACAO, MOD) ainda nao implementadas -- Fase 8
    push dword msg_nao_implementado_len
    push dword msg_nao_implementado
    call print_string
    add esp, 8
    jmp menu_loop

faz_soma:
    push dword [ebp-148]         ; segundo numero (b)
    push dword [ebp-144]         ; primeiro numero (a)
    call soma
    add esp, 8
    mov [ebp-152], eax           ; resultado = a + b
    jmp mostra_resultado

faz_subtracao:
    push dword [ebp-148]         ; b
    push dword [ebp-144]         ; a
    call subtracao
    add esp, 8
    mov [ebp-152], eax           ; resultado = a - b
    jmp mostra_resultado

faz_multiplicacao:
    ; primeiro verifica se a*b estoura 32 bits ANTES de calcular de
    ; verdade -- se estourar, o enunciado pede para mostrar
    ; "OCORREU OVERFLOW" e ENCERRAR o programa (nao apenas voltar
    ; ao menu, diferente dos outros erros deste projeto).
    push dword [ebp-148]
    push dword [ebp-144]
    call verifica_overflow_multiplicacao
    add esp, 8

    cmp eax, 0
    jne overflow_multiplicacao_fatal

    push dword [ebp-148]
    push dword [ebp-144]
    call multiplicacao
    add esp, 8
    mov [ebp-152], eax           ; resultado = a * b
    jmp mostra_resultado

overflow_multiplicacao_fatal:
    push dword msg_overflow_mult_len
    push dword msg_overflow_mult
    call print_string
    add esp, 8
    mov esp, ebp
    pop ebp
    mov eax, 1                    ; syscall sys_exit
    xor ebx, ebx                   ; codigo de saida 0
    int 0x80

faz_divisao:
    ; verifica divisor == 0 ANTES de chamar divisao (que usa IDIV) --
    ; dividir por zero derrubaria o programa (SIGFPE) se nao fosse
    ; checado aqui. O enunciado nao especifica esse caso, entao
    ; optamos por avisar o usuario e voltar ao menu (em vez de
    ; encerrar o programa, que e reservado para overflow).
    cmp dword [ebp-148], 0
    je divisao_por_zero

    push dword [ebp-148]         ; b (divisor)
    push dword [ebp-144]         ; a (dividendo)
    call divisao
    add esp, 8
    mov [ebp-152], eax           ; resultado = a / b
    jmp mostra_resultado

divisao_por_zero:
    push dword msg_divisao_zero_len
    push dword msg_divisao_zero
    call print_string
    add esp, 8
    jmp menu_loop

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