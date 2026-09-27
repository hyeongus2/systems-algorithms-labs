

module majority(A,B,C,O);

    input A,B,C;
    output O;

    // Fill the blank
    wire O1, O2, O3;

    and U1(O1, A, B);
    and U2(O2, B, C);
    and U3(O3, C, A);

    or U4(O, O1, O2, O3);

endmodule
