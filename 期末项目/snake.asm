STKSEG SEGMENT
    DB 128 DUP(0)
STKSEG ENDS

DATASEG SEGMENT 
    UP DB 48H
	DOWN DB 50H
	LEFT DB 4BH
	RIGHT DB 4DH
    DIRECTION DW 3      ; 上 0 下 1 左 2 右 3 默认向右

    MAP_COLOR DW 1100H      ; 蓝色边框
    STR_COLOR DB 04H        ; 红字
    SNAKE_COLOR DW 6600H    ; 黄色的蛇
    FOOD_COLOR DW  4400H    ; 红色食物
    SCREEN_COLOR DW 0001H    

    SNAKE DW 200 dup (0,0,0)  ; 三个数是来记录前一个节点，在屏幕上显示的位置，记录下一个点在内存中的相对偏移
    SNAKE_HEAD DW 0           ; 存放蛇头指针
    SNAKE_TAIL DW 12          ; 存放蛇尾指针
    ALLOC_BLOCK DW 18         ; 存放新结点指针

    FOOD DW ?
    SCORE DB 0
    SCORE_STR DB 10 DUP(0)
    IS_DEAD DB 0

    GAME_OVER_MES DB "Game Over!!$"
    SCORE_MES DB "Score = $"
    DIR_MES DB "Direction = $"
DATASEG ENDS

CODESEG SEGMENT
    ASSUME CS: CODESEG, DS: DATASEG, SS:STKSEG
MAIN PROC FAR
    MOV AX, DATASEG
    MOV DS, AX
    CALL CLEAR_SCREEN   ; 清屏
    MOV AX, 0B800H      ; B800H 为 80 * 25 彩色字符模式的显示缓冲区
    MOV ES, AX          ; 映射显存段到 ES，之后不会再动ES了，ES永远是显存
    CALL DRAW_MAP
    CALL DRAW_SNAKE
    CALL GENERATE_FOOD
MAIN_LOOP:
    CALL DELAY
    CALL KEYBOARD_INPUT
    CALL MOVE_SNAKE
    CMP IS_DEAD, 1
    JZ END_GAME
    JMP MAIN_LOOP
END_GAME:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP

; 清屏
CLEAR_SCREEN PROC
    MOV AX, 0600H       ; 清屏功能
    MOV BH, 07H         ; 背景黑色，文本白色
    MOV CX, 0           ; 左上角坐标 (0,0)
    MOV DX, 184FH       ; 右下角坐标 (24,79)
    INT 10H             ; 调用 BIOS 中断清屏
    RET
CLEAR_SCREEN ENDP

DRAW_MAP PROC
    MOV DX, MAP_COLOR   ; DX 中存放颜色
    MOV BX, 0
    MOV CX, 31      ; 一共是 80 * 2 = 160
DRAW_H_LINE:
    MOV ES:[BX + 0], DX    ; 第一行
    MOV ES:[BX + 80*2*23], DX   ; 最后一行
    ADD BX, 02H
    LOOP DRAW_H_LINE
    MOV BX, 0
    MOV CX, 23      ; 画了线的一共有23列
DRAW_V_LINE:
    MOV ES:[BX], DX
    MOV ES:[BX + 30*2], DX
    ADD BX, 0A0H
    LOOP DRAW_V_LINE
    ; 打印分数信息
    MOV SI, OFFSET SCORE_MES
    MOV DH, 24
    MOV DL, 4
    MOV CL, STR_COLOR
    CALL SHOW_STR 
    RET
DRAW_MAP ENDP

DRAW_SNAKE PROC
    MOV BX, OFFSET SNAKE
    ADD BX, 0
    MOV SI, 10*160+10*2
    MOV DX, SNAKE_COLOR
    
    MOV WORD PTR DS:[BX], 0 ;
    MOV DS:[BX+2], SI   ; 存放了位置
    MOV WORD PTR DS:[BX+4], 6   ; 存放后续结点在内存中的偏移量
    MOV ES:[SI], DX

    SUB SI, 2
    ADD BX, 6

    MOV WORD PTR DS:[BX], 0 ;
    MOV DS:[BX+2], SI   ; 存放了位置
    MOV WORD PTR DS:[BX+4], 12   ; 存放后续结点在内存中的偏移量
    MOV ES:[SI], DX

    SUB SI, 2
    ADD BX, 6

    MOV WORD PTR DS:[BX], 6 ;
    MOV DS:[BX+2], SI   ; 存放了位置
    MOV WORD PTR DS:[BX+4], 18   ; 存放后续结点在内存中的偏移量
    MOV ES:[SI], DX
    RET
DRAW_SNAKE ENDP

; 显示字符串，SI 需要指向需要显示的字符串， CL 中需要存放颜色属性, DX 中存放位置（DH 行号，DL 列号）
SHOW_STR PROC
    PUSH CX
    ; 计算显示位置的显存偏移量
    MOV AL, 0A0H        ; A0H = 160, 80 个字符占 160 个字节
    MUL DH              ; 行首地址 = A0H * 行号
    MOV BX, AX
    MOV AL, 02H         ; 一个字符占两个字节
    MUL DL              ; 列偏移地址 = 2 * 列号
    MOV DI, AX
    POP CX
    ; 显示字符串
DO: 
    MOV AL, [SI]        ; 读取 MESSAGE 中的当前字符
    CMP AL, '$'         ; 判断是否为字符串结束符
    JE OK               ; 如果是 '$'，则跳出循环
    MOV ES:[BX+DI], AL  ; 将字符写入显存
    INC DI              ; 指向下一个字节
    MOV ES:[BX+DI], CL  ; 写入颜色属性
    INC DI              ; 指向下一个字节
    INC SI              ; 指向 MESSAGE 中的下一个字符
    JMP DO              ; 循环继续
OK:
    RET
SHOW_STR ENDP

KEYBOARD_INPUT PROC
    MOV AH, 1
    INT 16H     ; 从键盘读入字符
    JZ DIR_RET
    MOV AH,0
    INT 16H
    CMP AH, UP
    JE MOVE_UP
    CMP AH, DOWN
    JE MOVE_DOWN
    CMP AH, LEFT
    JE MOVE_LEFT
    CMP AH, RIGHT
    JE MOVE_RIGHT
    RET
MOVE_UP:
    CMP DIRECTION, 1
    JE DIR_RET
    MOV DIRECTION, 0  
    RET
MOVE_DOWN:
    CMP DIRECTION, 0
    JE DIR_RET
    MOV DIRECTION, 1  
    RET
MOVE_LEFT:
    CMP DIRECTION, 3
    JE DIR_RET
    MOV DIRECTION, 2  ; 设置方向为向左
    RET
MOVE_RIGHT:
    CMP DIRECTION, 2
    JE DIR_RET
    MOV DIRECTION, 3  ; 设置方向为向右
    RET
DIR_RET:
    RET
KEYBOARD_INPUT ENDP

; 一个基于递减的简单延时函数，一点也不精确，只是需要一点延迟
; DELAY PROC
;     ; 延迟代码（通过简单的计数来实现）
;     MOV CX, 50000
; DELAY_LOOP:
;     DEC CX
;     JNZ DELAY_LOOP
;     RET
; DELAY ENDP

DELAY PROC
    PUSH AX
    PUSH DX
    MOV DX, 1H
    XOR AX, AX
DELAYING:
    SUB AX, 1              ; AX -= 1
    SBB DX, 0              ; SBB：带借位减法， 格式：SBB DST,SRC, 执行的操作：（DST）←(DST)-(SRC)-CF,其中CF为进位的值
    CMP AX, 0              ; 比较 AX 和 0
    JNE DELAYING           ; 如果 AX 不等于 0，继续循环
    CMP DX, 0              ; 比较 DX 和 0
    JNE DELAYING           ; 如果 DX 不等于 0，继续循环
    POP DX                 ; 恢复 DX 寄存器的值
    POP AX                 ; 恢复 AX 寄存器的值
    RET                    ; 返回
DELAY ENDP

MOVE_SNAKE PROC
    ; 获取当前蛇的方向
    MOV AX, DIRECTION
    ; 获取蛇头的位置
    MOV BX, OFFSET SNAKE
    ADD BX, SNAKE_HEAD
    MOV SI, DS:[BX+2]

    CMP AX, 0  ; 如果是向上
    JE MOVE_UP_SNAKE
    CMP AX, 1  ; 如果是向下
    JE MOVE_DOWN_SNAKE
    CMP AX, 2  ; 如果是向左
    JE MOVE_LEFT_SNAKE
    CMP AX, 3  ; 如果是向右
    JE MOVE_RIGHT_SNAKE
    RET

MOVE_UP_SNAKE:
    SUB SI, 0A0H
    CALL JUDGE_GAME
    CALL DRAW_NEW_SNAKE
    RET

MOVE_DOWN_SNAKE:
    ADD SI, 0A0H
    CALL JUDGE_GAME
    CALL DRAW_NEW_SNAKE
    RET

MOVE_LEFT_SNAKE:
    SUB SI, 2
    CALL JUDGE_GAME
    CALL DRAW_NEW_SNAKE
    RET

MOVE_RIGHT_SNAKE:
    ADD SI, 2
    CALL JUDGE_GAME
    CALL DRAW_NEW_SNAKE
    RET
MOVE_SNAKE ENDP

; SI 中存放了新出现节点的位置
; 大概就是把最后一个节点（蛇尾）画到新出现的节点那边，然后让该结点成为新的蛇头
DRAW_NEW_SNAKE PROC
    PUSH AX
    CMP IS_DEAD, 1
    JZ NO_DRAW
    MOV BX, OFFSET SNAKE
    ADD BX, SNAKE_HEAD
    MOV AX, SNAKE_TAIL
    MOV DS:[BX+0], AX
    MOV BX, OFFSET SNAKE
    ADD BX, SNAKE_TAIL  ; 处理蛇尾节点
    PUSH DS:[BX+0]      ;
    MOV WORD PTR DS:[BX+0], 0
    MOV DI, DS:[BX+2]
    MOV AX, SCREEN_COLOR
    MOV ES:[DI], AX ; 在屏幕上擦掉蛇尾
    MOV DS:[BX+2], SI ; 蛇尾写入新的位置
    MOV AX, SNAKE_COLOR
    MOV ES:[SI], AX     ; 在屏幕上画出新的蛇头
    MOV AX, SNAKE_HEAD
    MOV DS:[BX+4], AX
    MOV AX, SNAKE_TAIL
    MOV SNAKE_HEAD, AX  ; 现在的蛇头是原先的蛇尾
    POP SNAKE_TAIL  ; 现在的蛇尾是原先蛇尾的下一个结点
NO_DRAW:
    POP AX
    RET
DRAW_NEW_SNAKE ENDP

GENERATE_FOOD PROC
    PUSH SI
    ;生成一个随机数
    MOV AH, 2         ; 读取时间
    INT 1AH           ; 时钟服务中断
    MOV AX, DX        
    MOV CL, 27
    CALL DIVDB        ; AL 中存放了余数
    ADD AL, 2
    MOV CL, 2
    MUL CL
    MOV BH, 0
    MOV BL, AL

    ;生成一个随机数
    MOV AH, 2         
    INT 1AH           
    MOV AX, DX        
    MOV CL, 21
    CALL DIVDB  ; AL 中存放了余数
    ADD AL, 2
    MOV CL, 0A0H
    MUL CL
    ADD AX, BX
    MOV SI, AX
    MOV FOOD, AX
    MOV AX, FOOD_COLOR
    MOV ES:[SI], AX
    POP SI
    RET
GENERATE_FOOD ENDP

; SI 中依旧存储了下一个结点的坐标
JUDGE_GAME PROC
    CMP SI, FOOD
    JNZ RETURN
    CALL EAT_FOOD
    CALL GENERATE_FOOD
    JMP ALIVE
RETURN:
    CMP BYTE PTR ES:[SI], 0
    JNE ALIVE
    CALL DEAD
    RET
ALIVE:
    RET
JUDGE_GAME ENDP

DEAD PROC
    CALL CLEAR_SCREEN
    MOV AX, 0B800H      ; B800H 为 80 * 25 彩色字符模式的显示缓冲区
    MOV ES, AX          ; 映射显存段到 ES，之后不会再动ES了，ES永远是显存
    ; SI 需要指向需要显示的字符串， CL 中需要存放颜色属性, DX 中存放位置（DH 行号，DL 列号）
    MOV DH, 12
    MOV DL, 35
    MOV SI, OFFSET GAME_OVER_MES
    MOV CL, STR_COLOR
    CALL SHOW_STR
    MOV SI, OFFSET SCORE_MES
    MOV DH, 24
    MOV DL, 4
    MOV CL, STR_COLOR
    CALL SHOW_STR 
    CALL PRINT_SCORE
    MOV IS_DEAD, 1
    RET
DEAD ENDP

; SI 中依旧存储了下一个结点的坐标
EAT_FOOD PROC
    PUSH AX 
    MOV BX, OFFSET SNAKE    
	ADD BX, SNAKE_HEAD
    MOV AX, ALLOC_BLOCK     
    MOV DS:[BX+0], AX       ; 头结点连着的结点是新结点，新结点成为新的头结点
    MOV BX, OFFSET SNAKE    
	ADD BX, ALLOC_BLOCK
    MOV WORD PTR DS:[BX+0], 0       ; 新结点没有连着任何结点
    MOV DS:[BX+2], SI               ; 新结点在屏幕上的位置
    MOV AX, SNAKE_COLOR
    MOV ES:[SI], AX                 ; 画出来
    MOV AX, SNAKE_HEAD
    MOV DS:[BX+4], AX               ; 
    MOV AX, ALLOC_BLOCK
    MOV SNAKE_HEAD, AX          ; 蛇头变为新的结点
    ADD ALLOC_BLOCK, 6
    INC SCORE
    CALL PRINT_SCORE
    POP AX
    RET
EAT_FOOD ENDP

; 输入：AX = 被除数, CL = 除数
; 输出：AL = 余数
DIVDB PROC
    MOV CH, 0
DIV_LOOP:
    CMP AX, CX       ; 如果 BX（被除数）小于除数 CL
    JC  DIV_DONE     ; 跳转到除法结束
    SUB AX, CX       ; 被除数减去除数
    JMP DIV_LOOP     ; 重复直到被除数小于除数
DIV_DONE:
    RET
DIVDB ENDP

PRINT_SCORE PROC
    PUSH SI
    MOV AH, 0
    MOV AL, SCORE
    MOV BX, 10
    MOV SI, OFFSET SCORE_STR

CONVERT_LOOP:
    XOR DX, DX      ;清空 DX 寄存器
    DIV BX          ;商位于 AX 寄存器，余数位于 DX 寄存器
    ADD DL, '0'
    MOV [SI], DL
    INC SI
    CMP AX, 0
    JNZ CONVERT_LOOP
    MOV BYTE PTR [SI], '$'
    ; 显示字符串，SI 需要指向需要显示的字符串， CL 中需要存放颜色属性, DX 中存放位置（DH 行号，DL 列号）
    MOV SI, OFFSET SCORE_STR
    MOV DH, 24
    MOV DL, 12
    MOV CL, STR_COLOR
    CALL SHOW_STR

    POP SI
    RET
PRINT_SCORE ENDP


CODESEG ENDS
    END MAIN