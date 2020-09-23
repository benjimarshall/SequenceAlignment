`timescale 1ns / 1ps
`include "macro.vh"

`define MAX_LEN1 (1024)
`define MAX_LEN2 (1536)
`define PIPELINE_LENGTH (48)

import datatypesPkg::*;

module med_solver_with_ram_avalon(
    input logic clk,
    input logic rst,

    // data memory port (read/write)

    // The address the processor asked for (minus the base address of the memory-mapped region). Note that this is just a signal and doesn't correspond to any real memory: our accelerator can interpret it how it likes.
    input logic [9:0] avm_main_address,
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

    logic solver_enable;

    `seq_base seq1 [0:`MAX_LEN1-1];
    `seq_base seq2 [0:`MAX_LEN2-1];
    logic [$clog2(`MAX_LEN1)+1:0] len1;
    logic [$clog2(`MAX_LEN2)+1:0] len2;
    logic solver_rst;

    logic finished;
    direction aligned_sequence [0:`MAX_LEN1+`MAX_LEN2-1];
    logic [$clog2(`MAX_LEN1):0] maxRowId;
    logic [$clog2(`MAX_LEN2):0] maxColId;
    logic grid_finished;

    // The accelerator logic block
    med_solver_with_ram #(.max_len1(`MAX_LEN1), .max_len2(`MAX_LEN2), .pipeline_length(`PIPELINE_LENGTH)) ms (
        .clk(clk),
        .rst(solver_rst),
        .solver_enable(solver_enable),
        .len1(len1),
        .len2(len2),
        .seq1(seq1),
        .seq2(seq2),
        .maxRowId(maxRowId),
        .maxColId(maxColId),
        .finished(finished),
        .grid_finished(grid_finished),
        .aligned_sequence(aligned_sequence)
    );

    // Reading is instantaneous, though there is no requirement to actually read some registers, a value just needs to
    // end up on the read data bus, and that value could depend on the address requested. No checks are made here to
    // see if the HPS is actually reading, the read value for the address on the address bus is just put out on the
    // read address bus. With a different setup you could use a read request / read ready protocol (to read from BRAMs
    // for example which take a couple of cycles), but this wasn't necessary here because BRAMs were dedicated to the
    // pointer grid and the aligned sequence is so much smaller that it can fit in registers (pointer grid scales
    // quadratically, sequence is just linear).
    always_comb begin
        // Special address 0 giving status bits, and the end points of the alignment
        if (avm_main_address == 10'd0) begin
            // Zero the unused bits between MSB and start of column index of maximum cell
            avm_main_readdata[63:$clog2(`MAX_LEN2)+48+1] = 0;

            // The column index of the maximum cell
            // This is indexed in a very strange way to be able to address the RAM blocks, which is hard when the
            // number of processing elements is not a power of two. My final design had it at 48.
            avm_main_readdata[$clog2(`MAX_LEN2)+48:48] =
                ((maxColId >> $clog2(`PIPELINE_LENGTH)) << ($clog2(`PIPELINE_LENGTH) - 1))
                + ((maxColId >> $clog2(`PIPELINE_LENGTH)) << ($clog2(`PIPELINE_LENGTH) - 2))
                + {{($clog2(`MAX_LEN2) - $clog2(`PIPELINE_LENGTH)){1'b0}},
                + maxColId[$clog2(`PIPELINE_LENGTH)-1:0]};

            // Zero the unused bits column index of maximum cell and row index of maximum cell
            avm_main_readdata[47:$clog2(`MAX_LEN1)+32+1] = 0;

            // The row index of the maximum cell
            avm_main_readdata[$clog2(`MAX_LEN1)+32:32] = maxRowId;

            avm_main_readdata[31:3] = 0;
            avm_main_readdata[2] = solver_enable;
            avm_main_readdata[1] = grid_finished;
            avm_main_readdata[0] = finished;
        end
        else begin
            // Output the sequence of backtraced pointers (which start the maximum scoring cell)
            // Outputs a 64 bit value, made up of null terminated sequence 2 bit pointers. (A null is an aligned 2b0)
            // After the null, no guarantees are made. Under the current design it should just be continuous 0s
            // but in past designs it could be garbage from a previous alignment.
            // An upper bound on the length is max(len1, len2) for SW, but more overhead is left here from when this
            // was prototyped as NW giving 64*32=2048 pointers
            if (avm_main_address <= 10'd64) begin
                for (int i = 0; i < 32; i = i+1) begin
                    avm_main_readdata[(2*i)+:2] = {aligned_sequence[31-i + ((avm_main_address-1) << 5)]};
                end
            end else avm_main_readdata = 64'bx; // Requesting an address that is out of bounds gets you some garbage
        end
    end

    // HPS writing a job to the FPGA uses synchronous logic (writing up to an address per FPGA cycle)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            solver_enable <= 1'b0;
            solver_rst <= 1'b0;
            len1 <= {($clog2(`MAX_LEN1)+2){1'b0}};
            len2 <= {($clog2(`MAX_LEN2)+2){1'b0}};
        end
        else begin
            // Detect magic address the processor writes to when indicating the accelerator should start
            if (avm_main_address == 10'd0 && avm_main_write) begin
                if (avm_main_writedata[0] == 1'b1) begin // starting solver
                    solver_enable <= 1'b1;
                    solver_rst <= 1'b0;
                    len1 <= avm_main_writedata[32+$clog2(`MAX_LEN1)+1:32];
                    len2 <= avm_main_writedata[48+$clog2(`MAX_LEN2)+1:48];
                end
                else begin // resetting solver
                    solver_enable <= 1'b0;
                    solver_rst <= 1'b1;
                end
            end
            else begin // writing a section of sequence input
                if (`DNA_MODE) begin
                    // DNA input logic
                    // Different to proteins because of different data sizes (2b for nucleotide, 5b for amino acid)
                    if (avm_main_address <= 10'd32 && avm_main_write) begin
                        for (int i = 0; i < 32; i = i+1) begin
                            seq1[31-i + ((avm_main_address-1) << 5)] <= dna_base'(avm_main_writedata[(2*i)+:2]);
                        end
                    end
                    else if (avm_main_address <= 10'd80 && avm_main_write) begin
                        for (int i = 0; i < 32; i = i+1) begin
                            seq2[31-i + ((avm_main_address-1-32) << 5)] <= dna_base'(avm_main_writedata[(2*i)+:2]);
                        end
                    end
                end else begin
                    // Protein input logic
                    if (avm_main_address <= 10'd128 && avm_main_write) begin
                        for (int i = 0; i < 8; i = i+1) begin
                            seq1[7-i + ((avm_main_address-1) << 3)] <= protein_base'(avm_main_writedata[(5*i)+:5]);
                        end
                    end
                    else if (avm_main_address <= 10'd320 && avm_main_write) begin
                        for (int i = 0; i < 8; i = i+1) begin
                            seq2[7-i + ((avm_main_address-1-128) << 3)] <= protein_base'(avm_main_writedata[(5*i)+:5]);
                        end
                    end
                end

                if (finished)
                    solver_enable <= 1'b0;
                else
                    solver_enable <= solver_enable;
            end // else not magic write address
        end // if not rst
    end // always_ff
endmodule // short_solver_avalon
