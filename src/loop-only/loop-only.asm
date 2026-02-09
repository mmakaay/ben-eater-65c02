.setcpu "65C02"

.segment "CODE"

    reset:

    halt:
        jmp halt

.segment "VECTORS"

    .word $0000        ; NMI vector
    .word reset        ; Reset vector
    .word $0000        ; IRQ vector

