STKSEG SEGMENT STACK
DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT
    BUFFER DB 10         ; 最大输入字符数
    DB 0                 ; 实际输入字符数
    DB 10 DUP('$')       ; 输入字符缓冲区
    PROMPT DB 13, 10, 'Please enter a number: $' ; 换行 + 提示信息
    NEWLINE DB 13, 10, '$'  ; 换行字符串
DATASEG ENDS

CODESEG SEGMENT
    ASSUME DS:DATASEG, CS:CODESEG

MAIN PROC FAR
    MOV AX, DATASEG
    MOV DS, AX

    ; 打印换行和用户输入提示
    MOV DX, OFFSET PROMPT
    MOV AH, 09H
    INT 21H

    ; 读取用户输入
    MOV DX, OFFSET BUFFER     ; DX 指向缓冲区
    MOV AH, 0AH       ; 0AH - 读取字符串
    INT 21H           

    ; 换行
    MOV DX, OFFSET NEWLINE    ; DX 指向换行字符
    MOV AH, 09H
    INT 21H            

    LEA DX, BUFFER + 2  ; 跳过长度字节
    MOV AH, 09H
    INT 21H             

    MOV AX, 4C00H
    INT 21H

MAIN ENDP

CODESEG ENDS

END MAIN