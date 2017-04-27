GLED_Init:
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
   ldi   Temp,0
   out   OCR0B,Temp

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
   ldi   Temp,0
   sts   OCR2B,Temp

   ret

GLED_DeInit:
   ;Configure Gear LED 1
   in    Temp,GLED1DDR
   andi  Temp,~(1 << GLED1)
   out   GLED1DDR,Temp
   cbi   GLED1PORT,GLED1
   ;  8 MHz / 256 = 31 kHz PWM
   clr   Temp
   out   TCCR0A,Temp
   out   TCCR0B,Temp
   out   OCR0B,Temp

   ;Configure Gear LED 2
   in    Temp,GLED2DDR
   andi  Temp,~(1 << GLED2)
   out   GLED2DDR,Temp
   cbi   GLED2PORT,GLED2
   ;  8 MHz / 256 = 31 kHz PWM
   clr   Temp
   sts   TCCR2A,Temp
   sts   TCCR2B,Temp
   sts   OCR2B,Temp

   ret


GLED1_SetBright:
   out   OCR0B,Temp
   ret

GLED2_SetBright:
   sts   OCR2B,Temp
   ret
