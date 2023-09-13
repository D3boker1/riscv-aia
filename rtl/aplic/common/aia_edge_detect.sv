module aia_edge_detect (
  input     logic clk_i ,
  input     logic rst_ni,
  input     logic d_i   ,
  output    logic re_o
);

  logic signal_prev; // Stores the previous value of the signal
  logic my_out_d, my_out_q;

  // Detect rising edge
  assign re_o = my_out_q;

  always_comb begin
    my_out_d = my_out_q;

    if (!my_out_d && d_i && !signal_prev) begin
      my_out_d = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      signal_prev <= 1'b0; // Reset on active low reset
      my_out_q    <= 1'b0;
    end else begin
      signal_prev <= d_i;
      my_out_q    <= my_out_d;
    end
  end

endmodule