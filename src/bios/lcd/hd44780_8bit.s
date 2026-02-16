; -----------------------------------------------------------------
; HD44780 LCD (8 bit data bus, 2 line display, 5x8 font)
;
; Drives the LCD using an 8 bit data bus connection, with all
; data bus pins connected to GPIO port B, and the control pins
; connected to 3 pins of GPIO port A.
;
;    HD44780 LCD                           GPIO
;    ┌─────────┐                          ┌─────────┐
;    │         │                          │         │
;    │         │                     n/c──┤ PA*     │
;    │  RS     │◄─────────────────────────┤ PA5     │ (PIN_RS)
;    │  RWB    │◄─────────────────────────┤ PA6     │ (PIN_RWB)
;    │  E      │◄─────────────────────────┤ PA7     │ (PIN_EN)
;    │         │                          │         │
;    │  D0     │◄────────────────────────►│ PB0     │
;    │  D1     │◄────────────────────────►│ PB1     │
;    │  D2     │◄────────────────────────►│ PB2     │
;    │  D3     │◄────────────────────────►│ PB3     │
;    │  D4     │◄────────────────────────►│ PB4     │
;    │  D5     │◄────────────────────────►│ PB5     │
;    │  D6     │◄────────────────────────►│ PB6     │
;    │  D7     │◄────────────────────────►│ PB7     │
;    │         │                          │         │
;    └─────────┘                          └─────────┘
;
; Parameters are passed via zero page: LCD::byte.
; All procedures preserve A, X, Y.
;
; -----------------------------------------------------------------

.ifndef BIOS_LCD_HD44780_S
BIOS_LCD_HD44780_S = 1

.include "bios/bios.s"

.scope DRIVER

.segment "ZEROPAGE"

    byte: .res 1               ; Input byte for write / write_instruction

.segment "BIOS"

    ; Pin mapping LCD control pins -> GPIO port A.
    PIN_EN  = GPIO::P7
    PIN_RWB = GPIO::P6
    PIN_RS  = GPIO::P5
    PORTA_PINS = (PIN_EN | PIN_RWB | PIN_RS)

    ; Pin mapping LCD data pins -> GPIO port B.
    PORTB_PINS = %11111111

    .include "bios/lcd/hd44780_common.s"

    .proc init
        ; Initialize all pins connected to the LCD in output mode.
        ;
        ; Port A (CMND register) will always be in output mode from here on.
        ; Port B (DATA register) will toggle input/output mode, depending on use.
        ;
        ; Out:
        ;   A, X, Y preserved

        pha

        ; Set port A control pins to output.
        lda #GPIO::PORTA
        sta GPIO::port
        lda #PORTA_PINS
        sta GPIO::mask
        jsr GPIO::set_outputs

        ; Set port B data pins to output.
        lda #GPIO::PORTB
        sta GPIO::port
        lda #PORTB_PINS
        sta GPIO::mask
        jsr GPIO::set_outputs

        ; Clear LCD control bits (EN, RW, RS), preserving non-LCD pins.
        lda #GPIO::PORTA
        sta GPIO::port
        lda #PORTA_PINS
        sta GPIO::mask
        lda #0
        sta GPIO::value
        jsr GPIO::set_pins

        ; Configure an initial display mode.
        jsr wait_till_ready
        lda #%00111000           ; Set 8-bit mode, 2 line display, 5x8 font
        sta byte
        jsr write_instruction
        jsr wait_till_ready
        lda #%00001110           ; Turn display on, cursor on, blink off
        sta byte
        jsr write_instruction
        jsr wait_till_ready
        lda #%00000110           ; Shift cursor on data, no display shift
        sta byte
        jsr write_instruction

        ; Clear the screen.
        jsr clr

        pla
        rts
    .endproc

    .proc write_instruction
        ; Write instruction to CMND register.
        ;
        ; In (zero page):
        ;   LCD::byte = instruction byte to write
        ; Out:
        ;   A, X, Y preserved

        pha

        ; Put the byte on the LCD data bus.
        lda #GPIO::PORTB
        sta GPIO::port
        lda byte
        sta GPIO::value
        jsr GPIO::write_port

        ; Set control pins: RWB=0 (write), RS=0 (CMND), EN=0.
        lda #GPIO::PORTA
        sta GPIO::port
        lda #PORTA_PINS
        sta GPIO::mask
        lda #0
        sta GPIO::value
        jsr GPIO::set_pins

        ; Pulse EN high then low to trigger data transfer.
        lda #PIN_EN
        sta GPIO::mask
        jsr GPIO::turn_on
        jsr GPIO::turn_off

        pla
        rts
    .endproc

    .proc write
        ; Write byte to DATA register.
        ;
        ; In (zero page):
        ;   LCD::byte = byte to write
        ; Out:
        ;   A, X, Y preserved

        pha

        ; Put the byte on the LCD data bus.
        lda #GPIO::PORTB
        sta GPIO::port
        lda byte
        sta GPIO::value
        jsr GPIO::write_port

        ; Set control pins: RWB=0 (write), RS=1 (DATA), EN=0.
        lda #GPIO::PORTA
        sta GPIO::port
        lda #PORTA_PINS
        sta GPIO::mask
        lda #PIN_RS
        sta GPIO::value
        jsr GPIO::set_pins

        ; Pulse EN high then low to trigger data transfer.
        lda #PIN_EN
        sta GPIO::mask
        jsr GPIO::turn_on
        jsr GPIO::turn_off

        pla
        rts
    .endproc

    .proc check_ready
        ; Poll the LCD to see if it is ready for input.
        ;
        ; Out:
        ;   LCD::byte = 0 if the LCD is ready for input
        ;   LCD::byte != 0 if the LCD is busy
        ;   A, X, Y preserved

        pha

        ; Configure port B for input, so we can read the status.
        lda #GPIO::PORTB
        sta GPIO::port
        lda #PORTB_PINS
        sta GPIO::mask
        jsr GPIO::set_inputs

        ; Set control pins: RWB=1 (read), RS=0 (CMND), EN=0.
        lda #GPIO::PORTA
        sta GPIO::port
        lda #PORTA_PINS
        sta GPIO::mask
        lda #PIN_RWB
        sta GPIO::value
        jsr GPIO::set_pins

        ; Pulse EN high, read port B, then EN low.
        lda #PIN_EN
        sta GPIO::mask
        jsr GPIO::turn_on

        lda #GPIO::PORTB
        sta GPIO::port
        jsr GPIO::read_port        ; GPIO::value = status byte from the LCD

        lda #GPIO::PORTA
        sta GPIO::port
        lda #PIN_EN
        sta GPIO::mask
        jsr GPIO::turn_off

        ; Restore port B for output.
        lda #GPIO::PORTB
        sta GPIO::port
        lda #PORTB_PINS
        sta GPIO::mask
        jsr GPIO::set_outputs

        ; Strip all bits except the busy bit and store in LCD::byte.
        lda GPIO::value
        and #BUSY_FLAG
        sta byte

        pla
        rts
    .endproc

    .proc wait_till_ready
        ; Wait for the LCD screen to be ready for the next input.
        ;
        ; Out:
        ;   A, X, Y preserved

        pha
    @loop:
        jsr check_ready
        lda byte
        bne @loop
        pla
        rts
    .endproc

.endif

.endscope

