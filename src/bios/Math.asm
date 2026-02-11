.SCOPE Math

.segment "ZP"
    word_a:   .word 0
    word_b:   .word 0
    word_c:   .word 0

.segment "CODE"

.PROC divmod16
    ; Perform divmod operation on a 2 byte word.
    ;
    ; In:
    ;   Math::word_a = the number to divide
    ;   Math::word_b = what to divide by
    ; Out:
    ;   Math::word_a = quotient
    ;   Math::word_c = remainder
    ;   A = clobbered
    ;   X/Y = preserved

    phx
    phy

    ; Initialize the remainder c.
    lda #0
    sta word_c
    sta word_c + 1
    clc
    
    ldx #16

    @divloop:
        ; Bit shift divident and quotient, passing on carry bits as we go.
        ; The first shift into value will also push the active carry bit to the
        ; end of the quotient, where the carry bit represents if the previous divide
        ; by the divisor was possible or not. This way, the quotient builds up
        ; bit by bit during the computations.
        rol word_a                   ; Low byte << 1
        rol word_a + 1               ; High byte << 1
        rol word_c                   ; Low byte << 1
        rol word_c + 1               ; High byte << 1

        ; See if we can subtract the divisor from the bit value that is currently
        ; shifted into the remainder bytes. When remainder < divisor, then the
        ; result will become negative, and the carry bit will be set to 0
        ; (due to borrowing).
        sec                         ; Set carry bit, to detect carry borrow for sbc
        lda word_c                  ; Load low byte of remainder
        sbc word_b                  ; Subtract low byte of divisor -> A
        tay                         ; A -> Y
        lda word_c + 1              ; Load high byte of remainder
        sbc word_b + 1              ; Subtract high byte of divisor -> A

        ; If carry bit is cleared, then division was not possible. We continue
        ; with shifting another bit, to see if that makes a division possible.
        bcc @no_div_possible

        ; Dividing was possible. Like with long tail divisions (on paper), we continue
        ; with the new remainder and the rest of the digits, which in this case can be
        ; accompolished by updating the remainder word with the remainder from the
        ; subtraction from above.
        sty word_c                  ; Update remainder low byte <- Y
        sta word_c + 1              ; Update remainder high byte <- A

    @no_div_possible:
        dex
        bne @divloop                ; Process all 16 bits, before continuing.
   
        rol word_a                  ; Shift last carry bit (representing if the last
        rol word_a + 1              ; division was possible or not) into the quotient.

    ply
    plx
    rts

.ENDPROC

.ENDSCOPE