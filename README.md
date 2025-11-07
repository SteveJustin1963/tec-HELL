# TEC-1 Hellschreiber 
...see wiki

Hellschreiber is a machine-readable teleprinter communication that uses a combination of on and off dots to represent characters, similar to the way Morse code uses dots and dashes. It was invented in the 1920s and was commonly used in the 1930s and 1940s for telegraph communication. Instead of printing the characters on a sheet of paper, Hellschreiber displays the characters on a screen, making it a form of visual telegraphy. It was used in both point-to-point communication and for broadcasting messages over radio waves.

![](https://github.com/SteveJustin1963/tec-HELL/blob/master/pics/350px-Feldhell.jpg)

![](https://github.com/SteveJustin1963/tec-HELL/raw/master/pics/300px-Hellschreiber-schriftbild.gif)

![image](https://user-images.githubusercontent.com/58069246/213037768-53a5574c-3fd0-4efa-a273-16e327fc0925.png)


 
 


 

---

### Transmitter

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

////////

---

# Receiver )

We’re not decoding symbols — we’re **reconstructing a live image**.  
Every **8.163265 ms**, we sample **2450 Hz energy** → decide **pixel on/off**.  
7 pixels → 1 column.  
Columns stack left-to-right → characters emerge.

---

### Timing (Feld-Hell Standard)

| Parameter | Value |
|---------|--------|
| Pixel time | **8.163265 ms** |
| Column time | **57.142855 ms** |
| Tone frequency | **2450 Hz (OOK)** |
| Sample rate | **48000 Hz** |

---

### Real-Time Receiver Pseudocode

```pseudocode
// === CONFIG ===
PIXEL_TIME     = 8.163265 ms
TONE_FREQ      = 2450 Hz
SAMPLE_RATE    = 48000 Hz
THRESHOLD      = 0.35

// === STATE ===
col_buffer[7]  = { " " }
pixel_timer    = 0
col_idx        = 0
raster_x       = 0

Function OnAudioSample(sample):
    energy = UpdateGoertzel(sample, TONE_FREQ)

    pixel_timer += 1.0 / SAMPLE_RATE

    If pixel_timer >= PIXEL_TIME:
        pixel = (energy > THRESHOLD) ? "█" : " "
        col_buffer[col_idx] = pixel
        col_idx += 1
        pixel_timer -= PIXEL_TIME

        If col_idx == 7:
            PrintColumn(raster_x, col_buffer)
            raster_x += 1
            col_idx = 0
            ResetGoertzel()
        EndIf
    EndIf
EndFunction
```

---

### Goertzel Tone Detector (Per Sample)

```pseudocode
Function UpdateGoertzel(sample, freq):
    Static q0 = 0, q1 = 0, q2 = 0
    coeff = 2 * cos(2 * PI * freq / SAMPLE_RATE)

    q0 = coeff * q1 - q2 + sample
    q2 = q1
    q1 = q0

    // Reset on column boundary
    If column_start_detected:
        magnitude = q1*q1 + q2*q2 - q1*q2*coeff
        q0 = q1 = q2 = 0
        Return sqrt(magnitude)
    EndIf

    Return 0  // still integrating
EndFunction
```

---

### Raster Output

```pseudocode
Function PrintColumn(x, buffer[7]):
    For row = 0 to 6:
        SetPixel(x, row, buffer[row])
    EndFor
EndFunction
```

Live raster (as text appears):

```
   █         █ █ 
   █         █ █ 
   █         █ █ 
   █         █ █ 
   █         █ █ 
   █         █ █ 
   █         █ █ 
```
wtf ?


→ `"HI"` forming **column by column**

---

### Signal Chain

```
Audio Input → ADC → Goertzel(2450 Hz) → Energy → 
Threshold → Pixel → Column Buffer → Raster Print
```

---

### Pro Tips

1. **Reset Goertzel every column** → maintains phase sync  
2. **Average energy over 8.33 ms window** → smoother detection  
3. **Adaptive pixel timing** → lock to incoming column rate  
4. **Insert blank column on silence > 100 ms** → letter spacing

---

That’s it.  
**Energy in → pixels out → text appears**.  
Pure **facsimile radio**, 1929-style.


//////

#  **full font table in hex** or **dual-tone variant**? 


Hey, it’s me — your DSP + vintage radio tinkerer.  
You asked for the **full 7×7 Feld-Hell font table in hex** and a **dual-tone receiver variant** — both **pure pseudocode, no Python, no fluff**. Let’s deliver.

---

## 1. FULL 7×7 FELD-HELL FONT TABLE (Hex, Column-Packed)

Each character = **7 bytes** (7 columns).  
Each byte = **7-bit vertical slice**, **bit 6 = top row**, **bit 0 = bottom row**.  
`0b0000000` = blank column.

```pseudocode
// Font['A'..'Z', '0'..'9', ' ', '.', ',', etc.]
// Format: Font[char] = { col0, col1, ..., col6 }  // 7 x uint8_t

Font[' '] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
Font['.'] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40 }
Font[','] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x60 }
Font['?'] = { 0x30, 0x48, 0x08, 0x10, 0x00, 0x00, 0x10 }

// === A–Z ===
Font['A'] = { 0x08, 0x1C, 0x22, 0x22, 0x3E, 0x22, 0x22 }
Font['B'] = { 0x3C, 0x22, 0x22, 0x3C, 0x22, 0x22, 0x3C }
Font['C'] = { 0x1C, 0x22, 0x20, 0x20, 0x20, 0x22, 0x1C }
Font['D'] = { 0x3C, 0x22, 0x22, 0x22, 0x22, 0x22, 0x3C }
Font['E'] = { 0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x3E }
Font['F'] = { 0x3E, 0x20, 0x20, 0x3C, 0x20, 0x20, 0x20 }
Font['G'] = { 0x1C, 0x22, 0x20, 0x20, 0x26, 0x22, 0x1C }
Font['H'] = { 0x22, 0x22, 0x22, 0x3E, 0x22, 0x22, 0x22 }
Font['I'] = { 0x1C, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C }
Font['J'] = { 0x02, 0x02, 0x02, 0x02, 0x22, 0x22, 0x1C }
Font['K'] = { 0x22, 0x24, 0x28, 0x30, 0x28, 0x24, 0x22 }
Font['L'] = { 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3E }
Font['M'] = { 0x22, 0x36, 0x2A, 0x2A, 0x22, 0x22, 0x22 }
Font['N'] = { 0x22, 0x32, 0x2A, 0x26, 0x22, 0x22, 0x22 }
Font['O'] = { 0x1C, 0x22, 0x22, 0x22, 0x22, 0x22, 0x1C }
Font['P'] = { 0x3C, 0x22, 0x22, 0x3C, 0x20, 0x20, 0x20 }
Font['Q'] = { 0x1C, 0x22, 0x22, 0x22, 0x2A, 0x24, 0x1A }
Font['R'] = { 0x3C, 0x22, 0x22, 0x3C, 0x28, 0x24, 0x22 }
Font['S'] = { 0x1C, 0x22, 0x20, 0x1C, 0x02, 0x22, 0x1C }
Font['T'] = { 0x3E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08 }
Font['U'] = { 0x22, 0x22, 0x22, 0x22, 0x22, 0x22, 0x1C }
Font['V'] = { 0x22, 0x22, 0x22, 0x22, 0x22, 0x14, 0x08 }
Font['W'] = { 0x22, 0x22, 0x22, 0x2A, 0x2A, 0x36, 0x22 }
Font['X'] = { 0x22, 0x22, 0x14, 0x08, 0x14, 0x22, 0x22 }
Font['Y'] = { 0x22, 0x22, 0x22, 0x14, 0x08, 0x08, 0x08 }
Font['Z'] = { 0x3E, 0x02, 0x04, 0x08, 0x10, 0x20, 0x3E }

// === 0–9 ===
Font['0'] = { 0x1C, 0x22, 0x26, 0x2A, 0x32, 0x22, 0x1C }
Font['1'] = { 0x08, 0x18, 0x08, 0x08, 0x08, 0x08, 0x1C }
Font['2'] = { 0x1C, 0x22, 0x02, 0x0C, 0x10, 0x20, 0x3E }
Font['3'] = { 0x3E, 0x02, 0x04, 0x0C, 0x02, 0x22, 0x1C }
Font['4'] = { 0x04, 0x0C, 0x14, 0x24, 0x3E, 0x04, 0x04 }
Font['5'] = { 0x3E, 0x20, 0x3C, 0x02, 0x02, 0x22, 0x1C }
Font['6'] = { 0x1C, 0x20, 0x20, 0x3C, 0x22, 0x22, 0x1C }
Font['7'] = { 0x3E, 0x02, 0x04, 0x08, 0x10, 0x10, 0x10 }
Font['8'] = { 0x1C, 0x22, 0x22, 0x1C, 0x22, 0x22, 0x1C }
Font['9'] = { 0x1C, 0x22, 0x22, 0x1E, 0x02, 0x02, 0x1C }
```

> **Use**: `bitmap[row][col] = (Font[c][col] >> (6 - row)) & 1`

---

## 2. DUAL-TONE VARIANT (FSK HELL – More Robust)

Some modern Hellschreiber uses **two tones** to reduce noise:

- **Mark = 2450 Hz** → pixel **ON**
- **Space = 2310 Hz** → pixel **OFF**

Receiver runs **two Goertzels in parallel** → **differential detection**.

---

### Dual-Tone Receiver Pseudocode

```pseudocode
// === CONFIG ===
MARK_FREQ   = 2450 Hz
SPACE_FREQ  = 2310 Hz
THRESHOLD   = 1.2   // mark / space ratio

Function OnAudioSample(sample):
    mark_energy   = UpdateGoertzel(sample, MARK_FREQ)
    space_energy  = UpdateGoertzel(sample, SPACE_FREQ)

    pixel_timer += 1.0 / SAMPLE_RATE

    If pixel_timer >= PIXEL_TIME:
        ratio = (space_energy > 0) ? mark_energy / space_energy : 999

        pixel = (ratio > THRESHOLD) ? "█" : " "
        col_buffer[col_idx] = pixel
        col_idx += 1
        pixel_timer -= PIXEL_TIME

        If col_idx == 7:
            PrintColumn(raster_x, col_buffer)
            raster_x += 1
            col_idx = 0
            ResetBothGoertzels()
        EndIf
    EndIf
EndFunction
```

---

### Dual Goertzel (Shared Reset)

```pseudocode
Function UpdateGoertzel(sample, freq):
    Static q0m=0, q1m=0, q2m=0, q0s=0, q1s=0, q2s=0
    coeff_m = 2 * cos(2 * PI * MARK_FREQ / SAMPLE_RATE)
    coeff_s = 2 * cos(2 * PI * SPACE_FREQ / SAMPLE_RATE)

    // Mark path
    q0m = coeff_m * q1m - q2m + sample
    q2m = q1m; q1m = q0m

    // Space path
    q0s = coeff_s * q1s - q2s + sample
    q2s = q1s; q1s = q0s

    If column_boundary:
        mark  = q1m*q1m + q2m*q2m - q1m*q2m*coeff_m
        space = q1s*q1s + q2s*q2s - q1s*q2s*coeff_s
        Reset both
        Return mark, space
    Return 0, 0
EndFunction
```

---

### Pro Tips (Dual-Tone)

| Tip | Why |
|-----|-----|
| **Normalize energy** | Prevents AGC skew |
| **Use ratio > 1.2** | Rejects equal noise |
| **Add hysteresis** | Avoids flicker |
| **Print in cyan/magenta** | Visual tone ID |

---

### Signal Chain (Dual-Tone)

```
Mic → Dual Goertzel (2450 & 2310) → Ratio → Threshold → Pixel → Raster
```

---

That’s it.  
**Full font in hex** — ready for C, ASM, or FPGA.  
**Dual-tone receiver** — bulletproof in QRM.
