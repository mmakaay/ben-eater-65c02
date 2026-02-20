; -----------------------------------------------------------------
; Delay API
;
; Provides timed delays based on the configured CPU clock speed.
;
; High-level macro (compile-time):
;   delay_us <microseconds>   - delay for a known number of us
;
; Low-level procedure (runtime):
;   DELAY::wait               - delay for DELAY::iterations * 5 cycles
;
; All procedures preserve A, X, Y. The delay_us macro clobbers A.
; -----------------------------------------------------------------

.ifndef KERNAL_DELAY_S
KERNAL_DELAY_S = 1

.include "breadbox/kernal.s"

.scope DELAY

    .include "breadbox/delay/waitloop.s"

.segment "ZEROPAGE"

    iterations: .res 2         ; 16-bit iteration count (lo/hi)

.segment "KERNAL"

    wait = DRIVER::wait
        ; Delay for approximately iterations * 5 CPU cycles.
        ;
        ; In (zero page):
        ;   DELAY::iterations = 16-bit iteration count (lo/hi)
        ; Out:
        ;   A, X, Y preserved

.endscope

; -----------------------------------------------------------------
; delay_us - compile-time microsecond delay
;
; Converts a compile-time constant (microseconds) into the matching
; iteration count for the current CPU_CLOCK, then calls DELAY::wait.
;
; In:
;   us = delay duration in microseconds (compile-time constant)
; Out:
;   A = clobbered (by set_word)
;   X, Y preserved
; -----------------------------------------------------------------

.macro delay_us us
    .local ITERATIONS
    ITERATIONS = (us * (::CPU_CLOCK / 1000000)) / 5
    set_word DELAY::iterations, #<ITERATIONS, #>ITERATIONS
    jsr DELAY::wait
.endmacro

; -----------------------------------------------------------------
; delay_ms - compile-time milisecond delay
;
; Converts a compile-time constant (miliseconds) into the matching
; iteration count for the current CPU_CLOCK, then calls DELAY::wait.
;
; In:
;   ms = delay duration in miliseconds (compile-time constant)
; Out:
;   A = clobbered (by set_word)
;   X, Y preserved
; -----------------------------------------------------------------

.macro delay_ms ms
    delay_us ms * 1000
.endmacro

.endif
