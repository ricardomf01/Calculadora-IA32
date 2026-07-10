
section .text
    global subtracao

; -------------------------------------------------------------
; subtracao
;   Subtrai dois inteiros de 32 bits usando a instrucao SUB real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX o resultado de a - b.
; -------------------------------------------------------------
subtracao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    sub eax, [ebp+12]

    pop ebp
    ret