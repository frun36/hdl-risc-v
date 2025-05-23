.section .text

.global start

start:
    li      a0, 0 
    li      s1, 16
.L0:
    call    wait
    addi    a0, a0, 1
    bne     a0, s1, .L0


