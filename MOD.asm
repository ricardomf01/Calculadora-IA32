; =============================================================
; mod.asm
; 
; Estrutura identica a divisao.asm (mesma instrucao IDIV, mesma
; extensao de sinal via CDQ/CWD) -- Porém, aqui retorna o RESTO 
; (EDX/DX apos o IDIV) em vez do quociente.
; =============================================================

section .text
    global mod
    global mod16

; -------------------------------------------------------------
; mod
;   Calcula o resto de a / b usando IDIV de 32 bits (o resto tem
;   o mesmo sinal do dividendo, seguindo a convencao do IA-32 /
;   estilo C).
;   [ebp+8]  = dividendo (a)
;   [ebp+12] = divisor (b) -- o chamador garante que b != 0
;   Retorna em EAX o resto de a / b.
; -------------------------------------------------------------
mod:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    cdq
    idiv dword [ebp+12]
    mov eax, edx           ; o resto fica em EDX apos o IDIV

    pop ebp
    ret

; -------------------------------------------------------------
; mod16
;   Mesma operacao, usando o par DX:AX (16 bits) e IDIV de 16
;   bits.
;   [ebp+8]  = dividendo (a), so os 16 bits baixos usados
;   [ebp+12] = divisor (b), so os 16 bits baixos usados --
;              o chamador garante que b != 0
;   Retorna em EAX (sign-extended de DX) o resto de a / b.
; -------------------------------------------------------------
mod16:
    push ebp
    mov ebp, esp

    mov ax, [ebp+8]
    cwd
    idiv word [ebp+12]
    movsx eax, dx           ; o resto fica em DX apos o IDIV de 16 bits

    pop ebp
    ret