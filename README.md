# TEC-1 Hellschreiber 
...see wiki

Hellschreiber is a machine-readable teleprinter communication that uses a combination of on and off dots to represent characters, similar to the way Morse code uses dots and dashes. It was invented in the 1920s and was commonly used in the 1930s and 1940s for telegraph communication. Instead of printing the characters on a sheet of paper, Hellschreiber displays the characters on a screen, making it a form of visual telegraphy. It was used in both point-to-point communication and for broadcasting messages over radio waves.

![](https://github.com/SteveJustin1963/tec-HELL/blob/master/pics/350px-Feldhell.jpg)

![](https://github.com/SteveJustin1963/tec-HELL/raw/master/pics/300px-Hellschreiber-schriftbild.gif)

![image](https://user-images.githubusercontent.com/58069246/213037768-53a5574c-3fd0-4efa-a273-16e327fc0925.png)


 
 



 
A walk you through how to **actually** implement a Feld-Hell transmitter in code — 

---

### The Core Idea (Tech View)

Hellschreiber isn’t text — it’s **facsimile**.  
Each character is a **7×7 pixel bitmap** (49 bits total).  
We **serialize one column at a time**, left-to-right, top-to-bottom.  
Each pixel = **tone on (1) or off (0)** for a fixed time slice.

> **Timing**: 245 baud ≈ 8.16 ms per pixel → 57 ms per column → 400 ms per character.

---

### Pseudocode — Real Implementation

```pseudocode
// Global: 7x7 font table (1 = pixel on, 0 = off)
Font[128] → 7×7 bitmatrix

Function SendHellschreiber(String msg):
    For each char c in msg:
        bitmap = Font[c]                  // 7 rows × 7 cols

        For col = 0 to 6:                 // Transmit column-by-column
            For row = 0 to 6:             // Scan top → bottom
                If bitmap[row][col] == 1:
                    Tone_ON(2450 Hz)      // or print "█"
                Else:
                    Tone_OFF()            // or print " "
                Delay(8.16 ms)            // One pixel time
            EndFor
            Delay(2 ms)                   // Small inter-column gap
        EndFor

        Silence(50 ms)                    // Character spacing
    EndFor
EndFunction
```

---

### Console Visualization (Debug Mode)

If you’re printing to screen (not modulating):

```pseudocode
For col = 0 to 6:
    For row = 0 to 6:
        Print bitmap[row][col] ? "█" : " "
    Print newline
Print "  "  // two-space letter gap
```

Output for `"A"`:

```
   █   
  ███  
 █   █ 
 █   █ 
 █████ 
 █   █ 
 █   █ 

   █   
  ███  
 █   █ 
 █   █ 
 █████ 
 █   █ 
 █   █ 
```

Each block = one **transmitted column**.

---

### Font Storage (Real Example)

```c
// C-style: packed bitmatrix (7 cols × 7 rows)
uint8_t Font['A'] = {
    0b0001000,  // col0
    0b0011100,  // col1
    0b0100010,  // col2
    0b0100010,  // col3
    0b0111110,  // col4
    0b0100010,  // col5
    0b0100010   // col6
};
```

Bit 6 = top row, bit 0 = bottom.

---

### Signal Chain (Radio View)

```
Text → Font Lookup → 7×7 Bitmap → Column Serializer → 
Pixel Timing (8.16ms) → 2450 Hz OOK → Antenna
```

- **OOK** = On-Off Keying (FSK with f2 = silence)
- Sync via **start pulse** or free-run (receiver aligns on energy)

---

### Pro Tips (From the Bench)

1. **Add dither**: randomize pixel timing ±1ms → reduces birdies.
2. **Pre-warp font**: slant columns 1px right for “italic” look (classic Feld-Hell).
3. **Double height**: use 14 rows (2px per scan line) → sharper text.
4. **Sync pulse**: send 1225 Hz for 100ms before message.

---

### One-Liner for Testing (Python)

```python
def hell_print(s): 
    [print(''.join('█ '[Font[c][r][col]] for r in range(7)), '\n  ', end='') 
     for c in s.upper() for col in range(7)]
```

---

That’s it. No ASCII hacks, no 8×8 confusion — just **real Hellschreiber**, the way Rudolf Hell built it in 1929.


