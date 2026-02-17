; From: Interrupt handling
; ------------------------
;
; Tutorial : https://www.youtube.com/watch?v=oOYA-jsWTmc
; Result   : https://www.youtube.com/watch?v=oOYA-jsWTmc&t=1276
;
; A difference with Ben's code, is that I chose to keep track of the last
; value that was displayed. This way, we can check if the value actually
; changed, before writing it to the LCD.
;
; Another improvement is disabling interrupts curing copying the counter to the
; input for the decimal conversion. Without debouncing (in hardware or software),
; the counter value could change when an interrupt is received right between
; reading the low byte and the high byte of the counter, resulting in strange
; jumps in the displayed decimal value. 
; Not something to worry about, but I noticed the jumps without deboncing and
; with a floating IRQ pin, causing thousands of IRQs per second.

.include "bios/bios.s"
.include "stdlib/fmtdec16.s"

.segment "ZEROPAGE"

counter:      .word 0
last_counter: .word 0

.segment "CODE"

.proc main
    ; Initialize the IRQ counters.
    clr_word counter
    clr_word last_counter
    inc last_counter           ; Make it different, to trigger LCD update at start

    ; Activate interrupts for VIA's CA1 port.
    ; At the time of writing, there is no abstraction layer for this yet,
    ; so here wee only make use of constants as provided by the kernal code
    ; to setup the IRQ pin.
    set_byte IO::IER_REGISTER, #(IO::IER_SET | IO::IER_CA1)
    clr_byte IO::PCR_REGISTER  ; Makes CA1 trigger interrupt on falling edge

    ; Configure and enable the IRQ handler.
    cp_address VECTORS::irq_vector, handle_irq
    cli

@loop_counter:
    ; Copy current counter value into the subroutine input parameter for the
    ; decimal string conversion. Disable interrupts during copy, to prevent
    ; race conditions with the IRQ handler. After copying, interrupts are
    ; enabled again, and the counter can receive updates, while we can
    ; process the copied counter value safely.
    sei
    cp_word ZP::word_a, counter
    cli

    ; Update the LCD display when the counter value has changed.
    lda ZP::word_a
    cmp last_counter
    bne @display_new_value
    lda ZP::word_a + 1
    cmp last_counter + 1
    bne @display_new_value

    ; No change, wait a bit longer.
    jmp @loop_counter

@display_new_value:
    ; Remember the new counter value for next iteration.
    cp_word last_counter, ZP::word_a

    ; Update LCD display.
    jsr fmtdec16            ; Call stdlib routine for converting counter to decimal.
    jsr LCD::home           ; Move the LCD cursor to the home position.
    jsr print_str_reverse   ; Print the converted string to the LCD display.

    ; Loop, to wait for the next interrupt.
    jmp @loop_counter
.endproc

.proc print_str_reverse
    ldy ZP::strlen
@loop:
    cpy #0
    beq @done
    dey
    lda ZP::str,y
    sta LCD::byte
    jsr LCD::write
    jmp @loop
@done:
    rts
.endproc

.proc handle_irq
    push_axy                 ; be a good citizen, and don't clobber registers.

    inc_word counter         ; Increment the IRQ counter.

    ldx #$ff                 ; A crude delay that acts as a software button debounce.
    ldy #$ff
@delay:
    dex
    bne @delay
    dey
    bne @delay

    bit IO::PORTA_REGISTER   ; Read PORTA to clear interrupt.
    
    pull_axy                 ; Restore the registers.
    rti
.endproc