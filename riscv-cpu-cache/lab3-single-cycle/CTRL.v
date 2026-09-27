module CTRL (
	input wire RSTn,
	input wire [31:0] instr,
	input wire BrEq,
	input wire BrLT,

	output reg PCSel,
	output reg [2:0] ImmSel,
	output reg RF_WE,
	output reg BrUn,
	output reg [1:0] ASel,
	output reg BSel,
	output reg [3:0] ALUOp,
	output reg [3:0] D_MEM_BE,
	output reg D_MEM_WEN,
	output reg [2:0] WBSel
	);

	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110;

	reg [6:0] opcode;
	reg [2:0] func3;
	reg [6:0] func7;

	assign opcode = instr[6:0];
	assign func3 = instr[14:12];
	assign func7 = instr[31:25];

	always @ (*) begin
        // Safe combinational defaults for reset and unsupported opcodes.
        PCSel = 0;
        ImmSel = Rtype;
        RF_WE = 0;
        BrUn = 0;
        ASel = 0;
        BSel = 0;
        ALUOp = 0;
        D_MEM_BE = 0;
        D_MEM_WEN = 1;
        WBSel = 3;
		if (!RSTn) begin
			PCSel = 0;
			WBSel = 3;	// RF_WD = 0
		end
		else begin
		case(opcode)
			7'b0110011: begin // Rtype
				PCSel = 0;
				ImmSel = Rtype;
				RF_WE = 1;
				ASel = 0;
				BSel = 0;
				ALUOp = {func7[5], func3};
				D_MEM_WEN = 1;
				WBSel = 1;
			end
			7'b0010011: begin // Itype
				PCSel = 0;
				ImmSel = Itype;
				RF_WE = 1;
				ASel = 0;
				BSel = 1;
				ALUOp = {(func3 == 3'h5 ? instr[30] : 1'b0), func3};
				D_MEM_WEN = 1;
				WBSel = 1;
			end
			7'b0000011: begin // LOAD(Ltype)
				PCSel = 0;
				ImmSel = Ltype;
				RF_WE = 1;
				ASel = 0;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				case(func3)
					3'h0: D_MEM_BE = 4'b0001;	// LB
					3'h1: D_MEM_BE = 4'b0011;	// LH
					3'h2: D_MEM_BE = 4'b1111;	// LW
					default: D_MEM_BE = 4'b0000;
				endcase
				D_MEM_WEN = 1;
				WBSel = 0;
			end
			7'b0100011: begin // Stype
				PCSel = 0;
				ImmSel = Stype;
				RF_WE = 0;
				ASel = 0;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				case(func3)
					3'h0: D_MEM_BE = 4'b0001;	// SB
					3'h1: D_MEM_BE = 4'b0011;	// SH
					3'h2: D_MEM_BE = 4'b1111;	// SW
					default: D_MEM_BE = 4'b0000;
				endcase
				D_MEM_WEN = 0;
				WBSel = 1;
			end
			7'b1100011: begin // Btype
				case(func3)
					3'h0: PCSel = (BrEq) ? 1 : 0;	// BEQ
					3'h1: PCSel = (BrEq) ? 0 : 1;	// BNE
					3'h4: PCSel = (BrLT) ? 1 : 0;	// BLT
					3'h5: PCSel = (BrLT) ? 0 : 1;	// BGE
					3'h6: PCSel = (BrLT) ? 1 : 0;	// BLTU
					3'h7: PCSel = (BrLT) ? 0 : 1;	// BGEU
					default: PCSel = 0;
				endcase
				ImmSel = Btype;
				RF_WE = 0;
				case(func3)
					3'h6: BrUn = 1;
					3'h7: BrUn = 1;
					default: BrUn = 0;
				endcase
				ASel = 1;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				D_MEM_WEN = 1;
				WBSel = 5;	// RF_WD = PCSel
			end
			7'b1101111: begin // JAL(Jtype)
				PCSel = 1;
				ImmSel = Jtype;
				RF_WE = 1;
				ASel = 1;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				D_MEM_WEN = 1;
				WBSel = 2;
			end
			7'b1100111: begin // JALR(Itype)
				PCSel = 1;
				ImmSel = Itype;
				RF_WE = 1;
				ASel = 0;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				D_MEM_WEN = 1;
				WBSel = 2;
			end
			7'b0110111: begin // LUI(Utype)
				PCSel = 0;
				ImmSel = Utype;
				RF_WE = 1;
				ASel = 2;	// A = 0
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				D_MEM_WEN = 1;
				WBSel = 1;
			end
			7'b0010111: begin // AUIPC(Utype)
				PCSel = 0;
				ImmSel = Utype;
				RF_WE = 1;
				ASel = 1;
				BSel = 1;
				ALUOp = 4'b0000;	// ADD
				D_MEM_WEN = 1;
				WBSel = 1;
			end
			7'b0001011: begin // MULT, MODULO, IS_EVEN(Rtype)
				PCSel = 0;
				ImmSel = Rtype;
				RF_WE = 1;
				ASel = 0;
				BSel = 0;
				if (func3 == 3'b110)		// IS_EVEN
					ALUOp = 4'b1100;
				else if (func7 == 7'b0000000)	// MULT
					ALUOp = 4'b1110;
				else				// MODULO
					ALUOp = 4'b1111;
				D_MEM_WEN = 1;
				WBSel = 1;
			end
		endcase
		end
	end

endmodule // CTRL
