;***********************************************************************************
;***[ ADC ]*************************************************************************
;***********************************************************************************

;Fclk = 8 000 000 Hz
;Fclkadc = 8 000 000 / 128 = 62 500 Hz (16 us)
;Fadc = 62 500 / 13 = 4 807,69 Hz (208 us)

;R1 = 510000
;R2 = 100000
;VBat = (ADC * 1.1 / 1024) * (R1 + R2) / R2 = 0.006553 * ADC
;ADC = VBat / 0.006553

;------------------------------------
; Description |  VBat, V  | ADC
;------------------------------------
; Good        |  4.20     | ---
; Good        |  4.01     | 612
; Normal      |  4.00     | 611
; Normal      |  3.61     | 551
; Low         |  3.60     | 550
; Low         |  3.30     | 503
; Fatal       |  3.29     | 502
; Fatal       |  2.50     | ---

.EQU ADC_VBAT_GOOD_MIN  = 612
.EQU ADC_VBAT_NORM_MIN  = 551
.EQU ADC_VBAT_LOW_MIN   = 503
;EQU ADC_VBAT_FATAL_MAX = 502

;***********************************************************************************
;***[ ADC Init ]********************************************************************
;***********************************************************************************

ADC_Init:
   clr   Temp
   sts   (rLuminosity + 0),Temp
   sts   (rLuminosity + 1),Temp
   sts   (rBattery + 0),Temp
   sts   (rBattery + 1),Temp


   ldi   Temp,(1<<ADC5D)|(1<<ADC4D)|(1<<ADC3D)|(1<<ADC2D)|(1<<ADC1D)|(1<<ADC0D)
   sts   DIDR0,Temp
   ldi   Temp,(3 << REFS0) | (0 << ADLAR) | (5 << MUX0)
   sts   ADMUX,Temp
   ldi   Temp,(1 << ADEN) | (1 << ADATE) | (1 << ADIE) | (7 << ADPS0)
   sts   ADCSRA,Temp
   clr   Temp
   sts   ADCSRB,Temp
   
   lds   Temp,ADCSRA
   sbr   Temp,(1<<ADSC)
   sts   ADCSRA,Temp
   ret

;***********************************************************************************
;***[ ADC DeInit ]******************************************************************
;***********************************************************************************

ADC_DeInit:
   clr   Temp
   sts   ADCSRA,Temp
   ret

;***********************************************************************************
;***[ ADC Conversion Complete ]*****************************************************
;***********************************************************************************

ADC_Complete:
   in    SSREG,SREG
   push  A_Mode
   push  A_VL
   push  A_VH

   lds   A_VL,ADCL
   lds   A_VH,ADCH

   ;Luminosity - ADC6 = 0b0110
   ;Battery    - ADC5 = 0b0101
   lds   A_Mode,ADMUX
   andi  A_Mode,$01
   brne  AC_Luminosity
AC_Battery:
   sts   (rBattery + 0),A_VL
   sts   (rBattery + 1),A_VH
   ldi   A_Mode,(3 << REFS0) | (0 << ADLAR) | (5 << MUX0)
   sts   ADMUX,A_Mode
   rjmp  AC_End
AC_Luminosity:
   sts   (rLuminosity + 0),A_VL
   sts   (rLuminosity + 1),A_VH
   ldi   A_Mode,(3 << REFS0) | (0 << ADLAR) | (6 << MUX0)
   sts   ADMUX,A_Mode

AC_End:
   pop   A_VH
   pop   A_VL
   pop   A_Mode
   out   SREG,SSREG
   reti

;***********************************************************************************
;***[ ADC Get Indication State ]****************************************************
;***********************************************************************************

ADC_GetBatteryState:
   lds   A_VL,(rBattery + 0)
   lds   A_VH,(rBattery + 1)

   ldi   A_ValueL,Byte1(ADC_VBAT_GOOD_MIN)
   ldi   A_ValueH,Byte2(ADC_VBAT_GOOD_MIN)
   cp    A_VL,A_ValueL
   cpc   A_VH,A_ValueH
   brsh  AGBS_Good
   ldi   A_ValueL,Byte1(ADC_VBAT_NORM_MIN)
   ldi   A_ValueH,Byte2(ADC_VBAT_NORM_MIN)
   cp    A_VL,A_ValueL
   cpc   A_VH,A_ValueH
   brsh  AGBS_Norm
   ldi   A_ValueL,Byte1(ADC_VBAT_LOW_MIN)
   ldi   A_ValueH,Byte2(ADC_VBAT_LOW_MIN)
   cp    A_VL,A_ValueL
   cpc   A_VH,A_ValueH
   brsh  AGBS_Low
   ldi   Temp,STATE_VBAT_FATAL
   ret
AGBS_Good:
   ldi   Temp,STATE_VBAT_GOOD
   ret
AGBS_Norm:
   ldi   Temp,STATE_VBAT_NORM
   ret
AGBS_Low:
   ldi   Temp,STATE_VBAT_LOW
   ret
