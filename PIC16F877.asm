		LIST 	P=PIC16F877
		include	<P16f877.inc>
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

;*************************************************************************************
; Welcome! Prepare to engage in a bingo game.
; In the system's background, a continuous square wave emanates from PORTC <2> , initially at a 5kHz frequency, 
; generated via a clock interrupt using timer 0. 
; At PORTA <0> , a sine wave is introduced, requiring a press of the button at PORTA <5? to capture an analog voltage,
; which is then converted into a digital signal.
; Using a PORTB keyboard,your task is to estimate the voltage and enter your guess, followed by the # symbol.
; You can change your mind as long as you haven't pressed #.  Once you press the # key, your choice is saved. 
; Please ensure your input is within the valid range, which consists of numbers between 0 and 5 only.  
; If your estimation is correct, the background square wave shifts to 25 kHz, 
; displaying a victory message; otherwise, an error message appears.
; You can restart the game by pressing the PORTA <5> button for another guess.

		org		0x00

reset:	goto	initialization 		; Start the main program that will run serially
		org		0x04				; Timer 0 runs in the background at the same time as the main program
 		goto	Square_wave			; The timer is initialized to a value and counted from the entered value until 0xFF and when it ends the PC changes to address 0x04
									; and from there it performs the interrupt.
									; Initially the interruption is a square wave with a frequency of 5 kHz
		org		0x10

initialization:

		bcf     STATUS, RP0    		; Clear the RP0 bit in the STATUS register to select Bank 0.
   		bcf     STATUS, RP1    		; Clear the RP1 bit in the STATUS register to ensure Bank 0 is selected.

	   
       						   		; Clear the contents of the register PORTE (Port E's output register) to set all bits to low.
	    clrf    PORTC          		; Clear the contents of the register PORTC (Port C's output register) to set all bits to low.
		clrf    PORTA		   		; Clear the contents of the register PORTA (Port A's output register) to set all bits to low.

    	bsf     STATUS, RP0    		; Set the RP0 bit in the STATUS register to select Bank 1.
	
							  		; configures the ADCON1 register with specific bit values, which will affect how the Analog-to-Digital Converter operates in microcontroller
	    movlw   0x06          		; Load the literal value 0x06 (6 in decimal) into the working register (WREG).
	    movwf   ADCON1         		; Move the value in WREG to the register ADCON1.

		clrf	TRISE				; PortE output : Clear the contents of the register TRISE (Port E's data direction register) to set all bits as outputs.
		clrf	TRISD				; PortD output : Clear the contents of the register TRISD (Port D's data direction register) to set all bits as outputs.
		clrf	TRISC				; PortC output : Clear the contents of the register TRISC (Port C's data direction register) to set all bits as outputs.
		movlw 	0xff				; All the pins on Port A of the PIC microcontroller to be configured as inputs 
		movwf 	TRISA

		movlw	0x0f   	   			; Sets the lower 4 bits of Port B as inputs (RB0-RB3) and the upper 4 bits as outputs (RB4-RB7).
		movwf	TRISB   	   		; Move the value in WREG to the register TRISB (Port B's data direction register).
		bcf		INTCON, GIE   		; Bit clear (0) the GIE (Global Interrupt Enable) bit in the INTCON register -Disables global interrupts.
		bcf 	OPTION_REG, 7 		; Bit clear (0) the seventh bit in the OPTION_REG register. Enables the weak pull-up resistors on Port B..
		bcf 	STATUS, RP0    		; Bit clear (0) the RP0 bit in the STATUS register (bank selection). Switch back to Bank 0 for CPU register access.


	
		movlw	0xE1				
		movwf	TMR0				; Initializes Timer 0 with the value 0xE1
		clrf	INTCON				; clears (sets to 0) all bits in the INTCON (Interrupt Control) register. INTCON is a register that controls various interrupt-related settings.
		bsf		INTCON, T0IE		; Enable T0-Enabling this bit means that the microcontroller will generate an interrupt when the Timer 0 overflows-0xff.
		bsf		STATUS, RP0			; Selects register bank 1 for CPU register access.
		bsf		INTCON, GIE			; Enables global interrupts. 
		movlw	0x01				; Configures Timer 0 with a prescaler of 1:4.
		movwf	OPTION_REG			
		clrf	TRISC				; Sets all pins in Port C as outputs
		bcf		STATUS, RP0			; Switches back to register bank 0 for CPU register access.-

		movlw	0xE5				; Initially the square wave has a frequency of 5 kHz so the appropriate value entered is 0xE5				
		movwf	0x53				; The register is responsible for the frequency of the square wave. value stored:0xE5 frequency:5kHz,value stored:0xFE frequency:25kHz.
		call	startAGame			; message on the LCD display
		call 	lulaa3	
		call 	pressTheButton		; message on the LCD display
		
		
click:	
		btfsc	PORTA ,0x05			; Waiting for POTRA <5> to be clicked
		goto	click

Unclicked:
		btfss	PORTA ,0x05			; Waiting for POTRA <5> to be released
		goto	Unclicked


; A/D Store the digital value in the register 0x53
A_d:	
		bcf		STATUS, RP0
		bsf		STATUS, RP0			; Bank1 
		movlw	0x02
		movwf	ADCON1				; all PORTA Analog 	
	
									; format : 6 lower bit of ADRESL =0
		movlw	0xff
		movwf	TRISA				; PortA input

		bcf		STATUS, RP0			; Bank0 
	
		movlw	0x81
		movwf	ADCON0				;Fosc/32, channel_0, ADC on
		call	d_20				;Delay TAC

lulaa:	
		bsf		ADCON0, GO			;start conversion
waitc:	
		btfsc	ADCON0, GO			;wait end of conversion
		goto	waitc
		call	d_4

		; Check voltage level
		movlw	0x33				; 1V = (1/5)*2^8 = 51 --> 0x33
		subwf	ADRESH, w
		btfss	STATUS, C	
		goto	value_0				; if it small than 1V
	
		movlw	0x66				; 2V = (2/5)*2^8 = 102 --> 0x66
		subwf	ADRESH, w
		btfss	STATUS, C	
		goto	value_1				; if it small than 2V
	
		movlw	0x99				; 3V = (3/5)*2^8 = 153 --> 0x99	
		subwf	ADRESH, w
		btfss	STATUS, C	
		goto	value_2				; if it small than 3V
	
		movlw	0xcc				; 4V = (4/5)*2^8 = 204 --> 0xcc
		subwf	ADRESH, w
		btfss	STATUS, C	
		goto	value_3				; if it small than 4V
	
		movlw	0xff				; 5V = (5/5)*2^8 = 256 --> 0xff
		subwf	ADRESH, w
		btfss	STATUS, C	
		goto	value_4				; if it small than 5V
	
		movlw	0x05				; Converting the analog to digital value - 5	
		movwf	0x56				; Place the value in register 0X56
	

continue:	
		call	WaitingForGuess		; message on the LCD display
		call 	lulaa3
		call 	init				; Cleaning and initializing the LCD display screen

guess:
		movlw	0xc7 				; The cursor is in the middle of the second line on the LCD display
		movwf	0x20
		call	lcdc				; write data to the LCD
		call	mdel				; medium delay.
		
		call 	wkb					; Waiting for input from keyboard PORTB
		clrw						; Clears the contents of the W register.Sets the W register to 0x00.

		movf 	0x35,0				; Saving the first value received from the keyboard 
		movwf 	0x51				; in the register 0x51
		
		movf 	0x35,0				; Saving the first value received from the keyboard 
		movwf 	0x54				; in the register 0x51

									; Checking if the first pressed key is #.
		movlw	0x0f				; The # key value is 0xf. 
		subwf   0x35,w				; We will perform a subtraction between this value and the value of the number obtained from the keypad
		btfsc	STATUS,Z			; If the subtraction operation is performed and its result is 0, the zero flag rises to one and the next line is performed.
		goto	guess				; The first key pressed is # - Enter a value from the keypad again
									; The first entry is correct - continue

		movlw	0x30				; Adding the value 0x30 to the hexadecimal number found in register 0x35 is used to convert a numeric value represented 
		addwf	0x54,0				; in hexadecimal to its corresponding ASCII character representation for display on an LCD
		movwf 	0x20
		call	lcdd				; write data to the LCD
		call	mdel				; medium delay.


hash_mark:
		movlw	0xc7 				; The cursor is in the middle of the second line on the LCD display
		movwf	0x20
		call	lcdc				; write data to the LCD
		call	mdel				; medium delay.
		
		call 	wkb					; Waiting for input from keyboard PORTB
		clrw						; Clears the contents of the W register.Sets the W register to 0x00.

		movf 	0x35,0				; Saving the second value received from the keyboard 
		movwf 	0x52				; in the register 0x52

									; Checking if the second pressed key is #.
		movlw 	0x0f				; The # key value is 0xf. 
		subwf 	0x35,w				; We will perform a subtraction between this value and the value of the number obtained from the keypad
		btfss	STATUS,Z			; If the subtraction operation is performed and its result is 0, the zero flag rises to one and the next line is --not-- executed..
		goto 	no_hash_mark		; is not #- Replace the existing value with the new current value
		
		movf 	0x51,0				; Saving the first value received from the keyboard 
		movwf 	0x52

		call 	answer
		movlw 	0x30				; Adding the value 0x30 to the hexadecimal number found in register 0x51 is used to convert a numeric value represented
		addwf 	0x52,w				; in hexadecimal to its corresponding ASCII character representation for display on an LCD
		movwf 	0x20
		call 	lcdd				; write data to the LCD
		call	mdel				; medium delay.
		call 	lulaa3
						
								
		;check if x=y			
equal:
		movf	0x51,w				; The resulting guess
		subwf	0x56,w				; Subtract the guess value from the sine wave sample array received from PORTA<0>
		btfss	STATUS,Z	 		; If the subtraction operation is performed and its result is 0, the zero flag rises to one and the next line is performed.
		call	miss				; The guess is wrong - issue an error message
		movlw	0xFE		;25 kHz	; The guess is correct. Change the square wave in PORTC<2> from 5kHz to 25kHz
		movwf	0x53				; Update register 0x53 that stores the square wave bit to approx 0xFE to output a square wave at a rate of 25 kHz
		call	bingo				; Print a victory message
		
newGame:
		call	pressForNew			; message on the LCD display
		bcf		STATUS, RP0
		bsf		STATUS, RP0			; Bank1 
		movlw	0x04				; PCFG 3:0  0100  Vref+=Vdd, Vref-=Vss, PA0,PA1,PA3: Analog in the others : Digital 	
		movwf	ADCON1		
		movlw	0xff
		movwf	TRISA				; PortA input
		bcf		STATUS, RP0			; Bank0 
	

click2:
		btfsc	PORTA ,0x05			; Waiting for POTRA <5> to be clicked
		goto	click2

Unclicked2:
		btfss	PORTA ,0x05			; Waiting for POTRA <5> to be released
		goto	Unclicked2			; If the POTRA <5> button is pressed a second time-
		goto	initialization		; return to the beginning of the game

		
infinite:    
		goto	infinite			; infinite loop


value_0:
		movlw	0x00				; Converting the analog to digital value - 0 
		movwf	0x56				; Place the value in register 0X56
		goto 	continue
	
value_1:
		movlw	0x01				; Converting the analog to digital value - 1
		movwf	0x56				; Place the value in register 0X56
		goto 	continue
	
value_2:
		movlw	0x02				; Converting the analog to digital value - 2
		movwf	0x56				; Place the value in register 0X56
		goto 	continue
	
value_3:
		movlw	0x03				; Converting the analog to digital value - 3
		movwf	0x56				; Place the value in register 0X56
		goto 	continue

value_4:
		movlw	0x04				; Converting the analog to digital value - 4
		movwf	0x56				; Place the value in register 0X56
		goto 	continue	
	
miss:
		call	Retry				; Wrong guess - message on LCD display
		call 	lulaa3
		goto	newGame				; To start a new game press the button in PORTA<5>
		return	

no_hash_mark:
									; Waiting for a decision to guess
		movf	0x52, w 			; Overwrite the initial value found in register 0x51
		movwf	0x51				; Insert into the register 0x51 the next value typed and found in the register

		movlw	0x30				; Adding the value 0x30 to the hexadecimal number found in register 0x51 is used to convert a numeric value represented
		addwf	0x52,0				; in hexadecimal to its corresponding ASCII character representation for display on an LCD
		movwf	0x20
		call	lcdd				; write data to the LCD
		call	mdel				; medium delay.
		goto	hash_mark			; Since you haven't decided on a guess - enter another number from the user on the keypad
		return


wkb: 		
			; initializes a keypad interface by setting various bits in the PORTB register. 
			; These bits control the rows and columns of a keypad matrix.

			; Deactivate the fourth column (bit 4), and activate columns 5, 6, and 7 (bits 5, 6, 7).
			bcf PORTB,0x4			; It clears bit 4 of PORTB, deactivating the fourth column.
			bsf PORTB,0x5			; It sets bit 5 of PORTB, activating the fifth column.
			bsf PORTB,0x6			; It sets bit 6 of PORTB, activating the sixth column.
			bsf PORTB,0x7			; It sets bit 7 of PORTB, activating the seventh column.
									; The following conditional checks determine which row in the activated column is pressed.

			btfss PORTB,0x0			; Check if bit 0 of PORTB is clear (connected to the first row).
			goto kb01				; If bit 0 is clear, jump to the label kb01.
			btfss PORTB,0x1			; If bit 0 is set, checks if the bit 1 of PORTB is clear
			goto kb02				; If bit 1 is clear, jump to the label kb02
			btfss PORTB,0x2			; If bit 1 is set, checks if the bit 2 of PORTB is clear
			goto kb03				; If bit 2 is clear, jump to the label kb03.
			btfss PORTB,0x3			; If bit 2 is set, checks if the bit 3 of PORTB is clear
			goto kb0a				; If bit 3 is clear, jump to the label kb0a.
			
			bsf PORTB,0x4			; Activate the fourth column.
			bcf PORTB,0x5			; Deactivate the fifth column.
			btfss PORTB,0x0			; Check if bit 0 of PORTB is clear (connected to the first row).
			goto kb04				; If bit 0 is clear, jump to the label kb04.
			btfss PORTB,0x1			; If bit 0 is set, checks if the bit 1 of PORTB is clear
			goto kb05				; If bit 1 is clear, jump to the label kb05
			btfss PORTB,0x2			; If bit 1 is set, checks if the bit 2 of PORTB is clear
			goto kb06				; If bit 2 is clear, jump to the label kb06.
			btfss PORTB,0x3			; If bit 2 is set, checks if the bit 3 of PORTB is clear
			goto kb0b				; If bit 3 is clear, jump to the label kb0b.
			
			bsf PORTB,0x5			; Activate the fifth column.
			bcf PORTB,0x6			; Deactivate the Sixth column.
			btfss PORTB,0x0			; Check if bit 0 of PORTB is clear (connected to the first row).
			goto kb07				; If bit 0 is clear, jump to the label kb07.
			btfss PORTB,0x1			; If bit 0 is set, checks if the bit 1 of PORTB is clear
			goto kb08				; If bit 1 is clear, jump to the label kb08.
			btfss PORTB,0x2			; If bit 1 is set, checks if the bit 2 of PORTB is clear
			goto kb09				; If bit 2 is clear, jump to the label kb09.
			btfss PORTB,0x3			; If bit 2 is set, checks if the bit 3 of PORTB is clear
			goto kb0c				; If bit 3 is clear, jump to the label kb0c.
			
			bsf PORTB,0x6			; Activate the Sixth column.
			bcf PORTB,0x7			; Deactivate the seventh column.
			btfss PORTB,0x0			; Check if bit 0 of PORTB is clear (connected to the first row).
			goto kb0e				; If bit 0 is clear, jump to the label kb0e.
			btfss PORTB,0x1			; If bit 0 is set, checks if the bit 1 of PORTB is clear
			goto kb00				; If bit 1 is clear, jump to the label kb00.
			btfss PORTB,0x2			; If bit 1 is set, checks if the bit 2 of PORTB is clear
			goto kb0f				; If bit 2 is clear, jump to the label kb0f.
			btfss PORTB,0x3			; If bit 2 is set, checks if the bit 3 of PORTB is clear
			goto kb0d				; If bit 3 is clear, jump to the label kb0d.

			goto wkb

kb00: 	movlw 0x00						
		goto end_wkb

kb01: 	movlw 0x01
		goto end_wkb

kb02: 	movlw 0x02
		goto end_wkb

kb03: 	movlw 0x03
		goto end_wkb

kb04:	movlw 0x04
		goto end_wkb

kb05: 	movlw 0x05
		goto end_wkb

kb06: 	call wrong					
		call Press_release
		call init
		goto guess

kb07: 	call wrong
		call Press_release
		call init
		goto guess

kb08: 	call wrong
		call Press_release
		call init
		goto guess

kb09: 	call wrong
		call Press_release
		call init
		goto guess

kb0a:	call wrong
		call Press_release
		call init
		goto guess

kb0b:	call wrong
		call Press_release
		call init
		goto guess


kb0c:	call wrong
		call Press_release
		call init
		goto guess

kb0d: 	call wrong
		call Press_release
		call init
		goto guess


kb0e:	call wrong
		call Press_release
		call init
		goto guess

kb0f: 	movlw 0x0f					; # key
		goto end_wkb


end_wkb:
		movwf 0x35					; The typed key value is saved in the register 0x35

Press_release:				
		movlw 0x0F					; waits for a button or switch release by continuously checking the value at PORTB. 
		movwf PORTB					; It uses subtraction and the Zero flag to detect when the button or switch is released.
		subwf PORTB,0				; When released, the code exits the loop and returns from a subroutine. ;
		btfss STATUS,Z				; the loop will continue until the button is released (PORTB value becomes zero).		
		goto Press_release
		return				


Square_wave:
		movwf	0x7A				;store W_reg --> 0x7A
		swapf	STATUS, w
		movwf	0x7B				;store STATUS --> 0x7B

		bcf		STATUS, RP0	
		bcf		STATUS, RP1	
		btfsc	INTCON, T0IF		; Checking the flag (Timer0)
		goto	Timer0

ERR:	goto	ERR

Timer0:	
							
		incf	PORTC				; An instruction that increments the value stored in this PORTC by 1 to perform a sequence.
		movf	0x53,w				; the timer counting from the value stored in register 0x53 
		movwf	TMR0				
			
		bcf		INTCON, T0IF		; clears the Timer 0 interrupt flag (T0IF) in the INTCON register. the Timer 0 interrupt has been serviced.
		swapf	0x7B, w
		movwf	STATUS				; restore STATUS-0x7B:This instruction stores the value in the working register (WREG) back into the STATUS register.
	      							; This effectively restores the STATUS register to its original state before the ISR(Interrupt Service Routine)was executed.

		swapf	0x7A, f
		swapf	0x7A, w				; restore W_reg <-- 0x7A

		; Timer 0 is an 8-bit timer, meaning it counts from 0 to 255- 0xff before going back to 0.
		; During the count the main program is executed.
		; When the timer finishes counting and reaches 0xff, it stops the main program and turns to execute an interrupt.
		; The interrupt will be a square wave. When the interrupt ends, 
		; the timer starts counting again from the value stored in register 0x53 until 0xff.
		; ends with a retfie instruction, which is used to return from an interrupt service routine. From the interrupt functions,
		; clear the timer 0 interrupt flag and restore the STATUS and WREG registers to their original state before the interrupt was executed.

		retfie

;---------------------------------------------------------------------------------------

;**********************************************************
;LCD display
;**********************************************************


startAGame:
		call	init
		movlw	0x80	; Place for the data on the LCD (top line)
		movwf	0x20
		call 	lcdc
		call	mdel
;---------------------------W------------------------------
		movlw	'W'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------e---------------------------
		movlw 	'e'			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;----------------------------l------------------------------
		movlw	'l'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------c------------------------------
		movlw	'c'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------o------------------------------
		movlw	'o'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------m------------------------------
		movlw	'm'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------(space)------------------------------
		movlw	' '			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel

;----------------------------t------------------------------
		movlw	't'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel

;----------------------------o------------------------------
		movlw	'o'		; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel


        ; Move cursor to the midel of the second line
		movlw 	0xC5         ; Place for the data on the LCD (center of the display)
		movwf 	0x20
		call 	lcdc
		call 	mdel
;----------------------------b------------------------------
		movlw	'b'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------i------------------------------
		movlw	'i'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------n------------------------------
		movlw	'n'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------g------------------------------
		movlw	'g'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------o------------------------------
		movlw	'o'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------(space)------------------------------
		movlw	' '			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------g---------------------------
		movlw	'g' 		; CHAR (the data )
		movwf	0x20
		call	lcdd
		call 	mdel
;----------------------------a------------------------------
		movlw	'a'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel

;----------------------------m------------------------------
		movlw	'm'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel

;----------------------------e------------------------------
		movlw	'e'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel

		return

answer:	
		call	init
		movlw	0x80		; Place for the data on the LCD (top line)
		movwf	0x20
		call 	lcdc
		call	mdel
;--------------------------------Y--------------------------
		movlw	'Y'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------o--------------------------
		movlw	'o'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------u--------------------------
		movlw	'u'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------r--------------------------
		movlw	'r'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------space--------------------------
		movlw	' '			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------a--------------------------
		movlw	'a'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------n--------------------------
		movlw	'n'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------s--------------------------
		movlw	's'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------w--------------------------
		movlw	'w'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------e--------------------------
		movlw	'e'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------r--------------------------
		movlw	'r'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------space--------------------------
		movlw	' '			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------i--------------------------
		movlw	'i'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------s--------------------------
		movlw	's'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------:--------------------------
		movlw	':'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel

		return			


pressTheButton:
        call	init
		movlw	0x80			; Place for the data on the LCD (top line)
		movwf	0x20
		call 	lcdc
		call	mdel
;------------------------------P----------------------------
		movlw	0x50			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------r----------------------------	
		movlw	0x72			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------e---------------------------	
		movlw	0x65			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------s---------------------------	
		movlw	0x73			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------s---------------------------	
		movlw	0x73			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------(space)-----------------------	
		movlw	0x20			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------P----------------------------
		movlw	0x50			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------<----------------------------
		movlw	0x3C			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------5----------------------------
		movlw	0x35			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------->----------------------------
		movlw	0x3E			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------(space)---------------------------	
		movlw	0x20			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel				
;-------------------------------t---------------------------
		movlw	0x74			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel				
;------------------------------o----------------------------	
		movlw	'o'				; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
		
		
        ; Move cursor to the midel of the second line
		movlw	0xC3         ; Place for the data on the LCD (center of the display)
		movwf	0x20
		call	lcdc
		call	mdel
;-------------------------------(c)---------------------------	
		movlw	'c'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------(a)---------------------------	
		movlw	'a'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------(c)---------------------------	
		movlw	'c'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------h---------------------------	
		movlw	'h'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------(space)---------------------------	
		movlw	0x20		; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------v---------------------------	
		movlw	'v'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------o---------------------------	
		movlw	'o'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;--------------------------------l--------------------------	
		movlw	'l'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------a---------------------------	
		movlw	'a'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------g---------------------------	
		movlw	'g'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
;-------------------------------e---------------------------	
		movlw	'e'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel						

        return

WaitingForGuess:
        call	init
        movlw	0x80
        movwf	0x20
        call	lcdc
        call	mdel
;-------------------------------E---------------------------
        movlw	'E'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call 	mdel
;------------------------------n----------------------------	
		movlw	'n'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;----------------------------t------------------------------
		movlw	't'			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------e---------------------------
        movlw	'e'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------r---------------------------
        movlw	'r'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
;----------------------------(space)------------------------------
		movlw	' '			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
 ;-------------------------------a---------------------------
        movlw	'a'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
;----------------------------(space)------------------------------
		movlw	' '			; CHAR (the data)
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------n----------------------------	
		movlw	'n'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel 
;------------------------------u----------------------------	
		movlw	'u'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------m----------------------------	
		movlw	'm'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------b----------------------------	
		movlw	'b'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------e----------------------------	
		movlw	'e'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;------------------------------r----------------------------	
		movlw	'r'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel


        ; Move cursor to the beginning of the second line
        movlw	0xC0
        movwf	0x20
        call	lcdc

        ; Display "for your guess" on the second line
 ;-------------------------------f---------------------------
        movlw	'f'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------o---------------------------
        movlw	'o'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------r---------------------------
        movlw	'r'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------(space)----------------------
        movlw	' '			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------y---------------------------
        movlw	'y'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------o---------------------------
        movlw	'o'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------u---------------------------
        movlw	'u'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
 ;-------------------------------r---------------------------
        movlw	'r'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
  ;-------------------------------(space)---------------------
        movlw	' '			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
  ;-------------------------------g---------------------------
        movlw	'g'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
  ;-------------------------------u---------------------------
        movlw	'u'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
  ;-------------------------------e---------------------------
        movlw	'e'			; CHAR (the data )
        movwf	0x20
        call	lcdd
        call	mdel
  ;-------------------------------s---------------------------
        movlw	's'			; CHAR (the data )
        movwf	0x20
        call 	lcdd
        call 	mdel
  ;-------------------------------s---------------------------
        movlw	's'			; CHAR (the data )
        movwf 	0x20
        call 	lcdd
        call 	mdel
		
		return

bingo:
		call	init
		movlw	0x85			 ;PLACE for the data on the LCD
		movwf	0x20
		call 	lcdc
		call	mdel
;----------------------------B------------------------------	
		movlw	0x42			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel

;------------------------------i----------------------------
		movlw	0x69			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel

;------------------------------n----------------------------	
		movlw	0x6E			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel

;-------------------------------g---------------------------
		movlw	0x67 			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel

;-------------------------------o---------------------------	
		movlw	0x6F			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------!---------------------------	
		movlw	0x21			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
	
		return

Retry:
		call	init
		movlw	0x85		;PLACE for the data on the LCD
		movwf	0x20
		call 	lcdc
		call	mdel
;-------------------------------M---------------------------	
		movlw	'M'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------i---------------------------	
		movlw	'i'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------s---------------------------	
		movlw	's'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel
;-------------------------------s---------------------------	
		movlw	's'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	mdel	
	
		return

wrong:	
		;Invalid letters
		call	init
		movlw	0x87 			;PLACE for the data on the LCD
		movwf	0x20
		call	lcdc
		call	mdel
;------------------------------I---------------------------
		movlw	'i' 			; CHAR (the data )
		movwf	0x20
		call	lcdd
		call	mdel
;-------------------------------n---------------------------
		movlw	'n'				; CHAR (the data )
		movwf	0x20
		call	lcdd
		call 	mdel
;-------------------------------v---------------------------
		movlw 	'v' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------a---------------------------
		movlw 	'a' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call	mdel
;-------------------------------l---------------------------
		movlw 	'l' 			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call 	mdel
;-------------------------------i---------------------------
		movlw 	'i' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------d---------------------------
		movlw 	'd' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel


		movlw 	0xC4 			;PLACE for the data on the LCD
		movwf	0x20
		call 	lcdc
		call	mdel
;-------------------------------c---------------------------
		movlw 	'c'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------h---------------------------
		movlw 	'h'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------a---------------------------
		movlw 	'a'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------r---------------------------
		movlw 	'r'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------a---------------------------
		movlw 	'a'				; CHAR (the data )
		movwf 	0x20	
		call 	lcdd
		call 	mdel
;-------------------------------c---------------------------
		movlw 	'c'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call	mdel
;-------------------------------t---------------------------
		movlw 	't'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------e---------------------------
		movlw 	'e'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------r---------------------------
		movlw 	'r'				; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
			
		return

pressForNew:
		call	init
		movlw	0x80 			;PLACE for the data on the LCD
		movwf 	0x20
		call 	lcdc
		call 	mdel
;-------------------------------p---------------------------
		movlw 	'p' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------r---------------------------
		movlw	'r' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------e---------------------------
		movlw 	'e' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------s---------------------------
		movlw 	's' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------s---------------------------
		movlw 	's' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------(space)----------------------
		movlw 	' ' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------P---------------------------
		movlw 	'P' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------<---------------------------
		movlw 	'<' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel		
;-------------------------------5---------------------------
		movlw 	'5' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel		
;------------------------------->---------------------------
		movlw 	'>' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel		
;-------------------------------(space)----------------------
		movlw 	' ' 			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call 	mdel
;-------------------------------f---------------------------
		movlw 	'f' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call	mdel
;-------------------------------o---------------------------
		movlw 	'o' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------r---------------------------
		movlw 	'r' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel


		movlw 	0xC0 			;PLACE for the data on the LCD
		movwf 	0x20
		call 	lcdc
		call 	mdel
;-------------------------------space---------------------------
		movlw 	' ' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------a---------------------------
		movlw 	'a' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------space---------------------------
		movlw 	' ' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------n---------------------------
		movlw 	'n' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------e---------------------------
		movlw 	'e' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------w---------------------------
		movlw 	'w' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------space---------------------------
		movlw 	' ' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------g---------------------------
		movlw 	'g' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------a---------------------------
		movlw 	'a' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------m---------------------------
		movlw 	'm' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel
;-------------------------------e---------------------------
		movlw 	'e' 			; CHAR (the data )
		movwf 	0x20
		call 	lcdd
		call 	mdel

		return
	

;*****************************
;subroutine to initialize LCD*
;*****************************

init:  
		; Initialize the LCD module
        movlw   0x30        ; Set initial data for LCD
        movwf   0x20        ; Store data in memory location
        call    lcdc        ; Call subroutine to send command to LCD
        call    del_41      ; Call delay subroutine

        ; Repeat the initialization steps for the LCD
        movlw   0x30        ; Repeat initialization step
        movwf   0x20
        call    lcdc
        call    del_01

        movlw   0x30        ; Repeat initialization step
        movwf   0x20
        call    lcdc
        call    mdel

        ; Clear the display
        movlw   0x01        ; Command: Display clear
        movwf   0x20
        call    lcdc
        call    mdel

        ; Set the entry mode: increment cursor, no shift
        movlw   0x06        ; Command: I/D=1, S=0
        movwf   0x20
        call    lcdc
        call    mdel

        ; Set display parameters: display on, no cursor, no blinking
        movlw   0x0c        ; Command: D=1, C=B=0
        movwf   0x20
        call    lcdc
        call    mdel

        ; Set function parameters: 8-bit interface, 2 lines, 5x8 dots
        movlw   0x38        ; Command: DL=1, N=1, F=0
        movwf   0x20
        call    lcdc
        call    mdel
        return

;***********************************
;subroutine to write data to LCD*
;***********************************

lcdd: 
; Write data to the LCD
        movlw   0x02        ; Set E=0, RS=1
        movwf   PORTE

        movf    0x20,w      ; Load data into W
        movwf   PORTD       ; Send data to LCD

        movlw   0x03        ; Set E=1, RS=1
        movwf   PORTE

        call    sdel        ; Call delay subroutine

        movlw   0x02        ; Set E=0, RS=1
        movwf   PORTE

        return


;***********************************
;subroutine to write command to LCD*
;***********************************

lcdc: 
		; Write command to the LCD
        movlw   0x00        ; Set E=0, RS=0
        movwf   PORTE

        movf    0x20,w      ; Load command into W
        movwf   PORTD       ; Send command to LCD

        movlw   0x01        ; Set E=1, RS=0
        movwf   PORTE

        call    sdel        ; Call delay subroutine

        movlw   0x00        ; Set E=0, RS=0
        movwf   PORTE
    
        return

                    
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Delay subroutines
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
del_41: 
		; Delay subroutine with value 0xCD (205) for loop
        movlw   0xcd
        movwf   0x23

lulaa6:
 		; Loop counter initialization
        movlw   0x20
        movwf   0x22

lulaa7:
 		; Inner loop: decrement counter, repeat if not zero
        decfsz  0x22,1
        goto    lulaa7
        decfsz  0x23,1
        goto    lulaa6 
        return

del_01: 
		; Delay subroutine with value 0x20 (32) for loop
        movlw   0x20
        movwf   0x22

lulaa8:
		; Loop counter initialization
        decfsz  0x22,1
        goto    lulaa8
        return

sdel: 
  		; Short delay subroutine with value 0x19 (25) for loop
        movlw   0x25
        movwf   0x23

lulaa2:
 		; Loop counter initialization
        movlw   0xfa
        movwf   0x22

lulaa1:
 		; Inner loop: decrement counter, repeat if not zero
        decfsz  0x22,1
        goto    lulaa1
        decfsz  0x23,1
        goto    lulaa2 
        return

mdel: 
		; Medium delay subroutine with value 0x0a (10) for outer loop
        movlw   0x0a
        movwf   0x24

lulaa5:
 		; Outer loop counter initialization
        movlw   0x19
        movwf   0x23

lulaa4:
 		; Inner loop counter initialization
        movlw   0xfa
        movwf   0x22

lulaa3:
		; Inner loop: decrement counter, repeat if not zero
        decfsz  0x22,1
        goto    lulaa3
        decfsz  0x23,1
        goto    lulaa4 
        decfsz  0x24,1
        goto    lulaa5
        return

d_20:
		movlw	0x20
		movwf	0x22

convert_1:	
		decfsz	0x22, f
		goto	convert_1
		return
d_4:	movlw	0x06
		movwf	0x22

convert_2:	
		decfsz	0x22, f
		goto	convert_2
		return

    end
