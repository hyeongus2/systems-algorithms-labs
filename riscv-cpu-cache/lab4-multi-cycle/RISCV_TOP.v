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

	// TODO: implement multi-cycle CPU
	// stage
	reg [2:0] stage;
	reg [2:0] nextStage;
	parameter IF = 3'b000, ID = 3'b001, EX = 3'b010, MEM = 3'b011, WB = 3'b100;
	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110;

	///////////////////////////////////////////////////
	// Variables
	// IF
	wire PCSel;
	reg [11:0] PC;
	wire [11:0] PC_buffer;
	wire [31:0] nextPC;
	wire [31:0] PC_plus_4;
	wire [31:0] instr;
	wire [31:0] instr_buffer;

	// ID
	wire [2:0] ImmSel;
	wire [31:0] Imm;
	wire BrUn;
	wire BrEq;
	wire BrLT;

	// EX
	wire ASel;
	wire BSel;
	wire [31:0] A;
	wire [31:0] B;
	wire [3:0] ALUOp;
	wire [31:0] result;

	// MEM
	wire D_MEM_WEN_buffer;
	wire [31:0] D_MEM_WEN_32;

	// WB
	wire [2:0] WBSel;
	wire RF_WE_buffer;
	wire [31:0] RF_WE_32;

	// etc.
	reg rHALT;
	reg rHALT_ready;
	reg LAST;	// indicate that the next stage is the last one of the execution of an instruction.

	///////////////////////////////////////////////////
	// Relationship between variables
	// IF
	assign I_MEM_ADDR = PC;
	assign instr_buffer = I_MEM_DI;

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
		.stage(stage),
		.isAdder(1'b1),
		.result(PC_plus_4)
	);

	//ID
	MUX2 instr_buffer1 (
		.in0(instr),
		.in1(instr_buffer),
		.sel(stage == ID),
		.out(instr)
	);

	assign RF_RA1 = instr[19:15];
	assign RF_RA2 = instr[24:20];
	assign RF_WA1 = instr[11:7];

	CTRL ctrl (
		.RSTn(RSTn),
		.instr(instr_buffer),
		.BrEq(BrEq),
		.BrLT(BrLT),
		.PCSel(PCSel),
		.ImmSel(ImmSel),
		.RF_WE(RF_WE_buffer),
		.BrUn(BrUn),
		.ASel(ASel),
		.BSel(BSel),
		.ALUOp(ALUOp),
		.D_MEM_BE(D_MEM_BE),
		.D_MEM_WEN(D_MEM_WEN_buffer),
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
	MUX2 asel (
		.in0(RF_RD1),
		.in1({{20{1'b0}}, PC}),
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
		.stage(stage),
		.isAdder(1'b0),
		.result(result)
	);

	// MEM
	MUX2 d_mem_wen (
		.in0(1),
		.in1({{31{1'b0}}, D_MEM_WEN_buffer}),
		.sel(stage == MEM),
		.out(D_MEM_WEN_32)
	);

	assign D_MEM_WEN = D_MEM_WEN_32[0];
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

	MUX2 rf_we (
		.in0(0),
		.in1({{31{1'b0}}, RF_WE_buffer}),
		.sel(stage == WB),
		.out(RF_WE_32)
	);

	assign RF_WE = RF_WE_32[0];

	// etc.
	assign HALT = rHALT;
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;
	assign OUTPUT_PORT = RF_WD;

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn && LAST) NUM_INST <= NUM_INST + 1;
	end

	// HALT checking
	always @ (*) begin
		if (instr == 32'h00008067 && RF_RD1 == 32'h0000000c)
			rHALT = 1;
	end

	// Initialization
	initial begin
		NUM_INST <= 0;
	end

	// Stage changing
	always @ (*) begin
		LAST = 0;

		case(ImmSel)
			Rtype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: nextStage = WB;
					WB: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			Itype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: nextStage = WB;
					WB: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			Ltype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: nextStage = MEM;
					MEM: nextStage = WB;
					WB: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			Stype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: nextStage = MEM;
					MEM: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			Btype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			Jtype: begin
				case(stage)
					IF: nextStage = ID;
					ID: nextStage = EX;
					EX: nextStage = WB;					
					WB: begin
						nextStage = IF;
						LAST = 1;
					end
				endcase
			end
			default: nextStage = IF;
		endcase
	end

	///////////////////////////////////////////////////
	// Sequential circuit
	always @ (posedge CLK) begin
		if (!RSTn) begin
			PC <= 0;
			stage <= IF;
		end
		else begin
			if (LAST) begin
				PC <= nextPC[11:0];
			end
			stage <= nextStage;
		end
	end

endmodule // RISCV_TOP
