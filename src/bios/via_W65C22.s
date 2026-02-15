; -----------------------------------------------------------------
; W65C22 VIA (Versatile Interface Adapter)
; -----------------------------------------------------------------

.ifndef BIOS_VIA_W65C22_S
BIOS_VIA_W65C22_S = 1

.include "bios/bios.s"

; The start of the VIA register space is configured in the
; linker configuration. The linker provides the starting
; address that is imported here.
.import __VIA_START__

.scope VIA

.segment "BIOS"

    ; Registers
    .scope REG
    PORTB     = __VIA_START__ + $0  ; I/O register for port B
    PORTA     = __VIA_START__ + $1  ; I/O register for port A
    DDRB      = __VIA_START__ + $2  ; Data direction for pins B0 - B7 (bit per pin, 0 = in, 1 = out)
    DDRA      = __VIA_START__ + $3  ; Data direction for pins A0 - A7 (bit per pin, 0 = in, 1 = out)
    PCR       = __VIA_START__ + $c  ; Peripheral Control Register (configure CA1/2, CB1/2)
    IFR       = __VIA_START__ + $d  ; Interrupt Flag Register (read triggered interrupt)
    IER       = __VIA_START__ + $e  ; Interrupt Enable Register (configure interrupts)
    .endscope

    .scope BIT
    ; IER register bits
    IER_SET   = %10000000   
    IER_CLR   = %00000000  
    IER_T1    = %01000000   ; Timer 1
    IER_T2    = %00100000   ; Timer 2
    IER_CB1   = %00010000  
    IER_CB2   = %00001000  
    IER_SHR   = %00000100   ; Shift register
    IER_CA1   = %00000010   ; Shift register
    IER_CA2   = %00000001   ; Shift register

    ; Port pins (can be used for both port A and B)
    P0        = %00000001
    P1        = %00000010
    P2        = %00000100
    P3        = %00001000
    P4        = %00010000
    P5        = %00100000
    P6        = %01000000
    P7        = %10000000
    .endscope

    .proc porta_set_inputs
        ; Set data direction to input for the requested pins on port A. 
        ;
        ; Usage:
        ;   lda #%10000110 ; to enable input on PA1, PA2 and PA7
        ;   lda #(VIA::BIT::P1 | VIA::BIT::P2 | VIA::BIT::P7)  ; equivalent
        ;   jsr porta_set_inputs
        ;
        ; In:
        ;   A = with bits for ports to update set to 1
        ; Output:
        ;   A = clobbered
        ;   Port A = requested pins set to input mode, other ports preserved

        eor #$ff
        and VIA::REG::DDRA
        sta VIA::REG::DDRA
        rts
    .endproc

    .proc porta_set_outputs
        ; Set data direction to output for the requested pins on port A. 
        ;
        ; Usage:
        ;   lda #%00110000 ; to enable output on PA4 and PA5
        ;   lda #(VIA::BIT::P4 | VIA::BIT::P5)  ; equivalent
        ;   jsr porta_set_outputs
        ;
        ; In:
        ;   A = with bits for ports to update set to 1
        ; Output:
        ;   A = clobbered
        ;   Port A = requested pins set to output mode, other ports preserved

        ora VIA::REG::DDRA
        sta VIA::REG::DDRA
        rts
    .endproc

    .proc porta_set_pins
        ; Set pin values on port A for a selected group of pins.
        ; Pins not selected by the mask are preserved.
        ;
        ; Note: the port is written twice. In the intermediate state, all
        ; masked pins are LOW. This is safe for the HD44780 LCD, where
        ; EN is edge-triggered on HIGH->LOW.
        ;
        ; Usage:
        ;   lda #(VIA::BIT::P7 | VIA::BIT::P6 | VIA::BIT::P5)  ; mask: pins to update
        ;   ldx #(VIA::BIT::P7 | VIA::BIT::P5)                  ; values: P7=1, P6=0, P5=1
        ;   jsr VIA::porta_set_pins
        ;
        ; In:
        ;   A = pin mask (1 = update this pin, 0 = preserve)
        ;   X = pin values (desired state for masked pins)
        ; Out:
        ;   A = clobbered
        ;   X = preserved

        eor #$ff            ; Invert mask to get preserve-mask
        and REG::PORTA      ; A = preserved pin values (masked pins cleared)
        sta REG::PORTA      ; Write with masked pins low (intermediate state)
        txa                 ; A = desired pin values
        ora REG::PORTA      ; Merge with preserved values
        sta REG::PORTA      ; Write final result
        rts
    .endproc

    .proc porta_turn_on
        ; Turn on (set HIGH) selected pins on port A.
        ; Other pins are preserved.
        ;
        ; Usage:
        ;   lda #VIA::BIT::P7             ; pin(s) to turn on
        ;   jsr VIA::porta_turn_on
        ;
        ; In:
        ;   A = pin mask (1 = turn on this pin)
        ; Out:
        ;   A = clobbered

        ora REG::PORTA
        sta REG::PORTA
        rts
    .endproc

    .proc porta_turn_off
        ; Turn off (set LOW) selected pins on port A.
        ; Other pins are preserved.
        ;
        ; Usage:
        ;   lda #VIA::BIT::P7             ; pin(s) to turn off
        ;   jsr VIA::porta_turn_off
        ;
        ; In:
        ;   A = pin mask (1 = turn off this pin)
        ; Out:
        ;   A = clobbered

        eor #$ff
        and REG::PORTA
        sta REG::PORTA
        rts
    .endproc

    .proc portb_turn_on
        ; Turn on (set HIGH) selected pins on port B.
        ; Other pins are preserved.
        ;
        ; Usage:
        ;   lda #VIA::BIT::P7             ; pin(s) to turn on
        ;   jsr VIA::portb_turn_on
        ;
        ; In:
        ;   A = pin mask (1 = turn on this pin)
        ; Out:
        ;   A = clobbered

        ora REG::PORTB
        sta REG::PORTB
        rts
    .endproc

    .proc portb_turn_off
        ; Turn off (set LOW) selected pins on port B.
        ; Other pins are preserved.
        ;
        ; Usage:
        ;   lda #VIA::BIT::P7             ; pin(s) to turn off
        ;   jsr VIA::portb_turn_off
        ;
        ; In:
        ;   A = pin mask (1 = turn off this pin)
        ; Out:
        ;   A = clobbered

        eor #$ff
        and REG::PORTB
        sta REG::PORTB
        rts
    .endproc

    .proc portb_set_pins
        ; Set pin values on port B for a selected group of pins.
        ; Pins not selected by the mask are preserved.
        ;
        ; Note: see porta_set_pins for details on intermediate state.
        ;
        ; Usage:
        ;   lda #(VIA::BIT::P7 | VIA::BIT::P6)  ; mask: pins to update
        ;   ldx #VIA::BIT::P7                    ; values: P7=1, P6=0
        ;   jsr VIA::portb_set_pins
        ;
        ; In:
        ;   A = pin mask (1 = update this pin, 0 = preserve)
        ;   X = pin values (desired state for masked pins)
        ; Out:
        ;   A = clobbered
        ;   X = preserved

        eor #$ff            ; Invert mask to get preserve-mask
        and REG::PORTB      ; A = preserved pin values (masked pins cleared)
        sta REG::PORTB      ; Write with masked pins low (intermediate state)
        txa                 ; A = desired pin values
        ora REG::PORTB      ; Merge with preserved values
        sta REG::PORTB      ; Write final result
        rts
    .endproc

    .proc portb_set_inputs
        ; Set data direction to input for the requested pins on port B. 
        ;
        ; Usage:
        ;   lda #%10000110 ; to enable input on PA1, PA2 and PA7
        ;   lda #(VIA::BIT::P1 | VIA::BIT::P2 | VIA::BIT::P7)  ; equivalent
        ;   jsr portb_set_inputs
        ;
        ; In:
        ;   A = with bits for ports to update set to 1
        ; Output:
        ;   A = clobbered
        ;   Port B = requested pins set to input mode, other ports preserved

        eor #$ff
        and VIA::REG::DDRB
        sta VIA::REG::DDRB
        rts
    .endproc

    .proc portb_set_outputs
        ; Set data direction to output for the requested pins on port B. 
        ;
        ; Usage:
        ;   lda #%00110000 ; to enable output on PA4 and PA5
        ;   lda #(VIA::BIT::P4 | VIA::BIT::P5)  ; equivalent
        ;   jsr portb_set_outputs
        ;
        ; In:
        ;   A = with bits for ports to update set to 1
        ; Output:
        ;   A = clobbered
        ;   Port B = requested pins set to output mode, other ports preserved

        ora VIA::REG::DDRB
        sta VIA::REG::DDRB
        rts
    .endproc

.endscope

.endif
