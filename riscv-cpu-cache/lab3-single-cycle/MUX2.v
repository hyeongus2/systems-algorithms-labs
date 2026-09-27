module MUX2 (
	input wire [31:0] in0,
	input wire [31:0] in1,
	input wire sel,

	output reg [31:0] out
	);

	always @ (*) begin
		out = sel ? in1 : in0;
	end

endmodule // MUX2
