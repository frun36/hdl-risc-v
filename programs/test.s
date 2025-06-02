.section .text
.global _start

_start:
    la a0, str
    li a1, 0x00400000
    li a2, 0x900

copy:
    lbu t0, 0(a0)
    sb t0, 0(a2)
    addi a0, a0, 1
    addi a2, a2, 1
    bne t0, zero, copy

    li a2, 0x900

wait_uart_ready:
    lw t0, 0x10(a1)
    bne t0, zero, wait_uart_ready

    lbu t0, 0(a2)
    beq t0, zero, end
    sb t0, 0x8(a1)
    sb t0, 0x4(a1)
    addi a2, a2, 1
    j wait_uart_ready

end:
    ebreak

.section .rodata
str:
    .asciz "Helou"
