with open('target/main.bin', 'rb') as f_in, open('target/prog_rom.mem', 'w') as rom, open('target/data_ram.mem', 'w') as data:
    for i in range(0x00200):
        word = f_in.read(4)
        if len(word) == 0:
            print("No data section")
            exit(0)
        if len(word) < 4:
            word = word + b'\x00' * (4 - len(word))
        # reverse bytes for little-endian to big-endian conversion
        swapped = word[::-1]
        print(swapped.hex(), file=rom)
    while True:
        word = f_in.read(4)
        if len(word) == 0:
            break
        if len(word) < 4:
            word = word + b'\x00' * (4 - len(word))
        # reverse bytes for little-endian to big-endian conversion
        swapped = word[::-1]
        print(swapped.hex(), file=data)
