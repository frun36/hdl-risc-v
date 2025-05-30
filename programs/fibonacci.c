#define LEDS 0x00400004
#define UART_DAT 0x00400008
#define UART_CTL 0x00400010

static void uart_send_char(char c) {
  while (*((volatile unsigned *)UART_CTL) != 0)
    ;

  *((volatile char *)UART_DAT) = c;
}

static void uart_print(unsigned x) {
  static const char hex_chars[16] = {'0', '1', '2', '3', '4', '5', '6', '7',
                                     '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};

  for (unsigned i = 8; i > 0; i--) {
    uart_send_char(hex_chars[(x >> ((i - 1) * 4)) & 0xF]);
  }
  uart_send_char('\r');
  uart_send_char('\n');
}

int main() {
  unsigned prev = 0;
  unsigned curr = 1;
  unsigned next = 0;

  volatile unsigned *leds = (volatile unsigned *)LEDS;
  *leds = 0;
  while (1) {
    uart_print(curr);
    *leds = curr;

    next = prev + curr;
    prev = curr;
    curr = next;
    for (unsigned j = 0; j < 1000000; j++)
      __asm__("nop");
  }
}
