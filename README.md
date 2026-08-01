# 3-Band Digital Audio Equalizer (Verilog HDL)

## 📌 Project Overview
This repository contains a Verilog HDL implementation of a **3-Band Digital Audio Equalizer**. The design dynamically processes a 16-bit audio stream across three distinct frequency bands: **Bass**, **Mids**, and **Treble**. 

To optimize FPGA hardware resources, the module employs a **Finite State Machine (FSM)** driven architecture that reuses a single shared **Multiply-Accumulate (MAC)** computation core sequentially across all three filter stages.

---

## 🏗 System Architecture & FSM Workflow

           +----------------------------------+
           |             ST_INPUT             |
           | (Sign-extend 16-bit to 32-bit)   |
           +----------------+-----------------+
                            |
                            v
           +----------------------------------+
           |             ST_BASS              |
           | (Process IIR Bass Filter Coeffs) |
           +----------------+-----------------+
                            |
                            v
           +----------------------------------+
           |             ST_MIDS              |
           | (Process IIR Mids Filter Coeffs) |
           +----------------+-----------------+
                            |
                            v
           +----------------------------------+
           |            ST_TREBLE             |
           | (Process IIR Treble Filter Coeffs|
           +----------------+-----------------+
                            |
                            v
           +----------------------------------+
           |            ST_OUTPUT             |
           |  (Apply Saturation / Overflow)   |
           +----------------------------------+


           ### Key Components

1. **Shared MAC Core:** 
   Computes the IIR difference equation using combinational logic:
   $$\text{mac\_out} = (b_1 \cdot \text{audio}) + (b_2 \cdot \text{audio1}) - (a_1 \cdot \text{mac\_out1}) - (a_2 \cdot \text{mac\_out2})$$

2. **State Machine (`state`):**
   * **`ST_input` (0):** Samples 16-bit `audio_in` and performs sign-extension to 32 bits.
   * **`ST_bass` (1):** Loads Bass filter coefficients ($b_1, b_2, a_1, a_2$) and applies feedback registers.
   * **`ST_mids` (2):** Loads Mids filter coefficients and computes intermediate output.
   * **`ST_treble` (3):** Loads Treble filter coefficients and completes cascaded processing.
   * **`ST_output` (4):** Checks upper and lower bounds for clipping and updates `filter_out`.

3. **Saturation Logic:**
   Prevents binary wraparound distortion during extreme amplitude boosts by clamping signed 16-bit boundaries between `+32767` and `-32768`.

---

## 🔌 Pinout & Interface

### Module Signature
```verilog
module Digital_equalizer(
    input  [15:0] audio_in,
    input  [3:0]  BassLevel,
    input  [3:0]  MidsLevel,
    input  [3:0]  TrebleLevel,
    input         reset,
    input         clk,
    output reg [15:0] audio_out
);

