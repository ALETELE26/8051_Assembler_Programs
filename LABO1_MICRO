;///////////Autor: Alejandro Iglesias Gutierréz//////////////////////////////////////////////
;___________________Declaracion del HARDWARE___________________________________________
; g f e d c b a -> P3.6 ... P3.0	Display 7seg
; I3 ... I0 -> P0.3 ... P0.0            Interruptores
; D3 ... D0 -> P1.3 ... P1.0            LEDs
;___________________Códigos del Display 7 seg/ANODO_COMUN__________________________________________
Codigo_0 EQU 0C0H
Codigo_1 EQU 0F9H
Codigo_2 EQU 0A4H 
Codigo_3 EQU 0B0H
Codigo_4 EQU 099H
Codigo_5 EQU 092H
Codigo_6 EQU 082H
Codigo_7 EQU 0B8H
Codigo_8 EQU 080H
Codigo_9 EQU 098H
Codigo_A EQU 088H
Codigo_B EQU 083H
Codigo_C EQU 0C6H
Codigo_D EQU 0A1H
Codigo_E EQU 086H
Codigo_F EQU 08EH
;____________________Declarando variables y máscaras__________________________________________
DISPLAY_7SEG EQU P3
SWITCHES EQU P0
LEDS EQU P1
DELAY_TIME_1 EQU R3
DELAY_TIME_2 EQU R4
DELAY_TIME_3 EQU R5
VERIFICADOR EQU 07FH
VERIFICADOR_2 EQU 07EH
MASCARA_SWITCHES EQU 00001111B
MASCARA_SWITCH3 EQU 08H
MASCARA_SWITCH2 EQU 04H
MASCARA_SWITCH1 EQU 02H
MASCARA_SWITCH0 EQU 01H
MASCARA_LED3_ON EQU 0F7H
MASCARA_LED2_ON EQU 0FBH
MASCARA_LED1_ON EQU 0FDH
MASCARA_LED0_ON EQU 0FEH
MASCARA_LED3_VER EQU 08H
MASCARA_LED2_VER EQU 08H
MASCARA_LED1_VER EQU 0CH
MASCARA_LED0_VER EQU 0EH
 

ORG 00H;///////////////INICIO DEL PROGRAMA//////////////////////////////////////////////////////////
;____________________Inicializando variables y punteros__________________________________________ 
MOV DPTR,#TABLA_7SEG
;____________________Ciclo_Infinito____________________________________________________
WHILE_TRUE:
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
ANL A,#MASCARA_SWITCHES;Limpio los bits mas significativos(P0.7-P0.4)
CALL ENCIENDO_7SEG
CHECKING_I3: 
ANL A,#MASCARA_SWITCH3;Verifico si el switch 3 esta cerrado
CJNE A,#MASCARA_SWITCH3,CHECKING_I2;si el switch 3 no esta cerrado salta
	MOV A,#MASCARA_LED3_ON;Cargo la mascara para que se encienda el led3
        MOV VERIFICADOR,#MASCARA_SWITCH3;Cargo la mascara para  verificar el led3
        MOV VERIFICADOR_2,#MASCARA_LED3_VER;Cargo la mascara para  verificar el led3
	CALL PARPADEO_LED
	JMP CHECKING_I3
CHECKING_I2: 
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
ANL A,#MASCARA_SWITCH2;Verifico si el switch 2 esta cerrado
CJNE A,#MASCARA_SWITCH2,CHECKING_I1;si el switch 2 no esta cerrado salta
	MOV A,#MASCARA_LED2_ON;Cargo la mascara para que se encienda el led2
        MOV VERIFICADOR,#MASCARA_SWITCH2;Cargo la mascara para  verificar el led2
         MOV VERIFICADOR_2,#MASCARA_LED2_VER;Cargo la mascara para  verificar el led2
	CALL PARPADEO_LED
	JMP CHECKING_I3
CHECKING_I1:
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
ANL A,#MASCARA_SWITCH1;Verifico si el switch 1 esta cerrado
CJNE A,#MASCARA_SWITCH1,CHECKING_I0;si el switch 1 no esta cerrado salta
	MOV A,#MASCARA_LED1_ON;Cargo la mascara para que se encienda el led1
        MOV VERIFICADOR,#MASCARA_SWITCH1;Cargo la mascara para  verificar el led1
        MOV VERIFICADOR_2,#MASCARA_LED1_VER;Cargo la mascara para  verificar el led1
	CALL PARPADEO_LED
	JMP CHECKING_I3
CHECKING_I0:
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
ANL A,#MASCARA_SWITCH0;Verifico si el switch 0 esta cerrado
CJNE A,#MASCARA_SWITCH0,WHILE_TRUE;si el switch 0 no esta cerrado salta
	MOV A,#MASCARA_LED0_ON;Cargo la mascara para que se encienda el led0
        MOV VERIFICADOR,#MASCARA_SWITCH0;Cargo la mascara para  verificar el led0
        MOV VERIFICADOR_2,#MASCARA_LED0_VER;Cargo la mascara para  verificar el led0
	CALL PARPADEO_LED
	JMP WHILE_TRUE
;____________________Implementación de subrutinas______________________________________________________________
PARPADEO_LED:
MOV LEDS,A;Enciendo el led
CALL delay_500ms;
MOV LEDS,#0FFH;Apago el led
CALL delay_500ms;
MOV B,A;Guardo temporalmente el valor de la máscara que me enciende el led
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
ANL A,#MASCARA_SWITCHES;Limpio los bits mas significativos(P0.7-P0.4)
CALL ENCIENDO_7SEG
ANL A,VERIFICADOR;se mantendrá cerrado el interruptor actual?
CJNE A,VERIFICADOR,AQUI2;Salta si se abrio el interruptor actual
AQUI:;Si entra acá es que se mantuvo cerrado el interruptor actual
MOV A,SWITCHES;Leo el estado de los interruptores
CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1') 
ANL A,VERIFICADOR_2;aplico la mascara de verificacion
CJNE A,VERIFICADOR,VERIFICA;Hay algun switch con mas jerarquía cerrado?
CONTINUA:
MOV A,B;Recupero el valor de la máscara que me enciende el led
JMP PARPADEO_LED
VERIFICA:
JNC AQUI2;Salta si hay algun switch con mas jerarquía cerrado
JMP CONTINUA
AQUI2:
RET



ENCIENDO_7SEG:
	MOVC A,@A+DPTR;Cargo el codigo correspondiente del 7seg
	MOV DISPLAY_7SEG,A;Enciendo los leds correspondientes
	MOV A,SWITCHES;Leo el estado de los interruptores
        CPL A;Cambio a lógica positiva(los interruptores cerrados significan un '1' lógico)
        ANL A,#MASCARA_SWITCHES;Limpio los bits mas significativos(P0.7-P0.4)
	RET
;Este delay genera aprox 500ms solo el micro tiene 12Pulsos_CLK/CM y CLK=12MHz
DELAY_500ms:
MOV DELAY_TIME_3,#4;1us
HERE2:
	MOV DELAY_TIME_2,#250;4us
HERE1:
	MOV DELAY_TIME_1,#250;1us x 250 x 4 = 1ms
	DJNZ DELAY_TIME_1,$;2us x 250 x 250 x4 = 500ms
	DJNZ DELAY_TIME_2,HERE1;2us x 250 x 4 = 2ms
	DJNZ DELAY_TIME_3,HERE2;8us
	RET;2us

;////////////////////////Tablas en memoria de Progama//////////////////////////////////////////////////////////////////
Tabla_7seg:
DB Codigo_0,Codigo_1,Codigo_2,Codigo_3,Codigo_4,Codigo_5,Codigo_6,Codigo_7,Codigo_8,Codigo_9,Codigo_A,Codigo_B,Codigo_C,Codigo_D,Codigo_E,Codigo_F
END
