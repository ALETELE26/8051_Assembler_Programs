;Este programa esta hecho para trabajar con un micro de 2pulsos de reloj por CM 
;y con un CLK de 2MHz
LED_PIN EQU P1.3
SWITCH_PIN EQU P2.5
DELAY_TIME_1 EQU R3
DELAY_TIME_2 EQU R4
DELAY_TIME_3 EQU R5
ORG 000H
        WHILE_TRUE:
        JB SWITCH_PIN,$;Quedate aqui mientras que el interruptor no se cierre
        CLR LED_PIN;Enciende el led
	CALL DELAY;500ms aprox
	SETB LED_PIN;Apaga el led
	CALL DELAY;500ms aprox
        JMP WHILE_TRUE

	
	DELAY:
	MOV DELAY_TIME_3,#4;1us
        HERE2:
		MOV DELAY_TIME_2,#250;4us
	HERE1:
		MOV DELAY_TIME_1,#250;1us x 250 x 4 = 1ms
		DJNZ DELAY_TIME_1,$;2us x 250 x 250 x4 = 500ms
		DJNZ DELAY_TIME_2,HERE1;2us x 250 x 4 = 2ms
		DJNZ DELAY_TIME_3,HERE2;8us
		RET;2us
END
	
	
	
	

