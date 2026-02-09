.setcpu "65C02"

; Constants for the W65C22S VIA (Versatile Interface Adapter)
PORTB     = $6000
PORTA     = $6001
PORTB_DIR = $6002
PORTA_DIR = $6003

; Constants for the LCD display
LCD_EN    = %10000000  ; Enable bit, toggle to transfer input to LCD
LCD_RW    = %01000000  ; Read / write bit (0 = write, 1 = read)
LCD_CTRL  = %00000000  ; Register Select bit (0 = control)
LCD_DATA  = %00100000  ; Register Select bit (1 = data)


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


    ; Subroutine: initialize the LCD hardware.
    ; Out: A clobbered 
    lcd_init:
        lda #0           ; Clear control bits (EN, RW, RS)
        sta PORTA

        lda #%11111111   ; Set all pins on port B to output (LCD data)
        sta PORTB_DIR
        lda #%11100000   ; Set top 3 pins on port A to output (LCD control)
        sta PORTA_DIR

        lda #%00111000   ; Set 8-bit mode, 2 line display, 5x8 font
        jsr lcd_send_control
        lda #%00001110   ; Turn display on, cursor on, blink off
        jsr lcd_send_control
        lda #%00000110   ; Shift cursor on data, no display shift
        jsr lcd_send_control
        rts


    ; Subroutine: clear the LCD screen.
    ; Out: A clobbered
    lcd_clear:
        lda #%00000001   ; Clear screen, set address to 0
        jsr lcd_send_control
        rts


    ; Subroutine: send a control command to the LCD display.
    ; In: A = command
    ; Out: A clobbered
    lcd_send_control:
        ; Put the command on the LCD inputs.
        sta PORTB
        ; Toggle EN with control register selected to send the command.
        lda #LCD_CTRL
        sta PORTA
        lda #(LCD_CTRL | LCD_EN)
        sta PORTA
        lda #(LCD_CTRL)
        sta PORTA
        rts


    ; Subroutine: send data to the LCD display.
    ; In: A = data
    ; Out: A clobbered
    lcd_send_data:
        ; Put the data on the LCD inputs.
        sta PORTB
        ; Toggle EN with data register selected to send the command.
        lda #LCD_DATA
        sta PORTA        
        lda #(LCD_DATA | LCD_EN)
        sta PORTA        
        lda #LCD_DATA
        sta PORTA
        rts


.segment "DATA"

    hello:
        .asciiz "Hello, world!"


.segment "VECTORS"

    .word $0000          ; NMI vector
    .word reset          ; Reset vector
    .word $0000          ; IRQ vector

