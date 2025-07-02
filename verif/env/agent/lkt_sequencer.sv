`ifndef __LKT_SEQUENCER_SV__
`define __LKT_SEQUENCER_SV__

class lkt_sequencer extends uvm_sequencer #(lkt_transaction);
    `uvm_component_utils(lkt_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

`endif
