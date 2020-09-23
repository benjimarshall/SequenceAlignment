`ifndef macros_vh
// NOTE: for Verilog 1995 `ifndef is not supported use `ifdef macros_vh `else
`define macros_vh

`define SCORE_RANGE 15:0
`define SCORE_WIDTH 16
`define SCORE_MIN 16'b1000_0000_0000_0000

// `define match blosum_compare
// `define seq_base protein_base

`define DNA_MODE 1
`define seq_base dna_base
`define match seq_compare

`define ALIGN_GAIN (16'sd5)
`define MISALIGN_PENALTY (-16'sd4)
`define GAP_PENALTY (16'sd2)

`endif
