module Branch_Comp (
	input wire [31:0] A,
	input wire [31:0] B,
	input wire BrUn,

	output reg BrEq,
	output reg BrLT
	);

	always @ (*) begin
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

		/*
		$display("A = %d", A);
		$display("B = %d", B);
		$display("==========");
		*/

	end

endmodule // Branch_Comp
