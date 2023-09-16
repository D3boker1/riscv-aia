
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module dummy_msi_device #(
    parameter int unsigned AXI_ADDR_WIDTH       = 64,
    parameter int unsigned AXI_DATA_WIDTH       = 64,
    parameter int unsigned DEST_ADDR            = 32'h2800_4000,
    parameter int unsigned CYCLES_BT_TRANSAC    = 0 // Number of cycles to wait between transactions

) (
    input logic         clk_i           , 
    input logic         rst_ni          ,
    input logic         start_interf_i  ,
    AXI_BUS.Master      mst_channel
);
    ariane_axi::req_t       axi_mst_msi_req;
    ariane_axi::resp_t      axi_mst_msi_resp;
    logic                   start_interf_detect;
    logic                   device_busy, device_ready;
    logic [3:0]             counter_d, counter_q;

    aia_edge_detect detect_start_interf_i (
        .clk_i  ( clk_i                 ),
        .rst_ni ( rst_ni                ), 
        .d_i    ( start_interf_i        ),
        .re_o   ( start_interf_detect   )
    );

    // ============================================================
    //                  Trigger Controller
    // ============================================================
    always_comb begin : controller_comb_logic
        device_ready = 1'b0;
        counter_d = counter_q;

        if (CYCLES_BT_TRANSAC == 0) begin : bypass_counter
            if(!device_busy && start_interf_detect) begin
                device_ready = 1'b1;
            end
        end else begin
            if(!device_busy && start_interf_detect) begin
                counter_d = counter_q + 1;
            end

            if (counter_q >= CYCLES_BT_TRANSAC) begin
                device_ready = 1'b1;
                counter_d = '0;
            end
        end
        
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : controller_seq_logic
        if(!rst_ni)begin
            counter_q <= '0;
        end else begin
            counter_q <= counter_d;
        end
    end

    // ============================================================
    //               AXI Lite transactions generator
    // ============================================================
    axi_lite_write_master#(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH                    ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH                    )
    ) dummy_pci_device_i (
        .clk_i          ( clk_i                             ),
        .rst_ni         ( rst_ni                            ),
        .ready_i        ( device_ready                      ),
        .id_i           ( '0                                ),
        .addr_i         ( DEST_ADDR                         ),
        .data_i         ( '0                                ),
        .busy_o         ( device_busy                       ),
        .req_o          ( axi_mst_msi_req                   ),
        .resp_i         ( axi_mst_msi_resp                  )
    );

    // ATENÇÃO: o conteúdo do ficheiro  vendor/pulp-platform/axi/include/axi/assign.svh tem de ser copiado para
    //          corev_apu/register_interface/include/register_interface/assign.svh
    `AXI_ASSIGN_FROM_REQ(mst_channel, axi_mst_msi_req)
    `AXI_ASSIGN_TO_RESP(axi_mst_msi_resp, mst_channel)

endmodule