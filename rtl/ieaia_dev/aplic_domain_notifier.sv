/** 
* Copyright 2023 Francisco Marques & Zero-Day Labs, Lda
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
* 
* Author: F.Marques <fmarques_00@protonmail.com>
*/

module aplic_domain_notifier 
import aplic_pkg::*;
import imsic_pkg::*;
#(
    parameter aplic_cfg_t          AplicCfg                = DefaultAplicCfg,
    parameter imsic_cfg_t          ImsicCfg                = DefaultImsicCfg,
    parameter type                 axi_req_t               = ariane_axi::req_t ,
    parameter type                 axi_resp_t              = ariane_axi::resp_t,
    // DO NOT EDIT BY PARAMETER
    parameter int                  NR_REG                  = (AplicCfg.NrSources-1)/32,
    parameter int                  IMSICS_LEN              = $clog2(ImsicCfg.NrHarts)
) (
    input   logic                                              i_clk,
    input   logic                                              ni_rst,
    input   logic                                              i_domaincfgIE [AplicCfg.NrDomains-1:0],
    input   setip_t [NR_REG:0]                                 i_setip_q,
    input   setie_t [NR_REG:0]                                 i_setie_q,
    input   target_t [AplicCfg.NrSources-1:1]                  i_target_q,
    input   intp_domain_t [AplicCfg.NrSources-1:1]             i_intp_domain,
    `ifdef MSI_MODE
    output  logic                                              o_forwarded_valid,
    output  eiid_t                                             o_intp_forwd_id,
    input   genmsi_t                                           i_genmsi [AplicCfg.NrDomains-1:0],
    output  logic                                              o_genmsi_sent [AplicCfg.NrDomains-1:0],
    /** IMSIC island CSR interface */
    input  csr_channel_to_imsic_t [ImsicCfg.NrHarts-1:0]       i_imsic_csr, 
    output csr_channel_from_imsic_t [ImsicCfg.NrHarts-1:0]     o_imsic_csr,
    /** IMSIC island AXI interface*/
    input   axi_req_t                                          i_imsic_req,
    output  axi_resp_t                                         o_imsic_resp
    `elsif DIRECT_MODE
    // should this be a struct?
    input  idelivery_t  [AplicCfg.NrHarts-1:0]   i_idelivery   [AplicCfg.NrDomains-1:0],
    input  iforce_t     [AplicCfg.NrHarts-1:0]   i_iforce      [AplicCfg.NrDomains-1:0],
    input  ithreshold_t [AplicCfg.NrHarts-1:0]   i_ithreshold  [AplicCfg.NrDomains-1:0],
    output claimi_t     [AplicCfg.NrHarts-1:0]   o_topi_sugg   [AplicCfg.NrDomains-1:0],
    output logic        [AplicCfg.NrHarts-1:0]   o_topi_update [AplicCfg.NrDomains-1:0],
    output logic        [AplicCfg.NrHarts-1:0]   o_eintp_cpu   [AplicCfg.NrDomains-1:0]
    `endif
);

    `ifdef MSI_MODE
        aplic_imsic_channel_t       aplic_imsic_channel;
        eiid_t                      forwarded_intp_id;
        logic                       forwarded_valid;
        logic  genmsi_sent [AplicCfg.NrDomains-1:0];

        always_comb begin : find_pen_en_intp
            forwarded_intp_id   = '0;
            forwarded_valid     = '0;
            for (int i = 0; i < AplicCfg.NrDomains; i++) begin
                genmsi_sent[i]  = '0;
            end
            aplic_imsic_channel.setipnum      = '0;    
            aplic_imsic_channel.select_file   = '0;           
            aplic_imsic_channel.imsic_en            = '0;

            for (int i = 1 ; i < AplicCfg.NrSources ; i++) begin
                if (i_setip_q[i/32][i%32] && i_setie_q[i/32][i%32] && 
                    i_domaincfgIE[i_intp_domain[i]]) begin
                    aplic_imsic_channel.setipnum      = i_target_q[i].dmdf.mf.eiid[ImsicCfg.NrSourcesW-1:0];
                    /** if intp belongs to M domain i_intp_domain = 0, else = 1. + guest index*/
                    aplic_imsic_channel.select_file   = (i_intp_domain[i] == 0) ? 0 : 1 + i_target_q[i].dmdf.mf.gi[0+:ImsicCfg.NrInptFilesW];
                    aplic_imsic_channel.imsic_en      = (1'b1 << i_target_q[i].hi[0+:IMSICS_LEN]);
                    forwarded_intp_id   = i[10:0];
                    forwarded_valid     = 1'b1;
                end
            end
        end

        assign o_genmsi_sent        = genmsi_sent;
        assign o_forwarded_valid    = forwarded_valid;
        assign o_intp_forwd_id      = forwarded_intp_id;

        imsic_island_top #(
            .ImsicCfg               ( ImsicCfg              ),
            .axi_req_t              ( axi_req_t             ),
            .axi_resp_t             ( axi_resp_t            )
        ) i_imsic_top (
            .i_clk                  ( i_clk                 ),
            .ni_rst                 ( ni_rst                ),
            .i_req                  ( i_imsic_req           ),
            .o_resp                 ( o_imsic_resp          ),
            .csr_channel_i          ( i_imsic_csr           ),
            .csr_channel_o          ( o_imsic_csr           ),
            .aplic_imsic_channel_i  ( aplic_imsic_channel   )  
        );
    `elsif DIRECT_MODE
        logic  [AplicCfg.NrHarts-1:0] has_valid_intp   [AplicCfg.NrDomains-1:0];
        iid_t  [AplicCfg.NrHarts-1:0] intp_id          [AplicCfg.NrDomains-1:0];
        prio_t [AplicCfg.NrHarts-1:0] intp_prio        [AplicCfg.NrDomains-1:0];
        prio_t [AplicCfg.NrHarts-1:0] prev_higher_prio [AplicCfg.NrDomains-1:0];

        always_comb begin
            // We should revisit this implementation
            for (int i = 0; i < AplicCfg.NrDomains; i++) begin
                has_valid_intp[i]      = '0;
                intp_id[i]             = '0;
                intp_prio[i]           = '0;
                prev_higher_prio[i]    = '1;
                o_topi_sugg[i]         = '0;
                o_topi_update[i]       = '0;
                for (int j = 0; j < AplicCfg.NrHarts; j++) begin
                    for (int w = 1; w < AplicCfg.NrSources; w++) begin
                        if (i_setip_q[w/32][w%32] && i_setie_q[w/32][w%32] &&
                            (i_intp_domain[w] == intp_domain_t'(i)) && (i_target_q[w].hi == hart_index_t'(j)) && 
                            (i_target_q[w].dmdf.iprio < prev_higher_prio[i][j])) begin
                            intp_id[i][j]          = iid_t'(w);
                            intp_prio[i][j]        = i_target_q[w].dmdf.iprio;
                            prev_higher_prio[i][j] = intp_prio[i][j];
                        end
                    end
                end
            end

            for (int i = 0; i < AplicCfg.NrDomains; i++) begin
                for (int j = 0; j < AplicCfg.NrHarts; j++) begin
                    if((intp_id[i][j] != '0) && ((intp_prio[i][j] < i_ithreshold[i][j]) || 
                    (i_ithreshold[i][j] == '0))) begin
                        o_topi_sugg[i][j].iid = intp_id[i][j];
                        o_topi_sugg[i][j].prio = intp_prio[i][j];
                        o_topi_update[i][j]  = 1'b1;
                        has_valid_intp[i][j] = 1'b1;
                    end
                end
            end
        end

        /** CPU line logic*/
        for (genvar i = 0; i < AplicCfg.NrDomains; i++) begin
            for (genvar j = 0; j < AplicCfg.NrHarts; j++) begin
                assign o_eintp_cpu[i][j] =  i_domaincfgIE[i] & i_idelivery[i][j] & 
                                            (has_valid_intp[i][j] | i_iforce[i][j]);
            end
        end
    `endif

endmodule