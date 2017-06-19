;*****************[ Local constants ]***********************************************

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

; --- Time intervals (discrete 50 ms -> SysTick) ---
.EQU LL_TIME_SHORT_SWITCH           = 3
.EQU LL_TIME_LONG_SWITCH            = 62

;*****************[ Local variables ]***********************************************

;DEF Temp     = r16
;DEF Value    = r16
.DEF L_ICmd   = r16
;DEF Flags    = r17
.DEF L_Flags  = r18 ;  6 7 8 9 10 11 12
.EQU  LFF     = 0   ;Button Fall Flag
.EQU  LRF     = 1   ;Button Rise Flag
.EQU  LNF     = 2   ;Need switch to the next state Flag
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

LEDLIGHT_Btn:
   push  L_Flags
   in    SSREG,SREG

   ;Load flags from RAM
   lds   L_Flags,rLFlags
   ;nop
   ;nop
   ;Set T bit in SREG
   ;set
   nop
   ;Check LedLight Button pin state
   sbic  LEDLPIN,LEDLIGHT
   rjmp  LLB_Released
LLB_Held:
   ;rcall SLEDB_On
   ;Load T bit and save it to Flag
   ;bld   L_Flags,LFF
   ;Pin low -> Falling edge detected
   sbr   L_Flags,(1 << LFF)
   rjmp  LLB_End
LLB_Released:
   ;rcall SLEDB_Off
   ;Load T bit and save it to Flag
   ;bld   L_Flags,LRF
   ;Pin high -> Rising edge detected
   sbr   L_Flags,(1 << LRF)
LLB_End:
   ;Store flags to RAM
   sts   rLFlags,L_Flags
   
   out   SREG,SSREG
   pop   L_Flags
   reti

;-----------------------------------------------------------------------------------

;  private void toggle()
;  {
;    if (fCurState == LL_STATE_OFF)
;    {
;      fCurState = LL_STATE_MAX;
;    }
;    else
;    {
;      fCurState = LL_STATE_OFF;
;    }
;    
;    fOwner.updateLedLight(fCurState);
;  }
LEDLIGHT_Toggle:
   ;ldi   L_Temp,LL_STATE_OFF
;   lds   L_CState,rLCState
   ;cp    L_CState,L_Temp
   cpi   L_CState,LL_STATE_OFF
   brne  LLT_GoToOff
LLT_GoToMax:
   ;ldi   L_Temp,LL_STATE_MAX
   ldi   L_CState,LL_STATE_MAX
   ret
LLT_GoToOff:
   ;mov   L_CState,L_Temp
;   sts   rLCState,L_CState
   sbr   Flags,(1 << SF)
   ret

;-----------------------------------------------------------------------------------

;  private void next()
;  {
;    if (fCurState == LL_STATE_OFF) return;
;    fCurState++;
;    if (fCurState > LL_STATE_FLS) fCurState = LL_STATE_MAX;
;
;    fOwner.updateLedLight(fCurState);
;  }
LEDLIGHT_Next:
   ;ldi   L_Temp,LL_STATE_OFF
;   lds   L_CState,rLCState
   ;cpse  L_CState,L_Temp
   cpi   L_CState,LL_STATE_OFF
   ;rjmp  LLN_Begin
   brne  LLN_Begin
   sbr   Flags,(1 << SF)
   ret
LLN_Begin:
   inc   L_CState
   ;ldi   L_Temp,(LL_STATE_FLS + 1)
   ldi   Temp,(LL_STATE_FLS + 1)
   ;cp    L_CState,L_Temp
   cp    L_CState,Temp
   brlo  LLN_End
   ;ldi   L_Temp,LL_STATE_MAX
   ;mov   L_CState,L_Temp
   ldi   L_CState,LL_STATE_MAX
LLN_End:
;   sts   rLCState,L_CState
   ret

;-----------------------------------------------------------------------------------

;  private void checkstate()
;  {
;    if ((fLLNeedNext) && (fCurState != fNewState))
;    {
;      fCmdTimer = 3;
;      fLLBtnFall = true;
;    }
;    else fLLNeedNext = false;
;  }
LEDLIGHT_CheckState:
;   lds   L_Flags,rLFlags
;   lds   L_CState,rLCState

   ;If switching to the next state needed
   sbrs  L_Flags,LNF
   rjmp  LLCS_NoSwitch
   ;Current state == New state -> No switching needed
   cp    L_CState,L_NState
   breq  LLCS_NoSwitch
   ;Load Command Timer with short switch time
;   ldi   L_Temp,3
;   mov   L_CTimer,L_Temp
   ldi   L_CTimer,LL_TIME_SHORT_SWITCH
   
   mov   L_Temp,L_CState
   subi  L_Temp,-$30
   rcall UART_Dbg
   
;   clt
;   bld   L_Flags,LNF
LLCS_NoSwitch:
   ;Clear New state switch flag
   cbr   L_Flags,(1 << LNF)
   ret
;LLCS_NoSwitch:
;   clt
;   bld   L_Flags,LNF
;   cbr   L_Flags,(1 << LNF)
;   ret












;-----------------------------------------------------------------------------------

LEDLIGHT_Init:
   ;LED Light Pin (Input)
   cbi   LEDLPORT,LEDLIGHT
   rcall LEDLIGHT_Release

   ;ldi   Temp,LEDLIGHT_OFF
   ;sts   rLCState,Temp
   clr   Temp
   sts   rLFlags,Temp
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
   ;cpi   Temp,LEDLIGHT_OFF
   ;breq  LDI_End

   ;ldi   L_Temp,LL_STATE_OFF
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
   ;rcall SLEDB_On
   lds   L_Flags,rLFlags
   sbr   L_Flags,(1 << LFF)
   sts   rLFlags,L_Flags
   set
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Process:
   ;Load current state
   lds   L_Flags,rLFlags
   lds   L_BTimer,rLBTimer
   lds   L_CTimer,rLCTimer
   lds   L_CState,rLCState
   lds   L_NState,rLNState

;  @Override
;  public void run()
;  {
;    while(fInWork) 
;    {
;      /* Led Light Button is pressed/IR command is issued */
;      if (fLLBtnFall)
;      {
;        fTimer = 0;
;        fLLBtnFall = false;
;        fOwner.updateLedLightPin(false);
;      }
LLP_CheckBtnFall:
   ;Check if falling edge of LedLight Button detected
   sbrs  L_Flags,LFF
   rjmp  LLP_CheckBtnRise
   ;Start counting how long Button will be held
   clr   L_BTimer
;   clt
;   bld   L_Flags,LFF
   cbr   L_Flags,(1 << LFF)
   
   ;Prepare state for indication
   ldi   Temp,SLEDS_STATE_LEDLIGHT_OFF
   rcall SLEDs_SetState

   rjmp  LLP_CheckIrCmdTimer

;      /* Led Light Button is released/IR command is finished */
;      if (fLLBtnRise)
;      {
;        fTimer += 1;
;        fLLBtnRise = false;
;        
;        log("  * Timeout = %d ms", fTimer * 50);
;        fOwner.updateLedLightPin(true);
;
;        if (fTimer > 60)
;        {
;          toggle();
;        }
;        else
;        {
;          next();
;        }
;        checkstate();
;      }
LLP_CheckBtnRise:
   ;Check if rising edge of LedLight Button detected
   sbrs  L_Flags,LRF
   rjmp  LLP_CheckIrCmdTimer
   ;Check how long the Button was held
   inc   L_BTimer
;   clt
;   bld   L_Flags,LRF
   cbr   L_Flags,(1 << LRF)
   
   ;
;   ldi   L_Temp,61
;   cp    L_BTimer,L_Temp
   ;If Button was held more than 3 s -> Toggle state (OFF->MAX/MAX->OFF)
   cpi   L_BTimer,(LL_TIME_LONG_SWITCH - 1)
   brsh  LLP_CBR_Toggle
LLP_CBR_Next:
   ;Else -> Go to the next state
   rcall LEDLIGHT_Next
   rjmp  LLP_CBR_CheckState
LLP_CBR_Toggle:
   rcall LEDLIGHT_Toggle
LLP_CBR_CheckState:
   ;Check if current state is final state
   rcall LEDLIGHT_CheckState

;      /* Timer for IR Command */
;      if (fCmdTimer > 0)
;      {
;        fCmdTimer--;
;        
;        if (fCmdTimer == 0) fLLBtnRise = true;
;      }
LLP_CheckIrCmdTimer:
   ;Release the Button if IR command was received
   ;And Command Timer expired
   tst   L_CTimer
   breq  LLP_End
   dec   L_CTimer
   tst   L_CTimer
   brne  LLP_End
   rcall LEDLIGHT_Release
   
   mov   L_Temp,L_CState
   subi  L_Temp,-$30
   rcall UART_Dbg

;      fTimer++;
;
;      delay(50);
;    }
;  }
LLP_End:
   inc   L_BTimer
   
   ;Store current state
   sts   rLFlags,L_Flags
   sts   rLBTimer,L_BTimer
   sts   rLCTimer,L_CTimer
   sts   rLCState,L_CState
   sts   rLNState,L_NState

   ret
   
;-----------------------------------------------------------------------------------

LEDLIGHT_IR_Cmd:
;    if (fCurState == LL_STATE_OFF) {
;      fCmdTimer = 65;
;    } else {
;      fCmdTimer = 2;
;    }
;--> Pin Control --> IRQ --> fLLBtnFall = true;
;    fLLNeedNext = false;

;   ldi   L_Temp,LL_STATE_OFF
;   cp    L_CState,L_Temp
   cpi   L_CState,LL_STATE_OFF
   brne  LLIC_TimeoutShort
LLIC_TimeoutLong:
;   ldi   L_Temp,65
   ldi   L_CTimer,(LL_TIME_LONG_SWITCH + 4)
   rjmp  LLIC_TimeoutEnd
LLIC_TimeoutShort:
;   ldi   L_Temp,2
   ldi   L_CTimer,(LL_TIME_SHORT_SWITCH - 1)
LLIC_TimeoutEnd:
;   mov   L_CTimer,L_Temp
;   clt
;   bld   L_Flags,LNF
   cbr   L_Flags,LNF

;    switch(cmd)
;    {
;      case IR_CMD_TOGGLE:
;        fCmdTimer = 65;
;        break;
LLIC_IRToggle:
   cpi   L_ICmd,LL_IR_CMD_TOGGLE
   brne  LLIC_IRNext
;   ldi   L_Temp,65
;   mov   L_CTimer,L_Temp
   ldi   L_CTimer,(LL_TIME_LONG_SWITCH + 4)
   rjmp  LLIC_IREnd
;      case IR_CMD_NEXT:
;        break;
LLIC_IRNext:
   cpi   L_ICmd,LL_IR_CMD_NEXT
   brne  LLIC_IRMin

   rjmp  LLIC_IREnd
;      case IR_CMD_MIN:
;        fNewState = LL_STATE_MIN;
;        fLLNeedNext = true;
;        break;
LLIC_IRMin:
   cpi   L_ICmd,LL_IR_CMD_MIN
   brne  LLIC_IRMid
;   ldi   L_Temp,LL_STATE_MIN
;   mov   L_NState,L_Temp
   ldi   L_NState,LL_STATE_MIN
;   set
;   bld   L_Flags,LNF
   sbr   L_Flags,LNF
   rjmp  LLIC_IREnd
;      case IR_CMD_MID:
;        fNewState = LL_STATE_MID;
;        fLLNeedNext = true;
;        break;
LLIC_IRMid:
   cpi   L_ICmd,LL_IR_CMD_MID
   brne  LLIC_IRMax
;   ldi   L_Temp,LL_STATE_MID
;   mov   L_NState,L_Temp
   ldi   L_NState,LL_STATE_MID
;   set
;   bld   L_Flags,LNF
   sbr   L_Flags,LNF
   rjmp  LLIC_IREnd
;      case IR_CMD_MAX:
;        fNewState = LL_STATE_MAX;
;        fLLNeedNext = true;
;        break;
LLIC_IRMax:
   cpi   L_ICmd,LL_IR_CMD_MAX
   brne  LLIC_IRError
;   ldi   L_Temp,LL_STATE_MAX
;   mov   L_NState,L_Temp
   ldi   L_NState,LL_STATE_MAX
;   set
;   bld   L_Flags,LNF
   sbr   L_Flags,LNF
   rjmp  LLIC_IREnd
;      default:
;        fCmdTimer = 0;
;        fLLBtnFall = false;
;        break;
;    }
LLIC_IRError:
   clr   L_CTimer
LLIC_IREnd:

;    if ((fLLNeedNext) && (fCurState == fNewState))
;    {
;      fCmdTimer = 0;
;      fLLBtnFall = false;
;      fLLNeedNext = false;
;    }
;  }
   sbrs  L_Flags,LNF
   ret
   cpse  L_CState,L_NState
   ret
   clr   L_CTimer
;   clt
;   bld   L_Flags,LNF
   cbr   L_Flags,LNF
   ret
   













;LEDLIGHT_Toggle:
;   lds   Temp,rLLightMode
;LLT_Max:
;LLT_On:
;   cpi   Temp,LEDLIGHT_OFF
   ;brne  LLT_Mid
;   brne  LLT_Off
;   ldi   Temp,LEDLIGHT_MAX
;   sts   rLLightMode,Temp
;   ldi   Temp,STATE_LEDLIGHT_ON
;   rjmp  LLT_End
;LLT_Mid:
;   cpi   Temp,LEDLIGHT_MAX
;   brne  LLT_Min
;   ldi   Temp,LEDLIGHT_MID
;   sts   rLedLightMode,Temp
;   ldi   Temp,STATE_IDLE
;   rjmp  LLT_End
;LLT_Min:
;   cpi   Temp,LEDLIGHT_MID
;   brne  LLT_Flash
;   ldi   Temp,LEDLIGHT_MIN
;   sts   rLedLightMode,Temp
;   ldi   Temp,STATE_IDLE
;   rjmp  LLT_End
;LLT_Flash:
;   cpi   Temp,LEDLIGHT_MIN
;   brne  LLT_Off
;   ldi   Temp,LEDLIGHT_FLASH
;   sts   rLedLightMode,Temp
;   ldi   Temp,STATE_IDLE
;   rjmp  LLT_End
;LLT_Off:
;   cpi   Temp,LEDLIGHT_FLASH
;   brne  LLT_Error
;   ldi   Temp,LEDLIGHT_OFF
;   sts   rLLightMode,Temp
;   ldi   Temp,STATE_LEDLIGHT_OFF
   ;rjmp  LLT_End
;LLT_End:
;   rcall SLEDs_SetState
;   rcall LEDLIGHT_Hold
;LLT_Error:
;   ret

;-----------------------------------------------------------------------------------

;LEDLIGHT_Next:
;   rcall LEDLIGHT_Hold
   ;Delay 75 ms
;   ldi   Temp,3
;   rcall Delay
;   rcall LEDLIGHT_Release
   ;Delay 150 ms
;   ldi   Temp,6
;   rcall Delay
;   ret

;-----------------------------------------------------------------------------------

;LEDLIGHT_Process:
;   lds   Temp,rLLightMode
;   cpi   Temp,LEDLIGHT_OFF
;   brne  LLP_End
;   cpi   Temp,LEDLIGHT_MAX
;   brne  LLP_End

;   lds   Timer,rLLightTimer
;   inc   Timer
;   cpi   Timer,60
;   brne  LLP_SaveTimer
;   rcall LEDLIGHT_Release
;   clr   Timer
;LLP_SaveTimer:
;   sts   rLLightTimer,Timer
;LLP_End:
;   ret

;SLEDs_SetState:
;   in    Port,SLEDPORT
;   com   Temp
;   andi  Temp,0b00000111
;   andi  Port,0b11111000
;   or    Port,Temp
;   out   SLEDPORT,Port
;   ret

;-----------------------------------------------------------------------------------
