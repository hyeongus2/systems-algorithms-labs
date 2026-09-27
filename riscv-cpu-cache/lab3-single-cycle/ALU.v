module ALU (
	input wire [3:0] ALUOp,
	input wire [31:0] A,
	input wire [31:0] B,

	output reg [31:0] result
	);

	reg [2:0] func3;
	reg func7;

	assign func3 = ALUOp[2:0];
	assign func7 = ALUOp[3];

	always @ (*) begin
		case(func3)
			3'h0: begin // ADD or SUB
				if (func7 == 0)	// ADD
					result = A + B;
				else		// SUB
					result = A - B;
			end
			3'h4: // XOR or IS_EVEN
				if (func7 == 0) // XOR
					result = A ^ B;
				else		// IS_EVEN
					result = (A % 2 == 0) ? 1 : 0;
			3'h6: // OR or MULT
				if (func7 == 0) // OR
					result = A | B;
				else		// MULT
					result = A * B;
			3'h7: // AND or MODULO
				if (func7 == 0) // AND
					result = A & B;
				else		// MODULO
					result = A % B;
			3'h1: // SLL
				result = A << B[4:0];
			3'h5: begin // SRL or SRA
				if (func7 == 0) // SRL
					result = A >> B[4:0];
				else		// SRA
					result = $unsigned($signed(A) >>> B[4:0]);
			end
			3'h2: // SLT
				result = ($signed(A) < $signed(B)) ? 1 : 0;
			3'h3: // SLTU
				result = ($unsigned(A) < $unsigned(B)) ? 1 : 0;
		    default: result = 32'b0;
		endcase

		/*
		$display("A = %d", A);
		$display("B = %d", B);
		$display("result = %d", result);
		$display("==========");
		*/

	end

endmodule // ALU
