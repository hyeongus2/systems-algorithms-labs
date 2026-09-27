`timescale 1ns/1ps
module digital_tb;
  reg A,B,C,D,sel;
  wire ma,mb,maj;
  wire [2:0] cnt;
  integer i, expected;
  MUXa m1(A,B,sel,ma);
  MUXb m2(A,B,sel,mb);
  majority m3(A,B,C,maj);
  count1s m4(A,B,C,D,cnt);
  initial begin
    for(i=0;i<32;i=i+1) begin
      {A,B,C,D,sel}=i[4:0]; #1;
      expected = {31'b0,A}+{31'b0,B}+{31'b0,C}+{31'b0,D};
      if(cnt !== expected[2:0]) $fatal(1,"popcount mismatch");
      if(ma !== (sel ? B : A) || mb !== ma) $fatal(1,"mux mismatch");
      if(maj !== ((A&B)|(A&C)|(B&C))) $fatal(1,"majority mismatch");
    end
    $display("32 digital input combinations passed"); $finish;
  end
endmodule
