; File:     irrxpd-defs.asm
; Device:   AVR
; Version:  2024-04-25
; Author:   Johannes Fechner
;           https://4n7.de/
;           https://github.com/jofe95

; == The register ir_status ==
; Bit positions are assigned as follows:
.equ IR_STATUS_PREV_bp = 0 ; previous state of IR RX input
.equ IR_STATUS_DATA_bp = 1 ; event flag, received valid data frame
.if IR_RECOGNIZE_REPETITION
.equ IR_STATUS_REPETITION_bp = 2 ; event flag, received repetition frame
.endif
.if IR_DEBUG
.equ IR_STATUS_DISCARDED_bp = 3 ; event flag, discarded reception
.endif

; == Possible values of register ir_pulseCntr ==
; Pulse/pause # within a frame, incremented at each falling edge (= begin of pulse):
; 0 = no edge received yet, waiting for begin of start pulse; or pulse already too long -> to be discarded
; 1 = after start edge, start pulse or pause ongoing
; 2 = first data pulse or pause ongoing, after reception of start pulse+pause
; 3 = second data pulse or pause ongoing, after reception of first data pulse+pause
; .
; .
; .
; 33 = last data pulse or pause ongoing (NEC or similar)
; 34 = stop pulse ongoing (NEC or similar)
.equ IR_DATA_START = 3 ; value of ir_pulseCntr when first data pulse+pause has been received
.equ IR_REPETITION_PAUSE_RECEIVED = 200 ; = repetition pause received, possible repetition frame stop bit ongoing

; == Debug message codes ==
.equ IR_PULSE_TOO_SHORT = $00
.equ IR_PULSE_TOO_LONG = $01
.equ IR_PAUSE_TOO_SHORT = $02
.equ IR_PAUSE_BETWEEN_0_1 = $03
.equ IR_PAUSE_TOO_LONG = $04
.equ IR_PAUSE_START_TOO_SHORT = $05
.equ IR_PAUSE_START_BETWEEN_R_D = $06
.equ IR_PAUSE_START_TOO_LONG = $07
.equ IR_PULSE_START_TOO_SHORT = $08
.equ IR_PULSE_START_TOO_LONG = $09
.equ IR_DATA_INVALID = $0A

; == IR code definitions ==
; Time values must be in ascending order, otherwise the corresponding comparisons must be modified.
.if IR_PROTOCOL == IR_NEC || IR_PROTOCOL == IR_NEC_EXT || IR_PROTOCOL == IR_ONKYO
; Time distances in microseconds (us):
.equ IR_PULSE = 560
.equ IR_PAUSE_0 = 560
.equ IR_PAUSE_1 = 1690
.equ IR_PAUSE_START_REPETITION = 2250
.equ IR_PAUSE_START_DATA = 4500
.equ IR_PULSE_START = 9000
; Data bit count:
.equ IR_DATA_BIT_CNT = 32
; Pulse count including start and stop bit:
.equ IR_PULSE_COUNT = IR_DATA_BIT_CNT + 2
.equ IR_DATA_BYTE_CNT = CEIL(IR_DATA_BIT_CNT / 8)

.elif IR_PROTOCOL == IR_SAMSUNG32
; Time distances in microseconds (us):
.equ IR_PULSE = 550
.equ IR_PAUSE_0 = 550
.equ IR_PAUSE_1 = 1650
.equ IR_PAUSE_START_DATA = 4500
.equ IR_PULSE_START = 4500
; Data bit count:
.equ IR_DATA_BIT_CNT = 32
; Pulse count including start and stop bit:
.equ IR_PULSE_COUNT = IR_DATA_BIT_CNT + 2
.equ IR_DATA_BYTE_CNT = CEIL(IR_DATA_BIT_CNT / 8)

.elif IR_PROTOCOL == IR_KASEIKYO
; Time distances in microseconds (us):
.equ IR_PULSE = 423
.equ IR_PAUSE_0 = 423
.equ IR_PAUSE_1 = 1269
.equ IR_PAUSE_START_DATA = 1690
.equ IR_PULSE_START = 3380
; Data bit count:
.equ IR_DATA_BIT_CNT = 48
; Pulse count including start and stop bit:
.equ IR_PULSE_COUNT = IR_DATA_BIT_CNT + 2
.equ IR_DATA_BYTE_CNT = CEIL(IR_DATA_BIT_CNT / 8)
.else
.error "Missing protocol definitions in irRxPulseDistance.asm."
.endif

; == Calculations ==
#define IR_TIMER_OCR ROUND(F_CPU*IR_SET_DIST*(1.0e-6)/IR_TIMER_PRESC-1)
; Calculate the resulting time distance between IR interrupts in microseconds (us):
#define IR_REAL_DIST (1.0e6*IR_TIMER_PRESC*(IR_TIMER_OCR+1)/F_CPU)
; Calculate the approximate ISR call counts of time constants (T is time in microseconds):
#define IR_MIN_CALLS(T) ROUND((100.0-IR_TOLERANCE)*(T)/IR_REAL_DIST/100.0)
#define IR_MAX_CALLS(T) ROUND((100.0+IR_TOLERANCE)*(T)/IR_REAL_DIST/100.0)

; == For testing ==
.equ IR_PAUSE_0_MAX = IR_MAX_CALLS(IR_PAUSE_0)
.equ IR_PAUSE_1_MIN = IR_MIN_CALLS(IR_PAUSE_1)
.if IR_PAUSE_0_MAX >= IR_PAUSE_1_MIN
.error "Range overlap: IR_PAUSE_0_MAX >= IR_PAUSE_1_MIN."
.endif
