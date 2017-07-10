.INCLUDE "m48def.inc"
.INCLUDE "01_Definitions.asm"
.INCLUDE "02_Interrupts.asm"
.INCLUDE "03_Delay.asm"
.INCLUDE "04_UART.asm"
.INCLUDE "05_WDT.asm"
.INCLUDE "06_StatusIndication.asm"
.INCLUDE "07_ADC.asm"
.INCLUDE "08_SysTickGears.asm"
.INCLUDE "09_TSOP.asm"
.INCLUDE "10_EEPROM.asm"
.INCLUDE "11_LedLight.asm"

;***********************************************************************************
;***[ Main Program ]****************************************************************
;***********************************************************************************

Reset:
   ldi   Temp,Byte1(RAMEND)
   out   SPL,Temp
   ldi   Temp,Byte2(RAMEND)
   out   SPH,Temp
   
   ;Disable Power to TWI
   ldi   Temp,(1 << PRTWI)
   sts   PRR,Temp
   ;Disable Power to AC
   ldi   Temp,(1 << ACD)
   out   ACSR,Temp
   ldi   Temp,(1 << AIN1D) | (1 << AIN0D)
   sts   DIDR1,Temp

   sbr   Flags,(1 << RF)

MainLoop:
   sbrc  Flags,RF
   rcall MC_Start
   sbrc  Flags,UF
   rcall UART_Process
   sbrc  Flags,CF
   rcall TSOP_Process
   sbrc  Flags,SF
   rcall MC_Stop
   sbrs  Flags,TF
   rjmp  MainLoop
   rcall SLEDs_Process
   rcall LEDLIGHT_Process
   cbr   Flags,(1 << TF)
   rjmp  MainLoop

;***********************************************************************************
;***[ MicroController Start ]*******************************************************
;***********************************************************************************

MC_Start:
   cbr   Flags,(1 << RF)

   ;Init LEDs
   rcall SLED_Init
   rcall PLED_On
   
   ;Init System Tick and Gear LEDs
   rcall SysTickGears_Init

   ;Init Led Light Button
   rcall LEDLIGHT_Init

   ;Init IR Receiver
   rcall TSOP_Init

   sei

   ;--- Check if WakeUp was on LedLight Button ---
   rcall LEDLIGHT_CheckButtonHeld
   brts  MC_Start_Continue

   ;--- Check if WakeUp was on IR Command ---
   rcall TSOP_CheckStartCommand
   brts  MC_Start_Continue

   ;--- Go Back to Sleep ---
   ;Disable Interrupts
   cli
   ;Clear all flags except Stop Flag
   ldi   Flags,(1 << SF)
   ret

MC_Start_Continue:
   ;Indicate Power On State
   ldi   Value,SLEDS_STATE_IDLE
   rcall SLEDs_SetState
   ldi   Value,SLEDS_COLOR_GREEN
   rcall SLEDs_Switch

   ;Init UART
   rcall UART_Init

   ;Init ADC
   rcall ADC_Init

   ret

;***********************************************************************************
;***[ MicroController Stop ]********************************************************
;***********************************************************************************

MC_Stop:
   ;Indicate Go To Sleep State
   ldi   Value,SLEDS_STATE_IDLE
   rcall SLEDs_SetState
   ldi   Value,SLEDS_COLOR_RED
   rcall SLEDs_Switch

   rcall UART_DeInit

   rcall ADC_DeInit

   rcall SysTickGears_DeInit

   rcall LEDLIGHT_DeInit

   rcall TSOP_DeInit

   ;Delay 325 ms
   ldi   Value,13
   rcall Delay25msX

   rcall PLED_Off
   rcall SLED_DeInit

   ;Enable External Interrupt 0 (IR in) for Wake Up
   ldi   Temp,(0 << ISC00)
   sts   EICRA,Temp
   ldi   Temp,(1 << INT0)
   out   EIMSK,Temp
   ;Enable External Interrupt 22 (PCINT22/PD6, Led Light) for Wake Up
   ;ldi   Temp,(1 << PCIE2)
   ;sts   PCICR,Temp
   ;ldi   Temp,(1 << PCINT22)
   ;sts   PCMSK2,Temp

   sei

   ;Config Sleep Mode to Power-Down and Go to Sleep
   ldi   Temp,(2 << SM0) | (1 << SE)
   out   SMCR,Temp
   sleep
   clr   Temp
   out   SMCR,Temp

   ;Disable External Interrupt 0 for Normal Work
   cli
   clr   Temp
   sts   EICRA,Temp
   out   EIMSK,Temp
   ldi   Temp,(1 << INTF0)
   out   EIFR,Temp
   ;Disable External Interrupt 22 for Normal Work
   ;clr   Temp
   ;sts   PCICR,Temp
   ;sts   PCMSK2,Temp
   ;ldi   Temp,(1 << PCIF2)
   ;sts   PCIFR,Temp

   cbr   Flags,(1 << SF)
   sbr   Flags,(1 << RF)
   ret

;***********************************************************************************
