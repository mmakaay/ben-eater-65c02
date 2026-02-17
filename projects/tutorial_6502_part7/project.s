; From: Subroutine calls, now with RAM
; ------------------------------------
;
; Tutorial : https://youtu.be/omI0MrTWiMU
; Result   : https://youtu.be/omI0MrTWiMU?t=927
; Code     : https://eater.net/downloads/hello-world-final.s
;
; When comparing this code to the raw-dogged code as used
; in the tutorial video, it might become clear what advantage
; the kernal project brings. The hardware initialization and
; interaction are encapsulated by the kernal, and in the code
; below, we can make use of the high level `LCD::write`
; subroutine.
;
;
.include "bios/bios.s"

main:
    ldx #0
@print:
    lda message,x
    beq @halt
    sta LCD::byte
    jsr LCD::write
    inx
    jmp @print

@halt:
    jmp BIOS::halt

message: .asciiz "Hello, world!"

