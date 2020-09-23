`timescale 1ns / 1ps
`include "macro.vh"

// `define LEN1 (16)
// `define LEN2 (16)
// `define MAX_LEN1 (16)
// `define MAX_LEN2 (16)

`define MAX_LEN1 (1024)
`define MAX_LEN2 (1024)
`define PIPELINE_LENGTH (48)


import datatypesPkg::*;

module tb_blosum();
    logic clk;
    protein_base seq1;
    protein_base seq2;
    logic [15:0] score;

    blosum_compare bc(.seq1(seq1), .seq2(seq2), .score(score));

    initial begin
        clk = 0;     // at time=0 set clock to zero and reset to active (1)

        seq1 = A;
        seq2 = A;

        #10 seq2 = B;
        #10 seq2 = C;
        #10 seq2 = D;
        #10 seq2 = E;
        #10 seq2 = F;
        #10 seq2 = G;
        #10 seq2 = H;
        #10 seq2 = I;
        #10 seq2 = J;
        #10 seq2 = K;
        #10 seq2 = L;
        #10 seq2 = M;
        #10 seq2 = N;
        #10 seq2 = O;
        #10 seq2 = P;
        #10 seq2 = Q;
        #10 seq2 = R;
        #10 seq2 = S;
        #10 seq2 = T;
        #10 seq2 = U;
        #10 seq2 = V;
        #10 seq2 = W;
        #10 seq2 = X;
        #10 seq2 = Y;
        #10 seq2 = Z;

    end


    always #5       // every five simulation units...
        clk <= !clk;  // ...invert the clock

endmodule
