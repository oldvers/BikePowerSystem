;***********************************************************************************
;***[ TSOP Init ]*******************************************************************
;***********************************************************************************

TSOP_Init:
   sbi   IRPORT,IR

   cbr   Flags,(1 << IF)
   clr   Temp
   sts   rIAddr,Temp
   sts   rInAddr,Temp
   sts   rICmd,Temp
   sts   rInCmd,Temp


   ldi   Temp,(0 << COM1A0) | (0 << COM1B0) | (0 << WGM10)
   sts   TCCR1A,Temp
   ;Capture Falling Edge, 8 us Tick
   ldi   Temp,(1 << ICNC1) | (0 << ICES1) | (0 << WGM12) | (3 << CS10)
   sts   TCCR1B,Temp
   ;ICP and OVF Interrupts
   ldi   Temp,(1 << ICIE1) | (1 << TOIE1)
   sts   TIMSK1,Temp
   ret

;***********************************************************************************
;***[ TSOP DeInit ]*****************************************************************
;***********************************************************************************

TSOP_DeInit:
   sbi   IRPORT,IR

   clr   Temp
   sts   TCCR1A,Temp
   sts   TCCR1B,Temp
   sts   TIMSK1,Temp
   ret

;***********************************************************************************
;***[ TSOP Time Intervals ]*********************************************************
;***********************************************************************************

;Name	Symbol	Norm      Min Time	Max Time	Min	    Max
;Clean	C	    96,75 ms  87,075    106,425	    10884	13303
;Pause	P	    40,5 ms	  36,45	    44,55	    4556	5568
;Start	S	    13,5 ms	  12,263    14,85	    1540	1856
;Repeat	R	    11,25 ms  10,125    12,263	    1265	1539
;One	H	    2,25 ms	  2,025	    2,475	    253		309
;Zero	L	    1,125 ms  1,013	    1,238	    126		154


;for fosc = 8000000 and fosc/64
.EQU LMin = 126
.EQU LMax = 154
.EQU HMin = 253
.EQU HMax = 309
.EQU RMin = 1265
.EQU RMax = 1538
.EQU SMin = 1541
.EQU SMax = 1856
.EQU PMin = 4556
.EQU PMax = 5568
.EQU CMin = 10884
.EQU CMax = 13303

;***********************************************************************************
;***[ TSOP Capture Interrupt ]******************************************************
;***********************************************************************************

TSOP_Capture:
   push  Temp
   in    SSREG,SREG
   clr   Temp                     ;Очищаем счечик таймера для измерения
   sts   TCNT1H,Temp
   sts   TCNT1L,Temp
   sbrc  Flags,IF
   rjmp  T1C_Impuls
T1C_Start:
   sbr   Flags,(1 << IF)
   out   SREG,SSREG
   pop   Temp
   reti
T1C_Impuls:
   push  I_DutyL
   push  I_DutyH

   lds   I_DutyL,ICR1L
   lds   I_DutyH,ICR1H
T1C_CMax:
   ldi   Temp,Byte2(CMax)
   cpi   I_DutyL,Byte1(CMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_CMin:
   ldi   Temp,Byte2(CMin)
   cpi   I_DutyL,Byte1(CMin)
   cpc   I_DutyH,Temp
   brsh  T1C_P
T1C_PMax:
   ldi   Temp,Byte2(PMax)
   cpi   I_DutyL,Byte1(PMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_PMin:
   ldi   Temp,Byte2(PMin)
   cpi   I_DutyL,Byte1(PMin)
   cpc   I_DutyH,Temp
   brsh  T1C_P
T1C_SMax:
   ldi   Temp,Byte2(SMax)
   cpi   I_DutyL,Byte1(SMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_SMin:
   ldi   Temp,Byte2(SMin)
   cpi   I_DutyL,Byte1(SMin)
   cpc   I_DutyH,Temp
   brsh  T1C_S
T1C_RMax:
   ldi   Temp,Byte2(RMax)
   cpi   I_DutyL,Byte1(RMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_RMin:
   ldi   Temp,Byte2(RMin)
   cpi   I_DutyL,Byte1(RMin)
   cpc   I_DutyH,Temp
   brsh  T1C_R
T1C_HMax:
   ldi   Temp,Byte2(HMax)
   cpi   I_DutyL,Byte1(HMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_HMin:
   set   ;Set T Flag in SREG = One
   ldi   Temp,Byte2(HMin)
   cpi   I_DutyL,Byte1(HMin)
   cpc   I_DutyH,Temp
   brsh  T1C_HL
T1C_LMax:
   ldi   Temp,Byte2(LMax)
   cpi   I_DutyL,Byte1(LMax)
   cpc   I_DutyH,Temp
   brsh  T1C_Error
T1C_LMin:
   clt   ;Clear T Flag in SREG = Zero
   ldi   Temp,Byte2(LMin)
   cpi   I_DutyL,Byte1(LMin)
   cpc   I_DutyH,Temp
   brsh  T1C_HL

T1C_Error:
   cbr   Flags,(1 << IF)
   pop   I_DutyH
   pop   I_DutyL
   out   SREG,SSREG
   pop   Temp
   reti

T1C_S:
   clr   Temp
   sts   rIIndex,Temp
   rjmp  T1C_End
T1C_P:
   ldi   Temp,77
   sts   rIIndex,Temp
   rjmp  T1C_End
T1C_R:
   lds   Temp,rIIndex
   cpi   Temp,77
   ;brne  T1C_Error
   clr   Temp
   sts   rIIndex,Temp
   rjmp  T1C_CheckCmd
T1C_HL:
   lds   Temp,rInCmd
   lsr   Temp
   bld   Temp,7      ;Load T Flag To Bit 7 of Register
   sts   rInCmd,Temp
   lds   Temp,rICmd
   ror   Temp
   sts   rICmd,Temp
   lds   Temp,rInAddr
   ror   Temp
   sts   rInAddr,Temp
   lds   Temp,rIAddr
   ror   Temp
   sts   rIAddr,Temp
T1C_CheckIndex:
   lds   Temp,rIIndex
   inc   Temp
   sts   rIIndex,Temp
   cpi   Temp,32
   brne  T1C_End

T1C_CheckCmd:
   push  I_nCmd
   lds   Temp,rICmd
   lds   I_nCmd,rInCmd
   com   I_nCmd
   cp    Temp,I_nCmd
   pop   I_nCmd
   brne  T1C_Error

   cbr   Flags,(1 << IF)
   sbr   Flags,(1 << CF)

T1C_End:
   pop   I_DutyH
   pop   I_DutyL
   out   SREG,SSREG
   pop   Temp
   reti

;***********************************************************************************
;***[ TSOP Overflow Interrupt ]*****************************************************
;***********************************************************************************

TSOP_Ovf:
   in    SSREG,SREG
   cbr   Flags,(1 << IF)
   out   SREG,SSREG
   reti

;***********************************************************************************
;***[ TSOP Check Start Command ]****************************************************
;***********************************************************************************

TSOP_CheckStartCommand:
   clt
   sbrs  Flags,CF
   ret
   lds   Temp,rICmd
   cpi   Temp,0
   brne  TCSC_End
   set
TCSC_End:
   ret

;***********************************************************************************
;***[ TSOP Command Processing ]*****************************************************
;***********************************************************************************

TSOP_Process:
   lds   I_Cmd,rICmd
TCP_Play:
   cpi   I_Cmd,0
   brne  TCP_ChM
   rjmp  TCP_End
TCP_ChM:
   cpi   I_Cmd,1
   brne  TCP_ChP
   rcall SLEDR_Off
   rjmp  TCP_End
TCP_ChP:
   cpi   I_Cmd,2
   brne  TCP_EQ
   rcall SLEDR_On
   rjmp  TCP_End
TCP_EQ:
   cpi   I_Cmd,4
   brne  TCP_M
   sbr   Flags,(1 << SF)
   rjmp  TCP_End
TCP_M:
   cpi   I_Cmd,5
   brne  TCP_P
   lds   Temp,rBrightness
   subi  Temp,1
   sts   rBrightness,Temp
   rcall GLED1_SetBright
   rcall GLED2_SetBright
   rjmp  TCP_End
TCP_P:
   cpi   I_Cmd,6
   brne  TCP_0
   lds   Temp,rBrightness
   subi  Temp,-1
   sts   rBrightness,Temp
   rcall GLED1_SetBright
   rcall GLED2_SetBright
   rjmp  TCP_End
TCP_0:
   cpi   I_Cmd,8
   brne  TCP_1
   ldi   Temp,0
   sts   rBrightness,Temp
   rcall GLED1_SetBright
   rcall GLED2_SetBright
   rjmp  TCP_End
TCP_1:
   cpi   I_Cmd,12
   brne  TCP_2
;   rcall LEDLIGHT_Next
   ;clr   I_Cmd
   ;sts   rICmd,I_Cmd
   ;sts   rInCmd,I_Cmd
   rjmp  TCP_NoRepeat ;TCP_End
TCP_2:
   cpi   I_Cmd,13
   brne  TCP_Prev
;   rcall LEDLIGHT_Next
;   rcall LEDLIGHT_Next
;   rcall LEDLIGHT_Next
   ;clr   I_Cmd
   ;sts   rICmd,I_Cmd
   ;sts   rInCmd,I_Cmd
   rjmp  TCP_NoRepeat ;TCP_End
TCP_Prev:
   cpi   I_Cmd,9
   brne  TCP_Next
   rcall SLEDG_Off
   cbr   Flags,(1 << BF)
   rjmp  TCP_End
TCP_Next:
   cpi   I_Cmd,10
   brne  TCP_PickSong
   sbr   Flags,(1 << BF)
   rcall SLEDG_On
   rjmp  TCP_End
TCP_PickSong:
   cpi   I_Cmd,24
   brne  TCP_ChSet
   ;clr   I_Cmd
   ;sts   rICmd,I_Cmd
   ;sts   rInCmd,I_Cmd
;   rcall LEDLIGHT_Toggle
   rjmp  TCP_NoRepeat ;TCP_End
TCP_ChSet:
   cpi   I_Cmd,26
   brne  TCP_End
   rcall ADC_GetBatteryState
   rcall SLEDs_SetState
;  rjmp  TCP_End
TCP_NoRepeat:
   clr   I_Cmd
   sts   rICmd,I_Cmd
   sts   rInCmd,I_Cmd
TCP_End:
   cbr   Flags,(1 << CF)
   ret

