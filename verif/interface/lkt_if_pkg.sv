`ifndef __LKT_IF_PKG_SV__
`define __LKT_IF_PKG_SV__

package lkt_if_pkg;
    // This package centralizes the definition of the virtual interface type.
    // By using the parameters from lkt_config_pkg, the typedef for lkt_vif
    // will automatically match the physical interface parameters, whether
    // the BOUNDARY_TEST macro is defined or not.

    import lkt_config_pkg::*;

    typedef virtual lkt_if #(
        .RESULT_WIDTH(lkt_config_pkg::RESULT_WIDTH),
        .NUM_LOOKUPS(lkt_config_pkg::NUM_LOOKUPS),
        .NUM_CHOICES(lkt_config_pkg::NUM_CHOICES)
    ) lkt_vif;

endpackage

`endif
