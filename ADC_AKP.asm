ADC_On:
  ser   Temp
  cbr   Temp,(1<<PC1)|(1<<PC0)
  out   DDRC,Temp

  ldi   Temp,(0<<REFS0)|(0<<ADLAR)|(0)
  sts   ADMUX,Temp
  ldi   Temp,(1<<ADEN)|(1<<ADATE)|(1<<ADIE)|(3<<ADPS0);(3<<ADPS0) 
  sts   ADCSRA,Temp  
   
  lds   Temp,ADCSRA
  sbr   Temp,(1<<ADSC)
  sts   ADCSRA,Temp
  ret

;********************************************************************************   
;  Вырубить АЦП
;********************************************************************************
ADC_Off:
  clr   Temp
  sts   ADCSRA,Temp
  sts   ADMUX,Temp
  ret

;********************************************************************************   
;  Обработка прерывания АЦП
;********************************************************************************
SetADC:
  ldi   Temp,(1<<ADEN)|(1<<ADSC)|(1<<ADATE)|(1<<ADIE)|(4<<ADPS0) ;(7<<ADPS0) 
  sts   ADCSRA,Temp
  ret

SetUB:
  ldi   Temp,(0<<REFS0)|(0<<ADLAR)|(1)
  sts   ADMUX,Temp
  ret

SetUT:
  ldi   Temp,(0<<REFS0)|(0<<ADLAR)|(0)
  sts   ADMUX,Temp
  ret


ADC_Complete:
  push  XL
  push  XH
  push  YL
  push  YH
  push  ZL
  push  ZH
  push  Temp
  in    Temp,SREG
  push  Temp
  push  Flags

Divide_Fdiskret:
  lds   ADC_DatL,ADCL
  lds   ADC_DatH,ADCH

  lds   cL,ADCCnt
  lds   cH,ADCCnt+1
  sbiw  cL,1
  sts   ADCCnt,cL
  sts   ADCCnt+1,cH
  brne  ADC_End
  ldi   Temp,Low(300)
  sts   ADCCnt,Temp
  ldi   Temp,High(300)
  sts   ADCCnt+1,Temp

  lds   Flags,GFlags
  sbrc  Flags,FF
  rcall SetADC

  sbrc  Flags,UF
  rjmp  U_UB
U_UT:
  sbr   Flags,(1<<UF)
  rcall SetUB

  lds   ADC_AdrL,(UT_Buf+Adr)
  lds   ADC_AdrH,(UT_Buf+Adr+1)
  st    X+,ADC_DatL
  st    X+,ADC_DatH
  sts   (UT_Buf+Adr),ADC_AdrL
  sts   (UT_Buf+Adr+1),ADC_AdrH
  ldi   cL,Low(UT_Buf+BufEnd)
  ldi   cH,High(UT_Buf+BufEnd)
  cp    ADC_AdrL,cL
  cpc   ADC_AdrH,cH
  brne  ADC_Pre_End
  
  sbr   Flags,(1<<CF)
  ldi   Temp,Low(UT_Buf+BufBeg)
  sts   (UT_Buf+Adr),Temp
  ldi   Temp,High(UT_Buf+BufBeg)
  sts   (UT_Buf+Adr+1),Temp
  rjmp  ADC_Pre_End
U_UB:
  cbr   Flags,(1<<UF)
  rcall SetUT

  lds   ADC_AdrL,(UB_Buf+Adr)
  lds   ADC_AdrH,(UB_Buf+Adr+1)
  st    X+,ADC_DatL
  st    X+,ADC_DatH
  sts   (UB_Buf+Adr),ADC_AdrL
  sts   (UB_Buf+Adr+1),ADC_AdrH
  ldi   cL,Low(UB_Buf+BufEnd)
  ldi   cH,High(UB_Buf+BufEnd)
  cp    ADC_AdrL,cL
  cpc   ADC_AdrH,cH
  brne  ADC_Pre_End 

  sbr   Flags,(1<<CF)
  ldi   Temp,Low(UB_Buf+BufBeg)
  sts   (UB_Buf+Adr),Temp
  ldi   Temp,High(UB_Buf+BufBeg)
  sts   (UB_Buf+Adr+1),Temp

ADC_Pre_End:
  sts   GFlags,Flags
    
ADC_End:
  pop   Flags
  pop   Temp
  out   SREG,Temp
  pop   Temp
  pop   ZH
  pop   ZL
  pop   YH
  pop   YL
  pop   XH
  pop   XL
  reti

;********************************************************************************   
;  Инициализация АЦП
;********************************************************************************
Init_ADC:
  ldi   Temp,Low(300)
  sts   ADCCnt,Temp
  ldi   Temp,High(300)
  sts   ADCCnt+1,Temp
  ldi   Temp,Low(UB_Buf+BufBeg)
  sts   (UB_Buf+Adr),Temp
  ldi   Temp,High(UB_Buf+BufBeg)
  sts   (UB_Buf+Adr+1),Temp
  ldi   Temp,Low(UT_Buf+BufBeg)
  sts   (UT_Buf+Adr),Temp
  ldi   Temp,High(UT_Buf+BufBeg)
  sts   (UT_Buf+Adr+1),Temp
  rcall ADC_On
  ret

;********************************************************************************   
;  Инициализация буфера АЦП
;********************************************************************************
;Buff_Init:
  ;ldi   ZL,Low(Buffer)
  ;ldi   ZH,High(Buffer)
  ;sts   PBuf,ZL
  ;sts   PBuf+1,ZH
;  ret
