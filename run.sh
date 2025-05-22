PROJECTNAME=soc
BOARD=icestick
BOARD_FREQ=12
CPU_FREQ=45
FPGA_VARIANT=hx1k
FPGA_PACKAGE=tq144
VERILOGS=$1
yosys -q -DICE_STICK -DBOARD_FREQ=$BOARD_FREQ -DCPU_FREQ=$CPU_FREQ -p \
    "synth_ice40 -relut -top $PROJECTNAME -json target/$PROJECTNAME.json" $VERILOGS  || exit
nextpnr-ice40 --force --timing-allow-fail --json target/$PROJECTNAME.json --pcf $BOARD.pcf --asc target/$PROJECTNAME.asc --freq $CPU_FREQ --$FPGA_VARIANT --package $FPGA_PACKAGE --pcf-allow-unconstrained --opt-timing || exit
icetime -p $BOARD.pcf -P $FPGA_PACKAGE -r target/$PROJECTNAME.timings -d hx1k -t target/$PROJECTNAME.asc
icepack target/$PROJECTNAME.asc target/$PROJECTNAME.bin || exit
iceprog target/$PROJECTNAME.bin || exit
echo DONE.

