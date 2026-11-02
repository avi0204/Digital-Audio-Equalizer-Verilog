`timescale 1ns / 1ps

module tb_Digital_equalizer;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg [15:0] audio_in = 16'd0;
    reg [3:0] BassLevel = 4'd7;
    reg [3:0] MidsLevel = 4'd7;
    reg [3:0] TrebleLevel = 4'd7;
    wire [15:0] audio_out;

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

    task send_sample;
        input signed [15:0] sample;
        begin
            @(negedge clk);
            audio_in = sample;
            repeat (5) @(posedge clk);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        reset = 1'b0;
        send_sample(16'sd1000);
        send_sample(16'sd0);
        send_sample(-16'sd1000);
        send_sample(16'sd0);
        if (^audio_out === 1'bx)
            $fatal(1, "audio_out contains X");
        $display("Equalizer smoke test passed, final output = %0d", $signed(audio_out));
        $finish;
    end
endmodule
