;***********************************************************************************
;***[ System Tick Init ]************************************************************
;***********************************************************************************

.EQU TIME_INTERVAL = 3125/2


SysTick_Init:
   ;*** Analogical to GLED_Init
   ;  8 MHz / 256 = 31 kHz PWM
   ldi   Temp,(0 << COM0A0) | (3 << COM0B0) | (3 << WGM00)
   out   TCCR0A,Temp
   ldi   Temp,(0 << WGM02) | (1 << CS00)
   out   TCCR0B,Temp
   ldi   Temp,0
   out   OCR0B,Temp
   ldi   Temp,(1 << TOV0)
   sts   TIMSK0,Temp

   ldi   T_CntL,Byte1(TIME_INTERVAL)
   ldi   T_CntH,Byte2(TIME_INTERVAL)
   sts   (rSysTickCnt + 0),T_CntL
   sts   (rSysTickCnt + 1),T_CntH
   ret

;***********************************************************************************
;***[ System Tick DeInit ]**********************************************************
;***********************************************************************************

SysTick_DeInit:
   clr   Temp
   out   TCCR0A,Temp
   out   TCCR0B,Temp
   out   OCR0B,Temp
   sts   TIMSK0,Temp
   ret

;***********************************************************************************
;***[ System Tick Interrupt ]*******************************************************
;***********************************************************************************

SysTick_Ovf:
   in    SSREG,SREG
   push  T_CntL
   push  T_CntH

   lds   T_CntL,(rSysTickCnt + 0)
   lds   T_CntH,(rSysTickCnt + 1)
   sbiw  T_CntL,1
   brne  STO_End

   sbr   Flags,(1 << TF)
   ldi   T_CntL,Byte1(TIME_INTERVAL)
   ldi   T_CntH,Byte2(TIME_INTERVAL)

STO_End:
   sts   (rSysTickCnt + 0),T_CntL
   sts   (rSysTickCnt + 1),T_CntH
   pop   T_CntH
   pop   T_CntL
   out   SREG,SSREG
   reti

