; File:		decoLightPowerSupply\main.asm
; Device:	ATtiny412
; Created:	2023-12-24 11:10:42
; Version:	2024-04-21
; Author:	Johannes Fechner
;			https://www.mikrocontroller.net/user/show/jofe

.nolist
.include <tn412def.inc>
.include "macros.asm"
.include "irRxPulseDistance.cfg.asm"
.include "irRxPulseDistance.defs.asm"
.list

; == Hardware definitions ==
; === Device-dependent settings for library files ===
.equ ATTINY212_LIKE = 1
.equ ATMEGA48A_LIKE = 0

; === CPU clock frequency in Hz ===
.equ F_CPU = 8_000_000	; 16 MHz fuse-selected, divided by 2.

; === Hardware connections ===
.equ IRRX_IN = PORTA_IN
.equ IRRX_bp = 6
.equ FET_VDIR = VPORTA_DIR
.equ FET_VOUT = VPORTA_OUT
.equ FET_bp = 1
.equ LED_VDIR = VPORTA_DIR
.equ LED_VOUT = VPORTA_OUT
.equ LED_bp = 7
.equ AC_VIN = VPORTA_IN
.equ AC_bp = 3

; == Register name definitions ==
.def reg00 = r2
; === Temporary registers ===
.def temp0 = r16
.def temp1 = r17
.def temp2 = r18
.def temp3 = r19
.def temp4 = r20
.def temp5 = r21
.def tempL = r24
.def tempH = r25
; === General registers ===
.def miscBits = r3					; Miscellaneous status bits and flags.
.equ MORSE_ACTIVE_bp = 0
.equ MORSE_TICK_bp = 1
.equ AC_FILTERED_bp = 2
.equ TIME_SET_bp = 3				; Whether time was already set since last reset (clock running at real time or not).
.def state = r4						; Time setting state.
; 0 default state.
; 1 waiting for tens of hours to be set.
; 2 waiting for units of hours to be set.
; 3 waiting for tens of minutes to be set.
; 4 waiting for units of minutes to be set.
; 5 waiting for tens of seconds to be set.
; 6 waiting for units of seconds to be set.
.equ STATE_TOTAL_CNT = 7			; Total count of states, including state 0.

; === IR_RX registers ===
.def ir_status = r5			; See file ir-rx-pulse-dist.asm.
; === Morse output registers ===
.def morseCallCntrL = r6	; Must be an even register.
.def morseCallCntrH = r7	; Must be the next register after morseCallCntrL.
; === ZVCD registers ===
.def acFilter = r8
.equ AC_FILTER_MAX_VAL = 20	; * 100 us == filter latency.

; == RAM usage ==
.dseg
.org SRAM_START
; === Real-time clock ===
mainsCycleCntr_ram:		.byte 1
seconds_ram:			.byte 1
minutes_ram:			.byte 1
hours_ram:				.byte 1
; === Morse output ===
currOutputDigit_ram:	.byte 1
currMorseAtom_ram:		.byte 1
morseMask_ram:			.byte 1
digitBuf_ram:			.byte 6
; === IR module ===
ir_callCntrL_ram:		.byte 1
ir_callCntrH_ram:		.byte 1
ir_pulseCntr_ram:		.byte 1
ir_mask_ram:			.byte 1
ir_data_ram:			.byte IR_DATA_BYTE_CNT ; The received data (address and command).
.if IR_DEBUG
ir_debugCode_ram:		.byte 1 ; The reason why reception was discarded (see "Debug message codes" in file irRxPulseDistance.defs.asm).
ir_debugCallCntrL_ram:	.byte 1 ; A copy of ir_callCntrL value when reception was discarded.
ir_debugCallCntrH_ram:	.byte 1 ; A copy of ir_callCntrH value when reception was discarded.
ir_debugPulseCntr_ram:	.byte 1 ; A copy of ir_pulseCntr value when reception was discarded.
.endif
.cseg

.org 0
	rjmp	reset

; CRCSCAN interrupt vectors
.org CRCSCAN_NMI_vect
	reti

; BOD interrupt vectors
.org BOD_VLM_vect
	reti

; PORTA interrupt vectors
.org PORTA_PORT_vect
	reti

; RTC interrupt vectors
.org RTC_CNT_vect
	reti
.org RTC_PIT_vect
	reti

; TCA0 interrupt vectors
.org TCA0_OVF_vect
	rjmp	isr100us
.org TCA0_HUNF_vect
	reti
.org TCA0_CMP0_vect
	reti
.org TCA0_CMP1_vect
	reti
.org TCA0_CMP2_vect
	reti

; TCB0 interrupt vectors
.org TCB0_INT_vect
	reti

; TCD0 interrupt vectors
.org TCD0_OVF_vect
	reti
.org TCD0_TRIG_vect
	reti

; AC0 interrupt vectors
.org AC0_AC_vect
	reti

; ADC0 interrupt vectors
.org ADC0_RESRDY_vect
	reti
.org ADC0_WCOMP_vect
	reti

; TWI0 interrupt vectors
.org TWI0_TWIS_vect
	reti
.org TWI0_TWIM_vect
	reti

; SPI0 interrupt vectors
.org SPI0_INT_vect
	reti

; USART0 interrupt vectors
.org USART0_RXC_vect
	reti
.org USART0_DRE_vect
	reti
.org USART0_TXC_vect
	reti

; NVMCTRL interrupt vectors
.org NVMCTRL_EE_vect
	reti

.org INT_VECTORS_SIZE
.include "irRxPulseDistance.asm"
.include "remote-control-panasonic-n2qayb-table.asm"

morseTable:
; 4 bytes per character: 3 bytes LED on/off sequence (1: LED on, 0: LED off),
; last byte contains total length in dot units.
.db 0b01110111, 0b01110111, 0b00000111, 19 ; 0
.db 0b11011101, 0b11011101, 0b00000001, 17 ; 1
.db 0b01110101, 0b01110111, 0b00000000, 15 ; 2
.db 0b11010101, 0b00011101, 0b00000000, 13 ; 3
.db 0b01010101, 0b00000111, 0b00000000, 11 ; 4
.db 0b01010101, 0b00000001, 0b00000000,  9 ; 5
.db 0b01010111, 0b00000101, 0b00000000, 11 ; 6
.db 0b01110111, 0b00010101, 0b00000000, 13 ; 7
.db 0b01110111, 0b01010111, 0b00000000, 15 ; 8
.db 0b01110111, 0b01110111, 0b00000001, 17 ; 9
.db 0b01010101, 0b01010101, 0b00000000, 15 ; Error: invalid digit received.
.db 0b01110111, 0b00000000, 0b00000000,  7 ; M

reset:
; Initialize registers:
	clr		reg00
	clr		miscBits
	clr		state
	clr		morseCallCntrL
	clr		morseCallCntrH
; Initialize IR registers:
	rcall	ir_init
; Initialize RAM:
	sts		mainsCycleCntr_ram, reg00
	sts		seconds_ram, reg00
	sts		minutes_ram, reg00
	sts		hours_ram, reg00
; Set clock prescaler:
	ldi		temp0, $D8
	xout	CPU_CCP, temp0
	ldi		temp0, $01
	xout	CLKCTRL_MCLKCTRLB, temp0	; Clock division by 2.
; Initialize TCA (ir_intr):
	ldi		temp0, low(IR_TIMER_OCR)
	xout	TCA0_SINGLE_PER, temp0
	ldi		temp0, high(IR_TIMER_OCR)
	xout	TCA0_SINGLE_PER+1, temp0
	ldi		temp0, 1					; No prescaling, enable.
	xout	TCA0_SINGLE_CTRLA, temp0
	xout	TCA0_SINGLE_INTCTRL, temp0	; Enable overflow interrupt.
; Initialize outputs:
	sbi		FET_VDIR, FET_bp
	sbi		LED_VDIR, LED_bp
; Enable interrupts:
	sei

; == Main loop ==
loop:
; === Real-time clock seconds tick ===
	lds		temp0, mainsCycleCntr_ram
	cpi		temp0, 50
	brlo	loop_afterSec
; mainsCycleCntr_ram reached 50, so one second is over.
	sts		mainsCycleCntr_ram, reg00
	lds		temp0, seconds_ram
	inc		temp0
	sts		seconds_ram, temp0
	cpi		temp0, 60
	brlo	loop_afterSec
; Seconds overflow.
	sts		seconds_ram, reg00
	lds		temp0, minutes_ram
	inc		temp0
	sts		minutes_ram, temp0
	cpi		temp0, 60
	brlo	loop_afterSec
; Minutes overflow.
	sts		minutes_ram, reg00
	lds		temp0, hours_ram
	inc		temp0
	sts		hours_ram, temp0
; Check whether output shall be switched on or off.
; Skip check if time was not set yet:
	bst		miscBits, TIME_SET_bp
	brtc	loop_noSwOff
	cpi		temp0, 19
	brne	loop_noSwOn
	sbi		FET_VOUT, FET_bp
	rjmp	loop_afterSec
loop_noSwOn:
	cpi		temp0, 23
	brne	loop_noSwOff
	cbi		FET_VOUT, FET_bp
	rjmp	loop_afterSec
loop_noSwOff:
; Check for hours overflow:
	cpi		temp0, 24
	brlo	loop_afterSec
; Hours overflow.
	sts		hours_ram, reg00
loop_afterSec:

; === Morse output ===
	mov		temp0, miscBits
	andi	temp0, (1<<MORSE_ACTIVE_bp) | (1<<MORSE_TICK_bp)
	cpi		temp0, (1<<MORSE_ACTIVE_bp) | (1<<MORSE_TICK_bp)
	breq	loop_startMorse
	rjmp	loop_afterMorse
loop_startMorse:
; Morse transmission active and 100 ms interval finished.
; First, clear event flag:
	clt
	bld		miscBits, MORSE_TICK_bp
; Check whether character or pause in-between is active:
	lds		temp0, currOutputDigit_ram
	sbrs	temp0, 0
	rjmp	loop_chr
; currOutputDigit_ram is odd -> pause.
	lds		temp1, currMorseAtom_ram
	inc		temp1
	cpi		temp1, 3
	brsh	loop_eop	; End of pause.
	sts		currMorseAtom_ram, temp1
	rjmp	loop_afterMorse
loop_eop:
	inc		temp0		; contains currOutputDigit_ram.
	sts		currOutputDigit_ram, temp0
	sts		currMorseAtom_ram, reg00
	sbi		LED_VOUT, LED_bp
	rjmp	loop_afterMorse
loop_chr:
; currOutputDigit_ram is even -> character.
	lsr		temp0		; contains currOutputDigit_ram.
; Fetch current output character from RAM:
	ldiz	digitBuf_ram
	addz	temp0
	ld		temp0, Z
; Fetch pattern of current output character from flash:
	ldiz	2*morseTable
	ldi		temp1, 4
	mul		temp0, temp1
	addz	r0
	lds		temp0, currMorseAtom_ram
	lsr		temp0
	lsr		temp0
	lsr		temp0
	addz	temp0
	lpm		temp1, Z				; Load bit pattern.
; Check for end of character:
	ldi		temp2, 3
	sub		temp2, temp0
	addz	temp2
	lpm		temp0, Z				; Load length of current morse character.
	lds		temp2, currMorseAtom_ram
	cp		temp2, temp0
	brsh	loop_morseEoc
	inc		temp2
	sts		currMorseAtom_ram, temp2
; Update LED output depending on current bit:
	lds		temp0, morseMask_ram
	and		temp1, temp0
	breq	loop_morse0
	sbi		LED_VOUT, LED_bp
	rjmp	loop_skipCbi
loop_morse0:
	cbi		LED_VOUT, LED_bp
loop_skipCbi:
; Left-shift bit mask:
	lsl		temp0
	brcc	loop_skipInc
	inc		temp0
loop_skipInc:
	sts		morseMask_ram, temp0
	rjmp	loop_afterMorse
loop_morseEoc: ; End of character.
	cbi		LED_VOUT, LED_bp
	lds		temp0, currOutputDigit_ram
; Check for end of transmission:
	cpi		temp0, 10		; after 6 characters and 5 pauses in-between.
	brsh	loop_morseEot
	inc		temp0
	sts		currOutputDigit_ram, temp0
	ldi		temp0, 1
	sts		currMorseAtom_ram, temp0
	ldi		temp0, 1<<1
	sts		morseMask_ram, temp0
	rjmp	loop_afterMorse
loop_morseEot: ; End of transmission.
	clt
	bld		miscBits, MORSE_ACTIVE_bp
loop_afterMorse:

; === Listening to IR event ===
; Check whether IR data was received:
	sbrs	ir_status, IR_STATUS_DATA_bp
	rjmp	loop_afterIr
; Valid IR data received.
	cli
; Clear IR miscBits flag:
	clt
	bld		ir_status, IR_STATUS_DATA_bp
; Check IR address and command:
	lds		temp0, ir_data_ram		; Kaseikyo manufacturer ID, byte #0.
	cpi		temp0, RC_CONST_0
	brne	loop_wrongAddr
	lds		temp0, ir_data_ram+1	; Kaseikyo manufacturer ID, byte #1.
	cpi		temp0, RC_CONST_1
	brne	loop_wrongAddr
	lds		temp0, ir_data_ram+2	; Kaseikyo parity (low nibble) + genre1 (high nibble).
	cpi		temp0, RC_CONST_2
	brne	loop_wrongAddr
	lds		temp0, ir_data_ram+3	; Kaseikyo genre2 (low nibble) + 4 LSbits of command (here always 0).
	cpi		temp0, RC_CONST_3
	breq	loop_addrOK
loop_wrongAddr:
	rjmp	loop_sei
loop_addrOK:
; Address OK. Load IR command:
	lds		temp0, ir_data_ram+4	; LSB of relevant command part.
; Convert command to ID:
	ldiz	2*rcCmdIdTable
	addz	temp0
	lpm		temp0, Z
; Make sure state is in allowed range:
	ldi		temp1, STATE_TOTAL_CNT
	cp		state, temp1
	brlo	loop_stateOK
; State is out-of-bounds.
	rjmp	reset
loop_stateOK:
; Branch according to state:
	ldiz	loop_jmpTbl
	addz	state
	ijmp
loop_jmpTbl:
	rjmp	loop_state0
	rjmp	loop_state1
	rjmp	loop_state2
	rjmp	loop_state3
	rjmp	loop_state4
	rjmp	loop_state5
	rjmp	loop_state6
loop_state0:
	cpi		temp0, RC_CMD_INFO
	brne	loop_state0m
; INFO button was pressed.
	lds		temp0, hours_ram
	rcall	to2digDec
	sts		digitBuf_ram, temp2
	sts		digitBuf_ram+1, temp1
	lds		temp0, minutes_ram
	rcall	to2digDec
	sts		digitBuf_ram+2, temp2
	sts		digitBuf_ram+3, temp1
	lds		temp0, seconds_ram
	rcall	to2digDec
	sts		digitBuf_ram+4, temp2
	sts		digitBuf_ram+5, temp1
	sts		currOutputDigit_ram, reg00
	ldi		temp0, 1
	sts		currMorseAtom_ram, temp0
	ldi		temp0, 1<<1
	sts		morseMask_ram, temp0
	set
	bld		miscBits, MORSE_ACTIVE_bp
	sbi		LED_VOUT, LED_bp
	rjmp	loop_sei
loop_state0m:
	cpi		temp0, RC_CMD_MENU
	brne	loop_state0_0
; MENU button was pressed.
	inc		state
	ldi		temp0, 11	; Line of character 'M' in morseTable.
	rjmp	loop_ord
loop_state0_0:
; Check for "0" button:
	cpi		temp0, 0
	brne	loop_state0_1
	cbi		FET_VOUT, FET_bp
	rjmp	loop_sei
loop_state0_1:
; Check for "1" button:
	cpi		temp0, 1
	breq	loop_swOn
	rjmp	loop_sei
loop_swOn:
	sbi		FET_VOUT, FET_bp
	rjmp	loop_sei
loop_state1:
; Check for digit 0..2:
	cpi		temp0, 3
	brlo	loop_state1v
	rjmp	loop_oem
loop_state1v:				; Valid digit.
	sts		digitBuf_ram, temp0
	inc		state
	rjmp	loop_ord
loop_state2:
	lds		temp1, digitBuf_ram
	cpi		temp1, 2
	breq	loop_state2_0eq2
; Check for digit 0..9:
	cpi		temp0, 10
	brlo	loop_state2v
	rjmp	loop_oem
loop_state2_0eq2:
; Check for digit 0..3:
	cpi		temp0, 4
	brlo	loop_state2v
	rjmp	loop_oem
loop_state2v:				; Valid digit.
	sts		digitBuf_ram+1, temp0
	inc		state
	rjmp	loop_ord
loop_state3:
; Check for digit 0..5:
	cpi		temp0, 6
	brlo	loop_state3v
	rjmp	loop_oem
loop_state3v:				; Valid digit.
	sts		digitBuf_ram+2, temp0
	inc		state
	rjmp	loop_ord
loop_state4:
; Check for digit 0..9:
	cpi		temp0, 10
	brlo	loop_state4v
	rjmp	loop_oem
loop_state4v:				; Valid digit.
	sts		digitBuf_ram+3, temp0
	inc		state
	rjmp	loop_ord
loop_state5:
; Check for digit 0..5:
	cpi		temp0, 6
	brlo	loop_state5v
	rjmp	loop_oem
loop_state5v:				; Valid digit.
	sts		digitBuf_ram+4, temp0
	inc		state
	rjmp	loop_ord
loop_state6:
; Check for digit 0..9:
	cpi		temp0, 10
	brlo	loop_state6v
	rjmp	loop_oem
loop_state6v:				; Valid digit.
; Set time:
	ldi		temp1, 10
	lds		temp2, digitBuf_ram
	mul		temp1, temp2
	lds		temp2, digitBuf_ram+1
	add		r0, temp2
	sts		hours_ram, r0
	lds		temp2, digitBuf_ram+2
	mul		temp1, temp2
	lds		temp2, digitBuf_ram+3
	add		r0, temp2
	sts		minutes_ram, r0
	lds		temp2, digitBuf_ram+4
	mul		temp1, temp2
	add		r0, temp0
	sts		seconds_ram, r0
; Reset state and set time-set flag:
	clr		state
	set
	bld		miscBits, TIME_SET_bp
	rjmp	loop_ord
loop_oem: ; Output error mark:
	ldi		temp0, 10		; Line of error mark in morseTable.
;	rjmp	loop_ord
loop_ord: ; Output received digit:
	sts		digitBuf_ram+5, temp0
	ldi		temp0, 10
	sts		currOutputDigit_ram, temp0
	ldi		temp0, 1
	sts		currMorseAtom_ram, temp0
	ldi		temp0, 1<<1
	sts		morseMask_ram, temp0
	set
	bld		miscBits, MORSE_ACTIVE_bp
	sbi		LED_VOUT, LED_bp
;	rjmp	loop_sei
loop_sei:
	sei
loop_afterIr:
	rjmp	loop

; == ISR, called every 100us by timer ==
isr100us:
; Save temporary registers and CPU_SREG:
	push	temp0
	push	temp1
	push	temp2
	push	tempL
	push	tempH
	push	ZL
	push	ZH
	xin		temp0, CPU_SREG
	push	temp0

; Clear interrupt flag:
	ldi		temp0, TCA_SINGLE_OVF_bm
	xout	TCA0_SINGLE_INTFLAGS, temp0

; === IR receiving ===
.include "ir_isr_body.asm"

; === Zero-voltage-crossing detection ===
; Read AC_bp input:
	sbic	AC_VIN, AC_bp
	rjmp	isrTimer_zvcd1
; AC_bp input is 0.
	tst		acFilter
	breq	isrTimer_bottom		; Branch if filter value is already 0.
	dec		acFilter			; Else, decrement filter value.
	rjmp	isr100us_afterZvcd
isrTimer_bottom:
	sbrs	miscBits, AC_FILTERED_bp
	rjmp	isr100us_afterZvcd			; Filter output was already 0.
; Negative edge detected. Update filter output:
	clt
	bld		miscBits, AC_FILTERED_bp
	rjmp	isr100us_afterZvcd
isrTimer_zvcd1:
; AC_bp input is 1.
	mov		temp0, acFilter
	cpi		temp0, AC_FILTER_MAX_VAL
	breq	isrTimer_top		; Branch if filter value is already at maximum.
	inc		acFilter			; Else, increment filter value.
	rjmp	isr100us_afterZvcd
isrTimer_top:
	sbrc	miscBits, AC_FILTERED_bp
	rjmp	isr100us_afterZvcd			; Filter output was already 1.
; Positive edge detected. Update filter output:
	set
	bld		miscBits, AC_FILTERED_bp
; Increment mains cycle counter:
	lds		temp0, mainsCycleCntr_ram
	inc		temp0
	sts		mainsCycleCntr_ram, temp0
isr100us_afterZvcd:

; === Morse output ===
.equ MORSE_TIME_UNIT = 1_000 ; * 100us.
	sbrs	miscBits, MORSE_ACTIVE_bp
	rjmp	isr100us_afterMorse
	movw	tempL, morseCallCntrL
	adiw	tempL, 1
	movw	morseCallCntrL, tempL
	subi	tempL, low(MORSE_TIME_UNIT)
	sbci	tempH, high(MORSE_TIME_UNIT)
	brlo	isr100us_afterMorse
	clr		morseCallCntrL
	clr		morseCallCntrH
	set
	bld		miscBits, MORSE_TICK_bp
isr100us_afterMorse:

isr100us_end:
; Restore modified registers:
	pop		temp0
	xout	CPU_SREG, temp0
	pop		ZH
	pop		ZL
	pop		tempH
	pop		tempL
	pop		temp2
	pop		temp1
	pop		temp0
	reti

; == Routine: Convert register to 2-digits decimal. ==
; Input:	temp0:	Number to be converted, will be destroyed.
; Output:	temp1:	Units.
;			temp2:	Tens or leading zero.
to2digDec:
	ldi		temp2, 0
to2digDec_tens:
	subi	temp0, 10
	brcs	to2digDec_units
	inc		temp2
	rjmp	to2digDec_tens
to2digDec_units:
; temp2 now contains the tens.
	subi	temp0, -10				; Add 10, because the previous loop subtracted 10 once too much.
; temp0 now contains the units.
	mov		temp1, temp0
to2digDec_end:
	ret
