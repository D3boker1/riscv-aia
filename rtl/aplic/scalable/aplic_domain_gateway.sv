/** 
* Copyright 2023 Francisco Marques & Zero-Day Labs, Lda
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
* 
* Author: F.Marques <fmarques_00@protonmail.com>
*
* Description: The APLIC domain gateway is the module encharge of
*              receiving the current setip array, and the new setip 
*              and follow the section 4.6 of AIA spec to determine the
*              new valid setip array value.
*              Also in this module happens the inverted interrupts rectification
*/

module aplic_domain_gateway #(
    parameter int                                     NR_SRC = 32,
    // DO NOT EDIT BY PARAMETER
    parameter int                                     NR_BITS_SRC = (NR_SRC > 32)? 32 : NR_SRC,
    parameter int                                     NR_REG = (NR_SRC-1)/32  
) (
    input   logic                                     i_clk,
    input   logic                                     ni_rst,
    input   logic [NR_SRC-1:0]                        i_sources,
    input   logic [NR_SRC-1:1][10:0]                  i_sourcecfg,
    input   logic [NR_REG:0][NR_BITS_SRC-1:0]         i_sugg_setip,
    input   logic                                     i_domaincfgDM,
    input   logic [NR_REG:0][NR_BITS_SRC-1:0]         i_active,
    input   logic [NR_REG:0][NR_BITS_SRC-1:0]         i_claimed,
    output  logic [NR_REG:0][NR_BITS_SRC-1:0]         o_intp_pen,
    output  logic [NR_REG:0][NR_BITS_SRC-1:0]         o_rectified_src,
    output  logic [NR_SRC-1:0][2:0]                   o_intp_pen_src
);

localparam INACTIVE             = 3'h0;
localparam DETACHED             = 3'h1;
localparam EDGE1                = 3'h4;
localparam EDGE0                = 3'h5;
localparam LEVEL1               = 3'h6;
localparam LEVEL0               = 3'h7;

localparam INACTIVE_C           = 3'h0;
localparam DETACHED_C           = 3'h1;
localparam EDGEX_C              = 3'h2;
localparam LEVELXDM0_C          = 3'h3;
localparam LEVELXDM1_C          = 3'h4;

localparam FROM_RECTIFIER       = 1'b0;
localparam FROM_EDGE_DETECTOR   = 1'b1;

/** Internal signals*/
logic [NR_SRC-1:0]                      rectified_src, rectified_src_q;
logic [NR_REG:0][NR_BITS_SRC-1:0]       new_intp;
/** Control signals */
logic [NR_SRC-1:0]                      new_intp_src;
logic [NR_SRC-1:0][2:0]                 intp_pen_src;

/** Control Logic */
always_comb begin
    for (integer i = 1; i < NR_SRC; i++) begin
        new_intp_src[i] = FROM_RECTIFIER;
        intp_pen_src[i] = INACTIVE_C;

        case (i_sourcecfg[i][2:0])
            INACTIVE: begin
                intp_pen_src[i] = INACTIVE_C;
            end
            DETACHED: begin
                intp_pen_src[i] = DETACHED_C;
            end
            EDGE1, EDGE0: begin
                new_intp_src[i] = FROM_EDGE_DETECTOR;
                intp_pen_src[i] = EDGEX_C;
            end
            LEVEL1, LEVEL0: begin
                if (i_domaincfgDM) begin
                    new_intp_src[i] = FROM_EDGE_DETECTOR;
                    intp_pen_src[i] = LEVELXDM1_C;
                end else begin
                    intp_pen_src[i] = LEVELXDM0_C;
                end
            end
            default: begin 
                new_intp_src[i] = FROM_RECTIFIER;
                intp_pen_src[i] = INACTIVE_C;
            end 
        endcase
    end
end

assign o_intp_pen_src = intp_pen_src;

/** Rectify the input*/
always_comb begin
    for (int i = 1; i < NR_SRC; i++) begin
        if ((i_sourcecfg[i][2:0] == INACTIVE) || (i_sourcecfg[i][2:0] == DETACHED)) begin
            rectified_src[i] = 0;
        end else begin
            rectified_src[i] = i_sources[i] ^ i_sourcecfg[i][0];
        end
    end
end

/** Converts the rectified 1D array into a 2D array format */
for (genvar i = 0; i <= NR_REG; i++) begin
    assign o_rectified_src[i] = rectified_src_q[NR_BITS_SRC*i +: NR_BITS_SRC];
end

/** Select the new interrupt */
for (genvar i = 1 ; i < NR_SRC; i++) begin    
    assign new_intp[i/32][i%32] = (new_intp_src[i]) ? (rectified_src[i] & ~rectified_src_q[i]) : rectified_src[i];
end

/** Choose logic to set pend */
always_comb begin
   for(int j = 0; j <= NR_REG; j++) begin
        for (int i = (j == 0) ? 1 : 0; i < NR_BITS_SRC; i++) begin
            case (intp_pen_src[(j*NR_BITS_SRC) + i])
                DETACHED_C: begin
                    o_intp_pen[j][i] = i_sugg_setip[j][i] & i_active[j][i] & ~(i_claimed[j][i]);
                end
                EDGEX_C: begin
                    o_intp_pen[j][i] = (new_intp[j][i] | i_sugg_setip[j][i]) & i_active[j][i] & ~(i_claimed[j][i]);
                end
                LEVELXDM0_C: begin
                    o_intp_pen[j][i] = new_intp[j][i] & i_active[j][i];
                end
                LEVELXDM1_C: begin
                    o_intp_pen[j][i] = (new_intp[j][i] | i_sugg_setip[j][i]) & i_active[j][i] & ~(~new_intp[j][i] | i_claimed[j][i]);
                end
                default: begin
                    o_intp_pen[j][i] = 1'b0;
                end
            endcase
        end
    end 
end

/** Interrupt previous value */
always_ff @(posedge i_clk, negedge ni_rst) begin
    if(!ni_rst)begin
        rectified_src_q <= '0;
    end else begin
        rectified_src_q <= rectified_src;
    end
end
endmodule