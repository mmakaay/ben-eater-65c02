.include "bios/bios.s"

.segment "CODE"

    main:
        jsr hello_world
        jsr BIOS::halt

    .PROC hello_world
        pha
        phx
        ldx #0
    @loop:
        lda hello,x
        beq @done
        jsr lcd_send_data
        inx
        bra @loop
    @done:
        plx
        pla
        rts
    .ENDPROC


.segment "DATA"

    hello:
        .asciiz "Hello, world!"

