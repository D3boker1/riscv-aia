module aia_edge_detect (
  input     logic clk_i,
  input     logic rst_ni,
  input     logic d_i,
  output    logic re_o
);

  logic signal_prev; // Stores the previous value of the signal

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      signal_prev <= 1'b0; // Reset on active low reset
    end else begin
      signal_prev <= d_i;
    end
  end

  // Detect rising edge
  assign re_o = (re_o == 0) ? (d_i && !signal_prev) : 1;

endmodule