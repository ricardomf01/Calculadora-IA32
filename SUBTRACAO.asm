; =============================================================
; subtracao.asm


section .text
    global subtracao
    global subtracao16
    global calcula_subtracao

; -------------------------------------------------------------
; subtracao(a, b) -> EAX = a - b, usando SUB de 32 bits.
; -------------------------------------------------------------
subtracao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    sub eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; subtracao16(a, b) -> EAX = a - b, usando SUB de 16 bits (AX).
; So os 16 bits baixos de cada parametro sao usados; resultado
; e sign-extended de volta para EAX.
; -------------------------------------------------------------
subtracao16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    sub ax, [ebp+12]
    movsx eax, ax

    pop ebp
    ret

; -------------------------------------------------------------
; calcula_subtracao(a, b, precisao) -> EAX
; Escolhe subtracao ou subtracao16 conforme precisao (0 = 16
; bits, 1 = 32 bits). Unico ponto de entrada usado por
; CALCULADORA.asm.
; -------------------------------------------------------------
calcula_subtracao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_subtracao_16

    push dword [ebp+12]
    push dword [ebp+8]
    call subtracao
    add esp, 8
    jmp fim_calcula_subtracao

calcula_subtracao_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call subtracao16
    add esp, 8

fim_calcula_subtracao:
    pop ebp
    ret