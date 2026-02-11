.include "../bios/bios.asm"

.segment "CODE"

    main:
        jsr hello_world
        jsr halt

    ; Subroutine: print "Hello, world!" to the LCD.
    hello_world:
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


.segment "DATA"

    hello:
        .asciiz "Hello, world!"

