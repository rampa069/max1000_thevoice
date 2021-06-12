//
// Oddysey2/Videopac The_Voice module on a max1000 FPGA.
//

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

assign {ram_data, ram_addr, ram_bs, ram_clk, ram_cke, ram_dqm,ram_we,ram_cas, ram_ras, ram_cs} = 'Z;


wire clk2m5,clk750k,pll_locked;

pll pll
(
  .inclk0 (clk12m),
  .areset (1'b0),
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
	 
	 .cart_wr_n_i  (cart_wr_n_s),    // WR   (A)
	 .cart_cs_i		(cart_cs_s),      // P14 (11)
	 .res_n_i      (reset_n),        // Button Reset & pll_locked

  
    .voice_addr   (voice_addr_s),   // A0-A7 (G,H,J,K,L,M,P,N)
	 .voice_d5     (voice_d5_s),     // D5 (7)
	 .voice_ldq    (voice_ldq_s)     // T0 (1)
);

wire [7:0] voice_addr_s;
wire signed [15:0] voice_s;
wire cart_wr_n_s,cart_cs_s,voice_d5_s,voice_ldq_s;

always @(posedge clk12m) begin
   cart_wr_n_s <= gpio_d[5];
	cart_cs_s   <= gpio_d[4];
	voice_addr_s <= gpio_d[12:6];
	voice_d5_s <= gpio_d[13];
	gpio_d[5] <= voice_ldq_s;
	voice_s <={snd_voice[15],snd_voice[11:0],3'b0};
end

assign led[1]=voice_ldq_s;
assign led[2]=voice_d5_s;
assign led[3]=cart_cs_s;
assign led[4]=cart_wr_n_s;
assign led[8]=reset_n;

dac_dsm2v dac_dsm2v 
(
  .reset_i  (~reset_n),
  .clock_i  (clk2m5),
  .dac_i    (voice_s),
  .dac_o    (gpio_d[14])
);
endmodule
