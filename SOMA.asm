
section .text
    global soma

; -------------------------------------------------------------
; soma
;   Soma dois inteiros de 32 bits usando a instrucao ADD real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX o resultado de a + b.
; -------------------------------------------------------------
soma:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    add eax, [ebp+12]

    pop ebp
    ret