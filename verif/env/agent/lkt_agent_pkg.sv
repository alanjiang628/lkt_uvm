`ifndef __LKT_AGENT_PKG_SV__
`define __LKT_AGENT_PKG_SV__

package lkt_agent_pkg;
  import uvm_pkg::*;
  import lkt_if_pkg::*; // Import the centralized virtual interface type
  `include "lkt_config.sv"
  `include "lkt_transaction.sv"
  `include "lkt_driver.sv"
  `include "lkt_monitor.sv"
  `include "lkt_sequencer.sv"
  `include "lkt_agent.sv"
endpackage

`endif
