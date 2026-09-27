module MUXb(a,b,sel,out);

    input a,b,sel;
    output out;

    // Fill in the blank
    assign out = (sel == 1'b0) ? a : b;

endmodule
