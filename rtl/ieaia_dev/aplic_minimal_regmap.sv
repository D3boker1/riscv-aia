/** 
* Copyright 2024 Francisco Marques & Zero-Day Labs, Lda
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
* 
* Author: F.Marques <fmarques_00@protonmail.com>
*/

module aplic_regmap 
import aplic_pkg::*;
#(
   parameter aplic_cfg_t                        AplicCfg          = DefaultAplicCfg,
   parameter type                               reg_req_t         = logic,
   parameter type                               reg_rsp_t         = logic,
   // DO NOT EDIT BY PARAMETER
   parameter int                                NR_REG            = (AplicCfg.NrSources-1)/32,
   parameter int                                NR_REG_LEN        = (NR_REG == 0 | NR_REG == 1) ? 1 : $clog2(NR_REG)
) (
  input  logic [AplicCfg.NrSources-1:1][AplicCfg.NrDomainsW-1:0]    intp_domain_i,
  output logic                        [AplicCfg.NrDomainsW-1:0]   target_domain_o,
  output logic                        [NR_REG_LEN-1:0]            target_source_reg_o,
  // Register: domaincfg
  input  domaincfg_t                  i_domaincfg         [AplicCfg.NrDomains-1:0],
  output domaincfg_t                  o_domaincfg         [AplicCfg.NrDomains-1:0],
  output logic                        o_domaincfg_we      [AplicCfg.NrDomains-1:0],
  // Register: sourcecfg
  input  sourcecfg_t                  [AplicCfg.NrSources-1:1]      i_sourcecfg   ,
  output sourcecfg_t                  [AplicCfg.NrSources-1:1]      o_sourcecfg   ,
  output logic                        [AplicCfg.NrSources-1:1]      o_sourcecfg_we,
  // Register: mmsiaddrcfg
  input  logic [31:0]                 i_mmsiaddrcfg                          [0:0],
  output logic [31:0]                 o_mmsiaddrcfg                          [0:0],
  output logic                        o_mmsiaddrcfg_we                       [0:0],
  // Register: mmsiaddrcfgh
  input  logic [31:0]                 i_mmsiaddrcfgh                         [0:0],
  output logic [31:0]                 o_mmsiaddrcfgh                         [0:0],
  output logic                        o_mmsiaddrcfgh_we                      [0:0],
  // Register: smsiaddrcfg
  input  logic [31:0]                 i_smsiaddrcfg                          [0:0],
  output logic [31:0]                 o_smsiaddrcfg                          [0:0],
  output logic                        o_smsiaddrcfg_we                       [0:0],
  // Register: smsiaddrcfgh
  input  logic [31:0]                 i_smsiaddrcfgh                         [0:0],
  output logic [31:0]                 o_smsiaddrcfgh                         [0:0],
  output logic                        o_smsiaddrcfgh_we                      [0:0],
  // Register: setip
  input  setip_t [NR_REG:0]           i_setip   ,
  output setip_t [NR_REG:0]           o_setip   ,
  output logic [NR_REG:0]             o_setip_we,
  // Register: setipnum
  output setipnum_t                   o_setipnum          [AplicCfg.NrDomains-1:0],
  output logic                        o_setipnum_we       [AplicCfg.NrDomains-1:0],
  // Register: in_clrip
  input  clrip_t [NR_REG:0]           i_in_clrip   ,
  output clrip_t [NR_REG:0]           o_in_clrip   ,
  output logic [NR_REG:0]             o_in_clrip_we,
  // Register: clripnum
  output clripnum_t                   o_clripnum          [AplicCfg.NrDomains-1:0],
  output logic                        o_clripnum_we       [AplicCfg.NrDomains-1:0],
  // Register: setie
  input  setie_t [NR_REG:0]           i_setie   ,
  output setie_t [NR_REG:0]           o_setie   ,
  output logic [NR_REG:0]             o_setie_we,
  // Register: setienum
  output setienum_t                   o_setienum          [AplicCfg.NrDomains-1:0],
  output logic                        o_setienum_we       [AplicCfg.NrDomains-1:0],
  // Register: clrie
  output clrie_t [NR_REG:0]           o_clrie   ,
  output logic [NR_REG:0]             o_clrie_we,
  // Register: clrienum
  output clrienum_t                   o_clrienum          [AplicCfg.NrDomains-1:0],
  output logic                        o_clrienum_we       [AplicCfg.NrDomains-1:0],
  // Register: setipnum_le
  input  setipnum_le_t                i_setipnum_le       [AplicCfg.NrDomains-1:0],
  output setipnum_le_t                o_setipnum_le       [AplicCfg.NrDomains-1:0],
  output logic                        o_setipnum_le_we    [AplicCfg.NrDomains-1:0],
  // Register: setipnum_be
  input  setipnum_be_t                i_setipnum_be       [AplicCfg.NrDomains-1:0],
  output setipnum_be_t                o_setipnum_be       [AplicCfg.NrDomains-1:0],
  output logic                        o_setipnum_be_we    [AplicCfg.NrDomains-1:0],
  // Register: target
  input  target_t                     [AplicCfg.NrSources-1:1]         i_target   ,
  output target_t                     [AplicCfg.NrSources-1:1]         o_target   ,
  output logic                        [AplicCfg.NrSources-1:1]         o_target_we,
  `ifdef MSI_MODE
  // Register: genmsi
  genmsi_t                            i_genmsi            [AplicCfg.NrDomains-1:0],
  genmsi_t                            o_genmsi            [AplicCfg.NrDomains-1:0],
  output logic                        o_genmsi_we         [AplicCfg.NrDomains-1:0],
  `elsif DIRECT_MODE
  // Register: idelivery
  input  idelivery_t [AplicCfg.NrHarts-1:0]    i_idelivery         [AplicCfg.NrDomains-1:0],
  output idelivery_t [AplicCfg.NrHarts-1:0]    o_idelivery         [AplicCfg.NrDomains-1:0],
  output logic [AplicCfg.NrHarts-1:0]          o_idelivery_we      [AplicCfg.NrDomains-1:0],
  // Register: iforce
  input  iforce_t [AplicCfg.NrHarts-1:0]       i_iforce            [AplicCfg.NrDomains-1:0],
  output iforce_t [AplicCfg.NrHarts-1:0]       o_iforce            [AplicCfg.NrDomains-1:0],
  output logic [AplicCfg.NrHarts-1:0]          o_iforce_we         [AplicCfg.NrDomains-1:0],
  // Register: ithreshold
  input  ithreshold_t [AplicCfg.NrHarts-1:0]   i_ithreshold        [AplicCfg.NrDomains-1:0],
  output ithreshold_t [AplicCfg.NrHarts-1:0]   o_ithreshold        [AplicCfg.NrDomains-1:0],
  output logic [AplicCfg.NrHarts-1:0]          o_ithreshold_we     [AplicCfg.NrDomains-1:0],
  // Register: topi
  input  claimi_t [AplicCfg.NrHarts-1:0]       i_topi              [AplicCfg.NrDomains-1:0],
  // Register: claimi
  input  claimi_t [AplicCfg.NrHarts-1:0]       i_claimi            [AplicCfg.NrDomains-1:0],
  output logic [AplicCfg.NrHarts-1:0]          o_claimi_re         [AplicCfg.NrDomains-1:0],
  `endif
  // Bus Interface
  input  reg_req_t                    i_req                                       ,
  output reg_rsp_t                    o_resp
);

  function bit domain_is_parent(input logic[AplicCfg.NrDomainsW-1:0] parent_candidate, 
                                input logic[AplicCfg.NrDomainsW-1:0] domain_idx);
    if (AplicCfg.DomainsCfg[domain_idx].ParentID == 32'(parent_candidate)) begin
        domain_is_parent = 1;
    end else begin
        domain_is_parent = 0;
    end
  endfunction

  function automatic bit check_source_domain (input logic[AplicCfg.NrSourcesW-1:0] source_idx, 
                                              input logic[AplicCfg.NrDomainsW-1:0] domain_idx);
    if (intp_domain_i[source_idx] == domain_idx) begin
      check_source_domain = 1;
    end else begin
      check_source_domain = 0;
    end
  endfunction

  // Auxiliar signals to compute indexs
  logic [31:0]            register_address;
  logic [AplicCfg.NrDomainsW-1:0] target_domain;
  logic [AplicCfg.NrSourcesW-1:0]  target_source;
  logic [9:0]             target_source_aux;
  logic [NR_REG_LEN-1:0]  target_source_reg;
  logic [6:0]             target_source_reg_aux;
  logic [AplicCfg.NrHartsW-1:0] target_idc_id;
  logic [31:0]            target_idc_id_aux;
  logic [4:0]             target_idc_reg;
  logic [31:0]            target_idc_reg_aux;

  logic [AplicCfg.NrDomains-1:0][NR_REG:0][31:0] en_in_domain;

  assign target_domain_o = target_domain;
  assign target_source_reg_o = target_source_reg;

  always_comb begin
    target_domain         = '0;
    register_address      = '0;
    en_in_domain          = '0;
    target_source         = '0;
    target_source_aux     = '0;
    target_source_reg     = '0;
    target_source_reg_aux = '0;
    target_idc_id         = '0;               
    target_idc_id_aux     = '0;                   
    target_idc_reg        = '0;                  
    target_idc_reg_aux    = '0;   

    // A case here improve hw?
    for (int i = 0; i < AplicCfg.NrDomains; i++) begin
        if ((i_req.addr >= AplicCfg.DomainsCfg[i].Addr) && 
            (i_req.addr < (AplicCfg.DomainsCfg[i].Addr + 'h4000 + ('h20 * AplicCfg.NrHarts)))) begin
            
            target_domain = AplicCfg.DomainsCfg[i].id[AplicCfg.NrDomainsW-1:0];
            register_address = i_req.addr - AplicCfg.DomainsCfg[i].Addr;  
            break;
        end
    end

    // We believe that this can impove hardware resources becuse we can now just use the register and save on some gates
    for (int i = 0; i < AplicCfg.NrDomains; i++) begin 
      for (int j = 1; j < AplicCfg.NrSources; j++) begin 
        if (check_source_domain(AplicCfg.NrSourcesW'(j), AplicCfg.NrDomainsW'(i))) begin
          en_in_domain[i][j/32][j%32] = 1'b1;
        end
      end 
    end

    target_source_aux = i_req.addr[9:0] >> 2;
    target_source = target_source_aux[AplicCfg.NrSourcesW-1:0];

    // if NR_REG != 0 then
    target_source_reg_aux = i_req.addr[6:0] >> 2;
    target_source_reg = target_source_reg_aux[NR_REG_LEN-1:0];
    // else 
    // target_source_reg = 0
    // endif

    // if NR_HArt == 1 then
    // target_idc_id = 0
    // else then 
    target_idc_reg_aux = register_address - 'h4000;
    target_idc_reg = target_idc_reg_aux[4:0]; // & 'h1f;
    target_idc_id_aux = target_idc_reg_aux >> 5;
    target_idc_id = target_idc_id_aux[AplicCfg.NrHartsW-1:0];

  end

always_comb begin
  o_resp.ready    = 1'b1;
  o_resp.rdata    = '0;
  o_resp.error    = '0;                       

  o_sourcecfg     = '0;
  o_sourcecfg_we  = '0;
  o_target        = '0;
  o_target_we     = '0;
  o_setip         = '0;
  o_setip_we      = '0;
  o_in_clrip      = '0;
  o_in_clrip_we   = '0;
  o_setie         = '0;
  o_setie_we      = '0;
  o_clrie         = '0;
  o_clrie_we      = '0;

  for (int i = 0; i < AplicCfg.NrDomains; i++) begin
    o_domaincfg[i]      = '0;
    o_domaincfg_we[i]   = '0;
    o_setipnum[i]       = '0;
    o_setipnum_we[i]    = '0;
    o_clripnum[i]       = '0;
    o_clripnum_we[i]    = '0;
    o_setienum[i]       = '0;
    o_setienum_we[i]    = '0;
    o_clrienum[i]       = '0;
    o_clrienum_we[i]    = '0;
    o_setipnum_le[i]    = '0;
    o_setipnum_le_we[i] = '0;
    o_setipnum_be[i]    = '0;
    o_setipnum_be_we[i] = '0;
    `ifdef MSI_MODE
    o_genmsi[i]         = '0;
    o_genmsi_we[i]      = '0;
    `elsif DIRECT_MODE
    o_idelivery[i]      = '0;
    o_idelivery_we[i]   = '0;
    o_iforce[i]         = '0;
    o_iforce_we[i]      = '0;
    o_ithreshold[i]     = '0;
    o_ithreshold_we[i]  = '0;
    o_claimi_re[i]      = '0;
    `endif
  end
  
  // this needs adjust to allow multiple M domains
  o_mmsiaddrcfg     [0] = '0;
  o_mmsiaddrcfg_we  [0] = '0;
  o_mmsiaddrcfgh    [0] = '0;
  o_mmsiaddrcfgh_we [0] = '0;
  o_smsiaddrcfg     [0] = '0;
  o_smsiaddrcfg_we  [0] = '0;
  o_smsiaddrcfgh    [0] = '0;
  o_smsiaddrcfgh_we [0] = '0;

  if (i_req.valid) begin
    if (i_req.write) begin
      unique case(register_address) inside
        'h0: begin
          o_domaincfg[target_domain].dm = AplicCfg.DeliveryMode;
          // o_domaincfg[target_domain].be     = i_req.wdata[DOMAINCFG_BE_OFF];
          o_domaincfg[target_domain].ie     = i_req.wdata[DOMAINCFG_IE_OFF];
          o_domaincfg_we[target_domain]      = 1'b1;
        end
        ['h4: 'h4 + ('h4 * (AplicCfg.NrSources-1))]: begin
          if (check_source_domain(target_source, target_domain)) begin
            o_sourcecfg[target_source].d     = i_req.wdata[10];
            if (o_sourcecfg[target_source].d) begin
              // devia verificar se o index é válido?
              o_sourcecfg[target_source].ddf.ci = i_req.wdata[9:0];
            end else begin
              if (is_valid_aplic_sourcecfg_sm(i_req.wdata[2:0])) begin
                o_sourcecfg[target_source].ddf.sm = sourcecfg_sm_t'(i_req.wdata[2:0]);
              end
            end
          end

          o_sourcecfg_we[target_source]      = 1'b1;
        end
        'h1bc0: begin
          o_mmsiaddrcfg[0][31:0]     = i_req.wdata[31:0];
          o_mmsiaddrcfg_we[0]      = 1'b1;
        end
        'h1bc4: begin
          o_mmsiaddrcfgh[0][31:0]     = i_req.wdata[31:0];
          o_mmsiaddrcfgh_we[0]      = 1'b1;
        end
        'h1bc8: begin
          o_smsiaddrcfg[0][31:0]     = i_req.wdata[31:0];
          o_smsiaddrcfg_we[0]      = 1'b1;
        end
        'h1bcc: begin
          o_smsiaddrcfgh[0][31:0]     = i_req.wdata[31:0];
          o_smsiaddrcfgh_we[0]      = 1'b1;
        end
        ['h1c00 : 'h1c00 + (NR_REG * 'h4)]: begin
          o_setip[target_source_reg][31:0]   = i_req.wdata[31:0] & en_in_domain[target_domain][target_source_reg];
          o_setip_we[target_source_reg]      = 1'b1;
        end
        'h1cdc: begin
          o_setipnum[target_domain][31:0]     = i_req.wdata[31:0];
          o_setipnum_we[target_domain]      = 1'b1;
        end
        ['h1d00 : 'h1d00 + (NR_REG * 'h4)]: begin
          o_in_clrip[target_source_reg][31:0]   = i_req.wdata[31:0] & en_in_domain[target_domain][target_source_reg];
          o_in_clrip_we[target_source_reg]      = 1'b1;
        end
        'h1ddc: begin
          o_clripnum[target_domain][31:0]     = i_req.wdata[31:0];
          o_clripnum_we[target_domain]      = 1'b1;
        end
        ['h1e00 : 'h1e00 + (NR_REG * 'h4)]: begin
          o_setie[target_source_reg][31:0]   = i_req.wdata[31:0] & en_in_domain[target_domain][target_source_reg];
          o_setie_we[target_source_reg]      = 1'b1;
        end
        'h1edc: begin
          o_setienum[target_domain][31:0]     = i_req.wdata[31:0];
          o_setienum_we[target_domain]      = 1'b1;
        end
        ['h1f00 : 'h1f00 + (NR_REG * 'h4)]: begin
          o_clrie[target_source_reg][31:0]     = i_req.wdata[31:0] & en_in_domain[target_domain][target_source_reg];
          o_clrie_we[target_source_reg]      = 1'b1;
        end
        'h1fdc: begin
          o_clrienum[target_domain][31:0]     = i_req.wdata[31:0];
          o_clrienum_we[target_domain]      = 1'b1;
        end
        'h2000: begin
          o_setipnum_le[target_domain][31:0]     = i_req.wdata[31:0];
          o_setipnum_le_we[target_domain]      = 1'b1;
        end
        'h2004: begin
          o_setipnum_be[target_domain][31:0]     = i_req.wdata[31:0];
          o_setipnum_be_we[target_domain]      = 1'b1;
        end
        `ifdef MSI_MODE
        'h3000: begin
          if (AplicCfg.DeliveryMode == DOMAIN_IN_MSI_MODE) begin
            o_genmsi[target_domain].hi     = i_req.wdata[GENMSI_HI_OFF +: GENMSI_HI_LEN];
            o_genmsi[target_domain].busy   = 1'b1;
            o_genmsi[target_domain].eiid   = i_req.wdata[GENMSI_EIID_OFF +: GENMSI_EIID_LEN];
            o_genmsi_we[target_domain]      = 1'b1;
          end
        end
        `endif
        ['h3004 : 'h3004 + ('h4 * (AplicCfg.NrSources-1))]: begin
          if (check_source_domain(target_source, target_domain)) begin
            o_target[target_source].hi     = i_req.wdata[TARGET_HI_OFF +: TARGET_HI_LEN];

            if (AplicCfg.DeliveryMode == DOMAIN_IN_DIRECT_MODE) begin
              o_target[target_source].dmdf.iprio = i_req.wdata[TARGET_IPRIO_OFF +: TARGET_IPRIO_LEN];
            end else if (AplicCfg.DeliveryMode == DOMAIN_IN_MSI_MODE) begin
              o_target[target_source].dmdf.mf.gi = i_req.wdata[TARGET_GI_OFF +: TARGET_GI_LEN];
              o_target[target_source].dmdf.mf.eiid = i_req.wdata[TARGET_EIID_OFF +: TARGET_EIID_LEN];
            end

            o_target_we[target_source]      = 1'b1;
          end
        end
        `ifdef DIRECT_MODE
        ['h4000 : 'h4000 + (('h1f) * (AplicCfg.NrHarts))]: begin
          if ((AplicCfg.NrHarts != 0) &&
              (AplicCfg.DeliveryMode == DOMAIN_IN_DIRECT_MODE)) begin
            unique case (target_idc_reg)
              'h00: begin
                o_idelivery[target_domain][target_idc_id] = i_req.wdata[0];
                o_idelivery_we[target_domain][target_idc_id] = 1'b1;
              end
              'h04: begin
                o_iforce[target_domain][target_idc_id] = i_req.wdata[0];
                o_iforce_we[target_domain][target_idc_id] = 1'b1;
              end
              'h08: begin
                o_ithreshold[target_domain][target_idc_id] = i_req.wdata[0 +: ITRHESHOLD_LEN];
                o_ithreshold_we[target_domain][target_idc_id] = 1'b1;
              end
              'h18,
              'h1c: begin
                // Writes to topi/claimi are ignored.
              end
              default: o_resp.error = 1'b1; 
            endcase
          end else begin
            o_resp.error = 1'b1;
          end
        end
        `endif
        default: o_resp.error = 1'b1;
      endcase
    end else begin
      unique case(register_address) inside
        'h0: begin
          o_resp.rdata[DOMAINCFG_RO80_OFF +: DOMAINCFG_RO80_LEN] = DOMAINCFG_RO80_VAL;
          o_resp.rdata[DOMAINCFG_IE_OFF] = i_domaincfg[target_domain].ie;
          o_resp.rdata[DOMAINCFG_DM_OFF] = i_domaincfg[target_domain].dm;
          o_resp.rdata[DOMAINCFG_BE_OFF] = i_domaincfg[target_domain].be;
        end
        ['h4: 'h4 + ('h4 * (AplicCfg.NrSources-1))]: begin
          if (check_source_domain(target_source, target_domain)) begin
            o_resp.rdata[10]  = i_sourcecfg[target_source].d;
            o_resp.rdata[2:0] = i_sourcecfg[target_source].ddf.sm;
          end else begin
            if (domain_is_parent(target_domain, intp_domain_i[target_source])) begin
              o_resp.rdata[10] = 'h1;
              o_resp.rdata[AplicCfg.NrDomainsW-1:0] = intp_domain_i[target_source];
            end
          end
        end
        'h1bc0: begin
          o_resp.rdata[31:0]     = i_mmsiaddrcfg[0][31:0];
        end
        'h1bc4: begin
          o_resp.rdata[31:0]     = i_mmsiaddrcfgh[0][31:0];
        end
        'h1bc8: begin
          o_resp.rdata[31:0]     = i_smsiaddrcfg[0][31:0];
        end
        'h1bcc: begin
          o_resp.rdata[31:0]     = i_smsiaddrcfgh[0][31:0];
        end
        ['h1c00 : 'h1c00 + (NR_REG * 'h4)]: begin
          o_resp.rdata = i_setip[target_source_reg] & en_in_domain[target_domain][target_source_reg];
        end
        'h1cdc: begin
          o_resp.rdata     = '0;
        end
        ['h1d00 : 'h1d00 + (NR_REG * 'h4)]: begin
          o_resp.rdata = i_in_clrip[target_source_reg] & en_in_domain[target_domain][target_source_reg];
        end
        'h1ddc: begin
          o_resp.rdata[31:0]     = '0;
        end
        ['h1e00 : 'h1e00 + (NR_REG * 'h4)]: begin
          o_resp.rdata[31:0] = i_setie[target_source_reg] & en_in_domain[target_domain][target_source_reg];
        end
        'h1edc: begin
          o_resp.rdata[31:0]     = '0;
        end
        ['h1f00 : 'h1f00 + (NR_REG * 'h4)]: begin
          o_resp.rdata[31:0]     = '0;
        end
        'h1fdc: begin
          o_resp.rdata[31:0]     = '0;
        end
        'h2000: begin
          o_resp.rdata[31:0]     = i_setipnum_le[target_domain][31:0];
        end
        'h2004: begin
          o_resp.rdata[31:0]     = i_setipnum_be[target_domain][31:0];
        end
        `ifdef MSI_MODE
        'h3000: begin
          if (AplicCfg.DeliveryMode == DOMAIN_IN_MSI_MODE) begin
            o_resp.rdata[GENMSI_HI_OFF +: GENMSI_HI_LEN] = i_genmsi[target_domain].hi;
            o_resp.rdata[GENMSI_BUSY_OFF] = i_genmsi[target_domain].busy;
            o_resp.rdata[GENMSI_EIID_OFF +: GENMSI_EIID_LEN] = i_genmsi[target_domain].eiid;
          end
        end
        `endif
        ['h3004 : 'h3004 + ('h4 * (AplicCfg.NrSources-1))]: begin
          // the else case is return all zeros, alreay covered by the reset value
          if (check_source_domain(target_source, target_domain)) begin
            o_resp.rdata[TARGET_HI_OFF +: TARGET_HI_LEN] = i_target[target_source].hi;
            if (AplicCfg.DeliveryMode == DOMAIN_IN_DIRECT_MODE) begin
              o_resp.rdata[TARGET_IPRIO_OFF +: TARGET_IPRIO_LEN] = i_target[target_source].dmdf.iprio;
            end else if (AplicCfg.DeliveryMode == DOMAIN_IN_MSI_MODE) begin
              o_resp.rdata[TARGET_GI_OFF +: TARGET_GI_LEN] = i_target[target_source].dmdf.mf.gi;
              o_resp.rdata[TARGET_EIID_OFF +: TARGET_EIID_LEN] = i_target[target_source].dmdf.mf.eiid;
            end
          end
        end
        `ifdef DIRECT_MODE
        ['h4000 : 'h4000 + (('h20) * (AplicCfg.NrHarts))-1]: begin
          if ((AplicCfg.NrHarts != 0) && 
              (AplicCfg.DeliveryMode == DOMAIN_IN_DIRECT_MODE)) begin
            unique case (target_idc_reg)
              'h00: begin
                o_resp.rdata[0] = i_idelivery[target_domain][target_idc_id];
              end
              'h04: begin
                o_resp.rdata[0] = i_iforce[target_domain][target_idc_id];
              end
              'h08: begin
                o_resp.rdata[0 +: ITRHESHOLD_LEN] = i_ithreshold[target_domain][target_idc_id];
              end
              'h18: begin
                o_resp.rdata[CLAIMI_IID_OFF +: CLAIMI_IID_LEN] = i_claimi[target_domain][target_idc_id].iid;
                o_resp.rdata[CLAIMI_PRIO_OFF +: CLAIMI_PRIO_LEN] = i_claimi[target_domain][target_idc_id].prio;
              end
              'h1c: begin
                o_resp.rdata[CLAIMI_IID_OFF +: CLAIMI_IID_LEN] = i_claimi[target_domain][target_idc_id].iid;
                o_resp.rdata[CLAIMI_PRIO_OFF +: CLAIMI_PRIO_LEN] = i_claimi[target_domain][target_idc_id].prio;
                o_claimi_re[target_domain][target_idc_id] = 1'b1;
              end
              default: o_resp.error = 1'b1; 
            endcase
          end else begin
            o_resp.error = 1'b1;
          end
        end
        `endif
        default: o_resp.error = 1'b1;
      endcase
    end
  end
end
endmodule
