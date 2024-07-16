;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_ADC EQU P0
BUS_DATOS_LCD EQU P2
INIC_ADC EQU P1.0;Pulso positivo del reloj del ADC
FIN_ADC EQU P1.1
RS_LCD EQU P1.2
E_LCD EQU P1.3






;____________________Declarando variables y máscaras__________________________________________
COMAND_COUNTER equ R4
DELAY_TIMER1 equ R2
DELAY_TIMER2 equ R3
DELAY_TIMER3 equ R5
MUESTRA_ADC EQU R6
CODIGO_SALTO_LINEA EQU 0C0H

ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo la señal de inicio del ADC
CLR INIC_ADC
;INICIALIZACION DEL LCD
CALL LCD_INIT







;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	CALL GET_SAMPLE
	CALL PROCESAR_MUESTRA
	CALL MOSTRAR_VOLTAJE













JMP WHILE_TRUE
;____________________Implementación de subrutinas______________________________________________________________
LCD_INIT:
	MOV COMAND_COUNTER,#0;Inicializo mi contador de comandos
	MOV DPTR,#TABLA_COMANDOS;Inicializo mi puntero de tablas
	NEXT_COMAND:
	       MOV A,COMAND_COUNTER;Cargo el indice del comando actual
	       MOVC A,@A+DPTR;Cargo el valor del comando actual
	       MOV bus_datos_lcd,A;Se lo paso al bus del LCD
	       CALL Mandar_comando
	       INC COMAND_COUNTER;Actualizo para apuntar al proximo comando
	       CJNE COMAND_COUNTER,#5,NEXT_COMAND; ¿ Fin de programación del LCD?
	       RET

MANDAR_DATOS:	
	SETB RS_LCD;Habilito el registro de datos
	;Genero la señal de ENABLE
	SETB E_LCD
	CALL DELAY_5MS
	CLR E_LCD
	RET

MANDAR_COMANDO:
	CLR RS_LCD;Habilito el registro de comandos
	;Genero la señal de ENABLE
	SETB E_LCD
	CALL DELAY_5MS
	CLR E_LCD
	RET

GET_SAMPLE:
        ;//Genero la señal de inicio
	SETB INIC_ADC
	NOP
	CLR INIC_ADC
	;//Espero por la señal de fin 
	JB FIN_ADC,$
        ;//Guardo la unidad de conversion del ADC
        MOV MUESTRA_ADC,BUS_DATOS_ADC

	RET

PROCESAR_MUESTRA:
	;//Ejecuto las operaciones de la funcion Voltaje(V)=((1/51)*(MUESTRA_ADC))
	MOV A, MUESTRA_ADC;Inicializo mi dividendo
	MOV B, #51;Inicializo mi divisor
	DIV AB
	MOV MUESTRA_ADC,A;//Guardo el voltaje ya convertido
	
MOSTRAR_VOLTAJE:
        ;///////////LIMPIO EL DISPLAY LCD///////////
	MOV BUS_DATOS_LCD, #01H
        CALL MANDAR_COMANDO;
        ;//////////MUESTRO EL LETRERO 1////////////
	CALL LOAD_MSG
	;///////SALTO DE LINEA////////////
        MOV BUS_DATOS_LCD, #CODIGO_SALTO_LINEA	
        CALL MANDAR_COMANDO;
        ;///////Muestro la lectura del voltaje///////
        ;//Inicializo el puntero de la tabla
        MOV DPTR,#TABLA_NUMEROS	
        ;//Cargo mi indice de tabla de voltajes
        MOV A,MUESTRA_ADC
        MOVC A,@A+DPTR;Cargo el valor del codigo ASCI del voltaje actual
        MOV BUS_DATOS_LCD,A;Se lo paso al bus del LCD
	CALL mandar_datos
;	;//Muestro la V de Volts
;	MOV BUS_DATOS_LCD,'V';Se lo paso al bus del LCD
;	CALL mandar_datos
;	MOV BUS_DATOS_LCD,' ';Se lo paso al bus del LCD
;	CALL mandar_datos
	;//Espero un segundo hasta la proxima lectura
	CALL DELAY_1S
	;////////////Coloco el cursor en el inicio///////////
	MOV BUS_DATOS_LCD, #80H
        CALL MANDAR_COMANDO;

LOAD_MSG:
        ;//Inicializo el indice de caracter
        MOV B,#0
        ;//Inicializo el puntero de la tabla
        MOV DPTR,#TABLA_MSG1
        ;//Bucle de cargar el mensaje
	NEXT_CARACTER:
	MOV A,B;Cargo el indice del comando actual
	MOVC A,@A+DPTR;Cargo el valor del codigo ASCI del caracter actual
        MOV BUS_DATOS_LCD,A;Se lo paso al bus del LCD
	CALL mandar_datos
	INC B;Actualizo mi indice
	JZ FIN_MSG
	JMP NEXT_CARACTER
	FIN_MSG:
		RET

DELAY_5ms: 
	       MOV DELAY_TIMER1, #10
	Here2: MOV DELAY_TIMER2, #250
	Here1: DJNZ DELAY_TIMER2, $ ;2us x 10 x 250 = 5ms
	       DJNZ DELAY_TIMER1, here2
	       RET

DELAY_1s: 
	       MOV DELAY_TIMER1, #8
	Here5: MOV DELAY_TIMER2, #250
	Here4: MOV DELAY_TIMER3, #250
	       DJNZ DELAY_TIMER3, $ ;2us x 250 x 250 x 8= 1sec
	       DJNZ DELAY_TIMER2, HERE4
	       DJNZ DELAY_TIMER1, HERE5
	       RET


;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
tabla_comandos: db 38h,06h,0Eh,80h,01h
tabla_msg1: db 'Voltaje Medido(V): '
db 0
TABLA_NUMEROS: db '012345'




END





