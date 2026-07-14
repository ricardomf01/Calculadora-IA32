; =============================================================
; exponenciacao.asm

section .text
    global verifica_overflow_exponenciacao
    global exponenciacao
    global verifica_overflow_exponenciacao16
    global exponenciacao16
    global calcula_verifica_overflow_exponenciacao
    global calcula_exponenciacao

; -------------------------------------------------------------
; verifica_overflow_exponenciacao
;   Simula base^expoente multiplicando passo a passo (igual ao
;   que "exponenciacao" vai fazer depois), checando a flag OF do
;   IMUL a cada passo -- para assim que detectar overflow, sem
;   precisar terminar o calculo.
;   [ebp+8]  = base
;   [ebp+12] = expoente (assumido >= 0 -- o chamador ja validou)
;   Retorna em EAX: 1 se ocorrer overflow, 0 caso contrario.
; -------------------------------------------------------------
verifica_overflow_exponenciacao:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    mov ecx, [ebp+12]           ; expoente
    cmp ecx, 0
    jle verifica_exp_sem_overflow   ; expoente 0 -> resultado 1, sem overflow

    mov ebx, [ebp+8]              ; base
    cmp ebx, 0
    je verifica_exp_sem_overflow    ; base 0 (expoente>0) -> resultado 0
    cmp ebx, 1
    je verifica_exp_sem_overflow    ; base 1 -> resultado sempre 1
    cmp ebx, -1
    je verifica_exp_sem_overflow    ; base -1 -> resultado e 1 ou -1

    ; |base| >= 2 a partir daqui -- loop de verdade, com checagem
    mov eax, 1                     ; resultado acumulado = 1

verifica_exp_loop:
    cmp ecx, 0
    jle verifica_exp_sem_overflow   ; terminou sem estourar

    imul eax, ebx
    jo verifica_exp_com_overflow

    dec ecx
    jmp verifica_exp_loop

verifica_exp_com_overflow:
    mov eax, 1
    jmp verifica_exp_fim

verifica_exp_sem_overflow:
    xor eax, eax

verifica_exp_fim:
    pop ecx
    pop ebx
    pop ebp
    ret

; -------------------------------------------------------------
; exponenciacao
;   Calcula base^expoente usando IMUL de 32 bits repetidamente.
;   PRESSUPOE que o chamador ja confirmou, via
;   verifica_overflow_exponenciacao, que o resultado cabe em 32
;   bits, e que o expoente e >= 0.
;   [ebp+8]  = base
;   [ebp+12] = expoente
;   Retorna em EAX o resultado de base^expoente.
; -------------------------------------------------------------
exponenciacao:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    mov eax, 1                     ; resultado = 1 (cobre expoente==0)
    mov ecx, [ebp+12]              ; expoente
    cmp ecx, 0
    jle exp_fim

    mov ebx, [ebp+8]                ; base
    cmp ebx, 0
    je exp_fim_zero                  ; base 0 (expoente>0) -> resultado 0
    cmp ebx, 1
    je exp_fim                       ; base 1 -> resultado fica 1
    cmp ebx, -1
    je exp_calcula_neg1

exp_loop:
    cmp ecx, 0
    jle exp_fim
    imul eax, ebx
    dec ecx
    jmp exp_loop

exp_fim_zero:
    xor eax, eax
    jmp exp_fim

exp_calcula_neg1:
    test ecx, 1
    jz exp_fim                       ; expoente par -> resultado fica 1
    mov eax, -1                       ; expoente impar -> resultado -1

exp_fim:
    pop ecx
    pop ebx
    pop ebp
    ret

; -------------------------------------------------------------
; verifica_overflow_exponenciacao16
;   Mesma ideia de verifica_overflow_exponenciacao, mas usando
;   IMUL de 16 bits (registrador AX) -- a flag OF, nessa forma,
;   ja reflete overflow de 16 bits diretamente.
;   [ebp+8]  = base (so os 16 bits baixos usados)
;   [ebp+12] = expoente (so os 16 bits baixos usados, >= 0)
;   Retorna em EAX: 1 se ocorrer overflow, 0 caso contrario.
; -------------------------------------------------------------
verifica_overflow_exponenciacao16:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    movsx ecx, word [ebp+12]      ; expoente (estendido p/ usar como contador)
    cmp ecx, 0
    jle verifica_exp16_sem_overflow

    movsx ebx, word [ebp+8]        ; base
    cmp ebx, 0
    je verifica_exp16_sem_overflow
    cmp ebx, 1
    je verifica_exp16_sem_overflow
    cmp ebx, -1
    je verifica_exp16_sem_overflow

    mov ax, 1                        ; resultado acumulado (16 bits) = 1

verifica_exp16_loop:
    cmp ecx, 0
    jle verifica_exp16_sem_overflow

    imul ax, bx
    jo verifica_exp16_com_overflow

    dec ecx
    jmp verifica_exp16_loop

verifica_exp16_com_overflow:
    mov eax, 1
    jmp verifica_exp16_fim

verifica_exp16_sem_overflow:
    xor eax, eax

verifica_exp16_fim:
    pop ecx
    pop ebx
    pop ebp
    ret

; -------------------------------------------------------------
; exponenciacao16
;   Calcula base^expoente usando IMUL de 16 bits (registrador
;   AX) repetidamente. PRESSUPOE que o chamador ja confirmou,
;   via verifica_overflow_exponenciacao16, que o resultado cabe
;   em 16 bits, e que o expoente e >= 0.
;   [ebp+8]  = base (so os 16 bits baixos usados)
;   [ebp+12] = expoente (so os 16 bits baixos usados)
;   Retorna em EAX (sign-extended de AX) o resultado.
; -------------------------------------------------------------
exponenciacao16:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    mov ax, 1                        ; resultado (16 bits) = 1
    movsx ecx, word [ebp+12]        ; expoente
    cmp ecx, 0
    jle exp16_fim

    movsx ebx, word [ebp+8]          ; base
    cmp ebx, 0
    je exp16_fim_zero
    cmp ebx, 1
    je exp16_fim
    cmp ebx, -1
    je exp16_calcula_neg1

exp16_loop:
    cmp ecx, 0
    jle exp16_fim
    imul ax, bx
    dec ecx
    jmp exp16_loop

exp16_fim_zero:
    xor ax, ax
    jmp exp16_fim

exp16_calcula_neg1:
    test ecx, 1
    jz exp16_fim
    mov ax, -1

exp16_fim:
    movsx eax, ax

    pop ecx
    pop ebx
    pop ebp
    ret

; -------------------------------------------------------------
; calcula_verifica_overflow_exponenciacao(base, expoente, precisao)
; -> EAX. Escolhe a checagem de 32 ou 16 bits conforme precisao.
; -------------------------------------------------------------
calcula_verifica_overflow_exponenciacao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_overflow_expo_16

    push dword [ebp+12]
    push dword [ebp+8]
    call verifica_overflow_exponenciacao
    add esp, 8
    jmp fim_calcula_overflow_expo

calcula_overflow_expo_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call verifica_overflow_exponenciacao16
    add esp, 8

fim_calcula_overflow_expo:
    pop ebp
    ret

; -------------------------------------------------------------
; calcula_exponenciacao(base, expoente, precisao) -> EAX
; Escolhe exponenciacao ou exponenciacao16 conforme precisao.
; Assume que o chamador ja confirmou, via
; calcula_verifica_overflow_exponenciacao, que nao ha overflow.
; -------------------------------------------------------------
calcula_exponenciacao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_exponenciacao_16

    push dword [ebp+12]
    push dword [ebp+8]
    call exponenciacao
    add esp, 8
    jmp fim_calcula_exponenciacao

calcula_exponenciacao_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call exponenciacao16
    add esp, 8

fim_calcula_exponenciacao:
    pop ebp
    ret