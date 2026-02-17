; Shared, register-like memory definitions that can be used input and/or
; output for subroutines.

.ifndef STR_S
STR_S = 1

.include "stdlib.s"

.proc str_clr
    ; Clear the ZP::str string.
    ; Out:
    ;   ZP::str = first byte set to 0
    ;   ZP::strlen = 0
    ;   A = clobbered
    lda #0
    sta ZP::str     ; Start byte to 0: making it an ampty null-terminated string
    sta ZP::strlen  ; String length to 0
    rts
.endproc

.proc str_add
    ; Adds a byte at the end of ZP::str.
    ;
    ; In:
    ;   A = the byte to add
    ; Out:
    ;   ZP::str = string with the character added to it
    ;   ZP::strlen = incremented string length
    ;   carry = 0 on success, 1 on fail (buffer overflow, no change done)
    ;   A = clobbered
    ; Out:
    ldy ZP::strlen     ; Protect against buffer overflow
    cpy #ZP::STR_LEN
    bcs @overflow      ; Branch if already at or beyond end of string buffer

    sta ZP::str,y      ; Write byte to end of string
    inc ZP::strlen     ; Increment string length by 1
    iny
    lda #0
    sta ZP::str,y      ; Set new string termination byte at end of string

    rts

    @overflow:
        lda #0
        sta ZP::str    ; Last byte to null for string termination
        sec            ; Set error flag
        rts
.endproc

.endif