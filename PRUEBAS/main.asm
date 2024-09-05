;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_7SEG EQU P1
BUS_CONTROL_7SEG EQU P2;CENTENAS->P2.0//DECENAS->P2.1//UNIDADES->P2.2//
BOCINA EQU P3.4

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
;//CONTADORES
CONTADOR_SEGUNDOS EQU R7
CONTADOR_PERSONAS EQU R6
POSTESCALADOR_1SEC EQU R5
INDICE_MSG EQU R4
;//VARIABLES
MASCARA_CONTROL_7SEG EQU R3 
CANT_MAX_PERSONAS EQU 25H
;//STATICS
VALOR_INICIAL_RAM EQU 29H
;//FLAGS
FLAGS EQU 20H
FLAG_2da_fase EQU 20H.0
FLAG_REINICIO EQU 20H.1
FLAG_MSG EQU 20H.2
;//RAM DE DISPLAY
CENTENAS EQU 26h
DECENAS EQU 27h
UNIDADES EQU 28h




ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0
JMP RUTINA_TIMER0
ORG 13H;Vector de EXTI 1
JMP RUTINA_EXT1
ORG 23H;Vector de UART tanto Tx como Rx
JMP RUTINA_UART




INICIO:
;____________________Inicializando variables y punteros__________________________________________ 
;//Banderas
MOV FLAGS,#0
;//Punteros
MOV DPTR,#TABLA_7SEG
MOV R0,#VALOR_INICIAL_RAM
MOV R1,#CENTENAS;Inicializo puntero de la RAM de display
;//Contadores
MOV contador_segundos,#0
MOV contador_personas,#0
MOV POSTESCALADOR_1SEC,#200
MOV INDICE_MSG,#0
;//Variables
MOV MASCARA_CONTROL_7SEG,#11111110B


;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilito la EXTI1(tecla)
SETB EA
SETB EX1
;//Configuro ambas interrupciones externas por frente de caida
SETB IT0
SETB IT1
;____________________Configurando los temporizadores__________________________________________
;//Timer 0(config:1ra fase):MODO 1, temporizador, disparo por HW
;//TImer 1: MODO 2, temporizador, disparo por SW
MOV TMOD,#00101001B
;//Timer 0: contador de 5ms(2500 CM)
MOV TH0,#HIGH(65536-2500)
MOV TL0,#LOW(65536-2500)
;//Timer 1: BR=1200 baudios (aprox) 
MOV TH1,#256-243
MOV TL1,#256-243
;____________________Configurando el UART__________________________________________
;//UART modo 1(10bits) con RX disable
SETB SM1
;____________________Ciclo_Infinito____________________________________________________

JNB FLAG_REINICIO,$
JMP INICIO
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:
	;//Es la primera persona que entró?
	CJNE CONTADOR_PERSONAS,#0,SIGO
	INC CANT_MAX_PERSONAS
	JMP SALGO	
   SIGO:;//Entró una nueva persona
        INC CONTADOR_PERSONAS
	;//Guardo en memoria la cantidad de segundos entre personas
        MOV A,CONTADOR_SEGUNDOS
	MOV @R0,A
	INC R0
	CALL DISPLAY_RAM_UPDATE
	;//Reinicio el conteo de segundos
	MOV CONTADOR_SEGUNDOS,#0
	;//Llegué al máximo de personas?
	MOV CONTADOR_PERSONAS,A
	CJNE A,CANT_MAX_PERSONAS,SALGO
	;////Reconfiguro a fase 2
	;//Se lo indico al programa
	SETB FLAG_2DA_FASE
	;//Apago el display
	MOV BUS_DATOS_7SEG,#0FFH
	;//Comienza la TX
	MOV DPTR,#TABLA_MSG
	SETB TI
	SETB TR1
	SETB FLAG_MSG
	;//Desactivo captura de muestras
	CLR EX0
	;////Reconfiguro timer 0 para que suene la bocina
	;//Timer 0: modo 2,temporizador disparo por SW
	MOV TMOD,#00100010B
	;//Recargo timer 0 como contador de 250 us(125CM)
	CLR TR0
	MOV TH0,#256-125
	MOV TL0,#256-125
	SETB TR0
SALGO:
            RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	JB FLAG_2DA_FASE,SUENO
	;//Estoy en la fase 1 recargo el timer
	CLR TR0
	MOV TH0,#HIGH(65536-2500)
	MOV TL0,#HIGH(65536-2500)
	SETB TR0
	;//Atiendo al display 7seg
	CALL DISPLAY_REFRESH
	DJNZ POSTESCALADOR_1SEC,ME_FUI
	;//Recargo postescalador
	MOV POSTESCALADOR_1SEC,#200
	;//Ha pasado 1 segundo
	INC CONTADOR_SEGUNDOS
	;//Si pasaron 190 segundos reconfiguro a segunda fase
	CJNE CONTADOR_SEGUNDOS,#190,ME_FUI
	;////Reconfiguro a fase 2
	;//Se lo indico al programa
	SETB FLAG_2DA_FASE
	;//Apago el display
	MOV BUS_DATOS_7SEG,#0FFH
	;//Comienza la TX
	MOV DPTR,#TABLA_MSG
	SETB TI
	SETB TR1
	SETB FLAG_MSG
	;//Desactivo captura de muestras
	CLR EX0
	;////Reconfiguro timer 0 para que suene la bocina
	;//Timer 0: modo 2,temporizador disparo por SW
	MOV TMOD,#00100010B
	;//Recargo timer 0 como contador de 250 us(125CM)
	CLR TR0
	MOV TH0,#256-125
	MOV TL0,#256-125
	SETB TR0
SUENO:
	CPL BOCINA
ME_FUI:
            RETI           

;/////Rutina EXTI1/////////
RUTINA_EXT1:
JB FLAG_2DA_FASE,REINICIO
;//Estoy en fase uno habilito la recepcion
SETB TR1
SETB REN
SETB ES
;//Desactivo la EXTI1
CLR EX1
JMP SALIDA
REINICIO:
SETB FLAG_REINICIO
SALIDA:
             RETI
;/////Rutina UART//////////
RUTINA_UART:;Comunicación Full-Duplex
        ;//Atiendo primero a la Rx más prioritaria
	JNB RI,Tx
	Rx:
        ;//Leo el caracter recibido
        MOV CANT_MAX_PERSONAS,SBUF
        ;//Inhabilito la rx
        CLR REN
        CLR TR1
        ;//Habilito muestreo de tiempo
        SETB EX0
        SETB ET0
        ;//Limpio la bandera de solicitud de IT de Rx
        CLR RI
        JMP EXIT
	Tx:
	;//Estoy tx mensaje o muestras?
	JB FLAG_MSG,MENSAJE
VALORES:;//Comienza la Tx del byte actual	
        MOV SBUF,@R0
        INC R0
        ;//Chequeo si hay que seguir Tx
        DJNZ CONTADOR_PERSONAS,LIMPIO
        ;//Termine de tx
        CLR ES
        ;//Espero por el reinicio
        SETB EX1
        JMP limpio
MENSAJE:;//Chequeo si hay que seguir Tx
        MOV A,INDICE_MSG
        MOVC A,@A+DPTR
        JZ FIN_MSG
        ;//Comienza la Tx del byte actual
        MOV SBUF,A
        JMP LIMPIO
FIN_MSG:;//Establezco condiciones iniciales para tx muestras
	MOV R0,#VALOR_INICIAL_RAM
	;//Mando el primer valor
	MOV SBUF,@R0
	INC R0
	DEC CONTADOR_PERSONAS 
	;//El programa debe saber que termine de transmitir el msg
	CLR FLAG_MSG 
 LIMPIO:;//Limpio la bandera de solicitud de IT de Tx
        CLR TI
        EXIT:
	RETI
          

;____________________Implementación de subrutinas______________________________________________________________
DISPLAY_RAM_UPDATE:
	;//Cargo la muestra actual y la proceso en centenas,decenas,unidades
	MOV A,CONTADOR_SEGUNDOS
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
	MOV BUS_CONTROL_7SEG,#0FFH;Apago las lamparas
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
Tabla_MSG:
DB 'Tiempos transcurridos',0




END






















