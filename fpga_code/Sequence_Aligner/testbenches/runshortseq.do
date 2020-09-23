# set up the "work" library
vlib work
# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog pe.sv
vlog tb_short_seq.sv
vlog short_solver.sv

# point the simulator at the compiled design
vsim work.tb_short_seq

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_short_seq/seqOuts           \
  /tb_short_seq/seq2              \
  /tb_short_seq/h_left            \
  /tb_short_seq/h_out             \
  /tb_short_seq/maxRowId_out      \
  /tb_short_seq/maxColId_out      \
  /tb_short_seq/max_h_out         \
  /tb_short_seq/rowId_out         \
  /tb_short_seq/enable            \
  /tb_short_seq/rst               \
  /tb_short_seq/clk
# run simulation for 200 nanoseconds
run 200 ns
wave zoom full
