`timescale 1ns / 1ps

import datatypesPkg::*;

module tb_pe(output logic signed [15:0] h_out,
             output direction pointer_out,
             output logic signed [15:0] new_diag,
             output logic signed [15:0] new_left,
             output logic signed [15:0] new_above);

    logic clk;      // clock signal we are going to generate
    logic rst;      // the reset input used to initialise the system

    dna_base seq1 = T;
    dna_base seq2 = T;
    logic signed [15:0] h_left = 16'b10;
    logic enable = 1'b1;

                    // instantiate design under test (dut)
    pe dut(.clk(clk), .rst(rst), .seq1(seq1), .seq2(seq2), .h_left(h_left), .enable(enable),
           .h_out(h_out),
           .pointer_out(pointer_out)
          );

    initial          // sequence of events to simulate
        begin
        clk = 0;     // at time=0 set clock to zero and reset to active (1)
        rst = 1;
        h_out = 16'b0;
        #20 rst = 0; // after 2 clock ticks set reset to inactive (0)
        end

    always #5       // every five simulation units...
        clk <= !clk;  // ...invert the clock

                    // produce debug output on the negative edge of the clock
    always @(negedge clk)
        $display("time=%05d: (h_out) = (%16d) %s",
        $time,      // simulator time
        h_out,     // outputs to display: red, amber, green
        pointer_out.name());

endmodule // tb_pe
