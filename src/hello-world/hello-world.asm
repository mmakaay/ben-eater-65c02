.include "../bios/bios.asm"

; Constants for the W65C22S VIA (Versatile Interface Adapter)
PORTB     = $6000
PORTA     = $6001
PORTB_DIR = $6002
PORTA_DIR = $6003

; Constants for the LCD display
; PORTA
LCD_EN    = %10000000  ; Enable bit, toggle to transfer (LCD E pin = 1)
LCD_READ  = %01000000  ; Read bit (LCD RW pin = 1)
LCD_WRITE = %00000000  ; Write bit (LCD RW pin = 0)
LCD_CMND  = %00000000  ; Select instruction register (LCD RS pin = 0)
LCD_DATA  = %00100000  ; Select data register (LCD RS pin = 1)
; PORTB
LCD_BUSY  = %10000000  ; Busy bit


.segment "CODE"

    reset:
        ldx #$ff         ; Initialize stack pointer (otherwise it's random)
        txs 

        jsr lcd_init
        jsr lcd_clear
        jsr hello_world

    halt:
        jmp halt         ; Stop execution


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


.segment "CODE"

    ; Subroutine: initialize the LCD hardware.
    ; Out: A clobbered 
    lcd_init:
        lda #0           ; Clear control bits (EN, RW, RS)
        sta PORTA

        lda #%11111111   ; Set all pins on port B to output (data bits)
        sta PORTB_DIR
        lda #%11100000   ; Set top 3 pins on port A to output (control bits)
        sta PORTA_DIR

        lda #%00111000   ; Set 8-bit mode, 2 line display, 5x8 font
        jsr lcd_send_instruction
        lda #%00001110   ; Turn display on, cursor on, blink off
        jsr lcd_send_instruction
        lda #%00000110   ; Shift cursor on data, no display shift
        jsr lcd_send_instruction
        rts


    ; Subroutine: clear the LCD screen.
    ; Out: A clobbered
    lcd_clear:
        lda #%00000001   ; Clear screen, set address to 0
        jsr lcd_send_instruction
        rts

    ; Subroutine: send an instruction to the LCD display.
    ; In: A = instruction
    ; Out: A clobbered
    lcd_send_instruction:
        jsr lcd_wait_till_idle

        ; Put the instruction on the LCD inputs.
        sta PORTB

        ; Write to instruction register.
        lda #(LCD_WRITE | LCD_CMND)
        sta PORTA
        lda #(LCD_WRITE | LCD_CMND | LCD_EN)
        sta PORTA
        lda #(LCD_WRITE | LCD_CMND)
        sta PORTA
        rts


    ; Subroutine: send data to the LCD display.
    ; In: A = data
    ; Out: A clobbered
    lcd_send_data:
        jsr lcd_wait_till_idle

        ; Put the data on the LCD inputs.
        sta PORTB

        ; Write to data register.
        lda #(LCD_WRITE | LCD_DATA)
        sta PORTA        
        lda #(LCD_WRITE | LCD_DATA | LCD_EN)
        sta PORTA        
        lda #(LCD_WRITE | LCD_DATA)
        sta PORTA
        rts


    ; Subroutine: wait for the LCD screen to not be busy.
    lcd_wait_till_idle:
        pha
        lda #%00000000   ; Configure port B for input
        sta PORTB_DIR

    @loop:
        lda #(LCD_READ | LCD_CMND)
        sta PORTA
        lda #(LCD_READ | LCD_CMND | LCD_EN)
        sta PORTA
        lda PORTB        ; Load status information from port B
        and #LCD_BUSY     ; Look only at the LCD busy bit
        bne @loop        ; Wait until busy bit = 0

        lda #(LCD_READ | LCD_CMND) 
        sta PORTA
        lda #%11111111   ; Configure port B for output
        sta PORTB_DIR
        pla
        rts


.segment "VECTORS"

    .word $0000          ; NMI vector
    .word reset          ; Reset vector
    .word $0000          ; IRQ vector

