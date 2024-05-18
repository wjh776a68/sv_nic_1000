`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: Sat May 18 13:43:14 CST 2024
// Design Name: 
// Module Name: ss2mm
// Project Name:  sv_nic
// Target Devices: XCVU37P
// Tool Versions: 2023.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ss2mm (
    input clk,
    input rst,

    (* MARK_DEBUG="true" *) input  wire [127:0]  ram_mem_dout,
    (* MARK_DEBUG="true" *) output reg  [63:0]   ram_mem_addr,
    (* MARK_DEBUG="true" *) output reg  [127:0]  ram_mem_din,
    (* MARK_DEBUG="true" *) output reg  [15:0]   ram_mem_we,
    (* MARK_DEBUG="true" *) output reg           ram_mem_en,

    output logic  [31:0]   packet_rx_length,
    output logic  [63:0]   packet_rx_baseaddr,
    output logic           packet_rx_valid,
    


    (* MARK_DEBUG="true" *) input  logic  [127:0]  s_axis_tdata,
    (* MARK_DEBUG="true" *) input  logic  [15:0]   s_axis_tkeep,
    (* MARK_DEBUG="true" *) input  logic           s_axis_tlast,
    (* MARK_DEBUG="true" *) input  logic           s_axis_tvalid,
    (* MARK_DEBUG="true" *) output logic           s_axis_tready

);

    logic [63:0] ram_mem_addr_next;

    (* MARK_DEBUG="true" *) logic  [31:0]   cur_rx_length;
    (* MARK_DEBUG="true" *) logic  [63:0]   cur_rx_baseaddr;

    (* MARK_DEBUG="true" *) enum logic [5:0] {
        RESET,
        CONVERT
    } fsm_r, fsm_s;

    always_ff @(posedge clk) begin
        case (fsm_r)
        RESET: s_axis_tready <= 1'b0;
        default: s_axis_tready <= 1'b1;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            fsm_r <= RESET;
        end else begin
            fsm_r <= fsm_s;
        end
    end

    always_comb begin
        case (fsm_r)
        RESET: begin
            fsm_s = CONVERT;
        end
        CONVERT: begin
            
            fsm_s = CONVERT;
            
            
            
        end
        default: fsm_s = RESET;
        endcase
    end


    logic packet_fin_r;

    always_ff @(posedge clk) begin
        if (s_axis_tvalid & s_axis_tready & s_axis_tlast) begin
            packet_fin_r <= 1'b1;
        end else begin
            packet_fin_r <= 1'b0;
        end
    end

    function logic [4:0] gettransferlength(input [15:0] tkeep);
        case (s_axis_tkeep)
        16'h0000: return 5'd0;
        16'h0001: return 5'd1;
        16'h0003: return 5'd2;
        16'h0007: return 5'd3;
        16'h000f: return 5'd4;
        16'h001f: return 5'd5;
        16'h003f: return 5'd6;
        16'h007f: return 5'd7;
        16'h00ff: return 5'd8;
        16'h01ff: return 5'd9;
        16'h03ff: return 5'd10;
        16'h07ff: return 5'd11;
        16'h0fff: return 5'd12;
        16'h1fff: return 5'd13;
        16'h3fff: return 5'd14;
        16'h7fff: return 5'd15;
        16'hffff: return 5'd16;
        
        endcase
    endfunction

    always_ff @(posedge clk) begin
        case (fsm_s)
        RESET: begin
            ram_mem_en <= 1'b0;
            ram_mem_we <= 16'h0000;
            ram_mem_addr <= 0;
            ram_mem_addr_next <= 0;

            cur_rx_length <= 0;
        end
        CONVERT: begin
            if (s_axis_tvalid & s_axis_tready) begin
                ram_mem_we <= s_axis_tkeep;
                ram_mem_din <= s_axis_tdata;
                ram_mem_addr_next <= ram_mem_addr_next + 16;
                ram_mem_addr <= ram_mem_addr_next;

                if (s_axis_tlast) begin
                    cur_rx_length <= 0; 
                end else begin
                    cur_rx_length <= cur_rx_length + gettransferlength(s_axis_tkeep);
                end
            end else begin
                ram_mem_we <= 16'h0000;
            end

        end
        endcase
    end

    logic s_axis_tlast_r;
    always_ff @(posedge clk) begin
        case (fsm_s)
        CONVERT: begin
            s_axis_tlast_r <= s_axis_tlast;

            if (s_axis_tlast_r & ~s_axis_tlast) begin
                cur_rx_baseaddr <= ram_mem_addr_next;
            end
        end 
        default: begin
            s_axis_tlast_r <= 1'b0;
            cur_rx_baseaddr <= 'd0;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        CONVERT: begin
            if (s_axis_tvalid & s_axis_tready & s_axis_tlast) begin
                packet_rx_length <= cur_rx_length + gettransferlength(s_axis_tkeep);
                packet_rx_baseaddr <= cur_rx_baseaddr;
            end

            if (packet_fin_r) begin
                packet_rx_valid <= 1'b1;
            end else begin
                packet_rx_valid <= 1'b0;
            end
        end
        default: begin
            packet_rx_valid <= 1'b0;
            
            
        end
        endcase
    end


endmodule
