# set up the "work" library
vlib work
# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog pe.sv
vlog tb_short_seq.sv
vlog backtrace.sv
vlog short_solver.sv
vlog tb_short_solver.sv

# point the simulator at the compiled design
vsim work.tb_short_solver

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_short_solver/ss/enable             \
  /tb_short_solver/ss/seqOuts             \
  /tb_short_solver/ss/prev_enable             \
  /tb_short_solver/ss/gridPositions             \
  /tb_short_solver/maxRowId             \
  /tb_short_solver/maxColId             \
  /tb_short_solver/ss/h_out             \
  /tb_short_solver/score_grid              \
  /tb_short_solver/ss/grid              \
  /tb_short_solver/aligned_sequence       \
  /tb_short_solver/ss/finished       \
  /tb_short_solver/ss/grid_finished       \
  /tb_short_solver/rst               \
  /tb_short_solver/clk

#  /tb_short_solver/ss/rowId_in             \
#  /tb_short_solver/ss/rowId_out             \
#  /tb_short_solver/ss/maxRowId_out             \
#  /tb_short_solver/ss/maxColId_out             \
#  /tb_short_solver/ss/max_h_out             \

# run simulation for 200 nanoseconds
run 500 ns
wave zoom full
