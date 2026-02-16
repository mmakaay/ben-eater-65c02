.setcpu "65C02"

; Suppress warnings about segments that are in the breadboard.cfg memory
; layout, but that are not used in this minimal application.
.segment "ZEROPAGE"
.segment "BIOS"
.segment "VARIABLES"

.segment "CODE"

    halt:
        jmp halt

.segment "VECTORS"

    .word $0000        ; NMI VECTOR
    .word halt         ; RESET VECTOR
    .word $0000        ; IRQ VECTOR

