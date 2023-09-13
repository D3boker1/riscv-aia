module aplic_counter (
    input  logic            clk_i,          // Module clock input
    input  logic            rst_sys_ni,     // Global module reset input
    input  logic            start_i,        // Signal to trigger the counter
    input  logic            counter_rst_i,  // Signal to reset the counter to 0
    input  logic            stop_i,         // Signal to stop the counter
    output logic [31:0]     counter_o       // Counter value output (32-bit)
);

    logic [31:0] counter_d, counter_q; // 32-bit counter register
    logic start_detected, stop_detected;
    logic stop_masked;
    logic counter_rst_n;

    assign counter_rst_n = ~counter_rst_i;
    aia_edge_detect aia_edge_detect_start (
        .clk_i  ( clk_i             ),
        .rst_ni ( counter_rst_n     ), 
        .d_i    ( start_i           ),
        .re_o   ( start_detected    )
    );

    assign stop_masked = start_detected & stop_i;
    aia_edge_detect aia_edge_detect_stop (
        .clk_i  ( clk_i             ),
        .rst_ni ( counter_rst_n     ), 
        .d_i    ( stop_masked       ),
        .re_o   ( stop_detected     )
    );
    
    always_comb begin
        // reset val.
        counter_d = counter_q;

        if(start_detected && !stop_detected) begin
            counter_d = counter_q + 1;
        end
    end

    always_ff @( posedge clk_i or negedge rst_sys_ni) begin
        if (!rst_sys_ni) begin
            counter_q <= '0;            // Reset counter when global reset is asserted
        end else if (counter_rst_i) begin
            counter_q <= '0;            // Reset counter when counter_rst_i is asserted
        end else begin
            counter_q <= counter_d; // Increment counter when start_i is asserted and stop_i is deasserted
        end
    end

    assign counter_o = counter_q; // Output the counter value

endmodule
