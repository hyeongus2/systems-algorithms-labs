
module MUXa(a,b,sel,out);

    input a,b,sel;
    output out;

    // Fill in the blank
    wire a_sel, b_sel;

    AND2 U1(a, ~sel, a_sel);
    AND2 U2(b, sel, b_sel);
    
    OR2 U3(a_sel, b_sel, out);

endmodule

module AND2(a,b,z);
    input a,b;
    output z;
    assign z = a&b;
endmodule

module OR2(a,b,z);
    input a,b;
    output z;
    assign z= a|b;
endmodule

