//
module aia_embedded_wrapper #(
    parameter int                                       NR_DOMAINS    = 2           ,
    parameter int                                       NR_SRC        = 32          ,
    parameter int unsigned                              NR_IMSICS     = 4           ,
    parameter int unsigned                              NR_VS_FILES_PER_IMSIC  = 1  ,
    parameter int                                       MIN_PRIO        = 6         ,
    parameter int unsigned                              AXI_ADDR_WIDTH  = 64        ,
    parameter int unsigned                              AXI_DATA_WIDTH  = 64        ,
    parameter int unsigned                              AXI_ID_WIDTH    = 4         ,
    parameter int                                       NR_IDCs         = 1         ,
    // DO NOT EDIT BY PARAMETER
    parameter int unsigned                              NR_INTP_FILES    = 2 + NR_VS_FILES_PER_IMSIC,
    parameter int                                       VS_INTP_FILE_LEN = $clog2(NR_VS_FILES_PER_IMSIC)
) (
    input   logic                                       i_clk                       ,
    input   logic                                       ni_rst                      ,
    `ifdef MSI_MODE
    /** Signals to generate an AXI MSI transaction */
    input logic                                         i_ready                     ,
    input logic [AXI_ADDR_WIDTH-1:0]                    i_addr                      ,
    input logic [AXI_DATA_WIDTH-1:0]                    i_data                      ,   
    /** Register config: CRSs interface From/To interrupt files */
    input  logic [NR_IMSICS-1:0]                        i_select_imsic              ,
    input  logic [1:0]                                  i_priv_lvl                  ,
    input  logic [VS_INTP_FILE_LEN:0]                   i_vgein                     ,
    input  logic [32-1:0]                               i_imsic_addr                ,
    input  logic [32-1:0]                               i_imsic_data                ,
    input  logic                                        i_imsic_we                  ,
    input  logic                                        i_imsic_claim               ,
    `endif
    /** Register config: AXI interface From/To system bus */
    input   logic [31:0]                                reg_intf_req_a32_d32_addr   ,
    input   logic                                       reg_intf_req_a32_d32_write  ,
    input   logic [31:0]                                reg_intf_req_a32_d32_wdata  ,
    input   logic [3:0]                                 reg_intf_req_a32_d32_wstrb  ,
    input   logic                                       reg_intf_req_a32_d32_valid  ,
    output  logic [31:0]                                reg_intf_resp_d32_rdata     ,
    output  logic                                       reg_intf_resp_d32_error     ,
    output  logic                                       reg_intf_resp_d32_ready     ,
    input   logic [NR_SRC-1:0]                          i_sources         
);

reg_intf::reg_intf_req_a32_d32                          i_aplic_confg_req;
reg_intf::reg_intf_resp_d32                             o_aplic_confg_resp;


assign i_aplic_confg_req.addr   = reg_intf_req_a32_d32_addr;
assign i_aplic_confg_req.write  = reg_intf_req_a32_d32_write;
assign i_aplic_confg_req.wdata  = reg_intf_req_a32_d32_wdata;
assign i_aplic_confg_req.wstrb  = reg_intf_req_a32_d32_wstrb;
assign i_aplic_confg_req.valid  = reg_intf_req_a32_d32_valid;

assign reg_intf_resp_d32_rdata = o_aplic_confg_resp.rdata;
assign reg_intf_resp_d32_error = o_aplic_confg_resp.error;
assign reg_intf_resp_d32_ready = o_aplic_confg_resp.ready;

`ifdef MSI_MODE
/** IMSIC island MSI channel */
ariane_axi::req_t                           req_msi;
ariane_axi::resp_t                          resp_msi;
/** IMSIC island CSRs interface*/
logic [NR_IMSICS-1:0][1:0]                  priv_lvl      ;
logic [NR_IMSICS-1:0][VS_INTP_FILE_LEN:0]   vgein         ;
logic [NR_IMSICS-1:0][32-1:0]               imsic_addr    ;
logic [NR_IMSICS-1:0][32-1:0]               imsic_data    ;
logic [NR_IMSICS-1:0]                       imsic_we      ;
logic [NR_IMSICS-1:0]                       imsic_claim   ;

always_comb begin
    priv_lvl = '0;
    vgein = '0;
    imsic_addr = '0;
    imsic_data = '0;
    imsic_we = '0;
    imsic_claim = '0;

    for (int i = 0; i < NR_IMSICS; i++) begin
        if (i_select_imsic[i] == 1'b1) begin
            priv_lvl[i] = i_priv_lvl;
            vgein[i] = i_vgein;
            imsic_addr[i] = i_imsic_addr;
            imsic_data[i] = i_imsic_data;
            imsic_we[i] = i_imsic_we;
            imsic_claim[i] = i_imsic_claim;
        end
    end
end
`endif

aplic_top #(
   .NR_SRC              ( NR_SRC                            ),
   .MIN_PRIO            ( MIN_PRIO                          ),
   .NR_DOMAINS          ( NR_DOMAINS                        ),
   .NR_IDCs             ( NR_IDCs                           ),
   .NR_IMSICS           ( NR_IMSICS                         ),
   .NR_VS_FILES_PER_IMSIC ( NR_VS_FILES_PER_IMSIC           ),
   .reg_req_t           ( reg_intf::reg_intf_req_a32_d32    ),
   .reg_rsp_t           ( reg_intf::reg_intf_resp_d32       ),
   .axi_req_t           ( ariane_axi::req_t                 ),
   .axi_resp_t          ( ariane_axi::resp_t                )
) aplic_top_minimal_i (
   .i_clk               ( i_clk                             ),
   .ni_rst              ( ni_rst                            ),
   .i_irq_sources       ( i_sources                         ),
   .i_req_cfg           ( i_aplic_confg_req                 ),
   .o_resp_cfg          ( o_aplic_confg_resp                ),
   `ifdef MSI_MODE
   .i_priv_lvl          ( priv_lvl                          ),    
   .i_vgein             ( vgein                             ),
   .i_imsic_addr        ( imsic_addr                        ),        
   .i_imsic_data        ( imsic_data                        ),        
   .i_imsic_we          ( imsic_we                          ),    
   .i_imsic_claim       ( imsic_claim                       ),        
   .o_imsic_data        ( ),        
   .o_xtopei            ( ),    
   .o_Xeip_targets      ( ),        
   .o_imsic_exception   ( ),            
   .i_imsic_req         ( req_msi                           ),
   .o_imsic_resp        ( resp_msi                          )
   `endif
);

`ifdef MSI_MODE
axi_lite_write_master#(
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH    )
) axi_lite_write_master_i (
    .clk_i              ( i_clk             ),
    .rst_ni             ( ni_rst            ),
    .ready_i            ( i_ready           ),
    .id_i               ( '0                ),
    .busy_o             (                   ),
    .addr_i             ( i_addr            ),
    .data_i             ( i_data            ),
    .req_o              ( req_msi           ),
    .resp_i             ( resp_msi          )
);
`endif

endmodule