; head.asm

CODESEG SEGMENT
    ASSUME CS: CODESEG
    PUBLIC PRINT_NUM, PRINT_TAB, PRINT_NEWLINE

;-----------------------------------
; PRINT_NUM
; 输入为 DX:AX，其中 DX 为高 16 位，AX 为低 16 位
; 将寄存器中的数字转换为字符并打印，固定打印宽度为 10
;-----------------------------------
PRINT_NUM PROC
    ; 保存寄存器
    PUSH CX
    PUSH BX
    PUSH SI
    PUSH DI

    ; 设置固定宽度为 10
    MOV DI, 10           ; 固定宽度为 10
    MOV SI, 0            ; 用 SI 计算位数

CONVERT_LOOP:
    MOV CX, 10           ; 除数为 10
    CALL DIVDW           ; 返回的 CX 为余数
    PUSH CX              ; 将余数（即一个数字位）压栈
    INC SI               ; 增加计数器
    ; 判断是否处理完毕
    CMP AX, 0
    JNZ CONVERT_LOOP
    CMP DX, 0
    JNZ CONVERT_LOOP

	; 计算剩余空格数
    MOV BX, DI           ; 将宽度加载到 BX 中
    SUB BX, SI           ; 计算剩余空格数

    ; 打印数字
PRINT_DIGITS:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    DEC SI
    JNZ PRINT_DIGITS
    
    ; 打印剩余空格
PRINT_SPACES:
    CMP BX, 0
    JLE PRINT_DONE       ; 如果不需要空格，跳到结束
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    DEC BX
    JMP PRINT_SPACES

PRINT_DONE:
    ; 恢复寄存器
    POP DI
    POP SI
    POP BX
    POP CX

    RET
PRINT_NUM ENDP

;-----------------------------------
; DIVDW
; 实现 32 位除以 16 位且不会溢出
; 输入为 DX:AX，其中 DX 为高 16 位，AX 为低 16 位, CX为除数
; 返回：DX:结果的高16位 AX:结果的低16位 CX:余数
;-----------------------------------
DIVDW PROC
	PUSH BX	    
	PUSH AX
	;计算第一部分
	MOV AX,DX
	MOV DX,0
	DIV cx
	;计算第二部分
	POP BX
	PUSH AX
	MOV AX, BX
	DIV CX
	MOV CX, DX

	POP DX
	POP BX

    RET
DIVDW ENDP

;-----------------------------------
; PRINT_TAB
; 打印制表符（4 个空格）
;-----------------------------------
PRINT_TAB PROC FAR
    PUSH DX
    PUSH AX

    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    INT 21H
    INT 21H
    INT 21H

    POP AX
    POP DX
    RET
PRINT_TAB ENDP

;-----------------------------------
; PRINT_NEWLINE
; 打印制表符（4 个空格）
;-----------------------------------
PRINT_NEWLINE PROC FAR
    PUSH DX
    PUSH AX

    MOV DL, 13
    MOV AH, 02H
    INT 21H
    MOV DL, 10
    MOV AH, 02H
    INT 21H

    POP AX
    POP DX
    RET
PRINT_NEWLINE ENDP

CODESEG ENDS
    END
