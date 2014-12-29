.section ".text"

.global util_r0_delay

//------------------------------------------------------------------
util_r0_delay:
    push {r0}
util_r0_delay_loop:
    subs r0, #1
    bne util_r0_delay_loop
    pop {r0}
    mov     pc, lr

//------------------------------------------------------------------
