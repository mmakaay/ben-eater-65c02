; -----------------------------------------------------------------
; UART HAL for RS232 serial communication
;
; Parameters are passed via zero page: UART::byte.
; All procedures preserve A, X, Y.
;
; Configuration
; -------------
; No configuration required. The UART base address is provided
; by the linker via __UART_START__.
;
; -----------------------------------------------------------------

.ifndef BIOS_UART_S
BIOS_UART_S = 1

.include "bios/bios.s"

.scope UART

    ; The start of the UART register space is configured in the
    ; linker configuration. The linker provides the starting
    ; address that is imported here.
    .import __UART_START__

    ; Import the hardware driver.
    .include "bios/uart/um6551.s"

    ; Zero page parameter interface.
    .segment "ZEROPAGE"

    byte: .res 1               ; Input/output byte for read/write

    .segment "BIOS"

    ; -------------------------------------------------------------
    ; Access to the low level driver API
    ; -------------------------------------------------------------

    init = DRIVER::init
        ; Initialize the serial interface: N-8-1, 19200 baud.
        ;
        ; Out:
        ;   A, X, Y preserved

    soft_reset = DRIVER::soft_reset
        ; Perform a soft reset of the UART.
        ;
        ; Out:
        ;   A, X, Y preserved

    check_rx = DRIVER::check_rx
        ; Check if there is a byte in the receiver buffer.
        ;
        ; Out:
        ;   UART::byte = non-zero if data available, zero if not
        ;   A, X, Y preserved

    read = DRIVER::read
        ; Read a byte from the receiver.
        ;
        ; Out:
        ;   UART::byte = received byte
        ;   A, X, Y preserved

    check_tx = DRIVER::check_tx
        ; Check if a byte can be sent to the transmitter.
        ;
        ; Out:
        ;   UART::byte = non-zero if ready, zero if busy
        ;   A, X, Y preserved

    write = DRIVER::write
        ; Write a byte to the transmitter.
        ;
        ; In (zero page):
        ;   UART::byte = byte to write
        ; Out:
        ;   A, X, Y preserved

    load_status = DRIVER::load_status
        ; Load the status register.
        ;
        ; Out:
        ;   UART::byte = status bits (IRQ DSR DCD TXE RXF OVR FRM PAR)
        ;   A, X, Y preserved

    ; -------------------------------------------------------------
    ; High level convenience wrappers.
    ; -------------------------------------------------------------

    .proc read_when_ready
        ; Wait for a byte in the receiver buffer, then read it.
        ;
        ; Out:
        ;   UART::byte = received byte
        ;   A, X, Y preserved

        pha
    @wait_for_rx:
        jsr check_rx
        lda byte
        beq @wait_for_rx
        jsr read
        pla
        rts
    .endproc

    .proc write_when_ready
        ; Wait for transmitter to be ready, then write a byte.
        ;
        ; In (zero page):
        ;   UART::byte = byte to write
        ; Out:
        ;   A, X, Y preserved

        pha
        lda byte               ; Save the data byte
        pha
    @wait_for_tx:
        jsr check_tx
        lda byte
        beq @wait_for_tx
        pla                    ; Restore the data byte
        sta byte
        jsr write
        pla
        rts
    .endproc

    .proc write_crnl_when_ready
        ; Wait for transmitter to be ready, and write CRNL (\r\n).
        ;
        ; Out:
        ;   A, X, Y preserved

        pha
        lda #$0d              ; CR, \r
        sta byte
        jsr write_when_ready
        lda #$0a              ; NL, \n
        sta byte
        jsr write_when_ready
        pla
        rts
    .endproc

.endscope

.endif
