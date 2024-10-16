;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;Este programa me permite mostrar en pantalla 7seg la temp en Celsius(entre 0 y 99grados) medida por un LM35, y
;convertida por el ADC0801 

;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_ADC EQU P0
UNIDADES_7SEG EQU P2
DECENAS_7SEG EQU P1
INIC_CONV EQU P3.4
FIN_CONV EQU P3.2
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

;____________________Declarando variables y máscaras__________________________________________
;////Contadores

CONTADOR_1sec EQU R5
;////Banderas
;FLAGS EQU 20H
;FLAG_MUESTRAS_TOMADAS EQU 20H.0
;////Variables
COCIENTE EQU 23H
RESTO EQU 24H
DIVISOR EQU 26H
;//RAM de cifras
VALOR_DECENAS EQU 30H
VALOR_UNIDADES EQU 31H


ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0
JMP RUTINA_TIMER0


INICIO:
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo mi divisor
MOV DIVISOR,#255
;//Inicializo mi puntero de tabla
MOV DPTR,#TABLA_7SEG
;////Inicializo los contadores
MOV CONTADOR_1SEC,#20
;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilito las IT de EXTI0, TIMER0,UART
SETB EX0
SETB ET0
SETB EA
;//Activo IT por flanco de caida
SETB IT0
;____________________Configurando los temporizadores__________________________________________
;//Timer 0 y Timer 1 -> modo 16 bits,disparo por SW,temporizador
MOV TMOD,#00010001B
;//Timer 0 contador de 50ms
MOV TH0,#HIGH(65536-50000)
MOV TL0,#LOW(65536-50000)
;//Disparo Timer 0
SETB TR0

;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:

JMP $

;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:;//Interupcion por el fin de conversion
	;//Leo la muestra actual
	MOV A,BUS_DATOS_ADC
	;//Convierto a unidades de ingenieria
	;//UI=99/255 * UC
        MOV B,#100
        MUL AB
        ;//MSB->B,LSB->A
        CALL DIVISION
        ;//Separo el cociente en decenas y unidades
        MOV A,COCIENTE
        MOV B,#10
        DIV AB
        MOV VALOR_DECENAS,A
        MOV VALOR_UNIDADES,B
        ;//--Actualizo el display
       	;//En A tengo el indice de la tabla 7seg(decenaas)
	;//Cargo el valor de la tabla 7seg
	MOVC A,@A+DPTR
	;//Actualizo las unidades
	MOV DECENAS_7SEG,A
	;//Cargo el indice de la tabla 7seg
	MOV A,VALOR_UNIDADES
	;//Cargo el valor de la tabla 7seg
	MOVC A,@A+DPTR
	;//Actualizo los decimales
	MOV UNIDADES_7SEG,A		
        FIN:
	        RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	;////Pasaron 50ms
	DJNZ CONTADOR_1SEC,SALGO
		;//Paso 1sec recargo su contador y doy inicio de conversion
		MOV CONTADOR_1SEC,#20               
		;//Doy inicio de conversion si me quedan muestras por tomar
		;JB FLAG_MUESTRAS_TOMADAS,SALGO
		CLR INIC_CONV
		NOP
		NOP
		SETB INIC_CONV
	SALGO:
            RETI           



;____________________Implementación de subrutinas______________________________________________________________
DIVISION:;En esta funcion A es el LSB y B el MSB
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

;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9



END

























