.386
.MODEL  FLAT, STDCALL
EXTERN  GetStdHandle@4    :	PROC ; Получение дескриптора.
EXTERN  WriteConsoleA@20  :	PROC ; Вывод в консоль.
EXTERN  CharToOemA@8      :	PROC ; Строку в OEM кодировку.
EXTERN  ReadConsoleA@20   :	PROC ; Ввод с консоли.
EXTERN  ExitProcess@4     :	PROC ; Функция выхода из программы.
EXTERN  lstrlenA@4        : PROC ; Функция определения длины строки.

.DATA	
	STR1 DB "Введите первое число, а затем второе в десятичной системе: ", 10, 0		
	STR2 DB "Результат умножения в шестнадцатеричной системе: ", 0
	STR_ERR DB "Ошибка. Нужно не менее 4-х знаков и не более 8-ми знаков", 0	

	DIN		DD ?		      ; Дескриптор ввода, 4 байта. (директива dd резервирует память объемом 32 бита (4 байта))
	DOUT	DD ?		      ; Дескриптор вывода, 4 байта.
	BUF		DB 200 dup (?)    ; Буфер для строк длиной 200 байт.
	LENS	DD ?		      ; Для количества выведенных символов.
	FIRST	DD 0
	SECOND	DD 0
	S_16	DD 16
	F_SIGN	DB 0
	S_SIGN	DB 0
	SIGN    DB 0
	
.CODE 
	START proc

	; Перекодировка STR1.
	MOV EAX, OFFSET STR1
	PUSH EAX						
	PUSH EAX
	CALL CharToOemA@8

	; Перекодировка STR2.
	MOV EAX, OFFSET STR2
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; Перекодировка STR_ERR.
	MOV EAX, OFFSET STR_ERR
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; Помещаем декриптор ввода в DIN.
	PUSH -10						
	CALL GetStdHandle@4 
	MOV DIN, EAX

	; Помещаем декриптор вывода в DOUT.
	PUSH -11
	CALL GetStdHandle@4
	MOV DOUT, EAX

	; Выводим строки на экран консоли.
	PUSH OFFSET STR1
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR1.
	PUSH 0					   ; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				   ; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET STR1		; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20


	; Ввод первого числа.
	PUSH 0					; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количества символов). 
	PUSH 200				   ; Помещаем 3-й аргумент в стек (максимальное количество символов).
	PUSH OFFSET BUF		; Помещаем 2-й аргумент в стек (адрес начала строки для ввода).
	PUSH DIN				   ; Помещаем 1-й аргумент в стек (дескриптор ввода).
	CALL ReadConsoleA@20			

	; Перевод из строки в первое число, а также проверка.
	PUSH OFFSET BUF
	SUB LENS, 2  ; Определяем длину строки без управляющих символов.
    CMP LENS, 1 ; Число должно содержать не меньше 4 знаков.
	JB ERROR
	CMP LENS, 6  ; Число должно содержать не больше 8 знаков.
	JA ERROR
	MOV ECX, LENS 
	MOV ESI, OFFSET BUF
	XOR EBX, EBX
	XOR EAX, EAX

	; Проверяем, отрицательно ли первое число.
	MOV BL, [ESI]						
	CMP BL, '-'
	JNE CONVERT_F		; Если не минус, то переход сразу к конвертированию.
	SUB LENS, 1		    ; Если минус, то уменьшить длину строки на 1.
	MOV ECX, LENS 
	MOV F_SIGN, 1	    ; Установить флаг отрицательности на 1 (true).
	INC ESI				; Переход на следующий символ строки (цифру).

	; продолжаем перевод
	CONVERT_F: ; метка начала цикла
		XOR EDX, EDX ; очистить EDX
		MOV DL, 10 ; на это число будем умножать
		MOV BL, [ESI] ; помещаем символ из введенной строки в BL
		SUB BL, '0' ; вычитаем из введенного символа код нуля
		MUL EDX ; умножаем старое значение BX на 10, результат – в AX
		ADD EAX, EBX ; добавить к полученному числу новое значение	
		INC ESI ; перейти на следующую строку
	LOOP CONVERT_F ; новая итерация цикла
	MOV FIRST, EAX

	; Ввод второго числа.
	PUSH 0			
	PUSH OFFSET LENS				
	PUSH 200						
	PUSH OFFSET BUF					
	PUSH DIN						
	CALL ReadConsoleA@20	

	; Перевод из строки во второе число и проверка.
	PUSH OFFSET BUF
	SUB LENS, 2  ; Определяем длину строки без управляющих символов.
    CMP LENS, 1 ; Число должно содержать не меньше 4 знаков.
	JB ERROR
	CMP LENS, 6  ; Число должно содержать не больше 8 знаков.
	JA ERROR
	MOV ECX, LENS 
	MOV ESI, OFFSET BUF
	XOR EBX, EBX
	XOR EAX, EAX

	; Проверяем, отрицательно ли второе число.
	MOV BL, [ESI]						
	CMP BL, '-'
	JNE CONVERT_S		; Если не минус, то переход сразу к конвертированию.
	SUB LENS, 1		    ; Если минус, то уменьшить длину строки на 1.
	MOV ECX, LENS 
	MOV S_SIGN, 1	    ; Установить флаг отрицательности на 1 (true).
	INC ESI				; Переход на следующий символ строки (цифру).

	; продолжаем перевод
	CONVERT_S: ; метка начала цикла
		XOR EDX, EDX ; очистить EDX
		MOV DL, 10 ; на это число будем умножать, делаем в цикле т.к. при умножении dx затирается
		MOV BL, [ESI] ; помещаем символ из введенной строки в BL
		SUB BL, '0' ; вычитаем из введенного символа код нуля
		MUL EDX ; умножаем старое значение BX на 10, результат – в AX
		ADD EAX, EBX ; добавить к полученному числу новое значение	
		INC ESI ; перейти на следующую строку
	LOOP CONVERT_S ; новая итерация цикла
	MOV SECOND, EAX

	CMP F_SIGN, 1
	JNE FUNC0
	CMP S_SIGN, 0
	JNE FUNC0
	MOV SIGN, 1

	FUNC0:
	CMP F_SIGN, 0
	JNE FUNC01
	CMP S_SIGN, 1
	JNE FUNC01
	MOV SIGN, 1

	FUNC01:

	MOV EAX, FIRST
	MOV EBX, SECOND
	MUL EBX
	MOV FIRST, EAX


	RES:
	; преобразование результата
	MOV EDX, FIRST
	XOR EDI, EDI 
	XOR EAX, EAX
	XOR ECX, ECX
	MOV ECX, 2	
	MOV ESI, OFFSET BUF; начало строки хранится в переменной buf

	CMP SIGN, 0				; Если результат отрицательный, 
	JE FUNC					; то добавить в строку знак '-'.
	MOV AX, 45				; 45 - код знака '-'.
	MOV [ESI], AX
	INC ESI

	FUNC:	
	MOV EBX, EDX
	MOV EAX, EBX
	XOR EDX, EDX
	
	CONVERT_FROM10TO16:
		CMP EBX, S_16
		JAE FUNC1
		JB FUNC5
		FUNC1:
			DIV S_16
			ADD DX, '0'
		CMP DX, '9'
		JA FUNC2
		JB FUNC3
		FUNC2:
			ADD DX, 7
		FUNC3:
			PUSH EDX ; кладем данные в стек, для инвертирования
			ADD EDI, 1
			XOR EDX, EDX
			XOR EBX,EBX
			MOV BX, AX
			MOV ECX, 2
	LOOP CONVERT_FROM10TO16
	FUNC5:
		ADD AX, '0'
		CMP AX, '9'
		JA FUNC6
		JB FUNC7
		FUNC6:
			ADD AX, 7

	FUNC7:
		PUSH EAX ; кладем данные в стек, для инвертирования
		ADD EDI, 1
		MOV ECX, EDI
		CONVERTS:
			POP [ESI]
			INC ESI
		LOOP CONVERTS
	

	; выводим результат
	PUSH OFFSET STR2
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR1.
	PUSH 0					   ; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				   ; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET STR2		; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20

	PUSH OFFSET BUF
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR1.
	PUSH 0					   ; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				   ; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET BUF		; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20
	
	; выход из программы 
	PUSH 0 ; параметр: код выхода
	CALL ExitProcess@4

	; В случае ошибки.
	ERROR:
		PUSH OFFSET STR_ERR
		CALL lstrlenA@4
		PUSH 0
		PUSH OFFSET LENS
		PUSH EAX
		PUSH OFFSET STR_ERR
		PUSH DOUT
		CALL WriteConsoleA@20


		PUSH 0
		CALL ExitProcess@4 ; выход

	START ENDP
	END START