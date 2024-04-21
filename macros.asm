; File: macros.asm

#define ROUND(X) (int(1.0*(X)+0.5))
#define FLOOR(X) (int(X))
#define CEIL(X) (frac(X) > 0 ? int(X)+1 : int(X))

.macro xout ; eXtended "out"
	.if @0 > 0x3F
		sts @0, @1
	.else
		out @0, @1
	.endif
.endmacro

.macro xin ; eXtended "in"
	.if @1 > 0x3F
		lds @0, @1
	.else
		in  @0, @1
	.endif
.endmacro

.macro ldiz ; Load immediate into Z double register.
	ldi		ZH, high(@0)
	ldi		ZL, low(@0)
.endmacro

.macro addz ; Add register to Z double register; register 'reg00' must be cleared.
	add 	ZL, @0
	adc		ZH, reg00
.endmacro

.macro addi16 ; RdH, RdL, k
	subi    @1, low(-@2)
	sbci    @0, high(-@2)
.endmacro
