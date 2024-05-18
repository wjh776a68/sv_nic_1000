`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: wjh776a68
// 
// Create Date: Sat May 18 13:43:14 CST 2024
// Design Name: 
// Module Name: nic_top
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

module nic_top # (
    localparam LANE_NUM = 4,
    localparam DATA_WIDTH = 128,
    localparam KEEP_WIDTH = DATA_WIDTH / 32,
    
    localparam RQ_USER_WIDTH = 62,
    localparam RC_USER_WIDTH = 75,
    localparam CQ_USER_WIDTH = 88,
    localparam CC_USER_WIDTH = 33
    
) (
    output  [LANE_NUM - 1 : 0]     pci_exp_txn,
    output  [LANE_NUM - 1 : 0]     pci_exp_txp,
    input   [LANE_NUM - 1 : 0]     pci_exp_rxn,
    input   [LANE_NUM - 1 : 0]     pci_exp_rxp,

    input               pcie_clk_p,
    input               pcie_clk_n,
    input               sys_reset,

    
    output              phy_rdy_out,
    output              user_lnk_up,
    output              positive_process_indicator,
    output              negative_process_indicator
);

    wire sys_clk;
    wire sys_clk_gt;
    
    wire user_clk;
    wire user_reset;

    IBUFDS_GTE4 #(
        .REFCLK_EN_TX_PATH(1'b0),   
        .REFCLK_HROW_CK_SEL(2'b00), 
        .REFCLK_ICNTL_RX(2'b00)     
    )
    IBUFDS_GTE4_inst (
        .O(sys_clk_gt),         
        .ODIV2(sys_clk), 
        .CEB(1'b0),     
        .I(pcie_clk_p),         
        .IB(pcie_clk_n)        
    );
    


    (* MARK_DEBUG="true" *) logic [5 : 0]   pcie_rq_seq_num0;
    (* MARK_DEBUG="true" *) logic           pcie_rq_seq_num_vld0;
    (* MARK_DEBUG="true" *) logic [5 : 0]   pcie_rq_seq_num1;
    (* MARK_DEBUG="true" *) logic           pcie_rq_seq_num_vld1;
    (* MARK_DEBUG="true" *) logic [7 : 0]   pcie_rq_tag0;
    (* MARK_DEBUG="true" *) logic [7 : 0]   pcie_rq_tag1;
    (* MARK_DEBUG="true" *) logic [3 : 0]   pcie_rq_tag_av;
    (* MARK_DEBUG="true" *) logic           pcie_rq_tag_vld0;
    (* MARK_DEBUG="true" *) logic           pcie_rq_tag_vld1;
    (* MARK_DEBUG="true" *) logic [1 : 0]   pcie_cq_np_req = 2'b11;
    (* MARK_DEBUG="true" *) logic [5 : 0]   pcie_cq_np_req_count;
    (* MARK_DEBUG="true" *) logic           cfg_phy_link_down;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_phy_link_status;
    (* MARK_DEBUG="true" *) logic [2 : 0]   cfg_negotiated_width;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_current_speed;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_max_payload;  
    (* MARK_DEBUG="true" *) logic [2 : 0]   cfg_max_read_req; 
    (* MARK_DEBUG="true" *) logic [15 : 0]  cfg_function_status;
    (* MARK_DEBUG="true" *) logic [11 : 0]  cfg_function_power_state;
    (* MARK_DEBUG="true" *) logic [503 : 0] cfg_vf_status;
    (* MARK_DEBUG="true" *) logic [755 : 0] cfg_vf_power_state;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_link_power_state;
    (* MARK_DEBUG="true" *) logic           cfg_err_cor_out;
    (* MARK_DEBUG="true" *) logic           cfg_err_nonfatal_out;
    (* MARK_DEBUG="true" *) logic           cfg_err_fatal_out;
    (* MARK_DEBUG="true" *) logic           cfg_local_error_valid;
    (* MARK_DEBUG="true" *) logic [4 : 0]   cfg_local_error_out;
    (* MARK_DEBUG="true" *) logic [5 : 0]   cfg_ltssm_state;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_rx_pm_state;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_tx_pm_state;
    (* MARK_DEBUG="true" *) logic [3 : 0]   cfg_rcb_status;
    (* MARK_DEBUG="true" *) logic [1 : 0]   cfg_obff_enable;
    (* MARK_DEBUG="true" *) logic           cfg_pl_status_change;
    (* MARK_DEBUG="true" *) logic [3 : 0]   cfg_tph_requester_enable;
    (* MARK_DEBUG="true" *) logic [11 : 0]  cfg_tph_st_mode;
    (* MARK_DEBUG="true" *) logic [251 : 0] cfg_vf_tph_requester_enable;
    (* MARK_DEBUG="true" *) logic [755 : 0] cfg_vf_tph_st_mode;
    

    
    wire [3:0]      cfg_interrupt_int;
    wire [3:0]      cfg_interrupt_pending;
    wire            cfg_interrupt_sent;

    wire [3 : 0] cfg_interrupt_msi_enable;
    wire [11 : 0] cfg_interrupt_msi_mmenable;
    wire cfg_interrupt_msi_mask_update;
    wire [31 : 0] cfg_interrupt_msi_data;
    wire [1 : 0] cfg_interrupt_msi_select;
    wire [31 : 0] cfg_interrupt_msi_int;
    wire [31 : 0] cfg_interrupt_msi_pending_status;
    wire cfg_interrupt_msi_pending_status_data_enable;
    wire [1 : 0] cfg_interrupt_msi_pending_status_function_num;
    wire cfg_interrupt_msi_sent;
    wire cfg_interrupt_msi_fail;
    wire [2 : 0] cfg_interrupt_msi_attr;
    wire cfg_interrupt_msi_tph_present;
    wire [1 : 0] cfg_interrupt_msi_tph_type;
    wire [7 : 0] cfg_interrupt_msi_tph_st_tag;
    wire [7 : 0] cfg_interrupt_msi_function_number;

    wire [3 : 0] cfg_interrupt_msix_enable;
    wire [3 : 0] cfg_interrupt_msix_mask;
    wire [251 : 0] cfg_interrupt_msix_vf_enable;
    wire [251 : 0] cfg_interrupt_msix_vf_mask;
    wire [31 : 0] cfg_interrupt_msix_data;
    wire [63 : 0] cfg_interrupt_msix_address;
    wire cfg_interrupt_msix_int;
    wire [1 : 0] cfg_interrupt_msix_vec_pending;
    wire [0 : 0] cfg_interrupt_msix_vec_pending_status;


    
    
    
    wire [DATA_WIDTH - 1 : 0]  s_axis_rq_tdata;
    wire [KEEP_WIDTH - 1 : 0]    s_axis_rq_tkeep;
    wire            s_axis_rq_tlast;
    wire [3 : 0]    s_axis_rq_tready;
    wire [RQ_USER_WIDTH - 1 : 0]   s_axis_rq_tuser;
    wire            s_axis_rq_tvalid;

    wire [DATA_WIDTH - 1 : 0]  m_axis_rc_tdata;
    wire [KEEP_WIDTH - 1 : 0]    m_axis_rc_tkeep;
    wire            m_axis_rc_tlast;
    wire            m_axis_rc_tready;
    wire [RC_USER_WIDTH - 1 : 0]   m_axis_rc_tuser;
    wire            m_axis_rc_tvalid;

    


    
    
    
    wire [DATA_WIDTH - 1 : 0]  m_axis_cq_tdata;
    wire [KEEP_WIDTH - 1 : 0]    m_axis_cq_tkeep;
    wire            m_axis_cq_tlast;
    wire            m_axis_cq_tready;
    wire [CQ_USER_WIDTH - 1 : 0]   m_axis_cq_tuser;
    wire            m_axis_cq_tvalid;

    wire [DATA_WIDTH - 1 : 0]  s_axis_cc_tdata;
    wire [KEEP_WIDTH - 1 : 0]    s_axis_cc_tkeep;
    wire            s_axis_cc_tlast;
    wire [3 : 0]    s_axis_cc_tready;
    wire [CC_USER_WIDTH - 1 : 0]   s_axis_cc_tuser;
    wire            s_axis_cc_tvalid;
    
    user_core # (
        .LANE_NUM(LANE_NUM),
        .DATA_WIDTH(DATA_WIDTH),

        .RQ_USER_WIDTH(RQ_USER_WIDTH),
        .RC_USER_WIDTH(RC_USER_WIDTH),
        .CQ_USER_WIDTH(CQ_USER_WIDTH),
        .CC_USER_WIDTH(CC_USER_WIDTH)

    ) user_core_inst (
        .clk(user_clk),
        .rst(user_reset),

        .s_axis_rq_tdata(s_axis_rq_tdata),
        .s_axis_rq_tkeep(s_axis_rq_tkeep),
        .s_axis_rq_tlast(s_axis_rq_tlast),
        .s_axis_rq_tready(s_axis_rq_tready),
        .s_axis_rq_tuser(s_axis_rq_tuser),
        .s_axis_rq_tvalid(s_axis_rq_tvalid),

        .m_axis_rc_tdata(m_axis_rc_tdata),
        .m_axis_rc_tkeep(m_axis_rc_tkeep),
        .m_axis_rc_tlast(m_axis_rc_tlast),
        .m_axis_rc_tready(m_axis_rc_tready),
        .m_axis_rc_tuser(m_axis_rc_tuser),
        .m_axis_rc_tvalid(m_axis_rc_tvalid),

        .m_axis_cq_tdata(m_axis_cq_tdata),
        .m_axis_cq_tkeep(m_axis_cq_tkeep),
        .m_axis_cq_tlast(m_axis_cq_tlast),
        .m_axis_cq_tready(m_axis_cq_tready),
        .m_axis_cq_tuser(m_axis_cq_tuser),
        .m_axis_cq_tvalid(m_axis_cq_tvalid),

        .s_axis_cc_tdata(s_axis_cc_tdata),
        .s_axis_cc_tkeep(s_axis_cc_tkeep),
        .s_axis_cc_tlast(s_axis_cc_tlast),
        .s_axis_cc_tready(s_axis_cc_tready),
        .s_axis_cc_tuser(s_axis_cc_tuser),
        .s_axis_cc_tvalid(s_axis_cc_tvalid),

        .cfg_interrupt_int(cfg_interrupt_int),
        .cfg_interrupt_pending(cfg_interrupt_pending),
        .cfg_interrupt_sent(cfg_interrupt_sent),

        .cfg_interrupt_msi_enable(cfg_interrupt_msi_enable),
        .cfg_interrupt_msi_mmenable(cfg_interrupt_msi_mmenable),
        .cfg_interrupt_msi_mask_update(cfg_interrupt_msi_mask_update),
        .cfg_interrupt_msi_data(cfg_interrupt_msi_data),
        .cfg_interrupt_msi_select(cfg_interrupt_msi_select),
        .cfg_interrupt_msi_int(cfg_interrupt_msi_int),
        .cfg_interrupt_msi_pending_status(cfg_interrupt_msi_pending_status),
        .cfg_interrupt_msi_pending_status_data_enable(cfg_interrupt_msi_pending_status_data_enable),
        .cfg_interrupt_msi_pending_status_function_num(cfg_interrupt_msi_pending_status_function_num),
        .cfg_interrupt_msi_sent(cfg_interrupt_msi_sent),
        .cfg_interrupt_msi_fail(cfg_interrupt_msi_fail),
        .cfg_interrupt_msi_attr(cfg_interrupt_msi_attr),
        .cfg_interrupt_msi_tph_present(cfg_interrupt_msi_tph_present),
        .cfg_interrupt_msi_tph_type(cfg_interrupt_msi_tph_type),
        .cfg_interrupt_msi_tph_st_tag(cfg_interrupt_msi_tph_st_tag),
        .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),
        
        .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
        .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
        .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
        .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
        .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
        .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
        .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
        .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
        .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),

        .cfg_max_payload(cfg_max_payload),
        .cfg_max_read_req(cfg_max_read_req),

        .positive_process_indicator(positive_process_indicator),
        .negative_process_indicator(negative_process_indicator)
    );
    
    
    pcie4c_uscale_plus_0 pcie4c_uscale_plus_0_i (
        .pci_exp_txn(pci_exp_txn),                      
        .pci_exp_txp(pci_exp_txp),                      
        .pci_exp_rxn(pci_exp_rxn),                      
        .pci_exp_rxp(pci_exp_rxp),                      
        .user_clk(user_clk),                            
        .user_reset(user_reset),                        
        .user_lnk_up(user_lnk_up),                      
        .s_axis_rq_tdata(s_axis_rq_tdata),              
        .s_axis_rq_tkeep(s_axis_rq_tkeep),              
        .s_axis_rq_tlast(s_axis_rq_tlast),              
        .s_axis_rq_tready(s_axis_rq_tready),            
        .s_axis_rq_tuser(s_axis_rq_tuser),              
        .s_axis_rq_tvalid(s_axis_rq_tvalid),            
        .m_axis_rc_tdata(m_axis_rc_tdata),              
        .m_axis_rc_tkeep(m_axis_rc_tkeep),              
        .m_axis_rc_tlast(m_axis_rc_tlast),              
        .m_axis_rc_tready(m_axis_rc_tready),            
        .m_axis_rc_tuser(m_axis_rc_tuser),              
        .m_axis_rc_tvalid(m_axis_rc_tvalid),            
        .m_axis_cq_tdata(m_axis_cq_tdata),              
        .m_axis_cq_tkeep(m_axis_cq_tkeep),              
        .m_axis_cq_tlast(m_axis_cq_tlast),              
        .m_axis_cq_tready(m_axis_cq_tready),            
        .m_axis_cq_tuser(m_axis_cq_tuser),              
        .m_axis_cq_tvalid(m_axis_cq_tvalid),            
        .s_axis_cc_tdata(s_axis_cc_tdata),              
        .s_axis_cc_tkeep(s_axis_cc_tkeep),              
        .s_axis_cc_tlast(s_axis_cc_tlast),              
        .s_axis_cc_tready(s_axis_cc_tready),            
        .s_axis_cc_tuser(s_axis_cc_tuser),              
        .s_axis_cc_tvalid(s_axis_cc_tvalid),            

        .cfg_interrupt_int(cfg_interrupt_int),          
        .cfg_interrupt_pending(cfg_interrupt_pending),  
        .cfg_interrupt_sent(cfg_interrupt_sent),        
        .cfg_interrupt_msi_enable(cfg_interrupt_msi_enable),                                            
        .cfg_interrupt_msi_mmenable(cfg_interrupt_msi_mmenable),                                        
        .cfg_interrupt_msi_mask_update(cfg_interrupt_msi_mask_update),                                  
        .cfg_interrupt_msi_data(cfg_interrupt_msi_data),                                                
        .cfg_interrupt_msi_select(cfg_interrupt_msi_select),                                            
        .cfg_interrupt_msi_int(cfg_interrupt_msi_int),                                                  
        .cfg_interrupt_msi_pending_status(cfg_interrupt_msi_pending_status),                            
        .cfg_interrupt_msi_pending_status_data_enable(cfg_interrupt_msi_pending_status_data_enable),    
        .cfg_interrupt_msi_pending_status_function_num(cfg_interrupt_msi_pending_status_function_num),  
        .cfg_interrupt_msi_sent(cfg_interrupt_msi_sent),                                                
        .cfg_interrupt_msi_fail(cfg_interrupt_msi_fail),                                                
        .cfg_interrupt_msi_attr(cfg_interrupt_msi_attr),                                                
        .cfg_interrupt_msi_tph_present(cfg_interrupt_msi_tph_present),                                  
        .cfg_interrupt_msi_tph_type(cfg_interrupt_msi_tph_type),                                        
        .cfg_interrupt_msi_tph_st_tag(cfg_interrupt_msi_tph_st_tag),                                    
        .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),                          
        .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),                                          
        .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),                                              
        .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),                                    
        .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),                                        
        .cfg_interrupt_msix_data(cfg_interrupt_msix_data),                                              
        .cfg_interrupt_msix_address(cfg_interrupt_msix_address),                                        
        .cfg_interrupt_msix_int(cfg_interrupt_msix_int),                                                
        .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),                                
        .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),                  


        .pcie_rq_seq_num0(pcie_rq_seq_num0),                                                            
        .pcie_rq_seq_num_vld0(pcie_rq_seq_num_vld0),                                                    
        .pcie_rq_seq_num1(pcie_rq_seq_num1),                                                            
        .pcie_rq_seq_num_vld1(pcie_rq_seq_num_vld1),                                                    
        .pcie_rq_tag0(pcie_rq_tag0),                                                                    
        .pcie_rq_tag1(pcie_rq_tag1),                                                                    
        .pcie_rq_tag_av(pcie_rq_tag_av),                                                                
        .pcie_rq_tag_vld0(pcie_rq_tag_vld0),                                                            
        .pcie_rq_tag_vld1(pcie_rq_tag_vld1),                                                            
        .pcie_cq_np_req(pcie_cq_np_req),                                                                
        .pcie_cq_np_req_count(pcie_cq_np_req_count),                                                    
        .cfg_phy_link_down(cfg_phy_link_down),                                                          
        .cfg_phy_link_status(cfg_phy_link_status),                                                      
        .cfg_negotiated_width(cfg_negotiated_width),                                                    
        .cfg_current_speed(cfg_current_speed),                                                          
        .cfg_max_payload(cfg_max_payload),                                                              
        .cfg_max_read_req(cfg_max_read_req),                                                            
        .cfg_function_status(cfg_function_status),                                                      
        .cfg_function_power_state(cfg_function_power_state),                                            
        .cfg_vf_status(cfg_vf_status),                                                                  
        .cfg_vf_power_state(cfg_vf_power_state),                                                        
        .cfg_link_power_state(cfg_link_power_state),                                                    
        .cfg_err_cor_out(cfg_err_cor_out),                                                              
        .cfg_err_nonfatal_out(cfg_err_nonfatal_out),                                                    
        .cfg_err_fatal_out(cfg_err_fatal_out),                                                          
        .cfg_local_error_valid(cfg_local_error_valid),                                                  
        .cfg_local_error_out(cfg_local_error_out),                                                      
        .cfg_ltssm_state(cfg_ltssm_state),                                                              
        .cfg_rx_pm_state(cfg_rx_pm_state),                                                              
        .cfg_tx_pm_state(cfg_tx_pm_state),                                                              
        .cfg_rcb_status(cfg_rcb_status),                                                                
        .cfg_obff_enable(cfg_obff_enable),                                                              
        .cfg_pl_status_change(cfg_pl_status_change),                                                    
        .cfg_tph_requester_enable(cfg_tph_requester_enable),                                            
        .cfg_tph_st_mode(cfg_tph_st_mode),                                                              
        .cfg_vf_tph_requester_enable(cfg_vf_tph_requester_enable),                                      
        .cfg_vf_tph_st_mode(cfg_vf_tph_st_mode),                                                        
          

        .sys_clk(sys_clk),                              
        .sys_clk_gt(sys_clk_gt),                        
        .sys_reset(sys_reset),        
        .phy_rdy_out(phy_rdy_out)                      
    );

  
endmodule
