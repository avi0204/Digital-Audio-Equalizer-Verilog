`timescale 1ns / 1ps

module tb_Digital_equalizer;
    reg clk;
    reg reset;
    reg [15:0] audio_in;
    reg [3:0] BassLevel;
    reg [3:0] MidsLevel;
    reg [3:0] TrebleLevel;
    wire [15:0] audio_out;
    integer failures;

    Digital_equalizer dut (
        .audio_in(audio_in),
        .BassLevel(BassLevel),
        .MidsLevel(MidsLevel),
        .TrebleLevel(TrebleLevel),
        .reset(reset),
        .clk(clk),
        .audio_out(audio_out)
    );

    always #5 clk = ~clk;

    task check_sample;
        input signed [15:0] sample;
        begin
            @(negedge clk);
            audio_in = sample;

            repeat (5) @(posedge clk);
            #1;

            if (^dut.filter_out === 1'bx) begin
                $display("FAIL: filter_out is unknown for input %0d", sample);
                failures = failures + 1;
            end else begin
                $display("PASS: input=%0d filter_out=%0d",
                         sample, $signed(dut.filter_out));
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        audio_in = 16'sd0;
        BassLevel = 4'd0;
        MidsLevel = 4'd0;
        TrebleLevel = 4'd0;
        failures = 0;

        repeat (2) @(posedge clk);
        reset = 1'b0;

        check_sample(16'sd0);
        check_sample(16'sd0);
        check_sample(16'sd0);
        check_sample(16'sd1000);
        check_sample(-16'sd1000);

        BassLevel = 4'd2;
        MidsLevel = 4'd2;
        TrebleLevel = 4'd2;
        check_sample(16'sd16000);

        if (failures != 0)
            $fatal(1, "Equalizer test failed: %0d failure(s)", failures);

        $display("Equalizer test passed.");
        $finish;
    end
endmodule
