module Pipeline_REG (
	// CLK, RSTn
	input wire CLK,
	input wire RSTn,

	//input wire Stall,
	input wire Load_Delay,
	input wire Flush,
	input wire Cache_Latency,

	// Stage
	input wire [2:0] stage,

	output reg [2:0] ostage,

	// Control path
	input wire PCSel,
	input wire [2:0] ImmSel,
	input wire RF_WE,
	input wire BrUn,
	input wire [2:0] func3,
	input wire ASel,
	input wire BSel,
	input wire [3:0] ALUOp,
	input wire [3:0] D_MEM_BE,
	input wire D_MEM_WEN,
	input wire [2:0] WBSel,

	output reg oPCSel,
	output reg [2:0] oImmSel,
	output reg oRF_WE,
	output reg oBrUn,
	output reg [2:0] ofunc3,
	output reg oASel,
	output reg oBSel,
	output reg [3:0] oALUOp,
	output reg [3:0] oD_MEM_BE,
	output reg oD_MEM_WEN,
	output reg [2:0] oWBSel,

	// Data path
	input wire [11:0] PC,
	input wire [31:0] PC_plus_4,
	input wire [31:0] instr,
	input wire [4:0] RF_RA1,
	input wire [4:0] RF_RA2,
	input wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	input wire [31:0] Imm,
	input wire [31:0] result,
	input wire [31:0] D_MEM_DI,

	output reg [11:0] oPC,
	output reg [31:0] oPC_plus_4,
	output reg [31:0] oinstr,
	output reg [4:0] oRF_RA1,
	output reg [4:0] oRF_RA2,
	output reg [4:0] oRF_WA1,
	output reg [31:0] oRF_RD1,
	output reg [31:0] oRF_RD2,
	output reg [31:0] oImm,
	output reg [31:0] oresult,
	output reg [31:0] oD_MEM_DI
	);

	// Stage
	reg [2:0] istage;

	assign istage = stage;

	// Control path
	reg iPCSel;
	reg [2:0] iImmSel;
	reg iRF_WE;
	reg iBrUn;
	reg [2:0] ifunc3;
	reg iASel;
	reg iBSel;
	reg [3:0] iALUOp;
	reg [3:0] iD_MEM_BE;
	reg iD_MEM_WEN;
	reg [2:0] iWBSel;

	assign iPCSel = PCSel;
	assign iImmSel = ImmSel;
	assign iRF_WE = RF_WE;
	assign iBrUn = BrUn;
	assign ifunc3 = func3;
	assign iASel = ASel;
	assign iBSel = BSel;
	assign iALUOp = ALUOp;
	assign iD_MEM_BE = D_MEM_BE;
	assign iD_MEM_WEN = D_MEM_WEN;
	assign iWBSel = WBSel;

	// Data path
	reg [11:0] iPC;
	reg [31:0] iPC_plus_4;
	reg [31:0] iinstr;
	reg [4:0] iRF_RA1;
	reg [4:0] iRF_RA2;
	reg [4:0] iRF_WA1;
	reg [31:0] iRF_RD1;
	reg [31:0] iRF_RD2;
	reg [31:0] iImm;
	reg [31:0] iresult;
	reg [31:0] iD_MEM_DI;

	assign iPC = PC;
	assign iPC_plus_4 = PC_plus_4;
	assign iinstr = instr;
	assign iRF_RA1 = RF_RA1;
	assign iRF_RA2 = RF_RA2;
	assign iRF_WA1 = RF_WA1;
	assign iRF_RD1 = RF_RD1;
	assign iRF_RD2 = RF_RD2;
	assign iImm = Imm;
	assign iresult = result;
	assign iD_MEM_DI = D_MEM_DI;

	parameter IF = 3'b000, ID = 3'b001, EX = 3'b010, MEM = 3'b011, WB = 3'b100, BUB = 3'b101;

	// Sequential circuit
	always @ (posedge CLK) begin
		if (RSTn) begin
			if (Cache_Latency) begin	// When cache hit/miss occurs
				if (istage == MEM) begin
					// Stage
					ostage <= BUB;
				end
				else begin
					if (istage == IF)
						ostage <= ID;	// Doing nothing
					else if (istage == ID)
						ostage <= EX;
					else if (istage == EX)
						ostage <= MEM;
					else if (istage == BUB)
						ostage <= BUB;
					else
						ostage <= 3'bx;
				end
			end
			else if (Load_Delay) begin	// When load delay occurs
				if (istage == IF) begin
					ostage <= ID;	// Doing nothing
				end
				else if (istage == ID) begin
					// Stage
					ostage <= BUB;

					// Control path
					oPCSel <= 1'bx;
					oImmSel <= 3'bx;
					oRF_WE <= 1'bx;
					oBrUn <= 1'bx;
					ofunc3 <= 3'bx;
					oASel <= 1'bx;
					oBSel <= 1'bx;
					oALUOp <= 4'bx;
					oD_MEM_BE <= 4'bx;
					oD_MEM_WEN <= 1'bx;
					oWBSel <= 3'bx;

					// Data path
					oPC <= 12'bx;
					oPC_plus_4 <= 32'bx;
					oinstr <= 32'bx;
					oRF_RA1 <= 5'b11111;	// Unknown register
					oRF_RA2 <= 5'b11111;
					oRF_WA1 <= 5'bx;
					oRF_RD1 <= 32'bx;
					oRF_RD2 <= 32'bx;
					oImm <= 32'bx;
					oresult <= 32'bx;
					oD_MEM_DI <= 32'bx;
				end
				else begin
					// Stage
					if (istage == EX)
						ostage <= MEM;
					else if (istage == MEM)
						ostage <= WB;
					else if (istage == BUB)
						ostage <= BUB;
					else
						ostage <= 3'bx;

					// Control path
					oPCSel <= iPCSel;
					oImmSel <= iImmSel;
					oRF_WE <= iRF_WE;
					oBrUn <= iBrUn;
					ofunc3 <= ifunc3;
					oASel <= iASel;
					oBSel <= iBSel;
					oALUOp <= iALUOp;
					oD_MEM_BE <= iD_MEM_BE;
					oD_MEM_WEN <= iD_MEM_WEN;
					oWBSel <= iWBSel;

					// Data path
					oPC <= iPC;
					oPC_plus_4 <= iPC_plus_4;
					oinstr <= iinstr;
					oRF_RA1 <= iRF_RA1;
					oRF_RA2 <= iRF_RA2;
					oRF_WA1 <= iRF_WA1;
					oRF_RD1 <= iRF_RD1;
					oRF_RD2 <= iRF_RD2;
					oImm <= iImm;
					oresult <= iresult;
					oD_MEM_DI <= iD_MEM_DI;
				end
			end
			else if (Flush) begin	// When flush occurs
				if ((istage == EX) || (istage == MEM) || (istage == BUB)) begin
					// Stage
					if (istage == EX)
						ostage <= MEM;
					else if (istage == MEM)
						ostage <= WB;
					else if (istage == BUB)
						ostage <= BUB;
					else
						ostage <= 3'bx;

					// Control path
					oPCSel <= iPCSel;
					oImmSel <= iImmSel;
					oRF_WE <= iRF_WE;
					oBrUn <= iBrUn;
					ofunc3 <= ifunc3;
					oASel <= iASel;
					oBSel <= iBSel;
					oALUOp <= iALUOp;
					oD_MEM_BE <= iD_MEM_BE;
					oD_MEM_WEN <= iD_MEM_WEN;
					oWBSel <= iWBSel;

					// Data path
					oPC <= iPC;
					oPC_plus_4 <= iPC_plus_4;
					oinstr <= iinstr;
					oRF_RA1 <= iRF_RA1;
					oRF_RA2 <= iRF_RA2;
					oRF_WA1 <= iRF_WA1;
					oRF_RD1 <= iRF_RD1;
					oRF_RD2 <= iRF_RD2;
					oImm <= iImm;
					oresult <= iresult;
					oD_MEM_DI <= iD_MEM_DI;
				end
				else begin
					// Stage
					if ((istage == IF) || (istage == ID))
						ostage <= BUB;
					else
						ostage <= 3'bx;

					// Control path
					oPCSel <= 1'bx;
					oImmSel <= 3'bx;
					oRF_WE <= 1'bx;
					oBrUn <= 1'bx;
					ofunc3 <= 3'bx;
					oASel <= 1'bx;
					oBSel <= 1'bx;
					oALUOp <= 4'bx;
					oD_MEM_BE <= 4'bx;
					oD_MEM_WEN <= 1'bx;
					oWBSel <= 3'bx;

					// Data path
					oPC <= 12'bx;
					oPC_plus_4 <= 32'bx;
					oinstr <= 32'bx;
					oRF_RA1 <= 5'b11111;	// Unknown register
					oRF_RA2 <= 5'b11111;
					oRF_WA1 <= 5'bx;
					oRF_RD1 <= 32'bx;
					oRF_RD2 <= 32'bx;
					oImm <= 32'bx;
					oresult <= 32'bx;
					oD_MEM_DI <= 32'bx;
				end
			end
			else begin		// Normal state
				// Stage
				if (istage == IF)
					ostage <= ID;
				else if (istage == ID)
					ostage <= EX;
				else if (istage == EX)
					ostage <= MEM;
				else if (istage == MEM)
					ostage <= WB;
				else if (istage == BUB)
					ostage <= BUB;
				else
					ostage <= 3'bx;

				// Control path
				oPCSel <= iPCSel;
				oImmSel <= iImmSel;
				oRF_WE <= iRF_WE;
				oBrUn <= iBrUn;
				ofunc3 <= ifunc3;
				oASel <= iASel;
				oBSel <= iBSel;
				oALUOp <= iALUOp;
				oD_MEM_BE <= iD_MEM_BE;
				oD_MEM_WEN <= iD_MEM_WEN;
				oWBSel <= iWBSel;

				// Data path
				oPC <= iPC;
				oPC_plus_4 <= iPC_plus_4;
				oinstr <= iinstr;
				oRF_RA1 <= iRF_RA1;
				oRF_RA2 <= iRF_RA2;
				oRF_WA1 <= iRF_WA1;
				oRF_RD1 <= iRF_RD1;
				oRF_RD2 <= iRF_RD2;
				oImm <= iImm;
				oresult <= iresult;
				oD_MEM_DI <= iD_MEM_DI;
			end
		end
	end

endmodule // Pipeline_REG
