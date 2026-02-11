.setcpu "65C02"

.segment "CODE"

    halt:
        jmp halt

.segment "VECTORS"

    .word $0000        ; NMI vector
    .word halt         ; Reset vector
    .word $0000        ; IRQ vector

