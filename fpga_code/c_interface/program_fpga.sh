# Pass .rbf file as argument
# You may need to adjust the MSEL disp switches for this to work
# I found it to work with all 6 switches set to 0 (the side closer to the large FPGA package BGA)
# For the Cambridge CL boards, these are on the underside of the blue DE1-SoC boards, and are
# found by unscrewing the 4 Philips head (*NOT* the Torx) on the red front board with the screen.
# cf "Linux on the SoC ARM Core" in https://www.cl.cam.ac.uk/teaching/1819/ECAD+Arch/additional.html
# and DE1-SoC User Manual (Chapter 3.1, pp. 12-13 for rev F boards, which are the CL's boards)

# Disable bridges that talk to the FPGA
echo 0 > /sys/class/fpga-bridge/fpga2hps/enable
echo 0 > /sys/class/fpga-bridge/hps2fpga/enable
echo 0 > /sys/class/fpga-bridge/lwhps2fpga/enable

# Copy the bitfile
dd if=$1 of=/dev/fpga0 bs=1M

# Re-enable them
echo 1 > /sys/class/fpga-bridge/fpga2hps/enable
echo 1 > /sys/class/fpga-bridge/hps2fpga/enable
echo 1 > /sys/class/fpga-bridge/lwhps2fpga/enable
