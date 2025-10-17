;
; LS 3-2.asm
;
; Created: 17.10.2025 21:32:10
; Author : basti
;


; Replace with your application code
;******* Progammstart ************************************************************************* 
			.Include "m16def.inc"		;Deklaration Atmega16
			.DEF akku = R16
			.cseg						;Flashspeicher
			.org 0x0000					;Startadresse nach Neustart

			jmp init					; springe zum init um Stapel zu inizialisieren

;******* Interrupts ******************************************************************************
;Leer

;******* Initialisierung der MC-Komponenten ************************************************
			.org 0x2A					;Adresse Anwenderprogramm

		;Stapelspeicher (Stack) einrichten
init:		LDI akku, LOW(RAMEND)	;lade akku mit lower Byte SRAM Ende
			OUT SPL, akku			;Inhalt von akku ins Stackregister Stackpointer low ausgeben
			LDI akku, HIGH(RAMEND)	;Lade akku mit higher Byte SRAM Ende


		;Ports einstellen
			LDI akku,0x00			;Wert von akku auf 0 setzen
			OUT DDRA,akku			;Port A 8 Eingänge
			LDI akku,0xff			
			OUT DDRB,akku			;Port B 8 Ausgänge
			LDI akku,0x00
			OUT DDRD,akku			;Port D 8 Eingänge
			LDI akku,0x1f			;Port C 5 Ausgänge und 3 Eingang (00011111)
			OUT DDRC,akku			;Port C Pin 0 bis 5 als Ausgang und Pin 6-8 als Eingang

		

;******* Beginn des Hauptprogramms ********************************************************
main:		
			IN akku,PIND			;An PORTD anliegende Werte nach akku(R16) einlesen
			SBRC akku,1
			rjmp P1
			SBRC akku,2
			rjmp P2
			SBRC akku,3
			rjmp P3
			SBRC akku,4
			rjmp P4
			SBRC akku,5
			rjmp P5
			SBRC akku,6
			rjmp P6

		;Hier kommt das spätere Anwenderprogramm hin

			jmp main				;Sprung zur Sprungmarke "main" für Endlosschleife

;******* Beginn Unterprogramm "P1" ************************************************************
P1:
			
			ret
;******* Beginn Unterprogramm "P2" ************************************************************
P2:			
			ret
;******* Beginn Unterprogramm "P3" ************************************************************
P3:
			ret	
;******* Beginn Unterprogramm "P4" ************************************************************
P4:
			ret
;******* Beginn Unterprogramm "P5" ************************************************************
P5:
			ret
;******* Beginn Unterprogramm "P6" ************************************************************
P6:
			ret

;******* Interrupt-Service-Routine ************************************************************
;Leer