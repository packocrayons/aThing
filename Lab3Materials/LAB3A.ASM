 NAME       LAB3A

;*****************************************************************************
;       B E G I N N I N G    O F    P R O G R A M 
;*****************************************************************************

;-----------------------------------------------------------------------------
;       E Q U A T E S 
;-----------------------------------------------------------------------------

; 8255 Setup
CNTR_8255   EQU 0FFFEh  ;Port control address
OUTPUT_MODE EQU 0B5h    ;Set up mode for port B output

; 8253 Setup
COUNT_CNTR  EQU 000Eh   ;counter control register address
MODE2       EQU 74h     ;______________________________________________________
MODE3       EQU 36h     ;______________________________________________________
COUNT0      EQU 0008h   ;counter0 address
COUNT1      EQU 000Ah   ;counter1 address
LOPT100uSEC   EQU 0F5h     ;______________________________________________________
HIPT100uSEC   EQU 00h     ;______________________________________________________
LOPT200uSEC   EQU 02h     ;______________________________________________________
HIPT200uSEC   EQU 00h     ;______________________________________________________

; 8259A Setup
CLR_A0      EQU 0000h   ;Which CW's written here? _____________________________
SET_A0      EQU 0002h   ;Which CW's written here? _____________________________
ICW1        EQU 17h     ;______________________________________________________
ICW2        EQU 20h     ;______________________________________________________
ICW4        EQU 03h     ;______________________________________________________
OCW1        EQU 0FCh    ;______________________________________________________

;-----------------------------------------------------------------------------
;       S T A R T    O F    V E C T O R    S E G M E N T 
;-----------------------------------------------------------------------------

VECTOR_SEG  SEGMENT
ORG         00080h      ;Interrupt vector: type 32 dec.
        
IR0_IP_VECT DW  ?       ;Low contains IP of ISR0
IR0_CS_VECT DW  ?       ;High contains CS of ISR0
IR1_IP_VECT DW  ?       ;Low contains IP of ISR1
IR1_CS_VECT DW  ?       ;High contains CS of ISR1

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
;
;   - This procedure is called from the main program to initialize the 
;     8253, the 8259A and the 8255.
;..............................................................................
INIT        PROC    NEAR
ASSUME      DS:DATA_SEG         ;offset relative to data_seg

;Initialize the 8255 to set port B as output to DAC.

            MOV DX,CNTR_8255    ; Port control address
            MOV AL,OUTPUT_MODE  ; Set up mode for port B output
            OUT DX,AL         

;Initialize 8253 counter0 and counter1 - counter2 is not used.
;Clock is the peripheral clock with frequency assumed to be 2.45MHz
;______________________________________________________________________________
;______________________________________________________________________________
;______________________________________________________________________________

            MOV DX,COUNT_CNTR   ;______________________________________________
            MOV AL,MODE3
            OUT DX,AL
            MOV DX,COUNT0
            MOV AL,LOPT100uSEC    ;______________________________________________
            OUT DX,AL
            MOV AL,HIPT100uSEC
            OUT DX,AL
    
            MOV DX,COUNT_CNTR   ;______________________________________________
            MOV AL,MODE2
            OUT DX,AL
            MOV DX,COUNT1
            MOV AL,LOPT200uSEC    ;______________________________________________
            OUT DX,AL
            MOV AL,HIPT200uSEC
            OUT     DX,AL

;Initialize 8259A to : ________________________________________________________
;______________________________________________________________________________
;______________________________________________________________________________
;______________________________________________________________________________
;______________________________________________________________________________

            MOV DX,CLR_A0   ;__________________________________________________
            MOV AL,ICW1
            OUT DX,AL
            MOV DX,SET_A0   ;__________________________________________________
            MOV AL,ICW2
            OUT DX,AL
            MOV AL,ICW4     ;__________________________________________________
            OUT DX,AL
            MOV AL,OCW1     ;__________________________________________________
            OUT DX,AL

;Initialization complete, interrupts still disabled.

            RET
INIT        ENDP


;..............................................................................
;   INTERRUPT SERVICE ROUTINE : ISR0
;..............................................................................
ISR0        PROC    NEAR
            IRET
ISR0        ENDP


;..............................................................................
;   INTERRUPT SERVICE ROUTINE : ISR1
;..............................................................................
ISR1        PROC    NEAR        
            IRET            
ISR1        ENDP


;..............................................................................
;   S T A R T     O F     M A I N     P R O G R A M 
;..............................................................................

ASSUME      DS:VECTOR_SEG           ;offset relative to vector_seg

;Set up the interrupt vectors.

BEG:        CLI                     ;Ensure no interrupt occurs.
            MOV AX,VECTOR_SEG       ;DS = vector_seg
            MOV DS,AX
            MOV IR0_IP_VECT,OFFSET ISR0 ;load all ISR's IP and CS  
            MOV IR1_IP_VECT,OFFSET ISR1
            MOV AX,CS
            MOV IR0_CS_VECT,AX
            MOV IR1_CS_VECT,AX

ASSUME      DS:DATA_SEG             ;offset relative to data_seg

            MOV     AX,DATA_SEG     ;Define data segment
            MOV     DS,AX
            CALL    INIT            ;Initialization
            STI                     ;Enable the interrupt now.
LOOP1:      
            JMP LOOP1

CODE_SEG        ENDS


;----------------------------------------------------------------------------
;       S T A R T     O F     D A T A     S E G M E N T 
;----------------------------------------------------------------------------
DATA_SEG        SEGMENT

DAC_MEMORY      DB  0               ;Store the current DAC value
GARBAGE         DB  0               ;Store the garbage character.

DATA_SEG        ENDS

                END     BEG


;******************************************************************************
;                 E N D      O F      P R O G R A M
;******************************************************************************
