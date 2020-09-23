`include "macro.vh"

import datatypesPkg::*;

// See backtrace.sv for a more self-explantory overview, without any complicated addressing to confuse you before
// trying to understand this. The addressing is quite fiddly, but it was good enough for what I was trying to
// investigate with my project

module backtrace_with_ram
        #(  parameter len1 = 5,
            parameter len2 = 5,
            parameter pipeline_length = 6
        )

       (input logic clk,
        input logic rst,
        input logic enable,
        input logic [$clog2(len1):0] startRow,
        input logic [$clog2(len2):0] startCol,

        input logic [1:0] pe_ram_out_data [pipeline_length-1:0],
        output logic [14:0] pe_ram_rdaddress [pipeline_length-1:0],

        output logic finished,
        output direction aligned_sequence [0:len1+len2-1]
       );

    logic [$clog2(len1+len2)+1:0] position;
    logic [$clog2(len1):0] currentRow;
    logic [$clog2(len2):0] currentCol;
    logic [$clog2(len2):0] leftCol;
    direction current_pointer;

    logic [$clog2(pipeline_length):0] ram_sel;
    logic [$clog2((len1*len2/pipeline_length)-1):0] depth_sel;

always_comb begin
    // Which RAM block to read from, calcuated from the current column index
    ram_sel = {1'b0, currentCol[$clog2(pipeline_length)-1:0]};
    // Which pointer in the BRAM to read from, calcuated from the current column and row indices
    depth_sel = ((currentCol >> $clog2(pipeline_length)) << $clog2(len1)) + currentRow;

    // All BRAMs share a read address request value for simplicity
    for (int i = 0; i < pipeline_length; i = i + 1) begin
        pe_ram_rdaddress[i] = depth_sel;
    end
    // Multiplexer to select the value being read out from BRAM, from the currently desired BRAM
    current_pointer = direction'({pe_ram_out_data[ram_sel]});

    // Index of the column to the left of the current one. Note due to weird addressing is that the column indices are
    // not continuous, and skip over values 48..63 under modulo 64, eg in sequence: ...46, 47, 64, 65...
    // This is relatively easy to implement with bit shifts, albeit a bit strange
    if (currentCol[$clog2(pipeline_length)-1:0] == {($clog2(pipeline_length)){1'b0}})
        leftCol = (((currentCol >> $clog2(pipeline_length)) - 1) << $clog2(pipeline_length)) + (pipeline_length-1);
    else
        leftCol = currentCol - 1;
end // always_comb


always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        finished <= 1'b0;
        aligned_sequence <= '{(len1+len2){Nil}};

        position <= {$clog2(len1+len2+2){1'b0}};
        currentRow <= startRow;
        currentCol <= startCol;
    end
    else begin
        if (enable) begin
            // We need to wait two cycles due to BRAM read delays
            // (Indexed by 2 LSBs of position).

            // Can't use pipelining because the next BRAM read address depends
            // on the value we're reading in the Left/Diagonal case because
            // both of those values are stored (consecutively) in one BRAM

            // However, this should be a 1 cycle wait but due to some register
            // inference bug I've not been able to find, it actually takes 2
            if (finished == 1'b0 && position[1:0] == 2'b11) begin
                position <= position + 2;

                aligned_sequence[position >> 2] <= current_pointer;

                case (current_pointer)
                    Above : currentRow <= currentRow - 1;
                    Left : currentCol <= leftCol;
                    Diagonal : begin
                            currentRow <= currentRow - 1;
                            currentCol <= leftCol;
                    end
                    Nil : finished <= 1'b1;
                endcase
            end // if not finished
            else
                position <= position + 1;
        end
        else begin
            currentRow <= startRow;
            currentCol <= startCol;
        end
    end // if enable
end

endmodule
