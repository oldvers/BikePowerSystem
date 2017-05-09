;*****************[ Local constants ]***********************************************

; --- Status LEDs states ---

.EQU SLEDS_STATE_IDLE           = 0
.EQU SLEDS_STATE_POWER_ON       = 1
.EQU SLEDS_STATE_VBAT_GOOD      = 2
.EQU SLEDS_STATE_VBAT_NORM      = 3
.EQU SLEDS_STATE_VBAT_LOW       = 4
.EQU SLEDS_STATE_VBAT_FATAL     = 5
.EQU SLEDS_STATE_LIGHT_SAVE_OK  = 6
.EQU SLEDS_STATE_LEDLIGHT_ON    = 7
.EQU SLEDS_STATE_LEDLIGHT_OFF   = 8

; --- Battery voltages ---
; ---------------------------
; | Description |  VBat, V  |
; ---------------------------
; | Good        |  4.20     |
; | Good        |  4.01     |
; | Normal      |  4.00     |
; | Normal      |  3.61     |
; | Low         |  3.60     |
; | Low         |  3.30     |
; | Fatal       |  3.29     |
; | Fatal       |  2.50     |
; ---------------------------

.EQU SLEDS_VBAT_GOOD_MIN  = 4010
.EQU SLEDS_VBAT_NORM_MIN  = 3610
.EQU SLEDS_VBAT_LOW_MIN   = 3300

; --- Device States Indication Table ---

;Format of Byte
; Bit Number   | 7  6  5  4  3  2  1  0
; Description  | B  G  R  {---Time----}
;   Time is in 50 ms Discrete

;--- Power On = 4 Green Flashes
ROM_StatePowerOn     : .DB $42, $02, $42, $02, $42, $02, $46, $00, $00, $00
;--- Battery Voltage Good = 5 Aqua Flashes
ROM_StateVBatGood    : .DB $C1, $01, $C1, $06, $C1, $02, $C1, $02, $C1, $00
;--- Battery Voltage Normal = 5 Green Flashes
ROM_StateVBatNorm    : .DB $41, $01, $41, $06, $41, $02, $41, $02, $41, $00
;--- Battery Voltage Low = 5 Yellow Flashes
ROM_StateVBatLow     : .DB $61, $01, $61, $06, $61, $02, $61, $02, $61, $00
;--- Battery Voltage Fatal = 5 Red Flashes
ROM_StateVBatFatal   : .DB $21, $01, $21, $06, $21, $02, $21, $02, $21, $00
;--- Light On = 3 Long Green Flashes
ROM_StateLedLightOn  : .DB $4A, $0A, $4A, $0A, $4A, $0A, $00, $00, $00, $00
;--- Light On = 3 Long Blue Flashes
ROM_StateLedLightOff : .DB $8A, $0A, $8A, $0A, $8A, $0A, $00, $00, $00, $00

;*****************[ Local variables ]***********************************************

;DEF Temp      = r16
;DEF Value     = r16
;DEF Flags     = r17
.DEF Timer     = r18
.DEF Port      = r19
.DEF T_State   = r21
.DEF T_Phase   = r22
.DEF T_Timer   = r23
.DEF T_Value   = r24
.DEF T_ConstL  = r25
.DEF T_ConstH  = r26
;DEF ValueL    = r28
.DEF T_CntL    = r28
.DEF T_PhasesL = r28
;DEF ValueH    = r29
.DEF T_CntH    = r29
.DEF T_PhasesH = r29
.DEF T_FlashL  = r30
.DEF T_FlashH  = r31

;*****************[ Status LEDs Init ]**********************************************

SLED_Init:   
   ;Configure Status LEDs
   in    Temp,SLEDDDR
   ori   Temp,(1 << SLEDR) | (1 << SLEDG) | (1 << SLEDB)
   out   SLEDDDR,Temp
   sbi   SLEDPORT,SLEDR
   sbi   SLEDPORT,SLEDG
   sbi   SLEDPORT,SLEDB

   ;Configure Power Status LED
   in    Temp,PLEDDDR
   ori   Temp,(1 << PLED)
   out   PLEDDDR,Temp
   sbi   PLEDPORT,PLED

   ;Init RAm variables
   clr   Temp
   sts   rSState,Temp
   sts   rSStateTimer,Temp
   sts   rSStateLEDs,Temp

   ret

;*****************[ Status LEDs DeInit ]********************************************

SLED_DeInit:   
   ;Configure Status LEDs
   in    Temp,SLEDDDR
   andi  Temp,~((1 << SLEDR) | (1 << SLEDG) | (1 << SLEDB))
   out   SLEDDDR,Temp
   cbi   SLEDPORT,SLEDR
   cbi   SLEDPORT,SLEDG
   cbi   SLEDPORT,SLEDB

   ;Configure Power Status LED
   in    Temp,PLEDDDR
   andi  Temp,~(1 << PLED)
   out   PLEDDDR,Temp
   cbi   PLEDPORT,PLED
   ret

;*****************[ Status Red LED On ]*********************************************

SLEDR_On:
   cbi   SLEDPORT,SLEDR
   ret

;*****************[ Status Red LED Off ]********************************************

SLEDR_Off:
   sbi   SLEDPORT,SLEDR
   ret

;*****************[ Status Red LED Toggle ]*****************************************

SLEDR_Toggle:
   in    Temp,SLEDPORT
   sbrc  Temp,SLEDR
   cbi   SLEDPORT,SLEDR
   sbrs  Temp,SLEDR
   sbi   SLEDPORT,SLEDR
   ret

;*****************[ Status Green LED On ]*******************************************

SLEDG_On:
   cbi   SLEDPORT,SLEDG
   ret

;*****************[ Status Green LED Off ]******************************************

SLEDG_Off:
   sbi   SLEDPORT,SLEDG
   ret

;*****************[ Status Blue LED On ]********************************************

SLEDB_On:
   cbi   SLEDPORT,SLEDB
   ret

;*****************[ Status Blue LED Off ]*******************************************

SLEDB_Off:
   sbi   SLEDPORT,SLEDB
   ret

;*****************[ Status Blue LED Toggle ]****************************************

SLEDB_Toggle:
   in    Temp,SLEDPORT
   sbrc  Temp,SLEDB
   cbi   SLEDPORT,SLEDB
   sbrs  Temp,SLEDB
   sbi   SLEDPORT,SLEDB
   ret

;*****************[ Power LED On ]**************************************************

PLED_On:
   cbi   PLEDPORT,PLED
   ret

;*****************[ Power LED Off ]*************************************************

PLED_Off:
   sbi   PLEDPORT,PLED
   ret

;*****************[ Status LEDs Switch ]********************************************

SLEDs_Switch:
   in    Port,SLEDPORT
   com   Value
   andi  Value,0b00000111
   andi  Port,0b11111000
   or    Port,Value
   out   SLEDPORT,Port
   ret

;*****************[ Status LEDs Capture State ]*************************************

SLEDs_Capture:
   in    Value,SLEDPORT
   com   Value
   andi  Value,0b00001111
   ret

;*****************[ Status LED Set State ]******************************************

SLEDs_SetState:
   ;Store new state
   mov   T_State,Value
   ;Save Status LEDs state
   rcall SLEDs_Capture
   sts   rSStateLEDs,Temp

   ;Init count of phases
   ldi   Temp,10
   clr   T_Phase
   ;Init phases pointer in RAM
   ldi   T_PhasesL,Byte1(rSStatePhases)
   ldi   T_PhasesH,Byte2(rSStatePhases)
   ;Init phases pointer in Flash
STSS_PowerOn:
   cpi   T_State,SLEDS_STATE_POWER_ON
   brne  STSS_VBatGood
   ldi   T_FlashL,Byte1(2*ROM_StatePowerOn)
   ldi   T_FlashH,Byte2(2*ROM_StatePowerOn)
   rjmp  STSS_Loop
STSS_VBatGood:
   cpi   T_State,SLEDS_STATE_VBAT_GOOD
   brne  STSS_VBatNorm
   ldi   T_FlashL,Byte1(2*ROM_StateVBatGood)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatGood)
   rjmp  STSS_Loop
STSS_VBatNorm:
   cpi   T_State,SLEDS_STATE_VBAT_NORM
   brne  STSS_VBatLow
   ldi   T_FlashL,Byte1(2*ROM_StateVBatNorm)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatNorm)
   rjmp  STSS_Loop
STSS_VBatLow:
   cpi   T_State,SLEDS_STATE_VBAT_LOW
   brne  STSS_VBatFatal
   ldi   T_FlashL,Byte1(2*ROM_StateVBatLow)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatLow)
   rjmp  STSS_Loop
STSS_VBatFatal:
   cpi   T_State,SLEDS_STATE_VBAT_FATAL
   brne  STSS_LedLightOn
   ldi   T_FlashL,Byte1(2*ROM_StateVBatFatal)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatFatal)
   rjmp  STSS_Loop
STSS_LedLightOn:
   cpi   T_State,SLEDS_STATE_LEDLIGHT_ON
   brne  STSS_LedLightOff
   ldi   T_FlashL,Byte1(2*ROM_StateLedLightOn)
   ldi   T_FlashH,Byte2(2*ROM_StateLedLightOn)
   rjmp  STSS_Loop
STSS_LedLightOff:
   cpi   T_State,SLEDS_STATE_LEDLIGHT_OFF
   brne  STSS_End
   ldi   T_FlashL,Byte1(2*ROM_StateLedLightOff)
   ldi   T_FlashH,Byte2(2*ROM_StateLedLightOff)
   ;rjmp  STSS_Loop
   ;Load phases from Flash to RAM
STSS_Loop:
   lpm   T_Value,Z+
   st    Y+,T_Value
   dec   Temp
   brne  STSS_Loop
   ;Save new state
   sts   rSState,T_State
   ;Save phase
   sts   rSStatePhase,T_Phase
STSS_End:
   ret

;*****************[ Status LEDs System Tick Function ]******************************

SLEDs_Process:
   ;Check if idle state
   lds   T_State,rSState
   cpi   T_State,SLEDS_STATE_IDLE
   breq  ST_CheckVBat
   ;Check if all the phases were complete
   lds   T_Phase,rSStatePhase
   cpi   T_Phase,10
   brsh  ST_CheckVBat

   ;Load phase description from RAM
   ldi   T_PhasesL,Byte1(rSStatePhases)
   ldi   T_PhasesH,Byte2(rSStatePhases)
   clr   Temp
   add   T_PhasesL,T_Phase
   adc   T_PhasesH,Temp
   ld    T_Value,Y
   ;Switch Status LEDs according to the current phase
   mov   Temp,T_Value
   swap  Temp
   lsr   Temp
   rcall SLEDs_Switch
   ;Get current phase timer
   mov   Temp,T_Value
   andi  Temp,$1F
   ;If timer == 0 - go to the next phase
   cpi   Temp,0
   breq  ST_NextPhase
   ;Decrement timer
   dec   Temp
   ;Compose timer and Status LEDs state
   andi  T_Value,$E0
   or    T_Value,Temp
   ;Save phase description to RAM
   st    Y,T_Value
   rjmp  ST_CheckVBat

ST_NextPhase:
   ;Increment phase
   inc   T_Phase
   sts   rSStatePhase,T_Phase
   ;Check if all the phases were complete
   cpi   T_Phase,10
   brne  ST_CheckVBat
   ;Recover previous Status LEDs state
   lds   Value,rSStateLEDs
   rcall SLEDs_Switch
   ;Go to Idle state
   ldi   T_State,SLEDS_STATE_IDLE
   sts   rSState,T_State

ST_CheckVBat:
   ;Timer Interval = 12.5 s
   lds   Timer,rSStateTimer
   inc   Timer
   cpi   Timer,250
   brne  ST_End
   clr   Timer
   rcall SLEDs_CheckBattery
   cpi   Temp,SLEDS_STATE_VBAT_FATAL
   brne  ST_End
   rcall SLEDs_SetState

ST_End:
   sts   rSStateTimer,Timer
   ret

;*****************[ Status LEDs Check Battery ]*************************************

SLEDs_CheckBattery:
   rcall ADC_GetBatteryVoltage
   ldi   T_ConstL,Byte1(SLEDS_VBAT_GOOD_MIN)
   ldi   T_ConstH,Byte2(SLEDS_VBAT_GOOD_MIN)
   cp    ValueL,T_ConstL
   cpc   ValueH,T_ConstH
   brsh  AGBS_Good
   ldi   T_ConstL,Byte1(SLEDS_VBAT_NORM_MIN)
   ldi   T_ConstH,Byte2(SLEDS_VBAT_NORM_MIN)
   cp    ValueL,T_ConstL
   cpc   ValueH,T_ConstH
   brsh  AGBS_Norm
   ldi   T_ConstL,Byte1(SLEDS_VBAT_LOW_MIN)
   ldi   T_ConstH,Byte2(SLEDS_VBAT_LOW_MIN)
   cp    ValueL,T_ConstL
   cpc   ValueH,T_ConstH
   brsh  AGBS_Low
   ldi   Temp,SLEDS_STATE_VBAT_FATAL
   ret
AGBS_Good:
   ldi   Temp,SLEDS_STATE_VBAT_GOOD
   ret
AGBS_Norm:
   ldi   Temp,SLEDS_STATE_VBAT_NORM
   ret
AGBS_Low:
   ldi   Temp,SLEDS_STATE_VBAT_LOW
   ret
