; File:     irrxpd-isrbody.asm
; Device:   AVR
; Created:  2023
; Version:  2024-04-25
; Author:   Johannes Fechner
;           https://4n7.de/
;           https://github.com/jofe95

; Increment interrupt counter, preventing overflow:
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    subi    temp0, $FF
    sbci    temp1, $FF
    breq    ir_isr_noInc    ; Maximum counter value reached.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    subi    temp0, low(-1)
    sbci    temp1, high(-1)
    sts     ir_callCntrL_ram, temp0
    sts     ir_callCntrH_ram, temp1
ir_isr_noInc:
; Detect whether IRRX value has changed:
    bst     ir_status, IR_STATUS_PREV_bp
    bld     temp0, IRRX_bp
    xin     temp1, IRRX_IN
    eor     temp0, temp1
    sbrs    temp0, IRRX_bp
    rjmp    ir_isr_end                              ; No change.
; IRRX has changed.
    bst     temp1, IRRX_bp                          ; Store current IR state into T flag.
    bld     ir_status, IR_STATUS_PREV_bp                ; Update previous state.
    brtc    ir_isr_fallingEdge
; Rising edge.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    lds     temp2, ir_pulseCntr_ram
    cpi     temp2, 1
    breq    ir_isr_1stRisingEdge
; Data or stop rising edge.
.if IR_DEBUG
    ldi     temp2, IR_PULSE_TOO_SHORT
.endif ; IR_DEBUG
    subi    temp0, low(IR_MIN_CALLS(IR_PULSE))
    sbci    temp1, high(IR_MIN_CALLS(IR_PULSE))
    brlo    ir_isr_discard                          ; Pulse was too short.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
.if IR_DEBUG
    ldi     temp2, IR_PULSE_TOO_LONG
.endif ; IR_DEBUG
    subi    temp0, low(IR_MAX_CALLS(IR_PULSE)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PULSE)+1)
    brsh    ir_isr_discard                          ; Pulse was too long.
; Data or stop pulse was within bounds.
; Stop pulse received?
    lds     temp0, ir_pulseCntr_ram
    cpi     temp0, IR_PULSE_COUNT
    breq    ir_isr_eot                              ; Yes, end of transmission.
.if IR_RECOGNIZE_REPETITION
    cpi     temp0, IR_REPETITION_PAUSE_RECEIVED
    breq    ir_isr_repetition                       ; Repetition frame received.
.endif ; IR_RECOGNIZE_REPETITION
    rjmp    ir_isr_clrCallCntr
ir_isr_eot:
; Regular (non-repetition) frame received.
; If supported by chosen protocol, check integrity of address and command:
.if IR_DEBUG && (IR_PROTOCOL == IR_NEC || IR_PROTOCOL == IR_NEC_EXT)
    ldi     temp2, IR_DATA_INVALID
.endif
.if IR_PROTOCOL == IR_NEC
    lds     temp0, ir_data_ram
    lds     temp1, ir_data_ram+1
    com     temp1
    cp      temp0, temp1
    brne    ir_isr_discard
.endif
.if IR_PROTOCOL == IR_NEC || IR_PROTOCOL == IR_NEC_EXT
    lds     temp0, ir_data_ram+2
    lds     temp1, ir_data_ram+3
    com     temp1
    cp      temp0, temp1
    brne    ir_isr_discard
.endif
; Valid transmission received.
    mov     temp0, ir_status
    ori     temp0, (1<<IR_STATUS_DATA_bp)
    mov     ir_status, temp0
    rjmp    ir_isr_clrPulseCntr
.if IR_RECOGNIZE_REPETITION
ir_isr_repetition:
    mov     temp0, ir_status
    ori     temp0, (1<<IR_STATUS_REPETITION_bp)
    mov     ir_status, temp0
    rjmp    ir_isr_clrPulseCntr
.endif ; IR_RECOGNIZE_REPETITION
ir_isr_1stRisingEdge:
.if IR_DEBUG
    ldi     temp2, IR_PULSE_START_TOO_SHORT
.endif ; IR_DEBUG
    subi    temp0, low(IR_MIN_CALLS(IR_PULSE_START))
    sbci    temp1, high(IR_MIN_CALLS(IR_PULSE_START))
    brlo    ir_isr_discard                          ; Start pulse was too short.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
.if IR_DEBUG
    ldi     temp2, IR_PULSE_START_TOO_LONG
.endif ; IR_DEBUG
    subi    temp0, low(IR_MAX_CALLS(IR_PULSE_START)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PULSE_START)+1)
    brsh    ir_isr_discard                          ; Start pulse was too long.
; Start pulse was within bounds.
ir_isr_rjmpClrCallCntr:
    rjmp    ir_isr_clrCallCntr
ir_isr_discard:
.if IR_DEBUG
    sts     ir_debugCode_ram, temp2
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    sts     ir_debugCallCntrL_ram, temp0
    sts     ir_debugCallCntrH_ram, temp1
    lds     temp0, ir_pulseCntr_ram
    sts     ir_debugPulseCntr_ram, temp0
    mov     temp0, ir_status
    ori     temp0, (1<<IR_STATUS_DISCARDED_bp)
    mov     ir_status, temp0
    rjmp    ir_isr_clrPulseCntr
.endif ; IR_DEBUG
ir_isr_fallingEdge:
    lds     temp2, ir_pulseCntr_ram
    inc     temp2
    sts     ir_pulseCntr_ram, temp2
    cpi     temp2, 1
    breq    ir_isr_rjmpClrCallCntr                  ; First falling edge, jump to end.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    cpi     temp2, 2
    breq    ir_isr_2ndFallingEdge                   ; Second falling edge (after start pause).
; Falling edge after data pause.
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_TOO_SHORT
.endif ; IR_DEBUG
    subi    temp0, low(IR_MIN_CALLS(IR_PAUSE_0))
    sbci    temp1, high(IR_MIN_CALLS(IR_PAUSE_0))
    brlo    ir_isr_discard                          ; Pause was too short.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    subi    temp0, low(IR_MAX_CALLS(IR_PAUSE_0)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PAUSE_0)+1)
    brlo    ir_isr_lsl                              ; '0' received, left-shift mask.
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_BETWEEN_0_1
.endif ; IR_DEBUG
    subi    temp0, low(IR_MIN_CALLS(IR_PAUSE_1))
    sbci    temp1, high(IR_MIN_CALLS(IR_PAUSE_1))
    brlo    ir_isr_discard
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    subi    temp0, low(IR_MAX_CALLS(IR_PAUSE_1)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PAUSE_1)+1)
    brlo    ir_isr_setDataBit                       ; '1' received.
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_TOO_LONG
.endif ; IR_DEBUG
    rjmp    ir_isr_discard                          ; Pause was too long.
ir_isr_2ndFallingEdge:
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_START_TOO_SHORT
.endif ; IR_DEBUG
.if IR_RECOGNIZE_REPETITION
    subi    temp0, low(IR_MIN_CALLS(IR_PAUSE_START_REPETITION))
    sbci    temp1, high(IR_MIN_CALLS(IR_PAUSE_START_REPETITION))
    brlo    ir_isr_discard
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
    subi    temp0, low(IR_MAX_CALLS(IR_PAUSE_START_REPETITION)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PAUSE_START_REPETITION)+1)
    brlo    ir_isr_afterRepPause
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_START_BETWEEN_R_D
.endif ; IR_DEBUG
.endif ; IR_RECOGNIZE_REPETITION
    subi    temp0, low(IR_MIN_CALLS(IR_PAUSE_START_DATA))
    sbci    temp1, high(IR_MIN_CALLS(IR_PAUSE_START_DATA))
    brlo    ir_isr_discard
    lds     temp0, ir_callCntrL_ram
    lds     temp1, ir_callCntrH_ram
.if IR_DEBUG
    ldi     temp2, IR_PAUSE_START_TOO_LONG
.endif ; IR_DEBUG
    subi    temp0, low(IR_MAX_CALLS(IR_PAUSE_START_DATA)+1)
    sbci    temp1, high(IR_MAX_CALLS(IR_PAUSE_START_DATA)+1)
    brlo    ir_isr_spwb
    rjmp    ir_isr_discard
ir_isr_spwb:
; Start pause was within bounds.
; Clear the data buffer:
    clr     temp0
    ldiz    ir_data_ram
ir_isr_clrDataLoop:
    st      Z+, reg00
    inc     temp0
    cpi     temp0, IR_DATA_BYTE_CNT
    brlo    ir_isr_clrDataLoop
; Initialize the bit mask:
    ldi     temp0, 1
    sts     ir_mask_ram, temp0
    rjmp    ir_isr_clrCallCntr
ir_isr_setDataBit:
; Get the current data bit index:
    lds     temp0, ir_pulseCntr_ram
    subi    temp0, IR_DATA_START
; Determine the data byte index:
    lsr     temp0                       ; Divide ...
    lsr     temp0
    lsr     temp0                       ; ... by 8.
    cpi     temp0, IR_DATA_BYTE_CNT     ; Make sure that ...
    brsh    ir_isr_clrPulseCntr         ; ... data byte index is within bounds.
; Load the Z pointer with data byte address:
    ldiz    ir_data_ram
    addz    temp0
; Load the data byte:
    ld      temp0, Z
; Set the bit in the data byte:
    lds     temp1, ir_mask_ram
    or      temp0, temp1
; Write back:
    st      Z, temp0
;   rjmp    ir_isr_lsl
ir_isr_lsl:
; Prepare the bit mask for the next bit:
    lds     temp0, ir_mask_ram
    lsl     temp0
    brcc    ir_isr_skipInc
    inc     temp0
ir_isr_skipInc:
    sts     ir_mask_ram, temp0
    rjmp    ir_isr_clrCallCntr
.if IR_RECOGNIZE_REPETITION
ir_isr_afterRepPause:
    ldi     temp0, IR_REPETITION_PAUSE_RECEIVED
    sts     ir_pulseCntr_ram, temp0
    rjmp    ir_isr_clrCallCntr
.endif ; IR_RECOGNIZE_REPETITION
ir_isr_clrPulseCntr:
    sts     ir_pulseCntr_ram, reg00
ir_isr_clrCallCntr:
    sts     ir_callCntrL_ram, reg00
    sts     ir_callCntrH_ram, reg00
; ### DEVICE-DEPENDENT ###
.if ATMEGA48A_LIKE == 1 && IR_TIMER_PRESC > 1
; Reset Timer2 prescaler, ATmega88A
    ldi     temp0, 1<<PSRASY
    xout    GTCCR, temp0
.endif
; ### END OF DEVICE-DEPENDENT ###
ir_isr_end:
