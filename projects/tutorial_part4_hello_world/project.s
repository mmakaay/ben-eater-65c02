; From: Connecting and LCD to our computer
; ----------------------------------------
;
; Tutorial : https://youtu.be/FY3zTUaykVo
; Result   : https://youtu.be/FY3zTUaykVo?t=1614
; Code     : https://eater.net/downloads/hello-world.s
;
.include "breadbox/kernal.s"

main:
    SET_BYTE LCD::byte, #'H'
    jsr LCD::write

    SET_BYTE LCD::byte, #'e'
    jsr LCD::write

    SET_BYTE LCD::byte, #'l'
    jsr LCD::write

    SET_BYTE LCD::byte, #'l'
    jsr LCD::write

    SET_BYTE LCD::byte, #'o'
    jsr LCD::write

    SET_BYTE LCD::byte, #','
    jsr LCD::write

    SET_BYTE LCD::byte, #' '
    jsr LCD::write

    SET_BYTE LCD::byte, #'w'
    jsr LCD::write

    SET_BYTE LCD::byte, #'o'
    jsr LCD::write

    SET_BYTE LCD::byte, #'r'
    jsr LCD::write

    SET_BYTE LCD::byte, #'l'
    jsr LCD::write

    SET_BYTE LCD::byte, #'d'
    jsr LCD::write

    SET_BYTE LCD::byte, #'!'
    jsr LCD::write

    jmp KERNAL::halt
