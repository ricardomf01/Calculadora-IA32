; =============================================================
; soma.asm

section .text
    global soma
    global soma16
    global calcula_soma

; -------------------------------------------------------------
; soma(a, b) -> EAX = a + b, usando ADD de 32 bits.
; -------------------------------------------------------------
soma:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    add eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; soma16(a, b) -> EAX = a + b, usando ADD de 16 bits (AX).
; So os 16 bits baixos de cada parametro sao usados; resultado
; e sign-extended de volta para EAX.
; -------------------------------------------------------------
soma16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    add ax, [ebp+12]
    movsx eax, ax

    pop ebp
    ret

; -------------------------------------------------------------
; calcula_soma(a, b, precisao) -> EAX
; Escolhe soma ou soma16 conforme precisao (0 = 16 bits, 1 = 32
; bits). Unico ponto de entrada usado pelo CALCULADORA.asm.
; -------------------------------------------------------------
calcula_soma:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_soma_16

    push dword [ebp+12]
    push dword [ebp+8]
    call soma
    add esp, 8
    jmp fim_calcula_soma

calcula_soma_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call soma16
    add esp, 8

fim_calcula_soma:
    pop ebp
    ret