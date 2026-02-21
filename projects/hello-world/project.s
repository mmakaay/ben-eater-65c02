.include "breadbox/kernal.inc"

message: .asciiz "Hello, world!"

main:
    CP_ADDRESS PRINT::string, message  ; Line up the message for printing

    .ifdef HAS_LCD
    jsr LCD::print                     ; Print message on the LCD display
    .endif

    .ifdef HAS_UART
    jsr UART::print                    ; Print message on an RS232 terminal
    .endif

    HALT                               ; Stop progra execution

