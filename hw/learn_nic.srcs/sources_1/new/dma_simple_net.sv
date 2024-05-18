`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: Sat May 18 13:43:14 CST 2024
// Design Name: 
// Module Name: dma_simple_net
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

module dma_simple_net #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter RQ_USER_WIDTH = 137,
    parameter RC_USER_WIDTH = 161
    
) (
    input clk,
    input rst,

    output reg      dma_trans_finish            ,
    input           dma_trans_valid             ,
    input           dma_trans_mode              ,
    input   [1:0]   dma_trans_function          ,
    input   [63:0]  dma_trans_cpu_region_addr   ,
    input   [63:0]  dma_trans_fpga_region_addr  ,
    input   [31:0]  dma_trans_transfer_len      ,

    output logic  [DATA_WIDTH - 1 : 0]        s_axis_rq_tdata,
    output reg  [KEEP_WIDTH - 1 : 0]        s_axis_rq_tkeep,
    output reg                              s_axis_rq_tlast,
    input       [3 : 0]                     s_axis_rq_tready,
    output reg  [RQ_USER_WIDTH - 1 : 0]     s_axis_rq_tuser,
    output reg                              s_axis_rq_tvalid,

    input       [DATA_WIDTH - 1 : 0]        m_axis_rc_tdata,
    input       [KEEP_WIDTH - 1 : 0]        m_axis_rc_tkeep,
    input                                   m_axis_rc_tlast,
    output reg                              m_axis_rc_tready,
    input       [RC_USER_WIDTH - 1 : 0]     m_axis_rc_tuser,
    input                                   m_axis_rc_tvalid,

    input  wire [127:0]  ram_senddma_dout[3:0],
    output reg  [63:0]   ram_senddma_addr[3:0],
    output reg  [127:0]  ram_senddma_din[3:0],
    output reg  [15:0]   ram_senddma_we[3:0],
    output reg           ram_senddma_en[3:0],

    input  wire [127:0]  ram_recvdma_dout[3:0],
    output reg  [63:0]   ram_recvdma_addr[3:0],
    output reg  [127:0]  ram_recvdma_din[3:0],
    output reg  [15:0]   ram_recvdma_we[3:0],
    output reg           ram_recvdma_en[3:0],

    output logic   [31:0]   packet_tx_length,
    output logic   [63:0]   packet_tx_baseaddr,
    output logic            packet_tx_valid,

    input logic [1 : 0]   cfg_max_payload,
    input logic [2 : 0]   cfg_max_read_req

);

    logic [31:0] dma_trans_transfer_len_dw_byte;
    logic [1:0] dma_trans_transfer_len_rest_byte;
    logic [0:0] dma_trans_transfer_len_iszero;
    always_ff @(posedge clk) begin
        if (dma_trans_transfer_len[1 : 0] != 2'b0) begin
            dma_trans_transfer_len_dw_byte <= dma_trans_transfer_len + 3;
        end else begin
            dma_trans_transfer_len_dw_byte <= dma_trans_transfer_len;
        end
        dma_trans_transfer_len_rest_byte <= dma_trans_transfer_len[1 : 0];
        dma_trans_transfer_len_iszero <= (dma_trans_transfer_len == 0) ? 1'b1 : 1'b0;
    end


    logic [10:0] max_payload_size; 
    logic [12:0] max_read_request_size; 

    logic [9:0] max_payload_size_sub1;
    logic [3:0] max_payload_size_log2;

    logic [12:0] max_read_request_size_sub1;
    logic [12:0] max_read_request_size_log2;

    always_ff @(posedge clk) begin
        case (cfg_max_payload)
        2'b00: max_payload_size <= 11'd128; 
        2'b01: max_payload_size <= 11'd256;
        2'b10: max_payload_size <= 11'd512;
        2'b11: max_payload_size <= 11'd1024;
        endcase

        case (cfg_max_payload)
        2'b00: max_payload_size_sub1 <= 10'd127;
        2'b01: max_payload_size_sub1 <= 10'd255;
        2'b10: max_payload_size_sub1 <= 10'd511;
        2'b11: max_payload_size_sub1 <= 10'd1023;
        endcase

        case (cfg_max_payload)
        2'b00: max_payload_size_log2 <= 4'd7;
        2'b01: max_payload_size_log2 <= 4'd8;
        2'b10: max_payload_size_log2 <= 4'd9;
        2'b11: max_payload_size_log2 <= 4'd10;
        endcase

    end

    always_ff @(posedge clk) begin
        case (cfg_max_read_req)
        3'b000: max_read_request_size <= 13'd128;
        3'b001: max_read_request_size <= 13'd256;
        3'b010: max_read_request_size <= 13'd512;
        3'b011: max_read_request_size <= 13'd1024;
        3'b100: max_read_request_size <= 13'd2048;
        3'b101: max_read_request_size <= 13'd4096;
        default: max_read_request_size <= 13'd128; 
        endcase

        case (cfg_max_read_req)
        3'b000: max_read_request_size_sub1 <= 13'd127;
        3'b001: max_read_request_size_sub1 <= 13'd255;
        3'b010: max_read_request_size_sub1 <= 13'd511;
        3'b011: max_read_request_size_sub1 <= 13'd1023;
        3'b100: max_read_request_size_sub1 <= 13'd2047;
        3'b101: max_read_request_size_sub1 <= 13'd4095;
        default: max_read_request_size_sub1 <= 13'd127; 
        endcase

        case (cfg_max_read_req)
        3'b000: max_read_request_size_log2 <= 13'd7;
        3'b001: max_read_request_size_log2 <= 13'd8;
        3'b010: max_read_request_size_log2 <= 13'd9;
        3'b011: max_read_request_size_log2 <= 13'd10;
        3'b100: max_read_request_size_log2 <= 13'd11;
        3'b101: max_read_request_size_log2 <= 13'd12;
        default: max_read_request_size_log2 <= 13'd7; 
        endcase
    end


    (* MARK_DEBUG="true" *) enum logic [4:0] {
        RESET,
        IDLE,
        DMA_SEND_START_PRE1,
        DMA_SEND_START_PRE2,
        DMA_SEND_START_PRE3,
        DMA_SEND_START,
        DMA_SEND_MID,
        DMA_RECV_START_PRE,
        DMA_RECV_START,
        DMA_RECV_MIDSTART,
        DMA_RECV_HEAD,
        DMA_RECV_MID,
        DMA_UPDATE_STATUS
    } fsm_r, fsm_s;


    /****************  ram fifo logic  *****************/
    logic [127:0] ram_senddma_dout_fifoed[3:0];
    logic         ram_senddma_dvld[3:0];
    logic [3:0]   ram_senddma_dvld_r[3:0];
    logic [127:0] ram_senddma_data_fifoed[3:0][3:0];
    logic         ram_senddma_en_fifoed[3:0];

    logic [2:0]   ram_senddma_cnt_fifoed[3:0];
    

    generate for (genvar i = 0; i < 4; i++) begin
        assign ram_senddma_dvld[i] = ram_senddma_dvld_r[i][1];

        always_ff @(posedge clk) begin
            if (rst) begin
                ram_senddma_dvld_r[i] <= 4'b0;
            end else begin
                ram_senddma_dvld_r[i] <= {ram_senddma_en[i], ram_senddma_dvld_r[i][3:1]};
            end
        end

        always_ff @(posedge clk) begin
            if (rst) begin
                ram_senddma_data_fifoed[i][0] <= 'hx;
                ram_senddma_data_fifoed[i][1] <= 'hx;
                ram_senddma_data_fifoed[i][2] <= 'hx;
                ram_senddma_data_fifoed[i][3] <= 'hx;

                ram_senddma_cnt_fifoed[i] <= 2'h0;
            end else begin
                case (fsm_s)
                IDLE: begin
                    ram_senddma_cnt_fifoed[i] <= 'h0;
                end
                default: begin
                    if (ram_senddma_dvld[i]) begin
                        ram_senddma_data_fifoed[i][0] <= ram_senddma_dout[i];
                        ram_senddma_data_fifoed[i][1] <= ram_senddma_data_fifoed[i][0];
                        ram_senddma_data_fifoed[i][2] <= ram_senddma_data_fifoed[i][1];
                        ram_senddma_data_fifoed[i][3] <= ram_senddma_data_fifoed[i][2];
                    end

                    if (ram_senddma_dvld[i] & ~ram_senddma_en_fifoed[i]) begin
                        if (ram_senddma_cnt_fifoed[i] == 3) begin
                            $stop(); 
                        end else begin
                            ram_senddma_cnt_fifoed[i] <= ram_senddma_cnt_fifoed[i] + 1;
                        end
                    end else if (~ram_senddma_dvld[i] & ram_senddma_en_fifoed[i]) begin
                        if (ram_senddma_cnt_fifoed[i] == 0) begin

                        end else begin
                            ram_senddma_cnt_fifoed[i] <= ram_senddma_cnt_fifoed[i] - 1;
                        end
                    end
                end
                endcase
            end
        end

        
        
        

        assign ram_senddma_en[i] = ram_senddma_en_fifoed[i];
        always_comb begin
            if (ram_senddma_cnt_fifoed[i] == 3'b0) begin
                ram_senddma_dout_fifoed[i] = ram_senddma_dout[i];
            end else begin
                ram_senddma_dout_fifoed[i] = ram_senddma_data_fifoed[i][ram_senddma_cnt_fifoed[i] - 1];
            end
        end



    end
    endgenerate
            


    wire [127:0]  ram_senddma_dout_0   = ram_senddma_dout[0];
    wire [63:0]   ram_senddma_addr_0   = ram_senddma_addr[0];
    wire [127:0]  ram_senddma_din_0    = ram_senddma_din[0];
    wire [15:0]   ram_senddma_we_0     = ram_senddma_we[0];
    wire          ram_senddma_en_0     = ram_senddma_en[0];
    wire [127:0]   ram_senddma_dout_fifoed_0     = ram_senddma_dout_fifoed[0];

    wire         ram_senddma_dvld_0 = ram_senddma_dvld[0];
    wire [3:0]   ram_senddma_dvld_r_0 = ram_senddma_dvld_r[0];
    wire [127:0] ram_senddma_data_fifoed_0_0 = ram_senddma_data_fifoed[0][0];
    wire [127:0] ram_senddma_data_fifoed_0_1 = ram_senddma_data_fifoed[0][1];
    wire [127:0] ram_senddma_data_fifoed_0_2 = ram_senddma_data_fifoed[0][2];
    wire [127:0] ram_senddma_data_fifoed_0_3 = ram_senddma_data_fifoed[0][3];
    wire         ram_senddma_en_fifoed_0 = ram_senddma_en_fifoed[0];

    wire [2:0]   ram_senddma_cnt_fifoed_0 = ram_senddma_cnt_fifoed[0];
    


    /****************  ram fifo logic  *****************/
    logic [127:0] ram_recvdma_dout_fifoed[3:0];
    logic         ram_recvdma_dvld[3:0];
    logic [3:0]   ram_recvdma_dvld_r[3:0];
    logic [127:0] ram_recvdma_data_fifoed[3:0][3:0];
    logic         ram_recvdma_en_fifoed[3:0];

    logic [2:0]   ram_recvdma_cnt_fifoed[3:0];
    

    generate for (genvar i = 0; i < 4; i++) begin
        assign ram_recvdma_dvld[i] = ram_recvdma_dvld_r[i][1];

        always_ff @(posedge clk) begin
            if (rst) begin
                ram_recvdma_dvld_r[i] <= 4'b0;
            end else begin
                ram_recvdma_dvld_r[i] <= {ram_recvdma_en[i], ram_recvdma_dvld_r[i][3:1]};
            end
        end

        always_ff @(posedge clk) begin
            if (rst) begin
                ram_recvdma_data_fifoed[i][0] <= 'hx;
                ram_recvdma_data_fifoed[i][1] <= 'hx;
                ram_recvdma_data_fifoed[i][2] <= 'hx;
                ram_recvdma_data_fifoed[i][3] <= 'hx;

                ram_recvdma_cnt_fifoed[i] <= 2'h0;
            end else begin
                case (fsm_s)
                IDLE: begin
                    ram_recvdma_cnt_fifoed[i] <= 'h0;
                end
                default: begin
                    if (ram_recvdma_dvld[i]) begin
                        ram_recvdma_data_fifoed[i][0] <= ram_recvdma_dout[i];
                        ram_recvdma_data_fifoed[i][1] <= ram_recvdma_data_fifoed[i][0];
                        ram_recvdma_data_fifoed[i][2] <= ram_recvdma_data_fifoed[i][1];
                        ram_recvdma_data_fifoed[i][3] <= ram_recvdma_data_fifoed[i][2];
                    end

                    if (ram_recvdma_dvld[i] & ~ram_recvdma_en_fifoed[i]) begin
                        if (ram_recvdma_cnt_fifoed[i] == 3) begin
                            $stop(); 
                        end else begin
                            ram_recvdma_cnt_fifoed[i] <= ram_recvdma_cnt_fifoed[i] + 1;
                        end
                    end else if (~ram_recvdma_dvld[i] & ram_recvdma_en_fifoed[i]) begin
                        if (ram_recvdma_cnt_fifoed[i] == 0) begin

                        end else begin
                            ram_recvdma_cnt_fifoed[i] <= ram_recvdma_cnt_fifoed[i] - 1;
                        end
                    end
                end
                endcase
            end
        end

        
        
        

        assign ram_recvdma_en[i] = ram_recvdma_en_fifoed[i];
        always_comb begin
            if (ram_recvdma_cnt_fifoed[i] == 3'b0) begin
                ram_recvdma_dout_fifoed[i] = ram_recvdma_dout[i];
            end else begin
                ram_recvdma_dout_fifoed[i] = ram_recvdma_data_fifoed[i][ram_recvdma_cnt_fifoed[i] - 1];
            end
        end



    end
    endgenerate
            


    wire [127:0]  ram_recvdma_dout_0   = ram_recvdma_dout[0];
    wire [63:0]   ram_recvdma_addr_0   = ram_recvdma_addr[0];
    wire [127:0]  ram_recvdma_din_0    = ram_recvdma_din[0];
    wire [15:0]   ram_recvdma_we_0     = ram_recvdma_we[0];
    wire          ram_recvdma_en_0     = ram_recvdma_en[0];
    wire [127:0]   ram_recvdma_dout_fifoed_0     = ram_recvdma_dout_fifoed[0];

    wire         ram_recvdma_dvld_0 = ram_recvdma_dvld[0];
    wire [3:0]   ram_recvdma_dvld_r_0 = ram_recvdma_dvld_r[0];
    wire [127:0] ram_recvdma_data_fifoed_0_0 = ram_recvdma_data_fifoed[0][0];
    wire [127:0] ram_recvdma_data_fifoed_0_1 = ram_recvdma_data_fifoed[0][1];
    wire [127:0] ram_recvdma_data_fifoed_0_2 = ram_recvdma_data_fifoed[0][2];
    wire [127:0] ram_recvdma_data_fifoed_0_3 = ram_recvdma_data_fifoed[0][3];
    wire         ram_recvdma_en_fifoed_0 = ram_recvdma_en_fifoed[0];

    wire [2:0]   ram_recvdma_cnt_fifoed_0 = ram_recvdma_cnt_fifoed[0];
    



    reg [3:0]   usr_first_be_r;
    reg [3:0]   usr_last_be_r;
    reg [2:0]   usr_addr_offset_r;
    reg [0:0]   usr_discontinue_r;
    reg [0:0]   usr_tph_present_r;
    reg [1:0]   usr_tph_type_r;
    reg [0:0]   usr_tph_indirect_tag_en_r;
    reg [7:0]   usr_tph_st_tag_r;
    reg [3:0]   usr_lo_seq_num_r;
    reg [31:0]  usr_parity_r;
    reg [1:0]   usr_hi_seq_num_r;

    always @(*) begin
        s_axis_rq_tuser = {
                            usr_hi_seq_num_r,
                            usr_parity_r,
                            usr_lo_seq_num_r,
                            usr_tph_st_tag_r,
                            usr_tph_indirect_tag_en_r,
                            usr_tph_type_r,
                            usr_tph_present_r,
                            usr_discontinue_r,
                            usr_addr_offset_r,
                            usr_last_be_r,
                            usr_first_be_r};

    end

    reg [1:0]  desc_mm_at_r;
    reg [61:0] desc_mm_address_r;
    reg [10:0] desc_mm_dword_count_r;
    reg [3:0]  desc_mm_req_type_r;
    reg [0:0]  desc_mm_poisoned_request_r;
    reg [7:0]  desc_mm_req_device_function_r;
    reg [7:0]  desc_mm_req_bus_r;
    reg [7:0]  desc_mm_tag_r;
    reg [7:0]  desc_mm_cpl_device_function_r;
    reg [7:0]  desc_mm_cpl_bus_r;
    reg [0:0]  desc_mm_req_id_enable_r;
    reg [2:0]  desc_mm_tc_r;
    reg [2:0]  desc_mm_attr_r;
    reg [0:0]  desc_mm_force_ecrc_r;

    always_ff @(posedge clk) begin
        desc_mm_at_r <= 2'b00;
        
        
        desc_mm_req_type_r <= {3'b0, dma_trans_mode} ; 
        desc_mm_poisoned_request_r <= 1'b0;
        desc_mm_req_device_function_r <= {6'b00000, dma_trans_function}; 
        desc_mm_req_bus_r <= 8'b00000000;
        
        desc_mm_cpl_device_function_r <= 8'b00000000; 
        desc_mm_cpl_bus_r <= 8'b00000000;
        desc_mm_req_id_enable_r <= 1'b0;
        desc_mm_tc_r <= 3'b000;
        desc_mm_attr_r <= 3'b000;
        desc_mm_force_ecrc_r <= 1'b0;
    end

    reg [1:0] mem_first_rd_flag_r = 0;
    reg [4:0] last_mem_size = 0;
    always @(posedge clk) begin
        if (m_axis_rc_tready & m_axis_rc_tvalid) begin 
            case (m_axis_rc_tkeep)
            
            
            
            4'b0001: begin
                last_mem_size <= 4;
            end
            4'b0011: begin
                last_mem_size <= 8;
            end
            4'b0111: begin
                last_mem_size <= 12;
            end
            4'b1111: begin
                last_mem_size <= 16;
            end
            endcase
        end
    end

    logic [63:0] ram_senddma_addr_rr;
    logic [63:0] ram_recvdma_addr_rr;

    logic recv_rcb_fin_r;
    logic [10:0] desc_mm_dword_count_rr;

    always_ff @(posedge clk) begin
        if (m_axis_rc_tlast & m_axis_rc_tready & m_axis_rc_tvalid) begin
            recv_rcb_fin_r <= 1'b1;
        desc_mm_dword_count_rr <= desc_mm_dword_count_r;
        end else begin
            recv_rcb_fin_r <= 1'b0;
        end
    end

    logic [21:0] total_times_cnt_r, times_cnt_r;

    logic [31:0] recvdata_cur_cnt_r;

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
            if (dma_trans_valid) begin
                if (dma_trans_mode) begin
                    fsm_s = DMA_SEND_START_PRE1; 
                end else begin
                    fsm_s = DMA_RECV_START_PRE; 
                end
            end else begin
                fsm_s = IDLE;
            end
        end
        DMA_SEND_START_PRE1: begin 
            fsm_s = DMA_SEND_START_PRE2;
        end
        DMA_SEND_START_PRE2: begin
            fsm_s = DMA_SEND_START_PRE3;
        end
        DMA_SEND_START_PRE3: begin
            
                fsm_s = DMA_SEND_START;
            
            
            
        end
        DMA_SEND_START: begin
            if (s_axis_rq_tready[0]) begin
                fsm_s = DMA_SEND_MID;
            end else begin
                fsm_s = DMA_SEND_START;
            end
        end
        DMA_SEND_MID: begin
            if (s_axis_rq_tready[0] & s_axis_rq_tlast & s_axis_rq_tvalid) begin
                if (total_times_cnt_r == times_cnt_r) begin
                    fsm_s = DMA_UPDATE_STATUS;
                end else begin
                    fsm_s = DMA_SEND_START;
                end
            end else begin
                fsm_s = DMA_SEND_MID;
            end
        end
        DMA_RECV_START_PRE: begin 
            fsm_s = DMA_RECV_START;
        end
        DMA_RECV_START: begin 
            if (s_axis_rq_tready[0]) begin
                fsm_s = DMA_RECV_MID; 
            end else begin
                fsm_s = DMA_RECV_START;
            end
        end
        
        
        
        
        
        
        
        DMA_RECV_MID: begin
            if (recv_rcb_fin_r) begin
                if (recvdata_cur_cnt_r == {desc_mm_dword_count_rr, 2'b0}) begin
                    if (total_times_cnt_r == times_cnt_r) begin
                        fsm_s = DMA_UPDATE_STATUS;
                    end else begin
                        fsm_s = DMA_RECV_MIDSTART;
                    end
                end else begin
                    fsm_s = DMA_RECV_MID;
                end
            end else begin
                fsm_s = DMA_RECV_MID;
            end
        end
        DMA_RECV_MIDSTART: begin 
            if (s_axis_rq_tready[0]) begin
                fsm_s = DMA_RECV_MID; 
            end else begin
                fsm_s = DMA_RECV_MIDSTART;
            end
        end
        DMA_UPDATE_STATUS: begin
            fsm_s = IDLE;
        end
        default: fsm_s = RESET;
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        DMA_UPDATE_STATUS: begin
            if (dma_trans_mode == 0) begin
                packet_tx_valid <= 1'b1;
                packet_tx_length <= dma_trans_transfer_len;
                packet_tx_baseaddr <= dma_trans_fpga_region_addr;
            end else begin
                packet_tx_valid <= 1'b0;
            end
        end
        default: begin
            packet_tx_valid <= 1'b0;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        DMA_UPDATE_STATUS: dma_trans_finish <= 1'b1;
        default: dma_trans_finish <= 1'b0;
        endcase
    end

    logic stall_flag_r, stalled_flag_r;

    always_ff @(posedge clk) begin
        case (fsm_s)
        RESET: begin
            for (integer i = 0; i < 4; i++) begin
                ram_senddma_addr[i] <= 64'd0;
                ram_recvdma_addr[i] <= 64'd0;
                
                
            end
        end
        IDLE: begin
            ram_senddma_addr[dma_trans_function] <= dma_trans_fpga_region_addr;
            ram_recvdma_addr[dma_trans_function] <= dma_trans_fpga_region_addr;
        end
        DMA_SEND_START_PRE1, DMA_SEND_START_PRE2, DMA_SEND_START_PRE3: begin
            ram_recvdma_addr[dma_trans_function] <= ram_recvdma_addr[dma_trans_function] + 16;
        end
        DMA_SEND_START: begin
           
        end
        DMA_SEND_MID: begin
            
            if (~s_axis_rq_tready[0]) begin
                
            end else begin
                ram_recvdma_addr[dma_trans_function] <= ram_recvdma_addr[dma_trans_function] + 16;
            end
        end
        DMA_RECV_START: begin
            ram_senddma_addr[dma_trans_function] <= dma_trans_fpga_region_addr;
        end
        DMA_RECV_HEAD, DMA_RECV_MID: begin
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                case (mem_first_rd_flag_r) 
                default: begin 
                    ram_senddma_addr_rr <= ram_senddma_addr[dma_trans_function] + 16;
                end
                3: begin
                    ram_senddma_addr_rr <= ram_senddma_addr_rr;
                end
                endcase

                case (mem_first_rd_flag_r) 
                0: begin
                    
                end
                1: begin
                    ram_senddma_addr[dma_trans_function] <= ram_senddma_addr[dma_trans_function] + 4; 
                end
                2: begin
                    ram_senddma_addr[dma_trans_function] <= ram_senddma_addr[dma_trans_function] + 16; 
                end
                3: begin
                    ram_senddma_addr[dma_trans_function] <= ram_senddma_addr_rr + last_mem_size;
                end
                endcase
            end
        end
        DMA_RECV_MIDSTART: begin
            ram_senddma_addr[dma_trans_function] <= ram_senddma_addr_rr + last_mem_size;
        end
        endcase
    end

    always_comb begin
        for (integer i = 0; i < 4; i++) begin
            ram_senddma_en_fifoed[i] = 1'b0;
            ram_recvdma_en_fifoed[i] = 1'b0;
        end
        
        case (fsm_s)
        DMA_SEND_START_PRE1, DMA_SEND_START_PRE2, DMA_SEND_START_PRE3: begin
            ram_recvdma_en_fifoed[dma_trans_function] = 1'b1;
        end
        DMA_SEND_MID, DMA_UPDATE_STATUS: begin
            if ((s_axis_rq_tvalid & s_axis_rq_tready[0] & s_axis_rq_tlast) | ~s_axis_rq_tready[0]) begin
                ram_recvdma_en_fifoed[dma_trans_function] = 1'b0;
            end else begin
                ram_recvdma_en_fifoed[dma_trans_function] = 1'b1;
            end
        end
        DMA_RECV_START_PRE, DMA_RECV_MIDSTART, DMA_RECV_START, DMA_RECV_HEAD, DMA_RECV_MID: begin
            ram_senddma_en_fifoed[dma_trans_function] = 1'b0;
        end
        endcase
    end

    logic [8:0] dma_remain_cnt_r;

    
    
    

    always_ff @(posedge clk) begin
        case (fsm_s)
        default: begin
            s_axis_rq_tvalid <= 1'b0;
            ram_senddma_we[dma_trans_function] <= 1'b0;
            ram_recvdma_we[dma_trans_function] <= 1'b0;
            desc_mm_tag_r <= 8'h00;
        end
        DMA_SEND_START_PRE3: begin
            total_times_cnt_r <= (dma_trans_transfer_len_dw_byte + max_payload_size_sub1) >> max_payload_size_log2;
            times_cnt_r <= 'd0;
            if (dma_trans_transfer_len_dw_byte >= max_payload_size) begin
                desc_mm_dword_count_r <= max_payload_size >> 2;
            end else begin
                case (cfg_max_payload)
                2'b00: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                2'b01: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                2'b10: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                2'b11: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                endcase
                
            end
            desc_mm_address_r <= dma_trans_cpu_region_addr >> 2;
            desc_mm_tag_r <= desc_mm_tag_r + 'd1;
        end
        DMA_SEND_START: begin
            s_axis_rq_tdata <= {
                desc_mm_force_ecrc_r,
                desc_mm_attr_r,
                desc_mm_tc_r,
                desc_mm_req_id_enable_r,
                desc_mm_cpl_bus_r,
                desc_mm_cpl_device_function_r,
                desc_mm_tag_r,
                desc_mm_req_bus_r,
                desc_mm_req_device_function_r,
                desc_mm_poisoned_request_r,
                desc_mm_req_type_r,
                desc_mm_dword_count_r,
                desc_mm_address_r,
                desc_mm_at_r
            };
            s_axis_rq_tkeep <= 4'hf;
            s_axis_rq_tvalid <= 1'b1;
            s_axis_rq_tlast <= 1'b0;

            dma_remain_cnt_r <= desc_mm_dword_count_r;

            if (dma_trans_transfer_len_iszero == 1'b1) begin
                usr_first_be_r  <= 4'b0000;
                usr_last_be_r   <= 4'b0000;
            end else if (desc_mm_dword_count_r != (max_payload_size >> 2)) begin
                if (desc_mm_dword_count_r == 1) begin
                    case (dma_trans_transfer_len_rest_byte) 
                    2'b00: usr_first_be_r <= 4'b1111; 
                    2'b01: usr_first_be_r <= 4'b0001; 
                    2'b10: usr_first_be_r <= 4'b0011; 
                    2'b11: usr_first_be_r <= 4'b0111; 
                    endcase
                    usr_last_be_r  <= 4'b0000;
                end else begin
                    usr_first_be_r <= 4'b1111; 
                    case (dma_trans_transfer_len_rest_byte) 
                    2'b00: usr_last_be_r <= 4'b1111; 
                    2'b01: usr_last_be_r <= 4'b0001; 
                    2'b10: usr_last_be_r <= 4'b0011; 
                    2'b11: usr_last_be_r <= 4'b0111; 
                    endcase
                end
            end else begin
                usr_first_be_r <= 4'b1111; 
                usr_last_be_r <= 4'b1111;
            end

            usr_addr_offset_r <= 3'b000;
            usr_discontinue_r <= 1'b0;
            usr_tph_present_r <= 1'b0;
            usr_tph_type_r <= 2'b00;
            usr_tph_indirect_tag_en_r <= 1'b0;
            usr_tph_st_tag_r <= 8'b00000000;
            usr_lo_seq_num_r <= 4'b0000;
            usr_parity_r <= 32'b0;
            usr_hi_seq_num_r <= 2'b00;

        end
        DMA_SEND_MID: begin
            if (s_axis_rq_tready[0] & s_axis_rq_tvalid) begin
                s_axis_rq_tvalid <= 1;

                if (dma_remain_cnt_r <= 4) begin

                    case (dma_remain_cnt_r[1:0])
                    0: s_axis_rq_tkeep <= 4'b1111;
                    3: s_axis_rq_tkeep <= 4'b0111;
                    2: s_axis_rq_tkeep <= 4'b0011;
                    1: s_axis_rq_tkeep <= 4'b0001;
                    endcase

                    s_axis_rq_tlast <= 1;
                    dma_remain_cnt_r <= 0;

                    times_cnt_r <= times_cnt_r + 'd1;
                    if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_payload_size_log2) begin
                        desc_mm_dword_count_r <= max_payload_size >> 2;
                    end else begin
                        case (cfg_max_payload)
                        2'b00: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                        2'b01: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                        2'b10: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                        2'b11: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                        endcase
                        
                    end
                    desc_mm_address_r <= desc_mm_address_r + (max_payload_size >> 2);
                    desc_mm_tag_r <= desc_mm_tag_r + 'd1;

                end
                else begin
                    s_axis_rq_tkeep <= 4'hf;
                    s_axis_rq_tlast <= 0;
                    dma_remain_cnt_r <= dma_remain_cnt_r - 4; 
                end
                
                s_axis_rq_tdata <= ram_recvdma_dout_fifoed[dma_trans_function];
            end
        end
        DMA_RECV_START_PRE: begin
            total_times_cnt_r <= (dma_trans_transfer_len_dw_byte + max_read_request_size_sub1) >> max_read_request_size_log2;
            times_cnt_r <= 'd0;
            if (dma_trans_transfer_len_dw_byte >= max_read_request_size) begin
                desc_mm_dword_count_r <= max_read_request_size >> 2;
            end else begin
                desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte >> 2;
            end
            desc_mm_address_r <= dma_trans_cpu_region_addr >> 2;
            desc_mm_tag_r <= desc_mm_tag_r + 'd1;
        end
        DMA_RECV_MIDSTART, DMA_RECV_START: begin
            if (desc_mm_dword_count_r != (max_read_request_size >> 2)) begin
                if (dma_trans_transfer_len_iszero == 1'b1) begin
                    usr_first_be_r  <= 4'b0000;
                    usr_last_be_r   <= 4'b0000;
                end else if (desc_mm_dword_count_r == 1) begin
                    case (dma_trans_transfer_len_rest_byte) 
                    2'b00: usr_first_be_r <= 4'b1111; 
                    2'b01: usr_first_be_r <= 4'b0001; 
                    2'b10: usr_first_be_r <= 4'b0011; 
                    2'b11: usr_first_be_r <= 4'b0111; 
                    endcase
                    usr_last_be_r  <= 4'b0000;
                end else begin
                    usr_first_be_r <= 4'b1111; 
                    case (dma_trans_transfer_len_rest_byte) 
                    2'b00: usr_last_be_r <= 4'b1111; 
                    2'b01: usr_last_be_r <= 4'b0001; 
                    2'b10: usr_last_be_r <= 4'b0011; 
                    2'b11: usr_last_be_r <= 4'b0111; 
                    endcase
                end
            end else begin
                usr_first_be_r <= 4'b1111; 
                usr_last_be_r <= 4'b1111;
            end
            
            
            usr_addr_offset_r <= 3'b000;
            usr_discontinue_r <= 1'b0;
            usr_tph_present_r <= 1'b0;
            usr_tph_type_r <= 2'b00;
            usr_tph_indirect_tag_en_r <= 1'b0;
            usr_tph_st_tag_r <= 8'b00000000;
            usr_lo_seq_num_r <= 4'b0000;
            usr_parity_r <= 32'b0;
            usr_hi_seq_num_r <= 2'b00;

            s_axis_rq_tlast <= 1;
            s_axis_rq_tdata <= {
                                desc_mm_force_ecrc_r,
                                desc_mm_attr_r,
                                desc_mm_tc_r,
                                desc_mm_req_id_enable_r,
                                desc_mm_cpl_bus_r,
                                desc_mm_cpl_device_function_r,
                                desc_mm_tag_r,
                                desc_mm_req_bus_r,
                                desc_mm_req_device_function_r,
                                desc_mm_poisoned_request_r,
                                desc_mm_req_type_r,
                                desc_mm_dword_count_r,
                                desc_mm_address_r,
                                desc_mm_at_r};
            s_axis_rq_tkeep <= 4'hf;
            s_axis_rq_tvalid <= 1'b1;

            ram_senddma_we[dma_trans_function] <= 'b0;
            recvdata_cur_cnt_r <= 0;
        end
        
        

        
        
        
        
        
        
        
        
        
        DMA_RECV_MID: begin
            s_axis_rq_tvalid <= 1'b0;
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                if (mem_first_rd_flag_r != 2'd1 && mem_first_rd_flag_r != 2'd2) begin
                    ram_senddma_we[dma_trans_function] <= {12'b0, {4{m_axis_rc_tkeep[3]}} & m_axis_rc_tuser[15:12]};
                    ram_senddma_din[dma_trans_function] <= m_axis_rc_tdata[127 -: 32];
                    recvdata_cur_cnt_r <= recvdata_cur_cnt_r + 4;

                    if (recvdata_cur_cnt_r + 4 == {desc_mm_dword_count_r, 2'b0}) begin
                        times_cnt_r <= times_cnt_r + 1;

                        if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_read_request_size_log2) begin
                            desc_mm_dword_count_r <= max_read_request_size >> 2;
                        end else begin
                            case (cfg_max_read_req)
                            3'b000: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                            3'b001: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                            3'b010: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                            3'b011: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                            3'b100: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[11 - 1 : 2];
                            3'b101: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[12 - 1 : 2];
                            default: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2]; 
                            endcase

                            
                        end
                        desc_mm_address_r <= desc_mm_address_r + (max_read_request_size >> 2);
                        desc_mm_tag_r <= desc_mm_tag_r + 'd1;
                    end

                end else begin
                    ram_senddma_we[dma_trans_function] <= {{4{m_axis_rc_tkeep[3]}}, {4{m_axis_rc_tkeep[2]}}, {4{m_axis_rc_tkeep[1]}}, {4{m_axis_rc_tkeep[0]}}} & m_axis_rc_tuser[15:0]; 
                    ram_senddma_din[dma_trans_function] <= m_axis_rc_tdata;
                    case (m_axis_rc_tkeep)
                        4'b0001: begin
                            recvdata_cur_cnt_r <= recvdata_cur_cnt_r + 4;
                            if (recvdata_cur_cnt_r + 4 == {desc_mm_dword_count_r, 2'b0}) begin
                                times_cnt_r <= times_cnt_r + 1;

                                if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_read_request_size_log2) begin
                                    desc_mm_dword_count_r <= max_read_request_size >> 2;
                                end else begin
                                    case (cfg_max_read_req)
                                    3'b000: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                                    3'b001: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                                    3'b010: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                                    3'b011: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                                    3'b100: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[11 - 1 : 2];
                                    3'b101: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[12 - 1 : 2];
                                    default: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2]; 
                                    endcase

                                    
                                end
                                desc_mm_address_r <= desc_mm_address_r + (max_read_request_size >> 2);
                                desc_mm_tag_r <= desc_mm_tag_r + 'd1;
                            end
                        end
                        4'b0011: begin
                            recvdata_cur_cnt_r <= recvdata_cur_cnt_r + 8;
                            if (recvdata_cur_cnt_r + 8 == {desc_mm_dword_count_r, 2'b0}) begin
                                times_cnt_r <= times_cnt_r + 1;

                                if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_read_request_size_log2) begin
                                    desc_mm_dword_count_r <= max_read_request_size >> 2;
                                end else begin
                                    case (cfg_max_read_req)
                                    3'b000: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                                    3'b001: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                                    3'b010: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                                    3'b011: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                                    3'b100: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[11 - 1 : 2];
                                    3'b101: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[12 - 1 : 2];
                                    default: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2]; 
                                    endcase

                                    
                                end
                                desc_mm_address_r <= desc_mm_address_r + (max_read_request_size >> 2);
                                desc_mm_tag_r <= desc_mm_tag_r + 'd1;
                            end
                        end
                        4'b0111: begin
                            recvdata_cur_cnt_r <= recvdata_cur_cnt_r + 12;
                            if (recvdata_cur_cnt_r + 12 == {desc_mm_dword_count_r, 2'b0}) begin
                                times_cnt_r <= times_cnt_r + 1;

                                if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_read_request_size_log2) begin
                                    desc_mm_dword_count_r <= max_read_request_size >> 2;
                                end else begin
                                    case (cfg_max_read_req)
                                    3'b000: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                                    3'b001: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                                    3'b010: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                                    3'b011: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                                    3'b100: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[11 - 1 : 2];
                                    3'b101: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[12 - 1 : 2];
                                    default: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2]; 
                                    endcase

                                    
                                end
                                desc_mm_address_r <= desc_mm_address_r + (max_read_request_size >> 2);
                                desc_mm_tag_r <= desc_mm_tag_r + 'd1;
                            end
                        end
                        4'b1111: begin
                            recvdata_cur_cnt_r <= recvdata_cur_cnt_r + 16;
                            if (recvdata_cur_cnt_r + 16 == {desc_mm_dword_count_r, 2'b0}) begin
                                times_cnt_r <= times_cnt_r + 1;

                                if (dma_trans_transfer_len_dw_byte >= (times_cnt_r + 2) << max_read_request_size_log2) begin
                                    desc_mm_dword_count_r <= max_read_request_size >> 2;
                                end else begin
                                    case (cfg_max_read_req)
                                    3'b000: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2];
                                    3'b001: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[8 - 1 : 2];
                                    3'b010: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[9 - 1 : 2];
                                    3'b011: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[10 - 1 : 2];
                                    3'b100: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[11 - 1 : 2];
                                    3'b101: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[12 - 1 : 2];
                                    default: desc_mm_dword_count_r <= dma_trans_transfer_len_dw_byte[7 - 1 : 2]; 
                                    endcase

                                    
                                end
                                desc_mm_address_r <= desc_mm_address_r + (max_read_request_size >> 2);
                                desc_mm_tag_r <= desc_mm_tag_r + 'd1;
                            end
                        end
                    endcase
                end

            end
            else begin
                ram_senddma_we[dma_trans_function] <= 'b0;
            end
        end
        endcase
    end


    always_ff @(posedge clk) begin
        case (fsm_s) 
        DMA_RECV_HEAD, DMA_RECV_MID: begin
            if (m_axis_rc_tvalid & m_axis_rc_tready & m_axis_rc_tlast) begin
                m_axis_rc_tready <= 1'b0;
            end else begin  
                m_axis_rc_tready <= 1'b1;
            end
        end
        default: begin
            m_axis_rc_tready <= 1'b0;
        end
        endcase
    end
    
    always @(posedge clk) begin
        case (fsm_r)
        DMA_RECV_HEAD, DMA_RECV_MID: begin
            if (m_axis_rc_tready & m_axis_rc_tvalid) begin
                case (mem_first_rd_flag_r)
                0: begin
                    mem_first_rd_flag_r <= 1;
                end
                1: begin
                    mem_first_rd_flag_r <= 2;
                end
                2: begin
                    if (m_axis_rc_tlast) begin
                        mem_first_rd_flag_r <= 3;
                    end
                    else begin
                        mem_first_rd_flag_r <= 2;
                    end
                end
                3: begin
                    mem_first_rd_flag_r <= 1;
                end
                endcase
            end
        end
        default: begin
            mem_first_rd_flag_r <= 0;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        case (fsm_s)
        DMA_SEND_START: begin
            stall_flag_r <= 1'b0;
            stalled_flag_r <= 1'b0;
        end
        DMA_SEND_MID: begin
            if (dma_remain_cnt_r <= 'h10 && stalled_flag_r == 1'b0) begin
                stall_flag_r <= 1'b1;
                stalled_flag_r <= 1'b1;
            end else begin
                stall_flag_r <= 1'b0;
            end
        end
        endcase
    end


endmodule
