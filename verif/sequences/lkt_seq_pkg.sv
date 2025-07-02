`ifndef __LKT_SEQ_PKG_SV__
`define __LKT_SEQ_PKG_SV__

package lkt_seq_pkg;
    import uvm_pkg::*;
    import lkt_agent_pkg::*;
    import lkt_env_pkg::*;

    `include "base_sequence.sv"
    `include "lk_table_func_randomized_seq.sv"
    `include "lk_table_func_one_hot_all_seq.sv"
    `include "lk_table_func_no_choice_seq.sv"
    `include "lk_table_func_one_hot_mixed_seq.sv"
    `include "lk_table_neg_multi_hot_seq.sv"
endpackage

`endif
