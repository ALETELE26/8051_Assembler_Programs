;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_7SEG EQU P0
BUS_CONTROL_7SEG EQU P1
;Dec. de horas->P1.0  Unid. de horas->P1.1  Dec. de minutos->P1.2  Unid. de minutos->P1.3
LED EQU P3.7
;//Botones
ALARM_SET EQU P2.0
UP EQU P2.1
DOWN EQU P2.2
MODE EQU P3.2

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
;//Variables
DEC_HORAS EQU R2
UNID_HORAS EQU R3
DEC_MIN EQU R4
UNID_MIN EQU R5
ALARM_DEC_HORAS EQU 34H
ALARM_UNID_HORAS EQU 35H
ALARM_DEC_MIN EQU 36H
ALARM_UNID_MIN EQU 37H
MASCARA_CONTROL_7SEG EQU 27H
MASCARA_CONFIG_MODE EQU 28H
;//RAM de Display Dec.H->70H Unid.H->71H  Dec.Min->72H  Unid.Min->73H
DISPLAY_RAM_DEC_H EQU 70H
DISPLAY_RAM_UNID_H EQU 71H
DISPLAY_RAM_DEC_MIN EQU 72H
DISPLAY_RAM_UNID_MIN EQU 73H
;//Banderas
FLAGS EQU 20H
FLAG_UPDATE EQU 20H.0
FLAG_REFRESH EQU 20H.1
FLAG_ALARM EQU 20H.2
FLAG_MODE_PRESS EQU 20H.3
FLAG_NEW_POLL EQU 20H.4
FLAG_WAITING_POLL EQU 20H.5
;//Contadores
CONTADOR_500ms EQU 50H
CONTADOR_1min EQU 51H
CONTADOR_5sec EQU 52H
CONTADOR_AUX_250ms EQU 54H
CONTADOR_7SEG EQU R7
CONTADOR_ITERACIONES EQU R6




ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0;//Interrupcion del boton Mode
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0;//Timer Principal de la Hora
JMP RUTINA_TIMER0
ORG 1BH;Vector de ITIMER 1;//Timer Demora del rebote
JMP RUTINA_TIMER1

INICIO:
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo las banderas inactivas
MOV FLAGS,#0
;//Inicializo la RAM de Display para que me muestre cero
MOV DISPLAY_RAM_DEC_MIN,#CODIGO_0
MOV DISPLAY_RAM_DEC_H,#CODIGO_0
MOV DISPLAY_RAM_UNID_H,#CODIGO_0
MOV DISPLAY_RAM_UNID_MIN,#CODIGO_0
;//Inicializando los punteros
MOV DPTR,#TABLA_7SEG;Puntero de la tabla
;//Inicializo contadores
MOV CONTADOR_7SEG,#0;Indica la cantidad de lamparas actualizadas
MOV CONTADOR_500ms,#100;100 veces 5ms es 500ms
MOV CONTADOR_1min,#120;120 veces 500ms es 1min
MOV CONTADOR_5SEC,#10;10 veces 500ms es 5sec
MOV CONTADOR_AUX_250ms,#25;25 veces 10ms es 250ms
;//Inicializo el led como apagado
CLR LED
;//Iniciando los valores de la hora en 0
MOV UNID_HORAS,#0
MOV UNID_MIN,#0
MOV DEC_HORAS,#0
MOV DEC_HORAS,#0
;//Iniciando los valores de la alarma a las 6PM
MOV ALARM_DEC_HORAS,#1
MOV ALARM_UNID_HORAS,#8
MOV ALARM_DEC_MIN,#0
MOV ALARM_UNID_MIN,#0
;//Inicializo la mascara de control
MOV MASCARA_CONTROL_7SEG,#11111110B


;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilitando la interrupcion del timer 0, timer 1 y la EXTI 0
SETB EA
SETB ET0
SETB EX0
SETB ET1
;//Mas prioridad para el timer 0
SETB PT0
;Configurando las interrupciones externas como activas con frente de caida
SETB IT0
;____________________Configurando los temporizadores__________________________________________
;//T0:Para contar 5ms(5000CM)(65536-5000)
;//T1:Para contar 10ms(10000CM)(65536-10000)
MOV TH0,#HIGH(65536-5000)
MOV TL0,#LOW(65536-5000)
MOV TH1,#HIGH(65536-10000)
MOV TL1,#LOW(65536-10000)
;//T0:Disparo por Software, Modo de 16 bits, modo temporizador
;//T1:Disparo por Software, Modo de 16 bits, modo temporizador
MOV TMOD,#00010001B
;//Disparo el temporizador 0
SETB TR0
;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
;//Tengo que actualizar la RAM display?
	JNB FLAG_UPDATE,SIGO3
		CALL DISPLAY_RAM_UPDATE
	SIGO3:
;//Tengo que refrescar el display?
	JNB FLAG_REFRESH,SIGO2
		CALL DISPLAY_REFRESH
	SIGO2:	
;//Comparo la hora actual con la alarma si no esta sonando
	JB FLAG_ALARM,SIGO1
		CALL CHECK_ALARM
	SIGO1:
;//Modo de configuracion activado?
	JNB FLAG_MODE_PRESS,WHILE_TRUE
	;////////Configuration Mode ON
	;Ya me di cuenta que se oprimio el boton
	CLR FLAG_MODE_PRESS
	;//Detengo el conteo de la hora del reloj
	CLR TR0
	;//Inicializo mi puntero de la hora
	MOV R0,#2;Los valores de la hora se encuentran en R2
	MOV CONTADOR_ITERACIONES,#4;(for n = 4):
	MOV MASCARA_CONFIG_MODE,#11111110B;Inicializo masc de control 
	;//Inicio del bucle de configuracion
	BUCLE_CONFIG:
	;//Activo solo el display que estoy actualizando
	MOV BUS_CONTROL_7SEG,MASCARA_CONFIG_MODE
	POLLING:
	;//Encuesto el boton UP
	JB UP,CONTINUO
	;////Actualizo la hora de manera correspondiente y la muestro
		;//Si estoy config. las dec. de las horas el valor max es 2
		CJNE CONTADOR_ITERACIONES,#4,VALIDACION3;Entra si estoy config. las dec de horas
			CJNE @R0,#2,INCREMENTO;Si no es dos el valor lo puedo incrementar
				MOV @R0,#0;Si es el valor max pasa a cero	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO
			INCREMENTO:
				INC @R0
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO
		VALIDACION3:
		;//Si estoy config. las unid. de las horas el valor max es 3
		CJNE CONTADOR_ITERACIONES,#3,VALIDACION2;Entra si estoy config. las unid de horas
		        CJNE DEC_HORAS,#2,AQUI6		        
			CJNE @R0,#3,INCREMENTO;Si no es tres el valor lo puedo incrementar
				MOV @R0,#0;Si es el valor max pasa a cero	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO
			AQUI6:
			CJNE @R0,#9,INCREMENTO;Si no es tres el valor lo puedo incrementar
				MOV @R0,#0;Si es el valor max pasa a cero	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO

		VALIDACION2:
		;//Si estoy config. las dec. de los min el valor max es 5
		CJNE CONTADOR_ITERACIONES,#2,VALIDACION1;Entra si estoy config. las dec de minutos
			CJNE @R0,#5,INCREMENTO;Si no es cinco el valor lo puedo incrementar
				MOV @R0,#0;Si es el valor max pasa a cero	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO
		VALIDACION1:;Definitivamente estoy config las unid. de los minutos
		;//El valor max es 9
			CJNE @R0,#9,INCREMENTO;Si no es nueve el valor lo puedo incrementar
				MOV @R0,#0;Si es el valor max pasa a cero	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO
		
	CONTINUO:
	;//Encuesto el boton DOWN
	JB DOWN,CONTINUO2
	;////Actualizo la hora de manera correspondiente y la muestro
        ;//En este caso siempre el valor minimo sera cero y lo que cambiara sera el valor que le siga
		CJNE CONTADOR_ITERACIONES,#4,CHECKING3;Entra si estoy config. las dec de horas
			CJNE @R0,#0,DECREMENTO;Si no es cero el valor lo puedo decrementar
				MOV @R0,#2;Si es el valor min, pasa a dos	
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO2
			DECREMENTO:
				DEC @R0
				CALL MOSTRAR_LAMPARA
				JMP CONTINUO2 
		CHECKING3:   
		CJNE CONTADOR_ITERACIONES,#3,CHECKING2;Entra si estoy config. las unid de horas 
		        CJNE DEC_HORAS,#2,AQUI7	
			CJNE @R0,#0,DECREMENTO;Si no es cero el valor lo puedo decrementar
					MOV @R0,#3;Si es el valor min, pasa a tres	
					CALL MOSTRAR_LAMPARA
					JMP CONTINUO2
			AQUI7:
			CJNE @R0,#0,DECREMENTO;Si no es cero el valor lo puedo decrementar
					MOV @R0,#9;Si es el valor min, pasa a nueve	
					CALL MOSTRAR_LAMPARA
					JMP CONTINUO2
			
			
		CHECKING2:   
		CJNE CONTADOR_ITERACIONES,#2,CHECKING1;Entra si estoy config. las dec. de min
			CJNE @R0,#0,DECREMENTO;Si no es cero el valor lo puedo decrementar
					MOV @R0,#5;Si es el valor min, pasa a cinco	
					CALL MOSTRAR_LAMPARA
					JMP CONTINUO2
		CHECKING1:;Indiscutiblemente estoy config. las unid. de los min
			CJNE @R0,#0,DECREMENTO;Si no es cero el valor lo puedo decrementar
					MOV @R0,#9;Si es el valor min, pasa a nueve	
					CALL MOSTRAR_LAMPARA
					JMP CONTINUO2
	CONTINUO2:
	;//Encuesto el boton SET_ALARM
	JB ALARM_SET,CONTINUO3
		;//Establezco hora actualizo hora actual como alarma
		MOV ALARM_DEC_HORAS,DEC_HORAS
		MOV ALARM_UNID_HORAS,UNID_HORAS
		MOV ALARM_DEC_MIN,DEC_MIN
		MOV ALARM_UNID_MIN,UNID_MIN
	CONTINUO3:	
	;//Preguntar por la bandera que me dice si oprimi MODE
	JB FLAG_MODE_PRESS,AQUI0
	;////Si no se oprimio MODE sigo encuestando UP, DOWN y SET_ALARM  despues de 500 ms
        ;//Le hago saber al timer 1 que estoy esperando por encuesta
        SETB FLAG_WAITING_POLL
	;//Disparo el timer 1
	SETB TR1
	;//Espero hasta que hayan pasado los 50ms
	JNB FLAG_NEW_POLL,$
	;//Detengo el conteo de timer 1
	CLR TR1
	;//Ya no estoy esperando encuesta
	CLR FLAG_WAITING_POLL
	;//Ya voy a atender la nueva encuesta
	CLR FLAG_NEW_POLL
	;//Vuelvo a encuestar la misma casilla de la hora
	JMP POLLING
	;//Si se oprimio MODE configuro la siguiente casilla de la hora(update control_mask,inc puntero y contador de iteraciones)
	AQUI0:
	;//Genero las condiciones para volver a apretar MODE
	CLR FLAG_MODE_PRESS
	;//Me quedan casillas por actualizar?
	DJNZ CONTADOR_ITERACIONES,ACTUALIZO2
	FINAL:;Aqui estoy si oprimi MODE 4 veces
		;//Actualizo la RAM de display
		CALL DISPLAY_RAM_UPDATE
		;//Rehabilito el conteo de la hora
		SETB TR0
		JMP WHILE_TRUE
	ACTUALIZO2:
	;//Actualizo la mascara de control de la lampara 7seg
	MOV A,MASCARA_CONFIG_MODE
	RL A
	MOV MASCARA_CONFIG_MODE,A
	;//Actualizo mi puntero de la RAM de hora
	INC R0
	;//Vuelvo al bucle
	JMP BUCLE_CONFIG
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:
	;//Le aviso al programa principal que se apreto el contador PRESS
	SETB FLAG_MODE_PRESS
	;//Inhabilito la EXTI 0
	CLR EX0
	;//Disparo el timer 1(delay 10ms)
	SETB TR1
            RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	;//Recarga de timer(tengo que hacerlo yo no tengo autorecarga)
	CLR TR0;Detengo temporalmente el conteo del timer 0
	MOV TH0,#HIGH(65536-5000);Recargo con los valores iniciales
	MOV TL0,#LOW(65536-5000)
	SETB TR0;Redisparo el timer 0
	;//Han pasado 5ms por lo que activo el refrescamiento
	SETB FLAG_REFRESH
	DJNZ CONTADOR_500ms,SALGO
	        ;//Recargo contador de 500m
	        MOV CONTADOR_500ms,#100;100 veces 5ms es 500ms
	        ;//Compruebo si llego la alarma
		JNB FLAG_ALARM,SIGO
                        ;//Preparo las condiciones para la prox. alarma		
		        DJNZ CONTADOR_5SEC,AQUI
		        MOV CONTADOR_5SEC,#10;
		        CLR FLAG_ALARM
			JMP SIGO
		        AQUI:
		        ;//Alterno el led
			CPL LED
		SIGO:
		DJNZ CONTADOR_1MIN,SALGO
			;//Recargo el contador de 1min
			MOV CONTADOR_1min,#120;120 veces 500ms es 1min
			;////////Si paso un min actualizo la hora
			;//Es necesario actualizar la RAM de display
			SETB FLAG_UPDATE
			CJNE UNID_MIN,#9,AQUI2
				;//Pasaron 10 min
				MOV UNID_MIN,#0
				;//Pregunto por las decenas de minuto
			CJNE DEC_MIN,#5,AQUI3
				;//Paso una hora
				MOV DEC_MIN,#0
				;//Pregunto por las decenas de las horas	
			CJNE DEC_HORAS,#2,AQUI4
				;//Paso un dia?
				CJNE UNID_HORAS,#3,AQUI5
					;//Paso un dia
					MOV DEC_HORAS,#0
					MOV UNID_HORAS,#0
					JMP SALGO
			AQUI5:
				;//Todavia no ha pasado un dia
				INC UNID_HORAS	
				JMP SALGO
			AQUI4:
				;//Han pasado 10 horas?
				CJNE UNID_HORAS,#9,AQUI5
				;//Han pasado 10 horas
				MOV UNID_HORAS,#0
				INC DEC_HORAS
				JMP SALGO
			AQUI3:
				;//No ha pasado una hora
				INC DEC_MIN
				JMP SALGO
			AQUI2:
				;//No han pasado diez min
				INC UNID_MIN
				JMP SALGO
	SALGO:
            RETI           

;/////Rutina TIMER1/////////
RUTINA_TIMER1:
	;//Recarga de timer(tengo que hacerlo yo no tengo autorecarga)
	CLR TR1;Detengo temporalmente el conteo del timer 1
	MOV TH1,#HIGH(65536-10000);Recargo con los valores iniciales
	MOV TL1,#LOW(65536-10000)
	;//Habilito la EXTI 0(ya paso el tiempo de rebote)
	SETB EX0
	;//Pregunto si esta esperando encuesta
	JNB FLAG_WAITING_POLL,SALGO2
	;//Redisparo el timer 1
	SETB TR1
	;//Si pasan 500ms nueva encuesta
	DJNZ CONTADOR_AUX_250ms,SALGO2
	;//Recargo el contador
	MOV CONTADOR_AUX_250ms,#25
	;//Aviso al prog. principal que debe encuestar again
	SETB FLAG_NEW_POLL
	SALGO2:
             RETI



;____________________Implementación de subrutinas______________________________________________________________
DISPLAY_RAM_UPDATE:
MOV R0,#2;Los valores de la hora se encuentran en R2
;//Necesito salvar el puntero de la RAM de display ya que su valor es critico para otras funciones
MOV A,R1
PUSH A
MOV R1,#70H;Puntero de la RAM de display
CLR FLAG_UPDATE;Ya estoy actualizando
MOV CONTADOR_ITERACIONES,#4;(for n = 4):
FOR_LOOP:
	MOV A,@R0;//Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo su valor correspondiente de la tabla
	MOV @R1,A;Lo almaceno en la RAM de display
	;//Actualizo los punteros
	INC R0
	INC R1
	;Fin del Loop?
	DJNZ CONTADOR_ITERACIONES,FOR_LOOP
	        ;//Recupero el valor del puntero de la RAM de Display
	        POP A
	        MOV R1,A
		RET
; _____________________________________________________________________________________________
DISPLAY_REFRESH:
        CLR FLAG_REFRESH;//Ya entre a refrescar
	MOV BUS_CONTROL_7SEG,#0FFH;Apago las lamparas
	MOV BUS_CONTROL_7SEG,MASCARA_CONTROL_7SEG;Activo el display que le corresponde
	MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	INC R1;Apunto a la proxima direccion de la RAM de display
	INC CONTADOR_7SEG
	CJNE CONTADOR_7SEG,#4,ROTA
		;//Reinicializo los valores(un barrido completo)
		MOV CONTADOR_7SEG,#0;Reinicializo conteo de lamparas
		MOV MASCARA_CONTROL_7SEG,#11111110B
		MOV R1,#70H;Reinicializo RAM de Display
	        RET
            ROTA:
		MOV A,MASCARA_CONTROL_7SEG
		RL A;Genero el nuevo codigo de barrido
		MOV MASCARA_CONTROL_7SEG,A
		RET
; _____________________________________________________________________________________________
CHECK_ALARM:
MOV CONTADOR_ITERACIONES,#4;(for n = 4):
MOV R0,#34H;//Apunto para la hora de la alarma establecida
;//Necesito salvar el puntero de la RAM de display ya que su valor es critico para otras funciones
MOV A,R1
PUSH A
MOV R1,#2;//Apunto para la zona de la hora actual
;//Iteracion de comparaciones
FOR_LOOP_2:
        ;//Cargo los valores actuales de comparacion
	MOV A,@R1
	MOV B,@R0
	CJNE A,B,TERMINO
		;//Me quedan casillas de la hora por revisar?
		DJNZ CONTADOR_ITERACIONES,ACTUALIZO
		;//Si estoy aqui activo la alarma y termino
		SETB FLAG_ALARM
		JMP TERMINO
		ACTUALIZO:
			;//Actualizo punteros para preguntar a la siguiente casilla
			INC R0
			INC R1
			JMP FOR_LOOP_2
TERMINO:
        ;//Recupero el valor del puntero de la RAM de Display
        POP A
        MOV R1,A
	RET
; _____________________________________________________________________________________________
MOSTRAR_LAMPARA:
	MOV A,@R0;Cargo el indice de la tabla
	MOVC A,@A+DPTR;Cargo el valor de la tabla
	MOV BUS_DATOS_7SEG,A;Lo muestro en la pantalla 7seg
RET
;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9




END























