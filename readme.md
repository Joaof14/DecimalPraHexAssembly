# ConversorDECparaHEX Decimal para Hexadecimal em Assembly (NASM)

Este programa em Assembly (NASM) para Linux lê um número decimal digitado pelo usuário, converte-o para hexadecimal e exibe o resultado na tela.

## Pré-requisitos
- NASM (Netwide Assembler) instalado
- Sistema Linux (ou WSL, se estiver no Windows)
- Pacote `build-essential` (para o linker `ld`)

## Como compilar e executar

1. **Salve o código** em um arquivo (ex: `conversorDECparaHEX.asm`)

2. **Compile** com o NASM (gerando um objeto ELF64):
   ```bash
   nasm -f elf64 conversorDECparaHEX.asm -o conversorDECparaHEX.o
   ```

3. **Linkar** para gerar o executável:
   ```bash
   ld -m elf_x86_64 conversorDECparaHEX.o -o conversorDECparaHEX
   ```

4. **Execute** o programa:
   ```bash
   ./conversorDECparaHEX
   ```

## Funcionamento do Programa

### Fluxo principal
1. Exibe a mensagem `"Digite um numero decimal: "`
2. Lê a entrada do usuário (como string)
3. Converte a string para um número inteiro (32 bits)
4. Converte o número decimal para hexadecimal
5. Exibe `"Hexadecimal: "` seguido do valor convertido
6. Adiciona uma quebra de linha (`\n`)
7. Encerra o programa

### Seções do Código

### **Seção `.data` (Dados Inicializados)**
```nasm
section .data
    msg_in      db "Digite um numero decimal: ", 0
    len_in      equ $ - msg_in
```
- **`msg_in`**: Define uma string (`db`) que será exibida para pedir ao usuário um número decimal. O `0` no final é um terminador nulo (não usado neste código, pois usamos `len_in`).
- **`len_in`**: Calcula o tamanho da string `msg_in` (subtrai o endereço atual `$` do início da string).

---

```nasm
    msg_out     db "Hexadecimal: ", 0
    len_out     equ $ - msg_out
```
- **`msg_out`**: String que será exibida antes do resultado hexadecimal.
- **`len_out`**: Tamanho da string `msg_out`.

---

```nasm
    hex_chars   db "0123456789ABCDEF"
```
- **`hex_chars`**: Tabela de caracteres hexadecimais (usada para converter valores de 0 a 15 em '0'-'F').

---

### **Seção `.bss` (Dados Não Inicializados)**
```nasm
section .bss
    entrada     resb 16
```
- **`entrada`**: Reserva 16 bytes (`resb`) para armazenar a string digitada pelo usuário.

---

```nasm
    numero      resd 1
```
- **`numero`**: Reserva 4 bytes (`resd`) para armazenar o número decimal convertido (inteiro de 32 bits).

---

```nasm
    resultado   resb 8
```
- **`resultado`**: Reserva 8 bytes para armazenar os dígitos hexadecimais convertidos (cada dígito é 1 byte).

---

```nasm
    tam_hex     resb 1
```
- **`tam_hex`**: Reserva 1 byte para guardar quantos dígitos hexadecimais foram gerados.

---

### **Seção `.text` (Código do Programa)**
```nasm
section .text
    global _start
```
- **`global _start`**: Define o ponto de entrada do programa (`_start`), onde o sistema operacional começa a executar.

---

### **Etapa 1: Exibir mensagem de entrada**
```nasm
_start:
    mov eax, 4          ; sys_write (syscall para escrever)
    mov ebx, 1          ; stdout (saída padrão = tela)
    mov ecx, msg_in     ; endereço da mensagem
    mov edx, len_in     ; tamanho da mensagem
    int 0x80            ; chama o kernel
```
- **`eax = 4`**: Chamada de sistema para escrever (`sys_write`).
- **`ebx = 1`**: Descritor de arquivo para saída padrão (`stdout`).
- **`ecx`**: Aponta para a mensagem `msg_in`.
- **`edx`**: Tamanho da mensagem (`len_in`).
- **`int 0x80`**: Interrupção para chamar o kernel Linux.

---

### **Etapa 2: Ler número digitado pelo usuário**
```nasm
    mov eax, 3          ; sys_read (syscall para ler)
    mov ebx, 0          ; stdin (entrada padrão = teclado)
    mov ecx, entrada    ; buffer para armazenar a entrada
    mov edx, 16         ; tamanho máximo a ser lido
    int 0x80
```
- **`eax = 3`**: Chamada de sistema para ler (`sys_read`).
- **`ebx = 0`**: Descritor de arquivo para entrada padrão (`stdin`).
- **`ecx`**: Aponta para o buffer `entrada`.
- **`edx = 16`**: Máximo de bytes a serem lidos.

---

### **Etapa 3: Converter string para número inteiro**
```nasm
    xor eax, eax        ; Zera EAX (acumulador do número)
    xor ecx, ecx        ; Zera ECX (índice do buffer)
```
- **`xor reg, reg`**: Zera os registradores (mais eficiente que `mov reg, 0`).

---

```nasm
.converte_loop:
    mov bl, [entrada + ecx] ; Lê um caractere do buffer
    cmp bl, 10          ; Compara com '\n' (fim da entrada)
    je .converte_fim    ; Se for '\n', termina
```
- **`[entrada + ecx]`**: Acessa o caractere na posição `ecx` do buffer.
- **`cmp bl, 10`**: Verifica se é o caractere de nova linha (`\n`).

---

```nasm
    sub bl, '0'         ; Converte ASCII para número (ex: '5' → 5)
    imul eax, eax, 10   ; Multiplica EAX por 10 (para avançar casas decimais)
    add eax, ebx        ; Adiciona o dígito atual a EAX
```
- **`sub bl, '0'`**: Converte o caractere ASCII para seu valor numérico.
- **`imul eax, eax, 10`**: Multiplica `eax` por 10 (para tratar cada novo dígito como dezena/centena/etc.).
- **`add eax, ebx`**: Adiciona o dígito atual ao acumulador.

---

```nasm
    inc ecx             ; Incrementa o índice
    jmp .converte_loop  ; Repete o loop
```
- **`inc ecx`**: Avança para o próximo caractere.
- **`jmp .converte_loop`**: Volta ao início do loop.

---

```nasm
.converte_fim:
    mov [numero], eax   ; Armazena o número convertido
```
- Salva o valor convertido (em `eax`) na variável `numero`.

---

### **Etapa 4: Exibir "Hexadecimal: "**
```nasm
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, msg_out    ; "Hexadecimal: "
    mov edx, len_out    ; Tamanho da mensagem
    int 0x80
```
- Similar à Etapa 1, mas exibe `msg_out`.

---

### **Etapa 5: Converter decimal para hexadecimal**
```nasm
    mov eax, [numero]   ; Carrega o número a ser convertido
    mov ecx, 0          ; Zera ECX (contador de dígitos)
```
- **`eax`**: Recebe o número decimal.
- **`ecx`**: Será usado para contar quantos dígitos hex foram gerados.

---

```nasm
.converte_hex:
    mov edx, 0          ; Zera EDX (resto da divisão)
    mov ebx, 16         ; Divisor = 16 (base hexadecimal)
    div ebx             ; Divide EAX por 16: EAX = quociente, EDX = resto
```
- **`div ebx`**: Divide `eax` por 16. O resto (`edx`) é o dígito hexadecimal atual (0 a 15).

---

```nasm
    mov bl, [hex_chars + edx] ; Pega o caractere hexadecimal correspondente
    mov [resultado + ecx], bl ; Armazena no buffer
    inc ecx             ; Incrementa o contador de dígitos
```
- **`hex_chars + edx`**: Acessa o caractere na tabela `hex_chars` (ex: resto 10 → 'A').
- **`[resultado + ecx]`**: Armazena o caractere no buffer.

---

```nasm
    test eax, eax       ; Verifica se EAX == 0
    jnz .converte_hex   ; Se não zero, continua
```
- **`test eax, eax`**: Verifica se ainda há mais dígitos para converter.
- **`jnz`**: Se `eax` não for zero, repete o loop.

---

```nasm
    mov [tam_hex], cl   ; Salva o número de dígitos gerados
```
- **`cl`**: Parte baixa de `ecx` (contém o número de dígitos).

---

### **Etapa 6: Imprimir dígitos hexadecimais (em ordem inversa)**
```nasm
movzx esi, byte [tam_hex] ; Carrega o tamanho em ESI
cmp esi, 0              ; Se não há dígitos, termina
je .fim
dec esi                 ; Começa do último dígito
```
- **`movzx`**: Carrega `tam_hex` (1 byte) em `esi` (32/64 bits), estendendo com zeros.
- **`dec esi`**: Ajusta para começar do último dígito (pois os dígitos foram gerados do menos significativo para o mais significativo).

---

```nasm
.imprime_loop:
    mov al, [resultado + esi] ; Pega o dígito
    mov [resultado + 7], al   ; Copia para uma posição fixa (para impressão)
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, resultado + 7 ; Endereço do dígito
    mov edx, 1          ; Tamanho = 1 byte
    int 0x80
```
- **`[resultado + esi]`**: Acessa o dígito hexadecimal na posição `esi`.
- **`[resultado + 7]`**: Copia o dígito para uma posição fixa (simplifica a chamada `sys_write`).
- Imprime o dígito atual.

---

```nasm
    dec esi             ; Decrementa o índice
    cmp esi, -1         ; Verifica se terminou
    jg .imprime_loop    ; Se não, continua
```
- **`jg`**: Salta se `esi > -1` (ou seja, enquanto `esi >= 0`).

---

### **Quebra de linha**
```nasm
mov byte [resultado], 10 ; Armazena '\n' no buffer
mov eax, 4               ; sys_write
mov ebx, 1               ; stdout
mov ecx, resultado       ; Endereço do '\n'
mov edx, 1               ; Tamanho = 1 byte
int 0x80
```
- **`10`**: Caractere de nova linha (`\n`).
- Imprime a quebra de linha.

---

### **Finalização**
```nasm
.fim:
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; Código de saída 0
    int 0x80
```
- **`eax = 1`**: Chamada de sistema para sair (`sys_exit`).
- **`ebx = 0`**: Código de saída (0 = sucesso).

---

## Exemplo de Uso
```bash
$ ./conversorDECparaHEX
Digite um numero decimal: 42
Hexadecimal: 2A
```

## Observações
- O programa suporta números de até 32 bits (0 a 4294967295)
- A conversão é feita dividindo o número por 16 e usando o resto como índice na tabela `hex_chars`
- Os dígitos hexadecimais são impressos em ordem inversa (do mais significativo para o menos significativo)

## Licença
Este código é de domínio público e foi construído para fins acadêmicos. Sinta-se livre para usá-lo e modificá-lo.
```
