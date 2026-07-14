; =============================================================
; mod.asm

section .text
    global mod
    global mod16
    global calcula_mod

; -------------------------------------------------------------
; mod(a, b) -> EAX = resto de a / b, usando IDIV de 32 bits (o
; resto acompanha o sinal do dividendo, convencao IA-32/estilo C).
; -------------------------------------------------------------
mod:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    cdq
    idiv dword [ebp+12]
    mov eax, edx

    pop ebp
    ret

; -------------------------------------------------------------
; mod16(a, b) -> EAX = resto de a / b, usando IDIV de 16 bits.
; Resultado sign-extended para EAX.
; -------------------------------------------------------------
mod16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    cwd
    idiv word [ebp+12]
    movsx eax, dx

    pop ebp
    ret

; -------------------------------------------------------------
; calcula_mod(a, b, precisao) -> EAX
; Escolhe mod ou mod16 conforme precisao. Assume que o chamador
; ja garantiu b != 0.
; -------------------------------------------------------------
calcula_mod:
    push ebp
    mov ebp, esp

    cmp dword [ebp+16], 0
    je calcula_mod_16

    push dword [ebp+12]
    push dword [ebp+8]
    call mod
    add esp, 8
    jmp fim_calcula_mod

calcula_mod_16:
    push dword [ebp+12]
    push dword [ebp+8]
    call mod16
    add esp, 8

fim_calcula_mod:
    pop ebp
    ret