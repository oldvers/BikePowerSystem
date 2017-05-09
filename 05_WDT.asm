;*****************[ WDT On ]********************************************************

WDT_On:
   ;Turn off global interrupt
   ;cli
   ;Reset Watchdog Timer
   wdr
   ;Start timed sequence
   lds   Temp,WDTCSR
   ori   Temp,(1<<WDCE)|(1<<WDE)
   sts   WDTCSR,Temp
   ;-- Got four cycles to set the new values from here -
   ;Set new prescaler(time-out) value = 1024K cycles (~8s)
   ldi   Temp,(1<<WDE) ;|(1<<WDP3)|(1<<WDP0)
   sts   WDTCSR,Temp
   ;-- Finished setting new values, used 2 cycles -
   ;Turn on global interrupt
   ;sei
   ret

;*****************[ WDT Off ]*******************************************************

WDT_Off:
   cli
   ;Reset Watchdog Timer
   wdr
   ;Clear WDRF in MCUSR
   clr   Temp
   out   MCUSR,Temp
   ;Write logical one to WDCE and WDE.
   ;Keep old prescaler setting to prevent unintentional time-out
   lds   Temp,WDTCSR
   ori   Temp,(1<<WDCE)|(1<<WDE)
   sts   WDTCSR,Temp
   ;Turn off WDT
   ldi   Temp,(0<<WDE)
   sts   WDTCSR,Temp
   ret

;***********************************************************************************
