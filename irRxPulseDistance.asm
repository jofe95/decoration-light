; File:		irRxPulseDistance.asm
; Device:	AVR
; Created:	2023
; Version:	2024-04-21
; Author:	Johannes Fechner
;			https://www.mikrocontroller.net/user/show/jofe

; SREG symbol was renamed to CPU_SREG in newer *def.inc files.
.ifndef SREG
.equ SREG = CPU_SREG
.endif

; == Routines ==
; === IR register initialization routine ===
ir_init:
	clr		ir_status
; Set IR_STATUS_PREV_bp bit (low-active):
	set
	bld		ir_status, IR_STATUS_PREV_bp
	sts		ir_callCntrL_ram, reg00
	sts		ir_callCntrH_ram, reg00
	sts		ir_pulseCntr_ram, reg00
	ret

.if IR_INCLUDE_ISR
; === IR receiver interrupt routine ===
ir_isr:
; Save temporary registers and SREG:
	push	temp0
	push	temp1
	push	temp2
	push	ZL
	push	ZH
	xin		temp0, SREG
	push	temp0
.if ATTINY212_LIKE
; Clear interrupt flag:
	ldi		temp0, TCA_SINGLE_OVF_bm
	xout	TCA0_SINGLE_INTFLAGS, temp0
.endif ; ATTINY212_LIKE
.include "ir_isr_body.asm"
; Restore modified registers:
	pop		temp0
	xout	SREG, temp0
	pop		ZH
	pop		ZL
	pop		temp2
	pop		temp1
	pop		temp0
	reti
.endif
