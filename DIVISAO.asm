
section .text
    global divisao

; -------------------------------------------------------------
; divisao
;   Divide dois inteiros de 32 bits usando a instrucao IDIV
;   real do IA-32 (divisao com sinal). IDIV divide EDX:EAX pelo
;   operando de 32 bits, entao e preciso estender o sinal de
;   EAX para EDX antes (instrucao CDQ), senao o resultado fica
;   errado para dividendos negativos.
;   [ebp+8]  = dividendo (a)
;   [ebp+12] = divisor (b)
;   O chamador garante que b != 0
;   Retorna em EAX o quociente inteiro de a / b (o resto, em
;   EDX apos o IDIV, e descartado aqui).
; -------------------------------------------------------------
divisao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]          ; dividendo
    cdq                       ; estende o sinal: EDX:EAX = sinal-estendido de EAX
    idiv dword [ebp+12]       ; EAX = quociente, EDX = resto

    pop ebp
    ret