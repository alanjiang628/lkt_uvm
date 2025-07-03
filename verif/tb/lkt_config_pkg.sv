`ifndef __LKT_CONFIG_PKG_SV__
`define __LKT_CONFIG_PKG_SV__

package lkt_config_pkg;
    // These parameters define the DUT configuration for a specific run.
    // They are used by tb_top to instantiate the interface and DUT,
    // and by the test package to configure the UVM environment.
`ifdef BOUNDARY_TEST
    // Configuration for boundary condition tests
    parameter int RESULT_WIDTH = 16; // Max example
    parameter int NUM_LOOKUPS  = 16; // Max example
    parameter int NUM_CHOICES  = 8;  // Max example
`else
    // Default configuration for standard tests
    parameter int RESULT_WIDTH = 3;
    parameter int NUM_LOOKUPS  = 8;
    parameter int NUM_CHOICES  = 2;
`endif
endpackage

`endif
