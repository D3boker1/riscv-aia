/** 
* Copyright 2023 Francisco Marques & Zero-Day Labs, Lda
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
* 
* Author: F.Marques <fmarques_00@protonmail.com>
* 
* Description: This module is the APLIC domain.
*              It is comprised by 3 submodules: gatway, notifier and register map.
*/ 
module aplic_domain_top #(
   parameter int                           DOMAIN_ADDR   = 32'hc000000,
   parameter int                           NR_SRC        = 32,          // Interrupt 0 is always 0
   parameter int                           MIN_PRIO      = 6,
   parameter int                           NR_IDCs       = 1,
   parameter                               APLIC_LEVEL   = "M",
   parameter                               APLIC         = "LEAF",
   parameter unsigned                      IMSIC_ADDR_TARGET= 64'h24000000,
   parameter unsigned                      NR_VS_FILES_PER_IMSIC= 64'h1,
   parameter type                          reg_req_t     = logic,
   parameter type                          reg_rsp_t     = logic,
   parameter type                          axi_req_t     = logic,
   parameter type                          axi_rsp_t     = logic,
   // DO NOT EDIT BY PARAMETER
   parameter int                           IPRIOLEN      = 3, //(MIN_PRIO == 1) ? 1 : $clog2(MIN_PRIO)
   parameter int                           NR_BITS_SRC   = 32,//(NR_SRC > 32)? 32 : NR_SRC,
   parameter int                           NR_REG        = (NR_SRC-1)/32
) (
   input  logic                            i_clk,
   input  logic                            ni_rst,
   input  reg_req_t                        i_req,
   output reg_rsp_t                        o_resp,
   input  logic [NR_SRC-1:0]               i_irq_sources,
   output logic [NR_SRC-1:0]               o_irq_del_sources,
   /**  interface for direct mode */
   `ifdef DIRECT_MODE
   /** Interrupt Notification to Targets. One per priv. level. */
   output logic [NR_IDCs-1:0]           o_Xeip_targets
   /** interface for MSI mode */
   `elsif MSI_MODE
   output  logic                        o_busy,
   output  axi_req_t                    o_req,
   input   axi_rsp_t                    i_resp
   `endif
);
// ================== INTERCONNECTION SIGNALS =====================
   /** Gateway */
   logic [NR_SRC-1:1][10:0]                    sourcecfg_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           sugg_setip_i;
   logic                                       domaincfgDM_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           active_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           claimed_forwarded_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           intp_pen_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           rectified_src_i;
   logic [NR_SRC-1:0][2:0]                     intp_pen_src;
   /** Notifier */
   logic                                       domaincfgIE_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           setip_q_i;
   logic [NR_REG:0][NR_BITS_SRC-1:0]           setie_q_i;
   logic [NR_SRC-1:1][31:0]                    target_q_i;
   `ifdef MSI_MODE
   logic                                       forwarded_valid;
   logic [10:0]                                intp_forwd_id;
   logic [31:0]                                genmsi;
   logic                                       genmsi_sent;
   `elsif DIRECT_MODE
      /**  interface for direct mode */
   logic [NR_IDCs-1:0][0:0]                    idelivery_i;
   logic [NR_IDCs-1:0][0:0]                    iforce_i;
   logic [NR_IDCs-1:0][IPRIOLEN-1:0]           ithreshold_i;
   logic [NR_IDCs-1:0][25:0]                   topi_sugg_i;
   logic [NR_IDCs-1:0]                         topi_update_i;
   `endif
// ================================================================

// ========================== GATEWAY =============================
   aplic_domain_gateway #(
      .NR_SRC(NR_SRC)
   ) i_aplic_domain_gateway (
      .i_clk(i_clk),
      .ni_rst(ni_rst), 
      .i_sources(i_irq_sources), 
      .i_sourcecfg(sourcecfg_i), 
      .i_sugg_setip(sugg_setip_i),
      .i_domaincfgDM(domaincfgDM_i), 
      .i_active(active_i), 
      .i_claimed(claimed_forwarded_i), 
      .o_intp_pen(intp_pen_i), 
      .o_rectified_src(rectified_src_i),
      .o_intp_pen_src(intp_pen_src) 
   ); // End of gateway instance
// ================================================================

// ========================== NOTIFIER ============================
   aplic_domain_notifier #(
      .NR_SRC(NR_SRC),
      .NR_IDCs(NR_IDCs),
      .MIN_PRIO(MIN_PRIO),
      .APLIC(APLIC),
      .APLIC_LEVEL(APLIC_LEVEL),
      .IMSIC_ADDR_TARGET(IMSIC_ADDR_TARGET),
      .NR_VS_FILES_PER_IMSIC(NR_VS_FILES_PER_IMSIC),
      .axi_req_t(axi_req_t),
      .axi_rsp_t(axi_rsp_t)
   ) i_aplic_domain_notifier (
      .i_clk(i_clk),
      .ni_rst(ni_rst),
      .i_domaincfgIE(domaincfgIE_i),
      .i_setip_q(setip_q_i),
      .i_setie_q(setie_q_i),
      .i_target_q(target_q_i),
      `ifdef DIRECT_MODE
      .i_idelivery(idelivery_i),
      .i_iforce(iforce_i),
      .i_ithreshold(ithreshold_i),
      .o_topi_sugg(topi_sugg_i),
      .o_topi_update(topi_update_i),
      .o_Xeip_targets(o_Xeip_targets)
      `elsif MSI_MODE
      .o_genmsi_sent(genmsi_sent),
      .i_genmsi(genmsi),
      .o_forwarded_valid(forwarded_valid),
      .o_intp_forwd_id(intp_forwd_id),
      .o_busy(o_busy),
      .o_req(o_req),
      .i_resp(i_resp)
      `endif
   ); // End of notifier instance
// ================================================================

// =========================== REGCTL =============================

   aplic_domain_regctl #(
      .DOMAIN_ADDR(DOMAIN_ADDR),
      .NR_SRC(NR_SRC),
      .MIN_PRIO(MIN_PRIO),
      .NR_IDCs(NR_IDCs),
      .APLIC(APLIC),
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
   ) i_aplic_domain_regctl (
      .i_clk(i_clk),
      .ni_rst(ni_rst),
      /** Register config: AXI interface From/To system bus */
      .i_req(i_req),
      .o_resp(o_resp),
      /** Gateway */
      .o_sourcecfg(sourcecfg_i),
      .o_sugg_setip(sugg_setip_i),
      .o_domaincfgDM(domaincfgDM_i),
      .o_active(active_i),
      .o_claimed_forwarded(claimed_forwarded_i),
      .i_intp_pen(intp_pen_i),
      .i_rectified_src(rectified_src_i),
      .i_intp_pen_src(intp_pen_src),
      /** Notifier */
      .o_domaincfgIE(domaincfgIE_i),
      .o_setip_q(setip_q_i),
      .o_setie_q(setie_q_i),
      .o_target_q(target_q_i),
      `ifdef MSI_MODE
      .o_genmsi(genmsi),
      .i_genmsi_sent(genmsi_sent),
      .i_forwarded_valid(forwarded_valid),
      .i_intp_forwd_id(intp_forwd_id)
      `elsif DIRECT_MODE
      .o_idelivery(idelivery_i),
      .o_iforce(iforce_i),
      .o_ithreshold(ithreshold_i),
      .i_topi_sugg(topi_sugg_i),
      .i_topi_update(topi_update_i)
      `endif
   );
// ================================================================

// ======================= IRQ DELEGATION =========================
   for (genvar i = 1; i < NR_SRC; i++) begin
      assign o_irq_del_sources[i] = i_irq_sources[i] & sourcecfg_i[i][10];   
   end
   assign o_irq_del_sources[0] = 1'b0;
// ================================================================

endmodule