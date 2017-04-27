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

   clr   Temp
   sts   rSState,Temp
   sts   rSStateTimer,Temp
   sts   rSStateLEDs,Temp

   ret

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

SLEDR_On:
   cbi   SLEDPORT,SLEDR
   ret

SLEDR_Off:
   sbi   SLEDPORT,SLEDR
   ret

SLEDR_Toggle:
   in    Temp,SLEDPORT
   sbrc  Temp,SLEDR
   cbi   SLEDPORT,SLEDR
   sbrs  Temp,SLEDR
   sbi   SLEDPORT,SLEDR
   ret

SLEDG_On:
   cbi   SLEDPORT,SLEDG
   ret

SLEDG_Off:
   sbi   SLEDPORT,SLEDG
   ret

SLEDB_On:
   cbi   SLEDPORT,SLEDB
   ret

SLEDB_Off:
   sbi   SLEDPORT,SLEDB
   ret

SLEDB_Toggle:
   in    Temp,SLEDPORT
   sbrc  Temp,SLEDB
   cbi   SLEDPORT,SLEDB
   sbrs  Temp,SLEDB
   sbi   SLEDPORT,SLEDB
   ret

PLED_On:
   cbi   PLEDPORT,PLED
   ret

PLED_Off:
   sbi   PLEDPORT,PLED
   ret

SLEDs_Switch:
   in    Port,SLEDPORT
   com   Temp
   andi  Temp,0b00000111
   andi  Port,0b11111000
   or    Port,Temp
   out   SLEDPORT,Port
   ret

SLEDs_Capture:
   in    Temp,SLEDPORT
   com   Temp
   andi  Temp,0b00001111
   ret
   

;***********************************************************************************
;***[ Status LED Set State ]********************************************************
;***********************************************************************************

SLEDs_SetState:
   mov   T_State,Temp

   rcall SLEDs_Capture
   sts   rSStateLEDs,Temp

   ldi   Temp,10
   clr   T_Phase
   ldi   T_PhasesL,Byte1(rSStatePhases)
   ldi   T_PhasesH,Byte2(rSStatePhases)

STSS_PowerOn:
   cpi   T_State,STATE_POWER_ON
   brne  STSS_VBatGood
   ldi   T_FlashL,Byte1(2*ROM_StatePowerOn)
   ldi   T_FlashH,Byte2(2*ROM_StatePowerOn)
   rjmp  STSS_Loop
STSS_VBatGood:
   cpi   T_State,STATE_VBAT_GOOD
   brne  STSS_VBatNorm
   ldi   T_FlashL,Byte1(2*ROM_StateVBatGood)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatGood)
   rjmp  STSS_Loop
STSS_VBatNorm:
   cpi   T_State,STATE_VBAT_NORM
   brne  STSS_VBatLow
   ldi   T_FlashL,Byte1(2*ROM_StateVBatNorm)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatNorm)
   rjmp  STSS_Loop
STSS_VBatLow:
   cpi   T_State,STATE_VBAT_LOW
   brne  STSS_VBatFatal
   ldi   T_FlashL,Byte1(2*ROM_StateVBatLow)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatLow)
   rjmp  STSS_Loop
STSS_VBatFatal:
   cpi   T_State,STATE_VBAT_FATAL
   brne  STSS_LedLightOn
   ldi   T_FlashL,Byte1(2*ROM_StateVBatFatal)
   ldi   T_FlashH,Byte2(2*ROM_StateVBatFatal)
   rjmp  STSS_Loop

STSS_LedLightOn:
   cpi   T_State,STATE_LEDLIGHT_ON
   brne  STSS_LedLightOff
   ldi   T_FlashL,Byte1(2*ROM_StateLedLightOn)
   ldi   T_FlashH,Byte2(2*ROM_StateLedLightOn)
   rjmp  STSS_Loop
STSS_LedLightOff:
   cpi   T_State,STATE_LEDLIGHT_OFF
   brne  STSS_End
   ldi   T_FlashL,Byte1(2*ROM_StateLedLightOff)
   ldi   T_FlashH,Byte2(2*ROM_StateLedLightOff)
;   rjmp  STSS_Loop

STSS_Loop:
   lpm   T_Value,Z+
   st    Y+,T_Value
   dec   Temp
   brne  STSS_Loop
   sts   rSState,T_State
   sts   rSStatePhase,T_Phase
STSS_End:
   ret

;***********************************************************************************
;***[Device States Indication Table]************************************************
;***********************************************************************************

;Format of Byte
; Bit Number   | 7  6  5  4  3  2  1  0
; Description  | B  G  R  {---Time----}
;   Time is in 50 ms Discrete

;.EQU STATE_VBAT_GOOD                = 2
;.EQU STATE_VBAT_NORM                = 3
;.EQU STATE_VBAT_LOW                 = 4
;.EQU STATE_VBAT_FATAL

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




;***********************************************************************************
;***[ System Tick Function ]********************************************************
;***********************************************************************************

SLEDs_Process:
   lds   T_State,rSState
   cpi   T_State,STATE_IDLE
   breq  ST_CheckVBat
   lds   T_Phase,rSStatePhase
   cpi   T_Phase,10
   brsh  ST_CheckVBat

   ldi   T_PhasesL,Byte1(rSStatePhases)
   ldi   T_PhasesH,Byte2(rSStatePhases)
   clr   Temp
   add   T_PhasesL,T_Phase
   adc   T_PhasesH,Temp
   ld    T_Value,Y

   mov   Temp,T_Value
   swap  Temp
   lsr   Temp
   rcall SLEDs_Switch

   mov   Temp,T_Value
   andi  Temp,$1F
   cpi   Temp,0
   breq  ST_NextPhase
   dec   Temp
   andi  T_Value,$E0
   or    T_Value,Temp
   st    Y,T_Value
   rjmp  ST_CheckVBat

ST_NextPhase:
   inc   T_Phase
   sts   rSStatePhase,T_Phase
   cpi   T_Phase,10
   brne  ST_CheckVBat
   ;rcall LEDLIGHT_Release
   lds   Temp,rSStateLEDs
   ;ldi   Temp,1
   rcall SLEDs_Switch
   ldi   T_State,STATE_IDLE
   sts   rSState,T_State

ST_CheckVBat:
   ;Timer Interval = 12.5 s
   lds   Timer,rSStateTimer
   inc   Timer
   cpi   Timer,250
   brne  ST_End
   clr   Timer
   rcall ADC_GetBatteryState
   cpi   Temp,STATE_VBAT_FATAL
   brne  ST_End
   rcall SLEDs_SetState

ST_End:
   sts   rSStateTimer,Timer
   ;cbr   Flags,(1 << TF)
   ret
