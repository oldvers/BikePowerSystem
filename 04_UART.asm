;*****************[ Local Constants ]***********************************************

.EQU FOSC = 8000000    ;Hz
.EQU BAUD = 38400      ;Bit/s

.EQU UBRR = ((FOSC/16/BAUD) - 1)

; --- EAST2 Protocol/Commands ---

.EQU  EAST2_START                    = $85
.EQU  EAST2_STOP                     = $21
.EQU  EAST2_DEVICE_ADDRESS           = $02

.EQU  CMD_CONNECT                    = $00
.EQU  CMD_SLED_CONTROL               = $10
.EQU  CMD_GLED_CONTROL               = $11
.EQU  CMD_GET_STATE                  = $12
.EQU  CMD_BOOT_ENTER                 = $F0
.EQU  CMD_DISCONNECT                 = $FF

.EQU  STATUS_SUCCESS                 = $00
.EQU  STATUS_ERROR                   = $02

; --- EAST2 States ---

.EQU EAST2_WAIT_START                = 0
.EQU EAST2_WAIT_SIZEL                = 1
.EQU EAST2_WAIT_SIZEH                = 2
.EQU EAST2_WAIT_DATA                 = 3
.EQU EAST2_WAIT_STOP                 = 4
.EQU EAST2_WAIT_CSL                  = 5
.EQU EAST2_WAIT_CSH                  = 6

;*****************[ Local Variables ]***********************************************

;DEF Temp    = r16
.DEF Mode    = r16
;DEF Flags   = r17
.DEF U_Data  = r21
.DEF U_Addr  = r22
.DEF U_Cmd   = r23
.DEF U_Param = r24
.DEF U_Cnt   = r26
.DEF U_CntL  = r26
.DEF U_CntH  = r27
.DEF U_Reg   = r28
.DEF U_RegL  = r28
.DEF U_RegH  = r29
.DEF U_Ptr   = r28
.DEF U_PtrL  = r28
.DEF U_PtrH  = r29
.DEF U_CS    = r30
.DEF U_CSL   = r30
.DEF U_CSH   = r31

;*****************[ UART Init]******************************************************

UART_Init:
   ;Init RAM variables
   clr   Temp
   sts   (rUCnt + 0),Temp
   sts   (rUCnt + 1),Temp
   sts   (rUPtr + 0),Temp
   sts   (rUPtr + 1),Temp
   sts   (rUCS + 0),Temp
   sts   (rUCS + 1),Temp
   ;Initial state
   ldi   Mode,EAST2_WAIT_START
   sts   rUMode,Mode
   ;Init TX pin
   sbi   UARTDDR,UTX
   ;Init BaudRate
   ldi   Temp,Byte2(UBRR)
   sts   UBRR0H,Temp
   ldi   Temp,Byte1(UBRR)
   sts   UBRR0L,Temp
   ;Clear status
   clr   Temp
   sts   UCSR0A,Temp
   ;Enable Rx/Tx, Enable interrupt on Rx complete
   ldi   Temp,(1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0)|(0<<TXCIE0)
   sts   UCSR0B,Temp
   ;Async mode, no parity, 8 bit, 1 stop
   ldi   Temp,(0<<UMSEL00)|(0<<UPM00)|(0<<USBS0)|(3<<UCSZ00)|(0<<UCPOL0)
   sts   UCSR0C,Temp
   ret

;*****************[ UART DeInit ]***************************************************

UART_DeInit:
   ;DeInit Tx pin
   clr   Temp
   cbi   UARTDDR,UTX
   ;DeInit UART
   clr   Temp
   sts   UCSR0A,Temp
   sts   UCSR0B,Temp
   sts   UCSR0C,Temp
   ret

;*****************[ UART Tx ]*******************************************************

UART_Tx:
   lds   Temp,UCSR0A
   sbr   Temp,(1<<TXC0)
   sts   UCSR0A,Temp
   sts   UDR0,U_Data
UT_Wait:
   lds   Temp,UCSR0A
   sbrs  Temp,TXC0
   rjmp  UT_Wait
   ret

;*****************[ UART Rx ]*******************************************************

UART_Rx:
UR_Wait:
   lds   Temp,UCSR0A
   sbrs  Temp,RXC0
   rjmp  UR_Wait
   lds   U_Data,UDR0
   ret

;*****************[ UART Rx Complete Interrupt ]************************************

UART_RxC:
   in    SSREG,SREG
   push  U_Data
   lds   U_Data,UDR0
   push  Mode
   lds   Mode,rUMode
URC_Start:
   cpi   Mode,EAST2_WAIT_START
   brne  URC_SizeL
   ldi   Temp,EAST2_START
   cpse  U_Data,Temp
   rjmp  URC_Error
   ldi   Mode,EAST2_WAIT_SIZEL
   rjmp  URC_End
URC_SizeL:
   cpi   Mode,EAST2_WAIT_SIZEL
   brne  URC_SizeH
   sts   (rUCnt + 0),U_Data
   sts   (rUSize + 0),U_Data
   ldi   Mode,EAST2_WAIT_SIZEH
   rjmp  URC_End
URC_SizeH:
   cpi   Mode,EAST2_WAIT_SIZEH
   brne  URC_Data
   sts   (rUCnt + 1),U_Data
   sts   (rUSize + 1),U_Data

   push  U_RegL
   push  U_RegH

   ldi   U_RegL,Byte1(rUBuffer)
   ldi   U_RegH,Byte2(rUBuffer)
   sts   (rUPtr + 0),U_RegL
   sts   (rUPtr + 1),U_RegH

   clr   U_Reg
   sts   (rUCS + 0),U_Reg
   sts   (rUCS + 1),U_Reg

   pop   U_RegH
   pop   U_RegL

   ldi   Mode,EAST2_WAIT_DATA
   rjmp  URC_End
URC_Data:
   cpi   Mode,EAST2_WAIT_DATA
   brne  URC_Stop

   push  U_RegL
   push  U_RegH

   lds   U_RegL,(rUPtr + 0)
   lds   U_RegH,(rUPtr + 1)
   st    Y+,U_Data
   sts   (rUPtr + 0),U_RegL
   sts   (rUPtr + 1),U_RegH

   lds   U_RegL,(rUCS + 0)
   lds   U_RegH,(rUCS + 1)
   add   U_RegL,U_Data
   clr   U_Data
   adc   U_RegH,U_Data
   sts   (rUCS + 0),U_RegL
   sts   (rUCS + 1),U_RegH

   lds   U_RegL,(rUCnt + 0)
   lds   U_RegH,(rUCnt + 1)
   sbiw  U_Reg,1
   sts   (rUCnt + 0),U_RegL
   sts   (rUCnt + 1),U_RegH

   pop   U_RegH
   pop   U_RegL
   brne  URC_End

   ldi   Mode,EAST2_WAIT_STOP
   rjmp  URC_End
URC_Stop:
   cpi   Mode,EAST2_WAIT_STOP
   brne  URC_CSL
   cpi   U_Data,EAST2_STOP
   brne  URC_Error
   ldi   Mode,EAST2_WAIT_CSL
   rjmp  URC_End
URC_CSL:
   cpi   Mode,EAST2_WAIT_CSL
   brne  URC_CSH
   lds   Temp,(rUCS + 0)
   cp    U_Data,Temp
   brne  URC_Error
   ldi   Mode,EAST2_WAIT_CSH
   rjmp  URC_End
URC_CSH:
   cpi   Mode,EAST2_WAIT_CSH
   brne  URC_Error
   lds   Temp,(rUCS + 1)
   cp    U_Data,Temp
   brne  URC_Error
   sbr   Flags,(1<<UF)
URC_Error:
   clr   Temp
   sts   (rUCnt + 0),Temp
   sts   (rUCnt + 1),Temp
   ldi   Mode,EAST2_WAIT_START
URC_End:
   sts   rUMode,Mode
   pop   Mode
   pop   U_Data
   out   SREG,SSREG
   reti

;*****************[ UART Process Command ]******************************************

UART_Process:
   ;Init variables
   ldi   U_PtrL,Byte1(rUBuffer)
   ldi   U_PtrH,Byte2(rUBuffer)
   lds   U_CntL,(rUSize + 0)
   lds   U_CntH,(rUSize + 1)
   ld    U_Addr,Y+
   ld    U_Cmd,Y+
   ld    U_Param,Y
   ;Check device address
   cpi   U_Addr,EAST2_DEVICE_ADDRESS
   breq  UCP_Connect
   rjmp  UCP_Error
; --- Connect to Device ---
UCP_Connect:
   cpi   U_Cmd,CMD_CONNECT
   brne  UCP_Enter_Boot
   ;Prepare answer
   ;Version
   ldi   Temp,Byte1(IP_VERSION)
   st    Y+,Temp
   ldi   Temp,Byte2(IP_VERSION)
   st    Y+,Temp
   ;Compilation date
   ldi   Temp,Byte1(IP_PROJECT_DATE)
   st    Y+,Temp
   ldi   Temp,Byte2(IP_PROJECT_DATE)
   st    Y+,Temp
   ldi   Temp,Byte3(IP_PROJECT_DATE)
   st    Y+,Temp
   ldi   Temp,Byte4(IP_PROJECT_DATE)
   st    Y+,Temp
   ;Compilation time
   ldi   Temp,Byte1(IP_PROJECT_TIME)
   st    Y+,Temp
   ldi   Temp,Byte2(IP_PROJECT_TIME)
   st    Y+,Temp
   ldi   Temp,Byte3(IP_PROJECT_TIME)
   st    Y+,Temp
   ldi   Temp,Byte4(IP_PROJECT_TIME)
   st    Y+,Temp
   ;Loading date and time
   ldi   ZL,Byte1(2*LOAD_DATE_TIME)
   ldi   ZH,Byte2(2*LOAD_DATE_TIME)
   ldi   U_Cnt,8
UCPC_Loop:
   lpm   Temp,Z+
   st    Y+,Temp
   dec   U_Cnt
   brne  UCPC_Loop
   ;Prepare answer length
   clr   U_CntH
   ldi   U_CntL,20
   rjmp  UCP_End
; --- Enter to firmware upgrade mode ---
UCP_Enter_Boot:
   cpi   U_Cmd,CMD_BOOT_ENTER
   brne  UCP_Disconnect
   ;Store Key in RAM
   ldi   Temp,Byte1($A55A)
   sts   ($0100),Temp
   ldi   Temp,Byte2($A55A)
   sts   ($0101),Temp
   ;Start WatchDog for reset and enter to Bootloader
   rcall WDT_On
   ;Wait for reset
UCPEB_WaitBoot:
   rjmp  UCPEB_WaitBoot
; --- Disconnect from Device ---
UCP_Disconnect:
   cpi   U_Cmd,CMD_DISCONNECT
   brne  UCP_SLED
   rjmp  UCP_Success
; --- Wrong Command ---
UCP_Error:
   ;Prepare answer length
   clr   U_CntH
   ldi   U_CntL,3
   ;Prepare answer
   ldi   Temp,STATUS_ERROR
   sts   (rUBuffer + 2),Temp
   rjmp  UCP_End
; --- Status LEDs control ---
UCP_SLED:
   ldi   U_Data,CMD_SLED_CONTROL
   cpse  U_Cmd,U_Data
   rjmp  UCP_GLED
   ;Status LED Red
   sbrs  U_Param,0
   rcall SLEDR_Off
   sbrc  U_Param,0
   rcall SLEDR_On
   ;Status LED Green
   sbrs  U_Param,1
   rcall SLEDG_Off
   sbrc  U_Param,1
   rcall SLEDG_On
   ;Status LED Blue
   sbrs  U_Param,2
   rcall SLEDB_Off
   sbrc  U_Param,2
   rcall SLEDB_On
   ;Power LED
   sbrs  U_Param,3
   rcall PLED_Off
   sbrc  U_Param,3
   rcall PLED_On
   rjmp  UCP_Success
; --- Gear LEDs control  ---
UCP_GLED:
   ldi   U_Data,CMD_GLED_CONTROL
   cpse  U_Cmd,U_Data
   rjmp  UCP_State
   ld    Temp,Y+
   rcall GLED1_SetBright
   ld    Temp,Y+
   rcall GLED2_SetBright
   rjmp  UCP_Success
; --- Get Device State ---
UCP_State:
   ldi   U_Data,CMD_GET_STATE
   cpse  U_Cmd,U_Data
   rjmp  UCP_Unknown
   ;Prepare answer length
   clr   U_CntH
   ldi   U_CntL,11
   ;Battery voltage
   rcall ADC_GetBatteryVoltage
   ;lds   Temp,(rBattery + 0)
   ;st    Y+,Temp
   st    Y+,ValueL
   ;lds   Temp,(rBattery + 1)
   ;st    Y+,Temp
   st    Y+,ValueH
   ;Luminosity voltage
   rcall ADC_GetLuminosityVoltage
   ;lds   Temp,(rLuminosity + 0)
   ;st    Y+,Temp
   st    Y+,ValueL
   ;lds   Temp,(rLuminosity + 1)
   ;st    Y+,Temp
   st    Y+,ValueH
   ;The last IR command
   lds   Temp,rIAddr
   st    Y+,Temp
   lds   Temp,rICmd
   st    Y+,Temp
   ;Status LED state
   rcall SLEDs_Capture
   st    Y+,Temp
   ;Gear 1 LED brightness
   in    Temp,OCR0B
   st    Y+,Temp
   ;Gear 2 LED brightness
   lds   Temp,OCR2B
   st    Y+,Temp
   rjmp  UCP_End
; --- Unknown command ---
UCP_Unknown:
   ret
;   ldi   U_Data,CMD_IRIVER_VOLP
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Back
;   rcall iRiver_VolP
;   rjmp  UCP_Success
;UCP_Back:
;   ldi   U_Data,CMD_IRIVER_BACK
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Next
;   rcall iRiver_Back
;   rjmp  UCP_Success
;UCP_Next:
;   ldi   U_Data,CMD_IRIVER_NEXT
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_External
;   rcall iRiver_Next
;   rjmp  UCP_Success
;UCP_External:
;   ldi   U_Data,CMD_PANASONIC_EXTERNAL
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Internal
;   rcall Panasonic_External
;   rjmp  UCP_Success
;UCP_Internal:
;   ldi   U_Data,CMD_PANASONIC_INTERNAL
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Light
;   rcall Panasonic_Internal
;   rjmp  UCP_Success
;UCP_Light:
;   ldi   U_Data,CMD_PANASONIC_LIGHT
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Sleep_On
;   mov   Light,U_Param
;   rcall Panasonic_Light
;   rjmp  UCP_Success
;UCP_Sleep_On:
;   ldi   U_Data,CMD_PANASONIC_SLEEP_ON
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Sleep_Off
;   mov   Light,U_Param
;   rcall Panasonic_Sleep_On
;   rjmp  UCP_Success
;UCP_Sleep_Off:
;   ldi   U_Data,CMD_PANASONIC_SLEEP_OFF
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Motor_On
;   mov   Light,U_Param
;   rcall Panasonic_Sleep_Off
;   rjmp  UCP_Success
;UCP_Motor_On:
;   ldi   U_Data,CMD_PANASONIC_MOTOR_ON
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_Motor_Off
;   mov   Light,U_Param
;   rcall Panasonic_Motor_On
;   rjmp  UCP_Success
;UCP_Motor_Off:
;   ldi   U_Data,CMD_PANASONIC_MOTOR_OFF
;   cpse  U_Cmd,U_Data
;   rjmp  UCP_End
;   mov   Light,U_Param
;   rcall Panasonic_Motor_Off

; --- Prepare success answer ---
UCP_Success:
   ;Prepare answer length
   clr   U_CntH
   ldi   U_CntL,3
   ;Prepare answer
   ldi   Temp,STATUS_SUCCESS
   sts   (rUBuffer + 2),Temp
; --- Send answer ---
UCP_End:
   ;Indicate command processing complete (clear flag)
   cbr   Flags,(1 << UF)
   ;Send prepared answer
   rcall UART_Tx_Answer
   ret

;*****************[ UART Send Answer ]**********************************************

UART_Tx_Answer:
   ;Prepare control sum
   clr   U_CSL
   clr   U_CSH
   ;Load pointer to prepared answer
   ldi   U_PtrL,Byte1(rUBuffer)
   ldi   U_PtrH,Byte2(rUBuffer)
   ;Send start byte
   ldi   U_Data,EAST2_START
   rcall UART_Tx
   ;Send length lower byte
   mov   U_Data,U_CntL
   rcall UART_Tx
   ;Send length higher byte
   mov   U_Data,U_CntH
   rcall UART_Tx

   ;Send prepared answer
UTA_Loop:
   ;Load answer byte
   ld    U_Data,Y+
   ;Calculate control sum
   clr   Temp
   add   U_CSL,U_Data
   adc   U_CSH,Temp
   ;Send answer byte
   rcall UART_Tx
   ;Check answer end
   sbiw  U_CntL,1
   brne  UTA_Loop

   ;Send stop byte
   ldi   U_Data,EAST2_STOP
   rcall UART_Tx

   ;Send control sum lower byte
   mov   U_Data,U_CSL
   rcall UART_Tx
   ;Send control sum higher byte
   mov   U_Data,U_CSH
   rcall UART_Tx
   ret

;***********************************************************************************
