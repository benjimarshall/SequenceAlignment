`timescale 1ns / 1ps
`include "macro.vh"

import datatypesPkg::*;

module tb_short_seq(output logic signed [15:0] h_out [0:4],
        output logic [3:0] rowId_out [4:0],
        output logic [3:0] maxRowId_out [4:0],
        output logic [3:0] maxColId_out [4:0],
        output logic signed [15:0] max_h_out [0:4],

        output direction pointer_out [0:4]);

    logic clk;      // clock signal we are going to generate
    logic rst;      // the reset input used to initialise the system

    dna_base [0:4] seq1 = {C,A,G,T, A};
    dna_base [0:4] seq2 = {G,C,A,T, A};
    logic signed [15:0] h_left =  16'b1000_0000_0000_0000 + `GAP_PENALTY + 10;
    logic [5:0] enable;     // junk msb
    dna_base [5:0] seqOuts; // junk msb

    logic [3:0] rowId_in = 4'b0;
    logic [3:0] maxRowId_in = 4'b0;
    logic [3:0] maxColId_in = 4'b0;
    logic signed [15:0] max_h_in = 16'b0;

                    // instantiate design under test
    genvar i;
    generate
    for (i = 0; i < 5; i = i + 1) begin
        pe #(.colOffset(i)) j(.clk(clk), .rst(rst), .enable(enable[i]),
                .enable_out(enable[i+1]),
                .seq1(seqOuts[i]), .seq2(seq2[i]), .h_left(i == 0 ? h_left : h_out[i-1]),
                .h_out(h_out[i]), .seq1_out(seqOuts[i+1]),
                .pointer_out(pointer_out[i]),

                .rowId_in(i == 0 ? rowId_in : rowId_out[i-1]),
                .maxRowId_in(i == 0 ? maxRowId_in : maxRowId_out[i-1]),
                .maxColId_in(i == 0 ? maxColId_in : maxColId_out[i-1]),
                .max_h_in(i == 0 ? max_h_in : max_h_out[i-1]),
                .rowId_out(rowId_out[i]), .maxRowId_out(maxRowId_out[i]),
                .maxColId_out(maxColId_out[i]), .max_h_out(max_h_out[i])

              );
    end // for
    endgenerate

    initial          // sequence of events to simulate
        begin
        clk = 0;     // at time=0 set clock to zero and reset to active (1)
        rst = 1;
        h_out[0] = 16'b0;
        h_out[1] = 16'b0;
        h_out[2] = 16'b0;
        h_out[3] = 16'b0;
        h_out[4] = 16'b0;
        enable = 6'b000001;
        #20 rst = 0; // after 2 clock ticks set reset to inactive (0)
        #5 seqOuts[0] = seq1[0];

        //genvar s;
        for (int s = 1; s < 5; s = s+1) begin
            #10 seqOuts[0] = seq1[s];
            rowId_in = s;
        end;
        // endgenerate
        #1 enable[0] = 1'b0;
        /*genvar ss;
        for (ss = 0; ss < 4; s = ss+1) begin
            #10 seqOuts[0] = seq1[ss];
        end;
        endgenerate*/

        end

    always #5       // every five simulation units...
        clk <= !clk;  // ...invert the clock

                    // produce debug output on the negative edge of the clock
    always @(negedge clk)
        $display("time=%05d: (h_out) = (%16d) %s",
        $time,      // simulator time
        h_out[0],     // outputs to display: red, amber, green
        pointer_out[0].name());

endmodule // tb_short_seq
