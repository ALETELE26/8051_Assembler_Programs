
c_direcciones EQU R2
byteMSB EQU R7
byteLSB EQU R6	
DIVISOR EQU 3FH
COCIENTE EQU R4
RESTO EQU R3
ORG 00H
	MOV DPTR,#200H;Inicializando mi puntero de la tabla
	MOV C_DIRECCIONES,#00H;Inicializando mi contador de
        MOV B,#00H;Inicializo mi total actual
        MOV BYTEMSB,#00H;Inicializo mi BYTE mas significativo
        MOV BYTELSB,#00H;Inicializo mi BYTE menos significativo
        MOV DIVISOR,#100;Inicializo mi divisor
        MOV COCIENTE,#00H;Inicializo mi cociente
        MOV RESTO,#00H;Inicializo mi resto
INICIO:
        CALL TOTAL
        CALL PROMEDIO
        JMP INICIO
TOTAL:
        MOV A,C_DIRECCIONES;Cargo el indice del byte actual 
        MOVC A,@A+DPTR;Cargo el valor del byte actual
        ADD A,B;Sumo el byte actual al total 
        JNC SIGUE;Salta si no hay acarreo
	        INC BYTEMSB;Incremento el BYTE mas significativo de la suma
        SIGUE:
	        MOV B,A;Actualizo el total
	        INC C_DIRECCIONES;Actualizo mi siguiente direccion
	        CJNE R2,#100,TOTAL;Compruebo si me quedan mas sumandos
	        MOV BYTELSB,A;Salvo el valor del byte menos significativo de la suma
		RET
PROMEDIO:	
	CLR C;
	SUBB A,DIVISOR;Resta sucesiva de elementos
	JC UPDATE_MSB;Salta si necesite un prestamo
	        INC COCIENTE
		JMP PROMEDIO
	UPDATE_MSB:
	        INC COCIENTE
	        DJNZ BYTEMSB,PROMEDIO;Actualizo y comparo el byteMSB del dividendo
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
ORG 200H;100 Bytes Random
	DB 66H
	DB 0F0H
	DB 0A0H
	DB 0E3H
	DB 3FH
	DB 5DH
	DB 0EDH
	DB 9CH
	DB 0A8H
	DB 45H
	DB 0A9H
	DB 0CDH
	DB 44H
	DB 82H
	DB 86H
	DB 0AEH
	DB 82H
	DB 86H
	DB 69H
	DB 0B9H
	DB 58H
	DB 2AH
	DB 69H
	DB 46H
	DB 3CH
	DB 0CFH
	DB 0D6H
	DB 0C5H
	DB 95H
	DB 0B2H
	DB 4FH
	DB 0DAH
	DB 86H
	DB 99H
	DB 84H
	DB 3BH
	DB 0F7H
	DB 0F7H
	DB 0A5H
	DB 96H
	DB 17H
	DB 0D8H
	DB 0C9H
	DB 0CH
	DB 0D5H
	DB 67H
	DB 0B6H
	DB 0ABH
	DB 0DCH
	DB 0C1H
	DB 0D0H
	DB 41H
	DB 45H
	DB 0D0H
	DB 8FH
	DB 0A0H
	DB 11H
	DB 0C9H
	DB 0FCH
	DB 19H
	DB 0EEH
	DB 0C4H
	DB 0A4H
	DB 05DH
	DB 4DH
	DB 0C1H
	DB 0B7H
	DB 3AH
	DB 0CAH
	DB 11H
	DB 0C9H
	DB 0CFH
	DB 61H
	DB 17H
	DB 0DH
	DB 54H
	DB 14H
	DB 0E4H
	DB 6CH
	DB 9FH
	DB 0C5H
	DB 6FH
	DB 0CDH
	DB 0C1H
	DB 29H
	DB 8AH
	DB 0CFH
	DB 0CFH
	DB 0DDH
	DB 0F8H
	DB 32H
	DB 77H
	DB 6EH
	DB 8AH
	DB 0AFH
	DB 0F4H
	DB 0E8H
	DB 30H
	DB 0DAH
	DB 0FAH
END
