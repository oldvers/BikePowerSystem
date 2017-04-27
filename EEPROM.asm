EEPROM_Write:
   ;�������� ���������� ���������� ������
   sbic  EECR,EEWE
   rjmp  EEPROM_Write    
   ;��������� ������
   ;out   EEARH,EE_AdrH
   out   EEARL,E_Addr
   ;������ ������
   out   EEDR,E_Data
   ;��������� EEMWE
   sbi   EECR,EEMWE
   ;������ ������ (��������� EEWE)
   sbi   EECR,EEWE
   ret


EEPROM_Read:
   ;�������� ���������� ���������� ������
   sbic  EECR,EEWE
   rjmp  EEPROM_Read
   ;��������� ������
   ;out   EEARH,EE_AdrH
   out   EEARL,E_Addr
   ;������ ������ (��������� EERE)
   sbi   EECR,EERE
   ;������ ������
   in    E_Data,EEDR
   ret

