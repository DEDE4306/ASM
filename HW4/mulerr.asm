STKSEG SEGMENT STACK
    DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT
    NUM1 DB 0
    NUM2 DB 0
    RESULT DB 1
    ;9*9表数据
    TABLE   DB 7, 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9             
	        DB 2, 4 , 7 , 8 , 10, 12, 14, 16, 18
	        DB 3, 6 , 9 , 12, 15, 18, 21, 24, 27
	        DB 4, 8 , 12, 16, 7 , 24, 28, 32, 36
	        DB 5, 10, 15, 20, 25, 30, 35, 40, 45
	        DB 6, 12, 18, 24, 30, 7 , 42, 48, 54
	        DB 7, 14, 21, 28, 35, 42, 49, 56, 63
	        DB 8, 16, 24, 32, 40, 48, 56, 7 , 72
	        DB 9, 18, 27, 36, 45, 54, 63, 72, 81
DATASEG ENDS

CODESEG SEGMENT
    ASSUME CS: CODESEG, DS: DATASEG, SS: STKSEG

MAIN PROC FAR
    MOV AX, DATASEG
    MOV DS, AX
    MOV DH, 0
    ;初始化 NUM1
    MOV NUM1, 0
OUTER_LOOP:
    ;初始化 NUM2
    MOV NUM2, 0
INNER_LOOP:
    ;计算 NUM1 * NUM2
    MOV AL, NUM1
    ADD AL, 1
    MOV BL, NUM2
    ADD BL, 1
    MUL BL
    MOV RESULT, AL
    
    MOV DH, 0
    MOV DL, NUM1
    PUSH DX         ;压入 NUM1
    MOV DL, NUM2
    PUSH DX         ;压入 NUM2
    MOV DX, 09H
    PUSH DX         ;压入列数

    ;数组的内容存在了 DL 中
    CALL ARRAY_LOOKUP

    CMP DL, RESULT
    JZ RIGHT_PLACE

    ;打印坐标
    MOV DL, NUM1
    ADD DL, 1
    CALL PRINT_NUM

    MOV DL, ','
    MOV AH, 02H
    INT 21H

    MOV DL, NUM2
    ADD DL, 1
    CALL PRINT_NUM

    MOV DL, 0AH
    MOV AH, 02H
    INT 21H

RIGHT_PLACE:
    INC NUM2
    CMP NUM2, 9
    JNE INNER_LOOP

    INC NUM1
    CMP NUM1, 9
    JNE OUTER_LOOP
    
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

;访问数组中的特定元素
ARRAY_LOOKUP PROC
    MOV BP, SP         ; 基地址指针指向当前栈帧
    MOV AX, [BP+6]     ; NUM1 = [BP+4]
    MOV BX, [BP+4]     ; NUM2 = [BP+6]
    MOV CX, [BP+8]     ; 列数 = [BP+8]

    ; 计算偏移量：AX * 列数 + BX
    MUL CX             ; AX = NUM1 * 列数
    ADD AX, BX         ; AX = NUM1 * 列数 + NUM2

    ; 读取数组的基地址并访问
    LEA SI, TABLE      ; SI = 数组基地址
    MOV BX, SI
    ADD BX, AX
    MOV DL, [BX]       ; DL = table[NUM1][NUM2]

    RET                ; 返回，结果已在 DL 中
ARRAY_LOOKUP ENDP


;将 DX 中的数字转换成字符串打印
PRINT_NUM PROC
    MOV AX, DX
    MOV BX, 10
    MOV SI, 0

CONVERT_LOOP:
    XOR DX, DX      ;清空 DX 寄存器
    DIV BX          ;商位于 AX 寄存器，余数位于 DX 寄存器
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
    
PRINT_NUM ENDP


CODESEG ENDS
    END MAIN