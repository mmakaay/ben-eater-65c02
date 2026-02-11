.include "../bios/bios.asm"

.segment "DATA"

    hello:       .asciiz "Press button!"

.segment "VARIABLES"

    irq_counter: .word   0

.segment "CODE"

    main:
        lda #0
        sta irq_counter            ; Reset the IRQ counter
        sta irq_counter + 1

        sta PCR                    ; Trigger VIA CA1 interrupt on falling edge
        lda #(IER_SET | IER_CA1)   ; Activate interrupts for CA1
        sta IER

        lda #<handle_irq           ; Configure IRQ handler to use.
        sta Bios::irq_vector
        lda #>handle_irq
        sta Bios::irq_vector + 1

        cli                        ; Enable interrupts

        jsr hello_world

    @wait_for_button:
        lda irq_counter
        ora irq_counter + 1
        beq @wait_for_button

        jsr lcd_clear

    @loop_irq_counter:
        ; Convert the number to a decimal string.
        lda irq_counter
        sta String::word2dec::value
        lda irq_counter + 1
        sta String::word2dec::value + 1
        jsr String::word2dec

        jsr lcd_home
        jsr print_decimal

        jmp @loop_irq_counter


    ; Subroutine: print the decimal string
    ; Out: Y clobbered
    print_decimal:
        pha
        ldy #0
    @loop:
        cpy #5
        beq @done
        lda String::word2dec::decimal,y
        beq @done
        jsr lcd_send_data
        iny
        bra @loop
    @done:
        pla
        rts


    ; Subroutine: print hello message to the LCD.
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


    handle_irq:
        inc irq_counter     ; Increment the IRQ counter
        bne @done           ; Return on no roll-over
        inc irq_counter + 1 ; Roll-over, increment the high byte too
    @done:
        bit PORTA           ; Read PORTA to clear interrupt
        rti

