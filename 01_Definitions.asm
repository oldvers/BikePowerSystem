;***********************************************************************************
;*****************[ Common constants ]**********************************************
;***********************************************************************************

;Project compilation date and time, device type
#define PROJECT_DATE __CENTURY__*1000000 + __YEAR__*10000 + __MONTH__*100 + __DAY__
#define PROJECT_TIME __HOUR__*10000 + __MINUTE__*100 + __SECOND__
#define DEVICESTRING "ATmega48"

;Version
.EQU  IP_VERSION        = $0204
.EQU  IP_PROJECT_DATE   = PROJECT_DATE
.EQU  IP_PROJECT_TIME   = PROJECT_TIME

;Firmware loading date and time, if exists
.EQU  LOAD_DATE_TIME    = ((FLASHEND + 1) - PAGESIZE + 1) ;$07E1

;***********************************************************************************
;*****************[ Hardware ports and pins ]***************************************
;***********************************************************************************

;-----------------------------------------------------------------------------------
;*** Status  LED  RGB   - Pin 23, 24, 25 - PC0, PC1, PC2 - ADC0, ADC1, ADC2 ***
.EQU SLEDDDR   = DDRC
.EQU SLEDPORT  = PORTC
.EQU SLEDR     = PC0
.EQU SLEDG     = PC1
.EQU SLEDB     = PC2
;-----------------------------------------------------------------------------------
;*** Power   LED  Green - Pin 26         - PC3           - ADC3 ***
.EQU PLEDDDR   = DDRC
.EQU PLEDPORT  = PORTC
.EQU PLED      = PC3
;-----------------------------------------------------------------------------------
;*** Gear LED 1 Blue    - Pin 9          - PD5           - OC0B ***
.EQU GLED1DDR  = DDRD
.EQU GLED1PORT = PORTD
.EQU GLED1     = PD5
;-----------------------------------------------------------------------------------
;*** Gear LED 2 Blue    - Pin 3          - PD3           - OC2B ***
.EQU GLED2DDR  = DDRD
.EQU GLED2PORT = PORTD
.EQU GLED2     = PD3
;-----------------------------------------------------------------------------------
;*** Phototransistor    - Pin 19         - xxx           - ADC6 ***
;-----------------------------------------------------------------------------------
;*** Power Voltage      - Pin 27, 28     - PC4, PC5      - ADC4, ADC5 ***
;-----------------------------------------------------------------------------------
;*** IR Receiver        - Pin 12, 32     - PB0, PD2      - ICP1, INT0 ***
.EQU IRDDR     = DDRB
.EQU IRPORT    = PORTB
.EQU IR        = PB0
.EQU ICMD      = GPIOR1
;-----------------------------------------------------------------------------------
;*** LED Light          - Pin 10         - PD6           - xxx ***
.EQU LEDLDDR   = DDRD
.EQU LEDLPORT  = PORTD
.EQU LEDLPIN   = PIND
.EQU LEDLIGHT  = PD6
.EQU LEDFLAGS  = GPIOR0
;-----------------------------------------------------------------------------------
;*** UART               - Pin 30, 31     - PD0, PD1      - RXD, TXD ***
.EQU UARTDDR   = DDRD
.EQU UARTPORT  = PORTD
.EQU URX       = PD0
.EQU UTX       = PD1
;EQU UCMD      = GPIOR2
;-----------------------------------------------------------------------------------

;***********************************************************************************
;*****************[ RAM variables ]*************************************************
;***********************************************************************************

.DSEG
  ; --- UART ---
  rUMode:        .BYTE  1
  rUSize:        .BYTE  2
  rUBuffer:      .BYTE  80
  rUCnt:         .BYTE  2
  rUPtr:         .BYTE  2
  rUCS:          .BYTE  2
  ; --- IR ---
  rIIndex:       .BYTE  1
  rIAddr:        .BYTE  1
  rInAddr:       .BYTE  1
  rICmd:         .BYTE  1
  rInCmd:        .BYTE  1
  rITimer:       .BYTE  1
  ; --- ADC ---
  rLuminosity:   .BYTE  2
  rBattery:      .BYTE  2
  ; --- Gear LEDs ---
  rBrightness:   .BYTE  1
  ; --- SysTick ---
  rSysTickCnt:   .BYTE  2
  rMicroTimerCnt:.BYTE  2
  ; --- State LEDs ---
  rSState:       .BYTE  1
  rSStatePhase:  .BYTE  1
  rSStatePhases: .BYTE  10
  rSStateTimer:  .BYTE  1
  rSStateLEDs:   .BYTE  1
  ; --- LED Light ---
  rLFlags:       .BYTE  1
  rLBTimer:      .BYTE  1
  rLCTimer:      .BYTE  1
  rLCState:      .BYTE  1
  rLNState:      .BYTE  1
.CSEG

;***********************************************************************************
;*****************[ Global Register variables ]*************************************
;***********************************************************************************

;Temporary register for using in Interrupts (may be not saved)
.DEF IRQR    = r12
;Register for storing SREG in interrupts
.DEF SSREG   = r13
;Global temporary register (used also as parameter for get/set values)
.DEF Temp    = r16
.DEF Value   = r16
;Global flags register (DO NOT USE as General register!!!)
.DEF Flags   = r17
.EQU  RF     = 0   ;Reset Flag
.EQU  SF     = 1   ;Sleep Flag
.EQU  UF     = 2   ;UART Flag
.EQU  IF     = 3   ;IR Flag
.EQU  CF     = 4   ;Command Flag
.EQU  BF     = 5   ;Blink Flag
.EQU  TF     = 6   ;SysTick Flag
.EQU  LF     = 7   ;Led Light Flag
;Global get/set 16 bit parameter registers
.DEF ValueL  = r24
.DEF ValueH  = r25

;-----------------------------------------------------------------------------------
