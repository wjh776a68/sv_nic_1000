create_clock -period 10.000 -name sys_clk [get_ports pcie_clk_p]
set_property PACKAGE_PIN AR15 [get_ports pcie_clk_p]
set_property IOSTANDARD LVCMOS18 [get_ports negative_process_indicator]
set_property IOSTANDARD LVCMOS18 [get_ports phy_rdy_out]
set_property IOSTANDARD LVCMOS18 [get_ports positive_process_indicator]
set_property IOSTANDARD LVCMOS18 [get_ports user_lnk_up]
set_property PACKAGE_PIN BH24 [get_ports phy_rdy_out]
set_property PACKAGE_PIN BG24 [get_ports user_lnk_up]
set_property PACKAGE_PIN BG25 [get_ports negative_process_indicator]
set_property PACKAGE_PIN BF25 [get_ports positive_process_indicator]

