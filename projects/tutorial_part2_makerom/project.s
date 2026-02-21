; From: How do CPUs read machine code?
; ------------------------------------
;
; Tutorial : https://youtu.be/yl8vPW5hydQ
; Result   : https://youtu.be/yl8vPW5hydQ?t=2678
; Code     : https://eater.net/downloads/makerom.py
;
; Note that a very low clockspeed is required to be able to see the
; LEDs blink. At high speeds, the output will just look a bunch
; of active LEDs.

.include "breadbox/kernal.inc"

main:
    SET_BYTE GPIO::port, GPIO::PORTB  ; Select VIA port B
    SET_BYTE GPIO::mask, #$ff         ; Select all pins
    jsr GPIO::set_outputs             ; And make them outputs

@loop:
    SET_BYTE GPIO::value, #$55        ; Use $55 (%01010101)
    jsr GPIO::set_pins                ; to set the pin output values

    SET_BYTE GPIO::value, #$aa        ; Use $aa (%10101010)
    jsr GPIO::set_pins                ; to set the pin output values

    jmp @loop                         ; And repeat

