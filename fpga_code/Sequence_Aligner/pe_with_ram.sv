`include "macro.vh"

import datatypesPkg::*;

module pe_with_ram
        #(  parameter len1 = 5,
            parameter len2 = 5
        )

        (input logic clk,
        input logic rst,
        input logic enable,
        input logic valid_col,

        input `seq_base seq1,
        input `seq_base seq2,
        input logic signed [`SCORE_RANGE] h_left,

        input logic [$clog2(len1):0] rowId_in,
        input logic [$clog2(len2):0] colId_in,
        input logic [$clog2(len1):0] maxRowId_in,
        input logic [$clog2(len2):0] maxColId_in,
        input logic signed [`SCORE_RANGE] max_h_in,

        output logic [$clog2(len1):0] rowId_out,
        output logic [$clog2(len1):0] maxRowId_out,
        output logic [$clog2(len2):0] maxColId_out,
        output logic signed [`SCORE_RANGE] max_h_out,

        output logic enable_out,
        output `seq_base seq1_out,

        output logic signed [`SCORE_RANGE] h_out,
        output direction pointer_out
        );

logic signed [`SCORE_RANGE] h_diag;
logic signed [`SCORE_RANGE] seq_score;
`match sc(.seq1(seq1), .seq2(seq2), .score(seq_score));

logic signed [`SCORE_RANGE] new_diag;
logic signed [`SCORE_RANGE] new_left;
logic signed [`SCORE_RANGE] new_above;
logic signed [`SCORE_RANGE] new_score;
direction new_pointer;

always_comb begin
    new_diag = h_diag + seq_score;
    new_left = h_left - `GAP_PENALTY;
    new_above = h_out - `GAP_PENALTY;

    // Find the best possible score out the three directions or starting afresh
    if (new_diag > 0) begin
        if (new_left > new_above) begin
            if (new_diag > new_left) begin
                new_score = new_diag;
                new_pointer = Diagonal;
            end
            else begin
                new_score = new_left;
                new_pointer = Left;
            end
        end
        else begin
            if (new_diag > new_above) begin
                new_score = new_diag;
                new_pointer = Diagonal;
            end
            else begin
                new_score = new_above;
                new_pointer = Above;
            end
        end
    end
    else begin
        if (new_left > new_above) begin
            if (new_left > 0) begin
                new_score = new_left;
                new_pointer = Left;
            end
            else begin
                new_score = 0;
                new_pointer = Nil;
            end
        end
        else begin
        if (new_above > 0) begin
                new_score = new_above;
                new_pointer = Above;
            end
            else begin
                new_score = 0;
                new_pointer = Nil;
            end
        end
    end
end


always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    h_diag <= `SCORE_MIN + `GAP_PENALTY + 10;
    h_out <= `SCORE_MIN + `GAP_PENALTY + 10;

    enable_out <= 1'b0;
    rowId_out <= {($clog2(len1)+1){1'b0}};
    maxRowId_out <= {($clog2(len1)+1){1'b0}};
    maxColId_out <= {($clog2(len2)+1){1'b0}};
    max_h_out <= 0;
  end
  else begin
    if (enable) begin
        // Process this cell's score
        h_out <= new_score;
        pointer_out <= new_pointer;

        // Keep the running maximum
        if (valid_col && new_score > max_h_out) begin
            if (new_score > max_h_in) begin
                max_h_out <= new_score;
                maxRowId_out <= rowId_in;
                maxColId_out <= colId_in;
            end
            else begin
                max_h_out <= max_h_in;
                maxRowId_out <= maxRowId_in;
                maxColId_out <= maxColId_in;
            end
        end
        else begin
            if (max_h_in > max_h_out) begin
                max_h_out <= max_h_in;
                maxRowId_out <= maxRowId_in;
                maxColId_out <= maxColId_in;
            end
            else begin
                max_h_out <= max_h_out;
                maxRowId_out <= maxRowId_out;
                maxColId_out <= maxColId_out;
            end
        end // maximum finding
    end // if enable
    else begin
        h_diag <= `SCORE_MIN + `GAP_PENALTY + 10;
        h_out <= `SCORE_MIN + `GAP_PENALTY + 10;
    end // if not enable

    enable_out <= enable;
    seq1_out <= seq1;

    rowId_out <= rowId_in;

    // h_out <= h_out + `ALIGN_GAIN;

    h_diag <= h_left;

  end
end

endmodule // pe
