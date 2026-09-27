module Forwarding_Unit (
	input wire [4:0] RF_RA1_ID,
	input wire [4:0] RF_RA2_ID,
	input wire [4:0] RF_RA1_EX,
	input wire [4:0] RF_RA2_EX,
	input wire [2:0] ImmSel_ID,
	input wire [2:0] ImmSel_EX,
	input wire [4:0] RF_WA1_EX,
	input wire [4:0] RF_WA1_MEM,
	input wire [4:0] RF_WA1_WB,
	input wire RF_WE_MEM,
	input wire RF_WE_WB,

	output reg Forward1_MEM,
	output reg Forward1_WB,
	output reg Forward2_MEM,
	output reg Forward2_WB,
	output reg Forward1_After,
	output reg Forward2_After,
	output reg Load_Delay
	);

	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110, JRtype = 3'b111;

	reg use_RA1_ID;
	reg use_RA2_ID;
	reg use_RA1_EX;
	reg use_RA2_EX;

	assign use_RA1_ID = (ImmSel_ID != Jtype) && (RF_RA1_ID != 5'b00000) && (RF_RA1_ID != 5'b11111);
	assign use_RA2_ID = ((ImmSel_ID == Rtype) || (ImmSel_ID == Stype) || (ImmSel_ID == Btype)) && (RF_RA2_ID != 5'b00000) && (RF_RA2_ID != 5'b11111);
	assign use_RA1_EX = (ImmSel_EX != Jtype) && (RF_RA1_EX != 5'b00000) && (RF_RA1_EX != 5'b11111);
	assign use_RA2_EX = ((ImmSel_EX == Rtype) || (ImmSel_EX == Stype) || (ImmSel_EX == Btype)) && (RF_RA2_EX != 5'b00000) && (RF_RA2_EX != 5'b11111);

	always @ (*) begin
		Forward1_MEM = 0;
		Forward1_WB = 0;
		Forward2_MEM = 0;
		Forward2_WB = 0;
		Forward1_After = 0;
		Forward2_After = 0;
		Load_Delay = 0;

		if (use_RA1_EX && (RF_RA1_EX == RF_WA1_MEM) && (RF_WE_MEM == 1))
			Forward1_MEM = 1;
		else if (use_RA1_EX && (RF_RA1_EX == RF_WA1_WB) && (RF_WE_WB == 1))
			Forward1_WB = 1;

		if (use_RA2_EX && (RF_RA2_EX == RF_WA1_MEM) && (RF_WE_MEM == 1))
			Forward2_MEM = 1;
		else if (use_RA2_EX && (RF_RA2_EX == RF_WA1_WB) && (RF_WE_WB == 1))
			Forward2_WB = 1;

		if (use_RA1_ID && (RF_RA1_ID == RF_WA1_WB) && (RF_WE_WB == 1))
			Forward1_After = 1;

		if (use_RA2_ID && (RF_RA2_ID == RF_WA1_WB) && (RF_WE_WB == 1))
			Forward2_After = 1;

		if (use_RA1_ID && (RF_RA1_ID == RF_WA1_EX) && (ImmSel_EX == Ltype))
			Load_Delay = 1;
		else if (use_RA2_ID && (RF_RA2_ID == RF_WA1_EX) && (ImmSel_EX == Ltype))
			Load_Delay = 1;
	end

endmodule // Forwarding_Unit
