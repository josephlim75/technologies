## Convert to encoded text

    xxd -p output.bin > input.txt

## Convert to Binary

    xxd -r -p input.txt output.bin
    echo "hex" | xxd -r -p - 
    echo "hex" | sha256sum | xxd -r -p -