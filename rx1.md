Here's the MINT Hellschreiber receiver code:

## MINT Hellschreiber Receiver

```mint
// Receiver configuration
[ 0 0 0 0 0 0 0 ] 'B !   // column Buffer (7 pixels)
0 'R !                    // Row index (0-6)
0 'X !                    // raster X position

// Read tone detector (LM567 or comparator on port 2)
:G  // ( -- bit ) Get tone present
  2 /I           // read input port 2
  1 &            // mask bit 0
;

// Store pixel in column buffer
:S  // ( pixel -- ) Store in buffer
  'R @ 'B # !    // buffer[row] = pixel
  'R @ 1 + 'R !  // row++
;

// Display one column to screen/port
:V  // ( -- ) View/display column
  7 (
    i 'B #       // get buffer[i]
    ( $DB )      // if 1: display '█' (0xDB)
    /E ( $20 )   // else: display ' ' (0x20)
    3 /O         // output to display port 3
  )
  $0A 3 /O       // newline
  0 'R !         // reset row counter
  'X @ 1 + 'X !  // increment X position
;

// Receive one pixel (8.16ms timing)
:P  // ( -- )
  G              // get tone state (0 or 1)
  S              // store in buffer
  8 /D           // 8ms pixel time (approx)
  'R @ 7 = (     // if collected 7 pixels
    V            // display column
  )
;

// Main receiver loop
:M
  (              // infinite loop
    P            // receive one pixel
  )
;

// Start receiving
M
```

## Enhanced Version with Goertzel-like Detection

```mint
// Simplified energy detector for 2450Hz
[ 0 0 0 0 0 0 0 ] 'B !   // column buffer
0 'E !                    // Energy accumulator
0 'R !                    // Row counter
0 'X !                    // X position

// Sample and accumulate energy
:A  // ( -- energy ) Accumulate samples
  0 'E !                  // reset energy
  40 (                    // sample ~40 times in 8ms
    2 /I                  // read ADC port
    'E @ + 'E !           // accumulate
    200 /W                // 200us between samples
  )
  'E @                    // return energy
;

// Detect pixel (threshold at 20)
:D  // ( -- bit ) Detect if tone present
  A                       // get energy
  20 >                    // threshold comparison
;

// Receive pixel with detection
:P
  D                       // detect tone (0 or 1)
  'R @ 'B # !            // store in buffer[row]
  'R @ 1 + 'R !          // row++
  'R @ 7 = (             // if row==7
    V                     // display column
    0 'R !               // reset row
  )
;

// Display column
:V
  7 ( i 'B # ( $DB ) /E ( $20 ) 3 /O )
  $0A 3 /O
;

// Main loop
:M ( P ) ;

M
```

## Simple Binary Input Version (Most Practical)

```mint
// Use external tone decoder (LM567 chip on port 2, bit 0)
[ 0 0 0 0 0 0 0 ] 'B !

:R  // ( -- ) Receive and display
  7 (                    // 7 pixels per column
    8 /D                 // 8ms pixel timing
    2 /I 1 &            // read tone detector
    i 'B # !            // buffer[i] = bit
  )
  7 ( i 'B # ( $23 ) /E ( $2E ) 3 /O )  // display # or .
  $0A 3 /O              // newline
;

:M ( R ) ;              // infinite receive loop

M
```

## Hardware Setup Required

**For tone detection, you need:**

1. **LM567 tone decoder IC** - outputs digital high when 2450Hz detected
   - Connect to TEC-1 port 2, bit 0
   - Or use comparator + filter

2. **Simple envelope detector:**
   - Diode + capacitor from antenna
   - Compare to threshold
   - Digital output to port 2

3. **Display options:**
   - Port 3 to serial terminal (shows █ and spaces)
   - Or accumulate in RAM buffer for 2D display
   - Or use TEC-1 LED matrix if available

## Key Differences from Transmitter

- **Timing is critical** - 8.163ms per pixel (simplified to 8ms)
- **Input buffering** - collects 7 pixels before display
- **Simple threshold** - digital input easier than full Goertzel
- **Real-time** - runs continuously, no font lookup needed

The display shows characters forming column-by-column as they're received!

Would you like me to add RAM buffering for a full screen display, or adjust for specific TEC-1 hardware ports?

///////


# How the MINT Hellschreiber Receiver Works

## The Big Picture

**Hellschreiber isn't text decoding - it's rebuilding a FAX image in real-time!**

Think of it like watching someone draw on an Etch-A-Sketch remotely:
- They move left-to-right (columns)
- You see dots appear top-to-bottom in each column
- Letters form as vertical slices appear one by one

## Step-by-Step Process

### 1. **The Transmitter Sends This:**

For letter 'A':
```
Column 0: 0001000 (one dot in middle)
Column 1: 0011100 (three dots)
Column 2: 0100010 (two dots at edges)
... 7 columns total
```

Each bit is sent as:
- **1** = 2450Hz tone for 8ms
- **0** = silence for 8ms

### 2. **Your Hardware Detects:**

```
Antenna → LM567 tone decoder → Digital output (HIGH/LOW)
                2450Hz?           to TEC-1 port 2
```

The LM567 chip outputs:
- **HIGH (1)** when it hears 2450Hz
- **LOW (0)** when silent

### 3. **The MINT Code Samples:**

```mint
:R  // Receive one column
  7 (                    // Loop 7 times (7 pixels = 1 column)
    8 /D                 // Wait 8ms (one pixel time)
    2 /I 1 &            // Read port 2, mask bit 0
    i 'B # !            // Store in buffer[i]
  )
  // ... then display
;
```

**What happens:**
1. Wait 8ms
2. Read the detector: is tone present? (1 or 0)
3. Store that bit in buffer position i
4. Repeat 7 times → now you have one column!

### 4. **Display the Column:**

```mint
7 ( i 'B # ( $23 ) /E ( $2E ) 3 /O )
```

For each of the 7 bits in buffer:
- If `1`: output '#' (solid pixel)
- If `0`: output '.' (blank pixel)
- Send to port 3 (serial terminal)

### 5. **Real-Time Visual Result:**

Your screen shows:

```
First column received:
.
.
.
#        ← this is the 0001000 from column 0 of 'A'
.
.
.

Second column received:
.
.
#
#        ← this is 0011100 from column 1
#
.
.

Third column received:
.
#
.
.        ← this is 0100010 from column 2
.
#
.

... continues ...
```

After all 7 columns are displayed side-by-side, you see:

```
   #     
  ###    
 #   #   
 #   #   
 #####   
 #   #   
 #   #   
```

It's an **'A'**!

## The Timing Dance

**Critical synchronization:**

```
Transmitter:          Receiver:
Send bit 0 (8ms)  →   Wait 8ms, sample → got bit 0
Send bit 1 (8ms)  →   Wait 8ms, sample → got bit 1
Send bit 2 (8ms)  →   Wait 8ms, sample → got bit 2
...
```

Both sides must agree on **8.16ms per pixel** (simplified to 8ms in MINT).

## Buffer Concept

```mint
[ 0 0 0 0 0 0 0 ] 'B !   // Array to hold 7 pixels
```

This is a **vertical slice buffer**:
```
B[0] ← top pixel
B[1] ← 
B[2] ←
B[3] ← middle pixel
B[4] ←
B[5] ←
B[6] ← bottom pixel
```

**Data flow:**
```
Input → Buffer[0-6] → Display vertically → Move right → Repeat
```

## Why This Works Without Decoding

**Traditional digital text:**
- Transmitter: "A" → encode to binary → send bits
- Receiver: receive bits → decode → "A"

**Hellschreiber facsimile:**
- Transmitter: "A" → draw dots → send dots
- Receiver: receive dots → draw dots → looks like "A"

**You're not decoding ASCII - you're literally painting the image dot-by-dot!**

## The Variables Explained

```mint
0 'R !   // Row index (which pixel of 7 we're collecting)
0 'X !   // X position (which column we're on)
```

**Flow:**
1. R starts at 0
2. Sample pixel → store in B[R] → R++
3. When R reaches 7 → display column → R resets to 0
4. X++ (move display cursor right)
5. Repeat forever

## Enhanced Version with Energy Detection

```mint
:A  // Accumulate energy over 8ms
  0 'E !                  
  40 (                    // 40 samples
    2 /I                  // read audio level from ADC
    'E @ + 'E !           // sum it up
    200 /W                // 200us delay = 40×200us = 8ms
  )
  'E @                    // return total energy
;

:D  // Detect if tone present
  A                       // get energy
  20 >                    // is it > threshold?
;
```

This version:
- Reads raw audio (not binary detector)
- Adds up signal strength over 8ms
- If energy > 20 → tone is present (bit = 1)
- More robust to noise than simple binary

## The Magic Moment

When you run `:M`, your TEC-1 becomes a **live teleprinter screen**:

1. Antenna picks up 2450Hz signal
2. MINT samples every 8ms
3. Text appears column by column
4. No character recognition needed!
5. You can even receive backwards text, upside-down, rotated - doesn't matter!

**It's pure visual communication** - like watching a fax machine, but for radio messages from 1929!

Would you like me to explain the transmitter side again, or show how to sync the timing better?

///////

