# set up the "work" library
vlib work
# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog pe.sv
vlog tb_pe.sv

# point the simulator at the compiled design
vsim work.tb_pe

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_pe/seq1              \
  /tb_pe/seq2              \
  /tb_pe/h_left            \
  /tb_pe/h_out             \
  /tb_pe/rst               \
  /tb_pe/clk
# run simulation for 200 nanoseconds
run 200 ns
wave zoom full
