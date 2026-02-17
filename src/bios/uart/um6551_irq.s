; -----------------------------------------------------------------
; UM6551 ACIA (Asynchronous Communications Interface Adapter)
;
; Drives the ACIA for RS232 serial communication. The ACIA is
; memory-mapped directly on the CPU bus (active-low chip select
; address decoded from the address lines). No GPIO port is involved.
;
; This implementation uses various techniques to make the serial
; connection rock solid:
;
; - IRQ triggering, to make sure the CPU sees bytes as soon as
;   they are ready in the RX buffer
; - Use of a read buffer, to temporarily store incoming bytes
;   when the CPU is too busy with other things to process these
; - Hardware flow control, to signal the other side that it must
;   (temporarily) stop sending data, when the read buffer is
;   filling up.
;
; Bus connection
; --------------
;
;     W65C02 CPU                            UM6551 ACIA
;    ┌──────────┐                          ┌──────────┐
;    │          │                          │          │
;    │  D0-D7   │◄────────────────────────►│ D0-D7    │ data bus
;    │  A0      │─────────────────────────►│ RS0      │ register select
;    │  A1      │─────────────────────────►│ RS1      │ register select
;    │  R/WB    │─────────────────────────►│ R/WB     │ read / write
;    │  PHI2    │─────────────────────────►│ PHI2     │ clock
;    │          │                          │          │
;    │          │                          │          │
;    │  A12-A15 │───── decoder ───────────►│ CS1B     │ chip select
;    │  + clock │           `─────────────►│ CS0      │
;    │          │                          │          │
;    │  IRQB    │◄─────────────────────────│ IRQB     │ interrupt
;    │          │                   n/c────│ RxC      │ ext. clock
;    │          │                          │          │
;    │          │                          │  XTAL    │◄── 1.8432 MHz
;    │          │                          │  TxD/RxD │◄──► RS232
;    │          │                          │          │
;    └──────────┘                          └──────────┘
;
; -----------------------------------------------------------------

.ifndef BIOS_UART_UM6551_IRQ_S
BIOS_UART_UM6551_IRQ_S = 1

.include "bios/bios.s"

.scope DRIVER

.segment "ZEROPAGE"

    write_ptr: .res 1
    read_ptr:  .res 1

.segment "RAM"

    input_buffer: .res $100

.segment "BIOS"

    .include "bios/uart/6551_common.s"

    ; The ZP byte is declared in the HAL (uart.s).
    byte = UART::byte

    .proc init
        push_axy

        jsr _soft_reset

        ; Initialize the input buffer, by syncing up the read and write pointers.
        ; This makes the circular buffer effectively empty.
        lda read_ptr
        sta write_ptr

        ; Setup and enable IRQ handler (for now, directly connected to the CPU).
        cp_address ::BIOS::irq_vector, _irq_handler
        cli

        ; Configure:
        ; - data = 8 bits, 1 stopbit
        ; - transmitter baud rate = according to configuration
        ; - receiver baud rate = using transmitter baud rate generator
        set_byte CTRL_REGISTER, #(LEN8 | STOP1 | USE_BAUD_RATE | RCSGEN)

        ; Configure:
        ; - parity = none
        ; - echo = off
        ; - transmitter = on
        ; - receiver = on
        ; - interrupts = enabled
        set_byte CMD_REGISTER, #(PAROFF | ECHOOFF | TIC2 | DTRON | IRQON)

        pull_axy
        rts
    .endproc

    .proc load_status
        pha
        lda STATUS_REGISTER
        sta byte
        pla
        rts
    .endproc

    check_rx = _get_buffer_size

    .proc read
        pha
        txa
        pha

        ; Read the next character from the input buffer.
        ldx read_ptr
        lda input_buffer,X
        sta byte
        inc read_ptr

        pla
        tax
        pla
        rts    
    .endproc

    .proc check_tx
        pha
        lda STATUS_REGISTER
        and #TXEMPTY
        sta byte
        pla
        rts
    .endproc

    .proc write
        pha
        lda byte
        sta DATA_REGISTER
        pla
        rts
    .endproc

    ; -----------------------------------------------------------------
    ; Internal helpers (not part of the driver API)
    ; -----------------------------------------------------------------

    .proc _irq_handler
        pha
        txa
        pha

        lda DATA_REGISTER   ; Load the byte from the UART DATA register

        ldx write_ptr       ; Store the byte in the input buffer
        sta input_buffer,X
        inc write_ptr

        lda STATUS_REGISTER ; Acknowledge the IRQ by reading from STATUS
        
        pla
        tax
        pla
        rti
    .endproc

    .proc _get_buffer_size
        ; Return the number of bytes that are stored in the buffer.
        ;
        ; byte = number of bytes in the buffer
        ; A, X, Y = preserved

        pha
        lda write_ptr  ; Get the current write pointer
        sec            ; Set carry, as required for clean subtract operation
        sbc read_ptr   ; Subtract the read pointer to get the buffer size
        sta byte

        pla
        rts
    .endproc

.endscope

.endif

