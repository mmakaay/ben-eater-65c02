.include "../bios/base.asm"
.include "../bios/w65c22s_via.asm"
.include "../bios/lcd_display.asm"

.segment "DATA"

    hello:       .asciiz "Press button!"

.segment "VARIABLES"

    irq_counter: .word   0
    value:       .word   0
    mod10:       .word   0
    decimal:     .byte   0, 0, 0, 0, 0

.segment "CODE"

    reset:
        sei              ; Set interrupts disabled
        ldx #$ff         ; Initialize stack pointer (otherwise it's random)
        txs 

        lda #0           ; Reset the IRQ counter
        sta irq_counter
        sta irq_counter + 1

        lda #0           ; CA1 interrupt on falling edge (bit 0)
        sta PCR
        lda #(IER_SET | IER_CA1) ; Activate interrupts for CA1
        sta IER

        jsr lcd_init
        jsr lcd_clear
        jsr hello_world

        cli              ; Clear interrupts disabled

    @wait_for_button:
        lda irq_counter
        ora irq_counter + 1
        beq @wait_for_button

        jsr lcd_clear

    @loop_irq_counter:
        ; Move number to convert to decimal to ram
        lda irq_counter
        sta value
        lda irq_counter + 1
        sta value + 1

        jsr init_decimal
        jsr lcd_home

    @divide:
        ; Reset mod 10 remainder to 0
        lda #0
        sta mod10
        sta mod10 + 1
        clc

        ldx #16

    @divloop:
        ; Rotate quotient and mod 10 remainder
        rol value
        rol value + 1
        rol mod10
        rol mod10 + 1

        ; A, Y = dividend - divisor
        ; When divident < divisor, then the remainder will have become
        ; negative, and the carry bit will be set to 0 (due to borrowing).
        sec              ; Set carry bit, to detect carry on subtract
        lda mod10        ; Load low byte from mod 10 remainder
        sbc #10          ; Subtract 10 from it
        tay              ; Save low byte in Y
        lda mod10 + 1    ; Load high byte from mod 10 remainder
        sbc #0           ; Subtract zero (seems useless, but can update carry)
        bcc @ignore_result ; Branch if divident < divisor
        sty mod10
        sta mod10 + 1

    @ignore_result:
        dex
        bne @divloop     ; Process all 16 bits
 
        rol value        ; Shift in the last bit of the quotient
        lda mod10        ; The remainder is a 0 - 9 number now
        clc
        adc #'0'         ; Add remainder to ASCII value of "0"
        jsr add_digit_to_decimal ; And add it to the decimal buffer

        ; Repeat until all base 10 digits have been extracted.
        lda value
        ora value + 1
        bne @divide      ; Branch if the dividend is not yet at zero

        jsr print_decimal
        jmp @loop_irq_counter

    halt:
        jmp halt         ; Stop execution


    ; Subroutine: initialize decimal representation string.
    ; Out: A clobbered = 0
    init_decimal:
        lda #0
        sta decimal + 0
        sta decimal + 1
        sta decimal + 2
        sta decimal + 3
        sta decimal + 4
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


    ; Subroutine: print the decimal string
    ; Out: Y clobbered
    print_decimal:
        pha
        ldy #0
    @loop:
        cpy #5
        beq @done
        lda decimal,y
        beq @done
        jsr lcd_send_data
        iny
        bra @loop
    @done:
        pla
        rts


    ; Subroutine: print "Hello, world!" to the LCD.
    hello_world:
        pha
        phx
        ldx #0
    @loop:
        lda hello,x
        beq @done
        jsr lcd_send_data
        inx
        bra @loop
    @done:
        plx
        pla
        rts


    handle_nmi:
        rti


    handle_irq:
        inc irq_counter     ; Increment the IRQ counter
        bne @done           ; Return on no roll-over
        inc irq_counter + 1 ; Roll-over, increment the high byte too
    @done:
        bit PORTA           ; Read PORTA to clear interrupt
        rti


.segment "VECTORS"

     .word handle_nmi       ; NMI vector
     .word reset            ; Reset vector
     .word handle_irq       ; IRQ vector
 
