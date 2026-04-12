create_clock -name core_clk -period 2.000 [get_ports clk_i]
set_clock_uncertainty 0.050 [get_clocks core_clk]

set_input_delay 0.200 -clock [get_clocks core_clk] [get_ports valid_i]
set_input_delay 0.200 -clock [get_clocks core_clk] [get_ports {data_i[*]}]

set_output_delay 0.200 -clock [get_clocks core_clk] [get_ports ready_o]
set_output_delay 0.200 -clock [get_clocks core_clk] [get_ports {data_o[*]}]

set_false_path -from [get_ports rst_ni]

