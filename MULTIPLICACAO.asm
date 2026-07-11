
section .text
    global multiplicacao
    global verifica_overflow_multiplicacao
    global multiplicacao16
    global verifica_overflow_multiplicacao16


; -------------------------------------------------------------
; verifica_overflow_multiplicacao
;   Multiplica a e b apenas para testar a flag OF do IMUL --
;   o resultado numerico em si e descartado aqui (a funcao
;   "multiplicacao" e quem calcula o valor de verdade depois,
;   caso esta funcao confirme que nao ha overflow).
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX: 1 se a*b estoura 32 bits, 0 caso contrario.
; -------------------------------------------------------------
verifica_overflow_multiplicacao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    imul eax, [ebp+12]          ; IMUL r32,r/m32 - seta OF/CF se
                                ; o resultado nao coube em 32 bits
    jo overflow_multiplicacao_detectado

    xor eax, eax                ; sem overflow -> retorna 0
    jmp fim_verifica_overflow_multiplicacao

overflow_multiplicacao_detectado:
    mov eax, 1                   ; com overflow -> retorna 1

fim_verifica_overflow_multiplicacao:
    pop ebp
    ret

; -------------------------------------------------------------
; multiplicacao
;   Multiplica dois inteiros de 32 bits usando a instrucao IMUL
;   real do IA-32. PRESSUPOE que o chamador ja chamou
;   verifica_overflow_multiplicacao antes e confirmou que o
;   resultado cabe em 32 bits.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX o resultado de a * b.
; -------------------------------------------------------------
multiplicacao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    imul eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; verifica_overflow_multiplicacao16
;   Mesma ideia de verifica_overflow_multiplicacao, mas usando o
;   IMUL de 16 bits (registrador AX). A flag OF, nessa forma,
;   reflete overflow de 16 bits diretamente.
;   [ebp+8]  = primeiro numero (a), so os 16 bits baixos usados
;   [ebp+12] = segundo numero (b), so os 16 bits baixos usados
;   Retorna em EAX: 1 se a*b estoura 16 bits, 0 caso contrario.
; -------------------------------------------------------------
verifica_overflow_multiplicacao16:
    push ebp
    mov ebp, esp
 
    mov ax, [ebp+8]
    imul ax, [ebp+12]          ; IMUL AX,r/m16 -- seta OF/CF se
                                 ; o resultado nao coube em 16 bits
    jo overflow_multiplicacao16_detectado
 
    xor eax, eax
    jmp fim_verifica_overflow_multiplicacao16
 
overflow_multiplicacao16_detectado:
    mov eax, 1
 
fim_verifica_overflow_multiplicacao16:
    pop ebp
    ret
 
; -------------------------------------------------------------
; multiplicacao16
;   Multiplica dois inteiros de 16 bits usando IMUL de 16 bits
;   (registrador AX). PRESSUPOE que o chamador ja confirmou, via
;   verifica_overflow_multiplicacao16, que o resultado cabe em
;   16 bits.
;   [ebp+8]  = primeiro numero (a), so os 16 bits baixos usados
;   [ebp+12] = segundo numero (b), so os 16 bits baixos usados
;   Retorna em EAX (sign-extended de AX) o resultado de a * b.
; -------------------------------------------------------------
multiplicacao16:
    push ebp
    mov ebp, esp
 
    mov ax, [ebp+8]
    imul ax, [ebp+12]
    movsx eax, ax
 
    pop ebp
    ret
