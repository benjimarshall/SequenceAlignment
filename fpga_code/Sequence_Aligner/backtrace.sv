`include "macro.vh"

import datatypesPkg::*;

module backtrace
        #(  parameter len1 = 5,
            parameter len2 = 5
        )

       (input logic clk,
        input logic rst,
        input logic enable,
        input direction grid [0:len2-1] [0:len1-1],
        input logic [$clog2(len1):0] startRow,
        input logic [$clog2(len2):0] startCol,

        output logic finished,
        output direction aligned_sequence [0:len1+len2-1]
       );

    logic [$clog2(len1+len2)-1:0] position;
    logic [$clog2(len1):0] currentRow;
    logic [$clog2(len2):0] currentCol;


always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        finished <= 1'b0;
        aligned_sequence <= '{(len1+len2){Nil}};

        position <= {$clog2(len1+len2){1'b0}};
        currentRow <= startRow;
        currentCol <= startCol;
    end
    else begin
        if (enable) begin
            if (finished == 1'b0) begin
                aligned_sequence[position] <= grid[currentCol][currentRow];
                position <= position + 1;

                case (grid[currentCol][currentRow])
                    Above : currentRow <= currentRow - 1;
                    Left : currentCol <= currentCol - 1;
                    Diagonal : begin
                            currentRow <= currentRow - 1;
                            currentCol <= currentCol - 1;
                    end
                    Nil : finished <= 1'b1;
                endcase
            end // if not finished
        end
        else begin
            currentRow <= startRow;
            currentCol <= startCol;
        end
    end // if enable
end

endmodule
