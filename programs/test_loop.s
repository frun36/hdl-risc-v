.section .text

.global start

start:
    li      a0, 0
    li      s1, 16
    li      s0, 0
.L0:
    lb      a1, 400(s0)
    sb      a1, 800(s0)
    call    wait
    addi    s0, s0, 1
    bne     s0, s1, .L0

    li      s0, 0
.L1:
    lb      a0, 800(s0)
    call    wait
    addi    s0, s0, 1
    bne     s0, s1, .L1

wait:
    li      t0, 1
    slli    t0, t0, 17
.L2:
    addi    t0, t0, -1
    bnez    t0, .L2
    ret
