`define DE10NANO 1
$$DE10NANO=1
$$VGA=1
$$HARDWARE=1
$$color_depth=6
$$color_max  =63
$$SDRAM=1

module SdramVga(
    input clk,
    output reg[7:0] led,
    // SDRAM
    output reg SDRAM_CLK,
    output reg SDRAM_CKE,
    output reg SDRAM_DQML,
    output reg SDRAM_DQMH,
    output reg SDRAM_nCS,
    output reg SDRAM_nWE,
    output reg SDRAM_nCAS,
    output reg SDRAM_nRAS,
    output reg [1:0] SDRAM_BA,
    output reg [12:0] SDRAM_A,
    inout [15:0] SDRAM_DQ,
    // VGA
    output reg vga_hs,
    output reg vga_vs,
    output reg [5:0] vga_r,
    output reg [5:0] vga_g,
    output reg [5:0] vga_b
    );

wire [7:0]  __main_out_led;

wire        __main_out_sdram_clk;
wire        __main_out_sdram_cle;
wire        __main_out_sdram_dqm;
wire        __main_out_sdram_cs;
wire        __main_out_sdram_we;
wire        __main_out_sdram_cas;
wire        __main_out_sdram_ras;
wire [1:0]  __main_out_sdram_ba;
wire [12:0] __main_out_sdram_a;
  
wire        __main_out_vga_hs;
wire        __main_out_vga_vs;
wire [5:0]  __main_out_vga_r;
wire [5:0]  __main_out_vga_g;
wire [5:0]  __main_out_vga_b;

wire reset_main;
assign reset_main = 1'b0;
wire run_main;
assign run_main = 1'b1;

M_main __main(
  .clock(clk),
  .reset(reset_main),
  .in_run(run_main),
  .inout_sdram_dq(SDRAM_DQ[7:0]),
  .out_led(__main_out_led),
  .out_sdram_clk(__main_out_sdram_clk),
  .out_sdram_cle(__main_out_sdram_cle),
  .out_sdram_dqm(__main_out_sdram_dqm),
  .out_sdram_cs(__main_out_sdram_cs),
  .out_sdram_we(__main_out_sdram_we),
  .out_sdram_cas(__main_out_sdram_cas),
  .out_sdram_ras(__main_out_sdram_ras),
  .out_sdram_ba(__main_out_sdram_ba),
  .out_sdram_a(__main_out_sdram_a),
  .out_video_hs(__main_out_vga_hs),
  .out_video_vs(__main_out_vga_vs),
  .out_video_r(__main_out_vga_r),
  .out_video_g(__main_out_vga_g),
  .out_video_b(__main_out_vga_b)
);

always @* begin

  led          = __main_out_led;

  SDRAM_CLK    = __main_out_sdram_clk;
  SDRAM_CKE    = __main_out_sdram_cle;
  SDRAM_DQML   = __main_out_sdram_dqm;
  SDRAM_DQMH   = 0;
  SDRAM_nCS    = __main_out_sdram_cs;
  SDRAM_nWE    = __main_out_sdram_we;
  SDRAM_nCAS   = __main_out_sdram_cas;
  SDRAM_nRAS   = __main_out_sdram_ras;
  SDRAM_BA     = __main_out_sdram_ba;
  SDRAM_A      = __main_out_sdram_a;
  vga_hs       = __main_out_vga_hs;
  vga_vs       = __main_out_vga_vs;
  vga_r        = __main_out_vga_r;
  vga_g        = __main_out_vga_g;
  vga_b        = __main_out_vga_b;
  
end

assign SDRAM_DQ[15:8] = 0;

endmodule