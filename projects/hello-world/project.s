.include "breadbox/kernal.s"

message: .asciiz "Hello, world!"

main:
    ldx #0               ; Byte position to read from `hello`

    lda hello,x          ; Read next byte
    beq @done            ; Stop at terminating null-byte
    sta LCD::byte        ; Line up byte for the LCD display
    jsr LCD::write       ; Wait for LCD display to be ready, then send byte
    inx                  ; Move to next byte position
    jmp @loop            ; And repeat
@done:
    jmp KERNAL::halt     ; Halt the computer
