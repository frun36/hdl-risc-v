.section .data
str:
    .byte 'D', 'U', 'P', 'A', '\r', '\n', 0

.section .text

.global start

start:
    li      s0, 0x00400008 # UART_DAT
    li      s1, 0x00400010 # UART_CTL
    li      s2, 0x00400004 # LED
    la      a0, str
led_off:
    sb      zero, 0(s2)

wait_uart_ready:
    lw      t0, 0(s1)
    bne     t0, zero, wait_uart_ready

    li      t0, (1 << 4)
    sb      t0, 0(s2)

    lb      t0, 0(a0)
    sb      t0, 0(s0)
    addi    a0, a0, 1
    beq     t0, zero, start
    j       led_off

