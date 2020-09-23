`timescale 1ns / 1ps
`include "macro.vh"

`define LEN1 (46)
`define LEN2 (41)
`define MAX_LEN1 (46)
`define MAX_LEN2 (46)

import datatypesPkg::*;

module med_solver_avalon(
    input logic clk,
    input logic rst,

    // data memory port (read/write)

    // The address the processor asked for (minus the base address of the memory-mapped region).
    // Note that this is just a signal and doesn't correspond to any real memory:
    // our accelerator can interpret it how it likes.
    input logic [5:0] avm_main_address,
    // Could allow the processor to specify smaller writes than 64-bit, but we don't use it.
    input logic [7:0]  avm_main_byteenable,
    // Whether the processor is requesting a read.
    input logic        avm_main_read,
    // Data we can send in response to read requests
    output  logic [63:0] avm_main_readdata,
    // Whether the processor is requesting a write
    input logic        avm_main_write,
    // Data the processor sends alongside a write request
    input logic [63:0] avm_main_writedata
    //output  logic        avm_main_waitrequest,
    //output  logic        avm_main_readdatavalid
);

    logic finished;
    logic [$clog2(`MAX_LEN1):0] maxRowId;
    logic [$clog2(`MAX_LEN2):0] maxColId;
    logic [`MAX_LEN1-1:0] [15:0] score_grid [`MAX_LEN2-1:0];
    direction grid [`MAX_LEN2-1:0] [`MAX_LEN1-1:0];
    direction aligned_sequence [`MAX_LEN1+`MAX_LEN2-1:0];
    dna_base seq1 [`MAX_LEN1-1:0] = '{A,T,C,A,G,T,T,G,G,A,T,C,A,G,T,T,G,G,A,T,C,A,G,T,T,G,G,A,T,C,
                                      A,G,T,T,G,G,A,T,C,A,G,T,T,G,G, A};
    dna_base seq2 [`MAX_LEN2-1:0] = '{A,A,A,A,A, G,G,C,A,T,T,G,T,G,G,C,A,T,T,G,T,G,G,C,A,T,T,G,T,G,
                                      G,C,A,T,T,G,T,G,G,C,A,T,T,G,T, A};

    med_solver #(.max_len1(`MAX_LEN1), .max_len2(`MAX_LEN2), .pipeline_length(16)) ms (
        .clk(clk),
        .rst(rst),
        .len1(8'd46),
        .len2(8'd41),
        .seq1(seq1),
        .seq2(seq2),
        .finished(finished),
        .maxRowId(maxRowId),
        .maxColId(maxColId),
        .grid(grid),
        .score_grid(score_grid),
        .aligned_sequence(aligned_sequence)
    );


    always_comb begin
        if (avm_main_address == 6'd0) begin
            avm_main_readdata[63:2] = 0;
            avm_main_readdata[1] = finished;
            avm_main_readdata[0] = finished;
        end
        else begin
            if (avm_main_address < 6'd3) begin
                for (int i = 0; i < 32; i = i+1) begin
                    avm_main_readdata[(2*i)+:2] = {aligned_sequence[i + avm_main_address - 1]};
                end
            end else avm_main_readdata = 64'bx;
        end
    end



endmodule // short_solver_avalon
