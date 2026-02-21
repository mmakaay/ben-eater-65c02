; -----------------------------------------------------------------
; Common code for IRQ-driven 6551 ACIA drivers
;
; Shared procedures for drivers that use IRQ-driven RX with a
; circular buffer and RTS flow control via a VIA GPIO pin.
;
; This file is included by the IRQ-driven driver files (UM6551,
; W65C51N, and similar) inside their DRIVER scope. The including 
; driver must define the following before including this file:
;
;   Variables (ZEROPAGE):
;     rx_w_ptr, rx_r_ptr, rx_pending, rx_off, status
;
;   Buffers (RAM):
;     rx_buffer
;
;   Constants:
;     RTS_PORT, RTS_PIN, RTS_PORT_REG
;     byte (= UART::byte alias)
;
;   From chip-specific common (via 6551_common.s):
;     RXFULL, STATUS_REGISTER, DATA_REGISTER
; -----------------------------------------------------------------

.ifndef KERNAL_UART_6551_IRQ_S
KERNAL_UART_6551_IRQ_S = 1

.include "breadbox/kernal.s"

.segment "KERNAL"

    ; -----------------------------------------------------------------
    ; Hardware flow control RTS pin.
    ;
    ; Flow control is driven via a VIA GPIO pin (instead of the ACIA's
    ; DTR or RTS pins, which have side effects that make them unusable
    ; for clean flow control). The pin directly drives the RS232 RTS
    ; line: HIGH = stop sending, LOW = send.
    ;
    ; The GPIO HAL is used for init and _turn_rx_on (main thread).
    ; The IRQ handler (_turn_rx_off) uses direct register access to
    ; avoid corrupting GPIO zero-page variables that LCD code may be
    ; using when the IRQ fires.
    ;
    ; The VIA port and pin are configurable via config.inc
    ; (UART_RTS_PORT, UART_RTS_PIN).
    ; Avoid sharing a port with a busy driver (e.g. LCD data bus).
    ; -----------------------------------------------------------------

    RTS_PORT     = ::UART_RTS_PORT
    RTS_PIN      = ::UART_RTS_PIN
    RTS_PORT_REG = IO::PORTB_REGISTER + ::UART_RTS_PORT

    .proc load_status
        pha
        lda status
        sta byte
        pla
        rts
    .endproc

    .proc check_rx
        pha
        lda rx_pending
        sta byte
        pla
        rts
    .endproc

    .proc read
        pha
        txa
        pha

        ; Check if we can read a byte from the input buffer.
        ; The carry flag is used for communicating if a byte could be read.
        clc                  ; carry 0 = flag "no byte was read"
        lda rx_pending       ; Check if there are any pending bytes.
        beq @done            ; No, we're done, leaving carry = 0.

        ; Read the next character from the input buffer.
        ldx rx_r_ptr
        lda rx_buffer,X
        sta byte

        ; Update counters.
        inc rx_r_ptr
        dec rx_pending

        jsr _turn_rx_on_if_buffer_emptying
        sec                  ; carry 1 = flag "byte was read"

    @done:
        pla
        tax
        pla
        rts
    .endproc

    ; -----------------------------------------------------------------
    ; Private code
    ; -----------------------------------------------------------------

    .proc _irq_handler_rx
        ; Handle the RX portion of an IRQ: read incoming byte into
        ; the circular buffer if RXFULL is set.
        ;
        ; Call this from the driver's IRQ handler after reading
        ; STATUS_REGISTER into A and storing it in `status`.
        ;
        ; In:
        ;   A = STATUS_REGISTER value (already read by caller)
        ;
        ; Clobbers: A, X

        and #RXFULL          ; Does the status indicate we can read a byte?
        beq @done            ; No, nothing to do.

        lda DATA_REGISTER    ; Load the byte from the UART DATA register.
        ldx rx_w_ptr         ; Store the byte in the input buffer.
        sta rx_buffer,X
        inc rx_w_ptr         ; Update counters.
        inc rx_pending

        jsr _turn_rx_off_if_buffer_almost_full

    @done:
        rts
    .endproc

    .proc _turn_rx_off_if_buffer_almost_full
        ; Check if the buffer is almost full. If it is, signal the remote side
        ; (via RS232 RTS) to stop sending data.

        lda rx_off           ; RX turned off already? (0 = no, 1 = yes).
        bne @done            ; Yes, no need to check pending buffer size.

        lda rx_pending       ; Buffer almost full?
        cmp #$d0
        bcc @done            ; No, no need to change rx_off state.

        ; The buffer is almost full. Assert RTS HIGH to tell remote to stop.
        lda #1
        sta rx_off
        lda RTS_PORT_REG
        ora #RTS_PIN
        sta RTS_PORT_REG

    @done:
        rts
    .endproc

    .proc _turn_rx_on_if_buffer_emptying
        ; Check if the buffer is emptying. If it is, signal the remote side
        ; (via RS232 RTS) to start sending data.

        lda rx_off           ; RX turned off? (0 = no, 1 = yes).
        beq @done            ; No, no need to check pending buffer size.

        lda rx_pending       ; Buffer empty enough again?
        cmp #$50
        bcs @done            ; No, no need to change rx_off state.

        ; The buffer is emptying. Assert RTS LOW to tell remote to send.
        ; SEI protects the full rx_off + RTS update, so the IRQ handler
        ; cannot re-assert RTS HIGH between clearing rx_off and the
        ; port register write.
        sei
        lda #0
        sta rx_off
        lda RTS_PORT_REG
        and #($FF ^ RTS_PIN)
        sta RTS_PORT_REG
        cli

    @done:
        rts
    .endproc

.endif
