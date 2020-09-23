`timescale 1ns / 1ps
`include "macro.vh"

`define LEN1 (10)
`define LEN2 (9)

import datatypesPkg::*;

module short_solver_avalon(
    input logic clk,
    input logic rst,

    // data memory port (read/write)

    // The address the processor asked for (minus the base address of the memory-mapped region). Note that this is just a signal and doesn't correspond to any real memory: our accelerator can interpret it how it likes.
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
    logic [$clog2(`LEN1):0] maxRowId;
    logic [$clog2(`LEN2):0] maxColId;
    logic [0:`LEN1-1] [15:0] score_grid [0:`LEN2-1];
    direction grid [0:`LEN2-1] [0:`LEN1-1];
    direction aligned_sequence [0:`LEN1+`LEN2-1] = '{Above,Left,Diagonal,Nil, Above,Left,Diagonal,Nil, Above,Left,Diagonal,Nil, Above,Left,Diagonal,Nil, Above,Left,Diagonal};
    dna_base seq1 [0:`LEN1-1] = '{A,T,C,A,G,T,T,G,G, A};
    dna_base seq2 [0:`LEN2-1] = '{G,G,C,A,T,T,G,T, A};

                    // instantiate design under test
    short_solver #(.len1(`LEN1), .len2(`LEN2)) ss(.clk(clk), .rst(rst), .seq1(seq1), .seq2(seq2),
    .finished(finished), .maxRowId(maxRowId), .maxColId(maxColId), .grid(grid), .score_grid(score_grid), .aligned_sequence(aligned_sequence));

    always_comb begin
        if (avm_main_address < 9'd61) begin
            // Pack the corresponding result value into the 64-bit register
            avm_main_readdata[63:`LEN1+`LEN2+1] = 0;
            for (int i = 0; i < `LEN1+`LEN2; i = i+1) begin
                avm_main_readdata[(2*i+1)+:2] = {aligned_sequence[i]};
            end
            //for (int i = 0; i < 31; i = i+1) begin
            //    avm_main_readdata[(2*i+2)+:2] = {aligned_sequence[i]};
            //end
            avm_main_readdata[1] = finished;
            avm_main_readdata[0] = finished;
        end else avm_main_readdata = 64'bx;
    end



endmodule // short_solver_avalon
