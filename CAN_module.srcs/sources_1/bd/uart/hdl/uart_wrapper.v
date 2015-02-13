//Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2014.3.1 (win64) Build 1056140 Thu Oct 30 17:03:40 MDT 2014
//Date        : Fri Feb 06 18:09:45 2015
//Host        : HotChocolate running 64-bit major release  (build 9200)
//Command     : generate_target uart_wrapper.bd
//Design      : uart_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module uart_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    MIO,
    uart_rtl_baudoutn,
    uart_rtl_ctsn,
    uart_rtl_dcdn,
    uart_rtl_ddis,
    uart_rtl_dsrn,
    uart_rtl_dtrn,
    uart_rtl_out1n,
    uart_rtl_out2n,
    uart_rtl_ri,
    uart_rtl_rtsn,
    uart_rtl_rxd,
    uart_rtl_rxrdyn,
    uart_rtl_txd,
    uart_rtl_txrdyn);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  inout [53:0]MIO;
  output uart_rtl_baudoutn;
  input uart_rtl_ctsn;
  input uart_rtl_dcdn;
  output uart_rtl_ddis;
  input uart_rtl_dsrn;
  output uart_rtl_dtrn;
  output uart_rtl_out1n;
  output uart_rtl_out2n;
  input uart_rtl_ri;
  output uart_rtl_rtsn;
  input uart_rtl_rxd;
  output uart_rtl_rxrdyn;
  output uart_rtl_txd;
  output uart_rtl_txrdyn;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [53:0]MIO;
  wire uart_rtl_baudoutn;
  wire uart_rtl_ctsn;
  wire uart_rtl_dcdn;
  wire uart_rtl_ddis;
  wire uart_rtl_dsrn;
  wire uart_rtl_dtrn;
  wire uart_rtl_out1n;
  wire uart_rtl_out2n;
  wire uart_rtl_ri;
  wire uart_rtl_rtsn;
  wire uart_rtl_rxd;
  wire uart_rtl_rxrdyn;
  wire uart_rtl_txd;
  wire uart_rtl_txrdyn;

uart uart_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .MIO(MIO),
        .uart_rtl_baudoutn(uart_rtl_baudoutn),
        .uart_rtl_ctsn(uart_rtl_ctsn),
        .uart_rtl_dcdn(uart_rtl_dcdn),
        .uart_rtl_ddis(uart_rtl_ddis),
        .uart_rtl_dsrn(uart_rtl_dsrn),
        .uart_rtl_dtrn(uart_rtl_dtrn),
        .uart_rtl_out1n(uart_rtl_out1n),
        .uart_rtl_out2n(uart_rtl_out2n),
        .uart_rtl_ri(uart_rtl_ri),
        .uart_rtl_rtsn(uart_rtl_rtsn),
        .uart_rtl_rxd(uart_rtl_rxd),
        .uart_rtl_rxrdyn(uart_rtl_rxrdyn),
        .uart_rtl_txd(uart_rtl_txd),
        .uart_rtl_txrdyn(uart_rtl_txrdyn));
endmodule
