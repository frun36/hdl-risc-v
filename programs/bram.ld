MEMORY
{
   PROGROM (RX) : ORIGIN = 0x00000, LENGTH = 0x00800
   DATARAM (RW) : ORIGIN = 0x00800, LENGTH = 0x00800
}
SECTIONS {

    .text : {
        . = ALIGN(4);
        target/main.o (.text)
        *(.text*)
    } > PROGROM

    .data : {
	. = ALIGN(4);
        *(.data*)          
        *(.sdata*)
        *(.rodata*) 
        *(.srodata*)
        *(.bss*)
        *(.sbss*)
	
        *(COMMON)
        *(.eh_frame)  
        *(.eh_frame_hdr)
        *(.init_array*)         
        *(.gcc_except_table*)  
    } > DATARAM
}
