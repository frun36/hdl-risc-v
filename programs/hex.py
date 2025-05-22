with open('target/main.bin', 'rb') as f_in:
    while True:
        word = f_in.read(4)
        if len(word) == 0:
            break
        if len(word) < 4:
            word = b'\x00' * (4 - len(word)) + word
        # reverse bytes for little-endian to big-endian conversion
        swapped = word[::-1]
        print(swapped.hex())
