;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________






;____________________Declarando variables y máscaras__________________________________________






ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
JMP INICIO
ORG 03H;Vector de EXTI 0
JMP RUTINA_EXT0
ORG 0BH;Vector de ITIMER 0
JMP RUTINA_TIMER0
ORG 13H;Vector de EXTI 1
JMP RUTINA_EXT1
ORG 1BH;Vector de ITIMER 1
JMP RUTINA_TIMER1
ORG 23H;Vector de UART tanto Tx como Rx
JMP RUTINA_UART




INICIO:
;____________________Inicializando variables y punteros__________________________________________ 


;____________________Configurando el mecanismo de interrupcion__________________________________________ 


;____________________Configurando los temporizadores__________________________________________


;____________________Configurando el UART__________________________________________


;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:













JMP WHILE_TRUE
;____________________Rutinas de interrupcion______________________________________________________________
;/////Rutina EXTI0/////////
RUTINA_EXT0:


            RETI

;/////Rutina TIMER0/////////
RUTINA_TIMER0:


            RETI           

;/////Rutina EXTI1/////////
RUTINA_EXT1:




             RETI

;/////Rutina TIMER1/////////
RUTINA_TIMER1:




             RETI
;/////Rutina UART//////////
RUTINA_UART:;Comunicación Full-Duplex
        ;//Atiendo primero a la Rx más prioritaria
	JNB RI,Tx
	Rx:
        ;//Leo el caracter recibido
        MOV A,SBUF
        ;//Ejecuto la acción a realizar
        ;......
        ;//Limpio la bandera de solicitud de IT de Rx
        CLR RI
        ;//Tengo que trasnsmitir también?
        JNB TI,EXIT
	Tx:
        ;//Chequeo si hay que seguir Tx
        ;.....
        ;//Muevo el caracter que quiero transmitir al ACC
        ;.....
        ;//Comienza la Tx del byte actual
        MOV SBUF,A
        ;//Limpio la bandera de solicitud de IT de Tx
        CLR TI
        EXIT:
	RETI
          

;____________________Implementación de subrutinas______________________________________________________________






;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////





END





















