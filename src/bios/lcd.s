; -----------------------------------------------------------------
; LCD display HAL
;
; Parameters are passed via zero page: LCD::byte.
; All procedures preserve A, X, Y.
;
; Configuration
; -------------
; Define these constants before including bios.s to override defaults.
;
;   LCD_MODE      = 4 or 8 (default: 8)
;   LCD_CMND_PORT = GPIO port for control pins (0=PORTB, 1=PORTA)
;   LCD_DATA_PORT = GPIO port for data pins (0=PORTB, 1=PORTA)
;   LCD_PIN_RS    = pin bitmask for Register Select
;   LCD_PIN_RWB   = pin bitmask for Read/Write
;   LCD_PIN_EN    = pin bitmask for Enable
;
; Each driver provides its own defaults. See hd44780_4bit.s and
; hd44780_8bit.s for the default pin layouts.
;
; -----------------------------------------------------------------

.ifndef BIOS_LCD_S
BIOS_LCD_S = 1

.include "bios/bios.s"

; Select the hardware driver.
.ifndef LCD_MODE
    LCD_MODE = 8
.endif

.if LCD_MODE - 8 = 0
    LCD_DRIVER_8BIT = 1
.elseif LCD_MODE - 4 = 0
    LCD_DRIVER_4BIT = 1
.else
    .error "LCD_MODE must be 4 or 8"
.endif

.scope LCD

    .ifdef LCD_DRIVER_8BIT
        .include "bios/lcd/hd44780_8bit.s"
    .else
        .include "bios/lcd/hd44780_4bit.s"
    .endif

    ; Zero page parameter interface.
    byte = DRIVER::byte

    ; -------------------------------------------------------------
    ; Access to the low level driver API
    ; -------------------------------------------------------------

    init = DRIVER::init
        ; Initialize the LCD hardware.
        ;
        ; Out:
        ;   A, X, Y preserved

    check_ready = DRIVER::check_ready
        ; Poll the LCD to see if it is ready for input.
        ;
        ; Out:
        ;   LCD::byte = 0 if the LCD is ready for input
        ;   LCD::byte != 0 if the LCD is busy
        ;   A, X, Y preserved

    write_instruction = DRIVER::write_instruction
        ; Write instruction to CMND register.
        ;
        ; In (zero page):
        ;   LCD::byte = instruction byte to write
        ; Out:
        ;   A, X, Y preserved

    write = DRIVER::write
        ; Write byte to DATA register.
        ;
        ; In (zero page):
        ;   LCD::byte = byte to write
        ; Out:
        ;   A, X, Y preserved

    clr = DRIVER::clr
        ; Clear the LCD screen (waits for ready).
        ;
        ; Out:
        ;   A, X, Y preserved

    home = DRIVER::home
        ; Move LCD output position to home (waits for ready).
        ;
        ; Out:
        ;   A, X, Y preserved

    ; -------------------------------------------------------------
    ; High level convenience wrappers.
    ; -------------------------------------------------------------

    .proc write_instruction_when_ready
        ; Wait for LCD to become ready, then write instruction to
        ; CMND register.
        ;
        ; In (zero page):
        ;   LCD::byte = instruction byte to write
        ; Out:
        ;   A, X, Y preserved

        pha
        lda byte                   ; Save the instruction byte
        pha
    @wait:
        jsr check_ready
        lda byte
        bne @wait
        pla                        ; Restore the instruction byte
        sta byte
        jsr write_instruction
        pla
        rts
    .endproc

    .proc write_when_ready
        ; Wait for LCD to become ready, then write byte to DATA register.
        ;
        ; In (zero page):
        ;   LCD::byte = byte to write
        ; Out:
        ;   A, X, Y preserved

        pha
        lda byte                   ; Save the data byte
        pha
    @wait:
        jsr check_ready
        lda byte
        bne @wait
        pla                        ; Restore the data byte
        sta byte
        jsr write
        pla
        rts
    .endproc

.endscope

.endif
