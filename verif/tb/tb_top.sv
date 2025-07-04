`include "uvm_macros.svh"
import uvm_pkg::*;
`include "lkt_config_pkg.sv" // Import the new config package
`include "lkt_if.sv"
`include "lkt_if_pkg.sv" // Import the new virtual interface type package

module tb_top;
    import lkt_test_pkg::*; // Import the test package

    // Use the parameters from the config package to control instantiation
    parameter int P_RESULT_WIDTH = lkt_config_pkg::RESULT_WIDTH;
    parameter int P_NUM_LOOKUPS  = lkt_config_pkg::NUM_LOOKUPS;
    parameter int P_NUM_CHOICES  = lkt_config_pkg::NUM_CHOICES;

    bit clk;
    bit rst_n;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Interface instantiation with parameters from the config package
    lkt_if #(
        .RESULT_WIDTH(P_RESULT_WIDTH),
        .NUM_LOOKUPS(P_NUM_LOOKUPS),
        .NUM_CHOICES(P_NUM_CHOICES)
    ) vif(clk, rst_n);

    // DUT instantiation with parameters from the config package
    zh_1hot_lookup_table #(
        .RESULT_WIDTH(P_RESULT_WIDTH),
        .NUM_LOOKUPS(P_NUM_LOOKUPS),
        .NUM_CHOICES(P_NUM_CHOICES)
    ) dut (
        .lookup_table_i(vif.lookup_table_i),
        .input_i(vif.input_i),
        .output_o(vif.output_o)
    );

    initial begin
        // Set the virtual interface using the centralized typedef.
        // This ensures the type used here exactly matches the type used
        // in the UVM components, as both are driven by lkt_config_pkg.
        uvm_config_db#(lkt_if_pkg::lkt_vif)::set(null, "*", "vif", vif);
        
        // Run the test
        run_test();
    end

endmodule
