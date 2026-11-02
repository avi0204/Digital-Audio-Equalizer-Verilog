# 3-Band Digital Audio Equalizer

Verilog implementation of a three-band digital audio equalizer using the
project's original shared-MAC FSM algorithm. The filter processes signed
16-bit audio through cascaded **bass**, **mids**, and **treble** sections.

## Project status

- Original FSM and MAC-based filter algorithm retained
- Bass, mids, and treble coefficients added
- Four-bit gain controls and signed 16-bit saturation included
- Simulation testbench included
- Synthesis results and FPGA hardware validation not yet included

## Architecture

Each input sample passes through these states:

| State | Function |
|---|---|
| `ST_input` | Captures and sign-extends `audio_in` |
| `ST_bass` | Applies the bass section |
| `ST_mids` | Applies the mids section |
| `ST_treble` | Applies the treble section |
| `ST_output` | Clips the result to signed 16-bit range |

The shared MAC evaluates:

```text
mac_out = b1*audio + b2*audio1 - a1*mac_out1 - a2*mac_out2
```

The result is scaled by an arithmetic right shift of 10 bits. A complete
sample requires five clock cycles, so the clock should be at least five times
the audio sample rate.

## Coefficients

The coefficients in `Digital_equalizer.v` use signed Q2.10 scaling, where a
real coefficient is represented as:

```text
fixed_coefficient = real_coefficient * 2^10
```

The current coefficient sets are:

| Band | `b1` / `a1` | `b2` / `a2` | Design point |
|---|---:|---:|---|
| Bass | `-2031` | `1007` | 100 Hz, 48 kHz sample rate |
| Mids | `-1877` | `870` | 1 kHz, 48 kHz sample rate |
| Treble | `-664` | `305` | 8 kHz, 48 kHz sample rate |

The coefficients are declared as Verilog parameters, so they can be replaced
without changing the FSM or MAC datapath.

## Gain controls

| Input | Width | Function |
|---|---:|---|
| `BassLevel` | 4 bits | Bass gain control |
| `MidsLevel` | 4 bits | Mids gain control |
| `TrebleLevel` | 4 bits | Treble gain control |

The original gain-selection case statement maps the supported signed gain
codes to `k_coefficient` values of `0.5`, `0.75`, `1.0`, `1.25`, and `1.5`.
Unsupported values use the unity setting.

## Interface

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
```

`audio_in` and `audio_out` are signed 16-bit audio samples represented by
16-bit vectors. `reset` is sampled synchronously on the rising edge of
`clk`. The design clips positive results to `32767` and negative results to
`-32768` before storing the output.

## Simulation

The testbench is `tb_Digital_equalizer.v`. Compile it with Icarus Verilog:

```sh
iverilog -g2012 -Wall -o /tmp/equalizer_tb \
    Digital_equalizer.v tb_Digital_equalizer.v
vvp /tmp/equalizer_tb
```

The testbench applies zero, positive, negative, and high-amplitude samples,
then changes all three gain controls. It checks that the internal
`filter_out` value does not contain unknown bits.

## Known limitation

The current original RTL contains combinational assignments in the FSM
datapath, including the `ST_treble` path where `audio` is assigned from
`mac_out` while `mac_out` also depends on `audio`. Some simulators may report
unknown values or fail to settle because of this zero-delay combinational
feedback. This README documents the behavior; the original filter algorithm
has intentionally not been redesigned.

## Files

| File | Description |
|---|---|
| `Digital_equalizer.v` | Equalizer RTL |
| `tb_Digital_equalizer.v` | Simulation testbench |
| `README.md` | Project documentation |
