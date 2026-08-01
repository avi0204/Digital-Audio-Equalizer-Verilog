3-Band Digital Audio Equalizer (Verilog HDL)
📌 Project Overview
This repository contains a Verilog HDL implementation of a 3-Band Digital Audio Equalizer. The design dynamically processes a 16-bit audio stream across three distinct frequency bands: Bass, Mids, and Treble.  
PDF
+ 2

To optimize FPGA hardware resources, the module employs a Finite State Machine (FSM) driven architecture that reuses a single shared Multiply-Accumulate (MAC) computation core sequentially across all three filter stages.  
PDF
+ 1

🏗 System Architecture & FSM Workflow
               +----------------------------------+
               |             ST_INPUT             |
               | (Sign-extend 16-bit to 32-bit)   |
               +----------------+-----------------+
                                |
                                v
               +----------------------------------+
               |             ST_BASS              |
               | (Process IIR Bass Filter Coefficients)|
               +----------------+-----------------+
                                |
                                v
               +----------------------------------+
               |             ST_MIDS              |
               | (Process IIR Mids Filter Coefficients)|
               +----------------+-----------------+
                                |
                                v
               +----------------------------------+
               |            ST_TREBLE             |
               | (Process IIR Treble Filter Coeffs)|
               +----------------+-----------------+
                                |
                                v
               +----------------------------------+
               |            ST_OUTPUT             |
               |  (Apply Saturation / Overflow)   |
               +----------------------------------+
Key Components
Shared MAC Core:
Computes the IIR difference equation using combinational logic:
  
Unknown

mac_out=(b 
1
​
 ⋅audio)+(b 
2
​
 ⋅audio1)−(a 
1
​
 ⋅mac_out1)−(a 
2
​
 ⋅mac_out2)
  
Unknown

State Machine (state):

ST_input (0): Samples 16-bit audio_in and performs sign-extension to 32 bits.  
Unknown

ST_bass (1): Loads Bass filter coefficients (b 
1
​
 ,b 
2
​
 ,a 
1
​
 ,a 
2
​
 ) and applies feedback registers.  
Unknown

ST_mids (2): Loads Mids filter coefficients and computes intermediate output.  
Unknown

ST_treble (3): Loads Treble filter coefficients and completes cascaded processing.  
Unknown

ST_output (4): Checks upper and lower bounds for clipping and updates filter_out.  
Unknown

Saturation Logic:
Prevents binary wraparound distortion during extreme amplitude boosts by clamping signed 16-bit boundaries between +32767 and -32768.  
Unknown

🔌 Pinout & Interface
Module Signature
Verilog
module Digital_equalizer(
    input  [15:0] audio_in,
    input  [3:0]  BassLevel,
    input  [3:0]  MidsLevel,
    input  [3:0]  TrebleLevel,
    input         reset,
    input         clk,
    output reg [15:0] audio_out
);
Signal Descriptions
Port Name	Direction	Bit Width	Description
clk	Input	1	
System clock signal  
Unknown

reset	Input	1	
Active-high synchronous reset signal  
Unknown

audio_in	Input	16	
2's complement audio input sample  
Unknown

BassLevel	Input	4	
Control register for low-frequency gain  
Unknown

MidsLevel	Input	4	
Control register for mid-frequency gain  
Unknown

TrebleLevel	Input	4	
Control register for high-frequency gain  
Unknown

audio_out	Output	16	
Filtered and saturated 16-bit audio output  
Unknown

🚀 Getting Started & Simulation
Prerequisites
Synthesis / Simulation: Xilinx Vivado, ModelSim, or Icarus Verilog (iverilog)  
PDF

Waveform Viewer: GTKWave or Vivado Logic Analyzer

Running Simulation via Icarus Verilog
Bash
# Compile Verilog design and testbench
iverilog -o equalizer_tb Digital_equalizer.v Digital_equalizer_tb.v

# Execute simulation
vvp equalizer_tb

# View output waveforms
gtkwave equalizer_tb.vcd
🛠 Future Enhancements
Incorporate coefficient lookup tables (LUTs) mapped dynamically to BassLevel, MidsLevel, and TrebleLevel inputs.

Expand fixed-point precision for a 
k
​
  / b 
k
​
  scaling constants to reduce quantization noise.
