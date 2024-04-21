; File:			remote-control-panasonic-n2qayb.defs.asm
; Device:		AVR
; Version:		2024-04-05
; Description:	This file defines a table in ROM which associates each byte
;				value (0..255) with an ID which specifies the button meaning,
;				or RC_COMMANDS (the count of IDs) in case the byte is not
;				sent by any button of the remote control.
; Author:		Johannes Fechner
;				https://www.mikrocontroller.net/user/show/jofe

; The first address-like bytes sent by the Kaseikyo remote control:
.equ RC_CONST_0 = $02
.equ RC_CONST_1 = $20
.equ RC_CONST_2 = $80
.equ RC_CONST_3 = $00
; Total count of assigned button IDs:
.equ RC_COMMANDS = 20

rcCmdIdTable:
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db  1,  2,  3,  4,  5,  6,  7,  8,  9,  0, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 12, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 11, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
.db 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20

; Buttons "0".."9" -> 0..9.
;.equ RC_CMD_POWER = 10
.equ RC_CMD_MENU = 11
.equ RC_CMD_INFO = 12
;.equ RC_CMD_PLUS = 13
;.equ RC_CMD_BACK = 14
;.equ RC_CMD_SKIP_LEFT = 15
;.equ RC_CMD_PLAY = 16
;.equ RC_CMD_SKIP_RIGHT = 17
;.equ RC_CMD_MINUS = 18
;.equ RC_CMD_CANCEL = 19
