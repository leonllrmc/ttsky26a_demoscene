/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  wire [7:0] m_a;
  wire [7:0] m_b;
  wire [7:0] m_c;
  wire [7:0] m_d;
  reg [7:0] voff1;
  reg [7:0] voff2;



  always @(posedge hsync, negedge rst_n) begin
    if (~rst_n) begin
      voff2 <= 8'h08;
      voff1 <= 8'h00;
    end else begin
      if(~vsync) begin
        voff2 <= 8'h00;
      end else begin
        voff1 <= voff1 + 1;
        if(voff1 > (pix_y >> 3)) begin
          voff2 <= voff2 - 1;
          voff1 <= 8'h00;
        end
      end
    end
  end

  assign m_a = voff2;//=4;
  assign m_b = 0;//= -7;
  assign m_c = 0;//= 7;
  assign m_d = 0;//= 4;

  
  wire [9:0] moving_x = (pix_x * m_a + pix_y * m_c)/8;
  wire [9:0] moving_y = (pix_x * m_b + pix_y * m_d)/8;

  assign R = video_active ? {moving_x[5], moving_y[2]} : 2'b00;
  assign G = video_active ? {moving_x[6], moving_y[2]} : 2'b00;
  assign B = video_active ? {moving_x[7], moving_y[5]} : 2'b00;
  
  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  // Suppress unused signals warning
  wire _unused_ok_ = &{moving_x, pix_y, moving_y};

endmodule
