; =============================================================
; multiplicacao.asm


section .text
    global multiplicacao
    global verifica_overflow_multiplicacao
    global multiplicacao16
    global verifica_overflow_multiplicacao16
    global calcula_multiplicacao
    global calcula_verifica_overflow_multiplicacao

; -------------------------------------------------------------
; verifica_overflow_multiplicacao(a, b) -> EAX: 1 se a*b estoura
; 32 bits, 0 caso contrario. So testa a flag OF do IMUL; nao
; retorna o produto (isso e feito depois por "multiplicacao").
; -------------------------------------------------------------
verifica_overflow_multiplicacao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    imul eax, [ebp+12]
    jo overflow_multiplicacao_detectado

    xor eax, eax
    jmp fim_verifica_overflow_multiplicacao

overflow_multiplicacao_detectado:
    mov eax, 1

fim_verifica_overflow_multiplicacao:
    pop ebp
    ret

; -------------------------------------------------------------
; multiplicacao(a, b) -> EAX = a * b, usando IMUL de 32 bits.
; Assume que o chamador ja checou overflow antes.
; -------------------------------------------------------------
multiplicacao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    imul eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; verifica_overflow_multiplicacao16(a, b) -> EAX: mesma ideia,
; usando IMUL de 16 bits (AX) -- a flag OF ja reflete overflow
; de 16 bits diretamente.
; -------------------------------------------------------------
verifica_overflow_multiplicacao16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    imul ax, [ebp+12]
    jo overflow_multiplicacao16_detectado

    xor eax, eax
    jmp fim_verifica_overflow_multiplicacao16

overflow_multiplicacao16_detectado:
    mov eax, 1

fim_verifica_overflow_multiplicacao16:
    pop ebp
    ret

; -------------------------------------------------------------
; multiplicacao16(a, b) -> EAX = a * b, usando IMUL de 16 bits
; (AX). Resultado sign-extended de volta para EAX.
; -------------------------------------------------------------
multiplicacao16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    imul ax, [ebp+12]
    movsx eax, ax

    pop ebp
    ret

; -------------------------------------------------------------
; calcula_verifica_overflow_multiplicacao(a, b, precisao) -> EAX
; Escolhe a checagem de overflow de 32 ou 16 bits conforme
; precisao. Unico ponto de entrada usado por CALCULADORA.asm.
; -------------------------------------------------------------
calcula_verifica_overflow_multiplicacao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_overflow_mult_16

    push dword [ebp+12]
    push dword [ebp+8]
    call verifica_overflow_multiplicacao
    add esp, 8
    jmp fim_calcula_overflow_mult

calcula_overflow_mult_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call verifica_overflow_multiplicacao16
    add esp, 8

fim_calcula_overflow_mult:
    pop ebp
    ret

; -------------------------------------------------------------
; calcula_multiplicacao(a, b, precisao) -> EAX
; Escolhe multiplicacao ou multiplicacao16 conforme precisao.
; Assume que o chamador ja confirmou, via
; calcula_verifica_overflow_multiplicacao, que nao ha overflow.
; -------------------------------------------------------------
calcula_multiplicacao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_multiplicacao_16

    push dword [ebp+12]
    push dword [ebp+8]
    call multiplicacao
    add esp, 8
    jmp fim_calcula_multiplicacao

calcula_multiplicacao_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call multiplicacao16
    add esp, 8

fim_calcula_multiplicacao:
    pop ebp
    ret