; salary.asm

STKSEG SEGMENT
    DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT 
    ;以下是表示 21 年的 21 个字符串
    YEARS   DB '1975','1976','1977','1978','1979','1980','1981','1982','1983' 
            DB '1984','1985','1986','1987','1988','1989','1990','1991','1992' 
            DB '1993','1994','1995' 

    ;以下是表示 21 年公司总收入的 21 个 dword 型数据
    INCOMES DD 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514 
            DD 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000 
 
    ;以下是表示 21 年公司雇员人数的 21 个 word 型数据
    EMPLOYEES   DW 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226 
                DW 11542,14430,15257,17800 
DATASEG ENDS

TABLE SEGMENT
    DB 21 DUP('year summ ne ??') 
TABLE ENDS

CODESEG SEGMENT
    ASSUME CS: CODESEG, DS: DATASEG, ES:TABLE
    EXTRN PRINT_NUM: FAR, PRINT_TAB: FAR, PRINT_NEWLINE: FAR

MAIN PROC FAR
    MOV AX, DATASEG
    MOV DS, AX
    MOV AX, TABLE
    MOV ES, AX

    MOV CX, 21              ; 循环次数，21次
    MOV SI, OFFSET YEARS    ; SI 指向年份
    MOV DI, 0               ; DI 指向 TABLE 段的起始位置
; 将年份写入 TABLE 段
LOOP_YEARS:
    ; 写入年份
    MOVSB
    MOVSB
    MOVSB
    MOVSB
    ADD DI, 12              ; 跳到下一个记录的 'year' 字段
    LOOP LOOP_YEARS
    
    MOV CX, 21              ; 循环次数，21次
    MOV SI, OFFSET INCOMES  ; SI 指向收入
    MOV DI, 5               ; DI 指向 TABLE 段的收入位置
; 将收入写入 TABLE 段
LOOP_INCOMES:
    MOV AX, [SI]            ; 将 INCOMES 中的低 16 位加载到 AX
    MOV DX, [SI + 2]        ; 将 INCOMES 中的高 16 位加载到 DX
    MOV ES:[DI], AX         ; 将低 16 位写入 'summ' 的低位
    MOV ES:[DI + 2], DX     ; 将高 16 位写入 'summ' 的高位
    ADD DI, 16              ; 跳到下一个记录的 'summ' 字段
    ADD SI, 4               ; 指向下一个收入值
    LOOP LOOP_INCOMES
    
    MOV CX, 21                  ; 循环次数，21次
    MOV SI, OFFSET EMPLOYEES    ; SI 指向雇员人数
    MOV DI, 10               ; DI 指向 TABLE 雇员人数位置
; 将雇员人数写入 TABLE 段
LOOP_EMPLOYEES:
    MOV AX, [SI]            ; 将 EMPLOYEES 中数据加载到 AX
    MOV ES:[DI], AX         ; 写入 'ne'
    ADD DI, 16              ; 跳到下一个记录的 'ne' 字段
    ADD SI, 2               ; 指向下一个雇员人数
    LOOP LOOP_EMPLOYEES

    MOV CX, 21              ; 循环次数，21次
    MOV BX, 13              ; BX 初始化为 13
    MOV SI, OFFSET INCOMES
    MOV DI, OFFSET EMPLOYEES
; 计算人均收入，并将人均收入写入 TABLE 段
; 由于寄存器不够用，用了一下栈
LOOP_AVERAGE:
    PUSH BX
    MOV AX, [SI]            ; 将 INCOMES 中的低 16 位加载到 AX
    MOV DX, [SI + 2]        ; 将 INCOMES 中的高 16 位加载到 DX
    ADD SI, 4
         
    MOV BX, [DI]            ; 将 EMPLOYEES 中数据加载到 BX
    ADD DI, 2
    DIV BX                  ; 除以 BX                

    POP BX                  ; BX 中存放了接下来要用的 DI 的大小
    PUSH DI                 ; 保存现在 DI 中的内容
    MOV DI, BX              ; 将 BX 中的内容加载入 DI
    MOV ES:[DI], AX         ; 保存结果
    ADD DI, 16              ; 跳到下一个记录
    MOV BX, DI              ; 将 DI 中的内容放入 BX 中保存
    POP DI                  ; 恢复 DI 中的 EMPLOYEES 内容

    LOOP LOOP_AVERAGE


    ; 打印 TABLE 段内容
    MOV BX, 21                 ; 21条记录
    MOV SI, 0                  ; 指向 TABLE 起始位置
    MOV AX, TABLE
    MOV DS, AX                 ; DS 指向 TABLE 段
PRINT_TABLE:
    CALL PRINT_TAB
; 打印年份
    MOV CX, 4
PRINT_CHAR:
    MOV DL, [SI]
    MOV AH, 02H                ; 打印字符
    INT 21H                    
    INC SI
    LOOP PRINT_CHAR
    CALL PRINT_TAB
    CALL PRINT_TAB
    CALL PRINT_TAB

; 打印收入
    INC SI
    MOV AX, [SI]            ; 将 INCOMES 中的低 16 位加载到 AX
    ADD SI, 2               ; 增加 SI
    MOV DX, [SI]            ; 将 INCOMES 中的高 16 位加载到 DX
    ADD SI, 2               ; 增加 SI
    CALL PRINT_NUM
    CALL PRINT_TAB
    CALL PRINT_TAB

; 打印雇员人数
    INC SI
    MOV AX, [SI]            ; 将 EMPLOYEES 中的内容加载到 AX
    MOV DX, 0               ; 清空 DX 中的内容
    ADD SI, 2               ; 增加 SI
    CALL PRINT_NUM
    CALL PRINT_TAB
    CALL PRINT_TAB

; 打印平均工资
    INC SI
    MOV AX, [SI]            ; 将 AVERAGE 中的内容加载到 AX
    MOV DX, 0               ; 清空 DX 中的内容
    ADD SI, 2               ; 增加 SI
    CALL PRINT_NUM
    INC SI
    CALL PRINT_NEWLINE      ; 换行

    DEC BX
    JNZ PRINT_TABLE         ; 循环打印
    ; 结束程序
    MOV AX, 4C00H
    INT 21H                    

MAIN ENDP

CODESEG ENDS
    END MAIN