//
module aplic_top_minimal_wrapper #(
    parameter int                                       NR_DOMAINS    = 2           ,
    parameter int                                       NR_SRC        = 32          ,
    parameter int                                       MIN_PRIO      = 6           ,
    parameter int                                       NR_IDCs       = 1           ,
    parameter int                                       NR_INTP_FILES = 3           ,
    parameter int                                       VS_INTP_FILE_LEN = $clog2(NR_INTP_FILES-2)
) (
    input   logic                                       i_clk                       ,
    input   logic                                       ni_rst                      ,
    /**========================== IMSIC ==============================*/     
    /** Register config: CRSs interface From/To interrupt files */
    input  logic [1:0]                                  i_priv_lvl                  ,
    input  logic [VS_INTP_FILE_LEN:0]                   i_vgein                     ,
    input  logic [32-1:0]                               i_imsic_addr                ,
    input  logic [32-1:0]                               i_imsic_data                ,
    input  logic                                        i_imsic_we                  ,
    input  logic                                        i_imsic_claim               ,
    output logic [32-1:0]                               o_imsic_data                ,
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

reg_intf::reg_intf_req_a32_d32                          i_req;
reg_intf::reg_intf_resp_d32                             o_resp;

`ifdef MSI_MODE
ariane_axi::req_t                                       req_msi;          
ariane_axi::resp_t                                      resp_msi;
`endif

assign i_req.addr   = reg_intf_req_a32_d32_addr;
assign i_req.write  = reg_intf_req_a32_d32_write;
assign i_req.wdata  = reg_intf_req_a32_d32_wdata;
assign i_req.wstrb  = reg_intf_req_a32_d32_wstrb;
assign i_req.valid  = reg_intf_req_a32_d32_valid;

assign reg_intf_resp_d32_rdata = o_resp.rdata;
assign reg_intf_resp_d32_error = o_resp.error;
assign reg_intf_resp_d32_ready = o_resp.ready;

aplic_top #(
   .NR_SRC              ( NR_SRC                            ),
   .MIN_PRIO            ( MIN_PRIO                          ),
   .NR_DOMAINS          ( NR_DOMAINS                        ),
   .NR_IDCs             ( NR_IDCs                           ),
   .reg_req_t           ( reg_intf::reg_intf_req_a32_d32    ),
   .reg_rsp_t           ( reg_intf::reg_intf_resp_d32       )
) aplic_top_minimal_i (
   .i_clk               ( i_clk                             ),
   .ni_rst              ( ni_rst                            ),
   .i_irq_sources       ( i_sources                         ),
   .i_req_cfg           ( i_req                             ),
   .o_resp_cfg          ( o_resp                            ),
   `ifdef DIRECT_MODE
   .o_Xeip_targets      ()
   `elsif MSI_MODE
   .o_req_msi           ( req_msi                           ),
   .i_resp_msi          ( resp_msi                          )
   `endif
);

`ifdef MSI_MODE
imsic_top #(
    .NR_SRC             ( NR_SRC                            ),
    .MIN_PRIO           ( MIN_PRIO                          ),
    .NR_INTP_FILES      ( 2                                 ),
    .AXI_ID_WIDTH       ( 4                                 ),
    .axi_req_t          ( ariane_axi::req_t                 ),
    .axi_resp_t         ( ariane_axi::resp_t                )
) i_imsic_top (
    .i_clk              ( i_clk                             ),
    .ni_rst             ( ni_rst                            ),
    .i_req              ( req_msi                           ),
    .o_resp             ( resp_msi                          ),
    .i_priv_lvl         ( i_priv_lvl                        ),
    .i_vgein            ( i_vgein                           ),
    .i_imsic_addr       ( i_imsic_addr                      ),
    .i_imsic_data       ( i_imsic_data                      ),
    .i_imsic_we         ( i_imsic_we                        ),
    .i_imsic_claim      ( i_imsic_claim                     ),
    .o_imsic_data       ( o_imsic_data                      ),
    .o_xtopei           (),
    .o_Xeip_targets     (),
    .o_imsic_exception  ()
);
`endif
endmodule