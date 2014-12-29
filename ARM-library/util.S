.section ".text"

.global util_r0_delay
.global pseud_rand
.global pseud_rand_seeds

//------------------------------------------------------------------
// Counts down until r0 is 0
//------------------------------------------------------------------
util_r0_delay:
    subs r0, #1
    moveq pc, lr
    b util_r0_delay

//------------------------------------------------------------------
// Set the seed values for the PRNG
// Pass them in r0-r3
//------------------------------------------------------------------
pseud_rand_seeds:
	str r0, PRNG_X
	str r1, PRNG_Y
	str r2, PRNG_Z
	str r3, PRNG_W
	mov pc, lr
PRNG_X: .word 83276498
PRNG_Y: .word 38239823
PRNG_Z: .word 37924710
PRNG_W: .word 93847181

//------------------------------------------------------------------
// Get the next pseudo random in r0
//------------------------------------------------------------------
pseud_rand:
	push {r4, r5, lr}
	ldr r0, PRNG_X
	ldr r1, PRNG_Y
	ldr r2, PRNG_Z
	ldr r3, PRNG_W

	mov r4, r0, LSL #11
	eor r4, r4, r0
	eor r4, r4, LSR #8

	str r1, PRNG_X
	str r2, PRNG_Y
	str r3, PRNG_Z

	mov r5, r3, LSR #19
	eor r3, r5

	eor r3, r4

	str r3, PRNG_W
	mov r0, r3
	pop {r4, r5, pc}