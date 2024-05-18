`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: Sat May 18 13:43:14 CST 2024
// Design Name: 
// Module Name: mm2ss
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

module mm2ss ( 
    input clk,
    input rst,

    (* MARK_DEBUG="true" *) input  wire [127:0]  ram_mem_dout,
    (* MARK_DEBUG="true" *) output reg  [63:0]   ram_mem_addr,
    (* MARK_DEBUG="true" *) output reg  [127:0]  ram_mem_din,
    (* MARK_DEBUG="true" *) output reg  [15:0]   ram_mem_we,
    (* MARK_DEBUG="true" *) output reg           ram_mem_en,

    input       [31:0]   packet_tx_length,
    input       [63:0]   packet_tx_baseaddr,
    input                packet_tx_valid,
    


    (* MARK_DEBUG="true" *) output logic  [127:0]  m_axis_tdata,
    (* MARK_DEBUG="true" *) output logic  [15:0]   m_axis_tkeep,
    (* MARK_DEBUG="true" *) output logic           m_axis_tlast,
    (* MARK_DEBUG="true" *) output logic           m_axis_tvalid,
    (* MARK_DEBUG="true" *) input  logic           m_axis_tready

);

    (* MARK_DEBUG="true" *) logic       [31:0]   cur_tx_length_r;
    (* MARK_DEBUG="true" *) logic       [63:0]   cur_tx_baseaddr_r;


    (* MARK_DEBUG="true" *) enum logic [5:0] {
        RESET,
        IDLE,
        CONVERT_PRE4,
        CONVERT_PRE3,
        CONVERT_PRE2,
        CONVERT_PRE1,
        CONVERT
    } fsm_r, fsm_s;


    /****************  ram fifo logic  *****************/
    logic [127:0] ram_mem_dout_fifoed;
    logic         ram_mem_dvld;
    logic [3:0]   ram_mem_dvld_r;
    logic [127:0] ram_mem_data_fifoed[3:0];
    logic         ram_mem_en_fifoed;

    logic [2:0]   ram_mem_cnt_fifoed;
    


    assign ram_mem_dvld = ram_mem_dvld_r[1];

    always_ff @(posedge clk) begin
        if (rst) begin
            ram_mem_dvld_r <= 4'b0;
        end else begin
            ram_mem_dvld_r <= {ram_mem_en, ram_mem_dvld_r[3:1]};
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            ram_mem_data_fifoed[0] <= 'hx;
            ram_mem_data_fifoed[1] <= 'hx;
            ram_mem_data_fifoed[2] <= 'hx;
            ram_mem_data_fifoed[3] <= 'hx;

            ram_mem_cnt_fifoed <= 2'h0;
        end else begin
            case (fsm_s)
            IDLE: begin
                ram_mem_cnt_fifoed <= 'h0;
            end
            default: begin
                if (ram_mem_dvld) begin
                    ram_mem_data_fifoed[0] <= ram_mem_dout;
                    ram_mem_data_fifoed[1] <= ram_mem_data_fifoed[0];
                    ram_mem_data_fifoed[2] <= ram_mem_data_fifoed[1];
                    ram_mem_data_fifoed[3] <= ram_mem_data_fifoed[2];
                end

                if (ram_mem_dvld & ~ram_mem_en_fifoed) begin
                    if (ram_mem_cnt_fifoed == 3) begin
                        $stop(); 
                    end else begin
                        ram_mem_cnt_fifoed <= ram_mem_cnt_fifoed + 1;
                    end
                end else if (~ram_mem_dvld & ram_mem_en_fifoed) begin
                    if (ram_mem_cnt_fifoed == 0) begin

                    end else begin
                        ram_mem_cnt_fifoed <= ram_mem_cnt_fifoed - 1;
                    end
                end
            end
            endcase
        end
    end

    
    
    

    assign ram_mem_en = ram_mem_en_fifoed;
    always_comb begin
        if (ram_mem_cnt_fifoed == 3'b0) begin
            ram_mem_dout_fifoed = ram_mem_dout;
        end else begin
            ram_mem_dout_fifoed = ram_mem_data_fifoed[ram_mem_cnt_fifoed - 1];
        end
    end

    always_comb begin
        m_axis_tdata = ram_mem_dout_fifoed;
    end


    
    logic [31:0] cur_byte_cnt_r;
    logic [31:0] cur_byte_cnt_plus16_r;

    
    
    
    
    
    
    


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
            fsm_s = IDLE;
        end
        IDLE: begin
            if (packet_tx_valid) begin
                fsm_s = CONVERT_PRE4;
            end else begin
                fsm_s = IDLE;
            end
        end
        CONVERT_PRE4: begin
            fsm_s = CONVERT_PRE3;
        end
        CONVERT_PRE3: begin
            fsm_s = CONVERT_PRE2;
        end
        CONVERT_PRE2: begin
            fsm_s = CONVERT_PRE1;
        end
        CONVERT_PRE1: begin
            fsm_s = CONVERT;
        end
        CONVERT: begin
            if (m_axis_tvalid & m_axis_tready & m_axis_tlast) begin
                fsm_s = IDLE;
            end else begin
                fsm_s = CONVERT;
            end
        end
        default: fsm_s = RESET;
        endcase
    end

    always_comb begin
        case (fsm_s)
        CONVERT_PRE3, CONVERT_PRE2, CONVERT_PRE1: begin
            ram_mem_en_fifoed = 1'b1;
        end
        CONVERT: begin
            ram_mem_en_fifoed = m_axis_tvalid & m_axis_tready;
        end
        default: begin
            ram_mem_en_fifoed = 1'b0;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        RESET, IDLE: begin
            ram_mem_we <= 16'h00;
        end
        CONVERT_PRE4: begin
            ram_mem_addr <= packet_tx_baseaddr;
        end
        CONVERT_PRE3, CONVERT_PRE2, CONVERT_PRE1: begin
            ram_mem_addr <= ram_mem_addr + 16;
        end
        CONVERT: begin
            if (m_axis_tvalid & m_axis_tready) begin
                ram_mem_addr <= ram_mem_addr + 16;
            end
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        CONVERT_PRE4: begin
            cur_tx_length_r <= packet_tx_length;
            cur_tx_baseaddr_r <= packet_tx_baseaddr;
        end
        default: begin

        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        CONVERT: begin
            if (~m_axis_tvalid) begin
                cur_byte_cnt_r <= cur_byte_cnt_r + 32'd16;
                cur_byte_cnt_plus16_r <= cur_byte_cnt_plus16_r + 32'd16;
            end else if (m_axis_tvalid & m_axis_tready) begin
                cur_byte_cnt_r <= cur_byte_cnt_r + 32'd16;
                cur_byte_cnt_plus16_r <= cur_byte_cnt_plus16_r + 32'd16;
            end
        end
        default: begin
            cur_byte_cnt_r <= 32'd0;
            cur_byte_cnt_plus16_r <= 32'd16;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        RESET, IDLE: begin
            m_axis_tlast <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end
        CONVERT: begin
            
            m_axis_tvalid <= 1'b1;
            

            if (~m_axis_tvalid) begin
                if (cur_byte_cnt_plus16_r >= cur_tx_length_r) begin
                    case (cur_tx_length_r[3:0])
                        4'b0000: m_axis_tkeep <= 16'hffff;
                        4'b0001: m_axis_tkeep <= 16'h0001;
                        4'b0010: m_axis_tkeep <= 16'h0003;
                        4'b0011: m_axis_tkeep <= 16'h0007;
                        4'b0100: m_axis_tkeep <= 16'h000f;
                        4'b0101: m_axis_tkeep <= 16'h001f;
                        4'b0110: m_axis_tkeep <= 16'h003f;
                        4'b0111: m_axis_tkeep <= 16'h007f;
                        4'b1000: m_axis_tkeep <= 16'h00ff;
                        4'b1001: m_axis_tkeep <= 16'h01ff;
                        4'b1010: m_axis_tkeep <= 16'h03ff;
                        4'b1011: m_axis_tkeep <= 16'h07ff;
                        4'b1100: m_axis_tkeep <= 16'h0fff;
                        4'b1101: m_axis_tkeep <= 16'h1fff;
                        4'b1110: m_axis_tkeep <= 16'h3fff;
                        4'b1111: m_axis_tkeep <= 16'h7fff;
                    endcase

                    m_axis_tlast <= 1'b1;
                end else begin
                    m_axis_tkeep <= 16'hffff;
                    m_axis_tlast <= 1'b0;
                end
            end else if (m_axis_tvalid & m_axis_tready) begin
                if (cur_byte_cnt_plus16_r >= cur_tx_length_r) begin
                    case (cur_tx_length_r[3:0])
                        4'b0000: m_axis_tkeep <= 16'hffff;
                        4'b0001: m_axis_tkeep <= 16'h0001;
                        4'b0010: m_axis_tkeep <= 16'h0003;
                        4'b0011: m_axis_tkeep <= 16'h0007;
                        4'b0100: m_axis_tkeep <= 16'h000f;
                        4'b0101: m_axis_tkeep <= 16'h001f;
                        4'b0110: m_axis_tkeep <= 16'h003f;
                        4'b0111: m_axis_tkeep <= 16'h007f;
                        4'b1000: m_axis_tkeep <= 16'h00ff;
                        4'b1001: m_axis_tkeep <= 16'h01ff;
                        4'b1010: m_axis_tkeep <= 16'h03ff;
                        4'b1011: m_axis_tkeep <= 16'h07ff;
                        4'b1100: m_axis_tkeep <= 16'h0fff;
                        4'b1101: m_axis_tkeep <= 16'h1fff;
                        4'b1110: m_axis_tkeep <= 16'h3fff;
                        4'b1111: m_axis_tkeep <= 16'h7fff;
                    endcase

                    m_axis_tlast <= 1'b1;
                end else begin
                    m_axis_tkeep <= 16'hffff;
                    m_axis_tlast <= 1'b0;
                end

            end
            
        end
        endcase
    end





endmodule
