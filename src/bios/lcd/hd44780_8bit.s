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
; -----------------------------------------------------------------

.ifndef BIOS_LCD_HD44780_S
BIOS_LCD_HD44780_S = 1

.include "bios/bios.s"

.scope DRIVER

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
        ; Port A (CMND register) will always be in output mode from here on.
        ; Port B (DATA register) will toggle input/output mode, depending on use.

        ldy #GPIO::PORTA
        lda #PORTA_PINS
        jsr GPIO::set_outputs
        ldy #GPIO::PORTB
        lda #PORTB_PINS
        jsr GPIO::set_outputs

        ; Clear LCD control bits (EN, RW, RS), preserving non-LCD pins.
        ldy #GPIO::PORTA
        lda #PORTA_PINS
        ldx #0
        jsr GPIO::set_pins

        ; Configure an initial display mode.
        jsr wait_till_ready
        lda #%00111000   ; Set 8-bit mode, 2 line display, 5x8 font
        jsr write_instruction
        jsr wait_till_ready
        lda #%00001110   ; Turn display on, cursor on, blink off
        jsr write_instruction
        jsr wait_till_ready
        lda #%00000110   ; Shift cursor on data, no display shift
        jsr write_instruction

        ; Clear the screen.
        jsr clr

        rts
    .endproc

    .proc write_instruction
        ; Write instruction to CMND register.
        ;
        ; In:
        ;   A = instruction byte to write
        ; Out:
        ;   A = clobbered

        ; Put the byte on the LCD data bus.
        ldy #GPIO::PORTB
        jsr GPIO::write_port

        ; Set control pins: RWB=0 (write), RS=0 (CMND), EN=0.
        ldy #GPIO::PORTA
        lda #PORTA_PINS
        ldx #0
        jsr GPIO::set_pins

        ; Pulse EN high then low to trigger data transfer.
        lda #PIN_EN
        jsr GPIO::turn_on          ; Y still PORTA
        lda #PIN_EN
        jsr GPIO::turn_off         ; Y still PORTA
        
        rts
    .endproc

    .proc write
        ; Write byte to DATA register.
        ;
        ; In:
        ;   A = byte to write
        ; Out:
        ;   A = preserved

        pha

        ; Put the byte on the LCD data bus.
        ldy #GPIO::PORTB
        jsr GPIO::write_port
        
        ; Set control pins: RWB=0 (write), RS=1 (DATA), EN=0.
        ldy #GPIO::PORTA
        lda #PORTA_PINS
        ldx #PIN_RS
        jsr GPIO::set_pins

        ; Pulse EN high then low to trigger data transfer.
        lda #PIN_EN
        jsr GPIO::turn_on          ; Y still PORTA
        lda #PIN_EN
        jsr GPIO::turn_off         ; Y still PORTA
        pla

        rts
    .endproc

    .proc check_ready
        ; Poll the LCD to see if it is ready for input.
        ;
        ; Out:
        ;   A = 0 if the LCD is ready for input
        ;   A != 0 if the LCD is busy

        ; Configure port B for input, so we can read the status.
        ldy #GPIO::PORTB
        lda #PORTB_PINS
        jsr GPIO::set_inputs

        ; Set control pins: RWB=1 (read), RS=0 (CMND), EN=0.
        ldy #GPIO::PORTA
        lda #PORTA_PINS
        ldx #PIN_RWB
        jsr GPIO::set_pins

        ; Pulse EN high, read port B, then EN low.
        lda #PIN_EN
        jsr GPIO::turn_on          ; Y still PORTA
        ldy #GPIO::PORTB
        jsr GPIO::read_port        ; A = status byte from the LCD
        pha
        ldy #GPIO::PORTA
        lda #PIN_EN
        jsr GPIO::turn_off
        
        ; Restore port B for output.
        ldy #GPIO::PORTB
        lda #PORTB_PINS
        jsr GPIO::set_outputs

        pla                        ; Fetch the status byte that we read
        and #BUSY_FLAG             ; Strip all bits, except the busy bit

        rts
    .endproc

    .proc wait_till_ready
        ; Wait for the LCD screen to be ready for the next input.

        pha
    @loop:
        jsr check_ready
        bne @loop
        pla
        rts
    .endproc

.endif

.endscope

