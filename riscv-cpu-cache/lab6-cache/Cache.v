module Cache (
	input wire CLK,
	input wire CSN, // chip select negative??
	input wire [2:0] ImmSel,
	input wire [11:0] R_TOP_ADDR, // address from RISCV_TOP
	input wire R_TOP_WEN, // write enable negative?? from RISCV_TOP
	input wire [3:0] R_TOP_BE, // byte enable from RISCV_TOP
	input wire [31:0] R_TOP_DI, // data in from RISCV_TOP
	input wire [31:0] D_MEM_DI, // data in from D_MEM

	output reg [11:0] D_MEM_ADDR, // address to D_MEM
	output reg D_MEM_WEN, // write enable negative?? to D_MEM
	output reg [3:0] D_MEM_BE, // byte enable to D_MEM
	output reg [31:0] R_TOP_DOUT, // data out to RISCV_TOP
	output reg [31:0] D_MEM_DOUT, // data out to D_MEM
	output reg Cache_Latency, // when a cache hit/miss occurs
	output reg [31:0] READ_HIT_COUNT,
	output reg [31:0] READ_MISS_COUNT,
	output reg [31:0] WRITE_HIT_COUNT,
	output reg [31:0] WRITE_MISS_COUNT
	);

	parameter Rtype = 3'b000, Itype = 3'b001, Ltype = 3'b010, Stype = 3'b011, Btype = 3'b100, Utype = 3'b101, Jtype = 3'b110, JRtype = 3'b111;
	parameter READ_HIT = 0, READ_MISS = 1, WRITE_HIT = 2, WRITE_MISS = 3;
	parameter READ_HIT_LATENCY = 1, READ_MISS_LATENCY = 10, WRITE_HIT_LATENCY = 9, WRITE_MISS_LATENCY = 18;

	reg Use_Cache;
	reg [6:0] Tags [7:0];
	reg Valids [7:0];
	reg [31:0] Data00s [7:0];
	reg [31:0] Data01s [7:0];
	reg [31:0] Data10s [7:0];
	reg [31:0] Data11s [7:0];

	wire [6:0] Tag;
	wire [2:0] Index;
	wire [1:0] Block;
	wire [11:0] ADDR00;
	wire [11:0] ADDR01;
	wire [11:0] ADDR10;
	wire [11:0] ADDR11;
	wire [31:0] Data00;
	wire [31:0] Data01;
	wire [31:0] Data10;
	wire [31:0] Data11;
	wire [31:0] outline;

	reg [31:0] temp;
	reg [1:0] latency_type;
	reg [4:0] latency_count;

	assign Use_Cache = (ImmSel == Ltype) || (ImmSel == Stype);
	assign Tag = R_TOP_ADDR[11:5];
	assign Index = R_TOP_ADDR[4:2];
	assign Block = R_TOP_ADDR[1:0];
	assign ADDR00 = R_TOP_ADDR & (~ 12'h3);
	assign ADDR01 = ADDR00 + 1;
	assign ADDR10 = ADDR00 + 2;
	assign ADDR11 = ADDR00 + 3;
	assign Data00 = Data00s[Index];
	assign Data01 = Data01s[Index];
	assign Data10 = Data10s[Index];
	assign Data11 = Data11s[Index];

	integer i;

	initial begin
		for(i=0; i<8; i=i+1) begin
			Valids[i] <= 0;
		end

		Cache_Latency <= 0;
		latency_count <= 0;

		READ_HIT_COUNT <= 0;
		READ_MISS_COUNT <= 0;
		WRITE_HIT_COUNT <= 0;
		WRITE_MISS_COUNT <= 0;
	end

	MUX4 block (
		.in0(Data00),
		.in1(Data01),
		.in2(Data10),
		.in3(Data11),
		.sel(Block),
		.out(outline)
	);

	// MEMORY_ACCESS or CACHE_UPDATE
	always @ (negedge CLK) begin
		if (~CSN) begin
			if (Cache_Latency) begin // resolve a cache hit/miss
				case (latency_type)
					READ_MISS: begin
						case (latency_count)
							// MEMORY_ACCESS - memory read
							6: begin
								D_MEM_WEN <= 1;
								D_MEM_ADDR <= ADDR00;
							end
							5: begin
								Data00s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR01;
							end
							4: begin
								Data01s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR10;
							end
							3: begin
								Data10s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR11;
							end
							2: Data11s[Index] <= D_MEM_DI;
							// CACHE_UPDATE
							1: begin
								R_TOP_DOUT <= outline;
								Cache_Latency <= 0;
							end
							default: begin
							end
						endcase
					end
					WRITE_HIT: begin
						case (latency_count)
							// MEMORY_ACCESS - memory write
							4: begin
								D_MEM_WEN <= 0;
								D_MEM_ADDR <= ADDR00;
								D_MEM_DOUT <= Data00;
							end
							3: begin
								D_MEM_ADDR <= ADDR01;
								D_MEM_DOUT <= Data01;
							end
							2: begin
								D_MEM_ADDR <= ADDR10;
								D_MEM_DOUT <= Data10;
							end
							1: begin
								D_MEM_ADDR <= ADDR11;
								D_MEM_DOUT <= Data11;
								Cache_Latency <= 0;
							end
							default: begin
							end
						endcase
					end
					WRITE_MISS: begin
						case (latency_count)
							// MEMORY_ACCESS - memory read
							14: begin
								D_MEM_WEN <= 1;
								D_MEM_ADDR <= ADDR00;
							end
							13: begin
								Data00s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR01;
							end
							12: begin
								Data01s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR10;
							end
							11: begin
								Data10s[Index] <= D_MEM_DI;
								D_MEM_ADDR <= ADDR11;
							end
							10: Data11s[Index] <= D_MEM_DI;
							// CACHE_UPDATE
							9: begin
								case (Block)
									0: Data00s[Index] <= R_TOP_DI;
									1: Data01s[Index] <= R_TOP_DI;
									2: Data10s[Index] <= R_TOP_DI;
									3: Data11s[Index] <= R_TOP_DI;
								endcase
							end
							// MEMORY_ACCESS - memory write
							4: begin
								D_MEM_WEN <= 0;
								D_MEM_ADDR <= ADDR00;
								D_MEM_DOUT <= Data00;
							end
							3: begin
								D_MEM_ADDR <= ADDR01;
								D_MEM_DOUT <= Data01;
							end
							2: begin
								D_MEM_ADDR <= ADDR10;
								D_MEM_DOUT <= Data10;
							end
							1: begin
								D_MEM_ADDR <= ADDR11;
								D_MEM_DOUT <= Data11;
								Cache_Latency <= 0;
							end
							default: begin
							end
						endcase
					end
				endcase

				latency_count <= latency_count - 1;
			end
		end
	end

	// CACHE_ACCESS
	always @ (negedge CLK) begin
		if (~CSN) begin
			if (~Cache_Latency && Use_Cache) begin // Ltype or Stype
				if (R_TOP_WEN) begin // Ltype (Synchronous read)
					if ((Valids[Index] == 1) && (Tags[Index] == Tag)) begin	// READ_HIT
						READ_HIT_COUNT <= READ_HIT_COUNT + 1;

						Cache_Latency <= 0;
						latency_type <= READ_HIT;
						latency_count <= READ_HIT_LATENCY-1;

						D_MEM_BE <= R_TOP_BE;
						R_TOP_DOUT <= outline;
					end
					else begin // READ_MISS
						READ_MISS_COUNT <= READ_MISS_COUNT + 1;

						Cache_Latency <= 1;
						latency_type <= READ_MISS;
						latency_count <= READ_MISS_LATENCY-1;

						D_MEM_BE <= R_TOP_BE;
						Valids[Index] <= 1;
						Tags[Index] <= Tag;
					end
				end
				else begin // Stype (Synchronous write)
					if ((Valids[Index] == 1) && (Tags[Index] == Tag)) begin	// WRITE_HIT
						WRITE_HIT_COUNT <= WRITE_HIT_COUNT + 1;

						Cache_Latency <= 1;
						latency_type <= WRITE_HIT;
						latency_count <= WRITE_HIT_LATENCY-1;

						case (Block)
							0: Data00s[Index] <= R_TOP_DI;
							1: Data01s[Index] <= R_TOP_DI;
							2: Data10s[Index] <= R_TOP_DI;
							3: Data11s[Index] <= R_TOP_DI;
						endcase

						D_MEM_BE <= R_TOP_BE;
					end
					else begin // WRITE_MISS
						WRITE_MISS_COUNT <= WRITE_MISS_COUNT + 1;

						Cache_Latency <= 1;
						latency_type <= WRITE_MISS;
						latency_count <= WRITE_MISS_LATENCY-1;

						D_MEM_BE <= R_TOP_BE;
						Valids[Index] <= 1;
						Tags[Index] <= Tag;
					end
				end
			end
		end
	end

endmodule // Cache
