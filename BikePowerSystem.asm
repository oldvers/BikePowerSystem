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
   sbrc  Flags,TF
   rcall SysTick_Process
   sbrc  Flags,SF
   rcall MC_Stop
   rjmp  MainLoop


;***********************************************************************************
;***[ MicroController Start ]*******************************************************
;***********************************************************************************

MC_Start:
   cli

   rcall SLED_Init
   rcall PLED_On

   rcall UART_Init

   rcall ADC_Init

   clr   Timer
   rcall SysTickGears_Init
   ldi   Temp,STATE_POWER_ON
   rcall SLEDs_SetState

   rcall LEDLIGHT_Init

   rcall TSOP_Init

   rcall LEDLIGHT_CheckButtonHeld

   cbr   Flags,(1 << RF)

   sei

   ;Delay 200 ms
   ldi   Temp,8
   rcall Delay

   ser   Temp
   sts   rICmd,Temp
   cbr   Flags,(1 << CF)

   ;Delay 1 s
   ldi   Temp,35
   rcall Delay

   rcall TSOP_CheckStartCommand
   brts  MS_End
   sbr   Flags,(1 << SF)
MS_End:
   ret

;***********************************************************************************
;***[ MicroController Stop ]********************************************************
;***********************************************************************************

MC_Stop:
   cli

   rcall SLED_DeInit

   rcall UART_DeInit

   rcall ADC_DeInit

   rcall SysTickGears_DeInit

   rcall LEDLIGHT_DeInit

   rcall TSOP_DeInit

   ;Delay 300 ms
   ldi   Temp,13
   rcall Delay

   ;Enable External Interrupt 0 (IR in) for Wake Up
   ldi   Temp,(0 << ISC00)
   sts   EICRA,Temp
   ldi   Temp,(1 << INT0)
   out   EIMSK,Temp
   ;Enable External Interrupt 22 (PCINT22/PD6, Led Light) for Wake Up
;   ldi   Temp,(1 << PCIE2)
;   sts   PCICR,Temp
;   ldi   Temp,(1 << PCINT22)
;   sts   PCMSK2,Temp

   sei

   ;Config Sleep Mode to Power-Down and Go to Sleep
   ldi   Temp,(2 << SM0) | (1 << SE)
   out   SMCR,Temp
   sleep
   clr   Temp
   out   SMCR,Temp

   ;Disable External Interrupt 0 for Normal Work
   clr   Temp
   sts   EICRA,Temp
   out   EIMSK,Temp
   ldi   Temp,(1 << INTF0)
   out   EIFR,Temp
   ;Disable External Interrupt 22 for Normal Work
;   clr   Temp
;   sts   PCICR,Temp
;   sts   PCMSK2,Temp
;   ldi   Temp,(1 << PCIF2)
;   sts   PCIFR,Temp

   cbr   Flags,(1 << SF)
   sbr   Flags,(1 << RF)
   ret

;***********************************************************************************
;***[ System Tick Function ]********************************************************
;***********************************************************************************

SysTick_Process:
   rcall SLEDs_Process
   rcall LEDLIGHT_Process
;   lds   T_State,rState
;   cpi   T_State,STATE_IDLE
;   breq  ST_CheckVBat
;   lds   T_Phase,rStatePhase
;   cpi   T_Phase,10
;   brsh  ST_CheckVBat

;   ldi   T_PhasesL,Byte1(rStatePhases)
;   ldi   T_PhasesH,Byte2(rStatePhases)
;   clr   Temp
;   add   T_PhasesL,T_Phase
;   adc   T_PhasesH,Temp
;   ld    T_Value,Y

;   mov   Temp,T_Value
;   swap  Temp
;   lsr   Temp
;   rcall SLEDs_SetState

;   mov   Temp,T_Value
;   andi  Temp,$1F
;   cpi   Temp,0
;   breq  ST_NextPhase
;   dec   Temp
;   andi  T_Value,$E0
;   or    T_Value,Temp
;   st    Y,T_Value
;   rjmp  ST_CheckVBat

;ST_NextPhase:
;   inc   T_Phase
;   sts   rStatePhase,T_Phase
;   cpi   T_Phase,10
;   brne  ST_CheckVBat
;   rcall LEDLIGHT_Release
;   ldi   T_State,STATE_IDLE
;   sts   rState,T_State

;ST_CheckVBat:
;   ;Timer Interval = 12.5 s
;   inc   Timer
;   cpi   Timer,250
;   brne  ST_End
;   clr   Timer
;   rcall ADC_GetBatteryState
;   cpi   Temp,STATE_VBAT_FATAL
;   brne  ST_End
;   rcall SysTick_SetState

;ST_End:
   cbr   Flags,(1 << TF)
   ret


