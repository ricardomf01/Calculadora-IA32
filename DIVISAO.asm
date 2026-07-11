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
section .text
    global divisao
    global divisao16

divisao:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]          ; dividendo
    cdq                       ; estende o sinal: EDX:EAX = sinal-estendido de EAX
    idiv dword [ebp+12]       ; EAX = quociente, EDX = resto

    pop ebp
    ret

; -------------------------------------------------------------
; divisao16
;   Mesma operacao, usando o par DX:AX (16 bits) e IDIV de 16
;   bits. CWD (convert word to doubleword) e o equivalente de
;   16 bits do CDQ -- estende o sinal de AX para DX:AX antes do
;   IDIV, senao dividendos negativos dariam resultado errado.
;   [ebp+8]  = dividendo (a), so os 16 bits baixos usados
;   [ebp+12] = divisor (b), so os 16 bits baixos usados --
;              o chamador garante que b != 0
;   Retorna em EAX (sign-extended de AX) o quociente de a / b.
; -------------------------------------------------------------
divisao16:
    push ebp
    mov ebp, esp
 
    mov ax, [ebp+8]             ; dividendo (16 bits)
    cwd                           ; estende o sinal: DX:AX = sinal-estendido de AX
    idiv word [ebp+12]          ; AX = quociente, DX = resto
    movsx eax, ax
 
    pop ebp
    ret
