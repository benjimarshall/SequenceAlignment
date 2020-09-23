# set up the "work" library
vlib work
vlib altera_mf

# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog fifo_16b_1024w.v
vlog pe.sv
vlog backtrace.sv
vlog short_solver.sv
vlog med_solver.sv
vlog tb_med_solver.sv

# point the simulator at the compiled design
vsim -L work -L altera_mf_ver -L altera_mf work.tb_med_solver

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_med_solver/ms/enable             \
  /tb_med_solver/ms/seqOuts             \
  /tb_med_solver/ms/prev_enable             \
  /tb_med_solver/ms/gridPositions             \
  /tb_med_solver/ms/leftColId             \
  /tb_med_solver/ms/gridLessThan             \
  /tb_med_solver/ms/valid_cols             \
  /tb_med_solver/ms/maxRowId_out             \
  /tb_med_solver/maxRowId             \
  /tb_med_solver/maxColId             \
  /tb_med_solver/ms/bt/currentRow             \
  /tb_med_solver/ms/bt/currentCol             \
  /tb_med_solver/ms/h_left_left             \
  /tb_med_solver/ms/last_col_out             \
  /tb_med_solver/ms/last_col_rdreq             \
  /tb_med_solver/ms/last_col_wrreq             \
  /tb_med_solver/ms/last_col_empty             \
  /tb_med_solver/ms/last_col_full             \
  /tb_med_solver/ms/last_col_in             \
  /tb_med_solver/ms/h_out             \
  /tb_med_solver/score_grid              \
  /tb_med_solver/ms/grid              \
  /tb_med_solver/aligned_sequence       \
  /tb_med_solver/ms/finished       \
  /tb_med_solver/ms/grid_finished       \
  /tb_med_solver/rst               \
  /tb_med_solver/clk                \
  /tb_med_solver/sclr               \
  /tb_med_solver/in16               \
  /tb_med_solver/wrreq               \
  /tb_med_solver/out16               \
  /tb_med_solver/rdreq               \
  /tb_med_solver/empty               \
  /tb_med_solver/full

# run simulation for 200 nanoseconds
run 1200 ns
wave zoom full
