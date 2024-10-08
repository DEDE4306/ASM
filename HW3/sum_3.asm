STKSEG SEGMENT STACK
DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT

DATASEG ENDS

CODESEG SEGMENT
    ASSUME DS:DATASEG, CS:CODESEG, SS:STKSEG

MAIN PROC FAR
    MOV AX, DATASEG
    MOV DS, AX
    MOV AX, STKSEG
    MOV SS, AX

    MOV AX, 0
    MOV CX, 100
    PUSH AX

L:
    POP AX
    ADD AX, CX
    PUSH AX
    LOOP L

    POP AX
    CALL PRINT_RESULT      ; 调用打印函数

    MOV AX, 4C00H
    INT 21H

MAIN ENDP

PRINT_RESULT PROC
    MOV BX, 10
    MOV SI, 0

CONVERT_LOOP:
    XOR DX, DX
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC SI
    CMP AX, 0
    JNZ CONVERT_LOOP

PRINT_DIGITS:
    POP DX
    MOV AH, 02H
    INT 21H
    DEC SI
    JNZ PRINT_DIGITS
    RET
    
PRINT_RESUlT ENDP

CODESEG ENDS    

    END MAIN