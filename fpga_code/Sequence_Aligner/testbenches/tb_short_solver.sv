`timescale 1ns / 1ps
`include "macro.vh"

`define LEN1 (10)
`define LEN2 (9)

import datatypesPkg::*;

module tb_short_solver(
            output logic finished,
            output logic [$clog2(`LEN1):0] maxRowId,
            output logic [$clog2(`LEN2):0] maxColId,
            output logic [0:`LEN1-1] [15:0] score_grid [0:`LEN2-1],
            output direction grid [0:`LEN2-1] [0:`LEN1-1],
            output direction aligned_sequence [0:`LEN1+`LEN2-1]
        );

    logic clk;      // clock signal we are going to generate
    logic rst;      // the reset input used to initialise the system

    dna_base seq1 [0:`LEN1-1] = '{A,T,C,A,G,T,T,G,G, A};
    dna_base seq2 [0:`LEN2-1] = '{G,G,C,A,T,T,G,T, A};

                    // instantiate design under test
    short_solver #(.len1(`LEN1), .len2(`LEN2)) ss(.clk(clk), .rst(rst), .seq1(seq1), .seq2(seq2),
    .finished(finished), .maxRowId(maxRowId), .maxColId(maxColId), .grid(grid), .score_grid(score_grid), .aligned_sequence(aligned_sequence));

    initial          // sequence of events to simulate
        begin
            clk = 0;     // at time=0 set clock to zero and reset to active (1)
            rst = 1;

            #20 rst = 0; // after 2 clock ticks set reset to inactive (0)
        end

    always #5       // every five simulation units...
        clk <= !clk;  // ...invert the clock

                    // produce debug output on the negative edge of the clock

endmodule // tb_short_solver
