module Imm_Gen (
	input wire [2:0] ImmSel,
	input wire [31:0] instr,

	output reg [31:0] Imm
	);

	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110;

	always @ (*) begin
		case(ImmSel)
			Itype: Imm = {{21{instr[31]}}, instr[30:20]};
			Ltype: Imm = {{21{instr[31]}}, instr[30:20]};	// Ltype(Load instr.) is actually a kind of an Itype.
			Stype: Imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
			Btype: Imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
			Utype: Imm = {instr[31:12], {12{1'b0}}};
			Jtype: Imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
			default: Imm = 0;	// Rtype doesn't need an immediate.
		endcase
	end

endmodule // Imm_Gen
