;*****************[ Local constants ]***********************************************

;Fclk    = 8 000 000 Hz
;Fclkadc = 8 000 000 / 128 = 62 500 Hz (16 us)
;Fadc    = 62 500 / 13 = 4 807,69 Hz (208 us)

;R1      = 510000 Ohm
;R2      = 100000 Ohm
;VBat    = (ADC * 1.1 / 1024) * (R1 + R2) / R2 = 0.006553 * ADC
;VBat    = ADC * 1678 / 256 [mV]
;ADC     = VBat / 0.006553

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

.EQU ADC_COEFFICIENT = 1678

;*****************[ Local variables ]***********************************************

.DEF A_ML     = r0
.DEF A_MH     = r1
.DEF A_VL     = r2
.DEF A_VH     = r3
.DEF A_RN     = r4
.DEF A_RL     = r5
.DEF A_RH     = r6
.DEF A_RO     = r7
;DEF Temp     = r16
;DEF Value    = r16
;DEF Flags    = r17
.DEF A_Mode   = r21
;DEF ValueL   = r24
.DEF A_CL     = r24
;DEF ValueH   = r25
.DEF A_CH     = r25

;*****************[ ADC Init ]******************************************************

ADC_Init:
   clr   Temp
   sts   (rLuminosity + 0),Temp
   sts   (rLuminosity + 1),Temp
   sts   (rBattery + 0),Temp
   sts   (rBattery + 1),Temp

   ;Disable Digital Input Buffers on analog pins
   ldi   Temp,(1<<ADC5D)|(1<<ADC4D)|(1<<ADC3D)|(1<<ADC2D)|(1<<ADC1D)|(1<<ADC0D)
   sts   DIDR0,Temp
   ;Internal 1.1V Reference, Result is right adjusted, Select ADC5 input
   ldi   Temp,(3 << REFS0) | (0 << ADLAR) | (5 << MUX0)
   sts   ADMUX,Temp
   ;Enable ADC, Enable auto trigger, Enable interrupt, Prescaller = 128
   ldi   Temp,(1 << ADEN) | (1 << ADATE) | (1 << ADIE) | (7 << ADPS0)
   sts   ADCSRA,Temp
   clr   Temp
   sts   ADCSRB,Temp
   ;Start Conversion
   lds   Temp,ADCSRA
   sbr   Temp,(1<<ADSC)
   sts   ADCSRA,Temp
   ret

;*****************[ ADC DeInit ]****************************************************

ADC_DeInit:
   clr   Temp
   sts   ADCSRA,Temp
   ret

;*****************[ ADC Conversion Complete ]***************************************

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

;*****************[ ADC Calculate Voltage in mV ]***********************************

ADC_CalcVoltage:
   ;Load conversion coefficient
   ldi   A_CL,Byte1(ADC_COEFFICIENT)
   ldi   A_CH,Byte2(ADC_COEFFICIENT)
   ;Clear for carry operations
   clr   Temp
   ;Multiply MSBs
   mul   A_VH,A_CH
   ;Copy to MSW Result
   mov   A_RH,A_ML
   mov   A_RO,A_MH
   ;Multiply LSBs
   mul   A_VL,A_CL
   ;Copy to LSW Result
   mov   A_RN,A_ML
   mov   A_RL,A_MH
   ;Multiply 1H with 2L
   mul   A_VH,A_CL
   ;Add to Result
   add   A_RL,A_ML
   adc   A_RH,A_MH
   ;Add carry
   adc   A_RO,Temp
   ;Multiply 1L with 2H
   mul   A_VL,A_CH
   ;Add to Result
   add   A_RL,A_ML
   adc   A_RH,A_MH
   adc   A_RO,Temp
   ;Copy to Value
   mov   ValueL,A_RL
   mov   ValueH,A_RH
   ret

;*****************[ ADC Get Battery Voltage in mV ]*********************************

ADC_GetBatteryVoltage:
   lds   A_VL,(rBattery + 0)
   lds   A_VH,(rBattery + 1)
   rjmp  ADC_CalcVoltage

;*****************[ ADC Get Luminosity Voltage in mV ]******************************

ADC_GetLuminosityVoltage:
   lds   A_VL,(rLuminosity + 0)
   lds   A_VH,(rLuminosity + 1)
   rjmp  ADC_CalcVoltage

;***********************************************************************************
