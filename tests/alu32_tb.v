`timescale 1ns/1ps
module alu32_tb;
  reg [31:0] A,B;
  reg [3:0] ALUOp;
  wire [31:0] result;
`ifdef MULTICYCLE
  ALU dut(.A(A),.B(B),.ALUOp(ALUOp),.stage(3'b010),.isAdder(1'b0),.result(result));
`else
  ALU dut(.A(A),.B(B),.ALUOp(ALUOp),.result(result));
`endif
  task check;
    input [31:0] a,b,expected;
    input [3:0] op;
    begin
      A=a; B=b; ALUOp=op; #1;
      if(result !== expected) $fatal(1,"ALU32 mismatch");
    end
  endtask
  initial begin
    check(32'h80000000,1,32'hc0000000,4'hd);
    check(32'h80000000,33,32'h40000000,4'h5);
    check(1,32,1,4'h1);
    check(3,4,7,4'h0);
    check(3,4,32'hffffffff,4'h8);
    check(32'hffffffff,0,1,4'h2);
    $display("ALU32 checks passed"); $finish;
  end
endmodule
