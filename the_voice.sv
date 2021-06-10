module the_voice (
	// Main 12M clock
	input logic clk12m,

	// Accelerometer
	output logic acc_sclk,
	output logic acc_mosi,
	input  logic acc_miso,
	output logic acc_cs,
	input  logic acc_int1,
	input  logic acc_int2,

	// Onboard button
	input  logic btn,

	// Header GPIO
	inout  logic [14:0] gpio_d,
	input  logic  [7:0] gpio_a,

	// Onboard LEDs
	output logic  [8:1] led,

	// PMOD header
	inout  logic  [8:1] pmod,

	// Onboard RAM
	output logic        ram_clk,
	inout  logic [15:0] ram_data,
	output logic [13:0] ram_addr,
	output logic  [1:0] ram_dqm,
	output logic  [1:0] ram_bs,
	output logic        ram_cke,
	output logic        ram_ras,
	output logic        ram_cas,
	output logic        ram_we,
	output logic        ram_cs
);


wire clk2m5,clk750k,pll_locked;

pll pll
(
  .inclk0 (clk12m),
  .areset (0),
  .locked (pll_locked),
  .c0     (clk2m5),
  .c1     (clk750k)
);


wire signed [15:0] snd_voice;
wire reset_n = pll_locked && btn;
voice_glue voice_glue
(
 
    .clk750k  (clk750k),
    .clk2m5   (clk2m5),

    .snd_voice_o (snd_voice),
	 
	 .cart_wr_n_i  (gpio_d[5]),
	 .cart_cs_i		(gpio_d[4]),
	 .res_n_i      (reset_n),

    .voice_enable (1'b1),
    .voice_addr   (gpio_d[12:6]),
	 .voice_d5     (gpio_d[13]),
	 .voice_ldq    (gpio_d[3]) 
);

assign led[1] = gpio_d[4];
assign led[2] = gpio_d[5];
assign led[3] = reset_n;

dac_dsm2v dac_dsm2v 
(
  .reset_i  (~reset_n),
  .clock_i  (clk2m5),
  .dac_i    (snd_voice),
  .dac_o    (gpio_d[14])
);
endmodule
