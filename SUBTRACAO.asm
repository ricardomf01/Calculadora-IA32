; -------------------------------------------------------------
; subtracao
;   Subtrai dois inteiros de 32 bits usando a instrucao SUB real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX o resultado de a - b.
; -------------------------------------------------------------
section .text
    global subtracao
    global subtracao16

subtracao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]
    sub eax, [ebp+12]

    pop ebp
    ret

; -------------------------------------------------------------
; subtracao16
;   Subtrai dois inteiros de 16 bits usando a instrucao SUB real
;   do IA-32.
;   [ebp+8]  = primeiro numero (a)
;   [ebp+12] = segundo numero (b)
;   Retorna em EAX (sign-extended de AX) o resultado de a - b.
; -------------------------------------------------------------
subtracao16:
    push ebp
    mov ebp, esp
 
    mov ax, [ebp+8]
    sub ax, [ebp+12]       ; SUB de 16 bits (registrador AX)
    movsx eax, ax
 
    pop ebp
    ret
