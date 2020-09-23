# set up the "work" library
vlib work
vlib altera_mf

# compile our SystemVerilog files
vlog datatypesPkg.sv
vlog fifo_16b_1024w.v
vlog pe_bram.v
vlog pe.sv
vlog pe_with_ram.sv
vlog backtrace_with_ram.sv
vlog med_solver_with_ram.sv
vlog med_solver_with_ram_avalon.sv
vlog tb_med_solver_with_ram.sv

# point the simulator at the compiled design
vsim -L work -L altera_mf_ver -L altera_mf work.tb_med_solver_with_ram

# add waveforms to the "Wave" pane
add wave -position insertpoint \
  /tb_med_solver_with_ram/ms/enable             \
  /tb_med_solver_with_ram/ms/seqOuts             \
  /tb_med_solver_with_ram/ms/prev_enable             \
  /tb_med_solver_with_ram/ms/gridPositions             \
  /tb_med_solver_with_ram/ms/leftColId             \
  /tb_med_solver_with_ram/ms/leftColRamId             \
  /tb_med_solver_with_ram/ms/valid_cols             \
  /tb_med_solver_with_ram/ms/maxRowId_out             \
  /tb_med_solver_with_ram/maxRowId             \
  /tb_med_solver_with_ram/maxColId             \
  /tb_med_solver_with_ram/ms/bt/currentRow             \
  /tb_med_solver_with_ram/ms/bt/currentCol             \
  /tb_med_solver_with_ram/ms/bt/ram_sel             \
  /tb_med_solver_with_ram/ms/bt/depth_sel             \
  /tb_med_solver_with_ram/ms/bt/position             \
  /tb_med_solver_with_ram/ms/h_left_left             \
  /tb_med_solver_with_ram/ms/last_col_out             \
  /tb_med_solver_with_ram/ms/last_col_rdreq             \
  /tb_med_solver_with_ram/ms/last_col_wrreq             \
  /tb_med_solver_with_ram/ms/last_col_empty             \
  /tb_med_solver_with_ram/ms/last_col_full             \
  /tb_med_solver_with_ram/ms/last_col_in             \
  /tb_med_solver_with_ram/ms/h_out             \
  /tb_med_solver_with_ram/ms/pointer_out             \
  /tb_med_solver_with_ram/ms/directPointer             \
  /tb_med_solver_with_ram/ms/basePointer             \
  /tb_med_solver_with_ram/score_grid              \
  /tb_med_solver_with_ram/ms/grid              \
  /tb_med_solver_with_ram/aligned_sequence       \
  /tb_med_solver_with_ram/ms/bt/pe_ram_out_data        \
  /tb_med_solver_with_ram/ms/bt/pe_ram_rdaddress       \
  /tb_med_solver_with_ram/ms/pe_ram_out_data        \
  /tb_med_solver_with_ram/ms/pe_ram_rdaddress       \
  /tb_med_solver_with_ram/ms/pe_ram_wraddress       \
  /tb_med_solver_with_ram/ms/pe_ram_wren            \
  /tb_med_solver_with_ram/ms/finished       \
  /tb_med_solver_with_ram/ms/grid_finished       \
  /tb_med_solver_with_ram/solver_enable               \
  /tb_med_solver_with_ram/rst               \
  /tb_med_solver_with_ram/clk                \
  /tb_med_solver_with_ram/in2                \
  /tb_med_solver_with_ram/out2               \
  /tb_med_solver_with_ram/wraddress               \
  /tb_med_solver_with_ram/rdaddress               \
  /tb_med_solver_with_ram/wren               \
  /tb_med_solver_with_ram/sclr               \
  /tb_med_solver_with_ram/in16               \
  /tb_med_solver_with_ram/wrreq               \
  /tb_med_solver_with_ram/out16               \
  /tb_med_solver_with_ram/rdreq               \
  /tb_med_solver_with_ram/empty               \
  /tb_med_solver_with_ram/full

# run simulation for 200 nanoseconds
run 12000 ns
wave zoom full
