STKSEG SEGMENT STACK
DW 32 DUP(0)
STKSEG ENDS
; 堆栈段

DATASEG SEGMENT
	MSG DB "Hello World 20240911$"
DATASEG ENDS

CODESEG SEGMENT
	ASSUME CS:CODESEG,DS:DATASEG
	; 告诉汇编器对应的代码
MAIN PROC FAR
; 申明一个project
	MOV AX,DATASEG 
	MOV DS,AX
	; MOV DS,DATASEG
	; DS 指向数据段
	; 为什么不能用一句话？无法把立即数赋值给段寄存器
	; 无权限直接管理代码放在内存哪里
	MOV AH,9
	; 9号功能：打印字符串
	; 立即数寻址
	MOV DX,OFFSET MSG
	INT 21H
	; 21号中断，中断表
	MOV AX,4C00H
	; 相当于return 0
	INT 21H
MAIN ENDP
CODESEG ENDS
	END MAIN
	; 告诉程序应当结束，同时给出入口点
