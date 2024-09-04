;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_ADC EQU P0
RX_PIN EQU P3.0
TX_PIN EQU P3.1
INIC_CONV EQU P3.4
FIN_CONV EQU P3.2
BOCINA EQU P3.7
;____________________Declarando variables y máscaras__________________________________________
;////Contadores
CONTADOR_MUESTRAS EQU R7
CONTADOR_50ms EQU R6
CONTADOR_5sec EQU R5
;////Banderas
FLAGS EQU 20H
FLAG_MUESTRAS_TOMADAS EQU 20H.0
FLAG_BOCINA EQU 20H.1
FLAG_ERROR_DETECTED EQU 20H.2
FLAG_RESET EQU 20H.3
FLAG_MAYOR EQU 20H.4
FLAG_MENOR EQU 20H.5
FLAG_VALORES EQU 20H.6
FLAG_FIN_MSG EQU 20H.7
;////Variables
VALOR_MAX EQU 21H
VALOR_MIN EQU 22H
Indice_MSG EQU R2
DIRECCION_MIN EQU 22H
DIRECCION_MAX EQU 21H
VALOR_INICIAL_RAM EQU 26H;A partir de este valor estaran las 90 muestras
MASCARA_RX_READY EQU 01110100B
;//RAM de cifras
VALOR_CENTENAS EQU 23H
VALOR_DECENAS EQU 24H
VALOR_UNIDADES EQU 25H
;////Comandos
CMD_MAX EQU '1'
CMD_MIN EQU '2'
CMD_VAL EQU '3'
CMD_ALL EQU '4'
CMD_BOCINA EQU '5'
CMD_RESET EQU '6'

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
;//Apago la bocina
SETB BOCINA
;//Inactivo todas las banderas
MOV FLAGS,#0
;////Inicializo los contadores
MOV CONTADOR_MUESTRAS,#90
MOV CONTADOR_50ms,#200
MOV CONTADOR_5SEC,#100
MOV indice_msg,#0
;////Inicializo los punteros	
MOV R0,#VALOR_INICIAL_RAM;Inicializo puntero de la RAM

;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilito las IT de EXTI0, TIMER0,UART
SETB EX0
SETB ET0
SETB ES
SETB EA
;//Activo IT por flanco de caida
SETB IT0
;____________________Configurando los temporizadores__________________________________________
;//Timer 0 y Timer 1 -> modo 2(8 bits con autorrecarga),disparo por SW,temporizador
MOV TMOD,#00100010B
;//Timer 0 contador de 250us(256-250=6)
MOV TH0,#6
MOV TL0,#6
;//Timer 1 establece un BR=2,4Kb/s luego como:
;//TH1=256-(12MHz/(32 x 12 x 2400))=243 aprox
MOV TH1,#243
MOV TL1,#243
;//Disparo Timer 0
SETB TR0
;____________________Configurando el UART__________________________________________
;//Puerto Serie en modo 3(modo de 11 bits con bit de paridad), de momento no habilito la recepcion
SETB SM0
SETB SM1
;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
;//Espero a que todas las muestras se tomen
JNB FLAG_MUESTRAS_TOMADAS,$
;//Saco el mayor y el menor valor de las muestras
CALL CALCULAR_VALOR_MAX_MIN
;//Habilito la recepcion de datos
SETB REN
;//Espero por el cmd de reset
JNB FLAG_RESET,$
JMP INICIO

;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:;//Interupcion por el fin de conversion
	;//Leo la muestra actual
	MOV A,BUS_DATOS_ADC
	;//Lo almaceno en memoria e incremento el puntero
	MOV @R0,A
	INC R0
	;//Si termine de tomar muestras activo la bandera correspondiente
	DJNZ CONTADOR_MUESTRAS,FIN
		SETB FLAG_MUESTRAS_TOMADAS
		SETB FLAG_BOCINA		
        FIN:
	        RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	;////Pasaron 250us
	;//Tengo que tocar la bocina
	JNB FLAG_BOCINA,SIGO
		CPL BOCINA
	SIGO:
	DJNZ CONTADOR_50ms,SALGO
		;//Pasaron 50ms, recargo su contador
		MOV CONTADOR_50ms,#200
	DJNZ CONTADOR_5SEC,SALGO
		;//Pasaron 5sec recargo su contador y doy inicio de conversion
		MOV CONTADOR_5SEC,#100
		;//Doy inicio de conversion
		CLR INIC_CONV
		NOP
		SETB INIC_CONV
	SALGO:
            RETI           

;/////Rutina UART//////////
RUTINA_UART:;Comunicación Full-Duplex
        ;//Atiendo primero a la Rx más prioritaria
	JNB RI,Tx
	Rx:
        ;//Leo el caracter recibido
        MOV A,SBUF
        ;//Verifico la paridad par en el comando recibido
        JB P,Paridad_Impar
        Paridad_par:
        ;//Con paridad
        JB RB8,ERROR_RX
        JMP TODO_OK
        Paridad_Impar:
        JNB RB8,ERROR_RX
        JMP TODO_OK

        ERROR_RX:;//Se produjo un error en la comunicacion serie
        ;//Comunico el error y apago bocina
        SETB BOCINA
        CLR FLAG_BOCINA
        SETB FLAG_ERROR_DETECTED
        MOV DPTR,#TABLA_MSG_ERROR
        ;//Inhabilito la recepcion hasta que se termine la tarea de Tx
        CLR REN
        JMP LETS_TX
        TODO_OK:
        ;////Identifico la accion asociada al caracter
        CJNE A,CMD_RESET,PREGUNTO2
	        ;//Activo la bandera de reset
	        SETB FLAG_RESET
	        CLR EA
	        RETI
        PREGUNTO2:
        CJNE A,CMD_ALL,PREGUNTO3
	        ;//Activo las banderas de mandar tanto mayor, menor, como todos los valores
	        SETB FLAG_MENOR
	        SETB FLAG_MAYOR
	        SETB FLAG_VALORES
	        ;//Inhabilito la recepcion hasta que se termine la tarea de Tx
                CLR REN
                JMP LETS_TX
	PREGUNTO3:
	CJNE A,CMD_MAX,PREGUNTO4
	        ;//Activo la bandera de mandar mayor
	        SETB FLAG_MAYOR
       	        ;//Inhabilito la recepcion hasta que se termine la tarea de Tx
                CLR REN
                JMP LETS_TX
	PREGUNTO4:
	CJNE A,CMD_MIN,PREGUNTO5
		;//Activo la bandera de mandar menor
	        SETB FLAG_MENOR
	        ;//Inhabilito la recepcion hasta que se termine la tarea de Tx
                CLR REN
                JMP LETS_TX
	PREGUNTO5:
	
		;//Activo la bandera de mandar menor
	        SETB FLAG_VALORES
	        ;//Inhabilito la recepcion hasta que se termine la tarea de Tx
                CLR REN
                JMP LETS_TX
	PREGUNTO6:
	CJNE A,CMD_BOCINA,COMANDO_INVALIDO
		SETB BOCINA
		CLR FLAG_BOCINA
	COMANDO_INVALIDO:
		CLR RI
		RETI
        LETS_TX:
        ;//Limpio la bandera de solicitud de IT de Rx
        CLR RI

	Tx:
        ;////Identifico qué estoy transmitiendo
        ;//Estoy transmitiendo que ocurrió un error?
        
	        ;// Estoy transmitiendo un error
	        MOV DPTR,#TABLA_MSG_ERROR
	        CALL MANDAR_CARACTER
	        ;//Se termino de mandar el msg?
	        JNB FLAG_FIN_MSG,SALTO_INTERMEDIO
	        ;//Ya se acabo el mensaje no tengo que transmitir mas nada 
	        CLR FLAG_FIN_MSG
	        CLR FLAG_ERROR_DETECTED
	        ;//Espero el Reset
	        JMP $
	        JMP EXIT
        PREGUNTO7:
        ;//Estoy transmitiendo todos los valores?
        JNB FLAG_VALORES,PREGUNTO8
	        ;//Todavia estoy tx el msg o ya estoy mandando los valores
	        JB FLAG_FIN_MSG,MANDANDO_VALORES
		        ;//Estoy transmitiendo el mensaje todavia
		        MOV DPTR,#TABLA_MSG_TODOS
        	        CALL MANDAR_CARACTER
		        ;//Se termino de mandar el msg?
		        JNB FLAG_FIN_MSG,EXIT
		        CLR FLAG_FIN_MSG
		        ;//Ya se acabo el mensaje, empiezo a transmitir valores
	        MANDANDO_VALORES:
	        JB FLAG_FIN_MSG,MANDO
		        ;//Establezco condiciones iniciales
	                SETB FLAG_FIN_MSG
		        MOV R0,#VALOR_INICIAL_RAM;Apuntando a las muestras
		        MOV CONTADOR_MUESTRAS,#90
		        MOV R1,#VALOR_CENTENAS;Apuntando a la RAM CDU
		        MOV DPTR,#TABLA_MSG_NUMEROS;Apunto a los asci de numeros
	        MANDO:
		        CALL MANDAR_NUMERO
		        JB FLAG_FIN_MSG,EXIT
		        CLR FLAG_VALORES
		        JMP EXIT
        SALTO_INTERMEDIO:JMP EXIT
        PREGUNTO8:
        ;//Estoy transmitiendo el valor maximo?
        JNB FLAG_MAYOR,PREGUNTO9        
                ;//Todavia estoy tx el msg o ya estoy mandando el máximo
	        JB FLAG_FIN_MSG,MANDANDO_MAX
		        ;//Estoy transmitiendo el mensaje todavia
		        MOV DPTR,#TABLA_MSG_MAYOR
        	        CALL MANDAR_CARACTER
		        ;//Se termino de mandar el msg?
		        JNB FLAG_FIN_MSG,EXIT
		        CLR FLAG_FIN_MSG
		        ;//Ya se acabo el mensaje, empiezo a transmitir el maximo
		MANDANDO_MAX:
		JB FLAG_FIN_MSG,MANDO2
		        ;//Establezco condiciones iniciales
	                SETB FLAG_FIN_MSG
		        MOV R0,#DIRECCION_MAX;Apuntando al maximo
		        MOV CONTADOR_MUESTRAS,#1
		        MOV R1,#VALOR_CENTENAS;Apuntando a la RAM CDU
		        MOV DPTR,#TABLA_MSG_NUMEROS;Apunto a los asci de numeros
	        MANDO2:
		        CALL MANDAR_NUMERO
		        JB FLAG_FIN_MSG,EXIT
		        CLR FLAG_MAYOR
		        JMP EXIT
	PREGUNTO9:
        ;//Estoy transmitiendo el valor minimo?
	        JNB FLAG_MENOR,EXIT
		;//Todavia estoy tx el msg o ya estoy mandando el máximo
	        JB FLAG_FIN_MSG,MANDANDO_MIN
		        ;//Estoy transmitiendo el mensaje todavia
		        MOV DPTR,#TABLA_MSG_MENOR
        	        CALL MANDAR_CARACTER
		        ;//Se termino de mandar el msg?
		        JNB FLAG_FIN_MSG,EXIT
		        CLR FLAG_FIN_MSG
		        ;//Ya se acabo el mensaje, empiezo a transmitir el minimo
		MANDANDO_MIN:
		JB FLAG_FIN_MSG,MANDO3
		        ;//Establezco condiciones iniciales
	                SETB FLAG_FIN_MSG
		        MOV R0,#DIRECCION_MIN;Apuntando al minimo
		        MOV CONTADOR_MUESTRAS,#1
		        MOV R1,#VALOR_CENTENAS;Apuntando a la RAM CDU
		        MOV DPTR,#TABLA_MSG_NUMEROS;Apunto a los asci de numeros
	        MANDO3:
		        CALL MANDAR_NUMERO
		        JB FLAG_FIN_MSG,EXIT
		        CLR FLAG_MENOR
		        JMP EXIT
        EXIT:
        ;//Reviso si me queda algun tx en curso para habilitar la rx
        MOV A,#MASCARA_RX_READY
        ANL A,FLAGS
        JZ AQUI
        JMP ACA
        AQUI:
        SETB REN
        ACA:
        ;//Limpio la bandera de solicitud de IT de Tx
        CLR TI
	RETI
          

;____________________Implementación de subrutinas______________________________________________________________
CALCULAR_VALOR_MAX_MIN:
	;//Reinicializo el puntero de la RAM 
	MOV R0,#VALOR_INICIAL_RAM
	;//Inicializo el valor maximo de las muestras
	MOV VALOR_MAX,#00H
	MOV VALOR_MIN,#0FFH
	MOV CONTADOR_MUESTRAS,#90;Reinicializo el contador de muestras
	LOOP:
		;//Cargo el byte actual a comparar
		MOV A,@R0
		;//Actualizo el puntero de la RAM
		INC R0
		;//Pregunto iterativamente quien es mayor si el byte actual o el mayor hasta ahora
		CJNE A,VALOR_MAX,MAYOR
		;//Salto a preguntar si eres menor que el menor
		JMP MENOR
	MAYOR:
		;//Si eres menor que el mayor salta a preguntar por el menor
		JC MENOR
		;//Sobrescribo si es mayor
		MOV VALOR_MAX,A	
		JMP PREGUNTO
	MENOR:
	        CJNE A,VALOR_MIN,OVERW
		        ;//Aqui es igual asi que pregunto si termine y no sobrescribo nada
			JMP PREGUNTO
	OVERW:
	   ;//Si eres mayor que el menor salta al siguiente
	   JNC PREGUNTO
	   ;//Sino sobreescribo el menor
	   MOV VALOR_MIN,A
	
	PREGUNTO:
		;////Termine de comparar las 90 muestras?
		DJNZ CONTADOR_MUESTRAS,LOOP
RET

MANDAR_CARACTER:
        ;//Cargo la posicion del mensaje actual
	MOV A,INDICE_MSG
	;//Actualizo la posicion actial del mensaje
	INC INDICE_MSG
	;//Cargo el byte actual del mensaje
	MOVC A,@A+DPTR
	;//Configuro la paridad par en la tx
	JB P,TRANSMITO_1
	;//Aqui hay paridad par
        CLR TB8
        JMP SIGO_TX
        TRANSMITO_1:;//Aqui hay paridad impar
        SETB TB8
        SIGO_TX:
        ;//Verifico si es el final del mensaje
        JZ NO_TX
        ;//Sigo tx       
        MOV SBUF,A
        JMP ME_FUI
	NO_TX:
        ;//Final de msg regreso a condiciones especiales y no transmito
        MOV INDICE_MSG,#0
        SETB FLAG_FIN_MSG
        ME_FUI:
RET

MANDAR_NUMERO:
	;//Estaba tx un valor nuevo o no?
	CJNE R1,#VALOR_CENTENAS,CONTINUACION
		;////Nuevo valor		
		MOV A,@R0;Leo el caracter en memoria
		INC R0;Actualizo el puntero
		;//Proceso el valor actual
		MOV B,#100;Preparo el divisor
		DIV AB;Divido para obtener las centenas
		MOV VALOR_CENTENAS,A;En ACC se encuentra el cociente(las centenas)
		MOV A,B;En B se encuentra el resto(las decenas y unidades juntas)
		MOV B,#10;Preparo el divisor
		DIV AB;Divido y obtengo en ACC las decenas y en B las unidades
		MOV VALOR_DECENAS,A
		MOV VALOR_UNIDADES,B
	CONTINUACION:
		;//Verifico si ya termine con el valor actual
		CJNE R1,#VALOR_UNIDADES+1,KEEP_GOING
		;//Como tx una coma(00101100) es paridad impar
		SETB TB8
                ;//Transmito una coma
                MOV SBUF,#','
                ;//Paso a transmitir la siguiente muestra
		MOV R1,#VALOR_CENTENAS
		;//Era el ultimo de los valores de muestra?
		DJNZ CONTADOR_MUESTRAS,ESCAPE
		;//Termine de mandar todos los valores
		CLR FLAG_FIN_MSG
		JMP ESCAPE
		KEEP_GOING:
		MOV A,@R1;Cargo el valor CDU correspondiente
		INC R1;Actualizo el puntero
		MOVC A,@A+DPTR;Obtengo el ASCi del numero correspondiente
		;//Configuro la paridad par en la tx
		JB P,TX_1
		;//Aqui hay paridad par
	        CLR TB8
	        JMP KEEP_TX
	        TX_1:;//Aqui hay paridad impar
	        SETB TB8
	        KEEP_TX:
		MOV SBUF,A;Lo transmito	
ESCAPE:
	RET


;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
TABLA_MSG_ERROR:
DB 'Error de Paridad',0
TABLA_MSG_MAYOR:
DB 'Este es el mayor valor: ',0
TABLA_MSG_MENOR:
DB 'Este es el menor valor: ',0
TABLA_MSG_Todos:
DB 'Estos son todos los valores: ',0
TABLA_MSG_Numeros:
DB '0123456789',0




END























