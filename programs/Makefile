ASM_SRCS ?= main.s
OBJS := $(patsubst %.s,target/%.o,$(ASM_SRCS))

ASFLAGS := -march=rv32i -mabi=ilp32 -mno-relax
LDFLAGS := -T bram.ld -m elf32lriscv -nostdlib --no-relax

all: target/main.hex

# Create target directory if it doesn't exist
target/:
	mkdir -p target

# Assemble .s → target/.o
target/%.o: %.s | target/
	riscv64-elf-as $(ASFLAGS) $< -o $@

# Link object files to ELF
target/main.elf: $(OBJS)
	riscv64-elf-ld $(OBJS) -o $@ $(LDFLAGS)

# Convert ELF to binary
target/main.bin: target/main.elf
	riscv64-elf-objcopy -O binary $< $@

# Convert binary to hex
target/main.hex: target/main.bin
	python hex.py $< > $@

clean:
	rm -rf target

