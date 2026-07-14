; =============================================================
; divisao.asm

section .text
    global divisao
    global divisao16
    global calcula_divisao

; -------------------------------------------------------------
; divisao(a, b) -> EAX = quociente de a / b, usando IDIV de 32
; bits (EDX:EAX / operando). O resto (em EDX) e descartado.
; -------------------------------------------------------------
divisao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    cdq
    idiv dword [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; divisao16(a, b) -> EAX = quociente de a / b, usando IDIV de 16
; bits (DX:AX / operando). Resultado sign-extended para EAX.
; -------------------------------------------------------------
divisao16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    cwd
    idiv word [ebp+12]
    movsx eax, ax

    pop ebp
    ret

; -------------------------------------------------------------
; calcula_divisao(a, b, precisao) -> EAX
; Escolhe divisao ou divisao16 conforme precisao. Assume que o
; chamador ja garantiu b != 0.
; -------------------------------------------------------------
calcula_divisao:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_divisao_16

    push dword [ebp+12]
    push dword [ebp+8]
    call divisao
    add esp, 8
    jmp fim_calcula_divisao

calcula_divisao_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call divisao16
    add esp, 8

fim_calcula_divisao:
    pop ebp
    ret