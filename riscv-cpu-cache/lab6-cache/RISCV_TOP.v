module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,
	output reg [31:0] NUM_INST,
	output wire [31:0] OUTPUT_PORT
	);

	// TODO: implement pipeline CPU
	assign OUTPUT_PORT = RF_WD;

	initial begin
		NUM_INST <= 0;
	end

	// stage
	reg [2:0] stage;
	reg [2:0] nextStage;
	parameter IF = 3'b000, ID = 3'b001, EX = 3'b010, MEM = 3'b011, WB = 3'b100, BUB = 3'b101;
	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110, JRtype = 3'b111;

	///////////////////////////////////////////////////
	// Variables
	// IF
	reg [11:0] PC;
	wire [31:0] nextPC;
	wire [31:0] PC_plus_4;
	reg [31:0] instr;

	// IF_ID
	wire [2:0] stage_ID;
	wire [11:0] PC_IF;
	wire [11:0] PC_ID;
	wire [31:0] PC_plus_4_IF;
	wire [31:0] PC_plus_4_ID;
	wire [31:0] instr_IF;
	wire [31:0] instr_ID;

	// ID
	wire BrUn;
	wire BrEq;
	wire BrLT;

	// ID_EX
	wire [2:0] stage_EX;
	wire PCSel_ID;
	wire PCSel_EX_buffer;
	wire PCSel_EX;
	wire [2:0] ImmSel_ID;
	wire [2:0] ImmSel_EX;
	wire RF_WE_ID;
	wire RF_WE_EX;
	wire BrUn_ID;
	wire BrUn_EX;
	wire [2:0] func3_ID;
	wire [2:0] func3_EX;
	wire ASel_ID;
	wire ASel_EX;
	wire BSel_ID;
	wire BSel_EX;
	wire [3:0] ALUOp_ID;
	wire [3:0] ALUOp_EX;
	wire [3:0] D_MEM_BE_ID;
	wire [3:0] D_MEM_BE_EX;
	wire D_MEM_WEN_ID;
	wire D_MEM_WEN_EX;
	wire [2:0] WBSel_ID;
	wire [2:0] WBSel_EX;

	wire [11:0] PC_EX;
	wire [31:0] PC_plus_4_EX;
	wire [31:0] instr_EX;
	wire [4:0] RF_RA1_ID;
	wire [4:0] RF_RA1_EX;
	wire [4:0] RF_RA2_ID;
	wire [4:0] RF_RA2_EX;
	wire [4:0] RF_WA1_ID;
	wire [4:0] RF_WA1_EX;
	wire [31:0] RF_RD1_ID;
	wire [31:0] RF_RD1_EX_buffer;
	wire [31:0] RF_RD1_EX;
	wire [31:0] RF_RD2_ID;
	wire [31:0] RF_RD2_EX_buffer;
	wire [31:0] RF_RD2_EX;
	wire [31:0] Imm_ID;
	wire [31:0] Imm_EX;

	// EX
	wire PCSel_Branch;
	wire [1:0] ASel;
	wire [1:0] BSel;
	wire [31:0] A;
	wire [31:0] B;

	// EX_MEM
	wire [2:0] stage_MEM;
	wire PCSel_MEM;
	wire [2:0] ImmSel_MEM;
	wire RF_WE_MEM;
	wire [3:0] D_MEM_BE_MEM;
	wire D_MEM_WEN_MEM;
	wire [2:0] WBSel_MEM;

	wire [11:0] PC_MEM;
	wire [31:0] PC_plus_4_MEM;
	wire [31:0] instr_MEM;
	wire [4:0] RF_RA1_MEM;
	wire [4:0] RF_RA2_MEM;
	wire [4:0] RF_WA1_MEM;
	wire [31:0] RF_RD2_MEM;
	wire [31:0] result_EX;
	wire [31:0] result_MEM;
	wire [31:0] D_MEM_DI_MEM;

	// MEM
	wire [31:0] READ_HIT_COUNT;
	wire [31:0] READ_MISS_COUNT;
	wire [31:0] WRITE_HIT_COUNT;
	wire [31:0] WRITE_MISS_COUNT;

	// MEM_WB
	wire [2:0] stage_WB;
	wire PCSel_WB;
	wire RF_WE_WB;
	wire [2:0] WBSel_WB;

	wire [11:0] PC_WB;
	wire [31:0] PC_plus_4_WB;
	wire [4:0] RF_RA1_WB;
	wire [4:0] RF_RA2_WB;
	wire [4:0] RF_WA1_WB;
	wire [31:0] result_WB;
	wire [31:0] D_MEM_DI_WB;

	// WB

	// etc.
	reg [31:0] RF_WD_After;
	reg rHALT;
	wire Foward1_MEM;
	wire Foward1_WB;
	wire Foward2_MEM;
	wire Foward2_WB;
	wire Forward1_After;
	wire Forward2_After;
	wire Load_Delay;
	reg Stall;
	wire Flush;
	wire Cache_Latency;
	wire [31:0] temp;	// store garbage values

	///////////////////////////////////////////////////
	// Relationship between variables
	// IF
	assign I_MEM_ADDR = PC;
	assign instr = I_MEM_DI;
	assign PC_plus_4 = {{20{1'b0}}, PC} + 4;

	// IF_ID
	assign PC_IF = PC;
	assign PC_plus_4_IF = PC_plus_4;
	assign instr_IF = instr;

	Pipeline_REG if_id (
		.CLK(CLK),
		.RSTn(RSTn),
		.Load_Delay(Load_Delay),
		.Flush(Flush),
		.Cache_Latency(Cache_Latency),

		.stage(IF),
		.PCSel(1'bx),
		.ImmSel(3'bx),
		.RF_WE(1'bx),
		.BrUn(1'bx),
		.func3(3'bx),
		.ASel(1'bx),
		.BSel(1'bx),
		.ALUOp(4'bx),
		.D_MEM_BE(4'bx),
		.D_MEM_WEN(1'bx),
		.WBSel(3'bx),

		.ostage(stage_ID),
		.oPCSel(temp[0]),
		.oImmSel(temp[2:0]),
		.oRF_WE(temp[0]),
		.oBrUn(temp[0]),
		.ofunc3(temp[2:0]),
		.oASel(temp[0]),
		.oBSel(temp[0]),
		.oALUOp(temp[3:0]),
		.oD_MEM_BE(temp[3:0]),
		.oD_MEM_WEN(temp[0]),
		.oWBSel(temp[2:0]),

		.PC(PC_IF),
		.PC_plus_4(PC_plus_4_IF),
		.instr(instr_IF),
		.RF_RA1(5'bx),
		.RF_RA2(5'bx),
		.RF_WA1(5'bx),
		.RF_RD1(32'bx),
		.RF_RD2(32'bx),
		.Imm(32'bx),
		.result(32'bx),
		.D_MEM_DI(32'bx),

		.oPC(PC_ID),
		.oPC_plus_4(PC_plus_4_ID),
		.oinstr(instr_ID),
		.oRF_RA1(temp[4:0]),
		.oRF_RA2(temp[4:0]),
		.oRF_WA1(temp[4:0]),
		.oRF_RD1(temp),
		.oRF_RD2(temp),
		.oImm(temp),
		.oresult(temp),
		.oD_MEM_DI(temp)
	);

	// ID
	assign RF_RA1 = instr_ID[19:15];
	assign RF_RA2 = instr_ID[24:20];
	assign RF_WA1_ID = instr_ID[11:7];
	assign func3_ID = instr_ID[14:12];

	CTRL ctrl (
		.RSTn(RSTn),
		.instr(instr_ID),
		.PCSel(PCSel_ID),
		.ImmSel(ImmSel_ID),
		.RF_WE(RF_WE_ID),
		.BrUn(BrUn_ID),
		.ASel(ASel_ID),
		.BSel(BSel_ID),
		.ALUOp(ALUOp_ID),
		.D_MEM_BE(D_MEM_BE_ID),
		.D_MEM_WEN(D_MEM_WEN_ID),
		.WBSel(WBSel_ID)
	);

	Imm_Gen imm_gen (
		.ImmSel(ImmSel_ID),
		.instr(instr_ID),
		.Imm(Imm_ID)
	);

	// ID_EX
	assign RF_RA1_ID = RF_RA1;
	assign RF_RA2_ID = RF_RA2;
	assign RF_RD1_ID = (Forward1_After) ? RF_WD_After : RF_RD1;
	assign RF_RD2_ID = (Forward2_After) ? RF_WD_After : RF_RD2;

	Pipeline_REG id_ex (
		.CLK(CLK),
		.RSTn(RSTn),
		.Load_Delay(Load_Delay),
		.Flush(Flush),
		.Cache_Latency(Cache_Latency),

		.stage(stage_ID),
		.PCSel(PCSel_ID),
		.ImmSel(ImmSel_ID),
		.RF_WE(RF_WE_ID),
		.BrUn(BrUn_ID),
		.func3(func3_ID),
		.ASel(ASel_ID),
		.BSel(BSel_ID),
		.ALUOp(ALUOp_ID),
		.D_MEM_BE(D_MEM_BE_ID),
		.D_MEM_WEN(D_MEM_WEN_ID),
		.WBSel(WBSel_ID),

		.ostage(stage_EX),
		.oPCSel(PCSel_EX_buffer),
		.oImmSel(ImmSel_EX),
		.oRF_WE(RF_WE_EX),
		.oBrUn(BrUn_EX),
		.ofunc3(func3_EX),
		.oASel(ASel_EX),
		.oBSel(BSel_EX),
		.oALUOp(ALUOp_EX),
		.oD_MEM_BE(D_MEM_BE_EX),
		.oD_MEM_WEN(D_MEM_WEN_EX),
		.oWBSel(WBSel_EX),

		.PC(PC_ID),
		.PC_plus_4(PC_plus_4_ID),
		.instr(instr_ID),
		.RF_RA1(RF_RA1_ID),
		.RF_RA2(RF_RA2_ID),
		.RF_WA1(RF_WA1_ID),
		.RF_RD1(RF_RD1_ID),
		.RF_RD2(RF_RD2_ID),
		.Imm(Imm_ID),
		.result(32'bx),
		.D_MEM_DI(32'bx),

		.oPC(PC_EX),
		.oPC_plus_4(PC_plus_4_EX),
		.oinstr(instr_EX),
		.oRF_RA1(RF_RA1_EX),
		.oRF_RA2(RF_RA2_EX),
		.oRF_WA1(RF_WA1_EX),
		.oRF_RD1(RF_RD1_EX_buffer),
		.oRF_RD2(RF_RD2_EX_buffer),
		.oImm(Imm_EX),
		.oresult(temp),
		.oD_MEM_DI(temp)
	);

	// EX
	Forwarding_Unit forwarding_unit (
		.RF_RA1_ID(RF_RA1_ID),
		.RF_RA2_ID(RF_RA2_ID),
		.RF_RA1_EX(RF_RA1_EX),
		.RF_RA2_EX(RF_RA2_EX),
		.ImmSel_ID(ImmSel_ID),
		.ImmSel_EX(ImmSel_EX),
		.RF_WA1_EX(RF_WA1_EX),
		.RF_WA1_MEM(RF_WA1_MEM),
		.RF_WA1_WB(RF_WA1_WB),
		.RF_WE_MEM(RF_WE_MEM),
		.RF_WE_WB(RF_WE_WB),
		.Forward1_MEM(Forward1_MEM),
		.Forward1_WB(Forward1_WB),
		.Forward2_MEM(Forward2_MEM),
		.Forward2_WB(Forward2_WB),
		.Forward1_After(Forward1_After),
		.Forward2_After(Forward2_After),
		.Load_Delay(Load_Delay)
	);

	assign RF_RD1_EX = (Forward1_MEM) ? result_MEM : ((Forward1_WB) ? RF_WD : RF_RD1_EX_buffer);
	assign RF_RD2_EX = (Forward2_MEM) ? result_MEM : ((Forward2_WB) ? RF_WD : RF_RD2_EX_buffer);
	assign PCSel_EX = (ImmSel_EX == Btype) ? PCSel_Branch : PCSel_EX_buffer;

	
	Branch_Comp branch_comp (
		.A(RF_RD1_EX),
		.B(RF_RD2_EX),
		.BrUn(BrUn_EX),
		.func3(func3_EX),
		.PCSel(PCSel_Branch)
	);
	

	MUX2 asel (
		.in0(RF_RD1_EX),
		.in1({{20{1'b0}}, PC_EX}),
		.sel(ASel_EX),
		.out(A)
	);

	MUX2 bsel (
		.in0(RF_RD2_EX),
		.in1(Imm_EX),
		.sel(BSel_EX),
		.out(B)
	);

	ALU alu (
		.ALUOp(ALUOp_EX),
		.A(A),
		.B(B),
		.result(result_EX)
	);

	
	Branch_Predictor branch_predictor (
		.CLK(CLK),
		.RSTn(RSTn),
		.Cache_Latency(Cache_Latency),
		.PC(PC),
		.PC_plus_4(PC_plus_4),
		.PC_EX(PC_EX),
		.PC_plus_4_EX(PC_plus_4_EX),
		.ImmSel_EX(ImmSel_EX),
		.result_EX(result_EX),
		.PCSel_EX(PCSel_EX),
		.nextPC(nextPC),
		.Flush(Flush)
	);
	

	// EX_MEM
	Pipeline_REG ex_mem (
		.CLK(CLK),
		.RSTn(RSTn),
		.Load_Delay(Load_Delay),
		.Flush(Flush),
		.Cache_Latency(Cache_Latency),

		.stage(stage_EX),
		.PCSel(PCSel_EX),
		.ImmSel(ImmSel_EX),
		.RF_WE(RF_WE_EX),
		.BrUn(1'bx),
		.func3(3'bx),
		.ASel(1'bx),
		.BSel(1'bx),
		.ALUOp(4'bx),
		.D_MEM_BE(D_MEM_BE_EX),
		.D_MEM_WEN(D_MEM_WEN_EX),
		.WBSel(WBSel_EX),

		.ostage(stage_MEM),
		.oPCSel(PCSel_MEM),
		.oImmSel(ImmSel_MEM),
		.oRF_WE(RF_WE_MEM),
		.oBrUn(temp[0]),
		.ofunc3(temp[2:0]),
		.oASel(temp[0]),
		.oBSel(temp[0]),
		.oALUOp(temp[3:0]),
		.oD_MEM_BE(D_MEM_BE_MEM),
		.oD_MEM_WEN(D_MEM_WEN_MEM),
		.oWBSel(WBSel_MEM),

		.PC(PC_EX),
		.PC_plus_4(PC_plus_4_EX),
		.instr(instr_EX),
		.RF_RA1(RF_RA1_EX),
		.RF_RA2(RF_RA2_EX),
		.RF_WA1(RF_WA1_EX),
		.RF_RD1(32'bx),
		.RF_RD2(RF_RD2_EX),
		.Imm(32'bx),
		.result(result_EX),
		.D_MEM_DI(32'bx),

		.oPC(PC_MEM),
		.oPC_plus_4(PC_plus_4_MEM),
		.oinstr(instr_MEM),
		.oRF_RA1(RF_RA1_MEM),
		.oRF_RA2(RF_RA2_MEM),
		.oRF_WA1(RF_WA1_MEM),
		.oRF_RD1(temp),
		.oRF_RD2(RF_RD2_MEM),
		.oImm(temp),
		.oresult(result_MEM),
		.oD_MEM_DI(temp)
	);

	// MEM
	Cache cache (
		.CLK(CLK),
		.CSN(D_MEM_CSN),
		.ImmSel(ImmSel_MEM),
		.R_TOP_ADDR(result_MEM[11:0]),
		.R_TOP_WEN((stage_MEM == MEM) ? D_MEM_WEN_MEM : 1'b1),
		.R_TOP_BE(D_MEM_BE_MEM),
		.R_TOP_DI(RF_RD2_MEM),
		.D_MEM_DI(D_MEM_DI),
		.D_MEM_ADDR(D_MEM_ADDR),
		.D_MEM_WEN(D_MEM_WEN),
		.D_MEM_BE(D_MEM_BE),
		.R_TOP_DOUT(D_MEM_DI_MEM),
		.D_MEM_DOUT(D_MEM_DOUT),
		.Cache_Latency(Cache_Latency),
		.READ_HIT_COUNT(READ_HIT_COUNT),
		.READ_MISS_COUNT(READ_MISS_COUNT),
		.WRITE_HIT_COUNT(WRITE_HIT_COUNT),
		.WRITE_MISS_COUNT(WRITE_MISS_COUNT)
	);

	// MEM_WB
	Pipeline_REG mem_wb (
		.CLK(CLK),
		.RSTn(RSTn),
		.Load_Delay(Load_Delay),
		.Flush(Flush),
		.Cache_Latency(Cache_Latency),

		.stage(stage_MEM),
		.PCSel(PCSel_MEM),
		.ImmSel(3'bx),
		.RF_WE(RF_WE_MEM),
		.BrUn(1'bx),
		.func3(3'bx),
		.ASel(1'bx),
		.BSel(1'bx),
		.ALUOp(4'bx),
		.D_MEM_BE(4'bx),
		.D_MEM_WEN(1'bx),
		.WBSel(WBSel_MEM),

		.ostage(stage_WB),
		.oPCSel(PCSel_WB),
		.oImmSel(temp[2:0]),
		.oRF_WE(RF_WE_WB),
		.oBrUn(temp[0]),
		.ofunc3(temp[2:0]),
		.oASel(temp[0]),
		.oBSel(temp[0]),
		.oALUOp(temp[3:0]),
		.oD_MEM_BE(temp[3:0]),
		.oD_MEM_WEN(temp[0]),
		.oWBSel(WBSel_WB),

		.PC(PC_MEM),
		.PC_plus_4(PC_plus_4_MEM),
		.instr(32'bx),
		.RF_RA1(RF_RA1_MEM),
		.RF_RA2(RF_RA2_MEM),
		.RF_WA1(RF_WA1_MEM),
		.RF_RD1(32'bx),
		.RF_RD2(32'bx),
		.Imm(32'bx),
		.result(result_MEM),
		.D_MEM_DI(D_MEM_DI_MEM),

		.oPC(PC_WB),
		.oPC_plus_4(PC_plus_4_WB),
		.oinstr(temp),
		.oRF_RA1(RF_RA1_WB),
		.oRF_RA2(RF_RA2_WB),
		.oRF_WA1(RF_WA1_WB),
		.oRF_RD1(temp),
		.oRF_RD2(temp),
		.oImm(temp),
		.oresult(result_WB),
		.oD_MEM_DI(D_MEM_DI_WB)
	);

	// WB
	MUX8 wbsel (
		.in0(D_MEM_DI_WB),
		.in1(result_WB),
		.in2(PC_plus_4_WB),
		.in3(0),
		.in4(1),
		.in5({{31{1'b0}}, PCSel_WB}),
		.in6(0),
		.in7(1),
		.sel(WBSel_WB),
		.out(RF_WD)
	);

	assign RF_WE = (stage_WB == WB) ? RF_WE_WB : 1'b0;
	assign RF_WA1 = RF_WA1_WB;

	// etc.
	assign HALT = rHALT;
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign OUTPUT_PORT = RF_WD;

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn && stage_WB == WB && PC_WB >= 0) begin
			NUM_INST <= NUM_INST + 1;
		end

		RF_WD_After <= RF_WD;
	end

	real HIT_COUNT;
	real TOTAL_COUNT;

	// HALT checking
	always @ (*) begin
		if (instr_EX == 32'h00008067 && instr_MEM == 32'h00c00093) begin

			HIT_COUNT = READ_HIT_COUNT + WRITE_HIT_COUNT;
			TOTAL_COUNT = READ_HIT_COUNT + READ_MISS_COUNT + WRITE_HIT_COUNT + WRITE_MISS_COUNT;
			/*
			$display("--------------------");
			$display("READ_HIT = %d, READ_MISS = %d, WRITE_HIT = %d, WRITE_MISS = %d", READ_HIT_COUNT, READ_MISS_COUNT, WRITE_HIT_COUNT, WRITE_MISS_COUNT);
			$display("HIT_COUNT = %d, TOTAL_COUNT = %d, HIT_RATIO = %f", HIT_COUNT, TOTAL_COUNT, HIT_COUNT/TOTAL_COUNT);
			$display("--------------------");
			*/

			rHALT = 1;
		end
	end

	// Initialization
	initial begin
		NUM_INST <= 0;
	end

	///////////////////////////////////////////////////
	// Sequential circuit
	always @ (posedge CLK) begin
		if (!RSTn) begin
			PC <= 0;
			Stall <= 0;
		end
		else begin
			if (Cache_Latency) begin
				// Just stall the program.
			end
			else begin
				if (Stall == 0) begin
					if (Load_Delay) begin
						Stall <= 1;
					end
					else begin
						PC <= nextPC[11:0];
					end
				end
				else begin
					Stall <= 0;
					PC <= nextPC[11:0];
				end
			end
		end
	end

endmodule // RISCV_TOP
