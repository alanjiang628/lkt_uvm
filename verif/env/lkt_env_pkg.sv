`ifndef __LKT_ENV_PKG_SV__
`define __LKT_ENV_PKG_SV__

`include "lkt_agent_pkg.sv"

package lkt_env_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import lkt_agent_pkg::*;

    `include "components/lkt_scoreboard.sv"
    `include "components/lkt_coverage.sv"
    `include "lkt_env.sv"
endpackage

`endif
