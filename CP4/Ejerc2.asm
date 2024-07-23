;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
; Teclado matricial de 4x3      Salidas ->P2.3...P2.0    Entradas ->P0.0....P0.2
TECLADO_COLUMNAS EQU P0
TECLADO_FILAS EQU P2
LED EQU P1.0


;___________________Códigos del teclado matricial______________________________________
Codigo_0 EQU 00H
Codigo_1 EQU 01H
Codigo_2 EQU 02H
Codigo_3 EQU 03H
Codigo_4 EQU 04H
Codigo_5 EQU 05H
Codigo_6 EQU 06H
Codigo_7 EQU 07H
Codigo_8 EQU 08H
Codigo_9 EQU 09H
Codigo_Borrar EQU 7FH
Codigo_Enter EQU 0FFH

;____________________Declarando variables y máscaras__________________________________________
CONTADOR_FILAS EQU R0
CONTADOR_COLUMNAS EQU R1
CONTADOR_NUMEROS EQU R2
REG_AUX EQU R3
CONT_PARPADEO EQU R4
BARRIDO_CODE EQU R6
ALMACEN_VALOR EQU 50H
COLUMNAS_VALOR EQU 51H
FILAS_VALOR EQU 52H
NUMERO_1 EQU 53H
NUMERO_2 EQU 54H
NUMERO_3 EQU 55H
DELAY_TIMER1 equ 56H
DELAY_TIMER2 equ 57H
DELAY_TIMER3 equ 58H
CODIGO_PULSADO EQU R7

MASCARA_COLUMNAS EQU 07H;Porque son tres bits
NUMERO_DE_FILAS EQU 4 ;p
NUMERO_DE_COLUMNAS EQU 3;q
ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo mi led como encendido
CLR LED
;//Inicializo mi contador en cero
MOV CONTADOR_NUMEROS,#0
;//Inicializo mi puntero en la tabla
MOV DPTR,#TABLA_TECLADO





;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
    CALL OBTENER_CODIGO
    ;//Se introducio un numero?
    CJNE CODIGO_PULSADO,#0AH,HERE
	    HERE:;//Si el codigo es menor que 10 se apreto un numero sino una tecla de control
	    JNC CHECK_BORRAR
	    CALL GUARDAR_NUMERO
	    JMP WHILE_TRUE
	    CHECK_BORRAR:
	    CJNE CODIGO_PULSADO,#CODIGO_BORRAR,HERE2
		    ;//BORRO REGISTRO DE NUMERO GUARDADO
		    MOV CONTADOR_NUMEROS,#0
		    JMP WHILE_TRUE
		    HERE2:;//SI ENTRO AQUI LE DI AL ENTER
		    CALL ENTER
		    JMP WHILE_TRUE
		    
	    













;____________________Implementación de subrutinas______________________________________________________________

OBTENER_CODIGO:
	;//Inicializo contadores de filas y columnas
	MOV CONTADOR_FILAS,#0;i
	MOV CONTADOR_COLUMNAS,#0;j
	;//Inicializo codigo de barrido 
	MOV BARRIDO_CODE,#11111110B
	;//Cargo el codigo de barrido en las filas
  LOOP: MOV TECLADO_FILAS,BARRIDO_CODE
        ;//Leo las columnas
        MOV COLUMNAS_VALOR,TECLADO_COLUMNAS
        ;//Aislo las columnas
        ANL COLUMNAS_VALOR,#MASCARA_COLUMNAS
        ;//Hay tecla oprimida?
        MOV A,COLUMNAS_VALOR
        CJNE A,#MASCARA_COLUMNAS,TECLA_OPRIMIDA
	        ;//NO SE PULSO TECLA,POR TANTO INCREMENTA LA CANT DE FILAS
	        INC CONTADOR_FILAS
	        ;//Fin del barrido de teclado?
	        CJNE CONTADOR_FILAS,#NUMERO_DE_FILAS,REPITE
	                ;//Repito barrido del teclado
		        JMP OBTENER_CODIGO
		        REPITE:;//Obtengo nuevo codigo de barrido
			        MOV A,BARRIDO_CODE
			        RL A
			        MOV BARRIDO_CODE,A
			        ;//Escaneo nueva fila
			        JMP LOOP

	TECLA_OPRIMIDA:;//SE PULSO TECLA,POR TANTO OBTENGO SU COLUMNA
		;//Busco el bit de la columna	
		MOV A,COLUMNAS_VALOR
		RRC A
		;Es el bit correcto?
		JNC MATCH_COLUMN
			;//No es la columna,salta pa la otra
			INC CONTADOR_COLUMNAS
			;//Sera la ultima columna?
			CJNE CONTADOR_COLUMNAS,#NUMERO_DE_COLUMNAS,TECLA_OPRIMIDA
			;//Estado imposible vuelvo a empezar
			JMP OBTENER_CODIGO
			MATCH_COLUMN:;SI ES LA COLUMNA!!!!
			;/////Obtengo indice de la tabla A=q*i+j
			MOV A,CONTADOR_FILAS
			MOV B,#NUMERO_DE_COLUMNAS
			;//Multiplico el indice de filas por el total de columnas
			MUL AB
			;//Al resultado le sumo el indice de columnas
			ADD A,CONTADOR_COLUMNAS
			;//Obtengo el codigo de la tecla
			MOVC A,@A+DPTR
			;//Lo guardo
			MOV CODIGO_PULSADO,A
			RET

GUARDAR_NUMERO:
	;//Si ya conte 3 numeros no cuento mas
	CJNE CONTADOR_NUMEROS,#3,CHECK_CONT0
		RET
	CHECK_CONT0:
		CJNE CONTADOR_NUMEROS,#0,CHECK_CONT1 
		;//Primer numero que guardo
		MOV NUMERO_1,codigo_pulsado
		;//Conte un numero
		INC CONTADOR_NUMEROS  
		RET
	CHECK_CONT1:  
		CJNE CONTADOR_NUMEROS,#1,CHECK_CONT2
		;//Segundo numero que guardo
		MOV NUMERO_2,codigo_pulsado
		;//Conte un numero
		INC CONTADOR_NUMEROS  
		RET 
	CHECK_CONT2:;//Ya conte dos numeros confirmado
		;//Tercer numero que guardo
		MOV NUMERO_3,codigo_pulsado
		;//Conte un numero
		INC CONTADOR_NUMEROS	
		RET

ENTER:
	;//Tengo guardado algun numero antes de apretar enter?
	CJNE CONTADOR_NUMEROS,#0,CHECK_CONT1_AGAIN
		RET
        CHECK_CONT1_AGAIN:
	        CJNE CONTADOR_NUMEROS,#1,CHECK_CONT2_AGAIN
	        ;//El numero guardado es el de las unidades y lo almaceno
	        MOV ALMACEN_VALOR,NUMERO_1
	        ;//BORRO REGISTRO DE NUMERO GUARDADO
		MOV CONTADOR_NUMEROS,#0
	        JMP PARPADEO
	CHECK_CONT2_AGAIN:
		CJNE CONTADOR_NUMEROS,#2,CHECK_CONT3_AGAIN   
		;//El primer num guardado es el de las decenas y el segundo el de las unidades
		MOV A,NUMERO_1
		MOV B,#10
		MUL AB 
		ADD A,NUMERO_2
		;//El resultado de estas operaciones da el valor tecleado y lo guardo
		MOV ALMACEN_VALOR,A  
		;//BORRO REGISTRO DE NUMERO GUARDADO
		MOV CONTADOR_NUMEROS,#0
		JMP PARPADEO
	CHECK_CONT3_AGAIN:;//Confirmado que tengo tres numeros guardados
	;//El primer num guardado es el de las centenas
	;el segundo de las decenas y el tercero de las centenas//
		MOV A,NUMERO_1
		MOV B,#100
		MUL AB
		JB OV,VALOR_INVALIDO
                ;//Si es un valor valido respaldo el resultado
                MOV REG_AUX,A
                ;//Opero para extraer decenas y unidades
                MOV A,NUMERO_2
		MOV B,#10
		MUL AB 
		ADD A,NUMERO_3
		ADD A,REG_AUX
		JB OV,VALOR_INVALIDO
		;//El resultado de estas operaciones da el valor tecleado y lo guardo
		MOV ALMACEN_VALOR,A  
		;//BORRO REGISTRO DE NUMERO GUARDADO
		MOV CONTADOR_NUMEROS,#0
		JMP PARPADEO
		VALOR_INVALIDO:
			;//BORRO REGISTRO DE NUMERO GUARDADO
			MOV CONTADOR_NUMEROS,#0
			RET      
        PARPADEO:
	;//Inicializo mi contador de 5seg en cero
	MOV CONT_PARPADEO,#0
        LOOP2:
	SETB LED
	CALL DELAY_500MS
	CLR LED
	CALL DELAY_500MS
	INC CONT_PARPADEO
	CJNE CONT_PARPADEO,#5,LOOP2
	;//Ya pasaron los 5seg
	;//Reinicializo el led como encendido
	CLR LED
	RET
	
	
	
	






DELAY_500ms: 
	       MOV DELAY_TIMER1, #4
	Here5: MOV DELAY_TIMER2, #250
	Here4: MOV DELAY_TIMER3, #250
	       DJNZ DELAY_TIMER3, $ ;2us x 250 x 250 x 4 = 500ms
	       DJNZ DELAY_TIMER2, HERE4
	       DJNZ DELAY_TIMER1, HERE5
	       RET

;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
TABLA_Teclado:
DB CODIGO_1,CODIGO_2,CODIGO_3,CODIGO_4,CODIGO_5,CODIGO_6,CODIGO_7,CODIGO_8,CODIGO_9,CODIGO_BORRAR,CODIGO_0,CODIGO_ENTER



END






















