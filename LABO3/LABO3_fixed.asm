;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE______________________________________
BUS_DATOS_7SEG EQU P2
BUS_CONTROL_7SEG EQU P0
;  Centenas     Decenas    Unidades
;    P0.0         P0.1       P0.2
SENSOR_Tecla_Apretada EQU P3.2
LED EQU P3.7
TECLADO EQU P1
;  Columnas->P1.0 ... P1.2
;     Filas->P1.4 ... P1.7

;___________________Códigos del teclado matricial______________________________________
Codigo_0 EQU 00H
Codigo_1 EQU 01H
Codigo_2 EQU 02H
Codigo_3 EQU 03H
Codigo_4 EQU 04H
Codigo_5 EQU 05H
Codigo_6 EQU 06H
Codigo_7 EQU 07H
Codigo_8 EQU 08H
Codigo_9 EQU 09H
Codigo_Borrar EQU 7FH
Codigo_Enter EQU 0FFH

;___________________Códigos del Display 7 seg/ANODO_COMUN__________________________________________
Codigo_Cero EQU 0C0H
Codigo_Uno EQU 0F9H
Codigo_Dos EQU 0A4H 
Codigo_Tres EQU 0B0H
Codigo_Cuatro EQU 099H
Codigo_Cinco EQU 092H
Codigo_Seis EQU 082H
Codigo_Siete EQU 0F8H
Codigo_Ocho EQU 080H
Codigo_Nueve EQU 098H

;____________________Declarando variables y máscaras__________________________________________
RAM_CENTENAS EQU 30H
RAM_DECENAS EQU 31H
RAM_UNIDADES EQU 32H
ALMACEN_VALOR EQU 33H
COLUMNAS_VALOR EQU 34H
FILAS_VALOR EQU 35H
BARRIDO_TECLADO EQU 36H
DELAY_TIME1 EQU 39H
DELAY_TIME2 EQU 3AH
DELAY_TIME3 EQU 3BH
NUMERO_1 EQU 3CH
NUMERO_2 EQU 3DH
NUMERO_3 EQU 3EH
FLAGS EQU 33;//Direccion 21H
FLAG_BLINK EQU 33.0
FLAG_CENTENAS EQU 33.1
FLAG_DECENAS EQU 33.2
FLAG_UNIDADES EQU 33.3
FLAG_TECLA EQU 33.4
MASCARA_CONTROL_7SEG EQU 3FH 
CONTADOR_7SEG EQU R6
CONTADOR_FILAS EQU R3
CONTADOR_COLUMNAS EQU R4
CONT_PARPADEO EQU R2
CODIGO_PULSADO EQU R0
MASCARA_COLUMNAS EQU 07H;Porque son tres bits(3 columnas)
NUMERO_DE_FILAS EQU 4 ;p
NUMERO_DE_COLUMNAS EQU 3;q



ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXTI0





INICIO:
;____________________Configurando el mecanismo de interrupcion__________________________________________ 
;//Habilitando la EXTI 0
SETB EA
SETB EX0
;//Configurando la EXTI 0 como activa en frente de caida
SETB IT0
;____________________Inicializando variables y punteros__________________________________________ 
;//Inicializo la RAM de display en cero
MOV RAM_CENTENAS,#CODIGO_CERO
MOV RAM_DECENAS,#CODIGO_CERO
MOV RAM_UNIDADES,#CODIGO_CERO
;//Limpio todas las banderas
MOV FLAGS,#0
;//Inicializo el LED como encendido
CLR LED
;//Inicializo el valor de los numeros
MOV NUMERO_1,#0
MOV NUMERO_2,#0
MOV NUMERO_3,#0


;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
	CALL BARRIDO
        CALL OBTENER_CODIGO
	        ;//Una vez que obtuve mi codigo pulsado solo trabajo con la tabla 7seg
	        MOV DPTR,#TABLA_7SEG
	                ;//Se introdujo un numero o un comando?
	        CJNE CODIGO_PULSADO,#0AH,HERE
			HERE:;//Si el codigo es menor que 10 se apreto un numero sino una tecla de control
			JNC CHECK_BORRAR
			CALL GUARDAR_NUMERO
			JMP SALIDA
		CHECK_BORRAR:
		CJNE CODIGO_PULSADO,#CODIGO_BORRAR,HERE2
			;//BORRO REGISTRO DE NUMERO GUARDADO
			CALL BORRAR
			JMP SALIDA
		HERE2:;//SI ENTRO AQUI LE DI AL ENTER
			CALL ENTER
		SALIDA:
			JNB FLAG_BLINK,WHILE_TRUE;Salta si no hay que parpadear el led
				CALL PARPADEO
				CLR FLAG_BLINK
		
        
	


JMP WHILE_TRUE
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXTI0:;__Se activa al apretar una tecla___
	;//Le hago saber a la rutina principal que se apreto una tecla
	SETB FLAG_TECLA
	;//Inhabilito la interrupcion para eliminar cualquier rebote
	CLR EX0
	RETI

;____________________Implementación de subrutinas______________________________________________________________
DELAY_500ms: 
	       MOV DELAY_TIME1, #4
	Here5: MOV DELAY_TIME2, #250
	Here4: MOV DELAY_TIME3, #250
	       DJNZ DELAY_TIME3, $ ;2us x 250 x 250 x 4 = 500ms
	       DJNZ DELAY_TIME2, HERE4
	       DJNZ DELAY_TIME1, HERE5
	       RET

DELAY_5ms:
	MOV DELAY_TIME1,#10
   AQUI:MOV DELAY_TIME2,#250
	DJNZ DELAY_TIME2,$;2us x 10 x 250 = 5ms
	DJNZ DELAY_TIME1,AQUI
	RET

Delay_Rebote:
    Mov DELAY_TIME1,#250
Delay_Rebote_1: 
    MOV DELAY_TIME2,#250; 2us x 250 x 250 = 125ms
    DJNZ DELAY_TIME2,$
    DJNZ DELAY_TIME1,Delay_Rebote_1    
    RET
	
BARRIDO:
      SETB EX0;Habilito la interrupcion de tecla oprimida
      MOV CONTADOR_7SEG,#00H;Inicializo mi valor de displays 7seg
      ;//Inicializo contador de filas 
      MOV CONTADOR_FILAS,#0;i
      ;//Inicializo el esquema de barrido
      MOV MASCARA_CONTROL_7SEG,#11111110B
      MOV BARRIDO_TECLADO,#11101111B
      MOV R1,#30H;Inicializo el puntero para la RAM de display
      LOOP3:  
              ;///////Parte para barrer el display
              MOV BUS_CONTROL_7SEG,#0FFH;Apago las lamparas
	      MOV BUS_CONTROL_7SEG,MASCARA_CONTROL_7SEG;Activo el display que le corresponde
	      MOV BUS_DATOS_7SEG,@R1;Cargo el valor en la RAM de display correspondiente en el bus de datos
	      INC R1;Apunto a la proxima direccion de la RAM de display
	      INC CONTADOR_7SEG	      
	      ;////////Parte para barrer el teclado
	      ;//Cargo el codigo de barrido en las filas              
	      MOV TECLADO,BARRIDO_TECLADO
	      CALL delay_5ms
	      ;//Se oprimio una tecla?
	      JB FLAG_TECLA,FINALIZO
	      ;//NO SE PULSO TECLA,POR TANTO INCREMENTA LA CANT DE FILAS
	      INC CONTADOR_FILAS
      
	      CJNE CONTADOR_7SEG,#3,ROTA;Ve a rotar hasta alcanzar la cantidad de displays 7seg total
                     
		      ;/////Pregunto por la ultima fila del teclado
		      MOV A,BARRIDO_TECLADO
                      RL A;Genero el nuevo codigo de barrido
                      MOV BARRIDO_TECLADO,A;Lo guardo
		      ;//Cargo el codigo de barrido en las filas              
		      MOV TECLADO,BARRIDO_TECLADO
		      CALL delay_5ms
		      ;//Se oprimio una tecla?
		      JB FLAG_TECLA,FINALIZO
		      ;//Si aqui no se oprimio nada termino el barrido y vuelvo
		      JMP BARRIDO
              ROTA:
              MOV A,MASCARA_CONTROL_7SEG
	      RL A;Genero el nuevo codigo de barrido
	      MOV MASCARA_CONTROL_7SEG,A;Lo guardo
              MOV A,BARRIDO_TECLADO
              RL A;Genero el nuevo codigo de barrido
              MOV BARRIDO_TECLADO,A;Lo guardo	      
	      JMP LOOP3	
	     FINALIZO:
		     RET


OBTENER_CODIGO:
        ;//Como me di cuenta de que se apreto un boton limpio la bandera de tecla
        CLR FLAG_TECLA
	;//Inicializo mi puntero de la tabla
        MOV DPTR,#TABLA_TECLADO
        ;//Inicializo contador de columnas
        MOV CONTADOR_COLUMNAS,#0;j
        ;//Leo las columnas
        MOV COLUMNAS_VALOR,TECLADO
        ;//Aislo las columnas
        ANL COLUMNAS_VALOR,#MASCARA_COLUMNAS
        ;//Gran delay para evitar el rebote
        CALL DELAY_REBOTE
	TECLA_OPRIMIDA:;//SE PULSO TECLA,POR TANTO OBTENGO SU COLUMNA
		;//Busco el bit de la columna	
		MOV A,COLUMNAS_VALOR
		RRC A
		;Es el bit correcto?
		JNC MATCH_COLUMN
			;//No es la columna,salta pa la otra
			INC CONTADOR_COLUMNAS
			;//Sera la ultima columna?
			CJNE CONTADOR_COLUMNAS,#NUMERO_DE_COLUMNAS,TECLA_OPRIMIDA
			;//Estado imposible termino
			JMP FINAL
			MATCH_COLUMN:;SI ES LA COLUMNA!!!!
			;/////Obtengo indice de la tabla A=q*i+j
			MOV A,CONTADOR_FILAS
			MOV B,#NUMERO_DE_COLUMNAS
			;//Multiplico el indice de filas por el total de columnas
			MUL AB
			;//Al resultado le sumo el indice de columnas
			ADD A,CONTADOR_COLUMNAS
			;//Obtengo el codigo de la tecla
			MOVC A,@A+DPTR
			;//Lo guardo
			MOV CODIGO_PULSADO,A
			FINAL:
			RET
		  

PARPADEO:
	;//Inicializo mi contador de 5seg en cero
	MOV CONT_PARPADEO,#0
        LOOP2:
	SETB LED
	CALL DELAY_500MS
	CLR LED
	CALL DELAY_500MS
	INC CONT_PARPADEO
	CJNE CONT_PARPADEO,#5,LOOP2
	;//Ya pasaron los 5seg
	;//Reinicializo el led como encendido
	CLR LED
	RET		      

GUARDAR_NUMERO:
	;//Guarde un numero en las centenas?
	JB FLAG_CENTENAS,TERMINE;Si se cumple no guardo nada
		;//Si no se cumplio pregunto por las decenas
		JB FLAG_DECENAS,GUARDO_CENTENAS;Si ya guarde las decenas me toca guardar las centenas
			;//Si no se cumplio pregunto por las unidades
			JB FLAG_UNIDADES,GUARDO_DECENAS;Si ya guarde las unidades me toca guardar las decenas
				JMP GUARDO_UNIDADES;Si no, me toca guardar las unidades
        GUARDO_CENTENAS:
        MOV NUMERO_3,CODIGO_PULSADO;//Guardo mi tercer numero pulsado en memoria
        MOV A,CODIGO_PULSADO;//Cargo mi indice de la tabla
        MOVC A,@A+DPTR;//Cargo mi valor de la tabla
        MOV RAM_CENTENAS,A;//Actualizo la RAM de display
        SETB FLAG_CENTENAS;//Activo la bandera de las centenas
        JMP TERMINE
        GUARDO_DECENAS:
        MOV NUMERO_2,CODIGO_PULSADO;//Guardo mi segundo numero pulsado en memoria
        MOV A,CODIGO_PULSADO;//Cargo mi indice de la tabla
        MOVC A,@A+DPTR;//Cargo mi valor de la tabla
        MOV RAM_DECENAS,A;//Actualizo la RAM de display
        SETB FLAG_DECENAS;//Activo la bandera de las decenas
        JMP TERMINE
        GUARDO_UNIDADES:
        MOV NUMERO_1,CODIGO_PULSADO;//Guardo mi primer numero pulsado en memoria
        MOV A,CODIGO_PULSADO;//Cargo mi indice de la tabla
        MOVC A,@A+DPTR;//Cargo mi valor de la tabla
        MOV RAM_UNIDADES,A;//Actualizo la RAM de display
        SETB FLAG_UNIDADES;//Activo la bandera de las decenas   
        TERMINE:
	        RET
BORRAR:
	JB FLAG_CENTENAS,BORRAR_CENTENAS;Si hay centenas las borro
        JB FLAG_DECENAS,BORRAR_DECENAS;Si hay decenas las borro
	JB FLAG_UNIDADES,BORRAR_UNIDADES;Si hay unidades las borro
	JMP SALGO;Sino salgo y no hago nada
	BORRAR_CENTENAS:
		;//Reinicializo en cero las centenas en el display y en la ram
		MOV RAM_CENTENAS,#CODIGO_CERO
		MOV NUMERO_3,#0
		;//Desactivo la bandera de las centenas
		CLR FLAG_CENTENAS
		JMP SALGO
	BORRAR_DECENAS:
		;//Reinicializo en cero las decenas en el display y en la ram
		MOV RAM_DECENAS,#CODIGO_CERO
		MOV NUMERO_2,#0
		;//Desactivo la bandera de las decenas
		CLR FLAG_DECENAS
		JMP SALGO
	BORRAR_UNIDADES:
		;//Reinicializo en cero las unidades en el display y en la ram
		MOV RAM_UNIDADES,#CODIGO_CERO
		MOV NUMERO_1,#0
		;//Desactivo la bandera de las unidades
		CLR FLAG_UNIDADES
	SALGO:
		RET
		
ENTER:
	JNB FLAG_UNIDADES,ACABE;Si no he guardado nigun numero no hago nada
	;//Verifico si el numero entrado es menor que 256
	MOV A,NUMERO_3
	MOV B,#100
	MUL AB
	JB OV,REINICIALIZO;Si hay overflow reinicializo sin activar la bandera
	PUSH ACC
	MOV A,NUMERO_2
	MOV B,#10
	MUL AB
	ADD A,NUMERO_1
	POP B
	ADD A,B
	JB OV,REINICIALIZO;Si hay overflow reinicializo sin activar la bandera
	;//Sino el numero entrado es menor que 256 y activo el parpadeo
	SETB FLAG_BLINK
        REINICIALIZO:
        ;//Reinicializo la RAM de display con el codigo cero
        MOV RAM_CENTENAS,#CODIGO_CERO
	MOV RAM_DECENAS,#CODIGO_CERO
	MOV RAM_UNIDADES,#CODIGO_CERO
        ;//Inicializo el valor de los numeros
	MOV NUMERO_1,#0
	MOV NUMERO_2,#0
	MOV NUMERO_3,#0
	;//Limpio las banderas
        CLR FLAG_CENTENAS
	CLR FLAG_DECENAS
	CLR FLAG_UNIDADES
	ACABE:
		RET




;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
TABLA_Teclado:
DB CODIGO_1,CODIGO_2,CODIGO_3,CODIGO_4,CODIGO_5,CODIGO_6,CODIGO_7,CODIGO_8,CODIGO_9,CODIGO_BORRAR,CODIGO_0,CODIGO_ENTER
Tabla_7seg:
DB CODIGO_CERO,CODIGO_UNO,CODIGO_DOS,CODIGO_TRES,CODIGO_CUATRO,CODIGO_CINCO,CODIGO_SEIS,CODIGO_SIETE,CODIGO_OCHO,CODIGO_NUEVE



END























