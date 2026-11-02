`timescale 1ns / 1ps

// Three cascaded Regalia-Mitra-style second-order EQ sections.
//
// Coefficients are normalized biquad coefficients in signed Q2.14 format.
// The 4-bit controls select -12 dB through +12 dB in 1.6 dB steps:
//     gain_db = -12 + level * 24 / 15
//
// The default design point is 48 kHz: bass = 100 Hz, mids = 1 kHz and
// treble = 8 kHz, with Q = 0.8.  Coefficients are linearly interpolated
// between the -12 dB and +12 dB values so the controls are synthesizable.
// One input sample is accepted every five clocks.
module Digital_equalizer(
    input  [15:0] audio_in,
    input  [3:0]  BassLevel,
    input  [3:0]  MidsLevel,
    input  [3:0]  TrebleLevel,
    input         reset,
    input         clk,
    output reg [15:0] audio_out
);

    localparam [2:0] ST_INPUT  = 3'd0;
    localparam [2:0] ST_BASS  = 3'd1;
    localparam [2:0] ST_MIDS  = 3'd2;
    localparam [2:0] ST_TREBLE = 3'd3;
    localparam [2:0] ST_OUTPUT = 3'd4;

    reg [2:0] state;
    reg signed [31:0] input_sample;
    reg signed [31:0] bass_x1, bass_x2, bass_y1, bass_y2, bass_result;
    reg signed [31:0] mids_x1, mids_x2, mids_y1, mids_y2, mids_result;
    reg signed [31:0] treble_x1, treble_x2, treble_y1, treble_y2, treble_result;

    function automatic signed [17:0] interpolate;
        input signed [17:0] low;
        input signed [17:0] high;
        input [3:0] level;
        reg signed [31:0] span;
        begin
            span = high - low;
            interpolate = low + (span * level) / 15;
        end
    endfunction

    // Endpoint coefficients are generated from the Audio EQ Cookbook
    // peaking-EQ form and quantized to Q2.14.
    function automatic signed [17:0] coeff_b0;
        input [1:0] band;
        input [3:0] level;
        begin
            case (band)
                2'd0: coeff_b0 = interpolate(18'sd16187, 18'sd16583, level);
                2'd1: coeff_b0 = interpolate(18'sd14667, 18'sd18303, level);
                default: coeff_b0 = interpolate(18'sd10014, 18'sd26806, level);
            endcase
        end
    endfunction

    function automatic signed [17:0] coeff_b1;
        input [1:0] band;
        input [3:0] level;
        begin
            case (band)
                2'd0: coeff_b1 = interpolate(-18'sd32239, -18'sd32631, level);
                2'd1: coeff_b1 = interpolate(-18'sd27940, -18'sd31212, level);
                default: coeff_b1 = interpolate(-18'sd7877, -18'sd12888, level);
            endcase
        end
    endfunction

    function automatic signed [17:0] coeff_b2;
        input [1:0] band;
        input [3:0] level;
        begin
            case (band)
                2'd0: coeff_b2 = interpolate(18'sd16055, 18'sd16051, level);
                2'd1: coeff_b2 = interpolate(18'sd13514, 18'sd13178, level);
                default: coeff_b2 = interpolate(18'sd5740, -18'sd1031, level);
            endcase
        end
    endfunction

    function automatic signed [17:0] coeff_a1;
        input [1:0] band;
        input [3:0] level;
        begin
            case (band)
                2'd0: coeff_a1 = interpolate(-18'sd32239, -18'sd32631, level);
                2'd1: coeff_a1 = interpolate(-18'sd27940, -18'sd31212, level);
                default: coeff_a1 = interpolate(-18'sd7877, -18'sd12888, level);
            endcase
        end
    endfunction

    function automatic signed [17:0] coeff_a2;
        input [1:0] band;
        input [3:0] level;
        begin
            case (band)
                2'd0: coeff_a2 = interpolate(18'sd15858, 18'sd16250, level);
                2'd1: coeff_a2 = interpolate(18'sd11797, 18'sd15097, level);
                default: coeff_a2 = interpolate(-18'sd630, 18'sd9392, level);
            endcase
        end
    endfunction

    function automatic signed [31:0] biquad;
        input signed [31:0] x;
        input signed [31:0] x1;
        input signed [31:0] x2;
        input signed [31:0] y1;
        input signed [31:0] y2;
        input [1:0] band;
        input [3:0] level;
        reg signed [63:0] accumulator;
        begin
            accumulator = coeff_b0(band, level) * x
                        + coeff_b1(band, level) * x1
                        + coeff_b2(band, level) * x2
                        - coeff_a1(band, level) * y1
                        - coeff_a2(band, level) * y2;
            biquad = accumulator >>> 14;
        end
    endfunction

    function automatic signed [15:0] saturate;
        input signed [31:0] value;
        begin
            if (value > 32'sd32767)
                saturate = 16'sh7fff;
            else if (value < -32'sd32768)
                saturate = -16'sh8000;
            else
                saturate = value[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state          <= ST_INPUT;
            input_sample   <= 0;
            bass_x1        <= 0;
            bass_x2        <= 0;
            bass_y1        <= 0;
            bass_y2        <= 0;
            bass_result    <= 0;
            mids_x1        <= 0;
            mids_x2        <= 0;
            mids_y1        <= 0;
            mids_y2        <= 0;
            mids_result    <= 0;
            treble_x1      <= 0;
            treble_x2      <= 0;
            treble_y1      <= 0;
            treble_y2      <= 0;
            treble_result  <= 0;
            audio_out      <= 0;
        end else begin
            case (state)
                ST_INPUT: begin
                    input_sample <= $signed({{16{audio_in[15]}}, audio_in});
                    state <= ST_BASS;
                end

                ST_BASS: begin
                    bass_result <= biquad(input_sample, bass_x1, bass_x2,
                                          bass_y1, bass_y2, 2'd0, BassLevel);
                    bass_x2 <= bass_x1;
                    bass_x1 <= input_sample;
                    bass_y2 <= bass_y1;
                    bass_y1 <= biquad(input_sample, bass_x1, bass_x2,
                                      bass_y1, bass_y2, 2'd0, BassLevel);
                    state <= ST_MIDS;
                end

                ST_MIDS: begin
                    mids_result <= biquad(bass_result, mids_x1, mids_x2,
                                          mids_y1, mids_y2, 2'd1, MidsLevel);
                    mids_x2 <= mids_x1;
                    mids_x1 <= bass_result;
                    mids_y2 <= mids_y1;
                    mids_y1 <= biquad(bass_result, mids_x1, mids_x2,
                                      mids_y1, mids_y2, 2'd1, MidsLevel);
                    state <= ST_TREBLE;
                end

                ST_TREBLE: begin
                    treble_result <= biquad(mids_result, treble_x1, treble_x2,
                                            treble_y1, treble_y2, 2'd2, TrebleLevel);
                    treble_x2 <= treble_x1;
                    treble_x1 <= mids_result;
                    treble_y2 <= treble_y1;
                    treble_y1 <= biquad(mids_result, treble_x1, treble_x2,
                                        treble_y1, treble_y2, 2'd2, TrebleLevel);
                    state <= ST_OUTPUT;
                end

                ST_OUTPUT: begin
                    audio_out <= saturate(treble_result);
                    state <= ST_INPUT;
                end

                default: state <= ST_INPUT;
            endcase
        end
    end
endmodule
