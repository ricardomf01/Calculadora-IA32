; -------------------------------------------------------------
; soma
;   Soma dois inteiros de 32 bits usando a instrucao ADD real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX o resultado de a + b.
; -------------------------------------------------------------
section .text
    global soma
    global soma16

soma:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    add eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; soma16
;   Soma dois inteiros de 16 bits usando a instrucao ADD real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX (sign-extended de AX) o resultado de a + b.
; -------------------------------------------------------------
soma16:
    push ebp
    mov ebp, esp
 
    mov ax, [ebp+8]
    add ax, [ebp+12]      ; ADD de 16 bits (registrador AX)
    movsx eax, ax         ; estende o sinal de AX (16 bits) para EAX
 
    pop ebp
    ret
