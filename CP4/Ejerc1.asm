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

;____________________Declarando variables y máscaras__________________________________________
CONTADOR_MUESTRAS EQU R2
VALOR_CENTENAS EQU R3
VALOR_DECENAS EQU R4
VALOR_UNIDADES EQU R5
CONTADOR_7SEG EQU R6
CONTADOR_1SEGUNDO EQU R7
MASCARA_CONTROL_7SEG EQU 11111110B
DELAY_TIME_1 EQU 20H
DELAY_TIME_2 EQU 21H
DELAY_TIME_3 EQU 22H


ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros__________________________________________ 
INICIO:
;//Inicializo mi contador de muestras 
MOV contador_muestras,#0
;//Inicializo mi puntero de tabla
MOV DPTR,#TABLA_7SEG
;//Inicializo mi puntero de la RAM de muestras
MOV R0,#30H





;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	CALL GET_SAMPLE
        CALL DISPLAY_RAM_UPDATE
	CALL DISPLAY_UPDATE
	;//Si no he terminado de muestrear sigue
	CJNE CONTADOR_MUESTRAS,#200,WHILE_TRUE
	;//Si ya termine pon a pitar al buzzer
	;//Inicializo mi delay time en 62 para lograr un delay de 250us aprox
        MOV DELAY_TIME_1,#62
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
	;//Actualizo la cantidad de muestras recibidas
	INC CONTADOR_MUESTRAS
	RET


DISPLAY_RAM_UPDATE:
        ;//Obtengo el valor de las centenas dividiendo entre 100
        MOV A,contador_muestras
        MOV B,#100
        DIV AB
        MOV VALOR_CENTENAS,A;Guardo el cociente como el valor de las centenas
        MOV A,B;El resto sera el dividendo para mi proxima division
        MOV B,#10
        ;//Obtengo el valor de las decenas  y unidades dividiendo entre 10
        DIV AB
        MOV VALOR_DECENAS,A;Guardo el cociente como el valor de las decenas
        MOV VALOR_UNIDADES,B;Guardo el resto como el valor de las unidades
        ;//Transformo los valores para que los entienda el display
        ;DECENAS
	MOV A,VALOR_DECENAS;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_DECENAS,A;Se lo paso a la RAM designada para las decenas
	;UNIDADES
        MOV A,VALOR_UNIDADES;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_UNIDADES,A;Se lo paso a la RAM designada para las unidades
	;CENTENAS
        MOV A,VALOR_CENTENAS;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV VALOR_CENTENAS,A;Se lo paso a la RAM designada para los decimales
        RET
DISPLAY_UPDATE:
      MOV CONTADOR_1SEGUNDO,#50;Cuando el loop se repita 50 veces paso 1 sec
      REPITE:
      MOV CONTADOR_7SEG,#00H;Inicializo mi valor de displays 7seg
      MOV A,#MASCARA_CONTROL_7SEG;Inicializo el esquema de barrido
      MOV R1,#3;Inicializo el puntero para la RAM de display
      LOOP:
	      MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	      INC R1;Apunto a la proxima direccion de la RAM de display
	      INC CONTADOR_7SEG
	      MOV BUS_DIR_7SEG,A;Activo el display que le corresponde
	      CALL delay_6punto6ms
	      CJNE CONTADOR_7SEG,#3,ROTA
	      DJNZ contador_1segundo,REPITE
	      RET
	      ROTA:
		      RL A;Genero el nuevo codigo de barrido
		      JMP LOOP

DELAY_6punto6ms:
	MOV DELAY_TIME_1,#110
   AQUI:MOV DELAY_TIME_2,#30
	DJNZ DELAY_TIME_2,$
	DJNZ DELAY_TIME_1,AQUI
	RET

DELAY_500ms:
	MOV DELAY_TIME_3,#2;
	HERE2:
	MOV DELAY_TIME_2,#250;
	HERE1:
	MOV DELAY_TIME_1,#250;
	DJNZ DELAY_TIME_1,$;2CM=4us\\ 4us x 250 x 250 x2 = 500ms
	DJNZ DELAY_TIME_2,HERE1;
	DJNZ DELAY_TIME_3,HERE2;
	RET;2us
	
PLAY_BUZZER:
	
        ;//Pongo a pitar al buzzer con tonos de 2kHz
	CPL BUZZER
	DJNZ DELAY_TIME_1,$;Delay de 250us asumiendo CM de 1us
	RET









;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9




END


