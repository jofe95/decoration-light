; File:     irrxpd-init.asm
; Device:   AVR
; Created:  2023
; Version:  2024-04-25
; Author:   Johannes Fechner
;           https://4n7.de/
;           https://github.com/jofe95

; === IR initialization code ===
; To be included by main asm file after MCU reset, during initialization procedure.
    clr     ir_status
; Set IR_STATUS_PREV_bp bit (low-active):
    set
    bld     ir_status, IR_STATUS_PREV_bp
; Clear call and pulse counters:
    sts     ir_callCntrL_ram, reg00
    sts     ir_callCntrH_ram, reg00
    sts     ir_pulseCntr_ram, reg00
