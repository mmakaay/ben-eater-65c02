; Constants for the W65C22 VIA (Versatile Interface Adapter)

; Registers
PORTB     = $6000       ; I/O register for port B
PORTA     = $6001       ; I/O register for port A
PORTB_DIR = $6002       ; Data direction for B0 - B7 (0 = intput, 1 = output)
PORTA_DIR = $6003       ; Data direction for A0 - A7 (0 = intput, 1 = output)
PCR       = $600c       ; Peripheral Control Register (configure CA1/2, CB1/2)
IFR       = $600d       ; Interrupt Flag Register (read triggered interrupt)
IER       = $600e       ; Interrupt Enable Register (configure interrupts)

; IER register bits
IER_SET   = %10000000 
IER_CLR   = %00000000  
IER_T1    = %01000000   ; Timer 1
IER_T2    = %00100000   ; Timer 2
IER_CB1   = %00010000  
IER_CB2   = %00001000  
IER_SHR   = %00000100   ; Shift register
IER_CA1   = %00000010   ; Shift register
IER_CA2   = %00000001   ; Shift register
