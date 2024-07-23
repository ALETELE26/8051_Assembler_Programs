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
;RAM DE DISPLAY
VALOR_CENTENAS EQU 23H
VALOR_DECENAS EQU 24H
VALOR_UNIDADES EQU 25H

;Contadores
contador_cajas EQU R2
Contador_500ms EQU R3
CONTADOR_7SEG EQU R6

;Banderas
FLAGS EQU 20H
SWITCH_FLAG EQU 20H.0
LED_FLAG  EQU 20H.1
REFRESH_FLAG EQU 20H.2
UPDATE_FLAG EQU 20H.3

;Variables
MASCARA_CONTROL_7SEG EQU 27H





ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0
JMP RUTINA_TIMER0
ORG 13H;Vector de EXTI 1
JMP RUTINA_EXT1





INICIO:
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo contadores
MOV CONTADOR_CAJAS,#0
MOV CONTADOR_500ms,#100;100 x 5ms = 500ms
MOV CONTADOR_7SEG,#0;Indica la cantidad de lamparas actualizadas
;//Inicializo las banderas inactivas
MOV FLAGS,#0
;//Inicializando los punteros
MOV R1,#23H;Puntero de la RAM de display
MOV DPTR,#TABLA_7SEG;Puntero de la tabla
;//Inicializo la RAM de Display para que me muestre cero
MOV VALOR_CENTENAS,#CODIGO_0
MOV VALOR_DECENAS,#CODIGO_0
MOV VALOR_UNIDADES,#CODIGO_0
;//Inicializo el led como apagad0
CLR LED
;//Inicializo la mascara de los 7seg(catodo comun)
MOV MASCARA_CONTROL_7SEG,#11111110B
;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilitando la EXTI 0(conteo de cajas) y del timer 0
SETB EA
SETB EX0
SETB ET0
;//Configurando la EXTI 0 y 1 como activa en frente de caida
SETB IT0
SETB IT1
;//Mas prioridad para el timer 0
SETB PT0

;____________________Configurando los temporizadores__________________________________________
;//Para contar 5ms(1000CM)(65536-1000)
MOV TH0,#HIGH(65536-1000)
MOV TL0,#LOW(65536-1000)
;//T0:Disparo por Software, Modo de 16 bits, modo temporizador
MOV TMOD,#00000001
;//Disparo el temporizador 0
SETB TR0

;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
;//Tengo que refrescar el display?
	JNB REFRESH_FLAG,SIGO2
		CALL DISPLAY_REFRESH
	SIGO2:
;//Tengo que actualizar el display?
	JNB UPDATE_FLAG,SIGO3
		CALL DISPLAY_RAM_UPDATE
	SIGO3:
;//Tengo que parpadear los leds?	
	JNB LED_FLAG,WHILE_TRUE
		CALL PARPADEO
		
JMP WHILE_TRUE
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:
	INC contador_cajas
	;//Le indico al programa principal que tiene que actualizar la RAM de  display
	SETB UPDATE_FLAG
	CJNE contador_cajas,#200,SALE
	;//Ya es necesario que el led parpadee
	SETB LED_FLAG
	;//Ya no contaré más 
	CLR EX0
	SALE:
            RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	;//Recarga de timer(tengo que hacerlo yo no tengo autorecarga)
	CLR TR0;Detengo temporalmente el conteo del timer 0
	MOV TH0,#HIGH(65536-1000);Recargo con los valores iniciales
	MOV TL0,#LOW(65536-1000)
	SETB TR0;Redisparo el timer 0
	;//Han pasado 5ms por lo que activo el refrescamiento
	SETB REFRESH_FLAG
	;//Pregunto si debo atender al led
	JNB LED_FLAG,SALGO
	;//Si todavia no han pasado 500ms no hago nada
	DJNZ CONTADOR_500MS,SALGO
	;//Recargo contador de 500ms
	MOV CONTADOR_500MS,#100
	;//Pasaron 500ms complemento led
	CPL LED
        SALGO:
            RETI           

;/////Rutina EXTI1/////////
RUTINA_EXT1:
	SETB SWITCH_FLAG
            RETI




;____________________Implementación de subrutinas______________________________________________________________
DISPLAY_REFRESH:
	CLR REFRESH_FLAG;//Ya entre a refrescar
	MOV BUS_CONTROL_7SEG,#000H;Apago las lamparas
	MOV BUS_CONTROL_7SEG,MASCARA_CONTROL_7SEG;Activo el display que le corresponde
	MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	INC R1;Apunto a la proxima direccion de la RAM de display
	INC CONTADOR_7SEG
	CJNE CONTADOR_7SEG,#3,ROTA
		;//Reinicializo los valores(un barrido completo)
		MOV CONTADOR_7SEG,#0;Reinicializo conteo de lamparas
		MOV MASCARA_CONTROL_7SEG,#11111110B
		MOV R1,#23H;Reinicializo RAM de Display
	        RET
            ROTA:
		MOV A,MASCARA_CONTROL_7SEG
		RL A;Genero el nuevo codigo de barrido
		MOV MASCARA_CONTROL_7SEG,A
		RET

DISPLAY_RAM_UPDATE:
        ;//Ya entre a actualizar
        CLR UPDATE_FLAG
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

PARPADEO:
        ;//Habilito la EXTI 1
        SETB EX1
        SIGUE:
        JNB SWITCH_FLAG,SIGUE;Salta si no se ha apretado el switch
	;///////Reinicializo el programa
	;//Inicializo contadores
	MOV CONTADOR_CAJAS,#0
	;//Inicializo las banderas inactivas
	MOV FLAGS,#0
        ;//Inicializo la RAM de Display para que me muestre cero
	MOV VALOR_CENTENAS,#CODIGO_0
	MOV VALOR_DECENAS,#CODIGO_0
	MOV VALOR_UNIDADES,#CODIGO_0
	 ;//Inicializo el led como apagado
	CLR LED
        RET


;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9




END






















