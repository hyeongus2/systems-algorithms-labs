
module count1s(A,B,C,D,cnt);

    input A,B,C,D;
    output [2:0] cnt;

    // fill the blank
    assign cnt[2] = A & B & C & D;
    assign cnt[1] = (A & B & ~C) | (A & ~B & D) | (A & ~B & C) |
	    (B & C & ~D) | (~A & C & D) | (B & ~C & D);
    assign cnt[0] = A ^ B ^ C ^ D;

endmodule
