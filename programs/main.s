.section .text

.global start

start:
    li      a0, 0 
    li      s1, 16
.L0:
    call    wait
    addi    a0, a0, 1
    bne     a0, s1, .L0


wait:
    li      t0, 1
    slli    t0, t0, 19
.L2:
    addi    t0, t0, -1
    bnez    t0, .L2
    ret

