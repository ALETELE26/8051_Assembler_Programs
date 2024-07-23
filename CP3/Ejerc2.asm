;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////

;___________________Declaracion del HARDWARE___________________________________________
BUS_DIR_7SEG EQU P3
BUS_DATOS_7SEG EQU P2
MUESTRA_ADC EQU P0
INIC EQU P1.0
FIN EQU P1.1
BUZZER EQU P1.2
SWITCH EQU P1.3


;___________________Códigos del Display 7 seg/ANODO_COMUN__________________________________________
Codigo_0 EQU 0C0H
Codigo_1 EQU 0F9H
Codigo_2 EQU 0A4H 
Codigo_3 EQU 0B0H
Codigo_4 EQU 099H
Codigo_5 EQU 092H
Codigo_6 EQU 082H
Codigo_7 EQU 0F8H
Codigo_8 EQU 080H
Codigo_9 EQU 098H
Codigo_punto0 EQU 40H
Codigo_punto1 EQU 79H
Codigo_punto2 EQU 24H 
Codigo_punto3 EQU 30H
Codigo_punto4 EQU 019H
Codigo_punto5 EQU 012H
Codigo_punto6 EQU 002H
Codigo_punto7 EQU 078H
Codigo_punto8 EQU 000H
Codigo_punto9 EQU 018H

;____________________Declarando variables y máscaras__________________________________________
CONTADOR_MUESTRAS EQU R2
VALOR_DECENAS EQU R3
VALOR_UNIDADES EQU R4
VALOR_DECIMAL EQU R5
DELAY_TIME EQU R7
CONTADOR_7SEG EQU R6
DELAY_TIME_1 EQU 20H
DELAY_TIME_2 EQU 21H
DELAY_TIME_3 EQU 22H
COCIENTE EQU 23H
RESTO EQU 24H
DIVISOR EQU 26H
MASCARA_CONTROL_7SEG EQU 11111110B


ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros__________________________________________ 
INICIO:
;//Inicializo mi contador de muestras 
MOV contador_muestras,#50
;//Inicializo mi puntero de tabla
MOV DPTR,#TABLA_7SEG
;//Inicializo mi puntero de la RAM de muestras
MOV R0,#30H
;//Inicializo mi divisor
MOV DIVISOR,#255
MOV COCIENTE,#00H;Inicializo mi cociente
MOV RESTO,#00H;Inicializo mi resto
MOV VALOR_DECIMAL,#00H;Inicializo mi valor decimal
MOV CONTADOR_7SEG,#00H;Inicializo mi valor de displays 7seg




;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	CALL GET_SAMPLE
	CALL PROCESAR_MUESTRA
        CALL DISPLAY_RAM_UPDATE
	CALL DISPLAY_UPDATE
	;//Si no he terminado de muestrear sigue
	DJNZ CONTADOR_MUESTRAS,WHILE_TRUE
	;//Si ya termine pon a pitar al buzzer
   AQUI2:CALL PLAY_BUZZER
        ;//Encuesto el boton de reinicio
         JB SWITCH,AQUI2
         ;//Vuelvo a los valores iniciales del programa
         JMP INICIO
       
;____________________Implementación de subrutinas______________________________________________________________
GET_SAMPLE:
        ;//Genero la señal de inicio
	CLR INIC
	NOP
	NOP
	SETB INIC
	;//Espero por la señal de fin 
	JB FIN,$
	;//Guardo en la RAM la muestra
	MOV @R0,MUESTRA_ADC
	;//Actualizo puntero
	INC R0
	RET

PROCESAR_MUESTRA:
	;//Ejecuto las operaciones de la funcion T(Celsius)=((60/255)*(MUESTRA_ADC))+10
	MOV B,#60
	MOV A,MUESTRA_ADC
	MUL AB
	CALL DIVISION
	MOV A,COCIENTE
	ADD A,#10
	;//Separo el valor de las decenas y de las unidades
	MOV B,#10;Inicializo mi divisor para separar dec de uni
	DIV AB
	MOV VALOR_DECENAS,A;Guardo el cociente de la division en las decenas
	MOV VALOR_UNIDADES,B;Guardo el resto de la division en las unidades
	;//Verifico si el valor decimal es cero
	MOV A,RESTO
	CJNE A,#26,AQUI3
        AQUI3:
        JNC EXTRAER_DECIMAL
        MOV VALOR_DECIMAL,#0
        RET
	EXTRAER_DECIMAL:
	        ;//Inicializo los valores de los operandos	
		MOV B,#10
		MUL AB
		CALL DIVISION
		;Guardo el cociente de la nueva division como el valor decimal
		MOV VALOR_DECIMAL,COCIENTE
		RET

DISPLAY_RAM_UPDATE:
	MOV A,VALOR_DECENAS;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_DECENAS,A;Se lo paso a la RAM designada para las decenas
	MOV DPTR,#TABLA_PUNTO_DECIMAL;Cambio de tabla a la hora de las unidades
        MOV A,VALOR_UNIDADES;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_UNIDADES,A;Se lo paso a la RAM designada para las unidades
	MOV DPTR,#TABLA_7SEG;Regreso a la tabla con el DP apagado
        MOV A,VALOR_DECIMAL;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_DECIMAL,A;Se lo paso a la RAM designada para los decimales
        RET
	
DISPLAY_UPDATE:
      MOV CONTADOR_7SEG,#00H;Inicializo mi valor de displays 7seg
      MOV A,#MASCARA_CONTROL_7SEG;Inicializo el esquema de barrido
      MOV R1,#3;Inicializo el puntero para la RAM de display
      LOOP:
	      MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	      INC R1;Apunto a la proxima direccion de la RAM de display
	      INC CONTADOR_7SEG
	      MOV BUS_DIR_7SEG,A;Activo el display que le corresponde
	      CALL delay_5ms
	      CJNE CONTADOR_7SEG,#3,ROTA
	      RET
	      ROTA:
		      RL A;Genero el nuevo codigo de barrido
		      JMP LOOP
		      
	      
      
      





;	;//Cargo el indice de la tabla 7seg
;	MOV A,VALOR_DECENAS
;	;//Cargo el valor de la tabla 7seg
;	MOVC A,@A+DPTR
;	;//Actualizo las decenas
;	MOV DECENAS_7SEG,A
;	;//Cargo el indice de la tabla 7seg
;	MOV A,VALOR_UNIDADES
;	;//Cargo el valor de la tabla 7seg
;	MOVC A,@A+DPTR
;	;//Actualizo las decenas
;	MOV UNIDADES_7SEG,A

PLAY_BUZZER:
	;//Inicializo mi delay time en 125 para lograr un delay de 250us
        MOV DELAY_TIME,#125
        ;//Pongo a pitar al buzzer con tonos de 2kHz
	CPL BUZZER
	DJNZ DELAY_TIME,$;Delay de 250us asumiendo CM de 1us
	RET
DELAY_500ms:
	MOV DELAY_TIME_3,#4;1us
	HERE2:
	MOV DELAY_TIME_2,#250;4us
	HERE1:
	MOV DELAY_TIME_1,#250;1us x 250 x 4 = 1ms
	DJNZ DELAY_TIME_1,$;2us x 250 x 250 x4 = 500ms
	DJNZ DELAY_TIME_2,HERE1;2us x 250 x 4 = 2ms
	DJNZ DELAY_TIME_3,HERE2;8us
	RET;2us
DIVISION:
        ;//REINICIALIZO EL COCIENTE
	MOV COCIENTE,#0
	SALTO:
	CLR C;
	SUBB A,DIVISOR;Resta sucesiva de elementos
	JC UPDATE_MSB;Salta si necesite un prestamo
	        INC COCIENTE
		JMP SALTO
	UPDATE_MSB:
	        INC COCIENTE
	        DJNZ B,SALTO;Actualizo y comparo el byteMSB del dividendo
		FASE_FINAL:
			CJNE A,DIVISOR,HERE;Comparo el estado actual del LSB del dividendo y el divisor                 
			INC COCIENTE
			MOV RESTO,#0;Guardo el resto de la division
			RET
		        HERE:
		        	JC EXTRAER_RESTO;Si es menor cojo el resto y paro
		        	        SUBB A,DIVISOR;Resta sucesiva de elementos
		        	        INC COCIENTE
		        	        JMP FASE_FINAL
					EXTRAER_RESTO:
						MOV RESTO,A;Guardo el resto de la division
						RET

DELAY_5ms:
	MOV DELAY_TIME_1,#10
   AQUI:MOV DELAY_TIME_2,#250
	DJNZ DELAY_TIME_2,$
	DJNZ DELAY_TIME_1,AQUI
	RET
	
	



			


;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9
Tabla_punto_Decimal:
DB Codigo_punto0,codigo_punto1,Codigo_punto2,Codigo_punto3,Codigo_punto4,Codigo_punto5,Codigo_punto6,Codigo_punto7,Codigo_punto8,Codigo_punto9




END
