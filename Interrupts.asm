.CSEG
;ATmega48 Interrupts
.ORG $0000
   rjmp  Reset
.ORG $0001
   reti            ;Int0
.ORG $0002
   reti            ;Int1
.ORG $0003
   reti            ;PCInt0
.ORG $0004
   reti            ;PCInt1
.ORG $0005
   rjmp  LEDLIGHT_Btn ;PCInt2
.ORG $0006
   reti            ;WDT
.ORG $0007
   reti            ;T2 Comp A
.ORG $0008
   reti            ;T2 Comp B
.ORG $0009
   reti            ;T2 Ovf
.ORG $000A
   rjmp  TSOP_Capture ;T1 Capt
.ORG $000B
   reti            ;T1 Comp A
.ORG $000C
   reti            ;T1 Comp B
.ORG $000D
   rjmp  TSOP_Ovf  ;T1 Ovf
.ORG $000E
   reti            ;T0 Comp A
.ORG $000F
   reti            ;T0 Comp B
.ORG $0010
   rjmp  SysTick_Ovf  ;T0 Ovf
.ORG $0011
   reti            ;SPI STC
.ORG $0012
   rjmp  UART_RxC  ;USART Rx
.ORG $0013
   reti            ;USART UDRE
.ORG $0014
   reti            ;USART Tx
.ORG $0015
   rjmp  ADC_Complete ;ADC
.ORG $0016
   reti            ;EE Ready
.ORG $0017
   reti            ;AC
.ORG $0018
   reti            ;TWI
.ORG $0019
   reti            ;SPM Ready
.ORG $0020
