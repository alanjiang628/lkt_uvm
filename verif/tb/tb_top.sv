`include "uvm_macros.svh"
import uvm_pkg::*;
`include "lkt_config_pkg.sv" // Import the new config package
`include "lkt_if.sv"
`include "lkt_test_pkg.sv"

module tb_top;

    // Use the parameters from the config package
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

    // Interface instantiation with parameters
    lkt_if #(
        .RESULT_WIDTH(P_RESULT_WIDTH),
        .NUM_LOOKUPS(P_NUM_LOOKUPS),
        .NUM_CHOICES(P_NUM_CHOICES)
    ) vif(clk, rst_n);

    // DUT instantiation with parameters
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
        // Place virtual interface in config_db
        uvm_config_db#(virtual lkt_if)::set(null, "uvm_test_top", "vif", vif);
        
        // Waveform dumping
        $fsdbDumpfile("lkt_sim.fsdb");
        $fsdbDumpvars(0, tb_top);

        // Run the test
        run_test();
    end

endmodule
