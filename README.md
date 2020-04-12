# Binary-Fusion

<p align="center">
  <img width="380" height="243" src="https://raw.githubusercontent.com/Far117/Binary-Fusion/master/image.png">
</p>

This program was inspired by those doors which require two people with two different keys to open. Alone, each key is useless, and a perfect understanding of a single key won't help much when it comes to opening the door.

The program splits files in half, bit-by-bit. It alternates between giving the first bit of the input file to the "left" output file and the second bit of the input file to the "right" output file, with the third going back to the left, the fourth to the right, and so on until the input has been completely exhausted. The two halves are then completely unintelligible alone, and must be put back together before the file makes sense again.

### File Format
The output files have a one-byte header:

The first bit is `1` for the left file, and `0` for the right.

If an input file had an odd number of bytes, it won't be possible to split it in half evenly: there will be one nibble left over. If this is the case, then the second bit will be `1`.

The third and fourth bits are reserved for future use.

If the second bit was `0`, then the rest of the bits in this byte will also be `0`, and the data will start at the second byte. Otherwise, the remaining nibble will be the first nibble of data.