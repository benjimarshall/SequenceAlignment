`timescale 1ns / 1ps
`include "macro.vh"

import datatypesPkg::*;

module short_solver
        #( parameter len1 = 5,
           parameter len2 = 5 )
        ( input clk,
          input rst,
          input dna_base seq1 [len1-1:0],
          input dna_base seq2 [len2-1:0],

          output logic finished,
          output logic [$clog2(len1):0] maxRowId,
          output logic [$clog2(len2):0] maxColId,
          output logic [0:len1-1] [15:0] score_grid [0:len2-1],
          output direction grid [0:len2-1] [0:len1-1],

          output direction aligned_sequence [0:len1+len2-1]
        );


    // dna_base [4:0] seq1 = {C,A,G,T, A};
    // dna_base [4:0] seq2 = {G,C,A,T, A};
    logic signed [15:0] h_left =  16'b1000_0000_0000_0000 + `GAP_PENALTY + 10;
    logic [len2:0] enable;     // junk msb, but when it hits 0 all is written out
    dna_base seqOuts [len2:0]; // junk msb
    logic signed [15:0] h_out [len2-1:0];
    direction pointer_out [len2-1:0];

    logic [$clog2(len1):0] rowId_in = {($clog2(len1)+1){1'b0}};
    logic [$clog2(len1):0] maxRowId_in = {($clog2(len1)+1){1'b0}};
    logic [$clog2(len2):0] maxColId_in = {($clog2(len2)+1){1'b0}};
    logic signed [15:0] max_h_in = 16'b0;

    logic signed [$clog2(len1):0] rowId_out [len2-1:0];
    logic signed [$clog2(len1):0] maxRowId_out [len2-1:0];
    logic signed [$clog2(len2):0] maxColId_out [len2-1:0];
    logic signed [15:0] max_h_out [len2-1:0];

    logic grid_finished;

    assign maxRowId = maxRowId_out[len2-1];
    assign maxColId = maxColId_out[len2-1];

                    // instantiate design

    parameter int len2_width  = $clog2(len2) + 1;
    genvar i;
    generate
    for (i = 0; i < len2; i = i + 1) begin : generate_pes
        parameter bit [len2_width-1:0] colId = i;

        pe #(.len1(len1), .len2(len2))
            pe_cell(.clk(clk), .rst(rst), .enable(enable[i]),
                .enable_out(enable[i+1]),
                .valid_col(1'b1),
                .seq1(seqOuts[i]), .seq2(seq2[i]), .h_left(i == 0 ? h_left : h_out[i-1]),

                .rowId_in(i == 0 ? rowId_in : rowId_out[i-1]),
                .colId_in(colId),
                .maxRowId_in(i == 0 ? maxRowId_in : maxRowId_out[i-1]),
                .maxColId_in(i == 0 ? maxColId_in : maxColId_out[i-1]),
                .max_h_in(i == 0 ? max_h_in : max_h_out[i-1]),

                .rowId_out(rowId_out[i]),
                .maxRowId_out(maxRowId_out[i]),
                .maxColId_out(maxColId_out[i]),
                .max_h_out(max_h_out[i]),

                .h_out(h_out[i]), .seq1_out(seqOuts[i+1]),
                .pointer_out(pointer_out[i])
              );
    end // for
    endgenerate

    logic signed [$clog2(len1):0] gridPositions [len2-1:0];
    logic [len2:0] prev_enable;     // junk msb

    backtrace #(.len1(len1), .len2(len2)) bt
       (.clk(clk), .rst(rst), .enable(grid_finished), .grid(grid), .startRow(maxRowId), .startCol(maxColId),
        .finished(finished), .aligned_sequence(aligned_sequence)
       );

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            enable[0] <= 1'b1;
            grid_finished <= 1'b0;

            prev_enable <= {(len2){1'b0}};
            seqOuts[0] <= seq1[0];
            for (int i = 0; i < len2; i = i + 1) begin
                score_grid[i] <= {(len1+1){16'b0}};
                grid[i] <= '{(len1){Nil}};
                gridPositions[i] <= {($clog2(len1)+1){1'b1}};
            end // for
        end
        else begin
            if (gridPositions[0] < len1 -2) begin
                seqOuts[0] = seq1[gridPositions[0]+2];
                rowId_in <= gridPositions[0]+2;
            end
            else
                enable[0] <= 1'b0;

            for (int j = 0; j < len2; j = j + 1) begin
                if (enable[j] == 1'b1)
                    gridPositions[j] <= gridPositions[j] + 1;

                if (prev_enable[j] == 1'b1) begin
                    score_grid[j][gridPositions[j]] <= h_out[j];
                    grid[j][gridPositions[j]] <= pointer_out[j];
                end // if
            end // for

            prev_enable <= enable;

            if (enable == {(len2+1){1'b0}})
                grid_finished <= 1'b1;

        end //else
    end // always_ff

endmodule // short_solver
