NAME        LAB3B

;*****************************************************************************
;       B E G I N N I N G    O F    P R O G R A M 
;*****************************************************************************

;-----------------------------------------------------------------------------
;       E Q U A T E S 
;-----------------------------------------------------------------------------

; 8255 Setup
CNTR_8255   EQU 0FFFEh  ;Port control address
OUTPUT_MODE EQU 0B5h    ;Set up mode for port B output

; 8255 Control
PORT_B_ADDR EQU 0FFFAh  ;Port B address

; 8253 Setup
COUNT_CNTR  EQU 000Eh   ;counter control register address
MODE2       EQU 74h     ;01110100b - 01:Select Counter 1, 11:Read LSB first, 010:Mode 2, 0:Binary counter
MODE3       EQU 36h     ;00110110b - 00: select counter 0, 11:Read LSB first, 011:Mode 3, 0:Binary counter
COUNT0      EQU 0008h   ;counter0 address
COUNT1      EQU 000Ah   ;counter1 address
LO10MSEC    EQU 0B4h    ;5FB4 = 24500 at 2450000 = 1/100 = 10mSec
HI10MSEC    EQU 05Fh    ;
LO1SEC      EQU 064h    ;This doesn't seem to be the right number? it should be 2450000 = 256250h
HI1SEC      EQU 000h    ;

; 8259A Setup
CLR_A0      EQU 0000h   ;Which CW's written here? A0 = 0, A1 = 1 (8086 uses A1, use both for safety), D4 must be 1 to write ICW1
SET_A0      EQU 0002h   ;Which CW's written here? A0 = 1, A1 = 1 ("      "            "          " ), D4 must be 1 to write ICW2
ICW1        EQU 17h     ;00010111b - 000: address of IVA, 1, 0 - Edge triggered, 1: Call address interval of 4, Single mode, ICW4 needed
ICW2        EQU 20h     ;00100000b - T7-T3 = 00100
ICW4        EQU 03h     ;00000011b - 000, 0:not special fully nested, non-buffered, Auto EOI, 8086 mode
OCW1        EQU 0FCh    ;11111101 - channel 1 enabled.

; 8279 Setup
LED_RIGHT   EQU 090h    ;
LED_CNTR    EQU 0FFEAh  ;Port number for 8279 control register
LED_DATA    EQU 0FFE8h  ;Port number for 8279 data register 

;-----------------------------------------------------------------------------
;       S T A R T    O F    V E C T O R    S E G M E N T 
;-----------------------------------------------------------------------------

VECTOR_SEG  SEGMENT
ORG         00080h          ;Interrupt vector: type 32 dec.
        
IR0_IP_VECT DW  ?           ;Low contains IP of ISR0
IR0_CS_VECT DW  ?           ;High contains CS of ISR0
IR1_IP_VECT DW  ?           ;Low contains IP of ISR1
IR1_CS_VECT DW  ?           ;High contains CS of ISR1

VECTOR_SEG  ENDS

STACK SEGMENT PARA STACK 'stack'
STACK ENDS

;-----------------------------------------------------------------------------
;       S T A R T    O F    C O D E     S E G M E N T 
;-----------------------------------------------------------------------------

CODE_SEG    SEGMENT
ASSUME      CS:CODE_SEG, DS:DATA_SEG
ORG         00100h


;..............................................................................
;   PROCEDURE : INIT
;   - This procedure is called from the main program to initialize the 
;     8253, the 8259A and the 8255.
;..............................................................................
INIT        PROC    NEAR

;Initialize the 8255 to set port B as output to DAC.

            MOV DX,CNTR_8255    ; Port control address
            MOV AL,OUTPUT_MODE  ; Set up mode for port B output
            OUT DX,AL         

;Initialize 8253 counter0 and counter1 - counter2 is not used.
;Clock is the peripheral clock with frequency assumed to be 2.45MHz
;____________________________________________________________________________
;____________________________________________________________________________

        MOV DX,COUNT_CNTR   ;This is the address of the counter
        MOV AL,MODE3
        OUT DX,AL
        MOV DX,COUNT0
        MOV AL,LO10MSEC     ;write the counter value (LSB first - from the mode), then MSB
        OUT DX,AL
        MOV AL,HI10MSEC
        OUT DX,AL

        MOV DX,COUNT_CNTR   ;Same address
        MOV AL,MODE2
        OUT DX,AL
        MOV DX,COUNT1
        MOV AL,LO1SEC       ;Write the counter 1 value, LSB first
        OUT DX,AL
        MOV AL,HI1SEC
        OUT     DX,AL

;Initialize 8259A to :_______________________________________________________
;____________________________________________________________________________
;____________________________________________________________________________

        MOV DX,CLR_A0 ;____________________________________________________
        MOV AL,ICW1
        OUT DX,AL
        MOV DX,SET_A0   ;____________________________________________________
        MOV AL,ICW2
        OUT DX,AL
        MOV AL,ICW4     ;____________________________________________________
        OUT DX,AL

;____________________________________________________________________________

        MOV AL,OCW1     ;____________________________________________________
        OUT DX,AL

;Initialization complete, interrupts still disabled.

        RET
INIT    ENDP


;.............................................................................
;   PROCEDURE : DAC_UPDATE
;   - This procedure will be called by the ISR0 routine to update the 
;     DAC_MEMORY to produce a saw-tooth waveform through the 8255 PIP.
;.............................................................................
DAC_UPDATE  PROC    NEAR

        PUSH    DX              ;Save register to be used.
        PUSH    AX
        MOV DX,PORT_B_ADDR      ;Increased the step voltage to 
        MOV AL,DAC_MEMORY       ; DAC by 1 unit.
        OUT DX,AL           
        INC DAC_MEMORY          ;Store next value of voltage
        POP AX
        POP DX

        RET
DAC_UPDATE  ENDP


;..............................................................................
;   INTERRUPT SERVICE ROUTINE : ISR0
;   - This ISR will keep track of the time so is serviced every 10msec.
;   When it is called, it   calls the DAC_UPDATE procedure
;   to output   the sawtooth waveform (by incrementing the voltage).
;..............................................................................
ISR0    PROC    NEAR
        CALL    DAC_UPDATE      ;Update the DAC output
        IRET
ISR0    ENDP


;..............................................................................
;   INTERRUPT SERVICE ROUTINE : ISR1
;   - This ISR is serviced every 1 second, displaying a changing
;     garbage symbol on the SDK display.
;..............................................................................
ISR1    PROC    NEAR        
        PUSH    AX              ;Save registers.
        PUSH    DX
        MOV     AL,LED_RIGHT    ;____________________________________________ 
        MOV     DX,LED_CNTR     ;Address of control register  
        OUT     DX,AL           ;Load LED addr.-> control reg.
        MOV     DX,LED_DATA     ;Address for data register
        MOV     AL,GARBAGE
DISP:   INC     AL              ;Change GARBAGE CHAR.
        OUT     DX,AL           ;Send to LED display
        MOV     GARBAGE,AL
        POP     DX              ;Restore registers
        POP     AX      
        IRET            
ISR1    ENDP


;..............................................................................
;   S T A R T     O F     M A I N     P R O G R A M 
;..............................................................................

ASSUME  DS:VECTOR_SEG               ;offset relative to vector_seg

;Set up the interrupt vectors.

BEG:    CLI                         ;Ensure no interrupt occurs.
        MOV AX,VECTOR_SEG           ;DS = vector_seg
        MOV DS,AX
        MOV IR0_IP_VECT,OFFSET ISR0 ;load all ISR's IP and CS  
        MOV IR1_IP_VECT,OFFSET ISR1
        MOV AX,CS
        MOV IR0_CS_VECT,AX
        MOV IR1_CS_VECT,AX

ASSUME  DS:DATA_SEG                 ;offset relative to data_seg

        MOV     AX,DATA_SEG         ;Define data segment
        MOV     DS,AX
        CALL    INIT                ;Initialization
        STI                         ;Enable the interrupt now.
LOOP1:  NOP
        JMP LOOP1

CODE_SEG        ENDS


;----------------------------------------------------------------------------
;       S T A R T     O F     D A T A     S E G M E N T 
;----------------------------------------------------------------------------
DATA_SEG        SEGMENT

DAC_MEMORY  DB  0       ;Holds the current DAC value
GARBAGE     DB  0       ;Holds the current garbage character.

LED_TABLE	DB		71h		;Display 'F'
			DB	79h		;'E'
			DB	5Eh		;'D'
			DB	39h		;'C'
			DB	7Ch		;'B'	
			DB	77h		;'A'
			DB      6Fh		;'9'			
			DB      7Fh		;'8'	
			DB      07h		;'7'		
			DB      7Dh		;'6'
			DB      6Dh		;'5'
			DB      66h		;'4'	
			DB      4Fh		;'3'
			DB      5Bh		;'2'
			DB      06h		;'1'
			DB      3Fh		;'0'

DATA_SEG    ENDS

            END     BEG

;******************************************************************************
;                 E N D      O F      P R O G R A M
;******************************************************************************