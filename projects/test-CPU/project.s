; -----------------------------------------------------------------
; CPU check: detect NMOS 6502 vs CMOS 65C02.
;
; Uses the decimal mode ADC flag behavior difference:
;   SED / LDA #$99 / CLC / ADC #$01
;   Result: A = $00 on both CPUs.
;   65C02: Z=1 (Z flag reflects BCD result $00)
;   6502:  Z=0 (Z flag reflects binary intermediate $9A)
;
; The result is shown on the LCD display.
; -----------------------------------------------------------------

.include "breadbox/kernal.s"

.segment "ZEROPAGE"

    ptr: .res 2

.segment "CODE"

    msg_6502:  .asciiz "CPU: NMOS 6502"
    msg_65c02: .asciiz "CPU: CMOS 65C02"

    main:
        ; Detect CPU type using decimal mode Z flag behavior.
        sed
        lda #$99
        clc
        adc #$01        ; A=$00 on both; Z=1 on 65C02, Z=0 on 6502
        cld

        beq @is_65c02

    @is_6502:
        CP_ADDRESS PRINT::string, msg_6502
        jmp @print

    @is_65c02:
        CP_ADDRESS PRINT::string, msg_65c02

    @print:
        jmp LCD::print
        jmp KERNAL::halt

