`include "macro.vh"

import datatypesPkg::*;

module seq_compare(input `seq_base seq1, input `seq_base seq2,
                output logic signed [`SCORE_RANGE] score);

    always_comb begin
        if (seq1 == seq2)
            score = `ALIGN_GAIN;
        else
            score = `MISALIGN_PENALTY;
    end // always_comb
endmodule

module blosum_compare(input protein_base seq1, input protein_base seq2,
                      output logic signed [`SCORE_RANGE] score);

    localparam logic [15:0] BLOSUM_50 [0:25] [0:25] =
/*A */ '{'{5, -2, -1, -2, -1, -3,  0, -2, -1,  0, -1, -2, -1, -1,  0, -1, -1, -2,  1,  0,  0,  0, -3, -1, -2, -1},
/*B */  '{-2,  5, -3,  5,  1, -4, -1,  0, -4,  0,  0, -4, -3,  4,  0, -2,  0, -1,  0,  0,  0, -4, -5, -1, -3,  2},
/*C */  '{-1, -3, 13, -4, -3, -2, -3, -3, -2,  0, -3, -2, -2, -2,  0, -4, -3, -4, -1, -1,  0, -1, -5, -2, -3, -3},
/*D */  '{-2,  5, -4,  8,  2, -5, -1, -1, -4,  0, -1, -4, -4,  2,  0, -1,  0, -2,  0, -1,  0, -4, -5, -1, -3,  1},
/*E */  '{-1,  1, -3,  2,  6, -3, -3,  0, -4,  0,  1, -3, -2,  0,  0, -1,  2,  0, -1, -1,  0, -3, -3, -1, -2,  5},
/*F */  '{-3, -4, -2, -5, -3,  8, -4, -1,  0,  0, -4,  1,  0, -4,  0, -4, -4, -3, -3, -2,  0, -1,  1, -2,  4, -4},
/*G */  '{ 0, -1, -3, -1, -3, -4,  8, -2, -4,  0, -2, -4, -3,  0,  0, -2, -2, -3,  0, -2,  0, -4, -3, -2, -3, -2},
/*H */  '{-2,  0, -3, -1,  0, -1, -2, 10, -4,  0,  0, -3, -1,  1,  0, -2,  1,  0, -1, -2,  0, -4, -3, -1,  2,  0},
/*I */  '{-1, -4, -2, -4, -4,  0, -4, -4,  5,  0, -3,  2,  2, -3,  0, -3, -3, -4, -3, -1,  0,  4, -3, -1, -1, -3},
/**J*/  '{ 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*K */  '{-1,  0, -3, -1,  1, -4, -2,  0, -3,  0,  6, -3, -2,  0,  0, -1,  2,  3,  0, -1,  0, -3, -3, -1, -2,  1},
/*L */  '{-2, -4, -2, -4, -3,  1, -4, -3,  2,  0, -3,  5,  3, -4,  0, -4, -2, -3, -3, -1,  0,  1, -2, -1, -1, -3},
/*M */  '{-1, -3, -2, -4, -2,  0, -3, -1,  2,  0, -2,  3,  7, -2,  0, -3,  0, -2, -2, -1,  0,  1, -1, -1,  0, -1},
/*N */  '{-1,  4, -2,  2,  0, -4,  0,  1, -3,  0,  0, -4, -2,  7,  0, -2,  0, -1,  1,  0,  0, -3, -4, -1, -2,  0},
/**O*/  '{ 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*P */  '{-1, -2, -4, -1, -1, -4, -2, -2, -3,  0, -1, -4, -3, -2,  0, 10, -1, -3, -1, -1,  0, -3, -4, -2, -3, -1},
/*Q */  '{-1,  0, -3,  0,  2, -4, -2,  1, -3,  0,  2, -2,  0,  0,  0, -1,  7,  1,  0, -1,  0, -3, -1, -1, -1,  4},
/*R */  '{-2, -1, -4, -2,  0, -3, -3,  0, -4,  0,  3, -3, -2, -1,  0, -3,  1,  7, -1, -1,  0, -3, -3, -1, -1,  0},
/*S */  '{ 1,  0, -1,  0, -1, -3,  0, -1, -3,  0,  0, -3, -2,  1,  0, -1,  0, -1,  5,  2,  0, -2, -4, -1, -2,  0},
/*T */  '{ 0,  0, -1, -1, -1, -2, -2, -2, -1,  0, -1, -1, -1,  0,  0, -1, -1, -1,  2,  5,  0,  0, -3,  0, -2, -1},
/**U*/  '{ 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0},
/*V */  '{ 0, -4, -1, -4, -3, -1, -4, -4,  4,  0, -3,  1,  1, -3,  0, -3, -3, -3, -2,  0,  0,  5, -3, -1, -1, -3},
/*W */  '{-3, -5, -5, -5, -3,  1, -3, -3, -3,  0, -3, -2, -1, -4,  0, -4, -1, -3, -4, -3,  0, -3, 15, -3,  2, -2},
/*X */  '{-1, -1, -2, -1, -1, -2, -2, -1, -1,  0, -1, -1, -1, -1,  0, -2, -1, -1, -1,  0,  0, -1, -3, -1, -1, -1},
/*Y */  '{-2, -3, -3, -3, -2,  4, -3,  2, -1,  0, -2, -1,  0, -2,  0, -3, -1, -1, -2, -2,  0, -1,  2, -1,  8, -2},
/*Z */  '{-1,  2, -3,  1,  5, -4, -2,  0, -3,  0,  1, -3, -1,  0,  0, -1,  4,  0,  0, -1,  0, -3, -2, -1, -2,  5}};
        // A   B   C   D   E   F   G   H   I   *J  K   L   M   N   *O  P   Q   R   S   T   *U  V   W   X   Y   Z

    always_comb begin
        score = BLOSUM_50[seq1][seq2];
    end // always_comb
endmodule

module pe
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
        output dna_base seq1_out,

        output logic signed [`SCORE_RANGE] h_out,
        output direction pointer_out
        );

logic signed [`SCORE_RANGE] h_diag;
logic signed [`SCORE_RANGE] seq_score;
seq_compare sc(.seq1(seq1), .seq2(seq2), .score(seq_score));

logic signed [`SCORE_RANGE] new_diag;
logic signed [`SCORE_RANGE] new_left;
logic signed [`SCORE_RANGE] new_above;
logic signed [`SCORE_RANGE] new_score;
direction new_pointer;

always_comb begin
    new_diag = h_diag + seq_score;
    new_left = h_left - `GAP_PENALTY;
    new_above = h_out - `GAP_PENALTY;

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
