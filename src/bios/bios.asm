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

        LDA #<default_nmi      ; Set default NMI handler.
        STA nmi_vector         ; This vector can be overridden to
        LDA #>default_nmi      ; point to a custom NMI handler.
        STA nmi_vector + 1

        LDA #<default_nmi      ; Same for the IRQ handler.
        STA nmi_vector
        LDA #>default_nmi
        STA nmi_vector + 1

        ldx #$ff               ; Initialize stack pointer
        txs

        jsr lcd_init           ; Initialize LCD display
        jsr lcd_clear          ; Clear LCD display

        jmp main               ; Note: must be implemented by application


    ; Can be jumped to, to fully halt the computer.
    halt:
        jmp halt               ; Stop execution


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
    
    default_ieq:
        rti

.ENDSCOPE