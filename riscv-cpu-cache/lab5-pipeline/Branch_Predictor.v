module Branch_Predictor (
	input wire CLK,
	input wire RSTn,

	input wire [11:0] PC,
	input wire [31:0] PC_plus_4,
	input wire [11:0] PC_EX,
	input wire [31:0] PC_plus_4_EX,
	input wire [2:0] ImmSel_EX,
	input wire [31:0] result_EX,
	input wire PCSel_EX,

	output reg [31:0] nextPC,
	output reg Flush
	);

	parameter EMPTY = 10'b1111111111;
	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110, JRtype = 3'b111;

	wire [9:0] index_IF;
	wire [9:0] index_EX;
	reg [9:0] BTB [1023:0];
	reg [1:0] BHT [1023:0];
	wire Branch_EX;
	wire Hit;

	assign index_IF = PC[11:2];
	assign index_EX = PC_EX[11:2];
	assign Branch_EX = (ImmSel_EX == Btype) || (ImmSel_EX == Jtype) || (ImmSel_EX == JRtype);
	assign Hit = (BTB[index_EX] == (result_EX >> 2));

	integer i;

	initial begin
		for (i = 0; i < 1024; i = i + 1) begin
			BTB[i] <= EMPTY;
			BHT[i] <= 3;
		end
	end

	always @ (negedge CLK) begin
		if (!RSTn) begin
			nextPC <= PC_plus_4;
			Flush <= 0;
		end
		else if (BTB[index_IF] == EMPTY) begin
			if (Branch_EX == 1) begin
				if (PCSel_EX == 1) begin
					if (Hit == 1) begin
						case(BHT[index_EX])
							2: BHT[index_EX] <= 3;
							3: BHT[index_EX] <= 3;
						endcase

						nextPC <= PC_plus_4;
						Flush <= 0;
					end
					else begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 1;
							1: BHT[index_EX] <= 2;
							2: BHT[index_EX] <= 3;
							3: BHT[index_EX] <= 3;
						endcase

						if (BHT[index_EX] >= 2)
							BTB[index_EX] <= result_EX[11:2];

						nextPC <= result_EX;
						Flush <= 1;
					end
				end
				else begin	// PCSel_EX == 0
					if (Hit == 1) begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 0;
							1: BHT[index_EX] <= 0;
							2: BHT[index_EX] <= 1;
							3: BHT[index_EX] <= 2;
						endcase

						if (BHT[index_EX] <= 1)
							BTB[index_EX] <= PC_plus_4_EX[11:2];

						nextPC <= PC_plus_4_EX;
						Flush <= 1;
					end
					else begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 0;
							1: BHT[index_EX] <= 0;
						endcase

						nextPC <= PC_plus_4;
						Flush <= 0;
					end
				end
			end
			else begin	// Branch_EX == 0 && PCSel_EX == 0 && Hit == 0
				nextPC <= PC_plus_4;
				Flush <= 0;
			end

			BTB[index_IF] <= PC_plus_4[11:2];
		end
		else begin	// BTB[index_IF] != EMPTY
			if (Branch_EX == 1) begin
				if (PCSel_EX == 1) begin
					if (Hit == 1) begin
						case(BHT[index_EX])
							2: BHT[index_EX] <= 3;
							3: BHT[index_EX] <= 3;
						endcase

						nextPC <= BTB[index_IF] << 2;
						Flush <= 0;
					end
					else begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 1;
							1: BHT[index_EX] <= 2;
							2: BHT[index_EX] <= 3;
							3: BHT[index_EX] <= 3;
						endcase

						if (BHT[index_EX] >= 2)
							BTB[index_EX] <= result_EX[11:2];

						nextPC <= result_EX;
						Flush <= 1;
					end
				end
				else begin	// PCSel_EX == 0
					if (Hit == 1) begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 0;
							1: BHT[index_EX] <= 0;
							2: BHT[index_EX] <= 1;
							3: BHT[index_EX] <= 2;
						endcase

						if (BHT[index_EX] <= 1)
							BTB[index_EX] <= PC_plus_4_EX[11:2];

						nextPC <= PC_plus_4_EX;
						Flush <= 1;
					end
					else begin
						case(BHT[index_EX])
							0: BHT[index_EX] <= 0;
							1: BHT[index_EX] <= 0;
						endcase

						nextPC <= BTB[index_IF] << 2;
						Flush <= 0;
					end
				end
			end
			else begin	// Branch_EX == 0 && PCSel_EX == 0 && Hit == 0
				nextPC <= BTB[index_IF] << 2;
				Flush <= 0;
			end
		end
	end

endmodule // Branch_Predictor
