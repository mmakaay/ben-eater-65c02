.SCOPE String

.PROC word2dec
    ; Convert word value into decimal representation string.
    ;
    ; In:
    ;   String::word2dec::value = the word value to convert.
    ; Out:
    ;   String::word2dec::decimal = null-terminated string (max 5 digits)
    ;   A = clobbered
    ;   X/Y = preserved

    .segment "ZP"

        value:   .res 2
        decimal: .res 6             ; "65535" max + 1 null byte

    .segment "CODE"

    phx
    phy

    ; Clear the decimal output string.
    lda #0
    sta decimal + 0                 ; Digit 1
    sta decimal + 1                 ; Digit 2
    sta decimal + 2                 ; Digit 3
    sta decimal + 3                 ; Digit 4
    sta decimal + 4                 ; Digit 5
    sta decimal + 5                 ; Terminating null byte

    @next_digit:
        ; Perform divmod(10), giving us last digit + remaining value.
        lda value
        sta Math::word_a
        lda value + 1
        sta Math::word_a + 1
        lda #10
        sta Math::word_b
        lda #00
        sta Math::word_b + 1
        jsr Math::divmod16
 
        lda Math::word_c            ; Get computed remainder
        adc #'0'                    ; Add remainder to ASCII value of "0"
        jsr add_digit_to_decimal    ; And add it to the decimal buffer

        ; Repeat until all base 10 digits have been extracted.
        lda Math::word_a
        ora Math::word_a + 1
        bne @next_digit  ; Branch if the quotient is not yet at zero

    ply
    plx
    rts

    ; Subroutine: add character to the decimal string.
    ; In: A = ASCII character to push
    ; Out: Y clobbered
    add_digit_to_decimal:
        pha
        ldy #4
    @loop:
        dey
        lda decimal,y
        iny
        sta decimal,y
        dey
        bne @loop
        pla
        sta decimal
        rts

.ENDPROC

.ENDSCOPE