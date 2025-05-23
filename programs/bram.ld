MEMORY
{
   BRAM (RWX) : ORIGIN = 0x0000, LENGTH = 0x1800
}
SECTIONS
{
    everything :
    {
	. = ALIGN(4);
	target/main.o (.text)
        *(.*)
    } >BRAM
}
