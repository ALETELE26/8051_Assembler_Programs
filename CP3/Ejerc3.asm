;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
switchD EQU P1.3
switchC EQU P1.2
switchB EQU P1.1
switchA EQU P1.0
LEDs EQU P3





;____________________Declarando variables y máscaras__________________________________________
DELAY_TIME_1 EQU R3
DELAY_TIME_2 EQU R4
DELAY_TIME_3 EQU R5
INDICE EQU R2
MASCARA_LEDS EQU 0FFH





ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros, y puertos__________________________________________ 
MOV LEDS,#0;Inicio con todos los leds apagados
MOV INDICE,#0;Inizializo mi INDICE







;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	JB SWITCHA,Check_SWITCHB;Si SWITCHA se encienden de derecha a izquierda
        MOV DPTR,#TABLA_RIGHT_TO_LEFT
	CALL SECUENCIA_LED
	JMP WHILE_TRUE
	CHECK_SWITCHB:
	JB SWITCHB,Check_SWITCHC;Si SWITCHB esta cerrado encienden de izquierda a derecha
	MOV DPTR,#TABLA_LEFT_TO_RIGHT
	CALL SECUENCIA_LED
	JMP WHILE_TRUE
	CHECK_SWITCHC:
	JB SWITCHC,Check_SWITCHD;Si SWITCHC esta cerrado se encienden del centro hacia los extremos
	MOV DPTR,#TABLA_INSIDE_OUT
	CALL SECUENCIA_LED
	JMP WHILE_TRUE
	CHECK_SWITCHD:
	JB SWITCHD,WHILE_TRUE;Si SWITCHB esta cerrado se encienden desde los extremos hacia el centro
	MOV DPTR,#TABLA_OUT_TO_INSIDE
	CALL SECUENCIA_LED
	JMP WHILE_TRUE

;____________________Implementación de subrutinas______________________________________________________________
delay_500ms:
	MOV DELAY_TIME_3,#25;
	HERE2:
	MOV DELAY_TIME_2,#100;
	HERE1:
	MOV DELAY_TIME_1,#100;
	DJNZ DELAY_TIME_1,$;2us x 100 x 100 x 25 = 500ms
	DJNZ DELAY_TIME_2,HERE1;
	DJNZ DELAY_TIME_3,HERE2;
	RET;

SECUENCIA_LED:
	MOV INDICE,#0;Reinicializo mi INDICE
	LOOP:
		MOV A,INDICE;Cargo el indice de la tabla
		MOVC A, @A+DPTR;Cargo el valor de la tabla
		MOV LEDS,A;Se lo paso a los leds
		CALL delay_500ms
		CJNE A,#0FFH,REPITE	
		MOV LEDS,#0;Reinicio con todos los leds apagados
		CALL delay_500ms
                RET
	REPITE:
		INC INDICE;Actualizo mi indice de la tabla
		JMP LOOP
	



;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_Right_to_Left:
DB 00000001B,00000011B,00000111B,00001111B,00011111B,00111111B,01111111B,11111111B
Tabla_Left_to_Right:
DB 10000000B,11000000B,11100000B,11110000B,11111000B,11111100B,11111110B,11111111B
Tabla_Inside_Out:
DB 00011000B,00111100B,01111110B,11111111B
Tabla_Out_to_inside:
DB 10000001B,11000011B,11100111B,11111111B


END























