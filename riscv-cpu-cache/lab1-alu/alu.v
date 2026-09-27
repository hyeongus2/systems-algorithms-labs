`timescale 1ns / 100ps

module ALU(A,B,OP,C,Cout);

	input [15:0]A;
	input [15:0]B;
	input [3:0]OP;
	output [15:0]C;
	output Cout;

	//TODO
	wire [15:0] D;		// 2's complement of B
	reg [15:0] C;		// result of operation
	reg ovf;		// overflow flag

	assign Cout = ovf;
	assign D = ~B + 1;
	
	always @(*) begin
		ovf = 0;

		case(OP)
			4'b0000: begin	// addition
				C = A + B;
				ovf = (~A[15] & ~B[15] & C[15]) | (A[15] & B[15] & ~C[15]);
				end
			4'b0001: begin	// subtraction
				C = A + D;
				ovf = (A[15] ^ B[15]) & (C[15] ^ A[15]);
				end
			4'b0010: // and
				C = A & B;
			4'b0011: // or
				C = A | B;
			4'b0100: // nand
				C = ~(A & B);
			4'b0101: // nor
				C = ~(A | B);
			4'b0110: // xor
				C = A ^ B;
			4'b0111: // xnor
				C = ~(A ^ B);
			4'b1000: // identity
				C = A;
			4'b1001: // not
				C = ~A;
			4'b1010: // logical right shift
				C = A >> 1;
			4'b1011: // arithmetic right shift
				C = $unsigned($signed(A) >>> 1);
			4'b1100: // rotate right
				C = {A[0], A[15:1]};
			4'b1101: // logical left shift
				C = A << 1;
			4'b1110: // arithmetic left shift
				C = A << 1;
			4'b1111: // rotate left
				C = {A[14:0], A[15]};
			default:
				C = 0;
		endcase
	end

endmodule
