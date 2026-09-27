module Branch_Comp (
	input wire [31:0] A,
	input wire [31:0] B,
	input wire BrUn,
	input wire [2:0] func3,

	output reg PCSel
	);

	reg BrEq;
	reg BrLT;

	always @ (*) begin
		PCSel = 0;

		if (A == B) begin
			BrEq = 1;
			BrLT = 0;
		end
		else begin
			BrEq = 0;

			if (BrUn == 0) begin
				if ($signed(A) < $signed(B))
					BrLT = 1;
				else
					BrLT = 0;
			end
			else begin
				if ($unsigned(A) < $unsigned(B))
					BrLT = 1;
				else
					BrLT = 0;
			end
		end

		case(func3)
			3'h0: PCSel = (BrEq) ? 1 : 0;	// BEQ
			3'h1: PCSel = (BrEq) ? 0 : 1;	// BNE
			3'h4: PCSel = (BrLT) ? 1 : 0;	// BLT
			3'h5: PCSel = (BrLT) ? 0 : 1;	// BGE
			3'h6: PCSel = (BrLT) ? 1 : 0;	// BLTU
			3'h7: PCSel = (BrLT) ? 0 : 1;	// BGEU
			default: PCSel = 0;
		endcase

		/*
		if (PCSel == 0) begin
			$display("not taken");
			//PCSel = 1;
		end
		*/

	end

endmodule // Branch_Comp
