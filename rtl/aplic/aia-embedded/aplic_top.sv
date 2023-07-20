/** 
*   Copyright 2023 Francisco Marques, Universidade do Minho
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
* 
* Description: 
*
* NOTE: 
*/ 
module aplic_top #(
   parameter int                                NR_SRC                  = 32    ,
   parameter int                                MIN_PRIO                = 6     ,
   parameter int                                NR_DOMAINS              = 2     ,
   parameter int                                NR_IDCs                 = 1     ,
   parameter int unsigned                       NR_IMSICS               = 1     ,
   parameter int unsigned                       NR_VS_FILES_PER_IMSIC   = 0     ,
   parameter type                               reg_req_t               = logic ,
   parameter type                               reg_rsp_t               = logic ,
   parameter type                               axi_req_t               = logic ,
   parameter type                               axi_resp_t              = logic ,
   // DO NOT EDIT BY PARAMETER
   parameter int unsigned                       NR_INTP_FILES           = 2 + NR_VS_FILES_PER_IMSIC     ,
   parameter int                                VS_INTP_FILE_LEN        = $clog2(NR_VS_FILES_PER_IMSIC) ,
   parameter int                                NR_SRC_LEN              = $clog2(NR_SRC)
) (
   input  logic                                                      i_clk             ,
   input  logic                                                      ni_rst            ,
   input  logic [NR_SRC-1:0]                                         i_irq_sources     ,
   /** APLIC domain interface */
   input  reg_req_t                                                  i_req_cfg         ,
   output reg_rsp_t                                                  o_resp_cfg        ,
   `ifdef DIRECT_MODE
   /** Interrupt Notification to Targets. One per priv. level. */
   output logic [(NR_DOMAINS*NR_IDCs)-1:0]                           o_Xeip_targets
   `elsif MSI_MODE
   /** IMSIC island CSR interface */
   /** NOTE: This should be a struct */
   input  logic [NR_IMSICS-1:0][1:0]                                 i_priv_lvl        ,
   input  logic [NR_IMSICS-1:0][VS_INTP_FILE_LEN:0]                  i_vgein           ,
   input  logic [NR_IMSICS-1:0][32-1:0]                              i_imsic_addr      ,
   input  logic [NR_IMSICS-1:0][32-1:0]                              i_imsic_data      ,
   input  logic [NR_IMSICS-1:0]                                      i_imsic_we        ,
   input  logic [NR_IMSICS-1:0]                                      i_imsic_claim     ,
   output logic [NR_IMSICS-1:0][32-1:0]                              o_imsic_data      ,
   output logic [NR_IMSICS-1:0][NR_INTP_FILES-1:0][NR_SRC_LEN-1:0]   o_xtopei          ,
   output logic [NR_IMSICS-1:0][NR_INTP_FILES-1:0]                   o_Xeip_targets    ,
   output logic [NR_IMSICS-1:0]                                      o_imsic_exception ,
   /** IMSIC island AXI interface*/
   input   axi_req_t                                                 i_imsic_req       ,
   output  axi_resp_t                                                o_imsic_resp
   `endif
); /** End of APLIC top interface */

/** 
 * A 2-level synchronyzer to avoid metastability in the irq line
*/
logic [1:0][NR_SRC-1:0]    sync_irq_src;
always_ff @( posedge i_clk or negedge ni_rst) begin
   if(!ni_rst)begin
      sync_irq_src <= '0;
   end else begin
      sync_irq_src[0] <= i_irq_sources;
      sync_irq_src[1] <= sync_irq_src[0];
   end
end

/** APLIC Domain with IMSIC island */
aplic_domain_top #(
   .NR_DOMAINS              ( NR_DOMAINS            ),
   .NR_SRC                  ( NR_SRC                ),
   .NR_IDCs                 ( NR_IDCs               ),
   .MIN_PRIO                ( MIN_PRIO              ),
   .NR_IMSICS               ( NR_IMSICS             ),
   .NR_VS_FILES_PER_IMSIC   ( NR_VS_FILES_PER_IMSIC ),
   .reg_req_t               ( reg_req_t             ),
   .reg_rsp_t               ( reg_rsp_t             ),
   .axi_req_t               ( axi_req_t             ),
   .axi_resp_t              ( axi_resp_t            )
) i_aplic_generic_domain_top (
   .i_clk            ( i_clk              ),
   .ni_rst           ( ni_rst             ),
   .i_req_cfg        ( i_req_cfg          ),
   .o_resp_cfg       ( o_resp_cfg         ),
   .i_irq_sources    ( sync_irq_src[1]    ),
   .i_priv_lvl       ( i_priv_lvl         ),
   .i_vgein          ( i_vgein            ),
   .i_imsic_addr     ( i_imsic_addr       ),
   .i_imsic_data     ( i_imsic_data       ),
   .i_imsic_we       ( i_imsic_we         ),
   .i_imsic_claim    ( i_imsic_claim      ),
   .o_imsic_data     ( o_imsic_data       ),
   .o_xtopei         ( o_xtopei           ),
   .o_Xeip_targets   ( o_Xeip_targets     ),
   .o_imsic_exception( o_imsic_exception  ),
   .i_imsic_req      ( i_imsic_req        ),
   .o_imsic_resp     ( o_imsic_resp       )    
);

endmodule