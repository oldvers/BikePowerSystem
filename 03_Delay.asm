;*****************[ Local Variables ]***********************************************

.DEF Delay0  = r14
.DEF Delay1  = r15

;*****************[ Delay Function by 25 ms ]***************************************

Delay25msX:
   clr   Delay0     ;1
   clr   Delay1     ;1
D_Loop:
   dec   Delay0     ;1
   brne  D_Loop     ;2 -> 3*256 = 768
   dec   Delay1     ;1
   brne  D_Loop     ;2 -> (768 + 3)*256 = 197376 (~24.7 ms for 8 MHz)
   dec   Value      ;1
   brne  D_Loop     ;2 -> (197376 + 3)*Value
   ret
