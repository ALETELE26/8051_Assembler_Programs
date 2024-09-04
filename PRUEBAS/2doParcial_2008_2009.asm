;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_ADC EQU P0
BUS_DATOS_7SEG	EQU P2
BUS_CONTROL_7SEG EQU P1;Centenas P1.0___Decenas P1.1___UnidadesP1.2
LED EQU P3.7
RX_PIN EQU P3.0
TX_PIN EQU P3.1
INIC_CONV EQU P3.4
FIN_CONV EQU P3.2


;___________________Códigos del Display 7 seg/ANODO_COMUN__________________________________________
Codigo_0	EQU	0C0H
Codigo_1	EQU	0F9H
Codigo_2	EQU	0A4H
Codigo_3	EQU	0B0H
Codigo_4	EQU	099H
Codigo_5	EQU	092H
Codigo_6	EQU	082H
Codigo_7	EQU	0F8H
Codigo_8	EQU	080H
Codigo_9	EQU	098H

;____________________Declarando variables y máscaras__________________________________________
;//RAM de Display
CENTENAS EQU 70H
DECENAS EQU 71H
UNIDADES EQU 72H
;//Variables 
MUESTRA_ACTUAL EQU 29H
VALOR_INICIAL_RAM EQU 30H
MASCARA_CONTROL_7SEG EQU R3 
CMD_START EQU 41H
CMD_TX_BEGIN EQU 31H
CMD_RX_READY EQU 43H
;//Contadores 
CONTADOR_MUESTRAS EQU R7
CONTADOR_500ms EQU R6
;//Bandera
FLAG_WAITING_CMD EQU F0


ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0
JMP RUTINA_TIMER0
ORG 23H;Vector de UART tanto Tx como Rx
JMP RUTINA_UART




INICIO:
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo la mascara de control
MOV MASCARA_CONTROL_7SEG,#11111110B
;//Inicializo contadores
MOV CONTADOR_MUESTRAS,#25
MOV CONTADOR_500MS,#100;5ms x 100 = 500ms
;////Inicializo los punteros	
MOV R0,#VALOR_INICIAL_RAM;Inicializo puntero de la RAM
MOV R1,#CENTENAS;Inicializo puntero de la RAM de display
MOV DPTR,#TABLA_7SEG;Puntero de la tabla
;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilito las IT de EXTI0, TIMER0,UART
SETB EX0
SETB ET0
SETB ES
SETB EA
;//Activo IT por flanco de caida
SETB IT0
;____________________Configurando los temporizadores__________________________________________
;// Timer 1 -> modo 2(8 bits con autorrecarga),disparo por SW,temporizador
;//Timer 0 -> modo 1(16 bits sin autorecarga),disparo por SW,temporizador
MOV TMOD,#00100001B
;//Timer 1 establece un BR=9600b/s: 11.059MHz/(32 *12 * (256-FDH))=9600b/s aprox
MOV TH1,#0FDH
MOV TL1,#0FDH
;//Timer 0 tiene una base de conteo de 5ms, nuestro CM=1,085us y como 4608 X 1,085us = 5ms aprox:
MOV TH0,HIGH(65536-4608)
MOV TL0,LOW(65536-4608)
;Solo disparo Timer 0 al recibir el comando de inicio
;____________________Configurando el UART__________________________________________
;//Puerto Serie modo 1 (de 10 bits,8 de datos mas el de parada y el de arranque)
SETB SM1
;//Dejo habilitada la Rx
SETB REN
;//Genero mi baud rate
SETB TR1
;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
JMP $
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:;//!FIN DE CONVERSION!
	;//Leo la muestra actual
	MOV MUESTRA_ACTUAL,BUS_DATOS_ADC
	;//Tiene paridad inpar?
	MOV A,MUESTRA_ACTUAL
	JB P,GUARDO
	JMP AQUI
	;//Como tiene paridad impar la guardo en memoria
GUARDO:
	MOV @R0,MUESTRA_ACTUAL
	INC R0
	;//Ya llené el buffer de muestras?
	DJNZ CONTADOR_MUESTRAS,AQUI
	;//Envio Peticion de Tx y enciendo el led
	MOV SBUF,#CMD_TX_BEGIN
	SETB FLAG_WAITING_CMD
	CLR LED;Enciendo el led
	MOV BUS_DATOS_7SEG,#0FFH;//Apago el display
	CLR TR0;//Detengo la toma de muestras
	;//Reinicializo puntero de la RAM y el contador de muestras
	MOV R0,#VALOR_INICIAL_RAM
	MOV CONTADOR_MUESTRAS,#25
	JMP SALGO
AQUI:
	;//Actualizo RAM de display
	CALL DISPLAY_RAM_UPDATE
SALGO:
RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:;!Pasaron 5ms!
	;//Refresco display
	CALL DISPLAY_REFRESH
	DJNZ Contador_500ms,ME_FUI
	;//Sí, pasaron 500ms recargo el contador
	MOV CONTADOR_500ms,#100
	;//Doy inicio de conversion
	CLR INIC_CONV
	NOP
	NOP
	SETB INIC_CONV
ME_FUI:
RETI

;/////Rutina UART//////////
RUTINA_UART:;Comunicación Full-Duplex
        ;//Atiendo primero a la Rx más prioritaria
	JNB RI,Tx
	Rx:
        ;//Leo el caracter recibido
        MOV A,SBUF
        CJNE A,#CMD_START,ACUI
        ;//Habilito la toma de muestras
        SETB TR0
   ACUI:;//Recibi cmd de handshake completado?
        CJNE A,#CMD_RX_READY,ANUI
        ;//Tengo que transmitir los valores de las muestras
        SETB TI
        CLR FLAG_WAITING_CMD
        ;//No puedo recibir hasta que se complete la tx
        CLR REN
   ANUI:;//Limpio la bandera de solicitud de IT de Rx
        CLR RI
        ;//Tengo que trasnsmitir también?
        JNB TI,EXIT
	Tx:
	JB FLAG_WAITING_CMD,LIMPIO
	CJNE R0,#VALOR_INICIAL_RAM+25,SIGO_TX
	;//Ya transmiti los 25 valores regreso a condiciones iniciales
	MOV R0,#VALOR_INICIAL_RAM
	SETB TR0;//Retomo captura de muestras
	SETB LED;Apago el led
	SETB REN;//Retomo la recepcion de cmd
	JMP LIMPIO
SIGO_TX:;//Transmito el valor actual
        MOV SBUF,@R0
        INC R0
        ;//Limpio la bandera de solicitud de IT de Tx
 LIMPIO:CLR TI
        EXIT:
	RETI
;____________________Implementación de subrutinas______________________________________________________________

DISPLAY_RAM_UPDATE:
	;//Cargo la muestra actual y la proceso en centenas,decenas,unidades
	MOV A,MUESTRA_ACTUAL
        MOV B,#100;Preparo el divisor
	DIV AB;Divido para obtener las centenas
	MOV CENTENAS,A;En ACC se encuentra el cociente(las centenas)
	MOV A,B;En B se encuentra el resto(las decenas y unidades juntas)
	MOV B,#10;Preparo el divisor
	DIV AB;Divido y obtengo en ACC las decenas y en B las unidades
	MOV DECENAS,A
	MOV UNIDADES,B
;//Cargo los valores de 7 seg correspondientes a los resultados y los almaceno en la RAM de display
        MOV A,R0;//Salvo el valor del puntero de la RAM
        PUSH ACC
        MOV R0,#CENTENAS;//Apunto a la primera posicion de la RAM de display
        FOR_LOOP:;(for i=3,i++)
        MOV A,@R0
        MOVC A,@A+DPTR
        MOV @R0,A
        INC R0
        CJNE R0,#UNIDADES+1,FOR_LOOP
        POP ACC
        MOV R0,A;//Recupero el valor del puntero de la RAM
RET

DISPLAY_REFRESH:
;	MOV BUS_CONTROL_7SEG,#0FFH;Apago las lamparas
	MOV BUS_CONTROL_7SEG,MASCARA_CONTROL_7SEG;Activo el display que le corresponde
	MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	INC R1;Apunto a la proxima direccion de la RAM de display
	CJNE R1,#UNIDADES+1,ROTA
		;//Reinicializo los valores(un barrido completo)	
		MOV MASCARA_CONTROL_7SEG,#11111110B
		MOV R1,#CENTENAS;Reinicializo RAM de Display
	        RET
            ROTA:
		MOV A,MASCARA_CONTROL_7SEG
		RL A;Genero el nuevo codigo de barrido
		MOV MASCARA_CONTROL_7SEG,A
RET
;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0, Codigo_1, Codigo_2, Codigo_3, Codigo_4, Codigo_5, Codigo_6, Codigo_7, Codigo_8, Codigo_9





END























