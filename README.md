# 3-Band Digital Audio Equalizer (Verilog HDL)

> **Status: functional RTL reference design.** Simulation and synthesis-specific integration may still be added.

A Verilog HDL implementation of a 3-band digital audio equalizer. It processes a 16-bit audio stream across three frequency bands (**Bass**, **Mids**, **Treble**) using three cascaded IIR sections. An FSM sequences one sample through the bass, mids, treble, and output stages.

## Status

- [x] FSM-based architecture with three cascaded filter sections
- [x] Output saturation to signed 16-bit range
- [x] Testbench and simulation results
- [x] Coefficient derivation and documentation
- [ ] Synthesis results (LUTs, DSPs, Fmax)
- [ ] FPGA hardware demo

## Architecture

### FSM workflow

```text
        +--------------------------------------+
        |              ST_INPUT                |
        |  Sample audio_in, sign-extend to 32b |
        +------------------+-------------------+
                           |
                           v
        +--------------------------------------+
        |              ST_BASS                 |
        |  Load bass coefficients, run MAC     |
        +------------------+-------------------+
                           |
                           v
        +--------------------------------------+
        |              ST_MIDS                 |
        |  Load mids coefficients, run MAC     |
        +------------------+-------------------+
                           |
                           v
        +--------------------------------------+
        |              ST_TREBLE               |
        |  Load treble coefficients, run MAC   |
        +------------------+-------------------+
                           |
                           v
        +--------------------------------------+
        |              ST_OUTPUT               |
        |  Saturate and update audio_out       |
        +--------------------------------------+
```

| State | Value | Description |
|-------|-------|-------------|
| `ST_INPUT`  | 0 | Samples 16-bit `audio_in` and sign-extends it to 32 bits. |
| `ST_BASS`   | 1 | Loads bass coefficients (b1, b2, a1, a2) and updates feedback registers. |
| `ST_MIDS`   | 2 | Loads mids coefficients and computes the intermediate output. |
| `ST_TREBLE` | 3 | Loads treble coefficients and completes the cascaded processing. |
| `ST_OUTPUT` | 4 | Checks upper and lower bounds, clips if needed, and updates the output. |

One sample takes at least 5 clock cycles, so the clock must run at least 5x the audio sample rate. **TODO:** state the target sample rate and clock frequency.

### Cascaded biquad sections

Each section evaluates the IIR difference equation:

```text
mac_out = (b1 * audio) + (b2 * audio1) - (a1 * mac_out1) - (a2 * mac_out2)
```

where `x[n-1]` and `x[n-2]` are the previous two section inputs and
`y[n-1]` and `y[n-2]` are the previous two section outputs. The three
sections use independent histories and coefficient sets.

### Saturation

To avoid wraparound distortion on large boosts, the result is clamped to the signed 16-bit range, `-32768` to `+32767`, before being written to `audio_out`.

### Fixed-point format

Coefficients use signed Q2.14 fixed point. Each section uses the normalized
second-order equation:

```text
y[n] = (b0*x[n] + b1*x[n-1] + b2*x[n-2]
        - a1*y[n-1] - a2*y[n-2]) / 2^14
```

The internal samples and accumulator are signed 32-bit and 64-bit values,
respectively. The current implementation is a Regalia-Mitra-style cascade of
three peaking sections. The nominal sample rate is 48 kHz, with center
frequencies of 100 Hz, 1 kHz, and 8 kHz and Q = 0.8.

## Interface

```verilog
module Digital_equalizer(
    input  [15:0] audio_in,     // signed 16-bit audio sample
    input  [3:0]  BassLevel,    // 4-bit bass gain control
    input  [3:0]  MidsLevel,    // 4-bit mids gain control
    input  [3:0]  TrebleLevel,  // 4-bit treble gain control
    input         reset,
    input         clk,
    output reg [15:0] audio_out // signed 16-bit equalized output
);
```

| Port | Width | Description |
|------|-------|-------------|
| `audio_in`    | 16 | Signed input sample. |
| `BassLevel`   | 4  | Bass gain: level 0 = -12 dB, level 15 = +12 dB. |
| `MidsLevel`   | 4  | Mid gain: level 0 = -12 dB, level 15 = +12 dB. |
| `TrebleLevel` | 4  | Treble gain: level 0 = -12 dB, level 15 = +12 dB. |
| `reset`       | 1  | Synchronous active-high reset for all filter history and output. |
| `clk`         | 1  | System clock. |
| `audio_out`   | 16 | Signed equalized output, saturated. |

## Simulation and synthesis

The output for an input sample is available five rising edges after the
sample is accepted. Therefore the clock must be at least five times the audio
sample rate; for 48 kHz audio, use a clock of at least 240 kHz. A sample is
accepted in `ST_INPUT`, then processed by bass, mids, and treble sections
before the saturated result is written in `ST_OUTPUT`.

With Icarus Verilog installed, run the smoke test with:

```sh
iverilog -g2012 -o equalizer_tb Digital_equalizer.v tb_Digital_equalizer.v
vvp equalizer_tb
```
