;-----------------------------------------------------------------------------------

LEDLIGHT_Hold:
   ;LED Light Pin (Output)
   in    L_Temp,LEDLDDR
   ori   L_Temp,(1 << LEDLIGHT)
   out   LEDLDDR,L_Temp
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Release:
   ;LED Light Pin (Input)
   in    L_Temp,LEDLDDR
   andi  L_Temp,~(1 << LEDLIGHT)
   out   LEDLDDR,L_Temp
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Init:
   ;LED Light Pin (Input)
   cbi   LEDLPORT,LEDLIGHT
   rcall LEDLIGHT_Release

   ;ldi   Temp,LEDLIGHT_OFF
   ;sts   rLLightMode,Temp
   clr   L_Flags
   clr   L_BTimer
   clr   L_CTimer
   clr   L_CState
   clr   L_NState

   ;Enable External Interrupt 22 (PCINT22/PD6, Led Light) for Wake Up
   ldi   L_Temp,(1 << PCIF2)
   sts   PCIFR,L_Temp
   ldi   L_Temp,(1 << PCIE2)
   sts   PCICR,L_Temp
   ldi   L_Temp,(1 << PCINT22)
   sts   PCMSK2,L_Temp

   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_DeInit:
   ;lds   Temp,rLLightMode
   ;cpi   Temp,LEDLIGHT_OFF
   ;breq  LDI_End

   ldi   L_Temp,LL_STATE_OFF
   cp    L_CState,L_Temp
   breq  LDI_End
   rcall LEDLIGHT_Hold
   ;Delay 3000 ms
   ldi   Del50ms,120
   rcall Delay
LDI_End:
   cbi   LEDLPORT,LEDLIGHT
   rcall LEDLIGHT_Release
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Btn:
   ;push  Temp
   in    SSREG,SREG

   nop
   nop
   ;Set T bit in SREG
   set
   ;nop
   sbic  LEDLPIN,LEDLIGHT
   rjmp  LLB_Released
LLB_Held:
   ;rcall SLEDB_On
   ;Load T bit and save it to Flag
   bld   L_Flags,LFF
   rjmp  LLB_End
LLB_Released:
   ;rcall SLEDB_Off
   ;Load T bit and save it to Flag
   bld   L_Flags,LRF
LLB_End:
   out   SREG,SSREG
   ;pop   Temp
   reti

;-----------------------------------------------------------------------------------

LEDLIGHT_CheckButtonHeld:
   sbic  LEDLPIN,LEDLIGHT
   ret
LLCBH_Held:
   rcall SLEDB_On
   reti

;-----------------------------------------------------------------------------------

LEDLIGHT_IR_Cmd:
;    if (fCurState == LL_STATE_OFF) {
;      fCmdTimer = 65;
;    } else {
;      fCmdTimer = 2;
;    }
;--> Pin Control --> IRQ --> fLLBtnFall = true;
;    fLLNeedNext = false;

   ldi   L_Temp,LL_STATE_OFF
   cp    L_CState,L_Temp
   brne  LLIC_TimeoutShort
LLIC_TimeoutLong:
   ldi   L_Temp,65
   rjmp  LLIC_TimeoutEnd
LLIC_TimeoutShort:
   ldi   L_Temp,2
LLIC_TimeoutEnd:
   mov   L_CTimer,L_Temp
   clt
   bld   L_Flags,LNF

;    switch(cmd)
;    {
;      case IR_CMD_TOGGLE:
;        fCmdTimer = 65;
;        break;
LLIC_IRToggle:
   cpi   L_ICmd,LL_IR_CMD_TOGGLE
   brne  LLIC_IRNext
   ldi   L_Temp,65
   mov   L_CTimer,L_Temp
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
   ldi   L_Temp,LL_STATE_MIN
   mov   L_NState,L_Temp
   set
   bld   L_Flags,LNF
   rjmp  LLIC_IREnd
;      case IR_CMD_MID:
;        fNewState = LL_STATE_MID;
;        fLLNeedNext = true;
;        break;
LLIC_IRMid:
   cpi   L_ICmd,LL_IR_CMD_MID
   brne  LLIC_IRMax
   ldi   L_Temp,LL_STATE_MID
   mov   L_NState,L_Temp
   set
   bld   L_Flags,LNF
   rjmp  LLIC_IREnd
;      case IR_CMD_MAX:
;        fNewState = LL_STATE_MAX;
;        fLLNeedNext = true;
;        break;
LLIC_IRMax:
   cpi   L_ICmd,LL_IR_CMD_MAX
   brne  LLIC_IRError
   ldi   L_Temp,LL_STATE_MAX
   mov   L_NState,L_Temp
   set
   bld   L_Flags,LNF
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
   clt
   bld   L_Flags,LNF
   ret
   
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
   ldi   L_Temp,LL_STATE_OFF
   cp    L_CState,L_Temp
   brne  LLT_GoToOff
LLT_GoToMax:
   ldi   L_Temp,LL_STATE_MAX
LLT_GoToOff:
   mov   L_CState,L_Temp
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
   ldi   L_Temp,LL_STATE_OFF
   cpse  L_CState,L_Temp
   rjmp  LLN_Begin
   ret
LLN_Begin:
   inc   L_CState
   ldi   L_Temp,(LL_STATE_FLS + 1)
   cp    L_CState,L_Temp
   brlo  LLN_End
   ldi   L_Temp,LL_STATE_MAX
   mov   L_CState,L_Temp
LLN_End:
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
   sbrs  L_Flags,LNF
   rjmp  LLCS_NoSwitch
   cp    L_CState,L_NState
   breq  LLCS_NoSwitch
   ldi   L_Temp,3
   mov   L_CTimer,L_Temp
   clt
   bld   L_Flags,LNF
   ret
LLCS_NoSwitch:
   clt
   bld   L_Flags,LNF
   ret

;-----------------------------------------------------------------------------------

LEDLIGHT_Process:
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
   sbrs  L_Flags,LFF
   rjmp  LLP_CheckBtnRise
   clr   L_BTimer
   clt
   bld   L_Flags,LFF
   rjmp  LLP_CheckCmdTimer

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
   sbrs  L_Flags,LRF
   rjmp  LLP_CheckCmdTimer
   inc   L_BTimer
   clt
   bld   L_Flags,LRF
   
   ldi   L_Temp,61
   cp    L_BTimer,L_Temp
   brsh  LLP_CBR_Toggle
LLP_CBR_Next:
   rcall LEDLIGHT_Next
   rjmp  LLP_CBR_CheckState
LLP_CBR_Toggle:
   rcall LEDLIGHT_Next
LLP_CBR_CheckState:
   rcall LEDLIGHT_CheckState

;      /* Timer for IR Command */
;      if (fCmdTimer > 0)
;      {
;        fCmdTimer--;
;        
;        if (fCmdTimer == 0) fLLBtnRise = true;
;      }
LLP_CheckCmdTimer:
   tst   L_CTimer
   breq  LLP_End
   dec   L_CTimer
   tst   L_CTimer
   brne  LLP_End
   rcall LEDLIGHT_Release

;      fTimer++;
;
;      delay(50);
;    }
;  }
LLP_End:
   inc   L_BTimer
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
