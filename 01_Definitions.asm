;***********************************************************************************
;*****************[ Основные константы ]********************************************
;***********************************************************************************

;Дата и время компиляции проэкта, тип устройства
#define PROJECT_DATE __CENTURY__*1000000 + __YEAR__*10000 + __MONTH__*100 + __DAY__
#define PROJECT_TIME __HOUR__*10000 + __MINUTE__*100 + __SECOND__
#define DEVICESTRING "ATmega48"

;Версия
.EQU  IP_VERSION        = $0201
.EQU  IP_PROJECT_DATE   = PROJECT_DATE
.EQU  IP_PROJECT_TIME   = PROJECT_TIME

;Дата и время прошивки, если существует
.EQU  LOAD_DATE_TIME    = ((FLASHEND + 1) - PAGESIZE + 1) ;$07E1

;***********************************************************************************
;*****************[ Константы протокола EAST2 ]*************************************
;***********************************************************************************

.EQU  EAST2_START                    = $85
.EQU  EAST2_STOP                     = $21
.EQU  EAST2_DEVICE_ADDRESS           = $02

.EQU  CMD_CONNECT                    = $00
.EQU  CMD_SLED_CONTROL               = $10 ;
.EQU  CMD_GLED_CONTROL               = $11 ;
.EQU  CMD_GET_STATE                  = $12 ;

;.EQU  CMD_IRIVER_VOLP                = $15;
;.EQU  CMD_IRIVER_BACK                = $16;
;.EQU  CMD_IRIVER_NEXT                = $17;
;.EQU  CMD_PANASONIC_EXTERNAL         = $21;
;.EQU  CMD_PANASONIC_INTERNAL         = $22;
;.EQU  CMD_PANASONIC_LIGHT            = $23;
;.EQU  CMD_PANASONIC_SLEEP_ON         = $24;
;.EQU  CMD_PANASONIC_SLEEP_OFF        = $25;
;.EQU  CMD_PANASONIC_MOTOR_ON         = $26;
;.EQU  CMD_PANASONIC_MOTOR_OFF        = $27;

.EQU  CMD_BOOT_ENTER                 = $F0
.EQU  CMD_DISCONNECT                 = $FF

.EQU  STATUS_SUCCESS                 = $00
.EQU  STATUS_ERROR                   = $02

;***********************************************************************************
;*****************[ Режимы работы EAST2]********************************************
;***********************************************************************************

.EQU EAST2_WAIT_START               = 0
.EQU EAST2_WAIT_SIZEL               = 1
.EQU EAST2_WAIT_SIZEH               = 2
.EQU EAST2_WAIT_DATA                = 3
.EQU EAST2_WAIT_STOP                = 4
.EQU EAST2_WAIT_CSL                 = 5
.EQU EAST2_WAIT_CSH                 = 6

;***********************************************************************************
;*****************[ Режимы работы State]********************************************
;***********************************************************************************

.EQU STATE_IDLE                     = 0
.EQU STATE_POWER_ON                 = 1
.EQU STATE_VBAT_GOOD                = 2
.EQU STATE_VBAT_NORM                = 3
.EQU STATE_VBAT_LOW                 = 4
.EQU STATE_VBAT_FATAL               = 5
.EQU STATE_LIGHT_SAVE_OK            = 6
.EQU STATE_LEDLIGHT_ON              = 7
.EQU STATE_LEDLIGHT_OFF             = 8

;***********************************************************************************
;*****************[ Режимы работы LED Light]****************************************
;***********************************************************************************

.EQU LL_STATE_OFF                   = 0
.EQU LL_STATE_MAX                   = 1
.EQU LL_STATE_MID                   = 2
.EQU LL_STATE_MIN                   = 3
.EQU LL_STATE_FLS                   = 4

.EQU LL_IR_CMD_TOGGLE               = 1
.EQU LL_IR_CMD_NEXT                 = 2
.EQU LL_IR_CMD_MIN                  = 3
.EQU LL_IR_CMD_MID                  = 4
.EQU LL_IR_CMD_MAX                  = 5

;***********************************************************************************
;*****************[ Порты, назначение выводов ]*************************************
;***********************************************************************************
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
;-----------------------------------------------------------------------------------
;*** LED Light          - Pin 10         - PD6           - xxx ***
.EQU LEDLDDR   = DDRD
.EQU LEDLPORT  = PORTD
.EQU LEDLPIN   = PIND
.EQU LEDLIGHT  = PD6

;***********************************************************************************
;*****************[ Переменные в ОЗУ ]**********************************************
;***********************************************************************************

.DSEG
  rUMode:        .BYTE  1
  rUSize:        .BYTE  2
  rUBuffer:      .BYTE  80
  rUCnt:         .BYTE  2
  rUPtr:         .BYTE  2
  rUCS:          .BYTE  2
  rIIndex:       .BYTE  1
  rIAddr:        .BYTE  1
  rInAddr:       .BYTE  1
  rICmd:         .BYTE  1
  rInCmd:        .BYTE  1
  rLuminosity:   .BYTE  2
  rBattery:      .BYTE  2
  rBrightness:   .BYTE  1
  rSysTickCnt:   .BYTE  2
  rSState:       .BYTE  1
  rSStatePhase:  .BYTE  1
  rSStatePhases: .BYTE  10
  rSStateTimer:  .BYTE  1
  rSStateLEDs:   .BYTE  1
  rLLightMode:   .BYTE  1
  rLLightTimer:  .BYTE  1
.CSEG

;***********************************************************************************
;*****************[ Регистровые переменные ]****************************************
;***********************************************************************************




;*****************[ Main ]**********************************************************
.DEF Light   = r2
.DEF I_nCmd  = r3
.DEF SSREG   = r13

.DEF Delay0  = r14
.DEF Delay1  = r15
.DEF Del50ms = r16

.DEF Temp    = r16
;DEF Delay   = r17
.DEF Timer   = r18
.DEF Port    = r19
.DEF Flags   = r20
.EQU  RF     = 0   ;Reset Flag
.EQU  SF     = 1   ;Sleep Flag
.EQU  UF     = 2   ;UART Flag
.EQU  IF     = 3   ;IR Flag
.EQU  CF     = 4   ;Command Flag
.EQU  BF     = 5   ;Blink Flag
.EQU  TF     = 6   ;SysTick Flag
.EQU  LF     = 7   ;Led Light Flag

;*****************[ UART ]**********************************************************

;DEF Temp    = r16
.DEF Mode    = r16
.DEF U_Data  = r21
.DEF U_Addr  = r22
.DEF U_Cmd   = r23
.DEF U_Param = r24

.DEF U_Cnt   = r26
.DEF U_CntL  = r26
.DEF U_CntH  = r27
.DEF U_Reg   = r28
.DEF U_RegL  = r28
.DEF U_RegH  = r29
.DEF U_Ptr   = r28
.DEF U_PtrL  = r28
.DEF U_PtrH  = r29
.DEF U_CS    = r30
.DEF U_CSL   = r30
.DEF U_CSH   = r31

;*****************[ IR ]************************************************************

.DEF I_Cmd   = r16
.DEF I_DutyL = r28
.DEF I_DutyH = r29

;*****************[ ADC ]***********************************************************

.DEF A_VL     = r2
.DEF A_VH     = r3
.DEF A_Mode   = r21
.DEF A_ValueL = r28
.DEF A_ValueH = r29

;*****************[ UART ]**********************************************************

;DEF Temp     = r16
.DEF E_Data   = r21
.DEF E_Addr   = r22

;*****************[ LED Light ]*****************************************************

.DEF L_Flags  = r6  ;  6 7 8 9 10 11 12
.EQU  LFF     = 0   ;Button Fall Flag
.EQU  LRF     = 1   ;Button Rise Flag
.EQU  LNF     = 2   ;Need to switch to next state Flag
.DEF L_BTimer = r7  ;Button Timer
.DEF L_CTimer = r8  ;Command Timer
.DEF L_CState = r9  ;Current State
.DEF L_NState = r10 ;New State if needed
;DEF Temp     = r16
.DEF L_ICmd   = r16
.DEF L_Temp   = r17


;*****************[ System Tick ]***************************************************

.DEF T_State   = r21
.DEF T_Phase   = r22
.DEF T_Timer   = r23
.DEF T_Value   = r24
.DEF T_CntL    = r28
.DEF T_CntH    = r29
.DEF T_PhasesL = r28
.DEF T_PhasesH = r29
.DEF T_FlashL  = r30
.DEF T_FlashH  = r31
