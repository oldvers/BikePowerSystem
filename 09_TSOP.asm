;*****************[ Local constants ]***********************************************

; --- NEC Protocol Time Intervals ---
;Name	Symbol	Norm      Min Time	Max Time	Min	    Max
;Clean	C	    96,75 ms  87,075    106,425	    10884	13303
;Pause	P	    40,5 ms	  36,45	    44,55	    4556	5568
;Start	S	    13,5 ms	  12,263    14,85	    1540	1856
;Repeat	R	    11,25 ms  10,125    12,263	    1265	1539
;One	H	    2,25 ms	  2,025	    2,475	    253		309
;Zero	L	    1,125 ms  1,013	    1,238	    126		154

;For Fosc = 8000000 and Fosc/64
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

; --- IR commands ---
.EQU IR_CMD_PLAY      = 0
.EQU IR_CMD_CH_M      = 1
.EQU IR_CMD_CH_P      = 2
.EQU IR_CMD_EQ        = 4
.EQU IR_CMD_M         = 5
.EQU IR_CMD_P         = 6
.EQU IR_CMD_0         = 8
.EQU IR_CMD_PREV      = 9
.EQU IR_CMD_NEXT      = 10
.EQU IR_CMD_1         = 12
.EQU IR_CMD_2         = 13
.EQU IR_CMD_3         = 14
.EQU IR_CMD_4         = 16
.EQU IR_CMD_5         = 17
.EQU IR_CMD_6         = 18
.EQU IR_CMD_7         = 20
.EQU IR_CMD_8         = 21
.EQU IR_CMD_9         = 22
.EQU IR_CMD_PICK_SONG = 24
.EQU IR_CMD_CH_SET    = 26

;*****************[ Local variables ]***********************************************

.DEF I_nCmd    = r3
.DEF I_Cmd     = r16
.DEF I_DutyL   = r28
.DEF I_DutyH   = r29

;*****************[ TSOP Init ]*****************************************************

TSOP_Init:
   ;Init IR pin
   sbi   IRPORT,IR
   ;Clear flags
   cbr   Flags,(1 << CF)
   ;Init RAM variables
   ser   Temp
   sts   rIAddr,Temp
   sts   rInAddr,Temp
   sts   rICmd,Temp
   sts   rInCmd,Temp
   out   ICMD,Temp

   ;Timer 1 capture mode
   ldi   Temp,(0 << COM1A0) | (0 << COM1B0) | (0 << WGM10)
   sts   TCCR1A,Temp
   ;Capture Falling Edge, 8 us Tick
   ldi   Temp,(1 << ICNC1) | (0 << ICES1) | (0 << WGM12) | (3 << CS10)
   sts   TCCR1B,Temp
   ;ICP and OVF Interrupts
   ldi   Temp,(1 << ICIE1) | (1 << TOIE1)
   sts   TIMSK1,Temp
   ret

;*****************[ TSOP DeInit ]***************************************************

TSOP_DeInit:
   ;DeInit IR pin
   sbi   IRPORT,IR
   ;DeInit timer
   clr   Temp
   sts   TCCR1A,Temp
   sts   TCCR1B,Temp
   sts   TIMSK1,Temp
   ret

;*****************[ TSOP Capture Interrupt ]****************************************

TSOP_Capture:
   push  Temp
   in    SSREG,SREG
   ;Clear timer counter
   clr   Temp
   sts   TCNT1H,Temp
   sts   TCNT1L,Temp
   ;Check if receiving in progress
   sbrc  Flags,IF
   rjmp  T1C_Impuls
T1C_Start:
   ;Indicate receiving in progress (the first capture)
   sbr   Flags,(1 << IF)
   ;Wait for the next capture
   out   SREG,SSREG
   pop   Temp
   reti
T1C_Impuls:
   push  I_DutyL
   push  I_DutyH
   ;Load impulse duration
   lds   I_DutyL,ICR1L
   lds   I_DutyH,ICR1H
; --- Check impulse kind ---
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
   ;Set T Flag in SREG = 1 (One)
   set
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
   ;Clear T Flag in SREG = 0 (Zero)
   clt
   ldi   Temp,Byte2(LMin)
   cpi   I_DutyL,Byte1(LMin)
   cpc   I_DutyH,Temp
   brsh  T1C_HL
T1C_Error:
   ;Indicate no receiving
   cbr   Flags,(1 << IF)
   pop   I_DutyH
   pop   I_DutyL
   out   SREG,SSREG
   pop   Temp
   reti
; --- Start impulse ---
T1C_S:
   ;Clear bit index
   clr   Temp
   sts   rIIndex,Temp
   rjmp  T1C_End
; --- Pause impulse ---
T1C_P:
   ;Set bit index to specific value for future use
   ldi   Temp,77
   sts   rIIndex,Temp
   rjmp  T1C_End
; --- Repeat impulse ---
T1C_R:
   ;Check if Pause impulse was received
   lds   Temp,rIIndex
   cpi   Temp,77
   ;Clear bit index
   clr   Temp
   sts   rIIndex,Temp
   ;Repeat previous command
   rjmp  T1C_CheckCmd
; --- High/Low (One/Zero) impulse ---
T1C_HL:
   ;Shift right all received bits
   lds   Temp,rInCmd
   lsr   Temp
   ;Load T flag and save to the highest received bit
   bld   Temp,7
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
   ;Check if all the bits are received
   cpi   Temp,32
   brne  T1C_End
; --- Check received command ---
T1C_CheckCmd:
   push  I_nCmd
   lds   Temp,rICmd
   lds   I_nCmd,rInCmd
   com   I_nCmd
   ;Compare positive and negative received commands
   cp    Temp,I_nCmd
   pop   I_nCmd
   brne  T1C_Error

   ;Indicate IR receiving complete
   cbr   Flags,(1 << IF)
   sbr   Flags,(1 << CF)
   ;Store command to special register
   out   ICMD,Temp
; --- Error ---
T1C_End:
   pop   I_DutyH
   pop   I_DutyL
   out   SREG,SSREG
   pop   Temp
   reti

;*****************[ TSOP Overflow Interrupt ]***************************************

TSOP_Ovf:
   in    SSREG,SREG
   ;Indicate no receiving
   cbr   Flags,(1 << IF)
   out   SREG,SSREG
   reti

;*****************[ TSOP Check Start Command ]**************************************

TSOP_CheckStartCommand:
   ;Delay about 100 ms until the first command has been received
   ;  (cmd duration == 67.5 ms)
   ldi   Value,4
   rcall Delay25msX
   ;Clear IR command
   ser   Temp
   sts   rICmd,Temp
   sts   rInCmd,Temp
   out   ICMD,Temp
   cbr   Flags,(1 << CF)
   ;Indicate state
   ldi   Value,SLEDS_STATE_POWER_ON
   rcall SLEDs_SetState
   ;Delay during 1 second (20 x 50 ms SysTick)
   ;  including 100 ms of waiting at the beginning
   ldi   Temp,18
   sts   rITimer,Temp
   
TCSC_PowerOnWait:
   sbrc  Flags,CF
   rjmp  TCSC_CheckCommand
   sbrs  Flags,TF
   rjmp  TCSC_PowerOnWait
   ;Process State/Led Light
   rcall SLEDs_Process
   rcall LEDLIGHT_Process
   cbr   Flags,(1 << TF)
   ;Decrement timeout
   lds   Temp,rITimer
   dec   Temp
   sts   rITimer,Temp
   brne  TCSC_PowerOnWait
   ;Timeout 1 s expired - return
   ret
   
TCSC_CheckCommand:
   ;Clear result
   clt
   cbr   Flags,(1 << CF)

   ;Check if command == Play
   in    I_Cmd,ICMD
   cpi   I_Cmd,IR_CMD_PLAY
   brne  TCSC_PowerOnWait

   ;Set T flag - means Device can Wake Up
   set
   ret

;*****************[ TSOP Command Processing ]***************************************

TSOP_Process:
   in    I_Cmd,ICMD
TCP_Play:
   cpi   I_Cmd,IR_CMD_PLAY
   brne  TCP_ChM
   rjmp  TCP_NoRepeat
TCP_ChM:
   cpi   I_Cmd,IR_CMD_CH_M
   brne  TCP_ChP
   rcall SLEDR_Off
   rjmp  TCP_End
TCP_ChP:
   cpi   I_Cmd,IR_CMD_CH_P
   brne  TCP_EQ
   rcall SLEDR_On
   rjmp  TCP_End
TCP_EQ:
   cpi   I_Cmd,IR_CMD_EQ
   brne  TCP_M
   sbr   Flags,(1 << SF)
   rjmp  TCP_NoRepeat
TCP_M:
   cpi   I_Cmd,IR_CMD_M
   brne  TCP_P
   rcall SLEDB_Off
   lds   Temp,rBrightness
   subi  Temp,1
   sts   rBrightness,Temp
   rcall GLED1_SetBright
   rcall GLED2_SetBright
   rjmp  TCP_End
TCP_P:
   cpi   I_Cmd,IR_CMD_P
   brne  TCP_0
   rcall SLEDB_On
   lds   Temp,rBrightness
   subi  Temp,-1
   sts   rBrightness,Temp
   rcall GLED1_SetBright
   rcall GLED2_SetBright
   rjmp  TCP_End
TCP_0:
   cpi   I_Cmd,IR_CMD_0
   brne  TCP_1
   ldi   Temp,0
   rcall LEDLIGHT_IR_Next
   rjmp  TCP_NoRepeat
TCP_1:
   cpi   I_Cmd,IR_CMD_1
   brne  TCP_2
   rcall LEDLIGHT_IR_Min
   rjmp  TCP_NoRepeat
TCP_2:
   cpi   I_Cmd,IR_CMD_2
   brne  TCP_3
   rcall LEDLIGHT_IR_Mid
   rjmp  TCP_NoRepeat
TCP_3:
   cpi   I_Cmd,IR_CMD_3
   brne  TCP_5
   rcall LEDLIGHT_IR_Max
   rjmp  TCP_NoRepeat
TCP_5:
   cpi   I_Cmd,IR_CMD_5
   brne  TCP_Prev
   rcall LEDLIGHT_IR_Fls
   rjmp  TCP_NoRepeat
TCP_Prev:
   cpi   I_Cmd,IR_CMD_PREV
   brne  TCP_Next
   rcall SLEDG_Off
   cbr   Flags,(1 << BF)
   rjmp  TCP_End
TCP_Next:
   cpi   I_Cmd,IR_CMD_NEXT
   brne  TCP_PickSong
   sbr   Flags,(1 << BF)
   rcall SLEDG_On
   rjmp  TCP_End
TCP_PickSong:
   cpi   I_Cmd,IR_CMD_PICK_SONG
   brne  TCP_ChSet
   rcall LEDLIGHT_IR_Toggle
   rjmp  TCP_NoRepeat
TCP_ChSet:
   cpi   I_Cmd,IR_CMD_CH_SET
   brne  TCP_End
   rcall SLEDs_CheckBattery
   rcall SLEDs_SetState
TCP_NoRepeat:
   ser   I_Cmd
   out   ICMD,I_Cmd
   sts   rICmd,I_Cmd
   sts   rInCmd,I_Cmd
TCP_End:
   cbr   Flags,(1 << CF)
   ret

;***********************************************************************************
