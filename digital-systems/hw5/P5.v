module P5(
	input						CLK,
	input						RST,
	input	wire	[2-1:0]		XY,
	output	reg		[2-1:0]		Z
);
	parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, E = 3'b100;
	// fill the blank
	reg Diff;
	reg [2:0] S, next_S;
	always @(*) begin
		Diff = (~XY[0] & XY[1]) | (XY[0] & ~XY[1]);
	end
	always @(posedge CLK or posedge RST) begin
		if (RST)
			S <= A;
		else
			S <= next_S;
	end
	always @(*) begin
		case (S)
			A: next_S = Diff ? C : B;
			B: next_S = Diff ? C : D;
			C: next_S = Diff ? E : B;
			D: next_S = Diff ? C : A;
			E: next_S = Diff ? A : B;
            default: next_S = A;
		endcase
	end
	always @(*) begin
		case (S)
			A: Z = Diff ? 2'b10 : 2'b01;
			B: Z = Diff ? 2'b10 : 2'b01;
			C: Z = Diff ? 2'b10 : 2'b01;
			D: Z = Diff ? 2'b10 : 2'b11;
			E: Z = Diff ? 2'b00 : 2'b01;
            default: Z = 2'b00;
		endcase
	end
endmodule
