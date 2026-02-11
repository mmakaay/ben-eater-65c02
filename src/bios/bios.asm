.setcpu "65C02"

.include "W65C22.asm"
.include "LCD.asm"
.include "Math.asm"
.include "String.asm"

; Prevent build warnings when a segment is not used.
.segment "DATA"
.segment "VARIABLES"

.SCOPE Bios

.segment "BIOS"

    boot:
        sei                    ; Disable interrupts (must be enabled
                               ; using `cli` when code that uses this
                               ; bios requires interrupts)

        lda #<default_nmi      ; Set default NMI handler.
        sta nmi_vector         ; This vector can be overridden to
        lda #>default_nmi      ; point to a custom NMI handler.
        sta nmi_vector + 1

        lda #<default_irq      ; Same for the IRQ handler.
        sta irq_vector
        lda #>default_irq
        sta irq_vector + 1

        ldx #$ff               ; Initialize stack pointer
        txs

        jsr lcd_init           ; Initialize LCD display
        jsr lcd_clear          ; Clear LCD display

        jmp main               ; Note: must be implemented by application


    ; Can be jumped to, to fully halt the computer.
    halt:
        bra halt               ; Stop execution


.segment "ZP"

    nmi_vector: .res 2
    irq_vector: .res 2

.segment "VECTORS"

    .word handle_nmi           ; Non-Maskable Interrupt vector
    .word boot                 ; Reset vector
    .word handle_irq           ; IRQ vector

.segment "BIOS"

    handle_nmi:
        jmp (nmi_vector)
    
    handle_irq:
        jmp (irq_vector)

    default_nmi:
        rti
    
    default_irq:
        rti

.ENDSCOPE