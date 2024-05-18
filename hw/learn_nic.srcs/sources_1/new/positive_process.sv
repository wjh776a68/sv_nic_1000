`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: Sat May 18 13:43:14 CST 2024
// Design Name: 
// Module Name: positive_process
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


module positive_process #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 32,
    
    parameter RQ_USER_WIDTH = 137,
    parameter RC_USER_WIDTH = 161

) (
    input clk,
    input rst,

    /* (* MARK_DEBUG="true" *) */ output      [DATA_WIDTH - 1 : 0]        s_axis_rq_tdata,
    /* (* MARK_DEBUG="true" *) */ output      [KEEP_WIDTH - 1 : 0]        s_axis_rq_tkeep,
    /* (* MARK_DEBUG="true" *) */ output                                  s_axis_rq_tlast,
    /* (* MARK_DEBUG="true" *) */ input       [3 : 0]                     s_axis_rq_tready,
    /* (* MARK_DEBUG="true" *) */ output      [RQ_USER_WIDTH - 1 : 0]     s_axis_rq_tuser,
    /* (* MARK_DEBUG="true" *) */ output                                  s_axis_rq_tvalid,
    /*                         */ 
    /* (* MARK_DEBUG="true" *) */ input       [DATA_WIDTH - 1 : 0]        m_axis_rc_tdata,
    /* (* MARK_DEBUG="true" *) */ input       [KEEP_WIDTH - 1 : 0]        m_axis_rc_tkeep,
    /* (* MARK_DEBUG="true" *) */ input                                   m_axis_rc_tlast,
    /* (* MARK_DEBUG="true" *) */ output                                  m_axis_rc_tready,
    /* (* MARK_DEBUG="true" *) */ input       [RC_USER_WIDTH - 1 : 0]     m_axis_rc_tuser,
    /* (* MARK_DEBUG="true" *) */ input                                   m_axis_rc_tvalid,

    input  wire [127:0]  ram_ctl_dout[3:0],
    output reg  [63:0]   ram_ctl_addr[3:0],
    output reg  [127:0]  ram_ctl_din[3:0],
    output reg  [15:0]   ram_ctl_we[3:0],
    output reg           ram_ctl_en[3:0],

    input   logic [1:0] dma_watchdog[3:0],
    output  logic [1:0] dma_watchdog_ack[3:0],

    output  logic            irq_valid,
    output  logic [3 : 0]    irq_func,
    output  logic [63 : 0]   irq_addr,
    output  logic [31 : 0]   irq_data,
    output  logic [1:0]      irq_no,    
    input   logic            irq_ready,

    input logic [1 : 0]   cfg_max_payload,
    input logic [2 : 0]   cfg_max_read_req,

    output reg             indicator

); 
    logic [127:0]  ram_senddma_dout[3:0];
    logic [63:0]   ram_senddma_addr[3:0];
    logic [127:0]  ram_senddma_din[3:0];
    logic [15:0]   ram_senddma_we[3:0];
    logic          ram_senddma_en[3:0];

    logic [127:0]  ram_recvdma_dout[3:0];
    logic [63:0]   ram_recvdma_addr[3:0];
    logic [127:0]  ram_recvdma_din[3:0];
    logic [15:0]   ram_recvdma_we[3:0];
    logic          ram_recvdma_en[3:0];

    logic [127:0]  ram_send_dout[3:0];
    logic [63:0]   ram_send_addr[3:0];
    logic [127:0]  ram_send_din[3:0];
    logic [15:0]   ram_send_we[3:0];
    logic          ram_send_en[3:0];

    logic [127:0]  ram_recv_dout[3:0];
    logic [63:0]   ram_recv_addr[3:0];
    logic [127:0]  ram_recv_din[3:0];
    logic [15:0]   ram_recv_we[3:0];
    logic          ram_recv_en[3:0];


    logic      [DATA_WIDTH - 1 : 0]        s_axis_rq_tdata_int;
    logic      [KEEP_WIDTH - 1 : 0]        s_axis_rq_tkeep_int;
    logic                                  s_axis_rq_tlast_int;
    logic      [3 : 0]                     s_axis_rq_tready_int;
    logic      [RQ_USER_WIDTH - 1 : 0]     s_axis_rq_tuser_int;
    logic                                  s_axis_rq_tvalid_int;
    
    logic rand_logic = 1'b1;
    
    initial begin
        while(1) begin
            @(posedge clk);
            rand_logic <= $random();
        end
    end
    
    assign s_axis_rq_tready_int = rand_logic & s_axis_rq_tready;
    assign s_axis_rq_tvalid = rand_logic & s_axis_rq_tvalid_int;
    assign s_axis_rq_tdata  = s_axis_rq_tdata_int; 
    assign s_axis_rq_tkeep  = s_axis_rq_tkeep_int; 
    assign s_axis_rq_tlast  = s_axis_rq_tlast_int; 
    assign s_axis_rq_tuser  = s_axis_rq_tuser_int; 
    


    function logic [3:0] bin2onehot(input logic [1:0] func);
        case (func)
        2'b00: return 4'b0001;
        2'b01: return 4'b0010;
        2'b10: return 4'b0100;
        2'b11: return 4'b1000;
        endcase
    endfunction


    initial begin
        for (int i = 0; i < 4; i++) begin
            ram_ctl_addr[i] = 0;
            ram_ctl_din[i] = 0;
            ram_ctl_we[i] = 0;
            ram_ctl_en[i] = 1'b1;
            
            
            
        end
    end

    wire [127:0] ram_ctl_dout_s = ram_ctl_dout[0];
    wire [63:0]  ram_ctl_addr_s = ram_ctl_addr[0];
    wire [127:0] ram_ctl_din_s = ram_ctl_din[0];
    wire [15:0]  ram_ctl_we_s = ram_ctl_we[0];

    /* initial begin
        s_axis_rq_tdata = 0;
        s_axis_rq_tkeep = 0;
        s_axis_rq_tlast = 0;
        s_axis_rq_tuser = 0;
        s_axis_rq_tvalid = 0;
        m_axis_rc_tready = 1;
    end */

    initial begin
        indicator = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            indicator <= 0;
        end
        else begin
            if (m_axis_rc_tvalid & m_axis_rc_tready) begin
                indicator <= 1;
            end
            else begin
                indicator <= indicator;
            end
        end
    end

    reg [2:0] func_counter_r, func_counter_s;
    reg [1:0] func_dev, func_dev_r, func_dev_rr;
    reg [63:0] ram_ctl_addr_r[3:0], ram_ctl_addr_rr[3:0], ram_ctl_addr_rrr[3:0];
    wire [63:0] ram_ctl_addr_rr_s = ram_ctl_addr_rr[0];

    reg [63:0] allure_addr_cnt = 0;

    

    wire       dma_trans_finish_s; 
    reg        dma_trans_valid_r;
    reg        dma_trans_mode_r; 
    reg [1:0]  dma_trans_function_r;
    reg [63:0] dma_trans_cpu_region_addr_r;
    reg [63:0] dma_trans_fpga_region_addr_r;
    reg [31:0] dma_trans_transfer_len_r;
    reg [31:0] dma_trans_tag_r;
    reg [31:0] dma_trans_tag_out_r;

    (* MARK_DEBUG="true" *) enum logic [3:0] {
        RESET,
        IDLE,
        REQDECODE,
        READDMAINFO,
        GENDMAREQ,
        DMABUSY,
        GENINTR,
        UPDATEDMASTATUS,
        UPDATERXSTATUS
    } snoop_r, snoop_s;

    always @(posedge clk) begin
        if (rst) begin
            snoop_r <= RESET; 
        end else begin
            snoop_r <= snoop_s;
        end
    end

    logic [7:0] dma_watchdogs_s, dma_watchdog_ack_r;
    logic [2:0] readdma_cnt_r;
    
    assign dma_watchdogs_s[1:0] = dma_watchdog[0][1:0];
    assign dma_watchdogs_s[3:2] = dma_watchdog[1][1:0];
    assign dma_watchdogs_s[5:4] = dma_watchdog[2][1:0];
    assign dma_watchdogs_s[7:6] = dma_watchdog[3][1:0];

    assign dma_watchdog_ack[0][1:0] = dma_watchdog_ack_r[1:0];
    assign dma_watchdog_ack[1][1:0] = dma_watchdog_ack_r[3:2];
    assign dma_watchdog_ack[2][1:0] = dma_watchdog_ack_r[5:4];
    assign dma_watchdog_ack[3][1:0] = dma_watchdog_ack_r[7:6];
    
    
    logic interrupt_en[3:0];
    
    wire interrupt_en_0 = interrupt_en[0];


    logic   [31:0]   packet_tx_length;
    logic   [63:0]   packet_tx_baseaddr;
    logic            packet_tx_valid;

    logic  [31:0]   packet_rx_length;
    logic  [63:0]   packet_rx_baseaddr;
    logic           packet_rx_valid;

    logic  [15:0]   packet_rx_seqnum;


    logic mode_r;
    logic [1:0] function_r;
    
    always_comb begin
        case (snoop_r)
        RESET: begin
            snoop_s = IDLE;
        end
        IDLE: begin
            if (|{dma_watchdogs_s}) begin
                snoop_s = REQDECODE;
            end else if (packet_rx_valid) begin
                snoop_s = UPDATERXSTATUS;
            end else begin
                snoop_s = IDLE;
            end
        end
        REQDECODE: begin
            snoop_s = READDMAINFO;
        end
        READDMAINFO: begin
            if (readdma_cnt_r == 'd5) begin
                snoop_s = GENDMAREQ;
            end else begin
                snoop_s = READDMAINFO;
            end
        end
        GENDMAREQ: begin
            if (dma_trans_valid_r) begin
                snoop_s = DMABUSY;
            end else begin
                snoop_s = UPDATEDMASTATUS;
            end
        end
        DMABUSY: begin
            if (dma_trans_finish_s) begin

                snoop_s = GENINTR; 



            end else begin
                snoop_s = DMABUSY;
            end
        end
        GENINTR: begin
            if (~interrupt_en[function_r] | (irq_valid & irq_ready)) begin
                snoop_s = UPDATEDMASTATUS;
            end else begin
                snoop_s = GENINTR;
            end
        end
        UPDATEDMASTATUS: begin
            snoop_s = IDLE;
        end
        UPDATERXSTATUS: begin
            if (~interrupt_en[function_r] | (irq_valid & irq_ready)) begin
                snoop_s = IDLE;
            end else begin
                snoop_s = UPDATERXSTATUS;
            end
        end
        default: snoop_s = RESET; 
        endcase
    end


    always @(posedge clk) begin
        case (snoop_s)
        RESET, IDLE: begin
            readdma_cnt_r <= 'd0;
        end
        READDMAINFO: begin
            readdma_cnt_r <= readdma_cnt_r + 'd1;
        end
        endcase
    end

    
    logic [127:0] dma_csr_r[3:0];
    
    
    
    
    
    
    
    generate for (genvar i = 0; i < 4; i++) begin
        assign interrupt_en[i] = dma_csr_r[i][1] & dma_csr_r[i][0];
    end
    endgenerate
    
    always_ff @(posedge clk) begin
        case (snoop_s)
        REQDECODE: begin 
            for (integer i = 0; i < 4; i++) begin
                dma_csr_r[i] <= ram_ctl_dout[i][127 : 0];
            end
        end
        endcase
    end
    
    always @(posedge clk) begin
        case (snoop_s)
        GENINTR: begin
            if (interrupt_en[function_r]) begin
                case (dma_trans_mode_r)
                1'b0: irq_no <= 2'd0; 
                1'b1: irq_no <= 2'd1; 
                endcase
                
                irq_valid <= 1'b1;
                irq_func  <= bin2onehot(dma_trans_function_r);
                irq_addr  <= ram_ctl_dout[function_r][63 : 0];
                irq_data  <= ram_ctl_dout[function_r][95 : 64]; 
            end
        end
        UPDATERXSTATUS: begin 
            if (interrupt_en[function_r]) begin
                irq_no <= 2'd2; 
                
                irq_valid <= 1'b1;
                irq_func  <= bin2onehot(dma_trans_function_r);
    
    
            end
        end
        default: begin
            irq_valid <= 1'b0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        GENDMAREQ: begin
            dma_trans_mode_r <= mode_r;
            dma_trans_function_r <= function_r;
            if (dma_trans_tag_out_r == dma_trans_tag_r) begin
                dma_trans_valid_r <= 1'b0;
            end else begin
                dma_trans_valid_r <= 1'b1;
            end
        end
        DMABUSY: begin
        end
        default: begin
            dma_trans_valid_r <= 1'b0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        READDMAINFO: begin
            if (mode_r) begin 
                case (readdma_cnt_r)
                3: begin
                    dma_trans_cpu_region_addr_r <= ram_ctl_dout[function_r][63 -: 64];
                    dma_trans_fpga_region_addr_r <= ram_ctl_dout[function_r][127 -: 64];
                end
                4: begin
                    dma_trans_transfer_len_r <= ram_ctl_dout[function_r][31 -: 32];
                    dma_trans_tag_r <= ram_ctl_dout[function_r][63 -: 32];
                    dma_trans_tag_out_r <= ram_ctl_dout[function_r][95 -: 32];
                end
                endcase
            end else begin 
                case (readdma_cnt_r)
                3: begin
                    dma_trans_cpu_region_addr_r <= ram_ctl_dout[function_r][63 -: 64];
                    dma_trans_fpga_region_addr_r <= ram_ctl_dout[function_r][127 -: 64];
                end
                4: begin
                    dma_trans_transfer_len_r <= ram_ctl_dout[function_r][31 -: 32];
                    dma_trans_tag_r <= ram_ctl_dout[function_r][63 -: 32];
                    dma_trans_tag_out_r <= ram_ctl_dout[function_r][95 -: 32];
                end
                endcase
            end
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        UPDATEDMASTATUS: begin
            dma_watchdog_ack_r[2 * function_r + mode_r] <= 1'b1;
        end
        default: begin
            dma_watchdog_ack_r[7:0] <= 8'h0;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        RESET, IDLE: begin
            ram_ctl_addr[0] <= 64'h000; 
            ram_ctl_addr[1] <= 64'h000;
            ram_ctl_addr[2] <= 64'h000;
            ram_ctl_addr[3] <= 64'h000;
            ram_ctl_we[0] <= 16'h0;
            ram_ctl_we[1] <= 16'h0;
            ram_ctl_we[2] <= 16'h0;
            ram_ctl_we[3] <= 16'h0;
            packet_rx_seqnum <= 16'd0;
        end
        REQDECODE: begin
            casex(dma_watchdogs_s)
            8'bxxxxxxx1: begin
                ram_ctl_addr[0] <= 64'h100; 
            end
            8'bxxxxxx10: begin
                ram_ctl_addr[0] <= 64'h200; 
            end
            8'bxxxxx100: begin
                ram_ctl_addr[1] <= 64'h100; 
            end
            8'bxxxx1000: begin
                ram_ctl_addr[1] <= 64'h200; 
            end
            8'bxxx10000: begin
                ram_ctl_addr[2] <= 64'h100; 
            end
            8'bxx100000: begin
                ram_ctl_addr[2] <= 64'h200; 
            end
            8'bx1000000: begin
                ram_ctl_addr[3] <= 64'h100; 
            end
            8'b10000000: begin
                ram_ctl_addr[3] <= 64'h200; 
            end
            endcase
        end
        READDMAINFO: begin
            ram_ctl_addr[function_r] <= ram_ctl_addr[function_r] + 64'h10;
        end
        GENDMAREQ: begin
            ram_ctl_addr[function_r] <= 'h40;
        end
        UPDATEDMASTATUS: begin
            if (mode_r) begin 
                ram_ctl_addr[function_r] <= 'h210;
                ram_ctl_we[function_r] <= {4'h0, 4'hf, 4'h0, 4'h0};
                ram_ctl_din[function_r] <= {32'h0, dma_trans_tag_r[31:0], 32'h0, 32'h0};
            end else begin 
                ram_ctl_addr[function_r] <= 'h110;
                ram_ctl_we[function_r] <= {4'h0, 4'hf, 4'h0, 4'h0};
                ram_ctl_din[function_r] <= {32'h0, dma_trans_tag_r[31:0], 32'h0, 32'h0};
            end
        end
        UPDATERXSTATUS: begin
            ram_ctl_addr[0] <= 64'h000; 
            ram_ctl_we[0] <= 16'hfffc;
            ram_ctl_din[0] <= {packet_rx_baseaddr, packet_rx_length, packet_rx_seqnum, 16'b1}; 
            packet_rx_seqnum <= packet_rx_seqnum + 16'd1;
        end
        endcase
    end

    always @(posedge clk) begin
        case (snoop_s)
        REQDECODE: begin
            casex(dma_watchdogs_s)
            8'bxxxxxxx1: begin
                mode_r <= 0; 
                function_r <= 0; 
            end
            8'bxxxxxx10: begin
                mode_r <= 1; 
                function_r <= 0; 
            end
            8'bxxxxx100: begin
                mode_r <= 0; 
                function_r <= 1; 
            end
            8'bxxxx1000: begin
                mode_r <= 1; 
                function_r <= 1; 
            end
            8'bxxx10000: begin
                mode_r <= 0; 
                function_r <= 2; 
            end
            8'bxx100000: begin
                mode_r <= 1; 
                function_r <= 2; 
            end
            8'bx1000000: begin
                mode_r <= 0; 
                function_r <= 3; 
            end
            8'b10000000: begin
                mode_r <= 1; 
                function_r <= 3; 
            end
            default: begin

            end
            endcase
        end
        endcase
    end


    dma_simple_net #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
    
        .RQ_USER_WIDTH(RQ_USER_WIDTH),
        .RC_USER_WIDTH(RC_USER_WIDTH)
        
    ) dma_simple_net_inst (
        .clk(clk),
        .rst(rst),

        .dma_trans_finish               (dma_trans_finish_s), 
        .dma_trans_valid                (dma_trans_valid_r),
        .dma_trans_mode                 (dma_trans_mode_r), 
        .dma_trans_function             (dma_trans_function_r        ),
        .dma_trans_cpu_region_addr      (dma_trans_cpu_region_addr_r ),
        .dma_trans_fpga_region_addr     (dma_trans_fpga_region_addr_r),
        .dma_trans_transfer_len         (dma_trans_transfer_len_r    ),

        .s_axis_rq_tdata(s_axis_rq_tdata_int),
        .s_axis_rq_tkeep(s_axis_rq_tkeep_int),
        .s_axis_rq_tlast(s_axis_rq_tlast_int),
        .s_axis_rq_tready(s_axis_rq_tready_int),
        .s_axis_rq_tuser(s_axis_rq_tuser_int),
        .s_axis_rq_tvalid(s_axis_rq_tvalid_int),

        .m_axis_rc_tdata(m_axis_rc_tdata),
        .m_axis_rc_tkeep(m_axis_rc_tkeep),
        .m_axis_rc_tlast(m_axis_rc_tlast),
        .m_axis_rc_tready(m_axis_rc_tready),
        .m_axis_rc_tuser(m_axis_rc_tuser),
        .m_axis_rc_tvalid(m_axis_rc_tvalid),

        .ram_senddma_dout(ram_senddma_dout),
        .ram_senddma_addr(ram_senddma_addr),
        .ram_senddma_din(ram_senddma_din),
        .ram_senddma_we(ram_senddma_we),
        .ram_senddma_en(ram_senddma_en),

        .ram_recvdma_dout(ram_recvdma_dout),
        .ram_recvdma_addr(ram_recvdma_addr),
        .ram_recvdma_din(ram_recvdma_din),
        .ram_recvdma_we(ram_recvdma_we),
        .ram_recvdma_en(ram_recvdma_en),

        .packet_tx_length(packet_tx_length),
        .packet_tx_baseaddr(packet_tx_baseaddr),
        .packet_tx_valid(packet_tx_valid),

        .cfg_max_payload(cfg_max_payload),
        .cfg_max_read_req(cfg_max_read_req)

    );

    logic  [127:0]  send_axis_tdata;
    logic  [15:0]   send_axis_tkeep;
    logic           send_axis_tlast;
    logic           send_axis_tvalid;
    logic           send_axis_tready;

    logic  [127:0]  recv_axis_tdata;
    logic  [15:0]   recv_axis_tkeep;
    logic           recv_axis_tlast;
    logic           recv_axis_tvalid;
    logic           recv_axis_tready;


    mm2ss mm2ss_inst( 
        .clk(clk),
        .rst(rst),

        .ram_mem_dout(ram_send_dout[0]),
        .ram_mem_addr(ram_send_addr[0]),
        .ram_mem_din(ram_send_din[0]),
        .ram_mem_we(ram_send_we[0]),
        .ram_mem_en(ram_send_en[0]),

        .packet_tx_length(packet_tx_length),
        .packet_tx_baseaddr(packet_tx_baseaddr),
        .packet_tx_valid(packet_tx_valid),

        .m_axis_tdata   (send_axis_tdata    ),
        .m_axis_tkeep   (send_axis_tkeep    ),
        .m_axis_tlast   (send_axis_tlast    ),
        .m_axis_tvalid  (send_axis_tvalid   ),
        .m_axis_tready  (send_axis_tready   )
    );

    ss2mm ss2mm_inst(
        .clk(clk),
        .rst(rst),

        .ram_mem_dout(ram_recv_dout[0]),
        .ram_mem_addr(ram_recv_addr[0]),
        .ram_mem_din(ram_recv_din[0]),
        .ram_mem_we(ram_recv_we[0]),
        .ram_mem_en(ram_recv_en[0]),

        .packet_rx_length(packet_rx_length),
        .packet_rx_baseaddr(packet_rx_baseaddr),
        .packet_rx_valid(packet_rx_valid),

        .s_axis_tdata   (recv_axis_tdata    ),
        .s_axis_tkeep   (recv_axis_tkeep    ),
        .s_axis_tlast   (recv_axis_tlast    ),
        .s_axis_tvalid  (recv_axis_tvalid   ),
        .s_axis_tready  (recv_axis_tready   )

    );

    
    assign recv_axis_tdata  = send_axis_tdata ; 
    assign recv_axis_tkeep  = send_axis_tkeep ; 
    assign recv_axis_tlast  = send_axis_tlast ; 
    assign recv_axis_tvalid = send_axis_tvalid & rand_logic; 
    assign send_axis_tready = recv_axis_tready & rand_logic; 


    
    
    
    
    
    
    

    generate
        for (genvar i = 0; i < 4; i++) begin
            
            ram_ctrl #(
                .RAM_DEPTH(1024)
            ) dwram_tx_inst (
                .clk(clk),
                .rst(rst),
        
                .ram_douta(ram_senddma_dout[i]),
                .ram_doutb(ram_send_dout[i]),
                .ram_byteaddra(ram_senddma_addr[i]),
                .ram_byteaddrb(ram_send_addr[i]),
                .ram_dina(ram_senddma_din[i]),
                .ram_dinb(ram_send_din[i]),
                .ram_wea(ram_senddma_we[i]),
                .ram_web(ram_send_we[i]),
                .ram_ena(ram_senddma_en[i]),
                .ram_enb(ram_send_en[i])
            );
            
            ram_ctrl #(
                .RAM_DEPTH(1024)
            ) dwram_rx_inst (
                .clk(clk),
                .rst(rst),
        
                .ram_douta(ram_recvdma_dout[i]),
                .ram_doutb(ram_recv_dout[i]),
                .ram_byteaddra(ram_recvdma_addr[i]),
                .ram_byteaddrb(ram_recv_addr[i]),
                .ram_dina(ram_recvdma_din[i]),
                .ram_dinb(ram_recv_din[i]),
                .ram_wea(ram_recvdma_we[i]),
                .ram_web(ram_recv_we[i]),
                .ram_ena(ram_recvdma_en[i]),
                .ram_enb(ram_recv_en[i])
            );
        end    
    endgenerate

endmodule
