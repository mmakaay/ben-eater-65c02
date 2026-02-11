.macro  inc16   addr
    ; Increments a 2 byte word value with 1.
    ;
    ; In:
    ;   addr = address of the low byte
    ; Out:
    ;   addr = value incremented by 1 + carry
    ;   Carry = set when high byte overflows
    clc
    lda     addr
    adc     #1
    sta     addr
    lda     addr+1
    adc     #0
    sta     addr+1
.endmacro

