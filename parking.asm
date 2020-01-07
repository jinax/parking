__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC

;Programa para PIC 16F877A.
;Velocidad del Reloj = 4 MHz.
;Reloj instrucción: 250 kHz = 4 uS. 
;Perro Guardián deshabilitado.
;Tipo de Reloj XT.
;Protección de Código: OFF.
;**************************** Elegimos PIC ******************************

list p=16f877, f=inhx32

;************ Asignación de etiquetas de Registros de Funciones especiales a direcciones *********

#include <p16f877.inc>


;************* Igualdades *******************

Periodo equ D'255' ;periodo para el PWM
#DEFINE pulsadorEntrada PORTA,0
#DEFINE pulsadorSalida	PORTA,1
#DEFINE sensorEntrada	PORTA,2
#DEFINE sensorSalida	PORTA,3
#DEFINE ledRojoEntrada	PORTB,1
#DEFINE ledVerdeEntrada	PORTB,2
#DEFINE ledRojoSalida	PORTB,3
#DEFINE	ledVerdeSalida	PORTB,4
#DEFINE ledAmarillo		PORTB,5
#DEFINE ledNaranja		PORTB,6
#DEFINE banco1			BSF STATUS,RP0
#DEFINE banco0			BCF STATUS,RP0

;******************Registros*******************
CBLOCK 0x20
CuentaPlazas ;variable numero de plazas
Contador
ENDC

;****************Seccion Codigo de Reset********

ORG 0x00 ;Dirección del Vector de Reset
Goto Inicio ;Inicio del programa


;************Seccion de Configuracion*****************	
Org 0x05
Inicio	clrf 	PORTA
		clrf 	PORTB
		banco1
		movlw	0X06
		movwf 	ADCON1 ;Puerto A como digital
		movlw	b'00001111'
		movwf	TRISA ;4 primeros bits Puerto A como entrada
		movlw	b'00000000'
		movwf	TRISB ;Puerto B como salida, menos RB0	
		movlw  	b'11111001' 
		movwf	TRISC	;RC1 y RC2 como salidas
		movwf	Periodo-1
		movwf	PR2 	;carga PR2 con el periodo
		banco0
		movlw 	b'00000111'
		movwf	T2CON	
		call 	LCD_Inicializa ; Inicializar el LCD
		movlw 	b'00001010' ; 10 en binario
		movwf	CuentaPlazas ;el aparcamiento empieza con 10 plazas disponibles
		call 	MensajeInicio
		call 	CierraServo1
		call 	CierraServo2
		bsf 	ledRojoEntrada
		bsf 	ledRojoSalida
		
;****************************Principal*************************************

Principal 	btfsc	pulsadorEntrada ;comprueba si esta' pulsado el pulsador de entrada
			goto 	Pulsador2
			goto 	Pulsador1

;Control del Pulsador de entrada


Pulsador1	
			call 	Retardo_20ms
			call 	LCD_Borra    ;borra LCD
			movlw 	Mensaje0	;carga en W mensaje con el nombre del parking
			call 	LCD_Mensaje	;enseña por pantalla el mensaje con el nombre del parking
			call 	LCD_Linea2		;mueve cursor a la segunda linea
			movlw 	MensajeEntrada ;carga en W mensaje de bienvenida
			call 	LCD_Mensaje	;enseña en pantalla el mensaje de bienvenida
			bcf 	ledVerdeEntrada	;apaga led verde
;			call 	Retardo_1s	
			goto 	TestPlazasDisponibles	;verifica las plazas disponibles
			
;Control del Pulsador de salida

Pulsador2 	btfsc 	pulsadorSalida
			goto 	Principal
			call 	Retardo_20ms
			call 	LCD_Borra
			movlw 	Mensaje0
			call 	LCD_Mensaje
			call 	LCD_Linea2
			movlw 	MensajeSalida
			call 	LCD_Mensaje
			bcf 	ledVerdeSalida
;			call 	Retardo_1s
			goto 	AbreBarrera2

;control de la apertura de barrera

AbreBarrera1 	call 	AbreServo1
			 	bcf		ledRojoEntrada
				bsf 	ledVerdeEntrada
				btfsc	sensorEntrada
				goto	NoPasaCoche1
				goto	CierraBarrera1

;temporización del paso de coche por el sensor. Si el coche no pasa en 5 segundos, la barrera se cierra.

NoPasaCoche1	bsf 	ledNaranja
				incf 	Contador
				call 	Retardo_10ms ;tiempo suficiente para que vuelva al bucle anterior "AbreBarrera1" y verifique el sensor de Entrada
				movlw 	D'500'	; 10ms*500= 5000ms= 5s
				subwf 	Contador,W ;verifica si el contador es 500
				bcf 	ledNaranja
				btfss 	STATUS,Z ;si el Contador es 500 salta
				goto 	AbreBarrera1
				clrf 	Contador	;limpia el Contador para que pueda temporizar otra vez cuando se vuelva a pulsar el pulsador
				goto 	CierraBarreraSinCoche1 


AbreBarrera2 	call 	AbreServo2
			 	bcf 	ledRojoSalida
				bsf 	ledVerdeSalida
				btfsc	sensorSalida
				goto	NoPasaCoche2
				goto	CierraBarrera2

NoPasaCoche2	bsf 	ledNaranja
				incf 	Contador
				call 	Retardo_10ms
				movlw 	D'500'
				subwf 	Contador,W ;verifica si el contador es 500
				bcf 	ledNaranja
				btfss 	STATUS,Z ;si el Contador es 500 salta
				goto 	AbreBarrera2
				clrf 	Contador
				goto 	CierraBarreraSinCoche2

CierraBarrera1 	call 	CierraServo1
				decf 	CuentaPlazas
				bsf 	ledRojoEntrada
				bcf		ledVerdeEntrada
				call 	LCD_Borra
				call 	MensajeInicio
				goto 	Principal
				

CierraBarreraSinCoche1 	call CierraServo1
						bsf ledRojoEntrada
						bcf	ledVerdeEntrada
						call LCD_Borra
						call MensajeInicio
						goto Principal


CierraBarreraSinCoche2 	call CierraServo2
						bsf ledRojoSalida
						bcf	ledVerdeSalida
						call LCD_Borra
						call MensajeInicio
						goto Principal

CierraBarrera2 call CierraServo2
				incf CuentaPlazas
				bsf ledRojoSalida
				bcf ledVerdeSalida
				call LCD_Borra
				call MensajeInicio
				goto Principal

;test para verificar que hay plazas disponibles en el parking. Si hay plazas, va a subrutina
;para abrir barrera. Si no hay plazas visualiza en LCD mensaje de parking completo

TestPlazasDisponibles	bsf 	ledAmarillo ;enciende led amarillo
						call	Retardo_100ms
						bcf 	ledAmarillo ;apaga led amarillo
						movlw 	0x00
						subwf	CuentaPlazas,W ;verifica si el ContaPlazas es igual a 0, restando cuentaplazas de 0.
						btfss 	STATUS,Z ;si el ContaPlazas es igual a 0, salta
						goto	AbreBarrera1 ;va a la instrucción de abrir barrera de entrada
						call 	LCD_Borra
						movlw 	Mensaje0 ;guarda en W mensaje con nombre del parking
						call 	LCD_Mensaje ;visualiza mensaje con nombre del parking en primera linea 
						call	LCD_Linea2 ;envia cursor a segunda linea
						movlw	Mensaje0plazas ;guarda subrutina de mensaje de parking completo
						call 	LCD_Mensaje ; visualiza mensaje LCD de parking completo.
						goto	Principal


AbreServo1
				movlw  	b'00111100'
				movwf	CCP1CON
				movlw 	b'01011101' ;giro a 90º
				movwf 	CCPR1L
				call 	Retardo_20ms
				return
		
AbreServo2
				movlw	b'00111100'
				movwf	CCP2CON
				movlw 	b'01011101' ;giro a 90º
				movwf 	CCPR2L
				call 	Retardo_20ms
				return

CierraServo1
						movlw  	b'00011100'
						movwf	CCP1CON
						movlw 	b'00111000' ;giro a 0º
						movwf 	CCPR1L
						call 	Retardo_20ms
						return
					

CierraServo2
						movlw	b'00011100'
						movwf	CCP2CON
						movlw 	b'00111000' ;giro a 0º
						movwf 	CCPR2L
						call 	Retardo_20ms
						return


;***************** Visualiza en LCD "Plazas: (numero de plazas en decimal" **************

VisualizaCuentaPlazas 	

						call LCD_Linea2 ;cursor en la segunda linea
						movlw MensajeNumeroPlazas ;llama la subrutina
						call LCD_Mensaje ;visualiza el mensaje de numero de plazas
						movf CuentaPlazas,W ;envia el numero de plazas a W
						call BIN_a_BCD ;convierte binario a BCD
						call LCD_Byte ;visualiza el numero de plazas en el LCD
						return

;************************Subrutina MensajeInicio********************
; Mensaje Inicio: en primera linea visualiza nombre del parking. En la segunda linea visualiza numero de plazas

MensajeInicio	movlw 	Mensaje0 ;mensaje al inicio
				call 	LCD_Mensaje ;mensaje de inicio en pantalla
				call 	VisualizaCuentaPlazas
				return

;*************************Subrutina Mensajes*****************************
;subrutina que visualizará mensajes en la pantalla LCD 

Mensajes	addwf PCL,F

Mensaje0			DT"PARKING LOS COCHES",0x00
MensajeEntrada 		DT" BIENVENIDO",0x00
MensajeNumeroPlazas DT"PLAZAS LIBRES:",0x00 
MensajeSalida 		DT" BUEN VIAJE",0x00
Mensaje0plazas		DT" COMPLETO",0x00
;************************************************************************



;*************************** Librerías ********************************************************************
INCLUDE <RETARDOS.INC> ;llama librería de retardos
INCLUDE <LCD_4BIT_PORTD.INC> ;llama librería para gestionar LCD
INCLUDE <LCD_MENS.INC> ;llama librería para gestionar mensajes LCD
INCLUDE <BIN_BCD.INC> ;llama librería que convierte binarios en BCD
END
