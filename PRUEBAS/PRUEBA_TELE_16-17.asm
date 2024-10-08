;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
PULSO EQU P3.7
LED EQU P3.6
;____________________Declarando variables y máscaras__________________________________________
;////Banderas
FLAGS EQU 20H
FLAG_FIN_MSG EQU 20H.0
FLAG_PULSO EQU 20H.1
FLAG_LED EQU 20H.2
FLAG_FIN_TX EQU 20H.3
FLAG_REBOTE EQU 20H.4
;////Contadores
CONTADOR_250ms EQU R2
CONTADOR_50ms EQU R7
Contador_500ms EQU R6
;////Variables
Indice_MSG EQU R3
SEMIPERIODO EQU R4
;//RAM de cifras
VALOR_CENTENAS EQU 23H
VALOR_DECENAS EQU 24H
VALOR_UNIDADES EQU 25H



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
;//Inactivo todas las banderas
MOV FLAGS,#0
;////Inicializo los contadores
MOV CONTADOR_250ms,#5; 50ms X 5 = 250ms
MOV CONTADOR_50MS,#200; 250us x 200 = 50ms
MOV CONTADOR_500MS,#10
MOV indice_msg,#0
;//Inicializo punteros
MOV R1,#VALOR_CENTENAS
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
;//Timer 0 contador de 250us(256-250=6)(semiperiodo del pulso inicial)
MOV TH0,#6
MOV TL0,#6
;//Timer 1 establece un BR=1,2Kb/s luego como:
;//TH1=256-(12MHz/(32 x 12 x 1200))=230 aprox
MOV TH1,#230
MOV TL1,#230
;____________________Configurando el UART__________________________________________
;//Puerto Serie modo 1 (de 10 bits,8 de datos mas el de parada y el de arranque)
SETB SM1
;//Dejo habilitada la Rx
SETB REN
;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
JMP $
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:
	;//Es la primera vez que se oprime?
	JB FLAG_PULSO,AQUI
	       ;//Confirmo es 1ra vez
	       ;//habilito Puerto Serie y timer 0 para generar el tren de pulsos
	       SETB TR0
	       SETB TR1
	       ;//Notifico que ya se oprimio el boton una vez
	       SETB FLAG_PULSO
	       ;//Deshabilito esta int para evitar el caer dos veces seguidas
	       CLR EX0
	       SETB FLAG_REBOTE
	       JMP SALIDA
	AQUI:
	;//Es la 2da vez desactivo UART y reconfiguro el timer 0 para parpadear el led
	CLR TR1
	MOV TMOD,#00100001B;Pongo timer 0 en modo 1 para contar 50 ms
	CLR TR0
	MOV TH0,#HIGH(65536-50000)
	MOV TL0,#LOW(65536-50000)
	SETB TR0
	CLR FLAG_PULSO;//le hago saber a la rutina timer 0 que parpadee
	CLR EX0;//Permanezco asi hasta REST	
	SALIDA:
            RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:
        JNB FLAG_REBOTE,HERE
        CPL PULSO
	;//Estoy evitando el rebote?,esto solo se realiza una vez
	DJNZ CONTADOR_50MS,SALGO
	DJNZ CONTADOR_500MS,SALGO
	;//pasaron 500ms ya estoy libre de mi dedo
	SETB EX0
	CLR FLAG_REBOTE
	JMP SALGO
	HERE:
	;//Estoy tranmitiendo pulsos o no?
	JB FLAG_PULSO,Tx_PULSO
        MODO_PARPADEO:
	        ;//Como el parpadeo es en modo 1 tengo que recargar
	        CLR TR0
		MOV TH0,#HIGH(65536-50000)
		MOV TL0,#LOW(65536-50000)
		SETB TR0
		;//Ya pasaron los 250ms( semiT para 2Hz)?
		DJNZ CONTADOR_250MS,SALGO
			;// Como pasaron 250ms recargo el contador y complemento el led
			MOV CONTADOR_250MS,#5
			CPL LED
			JMP SALGO
	Tx_PULSO:
		;//Solo complemento el pulso y ya(su frecuencia dependera del valor RX)
		;//no tengo que recargar porque cuando tx pulsos estoy en modo 2 el timer 0
		CPL PULSO
	SALGO:
            RETI           
;/////Rutina UART//////////
RUTINA_UART:;Comunicación Full-Duplex
        ;//Atiendo primero a la Rx más prioritaria
	JNB RI,Tx
	Rx:
        ;//Leo el caracter recibido
        MOV A,SBUF
        ;//Opero para hallar el semiperiodo del pulso
        ;//(ByteRx x 2)+ 50=T/2 del pulso
        MOV B,#2
        MUL AB
        MOV B,#50
        ADD A,B
        MOV SEMIPERIODO,A;Guardo el resultado del T/2 del pulso
        ;////Coloco su complemento a 256 en THO y TLO
        ;//La operacion seria 255 +1 -T/2
        MOV A,#255
        CLR C ;como voy a restar tengo que limpiar el acarreo por si acaso
        SUBB A,SEMIPERIODO
        INC A;//Este ya es el complemento a 256 
        CLR TR0
        MOV TH0,A
        MOV TL0,A
        SETB TR0;//Frecuencia de pulso actualizada!
        ;//Proceso el semiperiodo al dividirlo en CDU
        MOV A,SEMIPERIODO
        MOV B,#100;Preparo el divisor
	DIV AB;Divido para obtener las centenas
	MOV VALOR_CENTENAS,A;En ACC se encuentra el cociente(las centenas)
	MOV A,B;En B se encuentra el resto(las decenas y unidades juntas)
	MOV B,#10;Preparo el divisor
	DIV AB;Divido y obtengo en ACC las decenas y en B las unidades
	MOV VALOR_DECENAS,A
	MOV VALOR_UNIDADES,B
        ;//Hasta que no termine de tx el msg no vuelvo a rx
        CLR REN
        ;//Limpio la bandera de solicitud de IT de Rx
        CLR RI
	Tx:
	;//termine de tx ?
	JB FLAG_FIN_TX,TX_COMPLETADA
        ;//Identifico estoy tx caracteres o los valores CDU?
        JB FLAG_FIN_MSG,TX_CDU
	        ;//Aqui estoy transmitiendo el msg
	        MOV DPTR,#TABLA_MSG
	        CALL MANDAR_CARACTER
                ;//Se termino de mandar el msg?
	        JNB FLAG_FIN_MSG,EXIT
	        ;//Ya se acabo el mensaje, empiezo a transmitir valores
        TX_CDU:
	        ;//Configuro para mandar numeros
	        MOV DPTR,#TABLA_CDU
	        MOV A,@R1;Cargo el valor CDU correspondiente
		INC R1;Actualizo el puntero
		MOVC A,@A+DPTR;Obtengo el ASCi del numero correspondiente
		MOV SBUF,A;Lo transmito	
		;//Verifico si ya termine con la tx
		CJNE R1,#VALOR_UNIDADES+1,EXIT
		;//Regreso a valores iniciales
                MOV R1,#VALOR_CENTENAS
                SETB FLAG_FIN_TX
        TX_COMPLETADA:;//Ya puedo recibir de nuevo
	        CLR FLAG_FIN_TX
	        CLR FLAG_FIN_MSG
	        SETB REN    
        EXIT:
        ;//Limpio la bandera de solicitud de IT de Tx
	RETI
          

;____________________Implementación de subrutinas______________________________________________________________
MANDAR_CARACTER:
        ;//Cargo la posicion del mensaje actual
	MOV A,INDICE_MSG
	;//Actualizo la posicion actial del mensaje
	INC INDICE_MSG
	;//Cargo el byte actual del mensaje
	MOVC A,@A+DPTR
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





;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
TABLA_MSG:DB 'Semiperiodo igual a ',0
TABLA_CDU:DB '0123456789'




END























