; -----------------------------------------------------------------
; GPIO driver for W65C22 VIA (Versatile Interface Adapter)
;
; Implements GPIO operations using absolute,Y addressing on the
; VIA port registers. Since PORTA = PORTB + 1 and DDRA = DDRB + 1,
; the Y register selects the port:
;
;   Y = 0 -> port B
;   Y = 1 -> port A
;
; -----------------------------------------------------------------

.ifndef BIOS_GPIO_VIA_W65C22_S
BIOS_GPIO_VIA_W65C22_S = 1

.include "bios/bios.s"

.scope DRIVER

.segment "ZEROPAGE"

    tmp_byte: .res 1

.segment "BIOS"

    .proc set_inputs
        ; Set data direction to input for the requested pins.
        ;
        ; In:
        ;   A = pin mask (1 = set to input)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered

        eor #$ff
        and VIA::DDRB_REGISTER,Y
        sta VIA::DDRB_REGISTER,Y
        rts
    .endproc

    .proc set_outputs
        ; Set data direction to output for the requested pins.
        ;
        ; In:
        ;   A = pin mask (1 = set to output)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered

        ora VIA::DDRB_REGISTER,Y
        sta VIA::DDRB_REGISTER,Y
        rts
    .endproc

    .proc set_pins
        ; Set pin values for a selected group of pins.
        ; Pins not selected by the mask are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = update this pin, 0 = preserve)
        ;   X = pin values (desired state for pins to update)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   X = preserved
        ;   Y = preserved

        eor #$ff                    ; Invert mask to get preserve-mask
        and VIA::PORTB_REGISTER,Y   ; A = preserved pin values
        stx tmp_byte                ; Save desired values temporarily
        ora tmp_byte                ; Merge preserved values with desired pin values
        sta VIA::PORTB_REGISTER,Y   ; Write final result
        rts
    .endproc

    .proc turn_on
        ; Turn on (set HIGH) selected pins.
        ; Other pins are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = turn on this pin)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   Y = preserved

        ora VIA::PORTB_REGISTER,Y
        sta VIA::PORTB_REGISTER,Y
        rts
    .endproc

    .proc turn_off
        ; Turn off (set LOW) selected pins.
        ; Other pins are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = turn off this pin)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   Y = preserved

        eor #$ff
        and VIA::PORTB_REGISTER,Y
        sta VIA::PORTB_REGISTER,Y
        rts
    .endproc

    .proc write_port
        ; Write a full byte to the port register.
        ;
        ; In:
        ;   A = byte to write
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = preserved
        ;   Y = preserved

        sta VIA::PORTB_REGISTER,Y
        rts
    .endproc

    .proc read_port
        ; Read a full byte from the port register.
        ;
        ; In:
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = byte read
        ;   Y = preserved

        lda VIA::PORTB_REGISTER,Y
        rts
    .endproc

.endscope

.endif
