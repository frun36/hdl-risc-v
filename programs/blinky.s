.section .text

.global start

start:
    li      s0, 0
    li      s1, 256
    li      s2, 0x00400004
.L0:
    sb      s0, 0(s2)
    call    wait
    addi    s0, s0, 1
    bne     s0, s1, .L0
.L1:
    nop
    j       .L1

wait:
    li      t0, 1
    slli    t0, t0, 20
.L2:
    addi    t0, t0, -1
    bnez    t0, .L2
    ret

