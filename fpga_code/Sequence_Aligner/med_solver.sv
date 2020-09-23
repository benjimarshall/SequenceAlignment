`timescale 1ns / 1ps
`include "macro.vh"

import datatypesPkg::*;

module med_solver
        #( parameter max_len1 = 5,
           parameter max_len2 = 5,
           parameter pipeline_length = 5 )
        ( input clk,
          input rst,
          input logic signed [$clog2(max_len1)+1:0] len1,
          input logic signed [$clog2(max_len2)+1:0] len2,
          input dna_base seq1 [0:max_len1-1],
          input dna_base seq2 [0:max_len2-1],

          output logic grid_finished,
          output logic finished,
          output logic [$clog2(max_len1):0] maxRowId,
          output logic [$clog2(max_len2):0] maxColId,
          output logic [0:max_len1-1] [15:0] score_grid [0:max_len2-1],
          output direction grid [0:max_len2-1] [0:max_len1-1],

          output direction aligned_sequence [0:max_len1+max_len2-1]
        );


    // dna_base [4:0] seq1 = {C,A,G,T, A};
    // dna_base [4:0] seq2 = {G,C,A,T, A};
    logic signed [15:0] h_left_left;
    logic [pipeline_length:0] enable;     // junk msb, but when it hits 0 all is written out
    dna_base seqOuts [pipeline_length:0]; // junk msb
    logic signed [15:0] h_out [pipeline_length-1:0];
    direction pointer_out [pipeline_length-1:0];
    logic [pipeline_length-1:0] valid_cols;

    dna_base seq2_in [pipeline_length-1:0];

    logic [$clog2(max_len1):0] rowId_in = {($clog2(max_len1)+1){1'b0}};
    logic [$clog2(max_len1):0] maxRowId_in = {($clog2(max_len1)+1){1'b0}};
    logic [$clog2(max_len2):0] maxColId_in = {($clog2(max_len2)+1){1'b0}};
    logic signed [15:0] max_h_in = 16'b0;

    logic signed [$clog2(max_len1):0] rowId_out [pipeline_length-1:0];
    logic signed [$clog2(max_len1):0] maxRowId_out [pipeline_length-1:0];
    logic signed [$clog2(max_len2):0] maxColId_out [pipeline_length-1:0];
    logic signed [15:0] max_h_out [pipeline_length-1:0];

    logic signed [$clog2(max_len2):0] leftColId;
    logic grid_finished;

    logic last_col_empty;
    logic last_col_full;
    logic last_col_rdreq;
    logic last_col_wrreq;
    logic signed [15:0] last_col_in;
    assign last_col_in = h_out[pipeline_length-1];
    logic [15:0] last_col_out;


    assign maxRowId = maxRowId_out[pipeline_length-1];
    assign maxColId = maxColId_out[pipeline_length-1];

                    // instantiate design
    parameter int max_len2_width  = $clog2(max_len2) + 1;
    genvar i;
    generate
    for (i = 0; i < pipeline_length; i = i + 1) begin : generate_pes
        parameter bit [max_len2_width-1:0] colId = i;

        pe #(.len1(max_len1), .len2(max_len2))
            pe_cell(.clk(clk), .rst(rst), .enable(enable[i]),
                .enable_out(enable[i+1]),
                .valid_col(valid_cols[i]),
                .seq1(seqOuts[i]), .seq2(seq2_in[i]), .h_left(i == 0 ? h_left_left : h_out[i-1]),

                .rowId_in(i == 0 ? rowId_in : rowId_out[i-1]),
                .colId_in(leftColId + colId),
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

    logic signed [$clog2(max_len1):0] gridPositions [pipeline_length-1:0];
    logic [pipeline_length:0] prev_enable;     // junk msb

    logic gridLessThan;

    fifo_16b_1024w last_col_fifo (.aclr(rst), .clock(clk), .sclr(1'b0),
        .data(last_col_in), .rdreq(last_col_rdreq),
        .q(last_col_out), .wrreq(last_col_wrreq),
        .empty(last_col_empty), .full(last_col_full)
    );

    backtrace #(.len1(max_len1), .len2(max_len2)) bt
       (.clk(clk), .rst(rst), .enable(grid_finished), .grid(grid), .startRow(maxRowId), .startCol(maxColId),
        .finished(finished), .aligned_sequence(aligned_sequence)
       );

    always_comb begin
        if (leftColId == {($clog2(max_len2)+1){1'b0}})
            h_left_left =  16'b1000_0000_0000_0000 + `GAP_PENALTY + 10;
        else
            h_left_left = last_col_out;
    end

    always_ff @(posedge clk or posedge rst) begin
        gridLessThan <= gridPositions[0] < len1 -2;

        if(rst) begin
            grid_finished <= 1'b0;
            prev_enable <= {(pipeline_length+1){1'b0}};

            enable[0] <= 1'b1;
            leftColId <= {($clog2(max_len2)+1){1'b0}};
            seqOuts[0] <= seq1[0];

            last_col_rdreq <= 1'b0;
            last_col_wrreq <= 1'b0;

            valid_cols <= {(pipeline_length-1){1'b1}};

            for (int i = 0; i < pipeline_length; i = i + 1) begin
                gridPositions[i] <= {($clog2(max_len1)+1){1'b1}};
                seq2_in[i] <= seq2[i];
            end

            for (int i = 0; i < max_len2; i = i + 1) begin
                score_grid[i] <= {(max_len1+1){16'b0}};
                grid[i] <= '{(max_len1){Nil}};
            end // for
        end
        else begin
            if (gridPositions[0] < len1 -2) begin
                seqOuts[0] <= seq1[gridPositions[0]+2];
                rowId_in <= gridPositions[0]+2;
                if (leftColId == {($clog2(max_len2)+1){1'b0}})
                    last_col_rdreq <= 1'b0;
                else
                    last_col_rdreq <= 1'b1;
            end
            else begin
                enable[0] <= 1'b0;
                last_col_rdreq <= 1'b0;
            end

            for (int j = 0; j < pipeline_length; j = j + 1) begin
                if (len2 > leftColId + j)
                    valid_cols[j] <= 1'b1;
                else
                    valid_cols[j] <= 1'b0;

                if (enable[j] == 1'b1)
                    gridPositions[j] <= gridPositions[j] + 1;

                if (prev_enable[j] == 1'b1) begin
                    score_grid[leftColId + j][gridPositions[j]] <= h_out[j];
                    grid[leftColId + j][gridPositions[j]] <= pointer_out[j];
                end // if
            end // for

            if (prev_enable[pipeline_length-1] == 1'b1) begin
                last_col_wrreq <= 1'b1;
            end
            else begin
                last_col_wrreq <= 1'b0;
            end

            prev_enable <= enable;

            if (enable == {(pipeline_length+1){1'b0}}) begin
                if (leftColId + pipeline_length >= len2) begin
                    grid_finished <= 1'b1;
                    leftColId <= leftColId;
                end
                else begin
                    enable[0] <= 1'b1;
                    leftColId <= leftColId + pipeline_length;
                    seqOuts[0] <= seq1[0];
                    last_col_rdreq <= 1'b1;

                    for (int i = 0; i < pipeline_length; i = i + 1) begin
                        gridPositions[i] <= {($clog2(max_len1)+1){1'b1}};
                        seq2_in[i] <= seq2[leftColId + pipeline_length + i];
                    end
                end
            end // if enable = 000000
            else leftColId <= leftColId;

        end //else rst
    end // always_ff

endmodule // short_solver
