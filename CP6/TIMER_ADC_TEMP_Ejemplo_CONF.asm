;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
BUS_DATOS_ADC EQU P0
BUS_DATOS_7SEG EQU P1
;Control Decenas Unidades CENTESIMAS DECIMAS
;          P1.0    P1.1       P1.2    P1.3
;
BUS_CONTROL_7SEG EQU P2
Inicio_ADC EQU P3.0
Bocina EQU P3.1
Fin_ADC EQU P3.2
Tecla EQU P3.3
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
;RAM DE DISPLAY
DECENAS EQU 70H
UNIDADES EQU 71H
CENTESIMAS EQU 72H
DECIMAS EQU 73H

;Banderas
FLAGS EQU 20H
FLAG_BOCINA EQU 20H.0
FLAG_REFRESH EQU 20H.1
FLAG_TECLA EQU 20H.2
FLAG_PROMEDIO EQU 20H.3
;Contadores
CONTADOR_MUESTRAS EQU R2
CONTADOR_5ms EQU R3
CONTADOR_1sec EQU R4
CONTADOR_DIRECCIONES EQU R5
CONTADOR_7SEG EQU R6
CONTADOR_ITERACIONES EQU R7


;Variables
COCIENTE EQU 23H
RESTO EQU 24H
DIVISOR EQU 26H
MASCARA_CONTROL_7SEG EQU 27H
BYTEMSB EQU 28H

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
;//Inicializo las banderas inactivas
MOV FLAGS,#0
;//Inicializo la RAM de Display para que me muestre cero
MOV DECENAS,#CODIGO_0
MOV UNIDADES,#CODIGO_0
MOV CENTESIMAS,#CODIGO_0
MOV DECIMAS,#CODIGO_0
;//Inicializando los punteros
MOV R0,#30H;Puntero de la RAM de muestras
MOV R1,#70H;Puntero de la RAM de display
MOV DPTR,#TABLA_7SEG;Puntero de la tabla
;//Inicializo contadores
MOV CONTADOR_7SEG,#0;Indica la cantidad de lamparas actualizadas
MOV CONTADOR_MUESTRAS,#50;Indica la cantidad de muestras que faltan por guardar
MOV CONTADOR_1SEC,#200;200 veces 5ms es 1sec
MOV CONTADOR_5ms,#20;20 veces 250us es 5ms
;//Inicializo la bocina como apagada
CLR BOCINA
;//Inicializo la mascara de los 7seg
MOV MASCARA_CONTROL_7SEG,#11111110

MOV DIVISOR,#255

;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;Configurando las interrupciones externas como activas con frente de caida
SETB IT0
SETB IT1
;//Habilitando la interrupcion externa 0(El fin de conversion) y el timer o
SETB EA
SETB EX0
SETB ET0
;//Mas prioridad para el timer 0
SETB PT0
;____________________Configurando los temporizadores__________________________________________
;//Para contar 250 us(256-250=6)
MOV TH0,#6
MOV TL0,#6
;//T0:Disparo por Software, Modo de 8bits con recarga, modo temporizador
MOV TMOD,#00000010
;//Disparo el temporizador 0
SETB TR0

;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	;//Si ya aprete la tecla inhabilito la interrupcion
	JNB FLAG_TECLA,CONTINUO
	        ;Desactivo la interrupcion de la tecla
		CLR EX1
		;Desactivo la bandera
		CLR FLAG_TECLA
	CONTINUO:
	;//Tengo que refrescar el display?
	JNB FLAG_REFRESH,SIGO2
		CALL DISPLAY_REFRESH
	SIGO2:
	;//Tengo que promediar ya los valores de temp obtenidos?
	JNB FLAG_PROMEDIO,WHILE_TRUE
		;//Desactivo la bandera ya que entre a hacer el promedio
		CLR FLAG_PROMEDIO
		CALL SACAR_PROMEDIO
	        ;//Retomo la captura de muestras
		SETB EX0
JMP WHILE_TRUE
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:;Rutina de fin de conversion ADC
	;//Leo el valor del ADC 
	MOV A,BUS_DATOS_ADC
	;//Ejecuto las operaciones de la funcion T(Celsius)=((60/255)*(MUESTRA_ADC))+10
	MOV B,#60
	MUL AB
	CALL DIVISION
	MOV A,COCIENTE
	ADD A,#10
	;//Guardo el resultado(con resolucion de un grado) en la RAM
	MOV @R0,A
	INC R0
	;//Actualizo cantidad de muestras restantes por tomar y actuo en correspondencias
	DJNZ CONTADOR_MUESTRAS,FINALIZO
	        MOV CONTADOR_MUESTRAS,#50;Recargo el contador de muestras
		SETB FLAG_PROMEDIO;Ya tome todas las muestras necesarias para sacar el promedio
		SETB FLAG_BOCINA;Ya tengo que sonar la bocina
		MOV R0,#30H;Reinicializo el puntero de la RAM
		;//Detengo la captura de muestras
		CLR EX0
		;//Habilito la interrupcion de la tecla 
		SETB EX1
	FINALIZO:
	        RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
	;//Complemento la bocina si esta activa
	JNB FLAG_BOCINA,SIGO
		CPL BOCINA
	SIGO:
	DJNZ CONTADOR_5MS,TERMINO
	RECARGO_7seg:
		MOV CONTADOR_5ms,#20
		;//Es necesario refrescar display
		SETB FLAG_REFRESH
		;//El contador de 5ms es el reloj del de 1sec
		DJNZ CONTADOR_1SEC,TERMINO
		RECARGO_ADC:
			MOV CONTADOR_1SEC,#200
			;//Doy inicio de conversion
				CLR INICIO_ADC
				NOP
				NOP
				SETB INICIO_ADC
       TERMINO:
		RETI

;/////Rutina EXTI1/////////
RUTINA_EXT1:;Rutina de la tecla
        ;//Apago la bocina y su bandera
	CLR BOCINA
	CLR FLAG_BOCINA
	;//Activo la bandera de la tecla
	SETB FLAG_TECLA
        RETI
        
;____________________Implementación de subrutinas______________________________________________________________
DIVISION:;(ENTRADAS->MSB(B),LSB(A),DIVISOR;SALIDAS->COCIENTE,RESTO)
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
SACAR_PROMEDIO:
        MOV B,#0;Inicializo acumulador aux
        MOV BYTEMSB,#00H;Inicializo mi BYTE mas significativo
        MOV CONTADOR_DIRECCIONES,#50;Cantidad de direcciones por recorrer
        MOV CONTADOR_ITERACIONES,#1;Cant. de decimales +1(porque el cero cuenta)
        MOV DIVISOR,#50;Para sacar el promedio divido entre la cant. de muestras
        LOOP:
	MOV A,@R0;Cargo el indice del byte actual 
	INC R0;Actualizo mi puntero de la RAM
	ADD A,B;Sumo el byte actual al total
        JNC SIGUE;Salta si no hay acarreo
	        INC BYTEMSB;Incremento el BYTE mas significativo de la suma
        SIGUE:
	        MOV B,A;Actualizo el total
	        DJNZ CONTADOR_DIRECCIONES,LOOP;Compruebo si me quedan mas sumandos
	        ;//Aqui tengo en A el LSB y tengo que cargar el MSB en B para poder dividir
	        MOV B,BYTEMSB
	        CALL DIVISION;Aqui ya termino de sacar el promedio
	        ;//Divido el cociente entre diez para tener decenas y unidades
	        MOV A,COCIENTE
	        MOV B,#10
	        DIV AB;El cociente tiene las decenas y el resto las unidades
	        ;//Guardo el valor de las decenas y las unidades
	        MOV DECENAS,A
	        MOV UNIDADES,B
	        ;//Me preparo pal bucle de buscar decimales
	        MOV R0,#72H;Apuntando a las centesimas
                BUCLE:;(Entradas->RESTO,SALIDAS->VALORES DECIMALES)
	        ;//Para convertir el resto en decimal multiplico x10 el resto y divido de nuevo
	        MOV A,#10
	        MOV B,RESTO
		MUL AB
		;//Compruebo si el resultado me dio en dos bytes o no
		PUSH A;Respaldo el acumulador
		MOV A,B
		JZ SOLO_UN_BYTE
		MAS_DE_UN_BYTE:
			;Si tengo 2 bytes divido por restas sucesivas
			POP A;Recupero el acumulador
			CALL DIVISION
			;Guardo el cociente de la nueva division como el valor decimal
			MOV @R0,COCIENTE
			INC R0
			DJNZ CONTADOR_ITERACIONES,BUCLE
			JMP ACT_DISPLAY_RAM
		SOLO_UN_BYTE:
			POP A;Recupero el acumulador
			MOV B,DIVISOR;Inicializo mi divisor
			DIV AB
			;Guardo el cociente de la nueva division como el valor decimal
			MOV @R0,COCIENTE
			;//Para alimentar posibles iteraciones
			MOV RESTO,B
			INC R0
			DJNZ CONTADOR_ITERACIONES,BUCLE
	        ACT_DISPLAY_RAM:
	        MOV R0,#70H;Apunto a la RAM de DISPLAY
	        MOV CONTADOR_ITERACIONES,#4;Porque tengo 4 display 7_seg
	        FOR_CANTIDAD_7SEG:
	        MOV A,@R0;Cargo el indice de la tabla
	        MOVC A,@A+DPTR;Cargo el valor de la tabla
	        MOV @R0,A;Lo guardo en la RAM de display
	        INC R0;Incremento mi puntero de la RAM
	        ;//Esto se repite para cada 7SEG
	        DJNZ CONTADOR_ITERACIONES,FOR_CANTIDAD_7SEG
	        ;//Reinicializo mi puntero RAM de muestras
	        MOV R0,#30H
	        ;//Retorno a mi valor de divisor por defecto
	        MOV DIVISOR,#255 
	        RET

;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9




END






















