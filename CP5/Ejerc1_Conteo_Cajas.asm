;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_7SEG EQU P2
BUS_CONTROL_7SEG EQU P1
CENTENAS EQU P1.0
DECENAS EQU P1.1
UNIDADES EQU P1.2
SENSOR EQU P3.2
SWITCH EQU P3.3
LED EQU P3.7
;___________________Códigos del Display 7 seg/CATODO_COMUN__________________________________________
Codigo_0 EQU 3FH
Codigo_1 EQU 6H
Codigo_2 EQU 5BH 
Codigo_3 EQU 4FH
Codigo_4 EQU 66H
Codigo_5 EQU 6DH
Codigo_6 EQU 7DH
Codigo_7 EQU 7H
Codigo_8 EQU 07FH
Codigo_9 EQU 67H

;____________________Declarando variables y máscaras__________________________________________
contador_cajas EQU R2
VALOR_CENTENAS EQU R3
VALOR_DECENAS EQU R4
VALOR_UNIDADES EQU R5
CONTADOR_7SEG EQU R6
DELAY_TIME_1 EQU 21H
DELAY_TIME_2 EQU 22H
LED_FLAG EQU F0
SWITCH_FLAG EQU 36.0
MASCARA_CONTROL_7SEG EQU 00000001B





ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;/////Vector de EXTI 0/////
INC contador_cajas
CJNE contador_cajas,#200,SALE
;//Ya es necesario que el led parpadee
SETB LED_FLAG
;//Ya no contaré más 
CLR EX0
SALE:
RETI
ORG 13H;//////Vector de EXTI 1/////

;//Paro el parpadeo
CLR LED
CLR LED_FLAG
;//Inhabilito la EXTI 1
CLR EX1
;//Reinicializo el conteo de cajas
MOV contador_cajas,#0
;//Rehabilito la EXTI O
SETB EX0
;//Muestro cero en el display 7seg
MOV BUS_CONTROL_7SEG,#00000100B;Para activar solo las unidades
MOV BUS_DATOS_7SEG,#CODIGO_0;Muestro el cero
;Activo la bandera del switch para que el programa sepa que se ha cerrado
SETB SWITCH_FLAG
RETI

INICIO:

;____________________Inicializando variables y punteros__________________________________________ 
MOV CONTADOR_CAJAS,#0
CLR SWITCH_FLAG
;//Inicializo mi puntero en la tabla
MOV DPTR,#TABLA_7SEG
;//Muestro cero en el display 7seg
MOV BUS_CONTROL_7SEG,#00000100B;Para activar solo las unidades
MOV BUS_DATOS_7SEG,#CODIGO_0;Muestro el cero

;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilitando la EXTI 0(conteo de cajas)
SETB EA
SETB EX0
;//Configurando la EXTI 0 y 1 como activa en frente de caida
SETB IT0
SETB IT1





;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	CALL DISPLAY_RAM_UPDATE
	CALL DISPLAY_REFRESH
	JNB LED_FLAG,WHILE_TRUE
	CALL PARPADEO

JMP WHILE_TRUE

;____________________Implementación de subrutinas______________________________________________________________
PARPADEO:
        ;//Habilito la EXTI 1
        SETB EX1
        SIGUE:
	CPL LED
	CALL DELAY_250ms
        JNB SWITCH_FLAG,SIGUE;Salta si no se ha apretado el switch
        CLR SWITCH_FLAG
        RET


DELAY_250ms:
	MOV DELAY_TIME_1,#200
   AQUI:MOV DELAY_TIME_2,#250
	DJNZ DELAY_TIME_2,$; 5us x 250 x 200 = 250ms
	DJNZ DELAY_TIME_1,AQUI
	RET

DELAY_6punto5ms:
	MOV DELAY_TIME_1,#10
  AQUI2:MOV DELAY_TIME_2,#130
	DJNZ DELAY_TIME_2,$; 5us x 130 x 10 = 6.5ms
	DJNZ DELAY_TIME_1,AQUI2
	RET

DISPLAY_RAM_UPDATE:
        ;//Obtengo el valor de las centenas dividiendo entre 100
        MOV A,contador_cajas
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

DISPLAY_REFRESH:
      MOV CONTADOR_7SEG,#00H;Inicializo mi cantidad de displays 7seg barridos
      MOV A,#MASCARA_CONTROL_7SEG;Inicializo el esquema de barrido
      MOV R1,#3;Inicializo el puntero para la RAM de display
      LOOP:
              MOV BUS_CONTROL_7SEG,#00H;Apago todas las lamparas
	      MOV BUS_CONTROL_7SEG,A;Activo el display que le corresponde
	      MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	      INC R1;Apunto a la proxima direccion de la uy AM de display
	      INC CONTADOR_7SEG
	      CALL delay_6punto5ms
	      CJNE CONTADOR_7SEG,#3,ROTA
	      RET
	              ROTA:
		      RL A;Genero el nuevo codigo de barrido
		      JMP LOOP

;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9




END






















