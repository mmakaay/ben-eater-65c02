; -----------------------------------------------------------------
; UM6551 ACIA (Asynchronous Communications Interface Adapter)
; -----------------------------------------------------------------

.ifndef BIOS_UART_UM6551_S
BIOS_UART_UM6551_S = 1

.include "bios/bios.s"

.segment "BIOS"

.scope DRIVER

    .scope REG
    ; Registers
    DATA   = __UART_START__ + $0  ; I/O register for bus communication
    STATUS = __UART_START__ + $1  ; Status register
    CMD    = __UART_START__ + $2  ; Command register
    CTRL   = __UART_START__ + $3  ; Control register
    .endscope

    .scope BIT
    ; STATUS register
    IRQ        = %10000000       ; Bit is 1 when interrupt has occurred
    DSR        = %01000000       ; Bit is 0 when Data Set is Ready
    DCD        = %00100000       ; Bit is 0 when Data Carrier is Detected
    TXEMPTY    = %00010000       ; Bit is 1 when Transmitter Data Register is Empty
    RXFULL     = %00001000       ; Bit is 1 when Receiver Data Register is Full
    OVERRUN    = %00000100       ; Bit is 1 when Overrun has occurred
    FRAMINGERR = %00000010       ; Bit is 1 when Framing Error was detected
    PARITYERR  = %00000001       ; Bit is 1 when Parity Error was detected
    SOFT_RESET = %00000000       ; Write to status register to perform a software reset

    ; CMD register

    ; Parity check controls
    PAROFF     = %00000000       ; Parity disabled
    PARODD     = %00100000       ; Odd parity receiver and transmitter
    PAREVEN    = %01000000       ; Even parity receiver and transmitter
    PARMARK    = %10100000       ; Mark parity bit transmitted, parity check disabled
    PARSPACE   = %11100000       ; Space parity bit transmitted, parity check disabled

    ; Receiver echo
    ECHOOFF    = %00000000       ; Echo disabled
    ECHOON     = %00010000       ; Echo enabled (use with TIC0)

    ; Transmitter controls
    TIC0       = %00000000       ; Transmit interrupt = off, RTS = high, transmitter = off
    TIC1       = %00000100       ; Transmit interrupt = on,  RTS = low,  transmitter = on
    TIC2       = %00001000       ; Transmit interrupt = off, RTS = low,  transmitter = on
    TIC3       = %00001100       ; Transmit interrupt = off, RTS = Low,  transmitter = transmit BRK

    ; Receiver interrupt control
    IRQON      = %00000000       ; IRQB enabled (from bit 3 of status register) TODO read how this works
    IRQOFF     = %00000010       ; IRQB disabled

    ; Data terminal ready control
    DTROFF     = %00000000       ; Receiver = off, interrupts = off, DTRB = high
    DTRON      = %00000001       ; Receiver = on, interrupts = on, DTRB = low

    ; CTRL register

    ; Stop Bit Number (SBN)
    STOP1      = %00000000       ; 1 stop bit
    STOP2      = %10000000       ; 2 stop bits, 1.5 for WL5 - parity, 1 for WL8 + parity

    ; Word Length (WL)
    LEN8       = %00000000       ; 8 bits per word
    LEN7       = %00100000       ; 7 bits per word
    LEN6       = %01000000       ; 6 bits per word
    LEN5       = %01100000       ; 5 bits per word

    ; Receiver Clock Source (RCS)
    RCSEXT     = %00000000       ; Use external clock (on RxC, providing a 16x clock input) 
    RCSGEN     = %00010000       ; Use baud rate generator (using 1.8432 MHz crystal on XTAL1/XTAL2)

    ; Selected Baud Rate (SBR)
    BNONE      = %00000000       ; 16x external clock
    B50        = %00000001       ; Baud rate 50
    B75        = %00000010       ; Baud rate 75
    B109       = %00000011       ; Baud rate 109.92
    B134       = %00000100       ; Baud rate 134.58
    B150       = %00000101       ; Baud rate 150
    B300       = %00000110       ; Baud rate 300
    B600       = %00000111       ; Baud rate 600
    B1200      = %00001000       ; Baud rate 1200
    B2400      = %00001010       ; Baud rate 2400
    B3600      = %00001011       ; Baud rate 3600
    B4800      = %00001100       ; Baud rate 4800
    B7200      = %00001101       ; Baud rate 7200
    B9600      = %00001110       ; Baud rate 9600
    B19200     = %00001111       ; Baud rate 19200
    .endscope

    .proc init
        ; Initialize the serial interface: N-8-1, 19200 baud.
        ;
        ; Out:
        ;   A = clobbered
        ;
        jsr soft_reset

        ; Configure:
        ; - data = 8 bits, 1 stopbit
        ; - transmitter baud rate = 19200
        ; - receiver baud rate = using transmitter baud rate generator
        set_byte REG::CTRL, #(BIT::LEN8 | BIT::STOP1 | BIT::B19200 | BIT::RCSGEN)

        ; Configure:
        ; - parity = none
        ; - echo = off
        ; - transmitter = on
        ; - receiver = on
        ; - interrupts = none
        set_byte REG::CMD, #(BIT::PAROFF | BIT::ECHOOFF | BIT::TIC2 | BIT::DTRON | BIT::IRQOFF)

        rts
    .endproc

    .proc soft_reset
        ; Write to status register for soft reset
        ;
        ; Out:
        ;   A = clobbered
        ;
        lda #BIT::SOFT_RESET
        sta REG::STATUS

        ; Wait for soft reset to complete. The UART needs time to finish its
        ; internal reset before CTRL and CMD writes will take effect.
        ldx #$ff
        ldy #$ff
    @wait:
        dey
        bne @wait
        dex
        bne @wait

        rts
    .endproc

    .proc load_status
        ; Load the status bits into register A.
        ;
        ; Out:
        ;   A = status bits (IRQ DSR DCD TXE RXF OVR FRM PAR)
        lda REG::STATUS
        rts
    .endproc

    .proc check_rx
        ; Check if there is a byte in the receiver buffer.
        ;
        ; Usage:
        ;   jsr check_rx
        ;   beq no_data  ; branch if no data available
        ;   ; ... retrieve data from the receiver
        ;
        ; Out:
        ;   A = clobbered
        ;   Z = 0: data available in the receiver (A != 0)
        ;   Z = 1: no data available (A = 0)
        ;
        lda REG::STATUS
        and #BIT::RXFULL
        rts
    .endproc

    .proc check_tx
        ; Check if a byte can be sent to the transmitter.
        ;
        ; Usage:
        ;   jsr check_tx
        ;   beq tx_not_ready  ; branch if transmitter not ready
        ;   ; ... send data to the transmitter
        ;
        ; Out:
        ;   A = clobbered
        ;   Z = 0: transmitter ready for sending data (A != 0)
        ;   Z = 1: send not possible (A = 0)
        ;
        lda REG::STATUS
        and #BIT::TXEMPTY
        rts
    .endproc

    .proc read
        ; Read a byte from the receiver.
        ;
        ; Out:
        ;   A = read byte
        ;
        lda REG::DATA
        rts
    .endproc

    .proc write
        ; Write a byte to the transmitter.
        ;
        ; Out:
        ;   A = preserved
        ;
        sta REG::DATA
        rts
    .endproc

.endscope

.endif

