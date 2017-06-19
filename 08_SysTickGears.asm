;*****************[ Local constants ]***********************************************

.EQU TIME_INTERVAL = 3125/2
.EQU DEFAULT_BRIGHTNESS = 15

;*****************[ System Tick/Gear LEDs Init ]************************************

SysTickGears_Init:
   ldi   Temp,DEFAULT_BRIGHTNESS
   sts   rBrightness,Temp

   ;Configure Gear LED 1
   in    Temp,GLED1DDR
   ori   Temp,(1 << GLED1)
   out   GLED1DDR,Temp
   cbi   GLED1PORT,GLED1
   ;  8 MHz / 256 = 31 kHz PWM
   ldi   Temp,(0 << COM0A0) | (3 << COM0B0) | (3 << WGM00)
   out   TCCR0A,Temp
   ldi   Temp,(0 << WGM02) | (1 << CS00)
   out   TCCR0B,Temp
   ldi   Temp,DEFAULT_BRIGHTNESS
   out   OCR0B,Temp
   ;Enable Overflow Interrupt for SysTick
   ldi   Temp,(1 << TOV0)
   sts   TIMSK0,Temp

   ;Configure Gear LED 2
   in    Temp,GLED2DDR
   ori   Temp,(1 << GLED2)
   out   GLED2DDR,Temp
   cbi   GLED2PORT,GLED2
   ;  8 MHz / 256 = 31 kHz PWM
   ldi   Temp,(0 << COM2A0) | (3 << COM2B0) | (3 << WGM20)
   sts   TCCR2A,Temp
   ldi   Temp,(0 << WGM22) | (1 << CS20)
   sts   TCCR2B,Temp
   ldi   Temp,DEFAULT_BRIGHTNESS
   sts   OCR2B,Temp

   ;Store SysTick Interval
   ldi   T_CntL,Byte1(TIME_INTERVAL)
   ldi   T_CntH,Byte2(TIME_INTERVAL)
   sts   (rSysTickCnt + 0),T_CntL
   sts   (rSysTickCnt + 1),T_CntH
   ret

;*****************[ System Tick DeInit ]********************************************

SysTickGears_DeInit:
   ;DeInit Gear LED 1
   in    Temp,GLED1DDR
   andi  Temp,~(1 << GLED1)
   out   GLED1DDR,Temp
   cbi   GLED1PORT,GLED1
   clr   Temp
   out   TCCR0A,Temp
   out   TCCR0B,Temp
   out   OCR0B,Temp
   ;Disable Timer Interrupts
   sts   TIMSK0,Temp

   ;DeInit Gear LED 2
   in    Temp,GLED2DDR
   andi  Temp,~(1 << GLED2)
   out   GLED2DDR,Temp
   cbi   GLED2PORT,GLED2
   clr   Temp
   sts   TCCR2A,Temp
   sts   TCCR2B,Temp
   sts   OCR2B,Temp
   
   ret

;*****************[ System Tick Interrupt ]*****************************************

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

;*****************[ Gear LEDs Brightness Control ]**********************************

GLED1_SetBright:
   out   OCR0B,Temp
   ret

GLED2_SetBright:
   sts   OCR2B,Temp
   ret
