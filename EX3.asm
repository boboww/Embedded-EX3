#include <p18F45K50.inc>
    CONFIG WDTEN=OFF	    ;disable watchdog timer
    CONFIG MCLRE = ON	    ;MCLEAR Pin on
    CONFIG DEBUG = ON	    ;Enable Debug Mode
    CONFIG LVP = ON	    ;Low-Voltage programming
    CONFIG PBADEN = OFF
    CONFIG FOSC = INTOSCIO  ;Internal oscillator, port function on RA6
    org 0		    ;start code at 0

offset	= 0x02
    
Start:    
    CLRF    PORTA	    ;clear port A
    CLRF    LATA	    ;clear latch A
    CLRF    TRISA	    ;set port A to output
    CLRF    PORTB	    ;clear port B
    CLRF    LATB	    ;clear latch B
    CLRF    TRISB	    ;set port B to output
    CLRF    PORTC	    ;clear port C
    CLRF    LATC	    ;clear latch C
    CLRF    TRISC	    ;set port C to output  
    
    MOVLW   b'11110100'	    ;OSC set to 16MHz
    MOVWF   OSCCON    
    MOVLW   b'11110111'	    ;Enable PLL
    MOVWF   OSCCON2    
    MOVLW   b'10111111'	    ;Set PLL to 3x (16MHzx3=48Mhz)
    MOVWF   OSCTUNE   
    
    MOVLW   b'00001010'	    ;Timer0 set prescaler off
    MOVWF   T0CON    
    MOVLW   0x0B	    ;fosc = 16MHz, fcy = 4Mhz, tCy = 2.5*10^-7s
    MOVWF   TMR0H	    ;Prescaler = 16, 0.25s = X*16*2.5*10^-7
    MOVLW   0xDC	    ;X = 62500
    MOVWF   TMR0L	    ;FFFF = 65536, 65536-62500 = 3035 = 0BDC
    
    MOVLW   b'00000011'	    ;AN0, ADC ON
    MOVWF   ADCON0
    MOVLW   b'00000000'	    ;ADC ref = Vdd, Vss
    MOVWF   ADCON1 
    MOVLW   b'10101011'	    ;20 TAD, FRC, right justified 
    MOVWF   ADCON2
    
    CLRF    ANSELA     
    BSF	    TRISA,0	    ;set RA0 to input
    BSF	    ANSELA,0	    ;set RA0 to analog
    MOVLW   0x02
    MOVWF   offset
    MOVLW   b'00000000'
            
Main:   
    BSF	    ADCON0,1	    ;start ADC
    CALL    ADC   

    MOVF    ADRESL,0	    ;move ADRESL to w
    ANDLW   b'00001111'	    ;apply mask
    CALL    Lookup	    ;call lookup table     
    MOVWF   PORTB	    ;write pattern in w to LEDs. 
    MOVLW   b'00000001'	    ;turn only 001 on
    MOVWF   PORTC
    CALL    Delay    
    
    SWAPF   ADRESL,0	    ;swap nibbles in ADRESL, move to w
    ANDLW   b'00001111'	    ;apply mask
    CALL    Lookup	    ;call lookup table
    MOVWF   PORTB	    ;write pattern in w to LEDs.
    MOVLW   b'00000010'	    ;turn only 010 on
    MOVWF   PORTC
    CALL    Delay
    
    
    MOVF    ADRESH,0	    ;move ADRESH to w
    ANDLW   b'00000011'	    ;apply mask
    CALL    Lookup	    ;call lookup table   
    MOVWF   PORTB	    ;write pattern in w to LEDs. 
    MOVLW   b'00000100'	    ;turn only 100 on
    MOVWF   PORTC
    CALL    Delay
    
    BRA	    Main

ADC:
    BTFSC   ADCON0,1	    ;Check for GO/DONE bit to clear 
    GOTO    ADC		    ;Loop to check for bit 1 of ADCON0 
    RETURN
    
Delay:     
    BSF	    T0CON, TMR0ON   ;start Timer0  
    BTG	    PORTA, RA7
    GOTO    Loop
        
Loop:
    BTFSS   INTCON, TMR0IF  ;monitor Timer0 interrupt flag
    BRA	    Loop	    ;loop
    BCF	    T0CON, TMR0ON   ;stop Timer0
    BCF	    INTCON, TMR0IF  ;clear Timer0 interrupt flag  
    RETURN
    
Lookup:
    MULWF   offset	    ;multiply offset
    MOVF    PRODL,0	    ;move lower 8-bits of product to w
    ADDWF   PCL		    ;jump to entry spec'd by w.
    RETLW   b'11000000'	    ;0
    RETLW   b'11111001'	    ;1
    RETLW   b'10100100'	    ;2
    RETLW   b'10110000'	    ;3
    RETLW   b'10011001'	    ;4
    RETLW   b'10010010'	    ;5
    RETLW   b'10000010'	    ;6
    RETLW   b'11111000'	    ;7
    RETLW   b'10000000'	    ;8
    RETLW   b'10011000'	    ;9
    RETLW   b'10001000'	    ;A
    RETLW   b'10000011'	    ;B
    RETLW   b'11000110'	    ;C
    RETLW   b'10100001'	    ;D
    RETLW   b'10000110'	    ;E
    RETLW   b'10001110'	    ;F        
    ;        '.GFEDCBA'
    
    end


