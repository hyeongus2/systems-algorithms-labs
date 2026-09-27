`timescale 1ns/1ps
module alu16_tb;
  reg [15:0] A, B;
  reg [3:0] OP;
  wire [15:0] C;
  wire Cout;
  ALU dut(A,B,OP,C,Cout);
  task check;
    input [15:0] a,b,expected;
    input [3:0] op;
    input overflow;
    begin
      A=a; B=b; OP=op; #1;
      if (C !== expected || Cout !== overflow) $fatal(1,"ALU16 mismatch");
    end
  endtask
  initial begin
    check(16'h0000,16'h8000,16'h8000,4'h1,1'b1);
    check(16'h8000,16'h8000,16'h0000,4'h1,1'b0);
    check(16'h7fff,16'h0001,16'h8000,4'h0,1'b1);
    check(16'hffff,16'h0001,16'h0000,4'h0,1'b0);
    check(16'h8000,16'h0000,16'hc000,4'hb,1'b0);
    $display("ALU16 checks passed"); $finish;
  end
endmodule
