`timescale 1ns / 1ps

module Digital_equalizer(
input [15:0]audio_in,
input [3:0]BassLevel,
input [3:0]MidsLevel,
input [3:0]TrebleLevel,
input reset,
input clk,
output reg [15:0]audio_out
    );
    
   reg [31:0]audio;
   wire [31:0]mac_out;
   wire [39:0] raw_mac;
   reg[31:0]mac_out1,mac_out2,audio1,bassh,midsh,trebleh;
   reg[11:0]b1,b2,a1,a2;
   reg signed [11:0] k_coefficient; 
   reg [2:0] gain_input;

   
   parameter bassb1 = -12'sd2031;
   parameter bassb2 =  12'sd1007;
   parameter bassa1 = -12'sd2031;
   parameter bassa2 =  12'sd1007;
   
   parameter midsb1 = -12'sd1877;
   parameter midsb2 =  12'sd870;
   parameter midsa1 = -12'sd1877;
   parameter midsa2 =  12'sd870;
   
   parameter trebleb1 = -12'sd664;
   parameter trebleb2 =  12'sd305;
   parameter treblea1 = -12'sd664;
   parameter treblea2 =  12'sd305;

   assign raw_mac = (((12'h400 + k_coeffcient)/2)*audio) + ((12'h400 -k_coefficient)/2)*(b1*audio + b2*audio1 - a1*mac_out1 - a2*mac_out2);
   assign mac_out = raw_mac >>> 10;
   
   reg[31:0]filter_out;
   
   reg [3:0] state, next_state;
   parameter  ST_input = 0, ST_bass = 1, ST_mids = 2, ST_treble = 3, ST_output = 4;
   reg [31:0]bass1, bass2, mids1, mids2, treble1, treble2;
   
   always@(*)begin
   case(state)
   ST_input: begin
             next_state <= ST_bass;
             audio <= {{16{audio_in[15]}},audio_in};
             end
   ST_bass: begin
             b1 = bassb1; b2 = bassb2; a1 = bassa1; a2 = bassa2;
             next_state = ST_mids;
             mac_out1 = bass1;
             mac_out2 = mac_out1; 
             audio1 = bassh;
             gain_input = BassLevel;
            end      
            
   ST_mids: begin
             b1 = midsb1; b2 = midsb2; a1 = midsa1; a2 = midsa2;
             next_state = ST_treble;
             mac_out1 = mids1;
             mac_out2 = mac_out1;
             audio1 = midsh;
             gain_input = MidsLevel;
            end
            
    ST_treble: begin
             b1 = trebleb1; b2 = trebleb2; a1 = treblea1; a2 = treblea2;
             next_state = ST_output;
             audio = mac_out;
             treble1 = mac_out;
             treble2 = treble1;
             mac_out1 = treble1;
             mac_out2 = mac_out1;
             audio1 = midsh;
             gain_input=TrebleLevel;
            end    
            
    ST_output: begin
               next_state = ST_input;
               end
     default: next_state = ST_input;                           
   endcase
   
   case (gain_input)
              3'sd-2: k_coefficient = 12'h200; // 0.5
              3'sd-1: k_coefficient = 12'h300; // 0.75
              3'sd0:  k_coefficient = 12'h400; // 1.0
              3'sd1:  k_coefficient = 12'h500; // 1.25
              3'sd2:  k_coefficient = 12'h600; // 1.5
              3'sd-4: k_coefficient = 12'h200; 
              3'sd-3: k_coefficient = 12'h200;
              3'sd3:  k_coefficient = 12'h600;
              default: k_coefficient = 12'h400;
          endcase
          
   end 
      
   always@(posedge clk) begin
   if(reset)begin
   state <= ST_input;
   audio1 <= 0; 
   mac_out1 <=0;
   mac_out2<=0; 
   bassh<=0; 
   midsh<=0;
   trebleh<=0;
   end
   else begin
   state <= next_state;
   case(state)
   ST_input: begin
             audio <= {{16{audio_in[15]}},audio_in};
             end
   ST_bass: begin
             audio <= mac_out;
             bass1 <= mac_out;
             bass2 <= bass1;
             mac_out1 <= bass1;
             mac_out2 <= mac_out1; 
             audio1 <= bassh;
             bassh<= audio;
            end      
            
   ST_mids: begin
             audio <= mac_out;
             mids1 <= mac_out;
             mids2 <= mids1;
             mac_out1 <= mids1;
             mac_out2 <= mac_out1;
             audio1 <= midsh;
             midsh<= audio;
            end
            
    ST_treble: begin
             audio <= mac_out;
             treble1 <= mac_out;
             treble2 <= treble1;
             mac_out1 <= treble1;
             mac_out2 <= mac_out1;
             audio1 <= midsh;
             trebleh<= audio;
            end    
            
    ST_output: begin;
               if(mac_out[25:10] >= 16'd32767)
                   filter_out <=  16'd32767;
                   else if(mac_out[25:10] <= -16'sd32768)
                   filter_out <= -16'd32678;
                   else
                    filter_out <= mac_out[25:10];
               end
     default: next_state<=ST_input;                           
   endcase
   end
   end
   
endmodule
