;
; LS 3-2.asm
;
; Created: 17.10.2025 21:32:10
; Author : basti
;


; Replace with your application code
;******* Progammstart ************************************************************************* 
			.Include "m16def.inc"		;Deklaration Atmega16

			.equ UMSCHALT_BIT  = 7		 ; Bit 7 in Port C für Umschaltung Hotend/Hotbed

			.def limit10	= r23
			.def limit2		= r22
			.def tolerance	= r21		 ; 
			.def solltemp   = r20		
			.def temphotbed = r18		 ; Register für eingelesene Ist-Temperatur
			.def temphotend = r19		 ; Register für eingelesene Ist-Temperatur
			.def akku 		= R16		 ; register 16 als "akku" definiert
			.def status 	= r17		 ; Status-Register für Port-Werte

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
			LDI status, LOW(RAMEND)	;lade akku mit lower Byte SRAM Ende
			OUT SPL, status			;Inhalt von akku ins Stackregister Stackpointer low ausgeben
			LDI status, HIGH(RAMEND);Lade akku mit higher Byte SRAM Ende

		;Ports einstellen
			LDI akku,0x00			;Wert von akku auf 0 setzen
			LDI status,0x00
			LDI temphotbed,0x00
			LDI temphotend,0x00
			LDI tolerance,0x00
			LDI limit2,0x00 
			LDI limit10,0x00
			LDI temphotend,0xff
			OUT DDRA,temphotend		;Port A 8 Eingänge
			LDI temphotbed,0xff			
			OUT DDRB,temphotbed		;Port B 8 Ausgänge
			LDI solltemp,0x00
			OUT DDRD,solltemp		;Port D 8 Eingänge
			LDI status,0x1D			;Port C 4 Ausgänge und 4 Eingang (00011101)
			OUT DDRC,status			;Port C Pin 3,4,5 und 7 als Ausgang und Pin 0,1,2 und 6 als Eingang
		

;******* Beginn des Hauptprogramms ********************************************************
MAIN_PROGRAM_LOOP:
		
			; --- A) Bewegungs- und Stillstandsüberwachung ---
			rcall WAIT_FOR_START		 ; Prüfe, ob 4 Minuten Stillstand erreicht sind
			
			; --- B) Filament-Ende Überwachung ---
			;rcall FILAMENT_CHECK		 ; Prüfe auf Bit 'Filament Ende' und aktiviere Stopp-Leuchte
			
			; --- C) Temperatur-Regelung: Hotend oder Hotbed ---
    
			; 1. Prüfe Umschalt-Bit (Port C Pin 7)
BIT_UMSCHALT:
			in status, PINC
			sbrs status, 7		; Teste Bit 7 (Umschalt_Bit).Springe, wenn Bit ist 1 (Umschalt_Bit)
			rjmp REGULATE_HOTBED

			;sbi PINC,7			;Setze Bit 7 in PORTC Umschalt_Bit
			cbi PORTC, 7		;Lösche Bit 7 in PORTC Umschalt_Bit 
			; --- D) Schleifenende ---
			rjmp MAIN_PROGRAM_LOOP       ; Beginne die Schleife erneut (kontinuierlicher Betrieb)


;******* Beginn Unterprogramm "Regulierung Hotend" ************************************************************
REGULATE_HOTEND:
	LDI tolerance,0x00
	LDI limit2,0x00
	in solltemp,PIND		; Lese Soll-Temp von Port D (8 Bit)
	in temphotend,PINA		; Lese ist Temperatur von Port A (8 bit) 
	
	; Berechnung Temperaturgrenze +/- 2 grad
	ldi tolerance,2	
	mov limit2,solltemp		
	sub limit2,temphotend
	cp limit2,tolerance
	BRLO heatdown
	
	rjmp heatup			
		
;******* Beginn Unterprogramm "Regulierung Hotbed" ************************************************************
REGULATE_HOTBED:
	LDI tolerance,0x00
	LDI limit10,0x00
    in solltemp,PIND		; Lese Soll-Temp von Port D (8 Bit)
	in temphotend,PINB		; Lese ist Temperatur von Port B (8 bit) 

	; Berechnung Temperaturgrenze +/- 10 grad
	ldi tolerance,10	
	mov limit10,solltemp		
	sub limit10,temphotbed
	cp limit10,tolerance
	BRLO heatdown
	
	rjmp heatup

;******* Beginn Unterprogramm "Heizung AN/AUS" ************************************************************
heatup:		
		sbi PORTC, 3		;Setze Bit 3 in PORTC Heizung An
		
		rjmp MAIN_PROGRAM_LOOP
heatdown:
		cbi PORTC, 3		;Lösche Bit 3 in PORTC Heizung Aus 
		rjmp MAIN_PROGRAM_LOOP

;******* Beginn Unterprogramm "Prüfen auf Bewegenung" ************************************************************
WAIT_FOR_START:
    in status, PINC         ; Lese den aktuellen Zustand der Port C Eingänge
    sbrs status, 0          ; Teste Bit 0 (START_BIT). Springe, wenn Bit ist 1 (Start gedrückt)
    rjmp WAIT_FOR_START     ; Wenn Start = 0, warte weiter

    rjmp FILAMENT_CHECK     ; Wenn Start = 1, fahre mit Filamentprüfung fort
	

;******* Beginn Unterprogramm "Prüfung des Filaments" ************************************************************
FILAMENT_CHECK:
    in status, PINC         ; Lese den aktuellen Zustand der Port C Eingänge
    sbrs status, 1          ; Teste Bit 1 (FILAMENT_WARN_BIT). Springe, wenn Bit ist 1 (< 20cm)
    rjmp BIT_UMSCHALT		; Wenn Bit 1 = 0, starte Hauptprogramm
	
    ; --- Wenn Filament < 20cm (Bit 1 = 1) ---
    rjmp WARN_AND_WAIT      ; Springe zur Warn- und Wartefunktion


	WARN_AND_WAIT:
    ; Aktiviere Warn-Leuchte (Port C Pin 5 auf High)
    sbi PORTC, 5            ; Setze Bit 5 in PORTC (Warn-LED an)

;******* Beginn Unterprogramm "Warten auf Auffüllen" ***********************************************************
WAIT_FOR_REFILL:
    in status, PINC         ; Lese den aktuellen Zustand der Port C Eingänge
    sbrc status, 1          ; Teste Bit 1 (FILAMENT_WARN_BIT). Springe, wenn Bit 1 ist 0 (Filament aufgefüllt)
    rjmp WAIT_FOR_REFILL    ; Wenn Bit 1 = 1, warte weiter

    ; --- Wenn Filament aufgefüllt (Bit 1 = 0) ---
    cbi PORTC, 5            ; Lösche Bit 5 in PORTC (Warn-LED aus)
    rjmp MAIN_PROGRAM_LOOP  ; Starte Hauptprogramm