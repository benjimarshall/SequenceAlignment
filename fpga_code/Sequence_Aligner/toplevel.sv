//
// Copyright (c) 2015 A. Theodore Markettos
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

// Top level file for DE1-SoC board with
// Cambridge display board

// Uncomment this if you have an HPS (ARM CPU) in your design
`define ENABLE_HPS

// `define LEN1 (10)
// `define LEN2 (9)
import datatypesPkg::*;

module toplevel(

      // Analogue-digital converter
/*      inout              ADC_CS_N,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      // Audio DAC
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,
*/
      // Clocks
      input              CLOCK_50,
      input              CLOCK2_50,
      input              CLOCK3_50,
      input              CLOCK4_50,

      // FPGA-side SDRAM
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      // Fan control (unused on native board)
      output             FAN_CTRL,

      // FPGA I2C
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      // General purpose I/O
      inout     [35:0]         GPIO_0,
 
      // Hex LEDs
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

`ifdef ENABLE_HPS
      // ARM Cortex A9 Hard Processor System
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
/*      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_E NET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout       [3:0]  HPS_FLASH_DATA,
      output             HPS_FLASH_DCLK,
      output             HPS_FLASH_NCSO,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_I2C2_SCLK,
      inout              HPS_I2C2_SDAT,
      inout              HPS_I2C_CONTROL,
      inout              HPS_KEY,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP,
*/
`endif /*ENABLE_HPS*/

      // Infra-red
      input              IRDA_RXD,
      output             IRDA_TXD,

      // Push buttons on DE1-SoC mainboard
      input       [3:0]  KEY,

      // Red LED row
      output      [9:0]  LEDR,

      // PS2 port
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      // Slide switches
      input       [9:0]  SW,

      // TMDS
      input              TD_CLK27,
      input      [7:0]  TD_DATA,
      input             TD_HS,
      output             TD_RESET_N,
      input             TD_VS,


      // VGA video
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS,

      // Cambridge display board (plugged into GPIO1 port)

      // rotary dials
      input       [1:0]  DIALL,
      input       [1:0]  DIALR,
      // LED pixel ring (inverted before reaching ring)
      output             LEDRINGn,
      
      // LCD display
      output      [7:0]  LCD_R_out,
      output      [7:0]  LCD_G_out,
      output      [7:0]  LCD_B_out,
      // -- only LCD_R[7:2], LCD_G[7:2], LCD_B[7:2] are wired
      // through to display board, low-order pins are ignored
      // outputs need to be inverted based on VERSION_n pin
        
      output             LCD_HSYNC,
      output             LCD_VSYNC,
      output             LCD_DEN,
      output             LCD_DCLK,
      output             LCD_ON,	    // set high to enable LCD panel
      output             LCD_BACKLIGHT, // set high to turn on backlight, PWM to dim
      
      // shift register for buttons on display board
      output             SHIFT_CLKIN,
      output             SHIFT_LOAD,
      input              SHIFT_OUT,

      // capacitive touch sensor reset (high=enabled)
      output             TOUCH_WAKE,
      // I2C for touch, temperature and EEPROM
      inout              DISPLAY_SDA,
      inout              DISPLAY_SCL,

      // externally pulled low on 2019 (green) boards
      // weak pullup inside FPGA
      input              VERSION_n

);

// your code goes here
/*
    dna_base seq1 [`LEN1-1:0] = '{A,T,C,A,G,T,T,G,G, A};
    dna_base seq2 [`LEN2-1:0] = '{G,G,C,A,T,T,G,T, A};

    logic signed [15:0] h_left = 16'b10;
    logic enable = 1'b1;
	 pe dut(.clk(CLOCK_50), .rst(1'b0), .seq1(T), .seq2(T), .h_left(h_left), .enable(enable), .h_out({HEX0, HEX1, HEX2}));

	 direction aligned_sequence [`LEN1+`LEN2-1:0];

    short_solver #(.len1(`LEN1), .len2(`LEN2)) ss(
	 .clk(CLOCK_50), 
	 .rst(!KEY[0]), 
	 .seq1(seq1), 
	 .seq2(seq2),
    .aligned_sequence(aligned_sequence));
	 
	 assign HEX0 = {1'b0, aligned_sequence[0], aligned_sequence[1], aligned_sequence[2]};
	 assign HEX1 = {1'b0, aligned_sequence[3], aligned_sequence[4], aligned_sequence[5]};
	 assign HEX2 = {1'b0, aligned_sequence[6], aligned_sequence[7], aligned_sequence[8]};
	 assign HEX3 = {1'b0, aligned_sequence[9], aligned_sequence[10], aligned_sequence[11]};
	 assign HEX4 = {1'b0, aligned_sequence[12], aligned_sequence[13], aligned_sequence[14]};
	 assign HEX5 = {1'b0, Diagonal, Above, Left};
*/

	
    accelerator_hps a (
        .clk_clk            (CLOCK_50),            //    clk.clk
        .reset_reset_n      (KEY[0]),      //  reset.reset_n
        .memory_mem_a       (HPS_DDR3_ADDR),       // memory.mem_a
        .memory_mem_ba      (HPS_DDR3_BA),      //       .mem_ba
        .memory_mem_ck      (HPS_DDR3_CK_P),      //       .mem_ck
        .memory_mem_ck_n    (HPS_DDR3_CK_N),    //       .mem_ck_n
        .memory_mem_cke     (HPS_DDR3_CKE),     //       .mem_cke
        .memory_mem_cs_n    (HPS_DDR3_CS_N),    //       .mem_cs_n
        .memory_mem_ras_n   (HPS_DDR3_RAS_N),   //       .mem_ras_n
        .memory_mem_cas_n   (HPS_DDR3_CAS_N),   //       .mem_cas_n
        .memory_mem_we_n    (HPS_DDR3_WE_N),    //       .mem_we_n
        .memory_mem_reset_n (HPS_DDR3_RESET_N), //       .mem_reset_n
        .memory_mem_dq      (HPS_DDR3_DQ),      //       .mem_dq
        .memory_mem_dqs     (HPS_DDR3_DQS_P),     //       .mem_dqs
        .memory_mem_dqs_n   (HPS_DDR3_DQS_N),   //       .mem_dqs_n
        .memory_mem_odt     (HPS_DDR3_ODT),     //       .mem_odt
        .memory_mem_dm      (HPS_DDR3_DM),      //       .mem_dm
        .memory_oct_rzqin   (HPS_DDR3_RZQ)    //       .oct_rzqin
    );


	 
    logic [27:0] count;

    always_ff @(posedge CLOCK_50) begin
        count <= count + 1;
    end

    always_comb begin
        LEDR <= count[27:18];
    end

endmodule
