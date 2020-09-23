`timescale 1ns / 1ps
`include "macro.vh"

// `define LEN1 (16)
// `define LEN2 (16)
// `define MAX_LEN1 (16)
// `define MAX_LEN2 (16)

`define LEN1 (46)
`define LEN2 (41)
`define MAX_LEN1 (1024)
`define MAX_LEN2 (64)


import datatypesPkg::*;

module tb_med_solver(output logic finished,
            output logic [$clog2(`MAX_LEN1):0] maxRowId,
            output logic [$clog2(`MAX_LEN2):0] maxColId,
            output logic [0:`MAX_LEN1-1] [15:0] score_grid [0:`MAX_LEN2-1],
            output direction grid [0:`MAX_LEN2-1] [0:`MAX_LEN1-1],
            output direction aligned_sequence [0:`MAX_LEN1+`MAX_LEN2-1]
);

    logic clk;      // clock signal we are going to generate
    logic rst;      // the reset input used to initialise the system

    // dna_base seq1 [`MAX_LEN1-1:0] = '{A,T,C,A,G,T,A,T,C,A,G,T,T,G,G, A};
    // dna_base seq2 [`MAX_LEN2-1:0] = '{G,G,C,A,G,G,C,A,G,G,C,T,T,G,T, A};

    dna_base seq1 [0:`MAX_LEN1-1] = '{A ,G,T,T,G,A,C,T,A,T,G,A,C,T,A,C,G,G,T,T,G,A,C,T,A,T,G,A,C,T,A,C,G,G,T,T,G,A,C,T,A,T,G,A,C,T,A,C,G,G,T,T,G,A,C,T,A,T,G,A,C,T,A,C, A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A,A};
    dna_base seq2 [0:`MAX_LEN2-1] = '{A ,A,G,G,C,G,A,C,G,G,C,T,G,T,T,C,G,G,A,C,G,G,A,C,T,G,T,T,C,G,G,A,C,G,G,A,C,G,G,C,T,G,T,G,T,T,C,G,G,A,C,G,G,T,T,C,G,G,A,C,G,G,G,C};

    // dna_base seq1 [`MAX_LEN1-1:0] = '{T,T,A,A,C,A,C,C,G,A,G,T,T,G,A,G,A,A,T,C,C,A,A,A,T,G,C,T,T,C,A,C,G,C,A,A,T,A,T,C,C,C,C,G,T,G,A,C,G,A,C,C,A,G,C,C,C,T,T,C,T,A,A,C,A,C,T,C,G,G,C,A,T,G,A,A,A,C,G,T,T,T,G,G,C,C,A,C,G,C,C,C,C,A,C,G,G,C,A,T,A,A,G,A,C,C,A,C,T,G,C,T,C,A,C,G,C,T,G,C,T,A,A,A,C,T,G, A};
    // dna_base seq2 [`MAX_LEN2-1:0] = '{A,C,A,G,G,G,C,G,T,T,C,G,C,G,T,C,C,T,G,C,C,A,G,G,C,C,A,G,A,G,A,A,A,G,C,T,C,C,C,C,T,C,C,T,C,C,T,G,C,T,G,A,T,A,C,C,A,T,A,G,T,G,T,C,A,G,A,G,G,C,C,T,C,A,T,A,C,G,T,A,T,G,A,A,C,A,G,G,T,C,C,C,G,T,C,A,A,T,G,C,G,A,G,T,C,A,G,G,G,C,C,G,G,G,T,C,C,G,G,A,C,G,C,C,A,A,G, A};

    logic rdreq;
    logic wrreq;
    logic sclr;

    logic empty;
    logic full;

    logic [15:0] in16;
    logic [15:0] out16;

                    // instantiate design under test
    fifo_16b_1024w last_col (.aclr(rst), .clock(clk), .sclr(sclr),
        .data(in16), .rdreq(rdreq),
        .q(out16), .wrreq(wrreq),
        .empty(empty), .full(full)
    );

    med_solver #(.max_len1(`MAX_LEN1), .max_len2(`MAX_LEN2), .pipeline_length(12)) ms
    (.clk(clk), .rst(rst), .len1(12'd60), .len2(8'd60), .seq1(seq1), .seq2(seq2),
    .finished(finished), .maxRowId(maxRowId), .maxColId(maxColId), .grid(grid), .score_grid(score_grid), .aligned_sequence(aligned_sequence));


    initial          // sequence of events to simulate
        begin
            clk = 0;     // at time=0 set clock to zero and reset to active (1)
            rst = 1;

            sclr = 1'b0;
            rdreq = 1'b0;
            wrreq = 1'b0;
            in16 = 16'hFF00;

            #20 rst = 0; // after 2 clock ticks set reset to inactive (0)

            #5 wrreq = 1'b1;
            #10 in16 = 16'hF0F0;

            #10 wrreq = 1'b0;
            #10 rdreq = 1'b1;

            #40 rdreq = 1'b0;

        end

    always #5       // every five simulation units...
        clk <= !clk;  // ...invert the clock

                    // produce debug output on the negative edge of the clock

endmodule // tb_short_solver
