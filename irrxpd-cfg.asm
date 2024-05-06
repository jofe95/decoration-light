; File:     irrxpd-cfg.asm
; Device:   AVR
; Created:  2023
; Version:  2024-04-25
; Author:   Johannes Fechner
;           https://4n7.de/
;           https://github.com/jofe95

; == Implemented IR codes ==
; Currently implemented IR codes, values following <https://www.mikrocontroller.net/articles/IRMP>:
.equ IR_NEC = 2
.equ IR_KASEIKYO = 5
.equ IR_SAMSUNG32 = 10
.equ IR_ONKYO = 56
.equ IR_NEC_EXT = 59        ; Not defined by IRMP.

; == Configuration ==
; Choose the IR protocol to be received from the list "Implemented IR codes" above:
.equ IR_PROTOCOL = IR_KASEIKYO

; Choose whether to recognize repetition frames, resulting in the IR_STATUS_REPETITION flag being set.
; Only available if the chosen protocol uses them.
; Set the following symbol to 0 in order to disable the recognition of repetition frames:
.equ IR_RECOGNIZE_REPETITION = 0

; Choose whether the IR_STATUS_DISCARDED flag is to be set when a reception was discarded,
; in addition to saving an error code and the counter values to RAM.
; Set the following symbol to 0 in order to disable that:
.equ IR_DEBUG = 0

; Set the admissible time tolerance in %:
.equ IR_TOLERANCE = 40

; Set the IR interrupt time distance in microseconds (us):
.equ IR_SET_DIST = 100

; Set the denominator of the IR timer prescaler:
.equ IR_TIMER_PRESC = 1
