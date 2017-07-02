;*****************[ Local constants ]***********************************************

.EQU LL_STATE_OFF                   = 0
.EQU LL_STATE_MAX                   = 1
.EQU LL_STATE_MID                   = 2
.EQU LL_STATE_MIN                   = 3
.EQU LL_STATE_FLS                   = 4

; --- Time intervals (discrete 50 ms -> SysTick) ---
.EQU LL_TIME_SHORT_SWITCH           = 3
.EQU LL_TIME_LONG_SWITCH            = 62

;*****************[ Local variables ]***********************************************

;DEF Temp     = r16
;DEF Value    = r16
.DEF L_ICmd   = r16
;DEF Flags    = r17
;LEDFLAGS     = GPIOR
.EQU  LFF     = 0   ;Button Fall Flag
.EQU  LRF     = 1   ;Button Rise Flag
.EQU  LNF     = 2   ;Need switch to the next state Flag
.EQU  LPF     = 3   ;Pause between switches flag
.DEF L_BTimer = r19 ;Button Timer
.DEF L_CTimer = r20 ;Command Timer
.DEF L_CState = r21 ;Current State
;DEF L_Dbg    = r21 ;Debug Data
.DEF L_NState = r22 ;New State if needed
.DEF L_Temp   = r23
;DEF ValueL   = r24
;DEF ValueH   = r25

;*****************[ Private functions ]*********************************************
; --- NOTE: Consider all the state registers in private functions are ---
; ---       already loaded ---
;-----------------------------------------------------------------------------------

LEDLIGHT_Hold:
   ;LED Light Pin (Output) -> Pull down to Gnd
   in    Temp,LEDLDDR
   ori   Temp,(1 << LEDLIGHT)
   out   LEDLDDR,Temp
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Release:
   ;LED Light Pin (Input) -> Pull up to Vcc
   in    Temp,LEDLDDR
   andi  Temp,~(1 << LEDLIGHT)
   out   LEDLDDR,Temp
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Toggle:
   cpi   L_CState,LL_STATE_OFF
   brne  LLT_GoToOff
LLT_GoToMax:
   ldi   L_CState,LL_STATE_MAX
   ret
LLT_GoToOff:
   ldi   L_CState,LL_STATE_OFF
;  sbr   Flags,(1 << SF)
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Next:
   cpi   L_CState,LL_STATE_OFF
   brne  LLN_Begin
;  sbr   Flags,(1 << SF)
   ret
LLN_Begin:
   inc   L_CState
   ldi   Temp,(LL_STATE_FLS + 1)
   cpse  L_CState,Temp
   ret
   ldi   L_CState,LL_STATE_MAX
   ret

;-----------------------------------------------------------------------------------

LL_Show:
   ldi   Value,0b00000000
LL_Off:
   cpi   L_CState,LL_STATE_OFF
   brne  LL_Max
   ldi   Value,0b00000000
   rjmp  LL_End
LL_Max:
   cpi   L_CState,LL_STATE_MAX
   brne  LL_Mid
   ldi   Value,0b00000111
   rjmp  LL_End
LL_Mid:
   cpi   L_CState,LL_STATE_MID
   brne  LL_Min
   ldi   Value,0b00000010
   rjmp  LL_End
LL_Min:
   cpi   L_CState,LL_STATE_MIN
   brne  LL_Fls
   ldi   Value,0b00000100
   rjmp  LL_End
LL_Fls:
   cpi   L_CState,LL_STATE_FLS
   brne  LL_End
   ldi   Value,0b00000001
LL_End:
   rcall SLEDs_Switch
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_CheckState:
   ;Release the Led Light Button
   rcall LEDLIGHT_Release

   ;If switching to the next state needed
   sbis  LEDFLAGS,LNF
   ret
   ;Check if pause before switching needed
   sbic  LEDFLAGS,LPF
   rjmp  LLCS_SwitchNext
LLCS_Pause:
   ;Indicate pause, load Command Timer with short switch time
   sbi   LEDFLAGS,LPF
   ldi   L_CTimer,LL_TIME_SHORT_SWITCH
   ret

LLCS_SwitchNext:
   ;Current state == New state -> No switching needed
   cp    L_CState,L_NState
   breq  LLCS_NoSwitch
   ;Indicate pause finished, load Command Timer with short switch time
   cbi   LEDFLAGS,LPF
   ldi   L_CTimer,LL_TIME_SHORT_SWITCH
   ;Hold the Led Light Button
   rcall LEDLIGHT_Hold

;   mov   L_Temp,L_CState
;   subi  L_Temp,-$30
;   rcall UART_Dbg

   ret

LLCS_NoSwitch:
   ;Clear New state switch flag
   cbi   LEDFLAGS,LNF
   ret

;-----------------------------------------------------------------------------------

;*****************[ Public functions ]**********************************************

;-----------------------------------------------------------------------------------

;Callback function for Micro Timer
SysTick_MicroTimerComplete:
   ;Check LedLight Button pin state
   sbic  LEDLPIN,LEDLIGHT
   rjmp  LLB_Released
LLB_Held:
   ;Pin low -> Falling edge detected
   sbi   LEDFLAGS,LFF
   ret
LLB_Released:
   ;Pin high -> Rising edge detected
   sbi   LEDFLAGS,LRF
   ret

;-----------------------------------------------------------------------------------

;IRQ Handler for Led Light Button
LEDLIGHT_Btn:
   rcall SysTick_MicroTimerReset
   reti

;-----------------------------------------------------------------------------------

LEDLIGHT_Init:
   ;LED Light Pin (Input)
   cbi   LEDLPORT,LEDLIGHT
   rcall LEDLIGHT_Release

   clr   Temp
   out   LEDFLAGS,Temp
   sts   rLBTimer,Temp
   sts   rLCTimer,Temp
   sts   rLCState,Temp
   sts   rLNState,Temp

   ;Enable External Interrupt 22 (PCINT22/PD6, Led Light) for Wake Up
   ldi   Temp,(1 << PCIF2)
   sts   PCIFR,Temp
   ldi   Temp,(1 << PCIE2)
   sts   PCICR,Temp
   ldi   Temp,(1 << PCINT22)
   sts   PCMSK2,Temp

   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_DeInit:
   lds   L_CState,rLCState
   cpi   L_CState,LL_STATE_OFF
   breq  LDI_End
   rcall LEDLIGHT_Hold
   ;Delay 3000 ms
   ldi   Value,120
   rcall Delay25msX
LDI_End:
   cbi   LEDLPORT,LEDLIGHT
   rcall LEDLIGHT_Release
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_CheckButtonHeld:
   clt
   sbic  LEDLPIN,LEDLIGHT
   ret
LLCBH_Held:
   sbi   LEDFLAGS,LFF
   set
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Process:
   ;Load current state
   lds   L_BTimer,rLBTimer
   lds   L_CTimer,rLCTimer
   lds   L_CState,rLCState
   lds   L_NState,rLNState

LLP_CheckBtnFall:
   ;Check if falling edge of Led Light Button was detected
   sbis  LEDFLAGS,LFF
   rjmp  LLP_CheckBtnRise
   cbi   LEDFLAGS,LFF
   ;Start counting how long Button will be held
   clr   L_BTimer
;   rcall PLED_On
   rjmp  LLP_CheckIrCmdTimer

LLP_CheckBtnRise:
   ;Check if rising edge of Led Light Button was detected
   sbis  LEDFLAGS,LRF
   rjmp  LLP_CheckIrCmdTimer
   cbi   LEDFLAGS,LRF
   ;Check how long the Button was held
   inc   L_BTimer
;   rcall PLED_Off

   ;If Button was held more than 3 s -> Toggle state (OFF->MAX/MAX->OFF)
   cpi   L_BTimer,(LL_TIME_LONG_SWITCH - 1)
   brsh  LLP_CBR_Toggle
LLP_CBR_Next:
   ;Else -> Go to the next state
   rcall LEDLIGHT_Next
   rjmp  LLP_CheckIrCmdTimer
LLP_CBR_Toggle:
   rcall LEDLIGHT_Toggle

LLP_CheckIrCmdTimer:
   ;Release the Button if IR command was received
   ;And Command Timer expired
   ;Go to the next state if needed
   tst   L_CTimer
   breq  LLP_End
   dec   L_CTimer
   tst   L_CTimer
   brne  LLP_End
   rcall LEDLIGHT_CheckState

LLP_End:
   inc   L_BTimer

   ;Store current state
   sts   rLBTimer,L_BTimer
   sts   rLCTimer,L_CTimer
   sts   rLCState,L_CState
   sts   rLNState,L_NState

;   rcall LL_Show

   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_IR_Toggle:
   ldi   L_CTimer,(LL_TIME_LONG_SWITCH + 4)
   rjmp  LLITN_Common

LEDLIGHT_IR_Next:
   ldi   L_CTimer,(LL_TIME_SHORT_SWITCH + 4)

LLITN_Common:
   sts   rLCTimer,L_CTimer
   cbi   LEDFLAGS,LNF
   rcall LEDLIGHT_Hold
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_IR_Mid:
   ldi   L_NState,LL_STATE_MID
   rjmp  LLIC_Common

LEDLIGHT_IR_Fls:
   ldi   L_NState,LL_STATE_FLS
   rjmp  LLIC_Common

LEDLIGHT_IR_Max:
   ldi   L_NState,LL_STATE_MAX
   rjmp  LLIC_Common

LEDLIGHT_IR_Min:
   ldi   L_NState,LL_STATE_MIN

LLIC_Common:
   lds   L_CState,rLCState

   cpi   L_CState,LL_STATE_OFF
   brne  LLIC_TimeoutShort
LLIC_TimeoutLong:
   ldi   L_CTimer,(LL_TIME_LONG_SWITCH + 4)
   rjmp  LLIC_TimeoutEnd
LLIC_TimeoutShort:
   ldi   L_CTimer,(LL_TIME_SHORT_SWITCH - 1)
LLIC_TimeoutEnd:
   sbi   LEDFLAGS,LNF
   cbi   LEDFLAGS,LPF

   cpse  L_CState,L_NState
   rjmp  LLIC_End
   ret

LLIC_End:
   sts   rLCTimer,L_CTimer
   sts   rLNState,L_NState
   rcall LEDLIGHT_Hold
   ret

;-----------------------------------------------------------------------------------
