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
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

	assign OUTPUT_PORT = RF_WD;

	initial begin
		NUM_INST <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

	// TODO: implement

	///////////////////////////////////////////////////
	// Variables
	// IF
	wire PCSel;
	reg [11:0] PC;
	wire [31:0] nextPC;
	wire [31:0] PC_plus_4;
	reg [31:0] instr;

	// ID
	wire [2:0] ImmSel;
	wire [31:0] Imm;
	wire BrUn;
	wire BrEq;
	wire BrLT;

	// EX
	wire [1:0] ASel;
	wire BSel;
	wire [31:0] A;
	wire [31:0] B;
	wire [3:0] ALUOp;
	wire [31:0] result;

	// WB
	wire [2:0] WBSel;

	// etc.
	reg rHALT;

	///////////////////////////////////////////////////
	// Relationship between variables
	// IF
	assign I_MEM_ADDR = PC;
	assign instr = I_MEM_DI;

	MUX2 pcsel (
		.in0(PC_plus_4),
		.in1(result),
		.sel(PCSel),
		.out(nextPC)
	);

	ALU adder (
		.ALUOp(4'b0000),
		.A({{20{1'b0}}, PC}),
		.B(4),
		.result(PC_plus_4)
	);

	// ID
	assign RF_RA1 = instr[19:15];
	assign RF_RA2 = instr[24:20];
	assign RF_WA1 = instr[11:7];

	CTRL ctrl (
		.RSTn(RSTn),
		.instr(instr),
		.BrEq(BrEq),
		.BrLT(BrLT),
		.PCSel(PCSel),
		.ImmSel(ImmSel),
		.RF_WE(RF_WE),
		.BrUn(BrUn),
		.ASel(ASel),
		.BSel(BSel),
		.ALUOp(ALUOp),
		.D_MEM_BE(D_MEM_BE),
		.D_MEM_WEN(D_MEM_WEN),
		.WBSel(WBSel)
	);

	Imm_Gen imm_gen (
		.ImmSel(ImmSel),
		.instr(instr),
		.Imm(Imm)
	);

	Branch_Comp branch_comp (
		.A(RF_RD1),
		.B(RF_RD2),
		.BrUn(BrUn),
		.BrEq(BrEq),
		.BrLT(BrLT)
	);

	// EX
	MUX4 asel (
		.in0(RF_RD1),
		.in1({{20{1'b0}}, PC}),
		.in2(0),
		.in3(1),
		.sel(ASel),
		.out(A)
	);

	MUX2 bsel (
		.in0(RF_RD2),
		.in1(Imm),
		.sel(BSel),
		.out(B)
	);

	ALU alu (
		.ALUOp(ALUOp),
		.A(A),
		.B(B),
		.result(result)
	);

	// MEM
	assign D_MEM_ADDR = result[11:0];
	assign D_MEM_DOUT = RF_RD2;

	// WB
	MUX8 wbsel (
		.in0(D_MEM_DI),
		.in1(result),
		.in2(PC_plus_4),
		.in3(0),
		.in4(1),
		.in5({{31{1'b0}}, PCSel}),
		.in6(0),
		.in7(1),
		.sel(WBSel),
		.out(RF_WD)
	);

	// etc.
	assign HALT = rHALT;
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;

	// HALT checking
	always @ (*) begin
		if (instr == 32'h00008067 && RF_RD1 == 32'h0000000c)
			rHALT = 1;
	end

	///////////////////////////////////////////////////
	// Sequential circuit
	always @ (posedge CLK) begin
		if (!RSTn)
			PC <= 0;
		else
			PC <= nextPC[11:0];
	end

endmodule //
