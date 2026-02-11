.setcpu "65C02"

; Suppress warnings about segments that are in the breadboard.cfg memory
; layout, but that are not used in this minimal application.
.SEGMENT "ZEROPAGE"
.SEGMENT "BIOS"
.SEGMENT "DATA"
.SEGMENT "VARIABLES"

.SEGMENT "CODE"

    HALT:
        JMP HALT

.SEGMENT "VECTORS"

    .WORD $0000        ; NMI VECTOR
    .WORD HALT         ; RESET VECTOR
    .WORD $0000        ; IRQ VECTOR

