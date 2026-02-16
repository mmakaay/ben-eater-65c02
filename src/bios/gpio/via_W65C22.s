; -----------------------------------------------------------------
; GPIO driver for W65C22 VIA (Versatile Interface Adapter)
;
; Implements GPIO operations using absolute,Y addressing on the
; VIA port registers. Since PORTA = PORTB + 1 and DDRA = DDRB + 1,
; an internal Y register value selects the port:
;
;   Y = 0 -> port B
;   Y = 1 -> port A
;
; Parameters are passed via zero page variables (GPIO::port,
; GPIO::mask, GPIO::value). All procedures preserve A, X, Y.
;
; -----------------------------------------------------------------

.ifndef BIOS_GPIO_VIA_W65C22_S
BIOS_GPIO_VIA_W65C22_S = 1

.include "bios/bios.s"

.scope DRIVER

.segment "ZEROPAGE"

    port:  .res 1              ; Port selector (GPIO::PORTA or GPIO::PORTB)
    mask:  .res 1              ; Pin mask (meaning depends on procedure)
    value: .res 1              ; Pin values / data byte

.segment "BIOS"

    .proc set_inputs
        ; Set data direction to input for the requested pins.
        ;
        ; In (zero page):
        ;   GPIO::mask = pin mask (1 = set to input)
        ;   GPIO::port = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda mask
        eor #$ff
        and VIA::DDRB_REGISTER,Y
        sta VIA::DDRB_REGISTER,Y

        pla
        tay
        pla
        rts
    .endproc

    .proc set_outputs
        ; Set data direction to output for the requested pins.
        ;
        ; In (zero page):
        ;   GPIO::mask = pin mask (1 = set to output)
        ;   GPIO::port = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda mask
        ora VIA::DDRB_REGISTER,Y
        sta VIA::DDRB_REGISTER,Y

        pla
        tay
        pla
        rts
    .endproc

    .proc set_pins
        ; Set pin values for a selected group of pins.
        ; Pins not selected by the mask are preserved.
        ;
        ; In (zero page):
        ;   GPIO::mask  = pin mask (1 = update this pin, 0 = preserve)
        ;   GPIO::value = pin values (desired state for masked pins)
        ;   GPIO::port  = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda mask
        eor #$ff                    ; Invert mask to get preserve-mask
        and VIA::PORTB_REGISTER,Y   ; A = preserved pin values
        ora value                   ; Merge with desired pin values
        sta VIA::PORTB_REGISTER,Y   ; Write final result

        pla
        tay
        pla
        rts
    .endproc

    .proc turn_on
        ; Turn on (set HIGH) selected pins.
        ; Other pins are preserved.
        ;
        ; In (zero page):
        ;   GPIO::mask = pin mask (1 = turn on this pin)
        ;   GPIO::port = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda mask
        ora VIA::PORTB_REGISTER,Y
        sta VIA::PORTB_REGISTER,Y

        pla
        tay
        pla
        rts
    .endproc

    .proc turn_off
        ; Turn off (set LOW) selected pins.
        ; Other pins are preserved.
        ;
        ; In (zero page):
        ;   GPIO::mask = pin mask (1 = turn off this pin)
        ;   GPIO::port = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda mask
        eor #$ff
        and VIA::PORTB_REGISTER,Y
        sta VIA::PORTB_REGISTER,Y

        pla
        tay
        pla
        rts
    .endproc

    .proc write_port
        ; Write a full byte to the port register.
        ;
        ; In (zero page):
        ;   GPIO::value = byte to write
        ;   GPIO::port  = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda value
        sta VIA::PORTB_REGISTER,Y

        pla
        tay
        pla
        rts
    .endproc

    .proc read_port
        ; Read a full byte from the port register.
        ;
        ; In (zero page):
        ;   GPIO::port = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   GPIO::value = byte read
        ;   A, X, Y preserved

        pha
        tya
        pha

        ldy port
        lda VIA::PORTB_REGISTER,Y
        sta value

        pla
        tay
        pla
        rts
    .endproc

.endscope

.endif
