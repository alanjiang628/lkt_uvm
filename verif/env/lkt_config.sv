`ifndef __LKT_CONFIG_SV__
`define __LKT_CONFIG_SV__

class lkt_config extends uvm_object;
    `uvm_object_utils(lkt_config)

    // Virtual interface handle
    virtual lkt_if vif;

    // DUT Parameters
    int RESULT_WIDTH = 3;
    int NUM_LOOKUPS  = 8;
    int NUM_CHOICES  = 2;

    // Environment control
    bit enable_sb = 1;
    bit enable_coverage = 1;

    function new(string name = "lkt_config");
        super.new(name);
    endfunction

endclass

`endif
