

section .data
    ; Mensagem que será exibida pedindo ao usuário para digitar um número
    msg_in      db "Digite um numero decimal: ", 0
    len_in      equ $ - msg_in

    ; Mensagem que será exibida antes do resultado em hexadecimal
    msg_out     db "Hexadecimal: ", 0
    len_out     equ $ - msg_out

    ; Tabela com os caracteres correspondentes aos valores hexadecimais
    hex_chars   db "0123456789ABCDEF"

section .bss
    ; Área reservada para armazenar o número digitado (como string)
    entrada     resb 16      

    ; Variável para armazenar o número decimal convertido (inteiro)
    numero      resd 1       

    ; Buffer para armazenar os dígitos hex convertidos (máx 8)
    resultado   resb 8       

    ; Guarda quantos dígitos hex foram gerados
    tam_hex     resb 1       

section .text
    global _start

_start:

    ; === Etapa 1: Exibir mensagem de entrada ===
    mov eax, 4          ; syscall: sys_write
    mov ebx, 1          ; arquivo de saída: stdout (tela)
    mov ecx, msg_in     ; mensagem
    mov edx, len_in     ; tamanho da mensagem
    int 0x80            ; chama o sistema

    ; === Etapa 2: Ler número digitado pelo usuário ===
    mov eax, 3          ; syscall: sys_read
    mov ebx, 0          ; arquivo de entrada: stdin (teclado)
    mov ecx, entrada    ; onde guardar o que foi digitado
    mov edx, 16         ; tamanho máximo
    int 0x80            ; chama o sistema

    ; === Etapa 3: Converter string digitada em número inteiro (decimal) ===
    xor eax, eax        ; zera EAX → vai guardar o resultado numérico
    xor ecx, ecx        ; zera ECX → usado como índice no buffer

.converte_loop:
    mov bl, [entrada + ecx] ; pega o caractere atual
    cmp bl, 10          ; verifica se é '\n' (ENTER = fim da entrada)
    je .converte_fim    ; se for, sai do loop

    sub bl, '0'         ; converte ASCII para número (ex: '5' → 5)
    imul eax, eax, 10   ; multiplica o acumulador por 10 (para avançar a casa decimal)
    add eax, ebx        ; adiciona o dígito atual

    inc ecx             ; passa para o próximo caractere
    jmp .converte_loop  ; repete o loop

.converte_fim:
    mov [numero], eax   ; armazena o número convertido na memória

    ; === Etapa 4: Exibir mensagem "Hexadecimal: " ===
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_out
    mov edx, len_out
    int 0x80

    ; === Etapa 5: Converter número decimal para hexadecimal ===
    mov eax, [numero]   ; carrega o número decimal
    mov ecx, 0          ; índice dos dígitos hex gerados

.converte_hex:
    mov edx, 0          ; zera o resto (necessário para divisão)
    mov ebx, 16         ; divisor = base hexadecimal
    div ebx             ; divide EAX por 16 → quociente em EAX, resto em EDX

    ; EDX contém o valor entre 0 e 15 → índice na tabela hex_chars
    mov bl, [hex_chars + edx] ; pega o caractere correspondente
    mov [resultado + ecx], bl ; guarda no buffer
    inc ecx             ; avança o índice do buffer

    test eax, eax       ; verifica se EAX ficou 0 (fim da conversão?)
    jnz .converte_hex   ; se não, continua dividindo

    ; Salva o número total de caracteres hex convertidos
    mov [tam_hex], cl

    ; === Etapa 6: Imprimir caracteres hex de trás pra frente ===
movzx esi, byte [tam_hex] ; quantos caracteres foram convertidos
cmp esi, 0
je .fim                   ; se zero, pula

dec esi                   ; começa do último índice

.imprime_loop:
    mov al, [resultado + esi]
    mov [resultado + 7], al     ; copiar para posição fixa

    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, resultado + 7      ; caractere atual
    mov edx, 1                  ; tamanho = 1 byte
    int 0x80

    dec esi
    cmp esi, -1
    jg .imprime_loop

; === Etapa 7: quebra de linha ===
mov byte [resultado], 10        ; 10 = '\n' (ASCII para nova linha)
mov eax, 4                      ; sys_write
mov ebx, 1                      ; stdout
mov ecx, resultado              ; endereço do '\n'
mov edx, 1                      ; tamanho = 1 byte
int 0x80

.fim:
    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; código de saída 0
    int 0x80