# set up the "work" library
vlib work
vlib altera_mf

# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog pe.sv
vlog tb_blosum.sv

# point the simulator at the compiled design
vsim -L work -L altera_mf_ver -L altera_mf work.tb_blosum

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_blosum/clk    \
  /tb_blosum/seq1   \
  /tb_blosum/seq2   \
  /tb_blosum/score

# run simulation for 200 nanoseconds
run 300 ns
wave zoom full
