.section .text

.global _start

_start:
    li      a0, 0
    li      a1, 0x900
    li      a2, 0xffff
    sb      a2, 0(a2)
    lbu     a0, 0(a2)
    addi    a0, a0, 1
    addi    a0, a0, 1
    addi    a0, a0, 1
    ebreak
