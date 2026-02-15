; -----------------------------------------------------------------
; GPIO (General Purpose I/O) abstraction
; -----------------------------------------------------------------

.ifndef BIOS_GPIO_S
BIOS_GPIO_S = 1

.include "bios/bios.s"

.scope GPIO

.segment "BIOS"

    ; Import the hardware driver.
    .include "bios/gpio/via_W65C22.s"

    ; Port selection constants (Y register values).
    PORTA = 1
    PORTB = 0

    ; Pin bit masks.
    P0 = %00000001
    P1 = %00000010
    P2 = %00000100
    P3 = %00001000
    P4 = %00010000
    P5 = %00100000
    P6 = %01000000
    P7 = %10000000

    ; -------------------------------------------------------------
    ; Access to the low level driver API
    ; -------------------------------------------------------------

    set_inputs = DRIVER::set_inputs
        ; Set data direction to input for the requested pins.
        ;
        ; In:
        ;   A = pin mask (1 = set to input)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered

    set_outputs = DRIVER::set_outputs
        ; Set data direction to output for the requested pins.
        ;
        ; In:
        ;   A = pin mask (1 = set to output)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered

    set_pins = DRIVER::set_pins
        ; Set pin values for a selected group of pins.
        ; Pins not selected by the mask are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = update this pin, 0 = preserve)
        ;   X = pin values (desired state for pins to update)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   X = preserved
        ;   Y = preserved

    turn_on = DRIVER::turn_on
        ; Turn on (set HIGH) selected pins.
        ; Other pins are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = turn on this pin)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   Y = preserved

    turn_off = DRIVER::turn_off
        ; Turn off (set LOW) selected pins.
        ; Other pins are preserved.
        ;
        ; In:
        ;   A = pin mask (1 = turn off this pin)
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = clobbered
        ;   Y = preserved

    write_port = DRIVER::write_port
        ; Write a full byte to the port register.
        ;
        ; In:
        ;   A = byte to write
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = preserved
        ;   Y = preserved

    read_port = DRIVER::read_port
        ; Read a full byte from the port register.
        ;
        ; In:
        ;   Y = port (GPIO::PORTA or GPIO::PORTB)
        ; Out:
        ;   A = byte read
        ;   Y = preserved

.endscope

.endif
